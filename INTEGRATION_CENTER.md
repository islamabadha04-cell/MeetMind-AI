# 🎛️ MeetMind AI — Integration Center Guide
**Target View:** `#page-integrations`  
**API Prefix:** `/api/v1/integrations`  

---

## 1. Overview & Capabilities

The **Integration Center** is a unified command hub in MeetMind AI that lets team leads and individual professionals manage connections to 10 enterprise platforms.

### Provider Catalog & Categories:
| Provider | Provider Key | Category | Auth Method | Primary Capabilities |
| :--- | :--- | :--- | :--- | :--- |
| **Google Calendar** | `google_calendar` | Calendar & Scheduling | OAuth 2.0 | Two-way meeting and task deadline synchronization. |
| **Gmail** | `gmail` | Email & Messaging | OAuth 2.0 (`gmail.compose`) | Executive follow-up and MoM email draft generation (Draft-Only). |
| **Google Drive** | `google_drive` | Cloud Storage & Docs | OAuth 2.0 (`drive.readonly`)| File browsing and direct document ingestion into Knowledge Base RAG. |
| **Microsoft Outlook** | `outlook` | Calendar & Scheduling | Microsoft Graph OAuth | Outlook Calendar events and Mail draft creation. |
| **Jira Cloud** | `jira` | Project Management | Atlassian OAuth 2.0 (3LO) | Converting approved meeting action items into Jira issues. |
| **Trello** | `trello` | Project Management | Developer Token / API Key | Creating cards on Trello boards and lists with deadlines. |
| **Slack** | `slack` | Email & Messaging | Slack OAuth 2.0 Bot | Posting structured meeting summaries, decisions, and action items. |
| **Notion** | `notion` | Cloud Storage & Docs | Notion API / OAuth | Exporting rich meeting notes, decisions, and todos into Notion databases. |
| **Zapier & Webhooks** | `zapier` | Automation & Webhooks | HMAC-SHA256 Secret | Real-time webhook event broadcasting with payload signing. |
| **WhatsApp Business** | `whatsapp` | Mobile & Chat | Meta Cloud API Webhook | Inbound voice note ingestion, transcription, and meeting note synthesis. |

---

## 2. Connection States & Lifecycle

Every provider card in the Integration Center reflects one of the following states:

1. **`not_connected`:** Clean state; provider is available to connect.
2. **`connecting`:** Authorization flow initiated; awaiting OAuth callback or credentials.
3. **`connected`:** Successfully authenticated with verified API access; displays connected account email and last sync time.
4. **`permission_required`:** Token scope lacks newly required permissions; re-authorization prompted.
5. **`expired`:** Refresh token expired; user prompted to re-authorize.
6. **`error`:** Upstream provider API returned throttling or network error.
7. **`disconnected`:** User explicitly disconnected; tokens purged and mappings archived.

---

## 3. UI Controls & Actions

- **Connect Account:** Opens authorization URL or API credential input dialog.
- **Test Connection:** Runs live or sandbox diagnostic pre-flight check and displays API status.
- **Settings / Info:** Inspects least-privilege permissions, authorized scopes, and linked external identifiers.
- **Disconnect:** Safely wipes server-side encrypted tokens and sets status to `disconnected`.

