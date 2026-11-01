# MEETMIND AI — OFFLINE AUDIO VAULT SPECIFICATION
**Version:** 6.0.0-mobile  
**Database Engine:** SQLite via `sqflite` (Android/iOS) and `sqflite_common_ffi` (Desktop/Test)  
**Vault Implementation:** `VaultDatabase` (`mobile_flutter/lib/core/services/vault_database.dart`)  
**Data Model:** `VaultRecordingModel` (`mobile_flutter/lib/models/vault_recording_model.dart`)  

---

## 1. Core Principle & Offline Guarantee

A meeting assistant must be completely dependable when internet connectivity is intermittent, slow, or unavailable (e.g. in airplanes, secure facilities, transit, or remote client offices).

**The MeetMind Offline Guarantee:**
1. Recording, waveform monitoring, duration tracking, and file saving work **100% locally with zero internet dependency**.
2. Completed recordings are securely written to device storage with an RFC 4122 UUID and a cryptographically verified SHA-256 checksum.
3. Audio files are **never deleted automatically** from device storage. Even after cloud synchronization confirms success, the local recording remains cached for offline playback until manually removed by the user.

---

## 2. Vault Database Schema

Table Name: `offline_audio_vault`

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | TEXT | PRIMARY KEY | Unique local recording UUID v4 |
| `title` | TEXT | NOT NULL | User-assigned meeting title |
| `file_path` | TEXT | NOT NULL | Absolute path on local file system |
| `file_size_bytes`| INTEGER | NOT NULL | Size in bytes |
| `duration_seconds`| INTEGER | NOT NULL | Total recorded audio duration |
| `sha256_checksum` | TEXT | NOT NULL | SHA-256 hash of audio stream |
| `created_at` | TEXT | NOT NULL | ISO 8601 creation timestamp |
| `sync_state` | TEXT | NOT NULL | Current lifecycle status |
| `remote_meeting_id`| INTEGER | NULLABLE | Server meeting ID once confirmed synced |
| `retry_count` | INTEGER | DEFAULT 0 | Number of failed upload attempts |
| `last_error` | TEXT | NULLABLE | Detailed description of last error |
| `idempotency_key`| TEXT | NOT NULL | Unique token passed in `X-Idempotency-Key` |

---

## 3. Sync State Lifecycle Matrix

```
       [Record Stopped]
              │
              ▼
       ┌──────────────┐
       │  Local Only  │
       └──────┬───────┘
              │ (Network check)
       ┌──────┴──────────────────────┐
       ▼                             ▼
┌──────────────┐             ┌──────────────┐
│  Uploading   │             │ Waiting For  │
└──────┬───────┘             │  Connection  │
       │                     └──────┬───────┘
   ┌───┴───────────┐                │ (Connection restored)
   ▼               ▼                ▼
┌────────┐   ┌───────────┐   ┌──────────────┐
│ Synced │   │  Failed / │◄──┤  Uploading   │
└────────┘   │ Retry Req │   └──────────────┘
             └─────┬─────┘
                   │ (Exponential Backoff / Manual Retry)
                   ▼
             ┌───────────┐
             │ Uploading │
             └───────────┘
```

1. **`localOnly`:** Recording is saved locally on the device file system.
2. **`waitingForConnection`:** Device is offline or airplane mode is active; item is queued in SQLite.
3. **`uploading`:** Active multipart upload stream in transit to FastAPI server.
4. **`synced`:** Server confirmed HTTP 200 and returned valid `meeting_id`.
5. **`failed` / `retryRequired`:** Network error, server timeout, or transient error. Scheduled for retry with exponential backoff.

---

## 4. Integrity Checks & Tamper Resistance
Before an upload begins, `VaultRecordingModel.computeChecksum()` reads the local file bytes and recalculates the SHA-256 hash. If the hash differs from the hash recorded at the end of audio capture, the upload is halted immediately to prevent corrupted payload transmission.

---

## 5. Documented Limitations
* **Storage Space:** Extended 4-hour meetings at 128 kbps require ~230 MB of device storage. Devices with low storage (<100 MB free) will warn the user before starting.
* **OS Process Termination:** If a user manually force-quits the app from the multitasking switcher while recording, the audio file up to the last flushed buffer is preserved and marked for recovery on next app launch.

