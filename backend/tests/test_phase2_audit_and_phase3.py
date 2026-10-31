import pytest
from fastapi.testclient import TestClient
import json
from app.main import app, startup_db_seed
from app.services.search_service import SearchService
from app.services.ai_service import AIService
from app.core.security import create_access_token

@pytest.fixture(autouse=True, scope="module")
def setup_seed():
    startup_db_seed()

@pytest.fixture
def client():
    return TestClient(app)

# --------------------------------------------------------------------------
# PART A AUDIT TESTS: Phase 2 Fixes
# --------------------------------------------------------------------------
def test_embedding_generation_and_caching():
    # 1. Test embedding generation
    vec1 = SearchService.get_embedding("Milestone payment was delayed due to approval stall")
    assert isinstance(vec1, list)
    assert len(vec1) >= 64
    assert any(x != 0.0 for x in vec1)

    # 2. Test caching
    vec2 = SearchService.get_embedding("Milestone payment was delayed due to approval stall")
    assert vec1 == vec2

def test_cosine_similarity_computation():
    v1 = [1.0, 0.0, 0.0, 0.0]
    v2 = [1.0, 0.0, 0.0, 0.0]
    v3 = [0.0, 1.0, 0.0, 0.0]
    sim_same = SearchService.cosine_similarity(v1, v2)
    sim_diff = SearchService.cosine_similarity(v1, v3)
    assert sim_same == pytest.approx(1.0, rel=1e-3)
    assert sim_diff == pytest.approx(0.0, rel=1e-3)

def test_hybrid_search_with_rrf(client):
    res = client.post("/api/v1/search/meetings", json={
        "query": "payment delays",
        "mode": "hybrid"
    })
    assert res.status_code == 200
    data = res.json()
    assert "results" in data
    assert "ai_synthesis" in data
    assert len(data["results"]) > 0
    hit = data["results"][0]
    assert "relevance_score" in hit
    assert "timestamp" in hit
    assert "excerpt" in hit

def test_meeting_creation_and_automatic_vector_indexing(client):
    meeting_payload = {
        "title": "UAT Performance and Budget Review",
        "category": "Meetings",
        "tint": "mint",
        "source_type": "meeting_link",
        "duration_seconds": 900,
        "transcript_text": "Emily will conduct load testing on Thursday. Client approved budget expansion for cloud infrastructure."
    }
    res = client.post("/api/v1/meetings", json=meeting_payload)
    assert res.status_code == 200
    data = res.json()
    m_id = data["id"]

    # Verify meeting update and re-indexing
    update_res = client.put(f"/api/v1/meetings/{m_id}", json={
        "title": "UAT Performance and Cloud Budget Review",
        "transcript_text": "Updated discussion on cellular latency and performance optimizations."
    })
    assert update_res.status_code == 200
    assert update_res.json()["title"] == "UAT Performance and Cloud Budget Review"

def test_knowledge_document_reprocessing(client):
    # Fetch first document
    docs_res = client.get("/api/v1/knowledge/documents")
    assert docs_res.status_code == 200
    docs = docs_res.json()
    assert len(docs) > 0
    doc_id = docs[0]["id"]

    # Call reprocess endpoint
    reprocess_res = client.post(f"/api/v1/knowledge/documents/{doc_id}/reprocess")
    assert reprocess_res.status_code == 200
    data = reprocess_res.json()
    assert data["status"] == "success"
    assert data["chunks_reindexed"] > 0

# --------------------------------------------------------------------------
# PART C: Phase 3 Task Management & Automation Tests
# --------------------------------------------------------------------------
def test_action_item_extraction_from_meeting(client):
    meetings_res = client.get("/api/v1/meetings")
    m_id = meetings_res.json()[0]["id"]

    extract_res = client.post(f"/api/v1/tasks/extract-from-meeting/{m_id}")
    assert extract_res.status_code == 200
    data = extract_res.json()
    assert data["status"] == "success"
    assert "tasks_extracted" in data

def test_task_crud_and_history(client):
    # 1. Create Task
    task_payload = {
        "title": "Implement Webhook Retry Mechanism",
        "description": "Ensure dropped bank callbacks retry with exponential backoff.",
        "assignee": "Hasnain Ali",
        "deadline": "Friday 5:00 PM",
        "priority": "high",
        "status": "pending",
        "project": "Payments"
    }
    create_res = client.post("/api/v1/tasks", json=task_payload)
    assert create_res.status_code == 200
    task_data = create_res.json()
    t_id = task_data["id"]
    assert task_data["assignee"] == "Hasnain Ali"

    # 2. Add comment
    comment_res = client.post(f"/api/v1/tasks/{t_id}/comments", json={
        "comment_text": "Configured retry queue with 3 max retries.",
        "author_name": "Hasnain"
    })
    assert comment_res.status_code == 200
    assert comment_res.json()["author_name"] == "Hasnain"

    # 3. Update Status
    update_res = client.put(f"/api/v1/tasks/{t_id}", json={
        "status": "completed"
    })
    assert update_res.status_code == 200
    assert update_res.json()["status"] == "completed"

    # 4. Check History
    hist_res = client.get(f"/api/v1/tasks/{t_id}/history")
    assert hist_res.status_code == 200
    history = hist_res.json()
    assert len(history) >= 2 # created + status_changed

