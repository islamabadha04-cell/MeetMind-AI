import pytest
import secrets
from datetime import datetime, timezone, timedelta
from fastapi.testclient import TestClient
from app.main import app
from app.db.session import SessionLocal
from app.models.models import Meeting, SharedMeetingLink, User

client = TestClient(app)

@pytest.fixture
def auth_headers():
    res = client.post("/api/v1/auth/login", json={"email": "emily@example.com", "password": "password123"})
    if res.status_code == 200:
        token = res.json()["access_token"]
        return {"Authorization": f"Bearer {token}"}
    return {}

def test_phase7_create_and_access_share_link(auth_headers):
    # 1. Fetch existing meetings
    res_m = client.get("/api/v1/meetings", headers=auth_headers)
    assert res_m.status_code == 200
    meetings = res_m.json()
    assert len(meetings) > 0
    meeting_id = meetings[0]["id"]

    # 2. Generate a secure share link
    share_payload = {
        "expires_in_days": 7,
        "allow_transcript": True,
        "allow_tasks": True,
        "allow_summary": True,
        "title": f"Public Quarterly Review {secrets.token_hex(4)}"
    }
    res_share = client.post(f"/api/v1/meetings/{meeting_id}/share", json=share_payload, headers=auth_headers)
    assert res_share.status_code == 200
    share_data = res_share.json()
    assert "share_token" in share_data
    token = share_data["share_token"]
    assert share_data["meeting_id"] == meeting_id
    assert share_data["is_active"] is True
    assert share_data["access_count"] == 0

    # 3. Public access WITHOUT ANY AUTHENTICATION (public internet stakeholder access)
    res_public = client.get(f"/api/v1/meetings/share/{token}")
    assert res_public.status_code == 200
    pub_data = res_public.json()
    assert pub_data["share_token"] == token
    assert pub_data["access_count"] == 1
    assert "summary" in pub_data

    # 4. List shares for the meeting
    res_list = client.get(f"/api/v1/meetings/{meeting_id}/shares", headers=auth_headers)
    assert res_list.status_code == 200
    tokens = [s["share_token"] for s in res_list.json()]
    assert token in tokens

    # 5. Revoke the share link
    res_del = client.delete(f"/api/v1/meetings/share/{token}", headers=auth_headers)
    assert res_del.status_code == 200
    assert res_del.json()["status"] == "revoked"

    # 6. Public access after revocation returns 404
    res_revoked = client.get(f"/api/v1/meetings/share/{token}")
    assert res_revoked.status_code == 404

def test_phase7_expired_link_returns_410(auth_headers):
    db = SessionLocal()
    try:
        meeting = db.query(Meeting).first()
        user = db.query(User).filter(User.email == "emily@example.com").first()
        if not meeting or not user:
            pytest.skip("No meeting or user available for test")

        expired_token = f"expired_test_{secrets.token_urlsafe(16)}"
        expired_link = SharedMeetingLink(
            meeting_id=meeting.id,
            user_id=user.id,
            share_token=expired_token,
            title="Expired Meeting",
            expires_at=datetime.now(timezone.utc).replace(tzinfo=None) - timedelta(hours=2),
            is_active=True,
            access_count=0
        )
        db.add(expired_link)
        db.commit()

        # Public access to expired link returns 410 Gone
        res = client.get(f"/api/v1/meetings/share/{expired_token}")
        assert res.status_code == 410
        assert "expired" in res.json()["detail"].lower()
    finally:
        db.close()
