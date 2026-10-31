import pytest
from fastapi.testclient import TestClient
import json
import time
import base64

from app.main import app, startup_db_seed

@pytest.fixture(autouse=True, scope="module")
def setup_seed():
    startup_db_seed()

@pytest.fixture
def client():
    return TestClient(app)

@pytest.fixture(scope="module")
def auth_users():
    c = TestClient(app)
    stamp = int(time.time() * 1000)
    
    # User A
    res_a = c.post("/api/v1/auth/register", json={
        "email": f"integ_user_a_{stamp}@corp.com",
        "password": "Password123!",
        "full_name": "Integration User A"
    })
    token_a = res_a.json()["access_token"]
    headers_a = {"Authorization": f"Bearer {token_a}"}

    # User B
    res_b = c.post("/api/v1/auth/register", json={
        "email": f"integ_user_b_{stamp}@corp.com",
        "password": "Password123!",
        "full_name": "Integration User B"
    })
    token_b = res_b.json()["access_token"]
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # User A creates a meeting and a task
    m_res = c.post("/api/v1/meetings", json={
        "title": "Phase 4 Architecture & Integrations Sync",
        "category": "Meetings",
        "transcript_text": "We need to connect Google Calendar, Gmail, Jira, and webhooks by end of week."
    }, headers=headers_a)
    meeting_id = m_res.json()["id"]

    t_res = c.post("/api/v1/tasks", json={
        "title": "Finalize Google Workspace OAuth Verification",
        "meeting_id": meeting_id,
        "assignee": "Integration User A",
        "deadline": "2026-11-05",
        "priority": "urgent"
    }, headers=headers_a)
    task_id = t_res.json()["id"]

    return {
        "headers_a": headers_a,
        "headers_b": headers_b,
        "meeting_id": meeting_id,
        "task_id": task_id
    }

# --------------------------------------------------------------------------
# Phase 4 Tests
# --------------------------------------------------------------------------

