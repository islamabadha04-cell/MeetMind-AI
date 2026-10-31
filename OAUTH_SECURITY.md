# 🔒 MeetMind AI — OAuth Security & Credential Architecture

---

## 1. Security Architecture Principles

MeetMind AI adheres to RFC 6749 (The OAuth 2.0 Authorization Framework) and RFC 7636 (Proof Key for Code Exchange):

1. **Server-Side Token Storage:**
   - Client applications (browser JavaScript, mobile clients) **never receive raw OAuth access or refresh tokens**.
   - Tokens are stored exclusively in backend database tables and encrypted using AES-256 via `cryptography.fernet`.
2. **Deterministic Salted Secret Encryption:**
   - The encryption key is derived deterministically from the backend `SECRET_KEY` using SHA-256 and urlsafe base64 encoding.
3. **State Token Validation (CSRF Prevention):**
   - Every OAuth authorization URL includes a cryptographically signed state token:
     `base64(user_id:provider:timestamp:random_hex:hmac_signature)`
   - State tokens have a strict 15-minute Time-To-Live (TTL).
   - The callback endpoint verifies the user ID and HMAC signature before exchanging the authorization code.
4. **Least-Privilege Authorization Scopes:**
   - MeetMind AI requests the narrowest possible scopes:
     - **Gmail:** `https://www.googleapis.com/auth/gmail.compose` (create drafts only; cannot read emails or search inbox).
     - **Google Drive:** `https://www.googleapis.com/auth/drive.readonly` (cannot edit or delete user files).
     - **Google Calendar:** `https://www.googleapis.com/auth/calendar.events` (cannot manage other calendars or sharing permissions).
     - **Microsoft Graph:** `Calendars.ReadWrite`, `Mail.ReadWrite` (create calendar items and drafts).
     - **Slack:** `chat:write`, `channels:read` (post messages to permitted channels).
5. **Safe Data Purging on Disconnect:**
   - When a user disconnects an integration, both access and refresh tokens are immediately overwritten with empty strings.

---

## 2. OAuth Callback Verification Pipeline

```
User clicks "Connect" 
  ──> GET /api/v1/integrations/{provider}/connect
  ──> Generates state token: HMAC-SHA256(user_id + provider + timestamp + random_hex)
  ──> Returns authorization URL
  ──> User grants consent on Provider Consent Screen
  ──> Provider redirects to callback URL with ?code=...&state=...
  ──> POST /api/v1/integrations/{provider}/callback
  ──> Backend verifies state token signature, timestamp TTL, and current user
  ──> Server-to-server POST to provider /token endpoint
  ──> Encrypts access_token & refresh_token with AES-256
  ──> Saves to 'integrations' table with status="connected"
  ──> Returns sanitized IntegrationResponse (Zero raw tokens in response)
```

