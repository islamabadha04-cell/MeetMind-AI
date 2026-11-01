import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.db.session import SessionLocal
from app.models.models import User, UpgradeRequest
from app.core.security import get_password_hash, create_access_token

client = TestClient(app)

def create_user_with_token(email: str, plan: str = "Free", is_admin: bool = False):
    db = SessionLocal()
    user = db.query(User).filter(User.email == email).first()
    if not user:
        user = User(
            email=email,
            hashed_password=get_password_hash("testpass123"),
            full_name=email.split("@")[0].capitalize(),
            plan=plan,
            minutes_limit=120 if plan == "Free" else 1200,
            minutes_used=0,
            is_active=True
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    else:
        user.plan = plan
        user.minutes_limit = 120 if plan == "Free" else 1200
        db.commit()
        db.refresh(user)
    
    token = create_access_token(user.id)
    user_id = user.id
    db.close()
    return user_id, {"Authorization": f"Bearer {token}"}

def test_unauthenticated_request_upgrade_rejected():
    res = client.post("/api/v1/subscription/request-upgrade", json={
        "requested_plan": "Pro",
        "billing_email": "test@example.com"
    })
    assert res.status_code == 401

def test_request_subscription_upgrade_lifecycle():
    user_id, headers = create_user_with_token("qa_sub_user@example.com", plan="Free")
    
    # 1. Check initial status
    res = client.get("/api/v1/subscription/status", headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert data["current_plan"] == "Free"
    assert data["is_pro"] is False
    assert data["minutes_limit"] == 120

    # 2. Submit upgrade request
    req_res = client.post("/api/v1/subscription/request-upgrade", headers=headers, json={
        "requested_plan": "Pro",
        "organization_name": "QA Labs Inc.",
        "billing_email": "qa_sub_user@example.com",
        "payment_method": "manual_bank",
        "notes": "Verified QA remediation test"
    })
    assert req_res.status_code == 200
    req_data = req_res.json()
    assert req_data["reference_id"].startswith("MM-REQ-")
    assert req_data["requested_plan"] == "Pro"
    assert req_data["amount_pkr"] == 2499
    assert req_data["status"] == "pending"
    ref_id = req_data["reference_id"]

    # 3. Status now shows pending upgrade, but user is STILL NOT PRO (no bypass!)
    res2 = client.get("/api/v1/subscription/status", headers=headers)
    assert res2.status_code == 200
    data2 = res2.json()
    assert data2["current_plan"] == "Free"
    assert data2["is_pro"] is False
    assert data2["pending_upgrade"]["reference_id"] == ref_id

    # 4. Unauthorized non-admin attempt to approve returns 403 Forbidden
    res_unauth = client.post("/api/v1/subscription/admin-approve", headers=headers, json={
        "reference_id": ref_id,
        "admin_notes": "Attempted self-approval"
    })
    assert res_unauth.status_code == 403

    # 5. Admin approves upgrade request
    _, admin_headers = create_user_with_token("admin@meetmind.ai", plan="Admin")
    res_app = client.post("/api/v1/subscription/admin-approve", headers=admin_headers, json={
        "reference_id": ref_id,
        "admin_notes": "Bank transfer confirmed via Meezan reconciliation audit."
    })
    assert res_app.status_code == 200
    app_data = res_app.json()
    assert app_data["status"] == "approved"

    # 6. User now has verified Pro entitlements
    res3 = client.get("/api/v1/subscription/status", headers=headers)
    assert res3.status_code == 200
    data3 = res3.json()
    assert data3["current_plan"] == "Pro"
    assert data3["is_pro"] is True
    assert data3["minutes_limit"] == 1200

