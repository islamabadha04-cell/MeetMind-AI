# 📱 WhatsApp Business Platform Integration Guide
**Primary Flow:** Inbound Voice Note → Audio Download → Gemini/Whisper Transcription → AI Synthesis → Meeting & Action Item Creation

---

## 1. Prerequisites (Meta Cloud API)

> [!IMPORTANT]
> A standard personal WhatsApp number cannot receive Cloud API webhooks directly. The integration requires a Meta Business Account and an authorized WhatsApp Business Platform phone number.

### Meta Developer Console Setup:
1. Register as a developer on **[Meta for Developers](https://developers.facebook.com/)**.
2. Create an App of type **Business**.
3. Under App Dashboard, add the **WhatsApp** product.
4. Obtain:
   - **WhatsApp Business Account ID**
   - **Phone Number ID**
   - **System User Permanent Access Token**
   - **Webhook Verify Token** (custom secret configured in server environment)

---

## 2. Webhook Configuration

- **Callback URL:** `https://meetmind-ai-74519.web.app/api/v1/integrations/whatsapp/webhook`
- **Verify Token:** Set to `META_WEBHOOK_VERIFY_TOKEN` (default: `meetmind_meta_webhook_secret_2026`).
- **Webhook Fields to Subscribe:** `messages`

---

## 3. Endpoints & Pipeline

### 3.1. Verification Challenge (GET)
- **Endpoint:** `GET /api/v1/integrations/whatsapp/webhook`
- **Query Parameters:** `hub.mode=subscribe`, `hub.verify_token=...`, `hub.challenge=...`
- **Behavior:** Validates verify token; returns challenge integer on match with HTTP 200.

### 3.2. Inbound Voice Note Processing (POST)
- **Endpoint:** `POST /api/v1/integrations/whatsapp/webhook`
- **Processing Steps:**
  1. Validates webhook authenticity and message type (`audio`).
  2. Retrieves media URL via `GET https://graph.facebook.com/v19.0/{audio_id}`.
  3. Downloads audio stream with authorized Bearer token.
  4. Passes audio into `AIService.transcribe_and_summarize_audio`.
  5. Automatically creates meeting record, executive summary, decisions, and action items in the user's MeetMind workspace.
  6. Returns HTTP 200 acknowledgment to Meta.

