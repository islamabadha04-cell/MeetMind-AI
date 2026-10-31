# MeetMind AI — Official Product Changelog
All notable changes and architectural upgrades to MeetMind AI are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.2.0] - 2026-10-31

### Added
- **Pakistani Localized Payment Gateways:** Dedicated tabbed checkout modal for JazzCash (`0312-5819717`), Easypaisa (`0312-5819717`), and Raast Instant Settlement with 1-click clipboard copy, instant Pro activation, and verified transaction alerts.
- **Audio-to-Transcript Synchronized Playback:** Sticky audio player bar in meeting details with interactive timestamps (`seekToTranscriptTime`). Clicking any speaker line instantly jumps audio to that exact moment and visually highlights the active spoken turn.
- **Executive Minutes of Meeting (MoM) PDF Export:** Automated corporate PDF generation via jsPDF featuring branded headers, metadata tables, executive callout blocks, key decisions, and tabular action items.
- **Universal Calendar Sync:** Two-way meeting and task calendar export supporting universal `.ics` download (Apple Calendar, Microsoft Outlook, Thunderbird) and instant 1-click Google Calendar web event creation.
- **Automated Headless CDP Test Suite:** 46-point automated browser verification suite testing DOM elements, navigation tabs, modal interactions, audio timeline math, and payment workflows.
- **Zero-Latency Guest Evaluation Access:** Instant one-click demo sandbox in `login.html` allowing rapid stakeholder evaluation without sign-up barriers.
- **Master Documentation Suite:** Published comprehensive technical architecture manuals:
  - `PROJECT_AUDIT.md`: System architecture, asset inventory, cost analysis.
  - `MASTER_ROADMAP.md`: Multi-phase roadmap covering Modules A through J.
  - `FEATURE_STATUS.md`: Feature verification matrix.
  - `DATABASE_SCHEMA.md`: Firestore & SQL entity relationship schemas.
  - `API_DOCUMENTATION.md`: REST endpoints & Firebase service interfaces.
  - `SECURITY_GUIDELINES.md`: Firestore security rules, zero-trust policies, and consent standards.
  - `DEPLOYMENT_GUIDE.md`: Production deployment procedures for Firebase & Cloud Run.

### Changed
- Refactored `firestore.rules` to enforce strict user-scoped row-level security (`resource.data.userId == request.auth.uid`), preventing unauthorized cross-tenant reads or updates.
- Hardened `app.html` against potential null references during dynamic tab transitions.
- Enhanced navigation bar responsiveness on mobile viewports.

---

## [1.1.0] - 2026-10-27

### Added
- FastAPI backend microservices integrating Gemini 2.5 Flash and Gemini 1.5 Flash models.
- Multimodal binary audio transcription endpoint (`/api/v1/meetings/transcribe-audio`).
- Cross-meeting conversational RAG intelligence endpoint (`/api/v1/chat/ask`).
- Task management REST API with assignee, priority, and deadline tracking.

### Fixed
- Resolved CORS headers for local and hosted origins.
- Added automatic SQLite database seeding for demo environments.

---

## [1.0.0] - 2026-10-20

### Added
- Initial release of MeetMind AI web application.
- Modern violet-themed responsive dashboard with meeting cards and stats counters.
- Firebase Authentication with Google Sign-In and Email/Password.
- Client-side Web Speech API live microphone transcription.
- Meeting categorization and color tinting system.

