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

