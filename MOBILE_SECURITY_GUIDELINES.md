# MEETMIND AI — MOBILE SECURITY & COMPLIANCE GUIDELINES
**Version:** 6.0.0-mobile  
**Standard:** Enterprise Mobile Security (OWASP MASVS / SOC2 Compliance)  

---

## 1. Secrets Management & Hardware Keystores

### 1.1 Token Storage
* Plaintext storage (`SharedPreferences` or `NSUserDefaults`) is **STRICTLY PROHIBITED** for sensitive tokens.
* All JWT access tokens, refresh tokens, and user credentials are encrypted using **`FlutterSecureStorage`**:
  * **Android:** Uses Android Keystore with `EncryptedSharedPreferences` (AES-256-GCM / RSA-2048 master keys).
  * **iOS:** Uses Apple Keychain Services with `kSecAttrAccessibleAfterFirstUnlock`.

### 1.2 Zero Hardcoded Secrets Rule
* Under no circumstances may API keys (`OPENAI_API_KEY`, `GEMINI_API_KEY`, `OLLAMA_API_KEY`, `SECRET_KEY`) be bundled into the Flutter application bundle, Dart code, or mobile assets.
* Reverse-engineering mobile binaries (decompiling APKs or IPAs) must reveal zero server credentials.

---

## 2. Server-Side AI Guardrails (Ollama & Gemini)

### 2.1 Provider Segregation & Credential Protection
* The mobile application **never** talks directly to `https://ollama.com` or `https://generativelanguage.googleapis.com`.
* All AI requests are mediated through the FastAPI backend (`/api/v1/search/chat` and `/api/v1/ai/ollama/chat`).
* The mobile client cannot manipulate backend prompts to bypass model restrictions or extract backend environment secrets.

### 2.2 Error Containment
* If an Ollama call fails with HTTP 402 (Missing Credits) or HTTP 429 (Rate Limit), the error is caught cleanly by `MeetingService.askAiChat` and surfaced as a clear informational notice with an actionable upgrade link (`https://ollama.com/plans`), preventing cryptic crashes or raw stack traces.

---

## 3. Data Protection at Rest & in Transit

### 3.1 Network Transport Security
* All network communication is enforced over **TLS 1.3 / HTTPS**.
* Plaintext HTTP connections are rejected by default in release builds via Android Network Security Config and iOS App Transport Security (`NSAppTransportSecurity`).

### 3.2 Offline Audio Vault Protection
* Local meeting audio files are stored in the application's private sandboxed document directory (`getApplicationDocumentsDirectory()`), preventing third-party apps from reading meeting recordings.
* Every recorded audio file has an accompanying SHA-256 integrity checksum verified prior to cloud dispatch.

---

## 4. Multi-Tenant Role-Based Access Control (RBAC)

* The mobile UI reflects user roles (`Owner`, `Admin`, `Manager`, `Editor`, `Viewer`), but **never relies solely on frontend checks**.
* Every action (e.g. inviting teammates, modifying notes, deleting meetings) is re-authenticated and validated server-side in `backend/app/main.py`.
* Cross-tenant access across organizations or outside users returns HTTP 403 Forbidden.

