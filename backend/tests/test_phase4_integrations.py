import pytest
from fastapi.testclient import TestClient
import json
import time

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
    # Verification challenge
    verify_res = client.get("/api/v1/integrations/whatsapp/webhook?hub.mode=subscribe&hub.verify_token=meetmind_meta_webhook_secret_2026&hub.challenge=115599")
    assert verify_res.status_code == 200
    assert verify_res.text.strip('"') == "115599"

    # Inbound voice note
    voice_note_payload = {
        "object": "whatsapp_business_account",
        "entry": [{
            "id": "WHATSAPP_BUSINESS_ACCOUNT_ID",
            "changes": [{
                "value": {
                    "messaging_product": "whatsapp",
                    "messages": [{
                        "from": "+923001234567",
                        "type": "audio",
                        "audio": {"id": "media_audio_001", "mime_type": "audio/ogg"}
                    }]
                }
            }]
        }]
    }
    post_res = client.post("/api/v1/integrations/whatsapp/webhook", json=voice_note_payload)
    assert post_res.status_code == 200
    assert post_res.json()["status"] == "success"

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
