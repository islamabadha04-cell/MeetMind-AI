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
    knowledge_documents = relationship("KnowledgeDocument", back_populates="user", cascade="all, delete-orphan")
    memories = relationship("MeetingMemory", back_populates="user", cascade="all, delete-orphan")

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
    raw_text = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

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
    category = Column(String(100), default="Important Decisions")
    fact_statement = Column(Text, nullable=False)
    meeting_id = Column(Integer, ForeignKey("meetings.id"), nullable=True)
    meeting_title = Column(String(255), default="")
    timestamp = Column(String(20), default="00:00")
    confidence = Column(String(20), default="0.95")
    revisions_json = Column(Text, default="[]")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="memories")

class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    role = Column(String(20), nullable=False) # user or assistant
    content = Column(Text, nullable=False)
    citations_json = Column(Text, default="[]") # citations referencing meetings or documents
    created_at = Column(DateTime, default=datetime.utcnow)
