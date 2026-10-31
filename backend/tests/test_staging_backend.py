import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_check_endpoint():
    res = client.get("/health")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "healthy"
    assert data["version"] == "4.0.1"
    assert data["database"] == "ok"
    assert "timestamp" in data

    # Test under /api/v1/health prefix as well
    res_v1 = client.get("/api/v1/health")
    assert res_v1.status_code == 200
    assert res_v1.json()["status"] == "healthy"

def test_readiness_probe():
    res = client.get("/ready")
    assert res.status_code == 200
    data = res.json()
    assert data["ready"] is True
    assert data["version"] == "4.0.1"

    res_v1 = client.get("/api/v1/ready")
    assert res_v1.status_code == 200
    assert res_v1.json()["ready"] is True

def test_root_endpoint_metadata():
    res = client.get("/")
    assert res.status_code == 200
    data = res.json()
    assert data["version"] == "4.0.1"
    assert "Phase 4B" in data["phase"]
    assert "health_url" in data

def test_structured_logging_headers():
    res = client.get("/health")
    assert res.status_code == 200
    assert "x-response-time" in res.headers
    assert res.headers["x-meetmind-version"] == "4.0.1"

def test_cors_preflight_for_preview_domain():
    # Emulate browser CORS preflight from Firebase Hosting preview domain
    headers = {
        "Origin": "https://meetmind-ai-74519--preview-v4-rj24mmx0.web.app",
        "Access-Control-Request-Method": "POST",
        "Access-Control-Request-Headers": "Authorization,Content-Type"
    }
    res = client.options("/api/v1/integrations", headers=headers)
    assert res.status_code == 200
    assert res.headers.get("access-control-allow-origin") == "https://meetmind-ai-74519--preview-v4-rj24mmx0.web.app"
