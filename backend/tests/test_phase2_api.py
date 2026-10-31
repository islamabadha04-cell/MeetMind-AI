import pytest
from fastapi.testclient import TestClient
from app.main import app, startup_db_seed

@pytest.fixture(autouse=True, scope="module")
def setup_seed():
    startup_db_seed()

client = TestClient(app)

def test_semantic_search_meetings():
    response = client.post("/api/v1/search/meetings", json={
        "query": "payment delays",
        "mode": "hybrid",
        "category": "all",
        "limit": 5
    })
    assert response.status_code == 200
    data = response.json()
    assert "query" in data
    assert "results" in data
    assert "ai_synthesis" in data

def test_meeting_comparison():
    meetings = client.get("/api/v1/meetings").json()
    assert len(meetings) >= 2
    id_a = meetings[0]["id"]
    id_b = meetings[1]["id"]
    response = client.post("/api/v1/meetings/compare", json={
        "meeting_a_id": id_a,
        "meeting_b_id": id_b
    })
    assert response.status_code == 200
    data = response.json()
    assert "matrix" in data
    assert "executive_delta" in data
    assert "progress_score" in data
    assert len(data["matrix"]) >= 5

def test_knowledge_document_list_and_upload():
    # 1. List documents
    list_res = client.get("/api/v1/knowledge/documents")
    assert list_res.status_code == 200
    docs = list_res.json()
    assert len(docs) >= 1

    # 2. Upload text document
    file_content = b"MeetMind AI Onboarding Guidelines: Employees are assigned a dedicated mentor on Day 1. Weekly sprint planning occurs every Monday at 10 AM PKT."
    upload_res = client.post(
        "/api/v1/knowledge/upload",
        files={"file": ("onboarding_manual.txt", file_content, "text/plain")},
        data={"category": "HR Policy"}
    )
    assert upload_res.status_code == 200
    upload_data = upload_res.json()
    assert upload_data["status"] == "success"
    assert upload_data["chunks_indexed"] >= 1

def test_meeting_memory_crud():
    # 1. List
    res = client.get("/api/v1/memory")
    assert res.status_code == 200
    mems = res.json()
    assert len(mems) >= 1

    # 2. Create
    create_res = client.post("/api/v1/memory", json={
        "category": "Important Decisions",
        "fact_statement": "Standardized all mobile API communication to HTTPS with token-based authentication.",
        "meeting_title": "Security Architecture Sync",
        "timestamp": "01:45"
    })
    assert create_res.status_code == 200
    new_mem = create_res.json()
    mem_id = new_mem["id"]

    # 3. Update
    update_res = client.put(f"/api/v1/memory/{mem_id}", json={
        "category": "Important Decisions",
        "fact_statement": "Standardized all mobile API communication to HTTPS with mutual TLS and bearer tokens."
    })
    assert update_res.status_code == 200
    updated_mem = update_res.json()
    assert len(updated_mem["revisions"]) >= 1

    # 4. Delete
    del_res = client.delete(f"/api/v1/memory/{mem_id}")
    assert del_res.status_code == 200

def test_universal_rag_chat():
    # 1. Question matching knowledge
    res = client.post("/api/v1/chat/ask", json={
        "question": "What is our company annual leave policy?",
        "scope": "knowledge"
    })
    assert res.status_code == 200
    data = res.json()
    assert "content" in data
    assert len(data["citations"]) >= 1

    # 2. Unrelated question with anti-hallucination check
    unrelated_res = client.post("/api/v1/chat/ask", json={
        "question": "What is the capital city of planet Neptune?",
        "scope": "all"
    })
    assert unrelated_res.status_code == 200
    unrelated_data = unrelated_res.json()
    assert "could not find sufficient information" in unrelated_data["content"].lower() or "معذرت" in unrelated_data["content"]
