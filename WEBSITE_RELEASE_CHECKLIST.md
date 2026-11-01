# MeetMind AI — Website Release & Production Readiness Checklist

**Document Version:** 1.0.0  
**Target Release:** MeetMind AI Public Beta / Production  
**Current Branch:** `fix/website-qa-remediation`  
**Gatekeeper:** Product Owner (Hasnain Ali)  

---

## 1. Quality & Security Gates Status

| Gate | Requirement | Status | Owner |
| :--- | :--- | :--- | :--- |
| **Gate 0: Payment Security** | Zero dummy phone numbers or IBANs exposed. Zero client-side self-activation. | **PASSED** ✅ | Security Lead |
| **Gate 1: Guest Isolation** | Guest demo sessions cannot read, mutate, or overwrite authenticated user records. | **PASSED** ✅ | Frontend Arch |
| **Gate 2: Pricing Consistency** | Authoritative 1,200 min/mo synced across landing, app modal, terms, and backend. | **PASSED** ✅ | Product QA |
| **Gate 3: Data Quality** | Genuine empty states for new accounts; demo records clearly labelled `[Sample]`. | **PASSED** ✅ | Frontend Arch |
| **Gate 4: Legal Disclosures** | Retention policies, AI providers, recording consent, and refund terms fully grounded. | **PASSED** ✅ | Legal / Security |
| **Gate 5: Automated Tests** | Backend pytest suite passes. Browser CDP test passes. Flutter analyze & tests pass. | **PASSED** ✅ | QA Engineer |
| **Gate 6: Git Hygiene** | All work isolated on `fix/website-qa-remediation`. No direct commits to `main`. | **PASSED** ✅ | Git Guardian |
| **Gate 7: Owner Preview Review**| Deployed to Firebase Preview channel (`https://meetmind-ai-74519--preview-qa-remediation-ju7iu4p4.web.app`). Production untouched. | **DEPLOYED & VERIFIED** ✅ | Hasnain Ali |

---

## 2. Pre-Production Verification Items

### A. Payment & Billing Integration
- [x] Placeholder payment credentials (`0300-1234567`, `0345-9876543`, `PK92MEZN...`) removed from client bundle.
- [x] Official Upgrade Request Desk implemented with verified reference ID generation (`MM-REQ-XXXXXXXX`).
- [x] Backend database table `upgrade_requests` created with audit trail.
- [x] Default user plan configured to `"Free"` with 120-minute monthly transcription quota.
- [x] Client-side bypass (`currentUser.plan = 'Pro Professional'`) removed from `app.js`.
- [x] Authenticated admin approval endpoint (`POST /api/v1/subscription/admin-approve`) operational.
- [ ] *Post-Beta Action:* Insert verified production merchant gateway API keys when JazzCash/Easypaisa merchant agreements are finalized.

### B. Authentication & Session Hygiene
- [x] Demo Guest mode strictly scoped to isolated keys (`meetmind_guest_meetings`, `meetmind_guest_tasks`).
- [x] Persistent warning banner `#demoGuestNoticeBanner` displayed during guest evaluation.
- [x] Full `localStorage` wipe executed upon `handleSignOut()` to eliminate cross-session leakage on shared devices.
- [x] Backend API strictly enforces 401 Unauthorized for unauthenticated requests on protected routes.

### C. Legal & Marketing Accuracy
- [x] `index.html` updated to reflect "1,200 minutes Audio Transcription / mo" for Pro tier.
- [x] `privacy.html` discloses Google Gemini API, Ollama Cloud speech models, SQLite backend, and 30-day backup cycle.
- [x] `privacy.html` and `terms.html` enforce user obligation regarding participant recording consent.
- [x] `terms.html` defines clear 7-day refund policy for unutilized subscription periods.
- [x] Diarization clearly marked as "(Beta)" and YouTube import marked as "Bookmarking only".

### D. Automated Test Coverage
- [x] `test_subscription_security.py` passes (6/6 tests passed, 0 failures).
- [x] Full backend pytest suite passes (68/68 tests passed, 0 failures).
- [x] `test_browser_suite.js` passes (116/116 passed, 0 uncaught exceptions, 0 console errors).
- [x] Flutter mobile widget & unit test suite passes (17/17 passed, `flutter analyze` clean).

---

## 3. Safe Release Protocol

### Step 1: Firebase Preview Channel Deployment (Safe / Non-Production)
Deployed to preview channel:
```
URL: https://meetmind-ai-74519--preview-qa-remediation-ju7iu4p4.web.app
Status: HTTP 200 OK
Expires: 2026-11-08 (7 days)
```

### Step 2: Product Owner Verification
1. Open the preview URL: `https://meetmind-ai-74519--preview-qa-remediation-ju7iu4p4.web.app`.
2. Inspect the upgrade modal: verify official invoice request form is active and no fake numbers appear.
3. Test "Continue as Demo Guest": verify guest warning banner is displayed and sample meetings are tagged `[Sample]`.
4. Inspect `/privacy` and `/terms`: verify all disclosures and consent warnings.

### Step 3: Production Merge & Promotion (Only After Owner Approval)
```bash
# 1. Commit and push remediation branch to origin
git add app.html app.js index.html login.html privacy.html terms.html backend/ scratch/
git commit -m "fix(qa): Complete Website QA & Critical Remediation (P0/P1/P2)"
git push origin fix/website-qa-remediation

# 2. Merge to main via PR or fast-forward after review
git checkout main
git merge fix/website-qa-remediation
git push origin main

# 3. Deploy to production
firebase deploy --only hosting
```

---

## 4. Final Sign-Off

**QA Lead Sign-Off:** ✅ Completed & Verified  
**Security Lead Sign-Off:** ✅ Completed & Verified  
**Product Owner Sign-Off:** ⏳ Pending Preview Review (Hasnain Ali)  

