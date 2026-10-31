# MEETMIND AI — Phase 3: AI Productivity & Automation Architecture

**Version:** 3.0.0 (Phase 3 Completed)  
**Status:** Verified & Operational  
**Application URL:** [https://meetmind-ai-74519.web.app](https://meetmind-ai-74519.web.app)  

---

## 1. System Vision & Objectives

Phase 3 transforms MeetMind AI from an intelligence and memory repository into an **action-oriented execution engine**. Rather than leaving meeting transcripts as passive records, MeetMind AI automatically detects commitments, extracts structured action items with spoken evidence quotes, routes unconfirmed tasks to managers for review, provides an interactive 5-column Kanban board, drafts contextual follow-ups in English/Urdu/Roman Urdu, and executes multi-step automation chains.

```
                      Meeting Audio & Transcript
                                  │
                                  ▼
                    AI Action Item Extractor
                     (Confirmed vs Suggested)
                                  │
                 ┌────────────────┴────────────────┐
                 ▼                                 ▼
         Confirmed Tasks                   AI Suggested Tasks
     (High Confidence >= 0.90)          (Requires Human Review)
                 │                                 │
                 │                                 ▼
                 │                      Manager Approval Pipeline
                 │                     (Approve / Reject / Assign)
                 │                                 │
                 └────────────────┬────────────────┘
                                  ▼
                   Smart Task Management Engine
            [Kanban Board | List View | Calendar View]
                                  │
         ┌────────────────────────┼────────────────────────┐
         ▼                        ▼                        ▼
 AI Follow-Up Drafter     Smart Notifications     Workflow Automation
 (Client / Payment / MoM) (Deadlines / Overdue)  (Triggers -> Actions)
```

---

## 2. Component Architectures

### 2.1 AI Action Item Extraction Engine (`backend/app/services/ai_service.py`)
- **Extraction Logic:** Scans spoken turns for action indicators (`will conduct`, `deploy`, `finalize`, `review`, `test`, `implement`, `prepare`).
- **Entity Identification:** Strictly identifies assignees from confirmed roster names (`Emily Watson`, `Hasnain Ali`, `Tariq Khan`, `Sarah`, `Usman`) and marks unconfirmed entities as `"Unassigned"`. Missing dates are left as `None` rather than fabricated.
- **Evidence Quote Binding:** Captures the verbatim sentence and exact audio timestamp (e.g., `03:40`), calculating a confidence score ($0.0 - 1.0$).
- **Gating Protocol:** AI-generated tasks are initially flagged with `is_ai_generated = True` and `is_approved = False`, generating an `ApprovalRequest` record for management.

### 2.2 Smart Task Management Dashboard (`app.html` & `app.js`)
- **View Switcher:**
  1. **Kanban Board:** 5 reactive status columns (`Pending`, `In Progress`, `Completed`, `Overdue`, `Cancelled`).
  2. **List View:** Dense corporate tabular view with sortable columns, assignee filters, and action buttons.
  3. **Calendar View:** Timeline view with milestone indicators and 1-click `.ICS` calendar export.
- **Task KPI Metrics:** Real-time counters computing Total, Pending, In Progress, Overdue, and Completed tasks.
- **Task Details Modal (`#taskDetailsModal`):**
  - Displays complete metadata, priority badge, and project tag.
  - Spoken transcript evidence quote box with timestamp jump.
  - Team discussion thread with real-time comment submission (`TaskComment`).
  - Full audit trail (`TaskHistory`) recording all state and assignment changes.

### 2.3 Manager Approvals Pipeline
- Dedicated interface (`#page-approvals`) for team managers.
- Inspects pending AI-extracted tasks alongside their originating meeting title and audio evidence quote.
- Actions:
  - **Approve & Assign:** Formally commits task to workspace, sets `is_approved = True`, and dispatches notification.
  - **Reject:** Cancels task with recorded decision notes and moves to cancelled archive.
  - **Modify:** Allows manager to override assignee or deadline before approval.

### 2.4 AI Follow-Up Generator
- Contextual drafting engine (`backend/app/services/ai_service.py`):
  - Supported types: `client_followup`, `payment_reminder` (Pakistani Gateway), `deadline_reminder`, `project_status`, `meeting_summary`.
  - Multilingual support:
    - **English:** Corporate executive styling.
    - **Urdu Nastaliq (اردو):** Formal business Urdu.
    - **Roman Urdu:** Professional Pakistani corporate style.
- **Safety Directive:** Produces drafts strictly for review and clipboard copy. **Never transmits messages without user authorization.**

### 2.5 Visual Workflow Automation Builder (`#page-workflows`)
- Multi-step event-driven automation:
  - **Triggers:** `meeting_completed`, `deadline_approaching`, `status_changed`.
  - **Conditions:** JSON rule evaluation (duration, priority, attendees).
  - **Actions:** Sequence of automated steps (generate summary, extract tasks, alert manager, draft follow-up).
- Execution engine logs all trigger events and execution runs with retry counts.

