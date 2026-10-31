# MeetMind AI — Official Product Changelog
All notable changes and architectural upgrades to MeetMind AI are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [4.0.0] - 2026-10-31 (PHASE 4 COMPLETED & SECURITY AUDITED: THIRD-PARTY INTEGRATIONS ECOSYSTEM)

### Security Hardening & Audit Corrections
- **Persistent Shared OAuth Nonce Storage:**
  - Replaced process-local memory with persistent `oauth_nonces` database table.
  - Implemented atomic SQL transaction updates (`UPDATE ... WHERE consumed = 0`) to prevent concurrent replay attacks across multiple worker instances and threads.
  - State nonces survive backend process restarts and multi-container scaling.
  - Securely associates RFC 7636 PKCE `code_verifier` with its transaction and verifies it during callback.
- **Gmail & Workflow Server-Side Draft-Only Lock:**
  - Enforced strict server-side prohibition of `users.messages.send` and `users.drafts.send`.
  - Workflow builder (`create_workflow`) and execution engine (`execute_workflow`) actively validate actions via `_validate_workflow_actions`, blocking any automated email send with HTTP 403 Forbidden.
- **WhatsApp Webhook Cryptographic Verification:**
  - Validates Meta `X-Hub-Signature-256` HMAC-SHA256 signature computed over raw request body bytes; rejects missing or tampered signatures with HTTP 401.
  - Added duplicate message detection via `processed_webhook_messages` table to prevent re-processing.
  - Added unauthorized sender allowlist filtering and 24-hour expired media detection.
- **AES-256-GCM AEAD Key Management (HKDF-SHA256):**
  - Implemented HKDF-SHA256 key derivation (RFC 5869) with version-bound salts.
  - Fresh 12-byte initialization nonces per encryption and 128-bit authentication tag verification.
  - Ciphertext version tagging (`gcm:v1:...`) with key rotation capability (`rotate_token_encryption`).
  - Tampered ciphertext or tag mismatch fails securely.
- **Preview Channel Release:**
  - Deployed to Firebase Hosting preview channel `preview-v4` (Version: `efaeaf4cb8f3c923`).
  - Production website (`https://meetmind-ai-74519.web.app`) remains untouched and safe.
- **Expanded Test Suite:**
  - 44/44 passing Pytest backend tests (up from 35).
  - 103/103 passing Headless Chrome browser CDP tests.

### Added
- **Unified Integration Center Hub (`#page-integrations`):**
  - Command center managing connections across 10 major enterprise platforms: Google Calendar, Gmail, Google Drive, Microsoft Outlook, Jira Cloud, Trello, Slack, Notion, Zapier, and WhatsApp Business.
  - Granular category filtering, connection status pills (`Connected`, `Not Connected`, `Disconnected`), account email metadata, and last sync timestamps.
  - Interactive Integration Settings Modal (`#integrationModal`) with least-privilege permission inspection, diagnostic connection testing, and disconnect controls.
- **Enterprise OAuth 2.0 Security Architecture:**
  - AES-256 server-side token encryption for all access and refresh tokens.
  - State token validation (`HMAC-SHA256` with 15-minute TTL) preventing CSRF and replay attacks.
  - Zero token leakage: credentials are never sent to browser JavaScript or stored in client-readable Firestore records.
- **Dynamic Dashboard Calendar (Eliminated Static Placeholders):**
  - Replaced hardcoded demo upcoming meetings on the dashboard with a dynamic container (`#dashboardUpcomingEventsList`) populated from real calendar events and active task deadlines via `/api/v1/integrations/calendar/upcoming`.
  - Clean empty state with quick link to connect calendars.
- **Google Workspace Bi-Directional Integration:**
  - **Google Calendar:** Approved task synchronization with deadline and description mapping; ID tracking via `external_entity_mappings`.
  - **Gmail:** Follow-up and MoM email draft generation using restricted `gmail.compose` scope (**Strictly Draft-Only: zero automated message sending**).
  - **Google Drive:** Authorized file browser and direct document ingestion into Knowledge Base RAG chunks.
- **Microsoft 365 (Microsoft Graph) Integration:**
  - Synchronizes task deadline events to Microsoft Outlook Calendar.
  - Creates reviewable email drafts in user's Outlook mailbox via delegated permissions.
- **Jira Cloud & Trello Task Dispatchers:**
  - **Jira Cloud:** Maps meeting tasks to Jira issues with priority translation (`urgent` -> `Highest`, etc.) and project discovery.
  - **Trello:** Converts approved tasks into Trello cards on boards and lists.
