# MEETMIND AI — MOBILE SECURITY AUDIT REPORT
## Authentication, Token Verification & Data Isolation Security Review

**Date:** November 1, 2026  
**Security Auditor:** Independent Senior Mobile Security Engineer  
**Scope:** Mobile Flutter App (`mobile_flutter/`), Backend Auth Services (`backend/app/`), Firebase Config  
**Overall Security Posture:** **CRITICAL VULNERABILITIES IDENTIFIED**  

---

### 1. Security Vulnerability Matrix

| ID | Title | Component | Severity | CVSS v3.1 | Status |
| :---: | :--- | :---: | :---: | :---: | :---: |
| **SEC-01** | Unverified Firebase JWT Signature & Claims Parsing | Backend (`main.py`) | **CRITICAL** | **9.8** | Active Vulnerability |
| **SEC-02** | Unauthenticated Fallback Grants Access to Seed Account | Backend (`main.py`) | **CRITICAL** | **9.1** | Active Vulnerability |
| **SEC-03** | Production Release Signing Fails Open to Debug Keys | Android Build (`build.gradle.kts`) | **HIGH** | **7.4** | Active Vulnerability |
| **SEC-04** | Hardcoded Demo Credentials in Mobile Guest Login | Mobile Client (`auth_service.dart`) | **HIGH** | **7.1** | Active Vulnerability |
| **SEC-05** | Unverified Email Matching Account Linking | Backend (`main.py`) | **HIGH** | **7.5** | Active Vulnerability |
| **SEC-06** | Audio Vault Recordings Stored in Plaintext on Disk | Mobile Client (`recordings/`) | **MEDIUM** | **5.5** | Architectural Limitation |
| **SEC-07** | Ephemeral Quick Tunnel Default Gateway in Mobile Client | Mobile Client (`api_client.dart`) | **MEDIUM** | **4.3** | Configuration Defect |
| **SEC-08** | Task Alarms Lost on Device Reboot | Android (`AndroidManifest.xml`) | **LOW** | **2.5** | Missing Receiver |

---

### 2. Deep Dive: Vulnerability Analysis

#### SEC-01: Unverified Firebase JWT Signature & Claims Parsing
* **Severity:** **CRITICAL (CVSS 9.8)**
* **Location:** `backend/app/main.py`, lines 177–197:
  ```python
  # 2. Try Firebase ID Token (JWT)
  try:
      unverified_claims = jwt.get_unverified_claims(token)
      firebase_email = unverified_claims.get("email")
      if firebase_email:
          user = db.query(User).filter(User.email == firebase_email).first()
          if user:
              return user
          ...
  ```
* **Attack Scenario:**
  The backend uses `jwt.get_unverified_claims(token)` without verifying the cryptographic signature against Google's public x509 certificates.
  An attacker can construct a fake, unsigned JWT payload containing `{"email": "victim_executive@example.com"}`.
  When sent with `Authorization: Bearer <fake_token>`, the backend accepts the unverified claims as truth, locates the victim's account, and returns full access to all private meetings, transcripts, and financial discussions.
* **Remediation:**
  Use the official `firebase-admin` Python SDK (`auth.verify_id_token(token, check_revoked=True)`) or verify the signature against Google's public keys (`https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com`), enforcing `aud == "meetmind-ai-74519"` and `iss == "https://securetoken.google.com/meetmind-ai-74519"`.

---

#### SEC-02: Unauthenticated Request Fallback to Seed User
* **Severity:** **CRITICAL (CVSS 9.1)**
* **Location:** `backend/app/main.py`, lines 199–212:
  ```python
  # Default fallback user for local evaluation/testing
  user = db.query(User).filter(User.email == "emily@example.com").first()
  if not user:
      user = db.query(User).first()
  ...
  return user
  ```
* **Attack Scenario:**
  If a client sends an API request without an `Authorization` header, or if the provided token is corrupted, `get_current_user` catches the exception and falls back to returning the user object for `emily@example.com`.
  Consequently, **endpoints requiring authentication are effectively public** and expose Emily's data to any unauthenticated caller.
