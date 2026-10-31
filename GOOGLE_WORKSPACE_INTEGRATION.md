# 🌐 Google Workspace Integration Guide (Calendar, Gmail, Drive)

---

## 1. Google Cloud Console Setup

To enable Google Workspace integrations in production:
1. Navigate to the **[Google Cloud Console](https://console.cloud.google.com/)** and select project `meetmind-ai-74519`.
2. Go to **APIs & Services > Library** and enable:
   - Google Calendar API v3
   - Gmail API v1
   - Google Drive API v3
3. Go to **APIs & Services > Credentials** and create an **OAuth 2.0 Client ID**:
   - **Application Type:** Web application
   - **Name:** MeetMind AI Workspace Integration
   - **Authorized JavaScript origins:** `https://meetmind-ai-74519.web.app`
   - **Authorized redirect URIs:**
     - `https://meetmind-ai-74519.web.app/api/v1/integrations/oauth/callback/google_calendar`
     - `https://meetmind-ai-74519.web.app/api/v1/integrations/oauth/callback/gmail`
     - `https://meetmind-ai-74519.web.app/api/v1/integrations/oauth/callback/google_drive`
     - `http://localhost:8080/api/v1/integrations/oauth/callback/google` (local dev)

---

## 2. Minimal Scopes & Justification

| Scope | Service | Purpose | Sensitivity Level |
| :--- | :--- | :--- | :--- |
| `https://www.googleapis.com/auth/calendar.events` | Google Calendar | Sync meeting action items & deadlines | Sensitive |
| `https://www.googleapis.com/auth/gmail.compose` | Gmail | Generate follow-up and MoM drafts (Draft-Only) | Sensitive |
| `https://www.googleapis.com/auth/drive.readonly` | Google Drive | Read documents selected by the user for RAG indexing | Restricted |

> [!IMPORTANT]
> **Google OAuth Verification:** When launching to external public users, Google Workspace applications requesting Sensitive or Restricted scopes require OAuth Verification and privacy policy submission. In Development/Testing mode, add testing accounts in the OAuth Consent Screen.

---

## 3. Endpoints & Workflows

### 3.1. Google Calendar Task Synchronization
- **Endpoint:** `POST /api/v1/integrations/google-calendar/sync-task`
- **Payload:** `{"task_id": 105, "calendar_id": "primary"}`
- **Behavior:** Reads task deadline, description, and assignee; creates or updates event; records ID in `external_entity_mappings`.

### 3.2. Gmail Draft Creation
- **Endpoint:** `POST /api/v1/integrations/gmail/create-draft`
- **Payload:** `{"recipient": "client@acme.com", "subject": "MoM Summary", "body": "..."}`
- **Behavior:** Encodes MIME payload; creates Gmail draft in the user's personal mailbox; **strictly draft-only (never auto-sends)**.

### 3.3. Google Drive File Ingestion
- **Endpoints:**
  - `GET /api/v1/integrations/google-drive/files`: Lists authorized files.
  - `POST /api/v1/integrations/google-drive/import`: Downloads file, chunks text, generates embeddings, and indexes into Knowledge Base RAG.

