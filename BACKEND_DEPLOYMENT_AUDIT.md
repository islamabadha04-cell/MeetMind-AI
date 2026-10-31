# MEETMIND AI — BACKEND ARCHITECTURE & DEPLOYMENT AUDIT
**Date:** October 31, 2026  
**Auditor:** Senior Cloud Architect, DevOps Engineer & Security Specialist  
**Application Version:** `v4.0.1`  
**Target Environment:** Staging / Cloud Preview  

---

## 1. Executive Summary

This architecture audit examines the FastAPI backend for **MeetMind AI**, analyzes its runtime configuration, data persistence, authentication integration with Firebase, environment variables, security posture, and identifies the full catalog of API endpoints required by the frontend.

---

## 2. Component Architecture Analysis

### 2.1 FastAPI Entry Point
- **File:** [`backend/app/main.py`](file:///c:/Users/Hasnain.DESKTOP-80IKSQ9/Desktop/hasnain/backend/app/main.py)
- **Framework:** FastAPI `0.162.0` on Starlette `1.10.0`
- **Application Instance:** `app = FastAPI(title=settings.PROJECT_NAME, version="4.0.1", ...)`
- **Middleware:** `CORSMiddleware`
- **Current Route Handlers:** 55 endpoints across Authentication, Meetings, Search, RAG Knowledge Base, Memory, Tasks, Approvals, Notifications, Workflows, and 10 Enterprise Integration providers.

### 2.2 Uvicorn Runtime Configuration
- **Server:** Uvicorn ASGI Server (`0.54.0`)
- **Worker Configuration:** Single worker in local development (`uvicorn app.main:app --host 0.0.0.0 --port 8000`); production template in `deploy_server.sh` targets 4 worker processes with Gunicorn/Uvicorn.
- **Protocol:** HTTP/1.1 and WebSockets via `websockets` package.
- **Port Binding:** Defaults to port `8000` or `$PORT` environment variable in containerized/cloud environments.

### 2.3 SQLAlchemy Database Configuration
- **File:** [`backend/app/db/session.py`](file:///c:/Users/Hasnain.DESKTOP-80IKSQ9/Desktop/hasnain/backend/app/db/session.py)
- **ORM Version:** SQLAlchemy `2.1.6`
- **Engine Setup:**
  ```python
  connect_args = {"check_same_thread": False} if "sqlite" in settings.DATABASE_URL else {}
  engine = create_engine(settings.DATABASE_URL, connect_args=connect_args, echo=False)
  SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
  Base = declarative_base()
  ```
- **Dialect Portability:** Declarative Base and schema definitions use standard ANSI/SQLAlchemy types (`Integer`, `String`, `Text`, `DateTime`, `Boolean`, `Float`, `ForeignKey`), ensuring 100% plug-and-play compatibility with **PostgreSQL** (`postgresql+psycopg2://...`) without altering business logic.

### 2.4 Current SQLite Database (`meetmind.db`)
- **Location:** `meetmind.db` (Root directory, 733,184 bytes)
- **Verified Backup:** `database_backups/meetmind_backup_20261031_pre_phase4b.db` (SHA256: `EFCF2873E27EE8D655C96187C5EF431B6DD1F2EA4D58EA6F2EAC4D961694C7BA`)
- **SQL Dump:** `database_backups/meetmind_dump_20261031.sql` (494 KB)
- **Table Inventory & Record Counts:**
  | Table Name | Record Count | Description |
  |---|:---:|---|
  | `users` | 73 | User credentials, roles, minutes quota |
  | `workspaces` | 0 | Multi-tenant organization boundaries |
  | `meetings` | 101 | Meeting sessions, audio links, durations |
  | `meeting_summaries` | 100 | AI Executive summaries, key decisions |
  | `meeting_chunks` | 70 | Text chunks for semantic vector search |
  | `tasks` | 135 | Extracted action items, deadlines, owners |
  | `task_comments` | 16 | Team collaboration discussions on tasks |
  | `task_history` | 83 | Audit trail of task status transitions |
  | `approval_requests` | 81 | Manager review queue for AI tasks |
  | `notifications` | 135 | System notifications and deadline alerts |
  | `workflows` | 29 | Automation trigger-action chains |
  | `workflow_executions` | 28 | Execution logs of automated workflows |
  | `knowledge_documents` | 40 | Uploaded company PDFs and DOCX files |
  | `document_chunks` | 41 | Sliding window RAG chunks with embeddings |
  | `meeting_memories` | 411 | Persistent organizational knowledge facts |
  | `integrations` | 40 | Enterprise provider connections |
  | `external_entity_mappings`| 88 | Sync IDs (Calendar event IDs, Jira IDs) |
  | `webhook_subscriptions` | 44 | Active outgoing webhook configurations |
  | `webhook_deliveries` | 22 | Outgoing webhook delivery logs |
  | `integration_jobs` | 40 | Asynchronous background integration jobs |
  | `oauth_nonces` | 37 | Persistent OAuth 2.0 nonces & PKCE verifiers |
  | `processed_webhook_messages`| 22 | Inbound webhook message deduplication |

### 2.5 Security Models
1. **Persistent OAuth Nonce Model (`OAuthNonce`):**
   - Stores 256-bit cryptographically unique nonces, user binding, provider binding, RFC 7636 PKCE `code_verifier`, and expiration timestamp (`expires_at`).
   - Atomic consumption via conditional SQL query (`UPDATE oauth_nonces SET consumed=1 WHERE consumed=0 AND expires_at >= :now`).
2. **Integration Token Storage (`Integration`):**
   - Access tokens and refresh tokens are encrypted using **AES-256-GCM AEAD** with **HKDF-SHA256 (RFC 5869)** key derivation.
   - 96-bit initialization vector (nonce) prepended to ciphertext; 128-bit authentication tag appended.
   - Versioned ciphertext prefix: `gcm:v1:...` supporting zero-downtime key rotation.
   - Failed tag validation immediately raises `TokenDecryptionError` and responds with `status="reauthorization_required"`.
3. **Webhook Deduplication Model (`ProcessedWebhookMessage`):**
   - Stores provider name, external `message_id` (e.g. WhatsApp `wamid`), sender identity, and processing timestamp.
   - Enforces unique constraint preventing duplicate webhook processing and replay attempts.

### 2.6 Firebase Authentication & Firestore Co-existence
- **Client-Side Auth:** [`firebase-service.js`](file:///c:/Users/Hasnain.DESKTOP-80IKSQ9/Desktop/hasnain/firebase-service.js) uses Firebase Web SDK v10.11.0 to authenticate users against Firebase Project `meetmind-ai-74519`.
- **Hybrid Data Flow:**
  - Browser writes meeting recordings and basic meeting logs to Firebase Firestore and Cloud Storage.
  - Deep intelligence workflows—including neural transcription, multi-meeting semantic search, RAG embeddings, AI comparison, workflow execution, and enterprise OAuth integrations—call the **FastAPI backend**.
- **Bearer Token Authentication:** The backend's `get_current_user` dependency parses Bearer tokens from the `Authorization` header, validating both internal HMAC-SHA256 tokens and Firebase Auth JWTs.

### 2.7 Environment Variables & Secrets
| Variable | Default Value | Purpose | Staging Requirement |
|---|---|---|---|
| `PROJECT_NAME` | `MeetMind AI` | Application branding | Keep standard |
| `ENVIRONMENT` | `development` | Runtime mode | Set to `staging` |
| `DEBUG` | `True` | Traceback exposure | Set to `False` in staging |
| `SECRET_KEY` | `meetmind-dev-...` | HMAC signing & token derivation | Must be high-entropy cryptographically random secret |
| `DATABASE_URL` | `sqlite:///./meetmind.db` | Storage connection | Use managed PostgreSQL in multi-worker staging |
| `GEMINI_API_KEY` | Configured | Google Gemini LLM API | Passed securely via environment |
| `BACKEND_CORS_ORIGINS`| `*` | Allowed CORS origins | Restrict to Firebase Hosting domains |

### 2.8 Existing Deployment Configurations
1. **`render.yaml`:**
   - Defines a Python web service `meetmind-api` on the free plan running `uvicorn app.main:app --host 0.0.0.0 --port $PORT`.
2. **`Dockerfile`:**
   - Base image `python:3.11-slim`, installs `requirements.txt`, copies `app/`, exposes port `8000`.
3. **`docker-compose.yml`:**
   - Defines `backend` and `frontend` (Nginx) services with persistent volume bindings.
4. **`deploy_server.sh`:**
   - Complete automated setup script for Ubuntu LTS servers configuring Python virtual environment, Systemd service, and Nginx reverse proxy with Let's Encrypt SSL.
5. **`firebase.json`:**
   - Configures Firebase Hosting for the frontend, rules for Firestore and Cloud Storage.

---

## 3. Comprehensive Endpoint Catalog Required by Frontend

| Endpoint Path | HTTP Method | Frontend Consumer | Purpose |
|---|:---:|---|---|
| `/` | `GET` | Health Check / Monitoring | Service info & active phase |
| `/health` | `GET` | Monitoring & Load Balancers | Liveness & database connectivity probe |
| `/ready` | `GET` | Cloud Deployments | Readiness & initialization probe |
| `/api/v1/auth/register` | `POST` | `login.html` | Register new user |
| `/api/v1/auth/login` | `POST` | `login.html` | Authenticate & issue JWT |
| `/api/v1/users/me` | `GET` | `app.js` | User profile & minute quota |
| `/api/v1/meetings` | `GET` | `app.js` | List meetings library |
| `/api/v1/meetings` | `POST` | `app.js` | Create meeting session |
| `/api/v1/meetings/{id}` | `PUT` | `app.js` | Update meeting details & transcript |
| `/api/v1/meetings/transcribe-audio`| `POST` | `app.js` (`#recordStudio`) | Neural speech transcription |
| `/api/v1/search/meetings` | `POST` | `app.js` (`#page-search`) | Multi-meeting hybrid BM25 + Vector search |
| `/api/v1/meetings/compare` | `POST` | `app.js` (`#page-compare`) | 7-category comparative delta analysis |
| `/api/v1/knowledge/documents` | `GET` | `app.js` (`#page-knowledge`) | List uploaded company documents |
| `/api/v1/knowledge/upload` | `POST` | `app.js` (`#page-knowledge`) | Upload and index PDF/DOCX for RAG |
| `/api/v1/knowledge/documents/{id}/reprocess`| `POST`| `app.js` (`#page-knowledge`) | Re-chunk and re-embed documents |
| `/api/v1/knowledge/documents/{id}`| `DELETE`| `app.js` (`#page-knowledge`) | Delete knowledge document |
| `/api/v1/memory` | `GET` | `app.js` (`#page-memory`) | Retrieve categorized meeting facts |
| `/api/v1/memory` | `POST` | `app.js` (`#page-memory`) | Store new organizational fact |
| `/api/v1/memory/{id}` | `PUT` | `app.js` (`#page-memory`) | Verify or update memory fact |
| `/api/v1/memory/{id}` | `DELETE`| `app.js` (`#page-memory`) | Purge memory record |
| `/api/v1/chat/ask` | `POST` | `app.js` (`#page-chat`) | Multi-source RAG question answering |
| `/api/v1/tasks` | `GET` | `app.js` (`#page-tasks`) | Action items list & Kanban board |
| `/api/v1/tasks` | `POST` | `app.js` (`#page-tasks`) | Create action item |
| `/api/v1/tasks/{id}` | `PUT` | `app.js` (`#page-tasks`) | Update task status & assignment |
| `/api/v1/tasks/{id}` | `DELETE`| `app.js` (`#page-tasks`) | Delete task |
| `/api/v1/tasks/{id}/comments` | `POST` | `app.js` (`#taskDetailModal`)| Add discussion thread comment |
| `/api/v1/tasks/{id}/history` | `GET` | `app.js` (`#taskDetailModal`)| Task transition audit log |
| `/api/v1/tasks/extract-from-meeting/{id}`| `POST`| `app.js` | Synthesize action items from transcript |
| `/api/v1/approvals` | `GET` | `app.js` (`#page-approvals`) | Pending AI action item review |
| `/api/v1/approvals/{id}/action` | `POST` | `app.js` (`#page-approvals`) | Approve or reject AI action item |
| `/api/v1/followups/generate` | `POST` | `app.js` (`#page-followups`) | Executive & Urdu follow-up emails |
| `/api/v1/notifications` | `GET` | `app.js` | Activity alerts & notifications |
| `/api/v1/notifications/{id}/read`| `PUT` | `app.js` | Mark notification read |
| `/api/v1/notifications/scan` | `POST` | `app.js` | Scan deadlines and alert team |
| `/api/v1/workflows` | `GET` | `app.js` (`#page-workflows`)| Automation workflow definitions |
| `/api/v1/workflows` | `POST` | `app.js` (`#page-workflows`)| Create workflow (Draft-Only guarded) |
| `/api/v1/workflows/{id}` | `PUT` | `app.js` (`#page-workflows`)| Update workflow |
| `/api/v1/workflows/{id}` | `DELETE`| `app.js` (`#page-workflows`)| Delete workflow |
| `/api/v1/workflows/{id}/execute` | `POST` | `app.js` (`#page-workflows`)| Trigger workflow execution |
| `/api/v1/workflows/{id}/executions`| `GET` | `app.js` (`#page-workflows`)| Execution logs |
| `/api/v1/integrations` | `GET` | `app.js` (`#page-integrations`)| Catalog of 10 enterprise providers |
| `/api/v1/integrations/{p}` | `GET` | `app.js` (`#integrationModal`)| Provider detail & scopes |
| `/api/v1/integrations/{p}/connect` | `POST` | `app.js` (`#integrationModal`)| Initiate OAuth / connect token |
| `/api/v1/integrations/{p}/callback`| `POST` | `app.js` | Complete OAuth with state & PKCE |
| `/api/v1/integrations/{p}/test` | `POST` | `app.js` (`#integrationModal`)| Connection diagnostic test |
| `/api/v1/integrations/{p}/disconnect`| `POST` | `app.js` (`#integrationModal`)| Disconnect provider |
| `/api/v1/integrations/{p}/sync` | `POST` | `app.js` (`#integrationModal`)| Trigger manual synchronization |
| `/api/v1/integrations/calendar/upcoming`| `GET`| `app.js` (`#dashboardUpcomingEventsList`)| Live upcoming events |
| `/api/v1/integrations/google-calendar/sync-task`| `POST`| `app.js` | Export task to Google Calendar |
| `/api/v1/integrations/gmail/create-draft`| `POST`| `app.js` | Create Gmail draft (Draft-Only) |
| `/api/v1/integrations/gmail/send` | `POST` | Security Barrier | Enforces HTTP 403 Forbidden |
| `/api/v1/integrations/google-drive/files`| `GET` | `app.js` | List Google Drive files |
| `/api/v1/integrations/google-drive/import`| `POST`| `app.js` | Ingest Drive document to RAG |
| `/api/v1/integrations/outlook/sync-task`| `POST`| `app.js` | Sync task to Outlook Calendar |
| `/api/v1/integrations/outlook/create-draft`| `POST`| `app.js` | Create Outlook email draft |
| `/api/v1/integrations/outlook/send`| `POST` | Security Barrier | Enforces HTTP 403 Forbidden |
| `/api/v1/integrations/jira/projects`| `GET` | `app.js` | Discover Jira Cloud projects |
| `/api/v1/integrations/jira/create-issue`| `POST`| `app.js` | Create Jira issue from task |
| `/api/v1/integrations/trello/boards`| `GET` | `app.js` | Discover Trello boards & lists |
| `/api/v1/integrations/trello/create-card`| `POST`| `app.js` | Create Trello card from task |
| `/api/v1/integrations/slack/channels`| `GET` | `app.js` | Discover Slack channels |
| `/api/v1/integrations/slack/post-summary`| `POST`| `app.js` | Post Block Kit summary to Slack |
| `/api/v1/integrations/notion/export-page`| `POST`| `app.js` | Export meeting notes to Notion |
| `/api/v1/integrations/webhooks/subscriptions`| `GET`| `app.js` | List active webhook subscriptions |
| `/api/v1/integrations/webhooks/subscriptions`| `POST`| `app.js` | Create webhook subscription |
| `/api/v1/integrations/webhooks/test-dispatch`| `POST`| `app.js` | Dispatch test signed webhook |
| `/api/v1/integrations/whatsapp/webhook`| `GET` | Meta Cloud API | Webhook verification handshake |
| `/api/v1/integrations/whatsapp/webhook`| `POST`| Meta Cloud API | Inbound voice note webhook |

---

## 4. Architectural Gap Analysis for Cloud Staging

1. **Localhost Dependency:**
   - `app.js` currently contains `window.MEETMIND_BACKEND_URL || 'http://localhost:8000/api/v1'`, meaning hosted preview users on mobile or external laptops attempt to hit `localhost:8000` on their own local machine, resulting in connection refusal.
2. **Relative Route Fallback:**
   - Several integration calls in `app.js` invoke `/api/v1/integrations...` relatively. On Firebase Hosting without an API proxy or central base URL helper, these requests fetch `index.html` as a 200 OK HTML payload, corrupting JSON parsing.
3. **Missing Health & Readiness Probes:**
   - Production cloud orchestrators require dedicated `/health` and `/ready` probes that verify database connectivity and runtime responsiveness.
4. **Multi-Instance Database Concurrency:**
   - SQLite uses file-level locking (`database is locked` on concurrent writes). Multi-worker cloud deployments require **PostgreSQL** or a managed relational database for ACID row-level locking.
