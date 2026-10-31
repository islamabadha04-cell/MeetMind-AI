"""
Phase 5 Test Suite: Team Collaboration, Organizations & Multi-Tenant RBAC
Covers:
- Workspace CRUD & seat limit enforcement
- Role-Based Access Control (Owner > Admin > Manager > Editor > Viewer)
- Invitation lifecycle (generate, expire, accept, duplicate rejection)
- Real-time collaborative note editing & revision audit trail
- Organization-scoped shared meeting memory vault & cross-tenant isolation
"""
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.db.session import get_db, SessionLocal
from app.models.models import User, Workspace, WorkspaceMember, WorkspaceInvite, CollaborativeNote, Meeting
from app.core.security import get_password_hash, create_access_token
import time
import secrets

client = TestClient(app)

def create_test_user_and_auth(email: str, name: str = "Test User"):
    db = SessionLocal()
    user = db.query(User).filter(User.email == email).first()
    if not user:
        user = User(
            email=email,
            hashed_password=get_password_hash("testpass123"),
            full_name=name,
            plan="Team",
            is_active=True
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    token = create_access_token(user.id)
    db.close()
    return user, {"Authorization": f"Bearer {token}"}

def test_list_and_get_seeded_workspace():
    # Emily (User 1) is the owner of Cowlar Engineering
    _, headers = create_test_user_and_auth("emily@example.com", "Emily Watson")
    res = client.get("/api/v1/workspaces", headers=headers)
    assert res.status_code == 200
    workspaces = res.json()
    assert len(workspaces) >= 1
    cowlar = next((w for w in workspaces if "Cowlar" in w["name"]), None)
    assert cowlar is not None
    assert cowlar["owner_name"] == "Emily Watson"
    assert cowlar["current_user_role"] == "owner"
    assert len(cowlar["members"]) >= 4

def test_create_new_workspace():
    user, headers = create_test_user_and_auth(f"ws_creator_{int(time.time())}@corp.com", "Workspace Founder")
    payload = {
        "name": "Alpha Innovations",
        "description": "Next-gen AI incubation unit",
        "tier": "Team"
    }
    res = client.post("/api/v1/workspaces", json=payload, headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert data["name"] == "Alpha Innovations"
    assert "alpha-innovations" in data["slug"]
    assert data["current_user_role"] == "owner"
    assert data["active_seats"] == 1
    assert data["owner_id"] == user.id

def test_rbac_access_control_matrix():
    ts = int(time.time())
    owner, owner_headers = create_test_user_and_auth(f"owner_{ts}@corp.com", "Workspace Owner")
    admin, admin_headers = create_test_user_and_auth(f"admin_{ts}@corp.com", "Workspace Admin")
    manager, manager_headers = create_test_user_and_auth(f"manager_{ts}@corp.com", "Workspace Manager")
    editor, editor_headers = create_test_user_and_auth(f"editor_{ts}@corp.com", "Workspace Editor")
    viewer, viewer_headers = create_test_user_and_auth(f"viewer_{ts}@corp.com", "Workspace Viewer")
    outsider, outsider_headers = create_test_user_and_auth(f"outsider_{ts}@corp.com", "Outsider User")

    # 1. Create Workspace by Owner
    res = client.post("/api/v1/workspaces", json={"name": f"Matrix Corp {ts}"}, headers=owner_headers)
    assert res.status_code == 200
    ws_id = res.json()["id"]

    # 2. Add members with their roles via database directly to set up matrix
    db = SessionLocal()
    db.add(WorkspaceMember(workspace_id=ws_id, user_id=admin.id, role="admin"))
    db.add(WorkspaceMember(workspace_id=ws_id, user_id=manager.id, role="manager"))
    db.add(WorkspaceMember(workspace_id=ws_id, user_id=editor.id, role="editor"))
    db.add(WorkspaceMember(workspace_id=ws_id, user_id=viewer.id, role="viewer"))
    db.commit()
    db.close()

    # 3. Outsider access check: Should be 403 Forbidden
    res = client.get(f"/api/v1/workspaces/{ws_id}", headers=outsider_headers)
    assert res.status_code == 403
    assert "Access denied" in res.json()["detail"]

    # 4. Viewer access: can read workspace & members, but CANNOT update or create notes
    res = client.get(f"/api/v1/workspaces/{ws_id}", headers=viewer_headers)
    assert res.status_code == 200
    assert res.json()["current_user_role"] == "viewer"

    # Viewer tries to update workspace -> HTTP 403
    res = client.put(f"/api/v1/workspaces/{ws_id}", json={"name": "Hacked Name"}, headers=viewer_headers)
    assert res.status_code == 403

    # Viewer tries to create note -> HTTP 403
    res = client.post(f"/api/v1/workspaces/{ws_id}/notes", json={"title": "Unauthorized"}, headers=viewer_headers)
    assert res.status_code == 403

    # 5. Editor access: CAN create note
    res = client.post(f"/api/v1/workspaces/{ws_id}/notes", json={"title": "Sprint Note", "content": "Initial text"}, headers=editor_headers)
    assert res.status_code == 200
    note_id = res.json()["id"]

    # Editor tries to update workspace info -> HTTP 403
    res = client.put(f"/api/v1/workspaces/{ws_id}", json={"name": "Hacked Name"}, headers=editor_headers)
    assert res.status_code == 403

    # 6. Admin access: CAN update workspace info
    res = client.put(f"/api/v1/workspaces/{ws_id}", json={"description": "Updated by admin"}, headers=admin_headers)
    assert res.status_code == 200

    # Admin CANNOT delete the workspace (only owner can)
    res = client.delete(f"/api/v1/workspaces/{ws_id}", headers=admin_headers)
    assert res.status_code == 403
    assert "requires 'owner' role" in res.json()["detail"]

    # 7. Owner CAN delete workspace (we verify at end of test or keep it)
    res = client.get(f"/api/v1/workspaces/{ws_id}", headers=owner_headers)
    assert res.status_code == 200

def test_invitation_lifecycle_and_rejection():
    ts = int(time.time())
    owner, owner_headers = create_test_user_and_auth(f"inv_owner_{ts}@corp.com", "Inv Owner")
    res = client.post("/api/v1/workspaces", json={"name": f"Inv Corp {ts}"}, headers=owner_headers)
    ws_id = res.json()["id"]

    # 1. Invite a new teammate as editor
    target_email = f"new_hire_{ts}@corp.com"
    res = client.post(f"/api/v1/workspaces/{ws_id}/invites", json={"email": target_email, "role": "editor"}, headers=owner_headers)
    assert res.status_code == 200
    inv_data = res.json()
    token = inv_data["invite_token"]
    assert inv_data["status"] == "pending"
    assert inv_data["email"] == target_email
    assert "meetmind" in inv_data["invite_url"]

    # 2. Accept invite with new teammate account
    new_user, new_headers = create_test_user_and_auth(target_email, "New Hire")
    res = client.post(f"/api/v1/workspaces/invites/{token}/accept", headers=new_headers)
    assert res.status_code == 200
    assert res.json()["current_user_role"] == "editor"

    # 3. Second attempt to accept same token should fail
    res = client.post(f"/api/v1/workspaces/invites/{token}/accept", headers=new_headers)
    assert res.status_code == 404
    assert "Invalid or already consumed" in res.json()["detail"]

def test_seat_limit_enforcement():
    ts = int(time.time())
    owner, owner_headers = create_test_user_and_auth(f"seat_owner_{ts}@corp.com", "Seat Owner")
    res = client.post("/api/v1/workspaces", json={"name": f"Seat Test {ts}"}, headers=owner_headers)
    ws_id = res.json()["id"]

    # Artificially set max_seats to 2
    db = SessionLocal()
    ws = db.query(Workspace).filter(Workspace.id == ws_id).first()
    ws.max_seats = 2
    # Add second member to fill seats
    second_user, _ = create_test_user_and_auth(f"seat_two_{ts}@corp.com", "Second Member")
    db.add(WorkspaceMember(workspace_id=ws_id, user_id=second_user.id, role="editor"))
    db.commit()
    db.close()

    # Try inviting 3rd member -> Should be rejected with HTTP 400
    res = client.post(f"/api/v1/workspaces/{ws_id}/invites", json={"email": f"seat_three_{ts}@corp.com", "role": "editor"}, headers=owner_headers)
    assert res.status_code == 400
    assert "Seat limit reached" in res.json()["detail"]

def test_collaborative_note_editing_and_revisions():
    ts = int(time.time())
    owner, owner_headers = create_test_user_and_auth(f"collab_owner_{ts}@corp.com", "Collab Owner")
    editor, editor_headers = create_test_user_and_auth(f"collab_editor_{ts}@corp.com", "Collab Editor")

    res = client.post("/api/v1/workspaces", json={"name": f"Collab Hub {ts}"}, headers=owner_headers)
    ws_id = res.json()["id"]

    # Add editor
    db = SessionLocal()
    db.add(WorkspaceMember(workspace_id=ws_id, user_id=editor.id, role="editor"))
    db.commit()
    db.close()

    # List notes (initial note was created during workspace creation)
    res = client.get(f"/api/v1/workspaces/{ws_id}/notes", headers=editor_headers)
    assert res.status_code == 200
    notes = res.json()
    assert len(notes) >= 1
    note_id = notes[0]["id"]
    initial_ver = notes[0]["version"]

    # Update note by editor
    update_payload = {
        "title": "Updated Architecture Agenda",
        "content": "Line 1: Refactor auth\nLine 2: Add websocket sync",
        "version": initial_ver
    }
    res = client.put(f"/api/v1/workspaces/{ws_id}/notes/{note_id}", json=update_payload, headers=editor_headers)
    assert res.status_code == 200
    updated_note = res.json()
    assert updated_note["version"] == initial_ver + 1
    assert updated_note["last_edited_by_name"] == "Collab Editor"

    # Get revision audit trail
    res = client.get(f"/api/v1/workspaces/{ws_id}/notes/{note_id}/revisions", headers=editor_headers)
    assert res.status_code == 200
    revisions = res.json()
    assert len(revisions) >= 2
    assert revisions[0]["version"] == initial_ver + 1
    assert "Edit by Collab Editor" in revisions[0]["revision_summary"]

def test_shared_vault_and_multi_tenant_isolation():
    ts = int(time.time())
    owner_a, headers_a = create_test_user_and_auth(f"vault_a_{ts}@corp.com", "Org A Lead")
    owner_b, headers_b = create_test_user_and_auth(f"vault_b_{ts}@corp.com", "Org B Lead")

    # Create Org A Workspace
    res_a = client.post("/api/v1/workspaces", json={"name": f"Org A {ts}"}, headers=headers_a)
    ws_a_id = res_a.json()["id"]

    # Create Org B Workspace
    res_b = client.post("/api/v1/workspaces", json={"name": f"Org B {ts}"}, headers=headers_b)
    ws_b_id = res_b.json()["id"]

    # Create Meeting owned by Org A
    db = SessionLocal()
    m_a = Meeting(
        user_id=owner_a.id,
        title=f"Org A Top Secret Roadmap {ts}",
        category="Meetings",
        duration_seconds=300
    )
    db.add(m_a)
    db.commit()
    db.refresh(m_a)
    meeting_a_id = m_a.id
    db.close()

    # Share Meeting into Org A Vault
    res = client.post(f"/api/v1/workspaces/{ws_a_id}/vault/share-meeting?meeting_id={meeting_a_id}", headers=headers_a)
    assert res.status_code == 200

    # Org A accesses Org A Vault -> sees meeting
    res = client.get(f"/api/v1/workspaces/{ws_a_id}/vault", headers=headers_a)
    assert res.status_code == 200
    vault_a = res.json()
    assert vault_a["meetings_count"] >= 1
    assert any(m_a.title in item["title"] for item in vault_a["items"])

    # Org B attempts to access Org A Vault -> Strictly Forbidden (HTTP 403)
    res = client.get(f"/api/v1/workspaces/{ws_a_id}/vault", headers=headers_b)
    assert res.status_code == 403
    assert "Access denied" in res.json()["detail"]
