# 🎯 Jira Cloud & Trello Integration Guide

---

## 1. Atlassian Jira Cloud (OAuth 2.0 3LO)

### 1.1. Atlassian Developer Console Setup
1. Register an app on **[Atlassian Developer Console](https://developer.atlassian.com/console/myapps/)**.
2. Enable **Jira Cloud platform API**.
3. Configure Authorization Code Grants (3LO) with callback:
   `https://meetmind-ai-74519.web.app/api/v1/integrations/oauth/callback/jira`
4. Set Scopes:
   - `read:jira-work`
   - `write:jira-work`
   - `read:jira-user`
   - `offline_access`

### 1.2. Priority & Issue Mapping
MeetMind AI task priorities map directly to Jira Cloud issue priorities:
| MeetMind Priority | Jira Priority |
| :--- | :--- |
| `urgent` | `Highest` |
| `high` | `High` |
| `medium` | `Medium` |
| `low` | `Low` |

### 1.3. Endpoints
- **List Projects:** `GET /api/v1/integrations/jira/projects`
- **Create Issue from Task:** `POST /api/v1/integrations/jira/create-issue`
  - Request: `{"task_id": 12, "project_key": "CORE"}`
  - Response: `{"success": true, "issue_key": "CORE-412", "issue_url": "https://meetmind-team.atlassian.net/browse/CORE-412"}`

---

## 2. Trello Integration

### 2.1. Developer Token Configuration
- Uses Trello REST API v1.
- Obtain API Key & Token from `https://trello.com/app-key`.
- User provides token in the MeetMind Integration Center modal.

### 2.2. Endpoints
- **List Boards:** `GET /api/v1/integrations/trello/boards`
- **Create Card from Task:** `POST /api/v1/integrations/trello/create-card`
  - Request: `{"task_id": 12, "board_id": "board_001", "list_id": "list_001"}`
  - Response: `{"success": true, "card_id": "c_a1b2c3d4", "card_url": "https://trello.com/c/c_a1b2c3d4"}`