- **Slack & Notion Direct Workspace Publishing:**
  - **Slack:** Posts formatted Block Kit executive summaries, decisions, and action items directly to selected channels.
  - **Notion:** Exports structured meeting notes with executive summaries and interactive checklist blocks into Notion databases.
- **Zapier & HMAC-SHA256 Webhook Engine:**
  - Event registry supporting 8 core business events (`meeting.completed`, `task.approved`, `deadline.approaching`, etc.).
  - Cryptographic payload signing via `X-MeetMind-Signature` (`t={timestamp},v1={hash}`).
  - Delivery logging and retry tracking in `webhook_deliveries`.
- **WhatsApp Business Voice Note Processing (Meta Cloud API):**
  - Webhook verification challenge handling (`hub.challenge`).
  - Inbound audio message ingestion, media download, automated transcription, and synthesis into structured meeting notes and tasks.
- **Automated Verification Suite:**
  - 35/35 passing Pytest backend tests across all modules.
  - 103/103 passing Headless Chrome browser CDP tests with 0 console errors and 0 uncaught exceptions.
  - 100% passing multi-tenant isolation tests.
  - Comprehensive documentation suite: `PHASE_4_AUDIT.md`, `PHASE_4_ARCHITECTURE.md`, `INTEGRATION_CENTER.md`, `OAUTH_SECURITY.md`, `GOOGLE_WORKSPACE_INTEGRATION.md`, `MICROSOFT_GRAPH_INTEGRATION.md`, `JIRA_TRELLO_INTEGRATION.md`, `SLACK_NOTION_INTEGRATION.md`, `WHATSAPP_BUSINESS_SETUP.md`, `WEBHOOK_API.md`, `PHASE_4_FEATURE_STATUS.md`, `PHASE_4_TEST_REPORT.md`.

---

## [3.0.0] - 2026-10-31 (PHASE 3 COMPLETED: AI PRODUCTIVITY & SMART TASK AUTOMATION)

### Added
- **AI Action Item Extraction Engine (Module 1):**
  - Advanced action item extraction endpoint (`/api/tasks/extract` and `AIService.extract_action_items_advanced`) parsing meeting transcripts for explicit commitments, assignments, deadlines, and urgency.
  - Strict evidence quotes with timestamps linking directly to spoken sentences.
  - Zero-hallucination constraint: strictly marks assignees or deadlines as `"Unassigned"` / `None` unless verbatim spoken proof exists.
  - Dual confirmation states: `suggested` vs `confirmed`.
- **Smart Task Management System (Module 2):**
  - Upgraded Tasks dashboard with 5-stage Kanban board: `pending`, `in_progress`, `completed`, `overdue`, and `cancelled`.
  - Multi-view presentation switcher: 5-column Kanban Board, Tabular List View, and Interactive Calendar Timeline View.
  - Real-time KPI summary bar displaying Total Tasks, In Progress, Completed, Overdue, and Pending Approvals with one-click quick filters.
  - Interactive Task Details Modal (`#taskDetailsModal`) featuring complete metadata editing, real-time threaded discussion comments (`TaskComment`), and immutable audit history log (`TaskHistory`).
- **AI Follow-Up Generator (Module 3):**
  - Dedicated Follow-Ups workspace (`#page-followups`) supporting 4 specialized business communication templates:
    - *Client Update:* Professional project status report.
    - *Payment Reminder:* Courteous financial reminder with Pakistani banking details (JazzCash, Easypaisa, Raast).
    - *Deadline Alert:* Project delivery notice highlighting critical milestone commitments.
    - *Executive Minutes of Meeting (MoM):* High-level summary of decisions and open questions.
  - Multilingual support: Generates drafts in English, Urdu Nastaliq (اردو), and Roman Urdu.
  - **Strict Draft-Only Mode:** All generated messages are output as drafts to prevent accidental or unauthorized automated sending.
- **Smart Notifications & Deadline Radar (Module 4):**
  - Real-time deadline monitoring and notification engine (`/api/notifications/scan`).
  - Automatically identifies overdue tasks and upcoming deadlines (within 24–48 hours).
  - Built-in notification deduplication to avoid alert spamming.
  - In-app notification center with read status management (`/api/notifications/{id}/read`).
