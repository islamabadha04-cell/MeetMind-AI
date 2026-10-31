from pydantic import BaseModel, ConfigDict
from typing import List, Optional, Dict, Any
from datetime import datetime

# Auth Schemas
class UserRegister(BaseModel):
    email: str
    password: str
    full_name: Optional[str] = "Ali Raza"

class UserLogin(BaseModel):
    email: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_name: str
    plan: str

class UserProfile(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    email: str
    full_name: str
    avatar_url: str
    plan: str
    minutes_used: int
    minutes_limit: int

# Task Schemas
class TaskCreate(BaseModel):
    title: str
    meeting_id: Optional[int] = None
    assignee: Optional[str] = "Ali"
    deadline: Optional[str] = None
    priority: Optional[str] = "medium"

class TaskResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    title: str
    assignee: str
    deadline: Optional[str]
    priority: str
    status: str
    meeting_id: Optional[int]

# Meeting Schemas
class MeetingCreate(BaseModel):
    title: str
    category: Optional[str] = "Meetings"
    tint: Optional[str] = "lilac"
    source_type: Optional[str] = "audio_recording"
    duration_seconds: Optional[int] = 0
    transcript_text: Optional[str] = None

class MeetingResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    title: str
    category: str
    tint: str
    source_type: str
    duration_seconds: int
    created_at: datetime
    summary: Optional[str] = None
    action_items: Optional[List[str]] = []

# Chat Schemas
class ChatQuery(BaseModel):
    question: str
    scope: Optional[str] = "all" # "meetings", "knowledge", "all"
    meeting_ids: Optional[List[int]] = None
    document_ids: Optional[List[int]] = None
    language: Optional[str] = "en" # "en", "ur", "roman"

class ChatResponse(BaseModel):
    role: str = "assistant"
    content: str
    citations: List[dict] = []
    scope_used: Optional[str] = "all"

# PHASE 2: Semantic Search Schemas
class SemanticSearchQuery(BaseModel):
    query: str
    mode: Optional[str] = "hybrid" # "semantic", "keyword", "hybrid"
    date_filter: Optional[str] = "all"
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

# PHASE 2: Meeting Comparison Schemas
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

# PHASE 2: Company Knowledge Base Schemas
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

# PHASE 2: Meeting Memory Schemas
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
