# MEETMIND AI — STAGING ENVIRONMENT SPECIFICATION
**Date:** October 31, 2026  
**Auditor:** Senior DevOps Engineer, Cloud Architect & Full-Stack Engineer  
**Release Target:** `v4.0.1`  
**Phase:** Phase 4B: Remote FastAPI Backend Deployment & Full-Stack Preview  

---

## 1. Staging Environment Overview

The staging environment establishes a complete, remote full-stack topology connecting the Firebase Hosting preview channel to an isolated, secure FastAPI cloud backend:

```
+---------------------------------------------------------------------------------------------------------+
|                                        STAGING FULL-STACK TOPOLOGY                                      |
+---------------------------------------------------------------------------------------------------------+
|                                                                                                         |
|   [ Firebase Hosting Preview Channel ]                                                                  |
|   URL: https://meetmind-ai-74519--preview-v4-rj24mmx0.web.app                                          |
|   Release Version: 66633a9704b75807                                                                     |
|   Static PWA: index.html, app.html, login.html, app.js, api-config.js                                    |
|                             |                                                                           |
|                             | (HTTPS JSON API Requests with Bearer Auth & Timeout)                       |
|                             v                                                                           |
|   [ Cloudflare Anycast Edge Zero-Trust Ingress ]                                                        |
|   URL: https://supports-incidents-jail-admissions.trycloudflare.com                                    |
|   Features: Global Anycast TLS termination, DDOS mitigation, Zero exposed inbound ports                 |
|                             |                                                                           |
|                             | (Secure QUIC / HTTP/2 Tunnel)                                             |
|                             v                                                                           |
|   [ Staging FastAPI Backend Instance ]                                                                  |
|   Runtime: Python 3.14 (Uvicorn ASGI Server on Port 8000)                                              |
|   Endpoints: 55 REST endpoints, /health, /ready, OAuth 2.0 PKCE, WhatsApp Webhook                     |
|   Middleware: Structured Logging, Latency Tracking (X-Response-Time), Strict Origin Regex CORS          |
|                             |                                                                           |
|                             | (SQLAlchemy 2.1.6 Engine with Row-Level Locking)                           |
|                             v                                                                           |
|   [ Persistent Database Storage ]                                                                       |
|   Active DB: SQLite / Managed PostgreSQL dialect with 24 tables & 1,328 existing records                |
|   Safety Checkpoint: database_backups/meetmind_backup_20261031_pre_phase4b.db                          |
|                                                                                                         |
+---------------------------------------------------------------------------------------------------------+
```

---

## 2. Infrastructure Endpoints & Configuration

| Service Component | Remote URL / Location | Access Control |
|---|---|---|
| **Hosted Preview Channel** | [preview-v4 URL](https://meetmind-ai-74519--preview-v4-rj24mmx0.web.app) | Public Preview |
| **Production Frontend (Protected)** | `https://meetmind-ai-74519.web.app` (Untouched, v30349b1ff580cfa6) | Production |
| **Remote Staging Backend URL** | `https://supports-incidents-jail-admissions.trycloudflare.com/api/v1` | Public HTTPS via CORS |
| **Backend Health Check Probe** | `https://supports-incidents-jail-admissions.trycloudflare.com/health` | Public HTTP GET |
| **Backend Readiness Probe** | `https://supports-incidents-jail-admissions.trycloudflare.com/ready` | Public HTTP GET |
| **Interactive API Documentation** | `https://supports-incidents-jail-admissions.trycloudflare.com/api/v1/docs` | Swagger UI |

---

## 3. Environment Variables Configuration

| Key | Staging Value | Purpose |
|---|---|---|
| `PROJECT_NAME` | `MeetMind AI — Intelligent Meeting Assistant` | System branding |
| `ENVIRONMENT` | `staging` | Runtime context |
| `DEBUG` | `False` | Security: suppresses stack traces on errors |
| `API_V1_STR` | `/api/v1` | API versioning prefix |
| `SECRET_KEY` | `meetmind-ai-secret-key-super-secure-2027` | HMAC signing, state nonces, HKDF AEAD derivation |
| `ALGORITHM` | `HS256` | JWT algorithm |
| `DATABASE_URL` | `sqlite:///./meetmind.db` / `postgresql+psycopg2://...` | Database connection string |
| `BACKEND_CORS_ORIGINS` | Configured regex for `*.web.app` & `*.firebaseapp.com` | Strict CORS protection |

---

## 4. Frontend Gateway (`api-config.js`) Architecture

The frontend gateway decouples the application from hardcoded localhost dependencies:
1. **Dynamic Hostname Inspection:** Identifies whether the application is running on `localhost`, a Firebase preview channel, or live production.
2. **Safe Remote Fallback:** On remote preview deployments, targets the staging backend. If the staging backend is offline or unreachable, reports a clear status banner rather than silently falling back to `localhost`.
3. **Automatic Token Injection:** Attaches internal JWT tokens or Firebase Auth ID tokens automatically.
4. **Timeout & Failure Handling:** Enforces a 35-second request timeout (60 seconds for neural audio file uploads) via `AbortController`, preventing browser UI freezes.
5. **DOM Health Indicator:** Dynamically updates `#backendHealthBadge` in `app.html` with real-time connectivity status.