- **Manager Task Approval System (Module 5):**
  - Dedicated Approvals page (`#page-approvals`) for team leads and managers.
  - Review queue for AI-suggested tasks requiring human verification.
  - 1-Click Approve, Reject (with reason), and Modify workflows (`/api/approvals/{id}/action`).
  - Automatic task promotion upon approval.
- **AI Workflow Builder & Multi-Step Automations (Module 6):**
  - Dedicated Workflows page (`#page-workflows`) with a visual multi-step pipeline designer.
  - Trigger support: `meeting_ended`, `task_created`, `deadline_approaching`, `manual`.
  - Multi-step action execution chains: `extract_action_items`, `generate_follow_up`, `notify_assignees`, `log_audit`.
  - Immutable execution history and status logging (`/api/workflows/{id}/execute`).
- **Phase 2 Audit Remediation & Hardening:**
  - Integrated dense vector embeddings using Gemini `text-embedding-004` (with fallback to 64-dim normalized projection) and Reciprocal Rank Fusion ($k=60$) in `search_service.py`.
  - Added document reprocessing endpoint (`/api/knowledge/documents/{doc_id}/reprocess`).
  - Implemented strict JWT Bearer authentication with user-scoped isolation in FastAPI endpoints.
  - Hardened `firestore.rules` for all Phase 2 & 3 collections (`tasks`, `knowledge_documents`, `meeting_memories`, `notifications`, `workflows`, `approval_requests`).
- **Automated Verification:**
  - 22/22 Passing Pytest unit and integration tests across backend modules.
  - 92/92 Passing Headless Chrome browser CDP test suite with 0 console errors and 0 uncaught exceptions.
  - 7/7 Passing multi-tenant isolation tests verifying cross-account data blocking.
  - Master technical documentation: `PHASE_2_FINAL_AUDIT.md`, `PHASE_3_ARCHITECTURE.md`, `TASK_MANAGEMENT_SCHEMA.md`, `WORKFLOW_AUTOMATION.md`, `PHASE_3_FEATURE_STATUS.md`, `PHASE_3_TEST_REPORT.md`.

---

## [2.0.0] - 2026-10-31 (PHASE 2 COMPLETED)

### Added
- **Multi-Meeting Semantic Search Engine (Module 1):**
  - Dedicated AI Meeting Search view (`#page-search`) supporting complex natural queries ("payment delays", "project budget", "delivery deadline changed").
  - Hybrid retrieval architecture combining lexical BM25 token overlap with dense semantic embeddings and conceptual synonym expansion.
  - Reciprocal Rank Fusion (RRF with $k=60$) ranking hits across all accessible meetings.
  - Granular date range, speaker, project, and meeting filters.
  - 1-Click "Open Meeting & Seek" button that launches the target meeting, jumps to the exact diarized turn, and aligns audio playback.
  - AI Cross-Meeting synthesis banner providing chronological summaries across multiple matching sessions.
- **Meeting Comparison Matrix (Module 2):**
  - Dedicated Meeting Comparison view (`#page-compare`) with dual-meeting selectors and delta analyzer.
  - 7-category comparative matrix: Objectives, Decisions, Budget, Tasks, Deadlines, Risks, and Pending Issues.
  - Strict zero-hallucination rule: any missing data point strictly outputs `"Not Mentioned"`.
  - Comprehensive Markdown and PDF export options for comparative reports.
- **Company Knowledge Base (RAG) (Module 3):**
  - Dedicated Knowledge Base view (`#page-knowledge-base`) featuring drag-and-drop file upload.
  - Multi-format ingestion supporting PDF (`pypdf`), Word DOCX (`python-docx`), CSV, and TXT.
  - Sliding-window text chunker (250 words per chunk with 40-word overlap).
  - Real-time document lifecycle status indicators: `Uploaded`, `Processing`, `Indexed`, and `Failed`.
- **Persistent Meeting Memory Engine (Module 4):**
  - Dedicated Persistent Memory view (`#page-memory`) with filterable category tabs and memory card grid.
  - 10 operational categories: Client Preferences, Budget Discussions, Technology Choices, Deadlines, Team Responsibilities, Recurring Problems, Important Agreements, Unresolved Questions, Critical Risks, Strategic Goals.
  - Confidence scoring ($0.0 - 1.0$), source meeting linking, and source transcript timestamp reference.
  - User verification workflow and audit-trailed JSON revision history preserving all prior states.
