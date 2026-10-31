# MEETMIND AI — Task Management & Approval Schema Specification

**Version:** 3.0.0 (Phase 3)  
**Status:** In Production  
**Live Application:** [https://meetmind-ai-74519.web.app](https://meetmind-ai-74519.web.app)  

---

## 1. Relational Database Schema (SQLAlchemy / PostgreSQL / SQLite)

### 1.1 Tasks Table (`tasks`)
```sql
CREATE TABLE tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    meeting_id INTEGER NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT DEFAULT '',
    assignee VARCHAR(100) DEFAULT 'Unassigned',
    deadline VARCHAR(50) NULL,
    priority VARCHAR(20) DEFAULT 'medium', -- low, medium, high, urgent
    status VARCHAR(20) DEFAULT 'pending',   -- pending, in_progress, completed, overdue, cancelled
    project VARCHAR(100) DEFAULT 'Core Sprint',
    confidence_score FLOAT DEFAULT 1.0,
    source_transcript_timestamp VARCHAR(20) DEFAULT '00:00',
    evidence_quote TEXT DEFAULT '',
    is_ai_generated BOOLEAN DEFAULT FALSE,
    is_approved BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE
);

CREATE INDEX idx_tasks_user_status ON tasks(user_id, status);
CREATE INDEX idx_tasks_project ON tasks(user_id, project);
CREATE INDEX idx_tasks_meeting_id ON tasks(meeting_id);
```

### 1.2 Task Comments Table (`task_comments`)
```sql
CREATE TABLE task_comments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    author_name VARCHAR(100) DEFAULT 'Emily Watson',
    comment_text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX idx_comments_task_id ON task_comments(task_id);
```

### 1.3 Task Audit History Table (`task_history`)
```sql
CREATE TABLE task_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    action VARCHAR(100) NOT NULL, -- created, updated, status_changed, assigned, approved, rejected
    previous_state TEXT DEFAULT '',
    new_state TEXT DEFAULT '',
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX idx_history_task_id ON task_history(task_id);
```

### 1.4 Manager Approval Requests Table (`approval_requests`)
```sql
CREATE TABLE approval_requests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    task_id INTEGER NOT NULL,
    requester_name VARCHAR(100) DEFAULT 'AI Synthesizer',
    approver_name VARCHAR(100) DEFAULT 'Emily Watson (Manager)',
    status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
    decision_notes TEXT DEFAULT '',
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
);
CREATE INDEX idx_approvals_user_status ON approval_requests(user_id, status);
```

### 1.5 Notifications Table (`notifications`)
```sql
CREATE TABLE notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    type VARCHAR(50) DEFAULT 'deadline', -- deadline, overdue, assigned, completed, approval, reminder
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    link_url VARCHAR(255) DEFAULT '#tasks',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read);
```

---

## 2. Firestore Document Model

In cloud deployments, tasks and approvals are mirrored to Firestore with strict Row-Level Security:

```json
{
  "taskId": "task_101",
  "userId": "auth_uid_123",
  "meetingId": "meet_456",
  "title": "Conduct mobile audio jitter stress test",
  "description": "Verify Android audio worklet buffer to eliminate recording latency.",
  "assignee": "Emily Watson",
  "deadline": "Thursday 4:00 PM",
  "priority": "high",
  "status": "pending",
  "project": "Core Sprint",
  "confidenceScore": 0.95,
  "timestamp": "03:40",
  "evidenceQuote": "Emily will conduct load testing on Thursday to eliminate audio jitter.",
  "isAiGenerated": true,
  "isApproved": true,
  "comments": [
    {
      "author": "Emily Watson",
      "text": "Tested on Pixel 8 with 64ms buffer.",
      "time": "11:30 AM"
    }
  ],
  "history": [
    {
      "action": "created",
      "note": "AI task initialized from sprint review",
      "timestamp": "2026-10-31T10:00:00Z"
    }
  ]
}
```

