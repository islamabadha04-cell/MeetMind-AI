# ⚡ MeetMind AI — Webhook & Zapier API Reference

MeetMind AI provides a secure, event-driven Webhook Engine for integrating with **Zapier**, **Make**, **n8n**, or custom corporate web services.

---

## 1. Supported Outbound Events

| Event Name | Trigger Condition |
| :--- | :--- |
| `meeting.completed` | An audio session has finished transcription, speaker diarization, and AI summarization. |
| `summary.generated` | An updated or bilingual summary (English, Urdu Nastaliq, Roman Urdu) is saved. |
| `task.created` | An action item is extracted by AI or manually added. |
| `task.approved` | A manager approves an AI-suggested task in `#page-approvals`. |
| `task.completed` | A task status is transitioned to `completed`. |
| `task.overdue` | A task deadline has passed without completion. |
| `deadline.approaching` | A milestone deadline is within 24 to 48 hours. |
| `document.indexed` | A company document or Google Drive file has been chunked and indexed into Knowledge Base RAG. |

---

## 2. Cryptographic Signature Verification (HMAC-SHA256)

Every webhook payload dispatched by MeetMind AI includes cryptographic security headers to prevent spoofing and replay attacks:

### Headers:
- `X-MeetMind-Timestamp`: UNIX timestamp integer (seconds).
- `X-MeetMind-Signature`: `t={timestamp},v1={hex_signature}`
- `X-MeetMind-Event`: Event name string (e.g. `meeting.completed`).

### Signature Calculation:
```python
import hmac
import hashlib

# 1. Concatenate timestamp and raw body bytes
signed_payload = f"{timestamp}.".encode() + raw_body_bytes

# 2. Compute HMAC-SHA256 using the subscription secret_key
expected_signature = hmac.new(
    secret_key.encode(),
    signed_payload,
    hashlib.sha256
).hexdigest()

# 3. Secure comparison
is_valid = hmac.compare_digest(received_signature, expected_signature)
```

---

## 3. Endpoints

### 3.1. List Subscriptions
- **`GET /api/v1/integrations/webhooks/subscriptions`**
- Returns all registered webhook subscriptions for the authenticated user.

### 3.2. Register Subscription
- **`POST /api/v1/integrations/webhooks/subscriptions`**
- Payload:
  ```json
  {
    "name": "Zapier Pipeline",
    "target_url": "https://hooks.zapier.com/hooks/catch/12345/abcdef",
    "events": ["meeting.completed", "task.approved"]
  }
  ```
- Returns subscription object with auto-generated signing secret (`sec_live_...`).

### 3.3. Test Dispatch
- **`POST /api/v1/integrations/webhooks/test-dispatch?subscription_id={id}&event_type=meeting.completed`**
- Sends signed test event payload to target URL and records response in `webhook_deliveries`.

