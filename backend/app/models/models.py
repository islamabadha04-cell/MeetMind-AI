from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Boolean, Float
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from app.db.session import Base

def utc_now():
    return datetime.now(timezone.utc)

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(255), default="Emily Watson")
    avatar_url = Column(String(500), default="/assets/emily.jpg")
    plan = Column(String(50), default="Pro") # Free, Pro, Team, Business
    minutes_used = Column(Integer, default=42)
    minutes_limit = Column(Integer, default=500)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=utc_now)

    meetings = relationship("Meeting", back_populates="user", cascade="all, delete-orphan")
    tasks = relationship("Task", back_populates="user", cascade="all, delete-orphan")
    knowledge_documents = relationship("KnowledgeDocument", back_populates="user", cascade="all, delete-orphan")
    memories = relationship("MeetingMemory", back_populates="user", cascade="all, delete-orphan")
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")
    workflows = relationship("Workflow", back_populates="user", cascade="all, delete-orphan")
    approval_requests = relationship("ApprovalRequest", back_populates="user", cascade="all, delete-orphan")
    integrations = relationship("Integration", back_populates="user", cascade="all, delete-orphan")
    entity_mappings = relationship("ExternalEntityMapping", back_populates="user", cascade="all, delete-orphan")
    webhook_subscriptions = relationship("WebhookSubscription", back_populates="user", cascade="all, delete-orphan")
    integration_jobs = relationship("IntegrationJob", back_populates="user", cascade="all, delete-orphan")
    oauth_nonces = relationship("OAuthNonce", back_populates="user", cascade="all, delete-orphan")
    owned_workspaces = relationship("Workspace", back_populates="owner", foreign_keys="Workspace.owner_id")
    workspace_memberships = relationship("WorkspaceMember", back_populates="user", cascade="all, delete-orphan")

class Workspace(Base):
    __tablename__ = "workspaces"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    slug = Column(String(100), unique=True, index=True, nullable=False)
    description = Column(Text, default="")
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    tier = Column(String(50), default="Team") # Starter, Team, Enterprise
    max_seats = Column(Integer, default=10)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=utc_now)
    updated_at = Column(DateTime, default=utc_now)

    owner = relationship("User", back_populates="owned_workspaces", foreign_keys=[owner_id])
    members = relationship("WorkspaceMember", back_populates="workspace", cascade="all, delete-orphan")
    invites = relationship("WorkspaceInvite", back_populates="workspace", cascade="all, delete-orphan")
    notes = relationship("CollaborativeNote", back_populates="workspace", cascade="all, delete-orphan")
    meetings = relationship("Meeting", back_populates="workspace")

