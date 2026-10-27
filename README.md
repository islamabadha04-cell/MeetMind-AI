# 🎙️ MeetMind AI — Next-Generation AI Meeting Assistant (2027)

> **Transform conversations into actionable insights.** AI-powered meeting recording, real-time speech-to-text, structured summaries, smart action item management, and conversational meeting search (RAG).

![MeetMind AI](assets/orb.jpg)

---

## ✨ Key Features

- **AI Voice Recording Studio**: Live oscillating waveform, real-time timer, bookmarks, trimming, and instant summarization.
- **Structured AI Summaries**: Executive summary, key decisions, action items with owners and deadlines, and risks analysis.
- **Ask Your Meetings (RAG Chat)**: Conversational AI interface searching authorized meeting records with timestamped citations.
- **Smart Task Manager**: Extracted checklist with assignees, priority levels (High/Medium/Low), and completion tracking.
- **Multi-Source Import**: YouTube video links with chapter extraction, Zoom/Google Meet links, and PDF/DOCX documents.
- **Multi-Platform Support**:
  - **PWA Mobile App**: Standalone mobile installation on Android and iOS with offline support (`manifest.json` & `sw.js`).
  - **Desktop Web App**: Dual Light & Dark theme dashboard with quick actions and stats.
  - **Flutter Mobile App**: Clean, modular Flutter & Riverpod architecture in `mobile_flutter/`.
- **Production FastAPI Backend**: REST API with OpenAPI documentation, JWT authentication, SQLite/PostgreSQL support, and Docker containerization.

---

## 🏗️ Project Architecture

```
├── assets/                  # App branding, icons, and illustrations
├── backend/                 # Python FastAPI Backend
│   ├── app/
│   │   ├── api/v1/          # Versioned REST API routers (auth, meetings, tasks, chat)
│   │   ├── core/            # Config, security, JWT
│   │   ├── db/              # SQLAlchemy session & base
│   │   ├── models/          # ORM models (User, Meeting, Task, Summary, Chat)
│   │   ├── schemas/         # Pydantic V2 validation schemas
│   │   └── services/        # AI summarizer, speech transcription, RAG search
│   ├── tests/               # Pytest automated test suite
│   ├── Dockerfile           # Backend container image
│   └── requirements.txt     # Python dependencies
├── mobile_flutter/          # Flutter Native Application
│   ├── lib/
│   │   ├── core/theme/      # Light & Dark themes with Inter typography
│   │   ├── models/          # Dart models
│   │   ├── providers/       # Riverpod state management
│   │   └── screens/         # Dashboard, Recording, Summary, Chat screens
│   └── pubspec.yaml         # Flutter dependencies
├── .github/workflows/       # Automated CI/CD Pipelines (Pytest & Docker)
├── index.html               # Frontend Web App & PWA
├── style.css                # Universal CSS Design System (Light & Dark)
├── app.js                   # Client Logic, Web Audio API, RAG Engine
├── manifest.json            # PWA Web App Manifest
├── sw.js                    # PWA Service Worker (Offline Cache)
├── docker-compose.yml       # Production container orchestration
└── deploy_server.sh         # 1-Click Ubuntu VPS server setup script
```

---

## 🚀 Quick Start

### 1. Web & Mobile App (PWA)
Open `index.html` in your browser or run the lightweight server:
```bash
python -m http.server 8080
```
Visit `http://localhost:8080` or open on mobile over local network to install on home screen!

### 2. Python FastAPI Backend
```bash
cd backend
python -m venv .venv
# On Windows:
.\.venv\Scripts\activate
# On Linux/macOS:
source .venv/bin/activate

pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
Interactive API Swagger Docs: `http://localhost:8000/api/v1/docs`

### 3. Run Automated Tests
```bash
cd backend
pytest -o pythonpath=. tests
```

### 4. Flutter Mobile App
```bash
cd mobile_flutter
flutter pub get
flutter run
```

---

## 📄 License
MIT License. Built for the Next-Generation AI Productivity Platform (2027).
