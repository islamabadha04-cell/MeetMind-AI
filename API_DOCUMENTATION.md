# MeetMind AI — Complete API Documentation
**Project:** MeetMind AI  
**Production Host:** `https://meetmind-ai-74519.web.app`  
**Backend API Base URL:** `http://localhost:8000/api/v1` (or production cloud run backend)  
**Authentication Standard:** Firebase JWT Bearer Tokens / OAuth 2.0 / HS256 JWT  

---

## 1. Overview & Protocol Architecture

MeetMind AI provides two high-performance API interfaces:
1. **Frontend Client SDK (`window.MeetMindFirebase`):** Direct authenticated communication with Firebase Auth, Firestore real-time listener sockets, and Cloud Storage buckets.
2. **RESTful Backend API (FastAPI):** High-throughput Python microservices handling Gemini 2.5 Flash multimodal transcription, diarization synthesis, task extraction, and Cross-Meeting Semantic RAG.

---

## 2. FastAPI REST Endpoints

### 2.1 Authentication & Profile

#### `POST /api/v1/auth/register`
Creates a new user account with hashed password and returns an initial JWT bearer token.
- **Request Body:**
  ```json
  {
    "email": "user@example.com",
    "password": "SecurePassword123!",
    "full_name": "Hasnain Ali"
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "access_token": "eyJhbGciOiJIUzI1NiIsIn...",
    "token_type": "bearer",
    "user_name": "Hasnain Ali",
    "plan": "Pro"
  }
  ```

#### `POST /api/v1/auth/login`
Authenticates existing credentials against bcrypt hashes.
- **Request Body:**
  ```json
  {
    "email": "user@example.com",
    "password": "SecurePassword123!"
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "access_token": "eyJhbGciOiJIUzI1NiIsIn...",
    "token_type": "bearer",
    "user_name": "Hasnain Ali",
    "plan": "Pro"
  }
  ```

#### `GET /api/v1/users/me`
Retrieves current profile metadata, quota balance, and active plan.
- **Response `200 OK`:**
  ```json
  {
    "id": 1,
    "email": "hasnain@example.com",
    "full_name": "Hasnain Ali",
    "avatar_url": "/assets/avatar.jpg",
    "plan": "Pro",
    "minutes_used": 42,
    "minutes_limit": 500,
    "is_active": true
  }
  ```

---

### 2.2 Meetings & AI Audio Processing

#### `GET /api/v1/meetings`
Fetches all meetings belonging to the authenticated user, ordered by creation date descending.
- **Response `200 OK`:**
  ```json
  [
    {
      "id": 1,
      "title": "Cowlar Sprint Review",
      "category": "Meetings",
      "tint": "lilac",
      "source_type": "audio_recording",
      "duration_seconds": 1840,
      "created_at": "2026-10-31T15:30:00Z",
      "summary": "Reviewed sprint delivery milestones and API latency.",
      "action_items": ["Finalize database migration", "Deploy PWA update"]
    }
  ]
  ```

#### `POST /api/v1/meetings`
Creates a meeting and automatically triggers the Gemini AI summarization pipeline.
- **Request Body:**
  ```json
  {
    "title": "Strategy Sync",
    "category": "General",
    "tint": "peach",
    "source_type": "manual",
    "duration_seconds": 1200,
    "transcript_text": "Speaker 1: Let's finalize the payment gateway options for Pakistan..."
  }
  ```
- **Response `200 OK`:** Complete meeting object with structured `executive_summary`, `action_items`, `decisions`, and `risks`.

#### `POST /api/v1/meetings/transcribe-audio`
Multimodal binary audio transcription endpoint powered by Gemini 2.5 Flash.
- **Headers:** `Content-Type: multipart/form-data`
- **Form Data:**
  - `file`: Raw audio blob (WAV, MP3, WebM, M4A, OGG)
  - `title` *(optional)*: Meeting title
- **Response `200 OK`:**
  ```json
  {
    "status": "success",
    "filename": "recording_20261031.webm",
    "title": "Client Discovery Call",
    "transcript": "Speaker 1: Hello everyone. Today we are launching the new portal...",
    "executive_summary": "Comprehensive briefing on product delivery dates and SLA agreements.",
    "key_points": ["Budget capped at 15,000 USD", "Launch slated for Q4"],
    "decisions": ["Approved JazzCash integration", "Selected Gemini Flash model"],
    "action_items": ["Send contract draft by Monday", "Set up staging tenant"],
    "risks": ["Potential API rate limits during peak hours"]
  }
  ```

---

### 2.3 Tasks & Deliverables

#### `GET /api/v1/tasks`
Lists all user tasks across meetings.
- **Query Params:** `status` (`pending` | `completed`), `priority` (`high` | `medium` | `low`)
- **Response `200 OK`:** Array of task objects.

#### `POST /api/v1/tasks`
Creates a standalone or meeting-linked action item.
- **Request Body:**
  ```json
  {
    "meeting_id": 1,
    "title": "Review Cowlar telemetry specifications",
    "assignee": "Hasnain",
    "deadline": "Friday, 5:00 PM",
    "priority": "high"
  }
  ```

---

### 2.4 Ask Your Meetings (RAG Chat)

