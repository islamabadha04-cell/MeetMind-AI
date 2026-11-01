# MEETMIND AI — FLUTTER MOBILE ARCHITECTURE
**Version:** 6.0.0-mobile  
**Platforms:** Android (API 24+) & iOS (14.0+)  
**State Management:** Flutter Riverpod (`StateNotifierProvider`, `StateProvider`)  
**Design System:** Material 3 with Soft Pastel MeetMind Theme & Inter / Noto Nastaliq Urdu Typography  

---

## 1. Architectural Philosophy & Layered Model

MeetMind AI Mobile follows a clean, decoupled layer architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  - 12 Core Screens (Dashboard, Studio, Meetings, Tasks...)  │
│  - Directionality / RTL Urdu Nastaliq & LTR Support         │
│  - Material 3 Light / Dark Dynamic Theme                    │
├─────────────────────────────────────────────────────────────┤
│                    State Management (Riverpod)              │
│  - AuthNotifier (Secure Token & Profile Management)         │
│  - VaultNotifier (Offline Audio Vault & Pending Queue)      │
│  - LanguageNotifier (English / Urdu / Roman Urdu)           │
│  - ThemeModeProvider (Dynamic Mode Switching)               │
├─────────────────────────────────────────────────────────────┤
│                    Domain & Service Layer                   │
│  - AudioRecordingService (Native Audio & Amplitude Waveform)│
│  - BackgroundSyncEngine (Auto Recovery & Idempotency)       │
│  - MeetingService & WorkspaceService (REST Endpoints)       │
├─────────────────────────────────────────────────────────────┤
│                    Data & Storage Layer                     │
│  - FlutterSecureStorage (Encrypted SharedPreferences/Keych.)│
│  - VaultDatabase (Local SQLite Persistence via sqflite)     │
│  - ApiClient (HTTP/HTTPS with Ingress Gateway & Retry)      │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Directory Structure

```
mobile_flutter/
├── lib/
│   ├── main.dart                          # App entry point, Riverpod Scope & Navigation Shell
│   ├── core/
│   │   ├── constants/
│   │   │   └── colors.dart                # MeetMind soft pastel color tokens & gradients
│   │   ├── localization/
│   │   │   ├── app_strings.dart           # Re-exported dictionary
│   │   │   └── language_provider.dart     # English, Urdu Nastaliq RTL & Roman Urdu state
│   │   ├── services/
│   │   │   ├── api_client.dart            # Central HTTP client, gateway resolver & retry
│   │   │   ├── auth_service.dart          # Login, Register, Profile, Guest Demo
│   │   │   ├── audio_recording_service.dart # AAC-LC encoder, duration timer & live waveform
│   │   │   ├── background_sync_engine.dart# Network status listener & exponential backoff
│   │   │   ├── meeting_service.dart       # Meetings, Transcripts, Tasks & AI Chat RAG
│   │   │   ├── secure_storage_service.dart# Hardware keystore secret persistence
│   │   │   ├── vault_database.dart        # Local SQLite database for offline recordings
│   │   │   └── workspace_service.dart     # Team workspaces, RBAC roles & collaborative notes
│   │   └── theme/
│   │       └── app_theme.dart             # Material 3 light/dark themes & typography
│   ├── models/
│   │   ├── meeting_detail_model.dart      # Meeting schema, summaries, diarized turns
│   │   ├── task_model.dart                # Action items schema & status lifecycle
│   │   ├── vault_recording_model.dart     # Offline audio vault record & SHA-256 checks
│   │   └── workspace_model.dart           # Cowlar Engineering team & RBAC models
│   ├── providers/
│   │   ├── auth_provider.dart             # Auth state notifier
│   │   ├── meeting_provider.dart          # Meeting list & theme mode
│   │   └── vault_provider.dart            # Vault state notifier & sync event listener
│   └── screens/
│       ├── chat_screen.dart               # Multi-turn RAG chat (Gemini & Ollama guardrail)
│       ├── dashboard_screen.dart          # Home dashboard, KPIs & quick action grid
│       ├── integrations_screen.dart       # 10 enterprise integration providers & scopes
│       ├── login_screen.dart              # Sign In / Sign Up & Demo Guest access
│       ├── meeting_detail_screen.dart     # Full meeting viewer, audio seek, MoM PDF export
│       ├── meetings_screen.dart           # My Meetings library with search & filters
│       ├── memory_screen.dart             # Persistent meeting memory categorized facts
│       ├── recording_studio_screen.dart   # Live recording studio with animated waveform
│       ├── search_screen.dart             # Semantic AI meeting search with ranked hits
│       ├── settings_screen.dart           # Language, theme, custom API gateway & logout
│       ├── tasks_screen.dart              # Action items Kanban & sync to web
│       ├── vault_screen.dart              # Offline audio vault queue & sync states
│       └── workspace_screen.dart          # Team workspace, roster, invites & notes pad
├── test/
│   └── widget_test.dart                   # Unit and widget test suite
├── android/                               # Native Android configuration (Foreground mic service)
├── ios/                                   # Native iOS configuration (Audio background mode)
└── pubspec.yaml                           # Project dependencies and asset declarations
```

---

## 3. Responsive Navigation & 12 Core Views

The application provides a responsive bottom navigation bar with 5 primary destinations (`Home`, `Meetings`, `Record`, `Tasks`, `Ask AI`), coupled with an extensible navigation drawer providing access to all 12 operational views:
1. **Home Dashboard:** High-level metrics, offline vault status, and 1-click recording launch.
2. **My Meetings:** Searchable repository of all processed meetings.
3. **Live Recording Studio:** Audio capture, waveform visualizer, and bookmarking.
4. **AI Meeting Chat:** Context-aware RAG querying over historical meeting records.
5. **Meeting Memory:** Extracted business facts, decisions, and deadlines.
6. **AI Meeting Search:** Cross-meeting semantic hybrid search.
7. **Tasks & Action Items:** Kanban board with real-time web synchronization.
8. **Calendar:** Synced schedules and upcoming milestones.
9. **Knowledge Base:** Company documents and policy manuals.
10. **Team Workspaces:** Multi-tenant workspace management and collaborative notes.
11. **Integrations:** Status of 10 external SaaS connectors.
12. **Settings:** Profile, language, theme, and API endpoint overrides.

