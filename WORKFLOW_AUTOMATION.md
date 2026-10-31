# MEETMIND AI — Visual Workflow Automation Engine

**Version:** 3.0.0 (Phase 3)  
**Status:** In Production  
**Live Application:** [https://meetmind-ai-74519.web.app](https://meetmind-ai-74519.web.app)  

---

## 1. Overview & Architecture

The **AI Workflow Automation Builder** provides an event-driven automation framework that binds meeting intelligence with organizational productivity tools. It allows managers and team leads to define trigger conditions, sequential execution steps, approval gates, and notifications without writing code.

```
┌────────────────────────────────────────────────────────┐
│                     Trigger Event                      │
│   (e.g., meeting_completed, deadline_approaching)      │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│                   Condition Gate                       │
│    (e.g., duration >= 60s, priority == "high")         │
└───────────────────────────┬────────────────────────────┘
                            │ (True)
                            ▼
┌────────────────────────────────────────────────────────┐
│                  Action Sequence                       │
│   Step 1: AIService.generate_meeting_summary()         │
│   Step 2: AIService.extract_action_items_advanced()    │
│   Step 3: ApprovalRequest.create(status="pending")     │
│   Step 4: AIService.generate_follow_up_draft()         │
│   Step 5: Notification.dispatch(type="approval")       │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│                 Execution Audit Log                    │
│   Status: Success | Failed | Retrying                  │
│   Retry Count: 0/3                                     │
│   Logs: ["Extracted 3 tasks", "Alerted Manager"]       │
└────────────────────────────────────────────────────────┘
```

---

## 2. Supported Triggers, Conditions & Actions

### 2.1 Triggers
- `meeting_completed`: Fires immediately after a live recording or uploaded audio file is processed.
- `deadline_approaching`: Periodic background cron or scan trigger firing 24 hours prior to a committed milestone deadline.
- `task_status_changed`: Fires when a task changes status (e.g., moved to `in_progress` or `completed`).

### 2.2 Conditions
- `duration_seconds >= N`: Only process sessions of substantial length.
- `priority in ["high", "urgent"]`: Filter tasks for high-importance escalation.
- `requires_approval == True`: Mandates manager review before assignment.

### 2.3 Actions
- `generate_summary`: Generates bilingual executive summary.
- `extract_tasks`: Runs semantic action item extractor.
- `create_approval`: Submits task to Manager Approvals portal.
- `draft_followup`: Prepares client email draft in English, Urdu, or Roman Urdu.
- `create_notification`: Emits in-app alert for assignees and managers.

---

## 3. Database Schema Specification

### 3.1 Workflows Table (`workflows`)
```sql
CREATE TABLE workflows (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT DEFAULT '',
    trigger_type VARCHAR(50) DEFAULT 'meeting_completed',
    conditions_json TEXT DEFAULT '[]',
    actions_json TEXT DEFAULT '[]',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### 3.2 Workflow Executions Table (`workflow_executions`)
```sql
CREATE TABLE workflow_executions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    workflow_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    trigger_event VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'success', -- success, failed, retrying
    logs_json TEXT DEFAULT '[]',
    retry_count INTEGER DEFAULT 0,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (workflow_id) REFERENCES workflows(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

---

## 4. Safety & Security Guardrails

1. **Explicit Authorization for External Actions:** The workflow engine is strictly sandboxed. It can generate drafts, queue approvals, and record notifications, but **never automatically sends emails, dispatches SMS, or modifies external systems without configured user confirmation.**
2. **Execution De-duplication:** Prevents infinite triggering loops by caching execution hashes over a sliding 10-minute window.
3. **Graceful Retry Mechanics:** If a step encounters a temporary failure (e.g. rate limit), the engine records the execution as `retrying` with an exponential backoff counter capped at 3 retries.