def test_list_all_10_providers(client, auth_users):
    headers = auth_users["headers_a"]
    res = client.get("/api/v1/integrations", headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert len(data) == 10
    providers = [item["provider"] for item in data]
    expected = [
        "google_calendar", "gmail", "google_drive", "outlook",
        "jira", "trello", "slack", "notion", "zapier", "whatsapp"
    ]
    for exp in expected:
        assert exp in providers
    # Verify default state
    assert all(item["connection_status"] in ["not_connected", "connected", "disconnected"] for item in data)

def test_oauth_connect_url_generation(client, auth_users):
    headers = auth_users["headers_a"]
    res = client.post("/api/v1/integrations/google_calendar/connect", json={}, headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert data["connection_status"] == "connecting"
    assert "accounts.google.com" in data["auth_url"]
    assert "calendar.events" in data["auth_url"]

def test_direct_connect_and_test(client, auth_users):
    headers = auth_users["headers_a"]
    connect_payload = {
        "api_key": "trello_mock_key_123",
        "token": "trello_mock_token_456",
        "account_email": "user_a@corp.com"
    }
    res = client.post("/api/v1/integrations/trello/connect", json=connect_payload, headers=headers)
    assert res.status_code == 200
    assert res.json()["connection_status"] == "connected"

    # Test Trello connection
    test_res = client.post("/api/v1/integrations/trello/test", headers=headers)
    assert test_res.status_code == 200
    assert test_res.json()["success"] is True

def test_disconnect_provider(client, auth_users):
    headers = auth_users["headers_a"]
    res = client.post("/api/v1/integrations/trello/disconnect", headers=headers)
    assert res.status_code == 200
    assert res.json()["status"] == "disconnected"

    # Check status updated
    get_res = client.get("/api/v1/integrations/trello", headers=headers)
    assert get_res.status_code == 200
    assert get_res.json()["connection_status"] == "disconnected"

def test_upcoming_calendar_events_no_placeholders(client, auth_users):
    headers = auth_users["headers_a"]
    res = client.get("/api/v1/integrations/calendar/upcoming", headers=headers)
    assert res.status_code == 200
    events = res.json()
    # Must contain the user's real task deadline
    assert len(events) >= 1
    assert any("Finalize Google Workspace OAuth Verification" in e["title"] for e in events)
    # Must NOT contain hardcoded static placeholders
    assert not any("Client Review Meeting" == e["title"] and e["source"] == "static" for e in events)

def test_google_calendar_sync_task(client, auth_users):
    headers = auth_users["headers_a"]
    task_id = auth_users["task_id"]
    res = client.post("/api/v1/integrations/google-calendar/sync-task", json={"task_id": task_id}, headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is True
    assert "gcal_" in data["event_id"]

def test_gmail_create_draft_strictly_draft_only(client, auth_users):
    headers = auth_users["headers_a"]
    payload = {
        "recipient": "client@acme.com",
        "subject": "Minutes of Meeting — Phase 4 Review",
        "body": "Dear Client,\nHere are the agreed milestones and action items."
    }
    res = client.post("/api/v1/integrations/gmail/create-draft", json=payload, headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is True
    assert data["status"] == "draft_created"
    assert "Draft-Only" in data["message"]

def test_google_drive_list_and_import(client, auth_users):
    headers = auth_users["headers_a"]
    # List files
    files_res = client.get("/api/v1/integrations/google-drive/files", headers=headers)
    assert files_res.status_code == 200
    files = files_res.json()
    assert len(files) >= 1

    # Import file
    import_payload = {
        "file_id": files[0]["id"],
        "file_name": files[0]["name"]
    }
    import_res = client.post("/api/v1/integrations/google-drive/import", json=import_payload, headers=headers)
    assert import_res.status_code == 200
    assert import_res.json()["success"] is True
    assert import_res.json()["chunks_indexed"] >= 1

def test_jira_and_trello_task_creation(client, auth_users):
    headers = auth_users["headers_a"]
    task_id = auth_users["task_id"]

    # Jira
    jira_res = client.post("/api/v1/integrations/jira/create-issue", json={"task_id": task_id, "project_key": "CORE"}, headers=headers)
    assert jira_res.status_code == 200
    assert "CORE-" in jira_res.json()["issue_key"]

    # Trello
    trello_res = client.post("/api/v1/integrations/trello/create-card", json={"task_id": task_id, "board_id": "board_001"}, headers=headers)
    assert trello_res.status_code == 200
    assert "card_id" in trello_res.json()

def test_slack_and_notion_exports(client, auth_users):
    headers = auth_users["headers_a"]
    meeting_id = auth_users["meeting_id"]

    # Slack
    slack_res = client.post("/api/v1/integrations/slack/post-summary", json={"meeting_id": meeting_id, "channel_id": "C01234567"}, headers=headers)
    assert slack_res.status_code == 200
    assert slack_res.json()["success"] is True

    # Notion
    notion_res = client.post("/api/v1/integrations/notion/export-page", json={"meeting_id": meeting_id}, headers=headers)
    assert notion_res.status_code == 200
    assert "notion_" in notion_res.json()["page_id"]

def test_webhook_engine_subscription_and_dispatch(client, auth_users):
    headers = auth_users["headers_a"]
    # Subscribe
    sub_payload = {
        "name": "Zapier Meeting Automation",
        "target_url": "https://hooks.zapier.com/hooks/catch/12345/abcde",
        "events": ["meeting.completed", "task.approved"]
    }
    sub_res = client.post("/api/v1/integrations/webhooks/subscriptions", json=sub_payload, headers=headers)
    assert sub_res.status_code == 200
    sub_data = sub_res.json()
    assert "sec_live_" in sub_data["secret_key"]
    sub_id = sub_data["id"]

    # Test dispatch
    dispatch_res = client.post(f"/api/v1/integrations/webhooks/test-dispatch?subscription_id={sub_id}&event_type=meeting.completed", headers=headers)
    assert dispatch_res.status_code == 200
    assert dispatch_res.json()["event_type"] == "meeting.completed"

def test_whatsapp_meta_cloud_webhook(client):
    import hmac
    import hashlib
    import os

    # 1. Verification challenge
    verify_res = client.get("/api/v1/integrations/whatsapp/webhook?hub.mode=subscribe&hub.verify_token=meetmind_meta_webhook_secret_2026&hub.challenge=115599")
    assert verify_res.status_code == 200
    assert verify_res.text.strip('"') == "115599"

    # 2. Inbound voice note with valid X-Hub-Signature-256
    app_secret = os.getenv("META_APP_SECRET", "meetmind_meta_app_secret_test_2026")
    msg_id = f"wamid_test_{int(time.time() * 1000)}"
    voice_note_payload = {
        "object": "whatsapp_business_account",
        "entry": [{
            "id": "WHATSAPP_BUSINESS_ACCOUNT_ID",
            "changes": [{
                "value": {
                    "messaging_product": "whatsapp",
                    "messages": [{
                        "id": msg_id,
                        "from": "+923001234567",
                        "type": "audio",
                        "timestamp": str(int(time.time())),
                        "audio": {"id": "media_audio_001", "mime_type": "audio/ogg"}
                    }]
                }
            }]
        }]
    }
    raw_payload = json.dumps(voice_note_payload).encode("utf-8")
    sig_hash = hmac.new(app_secret.encode("utf-8"), raw_payload, hashlib.sha256).hexdigest()
    valid_headers = {"X-Hub-Signature-256": f"sha256={sig_hash}", "Content-Type": "application/json"}

    post_res = client.post("/api/v1/integrations/whatsapp/webhook", content=raw_payload, headers=valid_headers)
    assert post_res.status_code == 200
    assert post_res.json()["status"] == "success"

def test_whatsapp_webhook_signature_rejections_and_filters(client):
    import hmac
    import hashlib
    import os

    app_secret = os.getenv("META_APP_SECRET", "meetmind_meta_app_secret_test_2026")
    msg_id = f"wamid_filter_{int(time.time() * 1000)}"
    payload = {
        "object": "whatsapp_business_account",
        "entry": [{
            "id": "WHATSAPP_BUSINESS_ACCOUNT_ID",
            "changes": [{
                "value": {
                    "messaging_product": "whatsapp",
                    "messages": [{
                        "id": msg_id,
                        "from": "+923009999999",
                        "type": "audio",
                        "timestamp": str(int(time.time())),
                        "audio": {"id": "media_audio_002", "mime_type": "audio/ogg"}
                    }]
                }
            }]
        }]
    }
    raw_bytes = json.dumps(payload).encode("utf-8")
    valid_sig = "sha256=" + hmac.new(app_secret.encode("utf-8"), raw_bytes, hashlib.sha256).hexdigest()

    # 1. Missing signature -> 401
    res_no_sig = client.post("/api/v1/integrations/whatsapp/webhook", content=raw_bytes, headers={"Content-Type": "application/json"})
    assert res_no_sig.status_code == 401

    # 2. Invalid signature -> 401
    res_bad_sig = client.post("/api/v1/integrations/whatsapp/webhook", content=raw_bytes, headers={
        "X-Hub-Signature-256": "sha256=0000000000000000000000000000000000000000000000000000000000000000",
        "Content-Type": "application/json"
    })
    assert res_bad_sig.status_code == 401

    # 3. Modified payload after signature calculation -> 401
    tampered_bytes = raw_bytes + b" "
    res_tampered = client.post("/api/v1/integrations/whatsapp/webhook", content=tampered_bytes, headers={
        "X-Hub-Signature-256": valid_sig,
        "Content-Type": "application/json"
    })
    assert res_tampered.status_code == 401

    # 4. Valid dispatch
    res_valid = client.post("/api/v1/integrations/whatsapp/webhook", content=raw_bytes, headers={
        "X-Hub-Signature-256": valid_sig,
        "Content-Type": "application/json"
    })
    assert res_valid.status_code == 200
    assert res_valid.json()["status"] == "success"

    # 5. Duplicate message -> detected and rejected from reprocessing
    res_dup = client.post("/api/v1/integrations/whatsapp/webhook", content=raw_bytes, headers={
        "X-Hub-Signature-256": valid_sig,
        "Content-Type": "application/json"
    })
    assert res_dup.status_code == 200
    assert res_dup.json()["status"] == "duplicate"

    # 6. Expired media (> 24 hours = 86400s)
    old_msg_id = f"wamid_old_{int(time.time() * 1000)}"
    expired_payload = {
        "object": "whatsapp_business_account",
        "entry": [{
            "id": "WHATSAPP_BUSINESS_ACCOUNT_ID",
            "changes": [{
                "value": {
                    "messaging_product": "whatsapp",
                    "messages": [{
                        "id": old_msg_id,
                        "from": "+923009999999",
                        "type": "audio",
                        "timestamp": str(int(time.time()) - 90000), # > 24 hours ago
                        "audio": {"id": "media_audio_expired", "mime_type": "audio/ogg"}
                    }]
                }
            }]
        }]
    }
    exp_bytes = json.dumps(expired_payload).encode("utf-8")
    exp_sig = "sha256=" + hmac.new(app_secret.encode("utf-8"), exp_bytes, hashlib.sha256).hexdigest()
    res_exp = client.post("/api/v1/integrations/whatsapp/webhook", content=exp_bytes, headers={
        "X-Hub-Signature-256": exp_sig,
        "Content-Type": "application/json"
    })
    assert res_exp.status_code == 200
    assert res_exp.json()["status"] == "rejected"
    assert res_exp.json()["reason"] == "expired_media"

def test_integrations_multi_tenant_isolation(client, auth_users):
    headers_a = auth_users["headers_a"]
    headers_b = auth_users["headers_b"]

    # User A creates a webhook subscription
    sub_payload = {
        "name": "User A Private Webhook",
        "target_url": "https://example.com/user_a/webhook",
        "events": ["meeting.completed"]
    }
    res_a = client.post("/api/v1/integrations/webhooks/subscriptions", json=sub_payload, headers=headers_a)
    assert res_a.status_code == 200
    sub_id_a = res_a.json()["id"]

    # User B lists webhooks: must NOT see User A's subscription
    res_b = client.get("/api/v1/integrations/webhooks/subscriptions", headers=headers_b)
    assert res_b.status_code == 200
    b_subs = res_b.json()
    assert not any(s["id"] == sub_id_a for s in b_subs)

    # User B tries to dispatch User A's webhook: must return 404
    hack_res = client.post(f"/api/v1/integrations/webhooks/test-dispatch?subscription_id={sub_id_a}", headers=headers_b)
    assert hack_res.status_code == 404

# --------------------------------------------------------------------------
# Phase 4 Security Hardening: AES-256-GCM, OAuth Replay, PKCE, Draft-Only
# --------------------------------------------------------------------------

def test_aes_256_gcm_encryption_and_backward_compatibility():
    from app.services.integration_service import encrypt_token, decrypt_token, _get_fernet_key
    from cryptography.fernet import Fernet

    secret_data = "ghp_live_access_token_secure_9999"
    
    # 1. AES-256-GCM encryption produces 'gcm:' prefix
    encrypted_gcm = encrypt_token(secret_data)
    assert encrypted_gcm.startswith("gcm:")
    
    # Decrypt returns original plaintext
    decrypted_gcm = decrypt_token(encrypted_gcm)
    assert decrypted_gcm == secret_data

    # Two encryptions produce different ciphertexts due to fresh 96-bit random nonce
    encrypted_gcm_2 = encrypt_token(secret_data)
    assert encrypted_gcm != encrypted_gcm_2
    assert decrypt_token(encrypted_gcm_2) == secret_data

    # 2. Backward compatibility with legacy Fernet encrypted tokens
    legacy_fernet = Fernet(_get_fernet_key()).encrypt(secret_data.encode()).decode()
    assert not legacy_fernet.startswith("gcm:")
    decrypted_legacy = decrypt_token(legacy_fernet)
    assert decrypted_legacy == secret_data

def test_oauth_state_nonce_and_replay_protection(client, auth_users):
    from app.services.integration_service import generate_oauth_state, verify_and_consume_oauth_state
    headers = auth_users["headers_a"]

    # 1. Generate legitimate state
    state = generate_oauth_state(user_id=1, provider="google_calendar")
    assert len(state) > 40

    # 2. First verification must succeed and consume the nonce
    res_1 = verify_and_consume_oauth_state(state, expected_user_id=1, expected_provider="google_calendar")
    assert res_1["valid"] is True
    assert "nonce" in res_1

    # 3. Replay attack: Second verification with EXACT same state must be rejected
    res_2 = verify_and_consume_oauth_state(state, expected_user_id=1, expected_provider="google_calendar")
    assert res_2["valid"] is False
    assert res_2.get("replayed") is True
    assert "already consumed" in res_2["reason"]

    # 4. Tampered state rejected
    tampered_state = state[:-5] + "AAAAA"
    res_tampered = verify_and_consume_oauth_state(tampered_state, expected_user_id=1, expected_provider="google_calendar")
    assert res_tampered["valid"] is False

def test_oauth_callback_with_state_validation_and_replay_rejection(client, auth_users):
    from app.services.integration_service import generate_oauth_state
    headers = auth_users["headers_a"]

    # Get actual user_id for User A
    me_res = client.get("/api/v1/users/me", headers=headers)
    assert me_res.status_code == 200
    user_id = me_res.json()["id"]

    # Generate legitimate state for User A
    valid_state = generate_oauth_state(user_id=user_id, provider="google_calendar")

    # 1. First callback with valid state succeeds
    cb_payload = {
        "auth_code": "auth_code_legitimate_12345",
        "state": valid_state
    }
    res_1 = client.post("/api/v1/integrations/google_calendar/callback", json=cb_payload, headers=headers)
    assert res_1.status_code == 200
    assert res_1.json()["connection_status"] == "connected"

    # 2. Replay attack: calling callback again with the already-consumed state must return HTTP 400
    res_2 = client.post("/api/v1/integrations/google_calendar/callback", json=cb_payload, headers=headers)
    assert res_2.status_code == 400
    assert "OAuth state verification failed" in res_2.json()["detail"]
    assert "already consumed" in res_2.json()["detail"]

def test_pkce_generation():
    from app.services.integration_service import generate_pkce_codes
    import hashlib
    import base64

    pkce = generate_pkce_codes()
    assert "code_verifier" in pkce
    assert "code_challenge" in pkce
    assert pkce["code_challenge_method"] == "S256"

    # Verify SHA-256 base64url transformation
    verifier = pkce["code_verifier"]
    expected_digest = hashlib.sha256(verifier.encode("utf-8")).digest()
    expected_challenge = base64.urlsafe_b64encode(expected_digest).decode("utf-8").rstrip("=")
    assert pkce["code_challenge"] == expected_challenge

def test_server_side_draft_only_enforcement(client, auth_users):
    headers = auth_users["headers_a"]

    # 1. Gmail draft creation works
    draft_res = client.post("/api/v1/integrations/gmail/create-draft", json={
        "recipient": "exec@domain.com",
        "subject": "Executive Summary",
        "body": "Meeting notes..."
    }, headers=headers)
    assert draft_res.status_code == 200
    assert draft_res.json()["status"] == "draft_created"

    # 2. Gmail automated send is strictly blocked with HTTP 403 Forbidden
    send_res = client.post("/api/v1/integrations/gmail/send", headers=headers)
    assert send_res.status_code == 403
    assert "Automated email sending is strictly prohibited" in send_res.json()["detail"]

    # 3. Outlook automated send is strictly blocked with HTTP 403 Forbidden
    outlook_send_res = client.post("/api/v1/integrations/outlook/send", headers=headers)
    assert outlook_send_res.status_code == 403
    assert "Automated email sending is strictly prohibited" in outlook_send_res.json()["detail"]

# --------------------------------------------------------------------------
# Section 1: OAuth Persistent Shared Storage & Concurrent Replay Tests
# --------------------------------------------------------------------------

def test_oauth_persistent_shared_storage_and_concurrent_replay(client, auth_users):
    from app.services.integration_service import generate_oauth_state, verify_and_consume_oauth_state
    from app.db.session import SessionLocal
    import concurrent.futures

    headers = auth_users["headers_a"]
    me_res = client.get("/api/v1/users/me", headers=headers)
    user_id = me_res.json()["id"]

    db = SessionLocal()
    try:
        pkce_verifier = "my_cryptographic_pkce_verifier_999888"
        # Pre-register state with DB persistent shared storage
        state = generate_oauth_state(user_id=user_id, provider="google_calendar", db=db, code_verifier=pkce_verifier)
        assert len(state) > 40

        # Concurrent Replay Test: 5 concurrent threads attempting to consume the same state
        results = []
        def attempt_consumption(worker_id):
            worker_db = SessionLocal()
            try:
                res = verify_and_consume_oauth_state(
                    state,
                    expected_user_id=user_id,
                    expected_provider="google_calendar",
                    db=worker_db
                )
                return res
            finally:
                worker_db.close()

        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
            futures = [executor.submit(attempt_consumption, i) for i in range(5)]
            for f in concurrent.futures.as_completed(futures):
                results.append(f.result())

        # Exactly ONE worker must succeed, the remaining 4 MUST be rejected
        successful = [r for r in results if r.get("valid") is True]
        rejected = [r for r in results if r.get("valid") is False]
        assert len(successful) == 1
        assert len(rejected) == 4
        assert successful[0]["code_verifier"] == pkce_verifier
        assert all("already consumed" in r.get("reason", "") for r in rejected)

        # Server Restart Simulation: Fresh independent DB session inspects the state
        restart_db = SessionLocal()
        try:
            from app.models.models import OAuthNonce
            raw_decoded = base64.urlsafe_b64decode(state.encode()).decode()
            nonce_hex = raw_decoded.split(":")[3]
            db_record = restart_db.query(OAuthNonce).filter(OAuthNonce.nonce == nonce_hex).first()
            assert db_record is not None
            assert db_record.consumed is True
            assert db_record.consumed_at is not None

            # Replay after restart must be rejected
            res_after_restart = verify_and_consume_oauth_state(
                state,
                expected_user_id=user_id,
                expected_provider="google_calendar",
                db=restart_db
            )
            assert res_after_restart["valid"] is False
            assert "already consumed" in res_after_restart["reason"]

            # Test expired state rejection in DB
            from app.core.config import settings
            import hmac
            import hashlib
            import secrets
            expired_raw = f"{user_id}:google_calendar:{int(time.time()) - 1000}:{secrets.token_hex(32)}"
            expired_sig = hmac.new(settings.SECRET_KEY.encode(), expired_raw.encode(), hashlib.sha256).hexdigest()
            expired_state = base64.urlsafe_b64encode(f"{expired_raw}:{expired_sig}".encode()).decode()
            res_expired = verify_and_consume_oauth_state(expired_state, expected_user_id=user_id, expected_provider="google_calendar", db=restart_db)
            assert res_expired["valid"] is False
            assert "expired" in res_expired["reason"]

            # Test invalid signature rejection in DB
            fresh_raw = f"{user_id}:google_calendar:{int(time.time())}:{secrets.token_hex(32)}"
            bad_sig_state = base64.urlsafe_b64encode(f"{fresh_raw}:0000000000000000".encode()).decode()
            res_bad_sig = verify_and_consume_oauth_state(bad_sig_state, expected_user_id=user_id, expected_provider="google_calendar", db=restart_db)
            assert res_bad_sig["valid"] is False
            assert "Invalid HMAC signature" in res_bad_sig["reason"]
        finally:
            restart_db.close()
    finally:
        db.close()

# --------------------------------------------------------------------------
# Section 2: Workflow Draft-Only Security Barrier Tests
# --------------------------------------------------------------------------

def test_workflow_draft_only_security_barrier(client, auth_users):
    headers = auth_users["headers_a"]

    # 1. Attempting to create a workflow with automated email send action -> 403 Forbidden
    forbidden_payload_1 = {
        "title": "Malicious Auto-Send Workflow",
        "trigger_type": "meeting_completed",
        "actions_json": json.dumps([{"type": "send_email", "recipient": "victim@domain.com"}])
    }
    res_block_1 = client.post("/api/v1/workflows", json=forbidden_payload_1, headers=headers)
    assert res_block_1.status_code == 403
    assert "Automated email dispatch ('send_email') is strictly forbidden" in res_block_1.json()["detail"]

    # 2. Attempting to create a workflow with gmail_send action -> 403 Forbidden
    forbidden_payload_2 = {
        "title": "Gmail Auto Dispatch",
        "trigger_type": "deadline_approaching",
        "actions_json": json.dumps([{"type": "gmail_send", "recipient": "victim@domain.com"}])
    }
    res_block_2 = client.post("/api/v1/workflows", json=forbidden_payload_2, headers=headers)
    assert res_block_2.status_code == 403
    assert "strictly forbidden" in res_block_2.json()["detail"]

    # 3. Legitimate workflow with 'create_draft' and 'extract_tasks' -> 200 OK
    valid_payload = {
        "title": "Legitimate Follow-Up & Action Items",
        "trigger_type": "meeting_completed",
        "actions_json": json.dumps([
            {"type": "extract_tasks"},
            {"type": "create_draft", "mode": "draft_only"}
        ])
    }
    res_ok = client.post("/api/v1/workflows", json=valid_payload, headers=headers)
    assert res_ok.status_code == 200
    wf_id = res_ok.json()["id"]

    # 4. Executing valid workflow -> 200 OK
    exec_res = client.post(f"/api/v1/workflows/{wf_id}/execute", headers=headers)
    assert exec_res.status_code == 200
    assert exec_res.json()["status"] == "success"

# --------------------------------------------------------------------------
# Section 5: AES-256-GCM HKDF Key Management & Tamper Rejection Tests
# --------------------------------------------------------------------------

def test_aes_256_gcm_hkdf_key_management_and_tamper_rejection():
    from app.services.integration_service import (
        encrypt_token, decrypt_token, rotate_token_encryption,
        derive_encryption_key, KEY_VERSIONS
    )

    test_token = "ya29.live_oauth_access_token_super_secret"
    
    # 1. HKDF Key derivation gives 32 bytes (256 bits)
    derived_k1 = derive_encryption_key("v1")
    assert len(derived_k1) == 32

    # 2. Encryption generates versioned ciphertext 'gcm:v1:...'
    encrypted = encrypt_token(test_token, key_version="v1")
    assert encrypted.startswith("gcm:v1:")

    # Decrypt returns original plaintext
    decrypted = decrypt_token(encrypted)
    assert decrypted == test_token

    # 3. Tampered ciphertext or tag mismatch fails securely (returns empty string)
    tampered_1 = encrypted[:-4] + "AAAA" # altered tag
    assert decrypt_token(tampered_1) == ""

    # When raise_on_error=True, TokenDecryptionError is raised on tampering
    from app.services.integration_service import TokenDecryptionError
    import pytest
    with pytest.raises(TokenDecryptionError):
        decrypt_token(tampered_1, raise_on_error=True)

    # Corrupted ciphertext
    tampered_2 = "gcm:v1:YWJjZGVmZ2hpams="
    assert decrypt_token(tampered_2) == ""
    with pytest.raises(TokenDecryptionError):
        decrypt_token(tampered_2, raise_on_error=True)

    # 4. Key rotation support: add v2 key and rotate
    KEY_VERSIONS["v2"] = "secondary_secret_key_rotation_test_2026"
    rotated = rotate_token_encryption(encrypted, target_version="v2")
    assert rotated.startswith("gcm:v2:")
    assert decrypt_token(rotated) == test_token

def test_tampered_token_triggers_reauthorization_required(client, auth_users):
    """
    Verifies that when encrypted credentials fail AES-GCM AEAD authentication tag validation,
    the /test endpoint gracefully returns status='reauthorization_required' with actionable guidance.
    """
    from app.db.session import SessionLocal
    from app.models.models import Integration
    from app.services.integration_service import encrypt_token

    headers = auth_users["headers_a"]
    me_res = client.get("/api/v1/users/me", headers=headers)
    user_id = me_res.json()["id"]

    db = SessionLocal()
    try:
        # Create an integration with tampered encrypted token
        valid_encrypted = encrypt_token("valid_token_12345")
        tampered_encrypted = valid_encrypted[:-4] + "ZZZZ" # Corrupt the authentication tag

        existing = db.query(Integration).filter(
            Integration.user_id == user_id,
            Integration.provider == "notion"
        ).first()

        if not existing:
            existing = Integration(
                user_id=user_id,
                provider="notion",
                connection_status="connected",
                encrypted_access_token=tampered_encrypted
            )
            db.add(existing)
        else:
            existing.encrypted_access_token = tampered_encrypted
            existing.connection_status = "connected"
        db.commit()

        # Call /integrations/notion/test
        test_res = client.post("/api/v1/integrations/notion/test", headers=headers)
        assert test_res.status_code == 200
        data = test_res.json()
        assert data["success"] is False
        assert data["status"] == "reauthorization_required"
        assert "authentication tag mismatch" in data["message"]
        assert data["account_info"]["reauthorization_required"] is True
    finally:
        db.close()
