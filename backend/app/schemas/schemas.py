from pydantic import BaseModel, ConfigDict
from typing import Optional, List, Dict, Any
from datetime import datetime

# ----------------- Auth Schemas -----------------
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_name: Optional[str] = "Emily Watson"
    plan: Optional[str] = "Pro"

class TokenData(BaseModel):
    user_id: Optional[int] = None
    email: Optional[str] = None

class UserBase(BaseModel):
    email: str
    full_name: Optional[str] = "Emily Watson"

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

class UserResponse(UserBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    avatar_url: Optional[str] = None
    plan: str
    minutes_used: int
    minutes_limit: int
    created_at: datetime

UserRegister = UserCreate
UserProfile = UserResponse

# ----------------- Meeting Schemas -----------------
class MeetingBase(BaseModel):
    title: str
    category: Optional[str] = "Meetings"
    tint: Optional[str] = "lilac"
    source_type: Optional[str] = "audio_recording"
    duration_seconds: Optional[int] = 0

class MeetingCreate(MeetingBase):
    transcript_text: Optional[str] = ""

class MeetingUpdate(BaseModel):
    title: Optional[str] = None
    category: Optional[str] = None
    tint: Optional[str] = None
    transcript_text: Optional[str] = None

class MeetingResponse(MeetingBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    created_at: datetime
    summary: Optional[str] = None
    action_items: Optional[List[str]] = []

# ----------------- PHASE 2: Semantic Search Schemas -----------------
class SemanticSearchQuery(BaseModel):
    query: str
    mode: Optional[str] = "hybrid" # "semantic" | "keyword" | "hybrid"
    category: Optional[str] = "all"
    speaker: Optional[str] = "all"
    limit: Optional[int] = 10

class SemanticSearchHit(BaseModel):
    meeting_id: int
    meeting_title: str
    date_str: str
    speaker: str
    timestamp: str
    excerpt: str
    relevance_score: float
    match_type: str # "semantic" | "keyword" | "hybrid"

class SemanticSearchResponse(BaseModel):
    query: str
    total_matches: int
    ai_synthesis: str
    results: List[SemanticSearchHit]

# ----------------- PHASE 2: Meeting Comparison Schemas -----------------
class MeetingComparisonRequest(BaseModel):
    meeting_a_id: int
    meeting_b_id: int

class ComparisonRow(BaseModel):
    category: str
    meeting_a_value: str
    meeting_b_value: str
    delta_analysis: str
    status: str # "changed", "same", "progressed", "risk", "not_mentioned"

class MeetingComparisonResponse(BaseModel):
    meeting_a: Dict[str, Any]
    meeting_b: Dict[str, Any]
    executive_delta: str
    matrix: List[ComparisonRow]
    progress_score: int # 0-100%

# ----------------- PHASE 2: Company Knowledge Base Schemas -----------------
class KnowledgeDocResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    title: str
    file_type: str
    file_size: int
    category: str
    status: str
    chunk_count: int
    created_at: datetime

# ----------------- PHASE 2: Meeting Memory Schemas -----------------
class MemoryItemCreate(BaseModel):
    category: str
    fact_statement: str
    meeting_id: Optional[int] = None
    meeting_title: Optional[str] = ""
    timestamp: Optional[str] = "00:00"

class MemoryItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    category: str
    fact_statement: str
    meeting_id: Optional[int]
    meeting_title: Optional[str]
    timestamp: Optional[str]
    confidence: Optional[str]
    revisions: Optional[List[Dict[str, Any]]] = []
    created_at: datetime
    updated_at: datetime

# ----------------- PHASE 2: Universal Chat Schemas -----------------
class ChatQuery(BaseModel):
    question: str
    scope: Optional[str] = "all" # "meetings" | "knowledge" | "all"
    language: Optional[str] = "en" # "en" | "ur" | "roman"

class ChatResponse(BaseModel):
    role: str
    content: str
    citations: List[Dict[str, Any]]
    scope_used: Optional[str] = "all"

# ----------------- PHASE 3: Task Management Schemas -----------------
class TaskCreate(BaseModel):
    title: str
    description: Optional[str] = ""
    meeting_id: Optional[int] = None
    assignee: Optional[str] = "Unassigned"
    deadline: Optional[str] = None
    priority: Optional[str] = "medium" # low, medium, high, urgent
    status: Optional[str] = "pending"
    project: Optional[str] = "Core Sprint"
    is_ai_generated: Optional[bool] = False
    is_approved: Optional[bool] = True
    confidence_score: Optional[float] = 1.0
    source_transcript_timestamp: Optional[str] = "00:00"
    evidence_quote: Optional[str] = ""

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    assignee: Optional[str] = None
    deadline: Optional[str] = None
    priority: Optional[str] = None
    status: Optional[str] = None
    project: Optional[str] = None
    is_approved: Optional[bool] = None

class TaskCommentCreate(BaseModel):
    comment_text: str
    author_name: Optional[str] = "Emily Watson"

class TaskCommentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    task_id: int
    author_name: str
    comment_text: str
    created_at: datetime

class TaskHistoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    task_id: int
    action: str
    previous_state: str
    new_state: str
    timestamp: datetime

class TaskResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    title: str
    description: Optional[str] = ""
    meeting_id: Optional[int] = None
    assignee: str
    deadline: Optional[str] = None
    priority: str
    status: str
    project: Optional[str] = "Core Sprint"
    confidence_score: Optional[float] = 1.0
    source_transcript_timestamp: Optional[str] = "00:00"
    evidence_quote: Optional[str] = ""
    is_ai_generated: Optional[bool] = False
    is_approved: Optional[bool] = True
    created_at: datetime
    updated_at: datetime
    comments: Optional[List[TaskCommentResponse]] = []
    history: Optional[List[TaskHistoryResponse]] = []

# ----------------- PHASE 3: Manager Approval Schemas -----------------
class ApprovalAction(BaseModel):
    decision: str # "approve" or "reject"
    decision_notes: Optional[str] = ""
    approver_name: Optional[str] = "Emily Watson (Manager)"
    override_assignee: Optional[str] = None
    override_deadline: Optional[str] = None

class ApprovalResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    task_id: int
    requester_name: str
    approver_name: str
    status: str
    decision_notes: Optional[str] = ""
    requested_at: datetime
    resolved_at: Optional[datetime] = None

# ----------------- PHASE 3: Notification Schemas -----------------
class NotificationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    type: str
    title: str
    message: str
    link_url: str
    is_read: bool
    created_at: datetime

# ----------------- PHASE 3: Workflow Automation Schemas -----------------
class WorkflowCreate(BaseModel):
    title: str
    description: Optional[str] = ""
    trigger_type: str # "meeting_completed", "task_overdue", "status_changed"
    conditions_json: Optional[str] = "[]"
    actions_json: Optional[str] = "[]"
    is_active: Optional[bool] = True

class WorkflowResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    title: str
    description: Optional[str] = ""
    trigger_type: str
    conditions_json: str
    actions_json: str
    is_active: bool
    created_at: datetime
    updated_at: datetime

class WorkflowExecutionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    workflow_id: int
    trigger_event: str
    status: str
    logs_json: str
    retry_count: int
    executed_at: datetime

# ----------------- PHASE 3: Follow-Up Draft Schemas -----------------
class FollowUpGenerateRequest(BaseModel):
    meeting_id: Optional[int] = None
    follow_up_type: str # "client_followup", "internal_team", "project_status", "payment_reminder", "deadline_reminder", "meeting_summary"
    language: Optional[str] = "en" # "en", "ur", "roman"
    recipient_name: Optional[str] = "Client / Team"
    extra_instructions: Optional[str] = ""

class FollowUpGenerateResponse(BaseModel):
    subject: str
    recipient: str
    body: str
    follow_up_type: str
    language: str
    meeting_title: str

# ----------------- PHASE 4: Integrations Ecosystem Schemas -----------------
class IntegrationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: Optional[int] = None
    provider: str
    provider_name: str
    category: str # "Calendar & Scheduling", "Email & Messaging", "Cloud Storage & Docs", "Project Management", "Automation & Webhooks", "Mobile & Chat"
    icon: str
    description: str
    connection_status: str # "not_connected", "connecting", "connected", "expired", "permission_required", "error", "disconnected"
    account_email: Optional[str] = ""
    account_name: Optional[str] = ""
    external_account_id: Optional[str] = ""
    authorized_scopes: List[str] = []
    last_synced_at: Optional[datetime] = None
    settings: Dict[str, Any] = {}
    error_message: Optional[str] = ""

class IntegrationConnectRequest(BaseModel):
    auth_code: Optional[str] = None
    redirect_uri: Optional[str] = None
    api_key: Optional[str] = None
    token: Optional[str] = None
    account_email: Optional[str] = None
    settings: Optional[Dict[str, Any]] = None

class IntegrationConnectResponse(BaseModel):
    provider: str
    connection_status: str
    auth_url: Optional[str] = None
    message: str

class IntegrationTestResponse(BaseModel):
    provider: str
    success: bool
    status: str
    message: str
    account_info: Optional[Dict[str, Any]] = None

class CalendarEventItem(BaseModel):
    id: str
    title: str
    start_time: str
    end_time: str
    source: str # "google_calendar", "outlook", "meetmind_task"
    link: Optional[str] = None
    attendees: Optional[List[str]] = []
    status: Optional[str] = "confirmed"

class CalendarSyncTaskRequest(BaseModel):
    task_id: int
    calendar_id: Optional[str] = "primary"

class CalendarSyncTaskResponse(BaseModel):
    success: bool
    task_id: int
    event_id: str
    event_url: Optional[str] = None
    message: str

class GmailDraftRequest(BaseModel):
    recipient: str
    subject: str
    body: str
    meeting_id: Optional[int] = None

class GmailDraftResponse(BaseModel):
    success: bool
    draft_id: str
    subject: str
    recipient: str
    status: str
    message: str

class GoogleDriveFileItem(BaseModel):
    id: str
    name: str
    mime_type: str
    size_bytes: Optional[int] = 0
    modified_time: Optional[str] = None

class GoogleDriveImportRequest(BaseModel):
    file_id: str
    file_name: str
    category: Optional[str] = "Imported Drive Documents"

class GoogleDriveImportResponse(BaseModel):
    success: bool
    document_id: int
    title: str
    chunks_indexed: int
    message: str

class OutlookSyncTaskRequest(BaseModel):
    task_id: int

class OutlookDraftRequest(BaseModel):
    recipient: str
    subject: str
    body: str

class JiraProjectItem(BaseModel):
    id: str
    key: str
    name: str

class JiraCreateIssueRequest(BaseModel):
    task_id: int
    project_key: str
    issue_type: Optional[str] = "Task"

class JiraCreateIssueResponse(BaseModel):
    success: bool
    issue_key: str
    issue_url: str
    message: str

class TrelloBoardItem(BaseModel):
    id: str
    name: str

class TrelloCreateCardRequest(BaseModel):
    task_id: int
    board_id: str
    list_id: Optional[str] = None

class TrelloCreateCardResponse(BaseModel):
    success: bool
    card_id: str
    card_url: str
    message: str

class SlackChannelItem(BaseModel):
    id: str
    name: str
    is_private: bool = False

class SlackPostSummaryRequest(BaseModel):
    meeting_id: int
    channel_id: str
    include_decisions: Optional[bool] = True
    include_action_items: Optional[bool] = True

class SlackPostSummaryResponse(BaseModel):
    success: bool
    channel_id: str
    timestamp: str
    message: str

class NotionExportPageRequest(BaseModel):
    meeting_id: int
    parent_page_id: Optional[str] = None

class NotionExportPageResponse(BaseModel):
    success: bool
    page_id: str
    page_url: str
    message: str

class WebhookSubscriptionCreate(BaseModel):
    name: str
    target_url: str
    events: List[str]

class WebhookSubscriptionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    target_url: str
    events: List[str]
    secret_key: str
    is_active: bool
    created_at: datetime

class WebhookDeliveryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    event_type: str
    status_code: int
    success: bool
    retry_count: int
    error_message: Optional[str] = None
    delivered_at: datetime