* **Remediation:**
  In non-local/production modes, `get_current_user` must raise `HTTPException(status_code=401, detail="Could not validate credentials")` whenever valid credentials are not provided. Demo fallback must be strictly gated behind `if settings.ENVIRONMENT == "local_development":`.

---

#### SEC-03: Production Release Signing Fails Open to Debug Keys
* **Severity:** **HIGH (CVSS 7.4)**
* **Location:** `mobile_flutter/android/app/build.gradle.kts`, lines 45–55:
  ```kotlin
  buildTypes {
      release {
          signingConfig = if (keystorePropertiesFile.exists()) {
              signingConfigs.getByName("release")
          } else {
              signingConfigs.getByName("debug")
          }
      }
  }
  ```
* **Impact:**
  If a developer or automated CI/CD pipeline triggers a release build (`flutter build apk --release` or `flutter build appbundle`) without `key.properties`, the build does not fail. Instead, it silently signs the release package with the public Android debug keystore.
  An attacker can spoof, tamper with, or repackage debug-signed artifacts, and Google Play Console will reject the submission.
* **Remediation:**
  Release builds must fail closed:
  ```kotlin
  buildTypes {
      release {
          if (!keystorePropertiesFile.exists()) {
              throw GradleException("Production key.properties not found. Release builds must not use debug keys.")
          }
          signingConfig = signingConfigs.getByName("release")
      }
  }
  ```

---

#### SEC-04: Hardcoded Demo Credentials in Mobile Guest Login
* **Severity:** **HIGH (CVSS 7.1)**
* **Location:** `mobile_flutter/lib/core/services/auth_service.dart`, lines 167–169:
  ```dart
  static Future<UserModel> loginAsGuest() async {
    return await login(email: 'emily@example.com', password: 'password123');
  }
  ```
* **Impact:**
  Hardcoding `emily@example.com` and `password123` in client source code grants anyone tapping "Explore as Guest" full read/write access to the persistent account of Emily Watson on staging and production databases.
* **Remediation:**
  Remove guest login from production builds or provision ephemeral, read-only demo sessions in an isolated sandbox database partition.

---

#### SEC-05: Unverified Email Matching Account Linking
* **Severity:** **HIGH (CVSS 7.5)**
* **Location:** `backend/app/main.py`, lines 182–184:
  `user = db.query(User).filter(User.email == firebase_email).first()`
* **Impact:**
  If an attacker registers an account on Firebase using an unverified email address that matches an existing enterprise user in the database, the backend links the session directly without checking `unverified_claims.get("email_verified") == True`.
* **Remediation:**
  Require `claims.get("email_verified") is True` before associating existing user records with Firebase identity.

---

#### SEC-06: Audio Recordings Stored Unencrypted at Rest
* **Severity:** **MEDIUM (CVSS 5.5)**
* **Location:** `mobile_flutter/lib/core/services/audio_recording_service.dart` & `vault_database.dart`
* **Impact:**
  Audio files are stored as standard AAC `.m4a` files in the app's document directory, and metadata is stored in plaintext SQLite without SQLCipher.
  On rooted Android devices or if a backup is extracted, confidential enterprise meeting audio can be extracted directly from physical flash memory.
* **Remediation:**
  For enterprise-grade security, encrypt audio files at rest using AES-256-GCM with keys managed in Android Keystore / iOS Keychain via `flutter_secure_storage`.

---

### 3. Multi-Tenant Access & Authorization Review

* **Workspace & Meeting Scoping:**
  In `backend/app/main.py`, queries for `/meetings` filter by `Meeting.user_id == current_user.id`.
  However, because `get_current_user` currently suffers from **SEC-01** (unverified JWT claims) and **SEC-02** (unauthenticated fallback to Emily), tenant isolation is effectively broken at the authentication gateway layer.
  Once SEC-01 and SEC-02 are remediated, the internal `user_id` and `workspace_id` filters will function as intended.

