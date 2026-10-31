# MeetMind AI — Complete Deployment & DevOps Guide
**Production URL:** `https://meetmind-ai-74519.web.app`  
**Firebase Project ID:** `meetmind-ai-74519`  
**Stack:** Vanilla Modern JavaScript (ES2026), Firebase Hosting, Cloud Firestore, Cloud Storage, Python 3.11+ FastAPI backend  

---

## 1. System Requirements & Prerequisites

Ensure the following runtimes and tools are installed:
- **Node.js:** v18.x or v20.x LTS
- **Firebase CLI:** v12+ (`npm install -g firebase-tools`)
- **Python:** v3.10+ (v3.11 recommended)
- **Git:** v2.30+
- **Google Chrome / Chromium:** For automated headless integration testing

---

## 2. Environment Configuration

### 2.1 Backend `.env` (`backend/.env`)
Create `backend/.env` with the following variables:
```env
PROJECT_NAME="MeetMind AI"
API_V1_STR="/api/v1"
SECRET_KEY="YOUR_SUPER_SECRET_PRODUCTION_KEY_HEX"
ACCESS_TOKEN_EXPIRE_MINUTES=10080
GEMINI_API_KEY="YOUR_GEMINI_API_KEY_HERE"
DATABASE_URL="sqlite:///./smart_noter.db"
# For production PostgreSQL:
# DATABASE_URL="postgresql://user:password@localhost:5432/meetmind"
```

### 2.2 Frontend Configuration (`firebase-service.js`)
Configured to production project `meetmind-ai-74519`:
```javascript
const firebaseConfig = {
  apiKey: "AIzaSyAVogcGOhsv2UgEAOEsCICkfMRrfD8dd_4",
  authDomain: "meetmind-ai-74519.firebaseapp.com",
  projectId: "meetmind-ai-74519",
  storageBucket: "meetmind-ai-74519.firebasestorage.app",
  messagingSenderId: "790778332182",
  appId: "1:790778332182:web:b4a2c8ebbd8720a61f6137",
  measurementId: "G-GKBBKE3046"
};
```

---

## 3. Frontend Deployment to Firebase Hosting

Deploying the frontend requires zero build steps (no Webpack/Vite bundling latency). All ES modules load natively.

```bash
# 1. Login to Firebase CLI
firebase login

# 2. Verify active project
firebase use meetmind-ai-74519

# 3. Deploy Firestore rules and static hosting
firebase deploy --only firestore:rules,hosting
```

*(On Windows PowerShell with execution policy restrictions, use `cmd.exe /c npx firebase-tools deploy --only hosting`)*.

---

## 4. Backend Deployment (FastAPI)

### 4.1 Staging Backend Deployment with Cloud Edge Ingress
The remote staging backend establishes an isolated HTTPS cloud edge:
```bash
# 1. Start FastAPI backend with app-dir
cd hasnain
backend\.venv\Scripts\python -m uvicorn app.main:app --app-dir backend --host 127.0.0.1 --port 8000

# 2. Start Cloudflare Anycast Ingress Tunnel (No ports opened, zero cold start)
cmd.exe /c npx cloudflared tunnel --url http://127.0.0.1:8000

# 3. Test Health & Readiness Probes
curl https://supports-incidents-jail-admissions.trycloudflare.com/health
curl https://supports-incidents-jail-admissions.trycloudflare.com/ready
```

### 4.2 Firebase Hosting Preview Channel Deployment
```bash
# Deploy isolated preview frontend linked to remote staging backend
cmd.exe /c npx firebase-tools hosting:channel:deploy preview-v4 --expires 7d
```

### 4.3 Production Docker Deployment (Cloud Run / VPS)
Use the included Dockerfile configuration:

```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/app ./app
EXPOSE 8080

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "4"]
```

Build and deploy to Google Cloud Run:
```bash
gcloud run deploy meetmind-backend \
  --source backend \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars GEMINI_API_KEY="YOUR_KEY"
```

---

## 5. Automated Pre-Deployment Verification

Before executing any production deploy, run the automated verification suite:

```bash
# 1. Run headless Chrome CDP test suite (46 comprehensive checks)
node scratch/test_browser_suite.js

# 2. Run backend pytest suite
cd backend
pytest -v
```

### 5.1 Verification Checklist
- [x] All 46 headless browser unit & integration tests pass (0 failures).
- [x] Authentication state machine transitions smoothly between Guest, Email, and Google accounts.
- [x] Audio-to-Transcript timestamp synchronization seeks accurately.
- [x] MoM PDF generator renders clean branded headers and tabular action items.
- [x] Universal `.ics` and Google Calendar export triggers without console errors.
- [x] Pakistani payment modal provides instant clipboard copy for JazzCash, Easypaisa, and Raast.
- [x] Firestore security rules block unauthorized cross-user queries.

