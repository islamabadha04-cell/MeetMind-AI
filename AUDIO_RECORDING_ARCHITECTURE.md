# MEETMIND AI — AUDIO RECORDING ARCHITECTURE
**Version:** 6.0.0-mobile  
**Encoding Format:** AAC-LC (`.m4a`), 128 kbps, 44,100 Hz Sample Rate  
**Service Implementation:** `AudioRecordingService` (`mobile_flutter/lib/core/services/audio_recording_service.dart`)  

---

## 1. Core Recording Pipeline

The recording engine uses the Flutter `record` package with direct hardware codec bindings:

```
┌─────────────────────────────────────────────────────────────┐
│                   Microphone Audio Stream                   │
└──────────────────────────────┬──────────────────────────────┘
                               │ (44.1 kHz, Mono/Stereo)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 Native Hardware Encoder                     │
│  - Android: MediaRecorder (AAC-LC)                          │
│  - iOS: AVAudioEngine / AVAudioRecorder (kAudioFormatMPEG4) │
└──────────────────────────────┬──────────────────────────────┘
                               │
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
┌───────────────────────────┐         ┌───────────────────────────┐
│     File Storage Stream   │         │    Amplitude Stream       │
│  - Writes to disk chunked │         │  - 150ms periodic polling │
│  - Path: doc/recordings/  │         │  - Normalizes [-60dB, 0dB]│
│    meetmind_rec_{uuid}.m4a│         │  - Drives 24-bar waveform │
└───────────────────────────┘         └───────────────────────────┘
```

---

## 2. Platform-Specific Native Requirements

### 2.1 Android Foreground Service & Permissions
* **Permissions in `AndroidManifest.xml`:**
  * `android.permission.RECORD_AUDIO`: Required for microphone access.
  * `android.permission.FOREGROUND_SERVICE`: Prevents process termination.
  * `android.permission.FOREGROUND_SERVICE_MICROPHONE`: Android 14+ typed foreground service.
  * `android.permission.POST_NOTIFICATIONS`: Android 13+ permission for persistent recording notification.
  * `android.permission.WAKE_LOCK`: Keeps CPU awake while recording screen-off.
* **OS Lifecycle Behavior:** Android terminates background applications aggressive during low memory conditions. Running an explicit foreground service with an active recording notification guarantees audio capture continuity.

### 2.2 iOS Background Audio Mode & Permissions
* **Settings in `Info.plist`:**
  * `NSMicrophoneUsageDescription`: *"MeetMind AI requires microphone access to record and transcribe your meetings."*
  * `UIBackgroundModes`: `<array><string>audio</string></array>`
* **Audio Session Category:** Sets `AVAudioSessionCategoryPlayAndRecord` with `defaultToSpeaker` option.
* **Interruption Handling:** When a cellular call arrives, iOS fires an audio session interruption. The service pauses cleanly and recovers upon session reactivation.

---

## 3. Moment Bookmarking Feature
While recording, users can tap the **Bookmark Moment** button. This records the exact second offset in `_bookmarkedTimestamps`. When the meeting is transcribed, these bookmark timestamps map directly to key decision excerpts, enabling 1-click audio seeking.

