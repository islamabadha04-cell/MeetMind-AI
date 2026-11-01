# MEETMIND AI — MOBILE API INTEGRATION SPECIFICATION
**Version:** 6.0.0-mobile  
**Backend Target:** FastAPI v4.0.1+  
**Authentication Scheme:** Bearer JWT in `Authorization` header  

---

## 1. Centralized API Client Architecture

All mobile network requests are routed through `ApiClient` (`mobile_flutter/lib/core/services/api_client.dart`), guaranteeing:
1. **Dynamic Gateway Resolution:**
   * Checks `SecureStorageService.getCustomApiUrl()` for tester/developer overrides.
   * Defaults to active remote staging ingress: `https://supports-incidents-jail-admissions.trycloudflare.com/api/v1`.
   * Automatically strips trailing slashes to prevent malformed URI errors.
2. **Token Injection:**
   * Securely loads JWT access token from hardware-backed encrypted storage.
   * Injects `Authorization: Bearer <token>` and `User-Agent: MeetMind-Flutter-Mobile/6.0.0`.
3. **Structured Error Handling:**
   * **401 Unauthorized:** Prompts re-authentication, cleans invalid tokens.
   * **402 Usage Limit:** Warns user of missing cloud model credits (e.g. Ollama plans link).
   * **403 Forbidden:** Rejects unauthorized draft-sending or cross-tenant actions.
   * **404 Not Found:** Maps missing resource details.
   * **429 Rate Limit:** Applies backoff.
   * **SocketException:** Automatically intercepts network drops and routes payloads to the Offline Vault.

---

## 2. Endpoint Catalog

| Module | Method | Endpoint | Request Body | Description |
|---|---|---|---|---|
| **Auth** | POST | `/auth/login` | `{"email", "password"}` | Issues JWT access token |
| **Auth** | POST | `/auth/register` | `{"email", "password", "full_name"}` | Registers user |
| **User** | GET | `/users/me` | None | Retrieves authenticated user profile |
| **Meetings** | GET | `/meetings` | None | Lists user's meetings |
| **Meetings** | GET | `/meetings/{id}` | None | Retrieves detailed meeting transcript & summary |
| **Upload** | POST | `/meetings/upload` | Multipart (`audio`, `title`, `category`) | Uploads audio recording stream with `X-Idempotency-Key` |
| **Tasks** | GET | `/tasks` | None | Lists action items |
| **Tasks** | POST | `/tasks` | `{"title", "description", "assignee", "deadline", "priority", "project"}` | Creates new task (synced to web) |
| **Tasks** | PUT | `/tasks/{id}` | `{"status"}` | Updates task progress (`pending`, `completed`) |
| **Search** | POST | `/search/meetings` | `{"query", "limit"}` | Performs semantic hybrid vector search |
| **Memory** | GET | `/memory` | None | Retrieves persistent categorized facts |
| **Chat** | POST | `/search/chat` | `{"message", "history"}` | Multi-Source RAG with Gemini |
| **Ollama** | POST | `/ai/ollama/chat` | `{"prompt"}` | Cloud Ollama call (Server-side API key guardrail) |
| **Workspaces**| GET | `/workspaces` | None | Lists authorized team workspaces |
| **Notes** | GET | `/workspaces/{id}/notes`| None | Fetches team collaborative notes |
| **Notes** | PUT | `/workspaces/{id}/notes/{note_id}` | `{"title", "content", "version"}` | Updates note with optimistic concurrency check |
| **Invites** | POST | `/workspaces/{id}/invites` | `{"email", "role"}` | Generates team invitation token |
| **Providers**| GET | `/integrations/providers` | None | Catalogs 10 third-party integration connectors |

---

## 3. Multipart Audio Upload Protocol

When uploading an audio recording from the device:
```http
POST /api/v1/meetings/upload HTTP/1.1
Host: supports-incidents-jail-admissions.trycloudflare.com
Authorization: Bearer <jwt_token>
User-Agent: MeetMind-Flutter-Mobile/6.0.0
X-Idempotency-Key: e1a3f69b-82a1-432a-bc91-2fa89b25f612
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary

------WebKitFormBoundary
Content-Disposition: form-data; name="title"

Sprint 15 Architecture Review
------WebKitFormBoundary
Content-Disposition: form-data; name="audio"; filename="meetmind_rec_e1a3f69b.m4a"
Content-Type: audio/mp4

[RAW_AUDIO_STREAM_BYTES]
------WebKitFormBoundary--
```
The server validates the audio payload, calculates duration, generates AI transcripts and summaries, and returns the persisted `meeting_id`.