def test_manager_approval_workflow(client):
    # Get pending approvals
    approvals_res = client.get("/api/v1/approvals?status_filter=pending")
    assert approvals_res.status_code == 200
    approvals = approvals_res.json()

    if approvals:
        appr_id = approvals[0]["id"]
        action_res = client.post(f"/api/v1/approvals/{appr_id}/action", json={
            "decision": "approve",
            "decision_notes": "Reviewed and confirmed deliverable milestone.",
            "approver_name": "Emily Watson (Lead)"
        })
        assert action_res.status_code == 200
        assert action_res.json()["status"] == "approved"

def test_ai_follow_up_generator(client):
    # Test English
    res_en = client.post("/api/v1/followups/generate", json={
        "follow_up_type": "client_followup",
        "language": "en",
        "recipient_name": "Tariq Khan"
    })
    assert res_en.status_code == 200
    data_en = res_en.json()
    assert "Executive Follow-Up" in data_en["subject"] or "Next Steps" in data_en["subject"]

    # Test Urdu
    res_ur = client.post("/api/v1/followups/generate", json={
        "follow_up_type": "payment_reminder",
        "language": "ur",
        "recipient_name": "طارق صاحب"
    })
    assert res_ur.status_code == 200
    data_ur = res_ur.json()
    assert "ادائیگی" in data_ur["subject"] or "خلاصہ" in data_ur["subject"]

    # Test Roman Urdu
    res_ro = client.post("/api/v1/followups/generate", json={
        "follow_up_type": "payment_reminder",
        "language": "roman",
        "recipient_name": "Tariq Bhai"
    })
    assert res_ro.status_code == 200
    assert "Meeting" in res_ro.json()["subject"] or "Payment" in res_ro.json()["subject"]

def test_smart_notifications_and_scan(client):
    scan_res = client.post("/api/v1/notifications/scan")
    assert scan_res.status_code == 200
    assert scan_res.json()["status"] == "success"

    notifs_res = client.get("/api/v1/notifications")
    assert notifs_res.status_code == 200
    notifs = notifs_res.json()
    assert len(notifs) > 0

    # Mark as read
    first_id = notifs[0]["id"]
    read_res = client.put(f"/api/v1/notifications/{first_id}/read")
    assert read_res.status_code == 200
    assert read_res.json()["is_read"] is True

def test_workflow_automation_lifecycle(client):
    # 1. Create Workflow
    wf_res = client.post("/api/v1/workflows", json={
        "title": "Post-Meeting Automation Chain",
        "description": "Auto extracts tasks and dispatches follow up notification.",
        "trigger_type": "meeting_completed",
        "conditions_json": json.dumps([{"min_duration": 60}]),
        "actions_json": json.dumps([{"action": "extract_tasks"}])
    })
    assert wf_res.status_code == 200
    wf = wf_res.json()
    wf_id = wf["id"]

    # 2. Execute Workflow
    exec_res = client.post(f"/api/v1/workflows/{wf_id}/execute")
    assert exec_res.status_code == 200
    execution = exec_res.json()
    assert execution["status"] == "success"

    # 3. View Executions
    logs_res = client.get(f"/api/v1/workflows/{wf_id}/executions")
    assert logs_res.status_code == 200
    assert len(logs_res.json()) >= 1

def test_backend_two_user_isolation(client):
    import time
    stamp = int(time.time() * 1000)

    # 1. Register User A
    reg_a = client.post("/api/v1/auth/register", json={
        "email": f"tenant_a_{stamp}@corp.com",
        "password": "Password123!",
        "full_name": "Tenant A Lead"
    })
    assert reg_a.status_code == 200
    token_a = reg_a.json()["access_token"]

    # 2. Register User B
    reg_b = client.post("/api/v1/auth/register", json={
        "email": f"tenant_b_{stamp}@corp.com",
        "password": "Password123!",
        "full_name": "Tenant B Lead"
    })
    assert reg_b.status_code == 200
    token_b = reg_b.json()["access_token"]

    # 3. User A creates a meeting and a task
    headers_a = {"Authorization": f"Bearer {token_a}"}
    headers_b = {"Authorization": f"Bearer {token_b}"}

    mA_res = client.post("/api/v1/meetings", json={
        "title": "Tenant A Secret Board Strategy",
        "category": "Meetings",
        "transcript_text": "Confidential acquisition terms for Tenant A."
    }, headers=headers_a)
    assert mA_res.status_code == 200
    mA_id = mA_res.json()["id"]

    tA_res = client.post("/api/v1/tasks", json={
        "title": "Transfer $100,000 to escrow",
        "assignee": "Tenant A Lead",
        "priority": "urgent"
    }, headers=headers_a)
    assert tA_res.status_code == 200

    # 4. User B queries meetings: must NOT see Tenant A's meeting
    mB_list = client.get("/api/v1/meetings", headers=headers_b)
    assert mB_list.status_code == 200
    mB_titles = [m["title"] for m in mB_list.json()]
    assert "Tenant A Secret Board Strategy" not in mB_titles

    # 5. User B queries tasks: must NOT see Tenant A's task
    tB_list = client.get("/api/v1/tasks", headers=headers_b)
    assert tB_list.status_code == 200
    tB_titles = [t["title"] for t in tB_list.json()]
    assert "Transfer $100,000 to escrow" not in tB_titles
