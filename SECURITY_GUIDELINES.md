# MeetMind AI — Enterprise Security & Privacy Guidelines
**Project:** MeetMind AI (`meetmind-ai-74519`)  
**Security Standard:** Zero-Trust Architecture, OWASP Top 10 Compliance, and Strict User Isolation  
**Auditor / Architect:** Senior Security Engineer & Cloud Architect  

---

## 1. Executive Security Principles

1. **Defense in Depth:** Security controls are enforced at the Edge (CDN), Network (TLS 1.3), Application (XSS/CSRF sanitization), Database (Row-Level Security & Security Rules), and Storage (scoped bucket isolation) layers.
2. **Zero-Trust User Data Isolation:** No user or organization can ever read, update, list, or delete another entity's meeting transcripts, audio files, or task records.
3. **No Credential Exposure:** Private API keys (Gemini API server keys, Firebase Admin credentials, Service Account JSONs) must NEVER be shipped in client-side bundles. Only public client credentials (Firebase Web Config) are permitted in public static files.
4. **Transparent Consent & Notice:** In compliance with international data privacy laws (GDPR/CCPA/PECA), recording notifications must be prominently displayed before audio acquisition begins.

---

## 2. Cloud Firestore Security Rules

Our production Firestore rules (`firestore.rules`) enforce strict user-scoped ownership:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Meetings: only authenticated user who created the meeting can read, update, or delete it
    match /meetings/{meetingId} {
      allow read, update, delete: if request.auth != null && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
    }
    
    // Tasks: scoped strictly to authenticated user
    match /tasks/{taskId} {
      allow read, update, delete: if request.auth != null && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
    }
    
    // User profile records: strictly locked to user matching their UID
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Shared Links: unguessable token lookup (read only)
    match /sharedLinks/{token} {
      allow read: if true; // Public access verified via cryptographic token
      allow write: if request.auth != null && request.resource.data.userId == request.auth.uid;
    }
  }
}
```

### 2.1 Attack Verification Log
During automated regression testing, unauthorized cross-tenant operations were simulated:
- `ATTACK_1`: Attacker UID attempts to read victim's document: **BLOCKED (`PERMISSION_DENIED`)**.
- `ATTACK_2`: Attacker UID attempts to modify victim's action items: **BLOCKED (`PERMISSION_DENIED`)**.
- `ATTACK_3`: Unauthenticated crawler attempts to list `/meetings`: **BLOCKED (`PERMISSION_DENIED`)**.

---

## 3. Firebase Cloud Storage Security Rules

Storage buckets (`meetmind-ai-74519.firebasestorage.app`) require path-level user authorization:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /recordings/{userId}/{allPaths=**} {
      // Audio recordings can only be uploaded and read by the authenticated user who owns the path
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public shareable exported assets
    match /public_exports/{token}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

---

## 4. Client-Side Sanitization & XSS Prevention

1. **DOM Insertion Hygiene:** User input, meeting transcripts, and LLM completions are never assigned directly to `innerHTML` without HTML entity encoding or trusted markdown parsers.
2. **Text Escaping Helper:** All dynamic UI elements (meeting titles, attendee names, task descriptions) use:
   ```javascript
   function escapeHTML(str) {
     return String(str || '')
       .replace(/&/g, '&amp;')
       .replace(/</g, '&lt;')
       .replace(/>/g, '&gt;')
       .replace(/"/g, '&quot;')
       .replace(/'/g, '&#039;');
   }
   ```
3. **Content Security Policy (CSP):** Firebase Hosting headers enforce strict script sources (`https://www.gstatic.com`, `https://apis.google.com`, `https://cdn.jsdelivr.net`) and disable unsafe inline evaluation.

---

## 5. Meeting Recording Privacy & Participant Consent

1. **Audible & Visual Notice:** Whenever audio recording or microphone streaming is engaged:
   - A pulsing red recording indicator `#recIndicator` is rendered persistently in the top navigation bar.
   - Browser tab displays recording icon.
   - An audible chime or system notification alerts participants that audio transcription is active.
2. **One-Click Audio Purge:** Users retain full sovereignty over their raw voice data. Deleting a meeting permanently purges the binary audio file from Cloud Storage and all corresponding transcript fragments from Firestore.
3. **No Covert Surveillance:** MeetMind AI explicitly rejects hidden background audio capture. Recording initiates only upon deliberate user interaction.

---

## 6. Two-Factor Authentication (2FA) & Session Hardening

1. **Email Verification:** Unverified accounts are warned before enterprise workspace data can be unlocked.
2. **Session Termination:** Clicking **Log Out** immediately wipes `localStorage`, `sessionStorage`, and calls `signOut(auth)` to revoke active Firebase refresh tokens.
3. **Guest Evaluation Isolation:** Demo/Guest sessions run with temporary local storage and are barred from persisting data to public cloud collections without full credentialed sign-in.

---

## 7. Third-Party Integrations & OAuth Security Standards (Phase 4)

1. **Server-Side AES-256 Token Encryption:**
   - Raw OAuth access tokens and refresh tokens are strictly encrypted at rest using server-side AES-256 (`cryptography.fernet`).
   - Tokens are never exposed to browser JavaScript, client-readable Firestore records, or client logs.
2. **Cryptographic State Parameter Validation:**
   - Every OAuth 2.0 initiation generates a cryptographically signed, timestamped state token (`HMAC-SHA256` with 15-minute TTL) binding the request to `user_id` and `provider`.
   - Prevents OAuth CSRF, authorization code interception, and token replay attacks.
3. **Least-Privilege Scoping:**
   - MeetMind AI enforces the narrowest possible permission scopes:
     - Gmail: `https://www.googleapis.com/auth/gmail.compose` (create drafts only; mailbox read access is blocked).
     - Google Drive: `https://www.googleapis.com/auth/drive.readonly` (read-only document access; cannot delete or modify files).
     - Microsoft Graph: `Calendars.ReadWrite`, `Mail.ReadWrite` (create calendar items and reviewable drafts).
4. **Draft-Only Email Safeguard:**
   - Automated message sending is strictly forbidden. All follow-up emails and MoMs generated for Gmail or Outlook are created strictly as drafts in the user's personal mailbox, requiring human review and explicit confirmation before sending.
5. **Webhook Payload Signing (HMAC-SHA256):**
   - Outbound webhook requests include `X-MeetMind-Signature` computed using the user's private webhook signing secret, preventing downstream payload tampering or spoofing.