class WorkspaceMember(Base):
    __tablename__ = "workspace_members"

    id = Column(Integer, primary_key=True, index=True)
    workspace_id = Column(Integer, ForeignKey("workspaces.id"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    role = Column(String(50), nullable=False, default="viewer") # owner, admin, manager, editor, viewer
    joined_at = Column(DateTime, default=utc_now)

    workspace = relationship("Workspace", back_populates="members")
    user = relationship("User", back_populates="workspace_memberships")

class WorkspaceInvite(Base):
    __tablename__ = "workspace_invites"

    id = Column(Integer, primary_key=True, index=True)
    workspace_id = Column(Integer, ForeignKey("workspaces.id"), nullable=False, index=True)
    inviter_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    email = Column(String(255), nullable=False, index=True)
    role = Column(String(50), default="editor") # admin, manager, editor, viewer
    invite_token = Column(String(128), unique=True, index=True, nullable=False)
    status = Column(String(30), default="pending") # pending, accepted, revoked, expired
    expires_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=utc_now)
    accepted_at = Column(DateTime, nullable=True)

    workspace = relationship("Workspace", back_populates="invites")
    inviter = relationship("User")

class CollaborativeNote(Base):
    __tablename__ = "collaborative_notes"

    id = Column(Integer, primary_key=True, index=True)
    workspace_id = Column(Integer, ForeignKey("workspaces.id"), nullable=False, index=True)
    meeting_id = Column(Integer, ForeignKey("meetings.id"), nullable=True, index=True)
    title = Column(String(255), nullable=False, default="Team Meeting Notes")
    content = Column(Text, default="")
    last_edited_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    last_edited_by_name = Column(String(100), default="Team Member")
    version = Column(Integer, default=1)
    created_at = Column(DateTime, default=utc_now)
    updated_at = Column(DateTime, default=utc_now)

    workspace = relationship("Workspace", back_populates="notes")
    meeting = relationship("Meeting")
    revisions = relationship("CollaborativeNoteRevision", back_populates="note", cascade="all, delete-orphan")

class CollaborativeNoteRevision(Base):
    __tablename__ = "collaborative_note_revisions"

    id = Column(Integer, primary_key=True, index=True)
    note_id = Column(Integer, ForeignKey("collaborative_notes.id"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    user_name = Column(String(100), default="Team Member")
    content_snapshot = Column(Text, nullable=False)
    revision_summary = Column(String(255), default="Document update")
    version = Column(Integer, default=1)
    created_at = Column(DateTime, default=utc_now)

    note = relationship("CollaborativeNote", back_populates="revisions")
    user = relationship("User")

class Meeting(Base):
    __tablename__ = "meetings"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String(255), nullable=False)
    category = Column(String(50), default="Meetings") # Meetings, Permanent, Hot, YouTube, General
    tint = Column(String(20), default="lilac") # lilac, peach, rose, mint, magenta, sky
    source_type = Column(String(50), default="audio_recording") # audio_recording, audio_upload, meeting_link, youtube, document, manual
    audio_file_path = Column(String(500), nullable=True)
    duration_seconds = Column(Integer, default=0)
    workspace_id = Column(Integer, ForeignKey("workspaces.id"), nullable=True, index=True)
    created_at = Column(DateTime, default=utc_now)

    user = relationship("User", back_populates="meetings")
    workspace = relationship("Workspace", back_populates="meetings")
    transcripts = relationship("TranscriptSegment", back_populates="meeting", cascade="all, delete-orphan")
    chunks = relationship("MeetingChunk", back_populates="meeting", cascade="all, delete-orphan")
    summary = relationship("MeetingSummary", back_populates="meeting", uselist=False, cascade="all, delete-orphan")
    tasks = relationship("Task", back_populates="meeting", cascade="all, delete-orphan")

class TranscriptSegment(Base):
    __tablename__ = "transcript_segments"

    id = Column(Integer, primary_key=True, index=True)
    meeting_id = Column(Integer, ForeignKey("meetings.id"), nullable=False)
    speaker_label = Column(String(100), default="Speaker 1")
    start_time = Column(String(20), default="00:00")
    end_time = Column(String(20), default="00:30")
    text = Column(Text, nullable=False)

    meeting = relationship("Meeting", back_populates="transcripts")

class MeetingChunk(Base):
    __tablename__ = "meeting_chunks"

    id = Column(Integer, primary_key=True, index=True)
    meeting_id = Column(Integer, ForeignKey("meetings.id"), nullable=False)
    speaker_label = Column(String(100), default="Speaker 1")
    start_time = Column(String(20), default="00:00")
    end_time = Column(String(20), default="00:30")
    text = Column(Text, nullable=False)
    embedding_json = Column(Text, default="[]")

    meeting = relationship("Meeting", back_populates="chunks")

class MeetingSummary(Base):
    __tablename__ = "meeting_summaries"

    id = Column(Integer, primary_key=True, index=True)
    meeting_id = Column(Integer, ForeignKey("meetings.id"), nullable=False)
    executive_summary = Column(Text, nullable=False)
    key_points_json = Column(Text, default="[]") # JSON list
    decisions_json = Column(Text, default="[]") # JSON list
    action_items_json = Column(Text, default="[]") # JSON list
    risks_json = Column(Text, default="[]") # JSON list
    created_at = Column(DateTime, default=utc_now)

    meeting = relationship("Meeting", back_populates="summary")

# --------------------------------------------------------------------------
# PHASE 3: Tasks & Automation Models
# --------------------------------------------------------------------------
class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    meeting_id = Column(Integer, ForeignKey("meetings.id"), nullable=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, default="")
    workspace_id = Column(Integer, ForeignKey("workspaces.id"), nullable=True, index=True)
    assignee = Column(String(100), default="Unassigned")
    deadline = Column(String(50), nullable=True)
    priority = Column(String(20), default="medium") # low, medium, high, urgent
    status = Column(String(20), default="pending") # pending, in_progress, completed, overdue, cancelled
    confidence_score = Column(Float, default=1.0)
    source_transcript_timestamp = Column(String(20), default="00:00")
    evidence_quote = Column(Text, default="")
    is_ai_generated = Column(Boolean, default=False)
    is_approved = Column(Boolean, default=True) # AI tasks require review
    project = Column(String(100), default="Core Sprint")
    created_at = Column(DateTime, default=utc_now)
    updated_at = Column(DateTime, default=utc_now)

    user = relationship("User", back_populates="tasks")
    meeting = relationship("Meeting", back_populates="tasks")
    comments = relationship("TaskComment", back_populates="task", cascade="all, delete-orphan")
    history = relationship("TaskHistory", back_populates="task", cascade="all, delete-orphan")
    approvals = relationship("ApprovalRequest", back_populates="task", cascade="all, delete-orphan")

class TaskComment(Base):
    __tablename__ = "task_comments"

    id = Column(Integer, primary_key=True, index=True)
    task_id = Column(Integer, ForeignKey("tasks.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    author_name = Column(String(100), default="Emily Watson")
    comment_text = Column(Text, nullable=False)
    created_at = Column(DateTime, default=utc_now)

    task = relationship("Task", back_populates="comments")

class TaskHistory(Base):
    __tablename__ = "task_history"

    id = Column(Integer, primary_key=True, index=True)
    task_id = Column(Integer, ForeignKey("tasks.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    action = Column(String(100), nullable=False) # created, updated, status_changed, assigned, approved
    previous_state = Column(Text, default="")
    new_state = Column(Text, default="")
    timestamp = Column(DateTime, default=utc_now)

    task = relationship("Task", back_populates="history")

class ApprovalRequest(Base):
    __tablename__ = "approval_requests"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    task_id = Column(Integer, ForeignKey("tasks.id"), nullable=False)
    requester_name = Column(String(100), default="AI Synthesizer")
    approver_name = Column(String(100), default="Emily Watson (Manager)")
    status = Column(String(20), default="pending") # pending, approved, rejected
    decision_notes = Column(Text, default="")
    requested_at = Column(DateTime, default=utc_now)
    resolved_at = Column(DateTime, nullable=True)

    user = relationship("User", back_populates="approval_requests")
    task = relationship("Task", back_populates="approvals")

class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    type = Column(String(50), default="deadline") # deadline, overdue, assigned, completed, approval, reminder
    title = Column(String(255), nullable=False)
    message = Column(Text, nullable=False)
    link_url = Column(String(255), default="#tasks")
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=utc_now)

    user = relationship("User", back_populates="notifications")

class Workflow(Base):
    __tablename__ = "workflows"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text, default="")
    trigger_type = Column(String(50), default="meeting_completed") # meeting_completed, task_overdue, status_changed
    conditions_json = Column(Text, default="[]") # rules list
    actions_json = Column(Text, default="[]") # sequential action list
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=utc_now)
    updated_at = Column(DateTime, default=utc_now)

    user = relationship("User", back_populates="workflows")
    executions = relationship("WorkflowExecution", back_populates="workflow", cascade="all, delete-orphan")

class WorkflowExecution(Base):
    __tablename__ = "workflow_executions"

    id = Column(Integer, primary_key=True, index=True)
    workflow_id = Column(Integer, ForeignKey("workflows.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    trigger_event = Column(String(100), nullable=False)
    status = Column(String(20), default="success") # success, failed, retrying
    logs_json = Column(Text, default="[]")
    retry_count = Column(Integer, default=0)
    executed_at = Column(DateTime, default=utc_now)

    workflow = relationship("Workflow", back_populates="executions")

# --------------------------------------------------------------------------
# Existing Knowledge & Memory Models
# --------------------------------------------------------------------------
class KnowledgeDocument(Base):
    __tablename__ = "knowledge_documents"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String(255), nullable=False)
    file_type = Column(String(20), default="pdf") # pdf, docx, txt, csv
    file_size = Column(Integer, default=0)
    category = Column(String(100), default="General Policy")
    status = Column(String(30), default="indexed") # uploaded, processing, indexed, failed
    chunk_count = Column(Integer, default=0)
    workspace_id = Column(Integer, ForeignKey("workspaces.id"), nullable=True, index=True)
    raw_text = Column(Text, nullable=True)
    created_at = Column(DateTime, default=utc_now)

    user = relationship("User", back_populates="knowledge_documents")
    chunks = relationship("DocumentChunk", back_populates="document", cascade="all, delete-orphan")

class DocumentChunk(Base):
    __tablename__ = "document_chunks"

    id = Column(Integer, primary_key=True, index=True)
    document_id = Column(Integer, ForeignKey("knowledge_documents.id"), nullable=False)
    chunk_index = Column(Integer, default=0)
    page_number = Column(Integer, default=1)
    text = Column(Text, nullable=False)
    embedding_json = Column(Text, default="[]")

    document = relationship("KnowledgeDocument", back_populates="chunks")

class MeetingMemory(Base):
    __tablename__ = "meeting_memories"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    workspace_id = Column(Integer, ForeignKey("workspaces.id"), nullable=True, index=True)
    category = Column(String(100), default="Important Decisions")
    fact_statement = Column(Text, nullable=False)
    meeting_id = Column(Integer, ForeignKey("meetings.id"), nullable=True)
    meeting_title = Column(String(255), default="")
    timestamp = Column(String(20), default="00:00")
    confidence = Column(String(20), default="0.95")
    revisions_json = Column(Text, default="[]")
    created_at = Column(DateTime, default=utc_now)
    updated_at = Column(DateTime, default=utc_now)

    user = relationship("User", back_populates="memories")

class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    role = Column(String(20), nullable=False) # user or assistant
    content = Column(Text, nullable=False)
    citations_json = Column(Text, default="[]")

# --------------------------------------------------------------------------
# PHASE 4: Third-Party Integrations Ecosystem Models
# --------------------------------------------------------------------------
class Integration(Base):
    __tablename__ = "integrations"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    provider = Column(String(50), nullable=False, index=True) # google_calendar, gmail, google_drive, outlook, jira, trello, slack, notion, zapier, whatsapp
    connection_status = Column(String(30), default="not_connected") # not_connected, connecting, connected, expired, permission_required, error, disconnected
    account_email = Column(String(255), default="")
    account_name = Column(String(255), default="")
    external_account_id = Column(String(255), default="")
    authorized_scopes_json = Column(Text, default="[]")
    encrypted_access_token = Column(Text, default="")
    encrypted_refresh_token = Column(Text, default="")
    token_expiry = Column(DateTime, nullable=True)
    settings_json = Column(Text, default="{}")
    last_synced_at = Column(DateTime, nullable=True)
    error_message = Column(Text, default="")
    created_at = Column(DateTime, default=utc_now)
    updated_at = Column(DateTime, default=utc_now)

    user = relationship("User", back_populates="integrations")

class ExternalEntityMapping(Base):
    __tablename__ = "external_entity_mappings"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    provider = Column(String(50), nullable=False, index=True)
    entity_type = Column(String(50), nullable=False) # task_event, task_issue, task_card, meeting_page, drive_doc
    internal_id = Column(Integer, nullable=False, index=True)
    external_id = Column(String(255), nullable=False)
    external_url = Column(String(500), default="")
    sync_hash = Column(String(64), default="")
    last_synced_at = Column(DateTime, default=utc_now)
    created_at = Column(DateTime, default=utc_now)

    user = relationship("User", back_populates="entity_mappings")

class WebhookSubscription(Base):
    __tablename__ = "webhook_subscriptions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(255), default="Custom Webhook")
    target_url = Column(String(500), nullable=False)
    secret_key = Column(String(255), nullable=False)
    events_json = Column(Text, default="[]") # JSON list of subscribed events
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=utc_now)
    updated_at = Column(DateTime, default=utc_now)

    user = relationship("User", back_populates="webhook_subscriptions")
    deliveries = relationship("WebhookDelivery", back_populates="subscription", cascade="all, delete-orphan")

class WebhookDelivery(Base):
    __tablename__ = "webhook_deliveries"

    id = Column(Integer, primary_key=True, index=True)
    subscription_id = Column(Integer, ForeignKey("webhook_subscriptions.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    event_type = Column(String(100), nullable=False)
    payload_json = Column(Text, nullable=False)
    status_code = Column(Integer, default=0)
    response_body = Column(Text, default="")
    success = Column(Boolean, default=False)
    retry_count = Column(Integer, default=0)
    error_message = Column(Text, default="")
    delivered_at = Column(DateTime, default=utc_now)

    subscription = relationship("WebhookSubscription", back_populates="deliveries")

class IntegrationJob(Base):
    __tablename__ = "integration_jobs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    provider = Column(String(50), nullable=False)
    job_type = Column(String(50), nullable=False) # sync_calendar, create_draft, import_doc, export_page, post_slack
    status = Column(String(30), default="completed") # pending, in_progress, completed, failed
    details_json = Column(Text, default="{}")
    error_message = Column(Text, default="")
    created_at = Column(DateTime, default=utc_now)
    completed_at = Column(DateTime, default=utc_now)

    user = relationship("User", back_populates="integration_jobs")

class OAuthNonce(Base):
    """
    Persistent shared storage for OAuth 2.0 state nonces and PKCE verifiers.
    Guarantees:
    - 256-bit cryptographically unique nonces.
    - 15-minute expiration enforcement.
    - Atomic one-time consumption (thread-safe, multi-instance, survives process restarts).
    - Cryptographic binding to user_id and provider.
    - Secure storage of the RFC 7636 PKCE code_verifier associated with the transaction.
    """
    __tablename__ = "oauth_nonces"

    id = Column(Integer, primary_key=True, index=True)
    nonce = Column(String(128), unique=True, index=True, nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    provider = Column(String(50), nullable=False, index=True)
    code_verifier = Column(String(255), nullable=True) # Secure PKCE association
    consumed = Column(Boolean, default=False, nullable=False, index=True)
    consumed_at = Column(DateTime, nullable=True)
    expires_at = Column(DateTime, nullable=False, index=True)
    created_at = Column(DateTime, default=utc_now)

    user = relationship("User", back_populates="oauth_nonces")

class ProcessedWebhookMessage(Base):
    """
    Tracks processed inbound webhook messages (e.g. WhatsApp wamid) to prevent
    duplicate message processing and replay attempts.
    """
    __tablename__ = "processed_webhook_messages"

    id = Column(Integer, primary_key=True, index=True)
    provider = Column(String(50), nullable=False, index=True) # whatsapp, zapier
    message_id = Column(String(255), unique=True, index=True, nullable=False)
    sender = Column(String(255), nullable=True, index=True)
    processed_at = Column(DateTime, default=utc_now)

