# 💬 Slack & Notion Integration Guide

---

## 1. Slack Integration (Bot Token & Webhooks)

### 1.1. Slack App Configuration
1. Create an app on the **[Slack API Portal](https://api.slack.com/apps)**.
2. In **OAuth & Permissions**, add Bot Token Scopes:
   - `chat:write` (post messages as MeetMind AI)
   - `channels:read` (list public channels)
   - `groups:read` (list private channels if invited)
3. Set OAuth Redirect URL:
   `https://meetmind-ai-74519.web.app/api/v1/integrations/oauth/callback/slack`

### 1.2. Endpoints
- **List Channels:** `GET /api/v1/integrations/slack/channels`
- **Post Meeting Summary:** `POST /api/v1/integrations/slack/post-summary`
  - Payload:
    ```json
    {
      "meeting_id": 5,
      "channel_id": "C01234567",
      "include_decisions": true,
      "include_action_items": true
    }
    ```
  - Dispatches formatted Slack Block Kit payload with executive summary, confirmed decisions, and assigned action items.

---

## 2. Notion Integration (Pages & Databases)

### 2.1. Notion Developer Portal Setup
1. Create an integration at **[Notion My Integrations](https://www.notion.so/my-integrations)**.
2. Select **Capabilities**:
   - Read content
   - Update content
   - Insert content
3. Share the destination Notion Database or Page with the MeetMind Integration.

### 2.2. Endpoints
- **Export Meeting to Notion:** `POST /api/v1/integrations/notion/export-page`
  - Payload: `{"meeting_id": 5}`
  - Response:
    ```json
    {
      "success": true,
      "page_id": "notion_8b9a1f...",
      "page_url": "https://notion.so/meetmind/notion_8b9a1f...",
      "message": "Meeting 'Sprint Architecture Review' exported to Notion with formatted Executive Summary, Decisions, and Action Items."
    }
    ```
  - Preserves source meeting references, date, duration, and sets up interactive checklist blocks for action items.

