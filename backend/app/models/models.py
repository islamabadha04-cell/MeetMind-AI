from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.session import Base

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
    created_at = Column(DateTime, default=datetime.utcnow)

    meetings = relationship("Meeting", back_populates="user", cascade="all, delete-orphan")
    tasks = relationship("Task", back_populates="user", cascade="all, delete-orphan")

class Workspace(Base):
    __tablename__ = "workspaces"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    owner_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, default=datetime.utcnow)

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
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="meetings")
    transcripts = relationship("TranscriptSegment", back_populates="meeting", cascade="all, delete-orphan")
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

class MeetingSummary(Base):
    __tablename__ = "meeting_summaries"

    id = Column(Integer, primary_key=True, index=True)
    meeting_id = Column(Integer, ForeignKey("meetings.id"), nullable=False)
    executive_summary = Column(Text, nullable=False)
    key_points_json = Column(Text, default="[]") # JSON list
    decisions_json = Column(Text, default="[]") # JSON list
    action_items_json = Column(Text, default="[]") # JSON list
    risks_json = Column(Text, default="[]") # JSON list
    created_at = Column(DateTime, default=datetime.utcnow)

    meeting = relationship("Meeting", back_populates="summary")

class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    meeting_id = Column(Integer, ForeignKey("meetings.id"), nullable=True)
    title = Column(String(255), nullable=False)
    assignee = Column(String(100), default="Unassigned")
    deadline = Column(String(50), nullable=True)
    priority = Column(String(20), default="medium") # low, medium, high
    status = Column(String(20), default="pending") # pending, in_progress, completed
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="tasks")
    meeting = relationship("Meeting", back_populates="tasks")

class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    role = Column(String(20), nullable=False) # user or assistant
    content = Column(Text, nullable=False)
    citations_json = Column(Text, default="[]") # citations referencing meetings
    created_at = Column(DateTime, default=datetime.utcnow)
