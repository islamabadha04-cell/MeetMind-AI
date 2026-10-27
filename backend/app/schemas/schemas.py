from pydantic import BaseModel
from typing import List, Optional
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
    id: int
    email: str
    full_name: str
    avatar_url: str
    plan: str
    minutes_used: int
    minutes_limit: int

    class Config:
        from_attributes = True

# Task Schemas
class TaskCreate(BaseModel):
    title: str
    meeting_id: Optional[int] = None
    assignee: Optional[str] = "Ali"
    deadline: Optional[str] = None
    priority: Optional[str] = "medium"

class TaskResponse(BaseModel):
    id: int
    title: str
    assignee: str
    deadline: Optional[str]
    priority: str
    status: str
    meeting_id: Optional[int]

    class Config:
        from_attributes = True

# Meeting Schemas
class MeetingCreate(BaseModel):
    title: str
    category: Optional[str] = "Meetings"
    tint: Optional[str] = "lilac"
    source_type: Optional[str] = "audio_recording"
    duration_seconds: Optional[int] = 0
    transcript_text: Optional[str] = None

class MeetingResponse(BaseModel):
    id: int
    title: str
    category: str
    tint: str
    source_type: str
    duration_seconds: int
    created_at: datetime
    summary: Optional[str] = None
    action_items: Optional[List[str]] = []

    class Config:
        from_attributes = True

# Chat Schemas
class ChatQuery(BaseModel):
    question: str

class ChatResponse(BaseModel):
    role: str = "assistant"
    content: str
    citations: List[dict] = []
