# MEETMIND AI — Persistent Meeting Memory Engine & Schema Specification

**Version:** 2.0.0 (Phase 2)  
**Status:** In Production  
**Live Application:** [https://meetmind-ai-74519.web.app](https://meetmind-ai-74519.web.app)

---

## 1. Overview & Purpose

The **Persistent Meeting Memory Engine** acts as the long-term cognitive brain for an organization. Rather than relying on employees to remember past client agreements, technical compromises, or budget limits from months ago, the engine automatically extracts, categorizes, validates, and stores institutional knowledge derived from every processed meeting.

---

## 2. The 10 Core Memory Categories

The memory engine classifies extracted facts into 10 distinct operational categories:

| Category ID | Category Label | Description & Scope |
|---|---|---|
| `client_preferences` | **Client Preferences** | Client expectations, preferred communication channels, tone, design preferences, and taboos. |
| `budget_discussions` | **Budget Discussions** | Agreed pricing, hourly rates, milestone payments, discount caps, and fee structures. |
| `tech_choices` | **Technology Choices** | Architecture decisions, stack selections (e.g., Python/FastAPI, Flutter, PostgreSQL), and tool mandates. |
| `deadlines` | **Project Deadlines** | Hard release targets, sprint completion dates, client demo commitments, and cutoff times. |
| `responsibilities` | **Team Responsibilities** | Ownership assignments, primary POCs, code review leads, and client account managers. |
| `recurring_issues` | **Recurring Problems** | Repeated bottlenecks, payment delays, scope creep incidents, and unstable third-party APIs. |
| `agreements` | **Important Agreements** | Formal commitments made by either party, warranty terms, and support SLAs. |
| `unresolved_questions`| **Unresolved Questions** | Open discussions requiring future clarification or external third-party confirmation. |
| `critical_risks` | **Critical Risks** | Budget overruns, security vulnerabilities, dependencies on single developers, or compliance gaps. |
| `strategic_goals` | **Strategic Goals** | Long-term roadmap targets, ARR milestones, market expansion, and platform scale aspirations. |

---

## 3. Database Schema Specification

### 3.1 Relational Schema (`meeting_memories` table)

Implemented in SQLAlchemy ([backend/app/models/models.py](file:///c:/Users/Hasnain.DESKTOP-80IKSQ9/Desktop/hasnain/backend/app/models/models.py)):

```sql
CREATE TABLE meeting_memories (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    meeting_id VARCHAR(36) NULL,
    category VARCHAR(50) NOT NULL,
    key_fact VARCHAR(255) NOT NULL,
    detail TEXT NOT NULL,
    confidence_score FLOAT DEFAULT 1.0,
    source_meeting_title VARCHAR(255) NULL,
    source_timestamp VARCHAR(20) NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    revision_count INTEGER DEFAULT 1,
    revision_history JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE SET NULL
);

CREATE INDEX idx_memories_user_category ON meeting_memories(user_id, category);
CREATE INDEX idx_memories_meeting_id ON meeting_memories(meeting_id);
```

### 3.2 Field Definitions & Constraints

- `id`: UUIDv4 primary identifier.
- `user_id`: Reference to the memory owner / workspace.
- `meeting_id`: Foreign key to the originating meeting (retained as `NULL` if meeting is archived/deleted, preserving organizational memory).
- `category`: String enumeration matching one of the 10 core categories.
- `key_fact`: Concise fact headline (e.g., *"Client requires milestone 2 signoff before initiating invoice payment"*).
- `detail`: Comprehensive explanation containing context, constraints, and speaker attribution.
- `confidence_score`: Float between `0.0` and `1.0` representing AI extraction confidence.
- `source_meeting_title`: Human-readable title of the originating meeting for instant display.
- `source_timestamp`: Timestamp string (e.g., `"06:40"`) indicating the exact transcript passage.
- `is_verified`: Boolean flag indicating whether a human user has inspected and verified the memory item.
- `revision_count`: Integer tracking how many edits have been applied.
- `revision_history`: JSON array logging historical values, timestamps, and editor identities.

---

## 4. Revision Tracking & Audit Trail

When a user edits a memory item in the UI or an automated pipeline updates details, the previous state is never silently overwritten. It is appended to `revision_history`:

```json
[
  {
    "revision": 1,
    "timestamp": "2026-10-25T11:42:00Z",
    "key_fact": "Client budget cap is $15,000",
    "detail": "Mentioned during initial discovery sync.",
    "modified_by": "system_ai_extractor"
  },
  {
    "revision": 2,
    "timestamp": "2026-10-28T16:15:00Z",
    "key_fact": "Client increased budget cap to $22,000 for mobile app",
    "detail": "Agreed in Sprint 4 Architecture Review after scope expansion.",
    "modified_by": "user_hasnain"
  }
]
```

---

## 5. Memory Extraction & Ingestion Pipeline

1. **Extraction Trigger:** Following meeting transcription and diarization, `memory_service.extract_meeting_memories(meeting)` is executed.
2. **Contextual Categorization:** Gemini 2.5 Flash processes the transcript turns against the 10 categories with a strict JSON extraction schema.
3. **Deduplication & Cross-Referencing:**
   - The engine checks existing memories in the user's workspace for matching entities (e.g., same client, same project).
   - If an existing memory contradicts the newly extracted fact (e.g., new deadline vs old deadline), the engine flags a **Contradiction Alert** and proposes an updated revision with link to the new meeting.
4. **User Verification Workflow:**
   - Unverified memories display an amber `Unverified AI Memory` badge in the UI.
   - Users can click **Verify** to validate the fact or **Edit** to modify wording, immediately raising confidence to `1.0`.
