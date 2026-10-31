# 🏢 Microsoft Graph Integration Guide (Outlook Calendar & Email)

---

## 1. Microsoft Entra ID (Azure AD) Registration

1. Register an application in the **[Azure Portal](https://portal.azure.com/)** under **Microsoft Entra ID > App registrations**.
2. **Supported Account Types:** Accounts in any organizational directory (Multitenant) and personal Microsoft accounts (`common`).
3. **Redirect URI (Web):** `https://meetmind-ai-74519.web.app/api/v1/integrations/oauth/callback/outlook`
4. **API Permissions (Microsoft Graph - Delegated):**
   - `Calendars.ReadWrite` (create & sync deadline events)
   - `Mail.ReadWrite` (create email drafts)
   - `offline_access` (refresh token acquisition)
   - `User.Read` (basic profile)
5. Generate a Client Secret and store in server environment variables:
   - `MICROSOFT_CLIENT_ID`
   - `MICROSOFT_CLIENT_SECRET`

---

## 2. API Endpoints

### 2.1. Outlook Calendar Deadline Sync
- **Endpoint:** `POST /api/v1/integrations/outlook/sync-task`
- **Request:** `{"task_id": 42}`
- **Response:**
  ```json
  {
    "success": true,
    "task_id": 42,
    "outlook_event_id": "AAMkAGI2...",
    "message": "Task deadline synchronized to Microsoft Outlook Calendar via Microsoft Graph."
  }
  ```

### 2.2. Outlook Mail Draft Generation (Draft-Only)
- **Endpoint:** `POST /api/v1/integrations/outlook/create-draft`
- **Request:**
  ```json
  {
    "recipient": "partner@corp.com",
    "subject": "Minutes of Meeting — Sprint Scope",
    "body": "..."
  }
  ```
- **Response:**
  ```json
  {
    "success": true,
    "draft_id": "msg_9f3b12...",
    "status": "draft_created",
    "message": "Outlook email draft created successfully. (Draft-Only: must be approved in Outlook to send)."
  }
  ```

