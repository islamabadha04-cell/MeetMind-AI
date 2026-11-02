# AURORA PRO — PRICING & SUBSCRIPTION ENTITLEMENT VERIFICATION

**Platform-Wide Pricing & Entitlement Audit Matrix**

---

## 1. Authoritative Pricing Configuration

| Tier | Public Price | Monthly Minutes | Seats / Scope | Core Features |
| :--- | :--- | :--- | :--- | :--- |
| **Free Starter** | Free Forever (Rs 0) | 120 mins / month | 1 Seat (Personal) | Bilingual Audio Transcription, Action Items, Personal Workspace |
| **Pro Professional** | Rs 2,499 / mo | 1,200 mins / month | 1 Seat (Personal) | Bilingual Speech AI, Cloud Storage Sync, MoM PDF Generator, Priority AI Processing |
| **Team Workspace** | Rs 6,999 / mo | High-Volume Pooled | 10 Member Seats | 10 Team Seats, Shared Memory Vault, Role-Based Access Control, Pooled Minutes |

---

## 2. Cross-Surface Synchronization Audit

| Surface | File Reference | Claims Audited | Verification Result |
| :--- | :--- | :--- | :--- |
| **Landing Page** | `index.html#pricing` | Pro: 1,200 mins/mo @ Rs 2,499<br>Team: 10 seats, pooled mins @ Rs 6,999 | ✅ SYNCHRONIZED |
| **Upgrade Modal** | `app.html#modalUpgrade` | Header: "1,200 AI minutes/month, bilingual speech AI, and cloud sync"<br>Team Card: "10 member seats • High-volume pooled minutes" | ✅ SYNCHRONIZED |
| **Terms of Service** | `terms.html#pricing` | Section 4: Pro 1,200 min cap, Team pooled minutes, manual billing flow | ✅ SYNCHRONIZED |
| **Workspace Settings** | `app.html#wsTierBadge` | Free: 1 Seat Used of 1 Seat<br>Team: 10 Seats Maximum | ✅ SYNCHRONIZED |
| **Backend Engine** | `backend/app/main.py` | `User.minutes_limit = 120` (Free), `1200` (Pro)<br>`Workspace.max_seats = 10` (Team) | ✅ SYNCHRONIZED |

---

## 3. Subscription Security Verification

1. **Anti-Bypass Guard:** A user cannot self-activate Pro tier or upgrade entitlements by merely entering an arbitrary Transaction ID or altering frontend `plan` attributes.
2. **Audit Verification:** All manual upgrades create a `PENDING_VERIFICATION` transaction requiring backend administrative approval.
3. **Database Integrity:** Entitlements are enforced strictly on the server during API calls (`/api/v1/meetings/transcribe-audio`).