#### `POST /api/v1/chat/ask`
Cross-Meeting Semantic Intelligence & Question Answering.
- **Request Body:**
  ```json
  {
    "question": "What budget decisions were finalized in our last client meeting?"
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "role": "assistant",
    "content": "In your 'Client Discovery Call' meeting, the budget was capped at 15,000 USD, and JazzCash/Raast were approved for localized payments.",
    "citations": [
      {
        "meeting_id": 1,
        "meeting_title": "Client Discovery Call",
        "snippet": "Budget capped at 15,000 USD; approved JazzCash."
      }
    ]
  }
  ```

---

## 3. Client Firebase Service Methods (`firebase-service.js`)

The web client provides unified wrappers through `window.MeetMindFirebase`:

| Method | Parameters | Returns | Description |
| :--- | :--- | :--- | :--- |
| `loginWithGoogle()` | None | `Promise<{success, user, error}>` | Launches Google OAuth popup |
| `loginWithEmail(email, pass)` | `email, password` | `Promise<{success, user, error}>` | Standard Firebase email auth |
| `registerWithEmail(email, pass)` | `email, password` | `Promise<{success, user, error}>` | New account signup |
| `resetPassword(email)` | `email` | `Promise<{success, error}>` | Dispatches password reset email |
| `logout()` | None | `Promise<{success}>` | Clears sessions, tokens, and storage |
| `saveMeeting(meetingData)` | `Object` | `Promise<{success, id, error}>` | Saves document in `meetings` collection |
| `subscribeMeetings(uid, cb)` | `userId, callback` | `UnsubscribeFunction` | Real-time reactive listener for user's meetings |
| `deleteMeeting(docId)` | `docId` | `Promise<{success, error}>` | Deletes meeting record |
| `saveTask(taskData)` | `Object` | `Promise<{success, id, error}>` | Creates record in `tasks` collection |
| `subscribeTasks(uid, cb)` | `userId, callback` | `UnsubscribeFunction` | Real-time listener for user's tasks |
| `deleteTask(docId)` | `docId` | `Promise<{success, error}>` | Deletes task |
| `uploadAudioBlob(blob, name)` | `Blob, fileName` | `Promise<{success, downloadUrl, error}>` | Uploads audio to user-scoped Cloud Storage |

---

## 4. Phase 4: Third-Party Integrations REST API

All Phase 4 endpoints require Bearer JWT authentication: `Authorization: Bearer <token>`.

### 4.1. Core Integration Hub
- `GET /api/v1/integrations`: Returns status, account email, scopes, and sync timestamps for all 10 providers.
- `GET /api/v1/integrations/{provider}`: Returns single provider status and configuration.
- `POST /api/v1/integrations/{provider}/connect`: Initiates connection (returns OAuth authorization URL or saves direct API key).
- `POST /api/v1/integrations/{provider}/callback`: Validates OAuth authorization code and state token; saves encrypted tokens.
- `POST /api/v1/integrations/{provider}/test`: Executes diagnostic test check against provider endpoint.
- `POST /api/v1/integrations/{provider}/disconnect`: Safely purges credentials and sets state to `disconnected`.
- `POST /api/v1/integrations/{provider}/sync`: Triggers manual synchronization.
- `GET /api/v1/integrations/calendar/upcoming`: Returns genuine upcoming events from calendar and active task deadlines (zero placeholders).

### 4.2. Provider-Specific Actions
- `POST /api/v1/integrations/google-calendar/sync-task`: Maps task deadline to Google Calendar event ID.
- `POST /api/v1/integrations/gmail/create-draft`: Creates reviewable email draft in Gmail (**Draft-Only mode**).
- `GET /api/v1/integrations/google-drive/files`: Lists authorized files in Google Drive.
- `POST /api/v1/integrations/google-drive/import`: Ingests Drive document into Knowledge Base RAG.
- `POST /api/v1/integrations/outlook/sync-task`: Syncs task deadline to Outlook Calendar.
- `POST /api/v1/integrations/outlook/create-draft`: Creates draft email in Microsoft Outlook.
- `GET /api/v1/integrations/jira/projects`: Lists Jira projects.
- `POST /api/v1/integrations/jira/create-issue`: Maps task to Jira issue with priority translation.
- `GET /api/v1/integrations/trello/boards`: Lists Trello boards.
- `POST /api/v1/integrations/trello/create-card`: Creates card on Trello board/list.
- `GET /api/v1/integrations/slack/channels`: Lists Slack channels.
- `POST /api/v1/integrations/slack/post-summary`: Posts Block Kit meeting summary to Slack.
- `POST /api/v1/integrations/notion/export-page`: Exports meeting notes and checklists to Notion.

### 4.3. Webhooks & WhatsApp
- `GET /api/v1/integrations/webhooks/subscriptions`: Lists webhook subscriptions for user.
- `POST /api/v1/integrations/webhooks/subscriptions`: Creates webhook subscription with auto-generated signing secret.
- `POST /api/v1/integrations/webhooks/test-dispatch`: Dispatches signed test event payload with `X-MeetMind-Signature` (HMAC-SHA256).
- `GET /api/v1/integrations/whatsapp/webhook`: Meta Cloud API verification challenge handler (`hub.challenge`).
- `POST /api/v1/integrations/whatsapp/webhook`: Meta Cloud API inbound audio/voice note webhook receiver.

