import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert "version" in response.json()

def test_get_meetings():
    response = client.get("/api/v1/meetings")
    assert response.status_code == 200
    assert isinstance(response.json(), list)

def test_get_tasks():
    response = client.get("/api/v1/tasks")
    assert response.status_code == 200
    assert isinstance(response.json(), list)

def test_ask_ai_chat():
    response = client.post("/api/v1/chat/ask", json={"question": "What are the main decisions?"})
    assert response.status_code == 200
    data = response.json()
    assert "content" in data
    assert data["role"] == "assistant"
