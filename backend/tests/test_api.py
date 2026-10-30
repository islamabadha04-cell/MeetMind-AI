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

def test_transcribe_audio():
    import io, wave, struct
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(16000)
        wav.writeframes(struct.pack("<h", 0) * 1600)
    
    response = client.post(
        "/api/v1/meetings/transcribe-audio",
        files={"file": ("test_clip.wav", buf.getvalue(), "audio/wav")}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert "transcript" in data
    assert "executive_summary" in data
