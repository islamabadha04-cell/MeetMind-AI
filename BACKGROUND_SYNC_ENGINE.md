# MEETMIND AI — BACKGROUND SYNCHRONIZATION ENGINE
**Version:** 6.0.0-mobile  
**Engine Implementation:** `BackgroundSyncEngine` (`mobile_flutter/lib/core/services/background_sync_engine.dart`)  
**Network Monitor:** `connectivity_plus: ^6.0.5`  

---

## 1. Engine Architecture & Operation

The `BackgroundSyncEngine` operates as a persistent singleton managing the transmission queue between local device storage and the remote MeetMind FastAPI backend.

```
┌─────────────────────────────────────────────────────────────┐
│                 Connectivity Plus Listener                  │
│       (Detects Wi-Fi / Mobile Data / Airplane Mode)         │
└──────────────────────────────┬──────────────────────────────┘
                               │ Event: Network Restored
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 Pending Uploads Queue Query                 │
│         SELECT * FROM offline_audio_vault WHERE             │
│  sync_state IN ('localOnly', 'waitingForConnection', ...)   │
└──────────────────────────────┬──────────────────────────────┘
                               │
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
┌───────────────────────────┐         ┌───────────────────────────┐
│     Checksum Integrity    │         │     Idempotency Header    │
│  - Recomputes SHA-256     │         │  - Attaches unique UUID   │
│  - Verifies file on disk  │         │    X-Idempotency-Key      │
└───────────┬───────────────┘         └───────────┬───────────────┘
            │                                     │
            └──────────────────┬──────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────┐
│          Multipart HTTP POST /api/v1/meetings/upload        │
└──────────────────────────────┬──────────────────────────────┘
                               │
            ┌──────────────────┴──────────────────┐
            ▼ (HTTP 200 OK)                       ▼ (HTTP Error / Drop)
┌───────────────────────────┐         ┌───────────────────────────┐
│       Mark As Synced      │         │ Exponential Backoff Retry │
│  - Saves remoteMeetingId  │         │  - Increment retry_count  │
│  - Broadcasts success     │         │  - delay = min(2^n * 2,60)│
└───────────────────────────┘         └───────────────────────────┘
```

---

## 2. Idempotency & Duplicate Prevention

In mobile environments, cellular handoffs or packet loss during the server response phase can cause the client to timeout even if the server processed the audio.

To eliminate duplicate meetings:
1. Every recording is assigned a persistent UUID v4 (`idempotencyKey`).
2. The key is transmitted as an HTTP header:
   `X-Idempotency-Key: 7b84cf22-94ea-4a62-9706-e7e0e7a1739c`
3. If the server receives an upload request with a previously processed idempotency key, it skips audio reprocessing and returns the existing meeting object directly with HTTP 200.

---

## 3. Exponential Backoff Formula

When a transient network error or server load spike occurs, the engine spaces out retries to avoid battery drain and API hammering:

$$\text{Delay (seconds)} = \min\left(2^{\text{retryCount}} \times 2,\, 60\right)$$

* Attempt 1: 4 seconds
* Attempt 2: 8 seconds
* Attempt 3: 16 seconds
* Attempt 4: 32 seconds
* Attempt 5+: 60 seconds (ceiling)

---

## 4. Real-Time Status Broadcast & UI Sync
The engine emits `SyncStatusEvent` objects over a broadcast stream (`statusStream`):
* `recordingId`: Target recording UUID.
* `state`: Current `VaultSyncState`.
* `progress`: Decimal progress indicator (`0.0` to `1.0`).
* `message`: User-facing description (e.g., *"Uploading to MeetMind Cloud..."*).

`VaultNotifier` listens to this stream, allowing the `VaultScreen` and `DashboardScreen` badges to update instantly without polling.

