# MEETMIND AI — MOBILE REAL DEVICE TEST PLAN
## Physical Android & iOS Hardware Verification Protocol

**Date:** November 1, 2026  
**Auditor:** Independent Senior QA & Test Automation Architect  
**Target Devices:** Physical Android Phone (Android 13/14+) & Physical iPhone (iOS 17+)  
**Objective:** Validate real-world hardware capabilities that cannot be proven by unit tests or headless emulators.

---

### 1. Prerequisites & Environment Setup

#### A. Network & Backend Ingress
* Real devices cannot reach `http://localhost:8000` or `127.0.0.1:8000`.
* A persistent, accessible HTTPS backend endpoint or local LAN IP (e.g., `http://192.168.1.X:8000/api/v1`) must be configured in `SettingsScreen` -> Custom API Gateway.

#### B. Android Sideloading Procedure
1. Enable **Developer Options** and **USB Debugging** on Android device.
2. Connect device via USB cable and verify via ADB:
   ```powershell
   adb devices
   ```
3. Accept Android SDK licenses on workstation:
   ```powershell
   flutter doctor --android-licenses
   ```
4. Build and install debug APK:
   ```powershell
   cd mobile_flutter
   flutter build apk --debug
   adb install -r build/app/outputs/flutter-apk/app-debug.apk
   ```

#### C. iOS TestFlight Deployment Procedure
1. Archive on macOS machine via Xcode:
   ```bash
   flutter build ipa --export-options-plist=ios/ExportOptions.plist
   ```
2. Upload archive to Apple App Store Connect via `altool` or Transporter.
3. Distribute build to Internal Testers via TestFlight.

---

### 2. Physical Device Test Execution Matrix

#### Test Case 1: Live Hardware Microphone Capture & Waveform
* **Steps:**
  1. Open app on physical phone and navigate to **Studio** tab.
  2. Tap "Start Recording". Verify OS microphone permission popup appears. Grant "While using the app".
  3. Speak into device microphone at varying volumes (whisper, normal, loud).
  4. Verify the 28-bar animated waveform dynamically expands and contracts in response to actual acoustic sound pressure.
* **Pass Criteria:** Mic indicator lights up in Android status bar; timer increments each second; audio records with zero clipping.

---

#### Test Case 2: Background Recording & Lock-Screen Resilience
* **Steps:**
  1. While meeting audio is actively recording, press the Home button to put app in background.
  2. Open other apps (e.g., Chrome, Notes).
  3. Lock the phone screen for 2 minutes.
  4. Unlock phone and return to MeetMind AI app. Tap "Stop Recording".
* **Pass Criteria:** Timer recorded continuously for the full duration; audio playback shows no missing audio gaps or OS throttling.
* **Note:** Requires native `<service android:foregroundServiceType="microphone">` fix before running on Android 14+.

---

#### Test Case 3: Offline Audio Vault in Airplane Mode (Zero Data Loss)
* **Steps:**
  1. Turn on **Airplane Mode** (disable Wi-Fi and Cellular data).
  2. Record a 30-second meeting titled *"Airplane Mode Offline Test"*.
  3. Stop recording. Navigate to **Vault** screen.
  4. Inspect the newly saved recording.
* **Pass Criteria:**
  - Recording appears in vault with state `Waiting for Connection`.
  - Checksum starts with `SHA: <8-char-hex>`.
  - Audio file exists on device storage. No network crash occurs.

---

#### Test Case 4: Automatic Network Recovery & Background Sync
* **Steps:**
  1. While still on the **Vault** screen with the pending recording from Test Case 3, disable Airplane Mode and reconnect to Wi-Fi.
  2. Do not tap any button on the screen.
* **Pass Criteria:**
  - `connectivity_plus` detects internet restoration within 3 seconds.
  - Sync state chip automatically transitions from `Waiting for Connection` -> `Uploading` -> `Synced with Cloud`.
  - Local notification pops up: *"☁️ Synced: Airplane Mode Offline Test — AI Transcript & Insights are ready"*.

---

#### Test Case 5: Native Google Sign-In with Real Hardware Account Picker
* **Steps:**
  1. On `LoginScreen`, tap "Continue with Google".
  2. Verify native Android Google Play Services account picker sheet slides up from bottom.
  3. Select an active Google account on the phone.
* **Pass Criteria:**
  - Phone completes OAuth exchange.
  - App transitions smoothly to `DashboardScreen` displaying user's actual Google profile name.
  - Requires SHA-1 fingerprint of signing key to be added to Firebase Console project `meetmind-ai-74519`.

---

#### Test Case 6: Cross-Platform Web & Mobile Synchronization
* **Steps:**
  1. Open web application at `https://meetmind-ai-74519.web.app` on laptop.
  2. Log in using the same user credentials used on the mobile phone.
  3. Create an action item task on mobile: *"Physical Device QA Sign-off"*.
  4. Refresh web dashboard on laptop.
* **Pass Criteria:** The exact task created on mobile appears instantly on the web application.

---

#### Test Case 7: Urdu Nastaliq & RTL Screen Inversion
* **Steps:**
  1. Go to `SettingsScreen` -> Language -> Select "اردو (Urdu)".
  2. Inspect `DashboardScreen`, `MeetingsScreen`, and `RecordingStudioScreen`.
* **Pass Criteria:** All headers, labels, and buttons render in correct right-to-left (RTL) alignment with authentic Nastaliq typography and zero clipped text boxes.

