# 🏗️ MeetMind AI — Phase 4 System Architecture
**Version:** 4.0.0  
**Status:** Completed & 100% Verified  
**Date:** October 31, 2026  

---

## 1. Architectural Overview

Phase 4 establishes an enterprise-grade **Third-Party Integrations Ecosystem** for MeetMind AI. The architecture enables bi-directional data flow between MeetMind AI and the core productivity tools that teams use daily:
- **Google Workspace** (Google Calendar, Gmail, Google Drive)
- **Microsoft 365** (Outlook Calendar, Outlook Mail)
- **Project Management** (Atlassian Jira Cloud, Trello)
- **Team Communication & Knowledge** (Slack, Notion)
- **Downstream Automation** (Zapier, Make, and Generic Webhooks)
- **Mobile Messaging & Voice** (WhatsApp Business Platform / Meta Cloud API)

```
                     ┌──────────────────────────────────────────┐
                     │          MeetMind AI Frontend            │
                     │  (Integration Center / Tasks / MoM / UI) │
                     └────────────────────┬─────────────────────┘
                                          │ REST API / JWT
                                          ▼
                     ┌──────────────────────────────────────────┐
                     │          FastAPI Microservice            │
                     │      (/api/v1/integrations/*)            │
                     └───────┬──────────────────────────┬───────┘
                             │                          │
           ┌─────────────────┴────────┐       ┌─────────┴───────────────────┐
           ▼                          ▼       ▼                             ▼
┌──────────────────────┐  ┌───────────────┐ ┌────────────────────┐ ┌──────────────────────┐
│  IntegrationService  │  │ WebhookEngine │ │ Google/MS/Atlassian│ │ Meta WhatsApp Cloud  │
│  - AES-256 Crypto    │  │ - HMAC-SHA256 │ │ OAuth 2.0 PKCE     │ │ Webhook Ingestion    │
│  - State Generator   │  │ - Deliveries  │ │ - Calendar, Mail   │ │ - Voice Note Audio   │
│  - Token Refresh     │  │ - Retry Queue │ │ - Drive, Jira, Card│ │ - AI Transcription   │
└──────────┬───────────┘  └───────┬───────┘ └─────────┬──────────┘ └──────────┬───────────┘
           │                      │                   │                       │
           └──────────────────────┼───────────────────┴───────────────────────┘
                                  ▼
           ┌─────────────────────────────────────────────┐
           │      Database Models (SQLite / PostgreSQL)  │
           │  • integrations                             │
           │  • external_entity_mappings                 │
           │  • webhook_subscriptions & deliveries       │
           │  • integration_jobs                         │
           └─────────────────────────────────────────────┘
```

---

## 2. Core Architectural Principles

1. **Security & Least Privilege:**
   - Raw tokens are **never** returned to the browser or stored in client-readable Firestore documents.
   - Tokens are encrypted at rest using server-side AES-256 (`cryptography.fernet`).
   - Every provider requests minimal delegated scopes (e.g. `gmail.compose` for draft generation; mailbox reading is strictly blocked).
2. **Draft-Only Safeguard:**
   - Follow-up emails created in Gmail or Outlook are saved **strictly as drafts**. No automated emails are ever dispatched without explicit human review in the email client.
3. **Decoupled Calendar Realism:**
   - The dashboard upcoming events widget dynamically binds to real connected calendar events and user tasks with deadlines.
   - Static placeholder demo meetings are completely eliminated.
4. **Idempotency & Mapping Integrity:**
   - External mappings are indexed in `external_entity_mappings` (`provider`, `entity_type`, `internal_id`, `external_id`).
   - Re-syncing an approved task updates the existing external calendar event or Jira issue rather than creating duplicates.
5. **Multi-Tenant Row Isolation:**
   - Every integration record and webhook subscription is bound to `current_user.id`.
   - Cross-tenant lookups and dispatches are blocked with `404 Not Found` or `403 Forbidden`.