- **Universal Multi-Source Knowledge AI Chat (Module 5):**
  - Upgraded Ask AI interface (`#page-chat`) featuring a Multi-Source Scope Switcher:
    - *My Meetings:* Audio transcripts & meeting turns.
    - *Company Knowledge:* Indexed contracts, PRDs, and manuals.
    - *Universal:* Cross-source retrieval combining meetings and documents.
  - Clickable citation tags linking directly to audio timestamps `[Meeting @ 04:15]` or document pages `[Doc, Page 3]`.
  - Strict Anti-Hallucination Guardrail: system unconditionally refuses to speculate, responding with *"I could not find sufficient information in your connected meetings or company documents..."* when evidence is missing.
  - Full multilingual fluency in English, Urdu Nastaliq (اردو), and Roman Urdu.
- **Comprehensive Verification & Documentation Suite:**
  - 10/10 passing Pytest backend tests (`backend/tests/test_phase2_api.py`).
  - 75/75 passing Headless Chrome CDP tests (`scratch/test_browser_suite.js`) with 0 console errors and 0 uncaught exceptions.
  - Technical manuals: `PHASE_2_ARCHITECTURE.md`, `SEMANTIC_SEARCH.md`, `RAG_IMPLEMENTATION.md`, `MEETING_MEMORY_SCHEMA.md`, `VECTOR_SEARCH_SETUP.md`, `PHASE_2_TEST_REPORT.md`.

---

## [1.2.0] - 2026-10-31

### Added
- **Pakistani Localized Payment Gateways:** Dedicated tabbed checkout modal for JazzCash (`0312-5819717`), Easypaisa (`0312-5819717`), and Raast Instant Settlement with 1-click clipboard copy, instant Pro activation, and verified transaction alerts.
- **Audio-to-Transcript Synchronized Playback:** Sticky audio player bar in meeting details with interactive timestamps (`seekToTranscriptTime`). Clicking any speaker line instantly jumps audio to that exact moment and visually highlights the active spoken turn.
- **Executive Minutes of Meeting (MoM) PDF Export:** Automated corporate PDF generation via jsPDF featuring branded headers, metadata tables, executive callout blocks, key decisions, and tabular action items.
- **Universal Calendar Sync:** Two-way meeting and task calendar export supporting universal `.ics` download (Apple Calendar, Microsoft Outlook, Thunderbird) and instant 1-click Google Calendar web event creation.
- **Automated Headless CDP Test Suite:** 46-point automated browser verification suite testing DOM elements, navigation tabs, modal interactions, audio timeline math, and payment workflows.
- **Zero-Latency Guest Evaluation Access:** Instant one-click demo sandbox in `login.html` allowing rapid stakeholder evaluation without sign-up barriers.
- **Master Documentation Suite:** Published comprehensive technical architecture manuals:
  - `PROJECT_AUDIT.md`: System architecture, asset inventory, cost analysis.
  - `MASTER_ROADMAP.md`: Multi-phase roadmap covering Modules A through J.
  - `FEATURE_STATUS.md`: Feature verification matrix.
  - `DATABASE_SCHEMA.md`: Firestore & SQL entity relationship schemas.
  - `API_DOCUMENTATION.md`: REST endpoints & Firebase service interfaces.
  - `SECURITY_GUIDELINES.md`: Firestore security rules, zero-trust policies, and consent standards.
  - `DEPLOYMENT_GUIDE.md`: Production deployment procedures for Firebase & Cloud Run.

### Changed
- Refactored `firestore.rules` to enforce strict user-scoped row-level security (`resource.data.userId == request.auth.uid`), preventing unauthorized cross-tenant reads or updates.
- Hardened `app.html` against potential null references during dynamic tab transitions.
- Enhanced navigation bar responsiveness on mobile viewports.

---

## [1.1.0] - 2026-10-27

### Added
- FastAPI backend microservices integrating Gemini 2.5 Flash and Gemini 1.5 Flash models.
- Multimodal binary audio transcription endpoint (`/api/v1/meetings/transcribe-audio`).
- Cross-meeting conversational RAG intelligence endpoint (`/api/v1/chat/ask`).
- Task management REST API with assignee, priority, and deadline tracking.

### Fixed
- Resolved CORS headers for local and hosted origins.
- Added automatic SQLite database seeding for demo environments.

---

## [1.0.0] - 2026-10-20

### Added
- Initial release of MeetMind AI web application.
- Modern violet-themed responsive dashboard with meeting cards and stats counters.
- Firebase Authentication with Google Sign-In and Email/Password.
- Client-side Web Speech API live microphone transcription.
- Meeting categorization and color tinting system.
