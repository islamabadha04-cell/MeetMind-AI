from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List
import json

from app.core.config import settings
from app.db.session import engine, Base, get_db
from app.models.models import User, Meeting, MeetingSummary, Task, ChatMessage
from app.schemas.schemas import (
    UserRegister, UserLogin, Token, UserProfile,
    MeetingCreate, MeetingResponse, TaskCreate, TaskResponse,
    ChatQuery, ChatResponse
)
from app.core.security import get_password_hash, verify_password, create_access_token
from app.services.ai_service import AIService

# Initialize DB tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.PROJECT_NAME,
    version="1.0.0",
    description="Next-Generation AI Meeting Assistant & Smart Productivity Platform (2026)",
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url=f"{settings.API_V1_STR}/docs"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Seed default demo user and meetings if empty
@app.on_event("startup")
def startup_db_seed():
    db = next(get_db())
    try:
        user = db.query(User).filter(User.email == "emily@example.com").first()
        if not user:
            user = User(
                email="emily@example.com",
                hashed_password=get_password_hash("password123"),
                full_name="Emily Watson",
                avatar_url="/assets/emily.jpg",
                plan="Pro",
                minutes_used=42,
                minutes_limit=500
            )
            db.add(user)
            db.commit()
            db.refresh(user)

            # Sample Meetings
            m1 = Meeting(
                user_id=user.id,
                title="Cowlar meeting points",
                category="Meetings",
                tint="lilac",
                source_type="meeting_link",
                duration_seconds=1840
            )
            db.add(m1)
            db.commit()
            db.refresh(m1)

            sum1 = MeetingSummary(
                meeting_id=m1.id,
                executive_summary="Reviewed project roadmap, low latency API design, and telemetry pipeline.",
                key_points_json=json.dumps(["Reduced API latency under 80ms", "Scheduled next sprint kickoff"]),
                action_items_json=json.dumps(["Finalize schema definitions", "Review mobile audio waveforms"])
            )
            db.add(sum1)

            # Sample Tasks
            t1 = Task(
                user_id=user.id,
                meeting_id=m1.id,
                title="Review Cowlar telemetry specifications",
                assignee="Emily",
                deadline="Friday, 5:00 PM",
                priority="high",
                status="pending"
            )
            t2 = Task(
                user_id=user.id,
                meeting_id=m1.id,
                title="Deploy PWA mobile service worker cache",
                assignee="Dev Team",
                deadline="Tomorrow",
                priority="medium",
                status="completed"
            )
            db.add(t1)
            db.add(t2)
            db.commit()
    finally:
        db.close()

# ----------------- Auth Endpoints -----------------
@app.post(f"{settings.API_V1_STR}/auth/register", response_model=Token)
def register(user_in: UserRegister, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == user_in.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="User with this email already exists")
    
    user = User(
        email=user_in.email,
        hashed_password=get_password_hash(user_in.password),
        full_name=user_in.full_name or "New User"
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token(user.id)
    return Token(access_token=token, user_name=user.full_name, plan=user.plan)

@app.post(f"{settings.API_V1_STR}/auth/login", response_model=Token)
def login(login_in: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == login_in.email).first()
    if not user or not verify_password(login_in.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    
    token = create_access_token(user.id)
    return Token(access_token=token, user_name=user.full_name, plan=user.plan)

@app.get(f"{settings.API_V1_STR}/users/me", response_model=UserProfile)
def get_me(db: Session = Depends(get_db)):
    user = db.query(User).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

# ----------------- Meetings Endpoints -----------------
@app.get(f"{settings.API_V1_STR}/meetings", response_model=List[MeetingResponse])
def get_meetings(db: Session = Depends(get_db)):
    meetings = db.query(Meeting).order_by(Meeting.created_at.desc()).all()
    res = []
    for m in meetings:
        sum_text = m.summary.executive_summary if m.summary else None
        actions = json.loads(m.summary.action_items_json) if (m.summary and m.summary.action_items_json) else []
        res.append(MeetingResponse(
            id=m.id,
            title=m.title,
            category=m.category,
            tint=m.tint,
            source_type=m.source_type,
            duration_seconds=m.duration_seconds,
            created_at=m.created_at,
            summary=sum_text,
            action_items=actions
        ))
    return res

@app.post(f"{settings.API_V1_STR}/meetings", response_model=MeetingResponse)
def create_meeting(item: MeetingCreate, db: Session = Depends(get_db)):
    user = db.query(User).first()
    new_m = Meeting(
        user_id=user.id if user else 1,
        title=item.title,
        category=item.category,
        tint=item.tint,
        source_type=item.source_type,
        duration_seconds=item.duration_seconds
    )
    db.add(new_m)
    db.commit()
    db.refresh(new_m)

    # Generate AI summary
    ai_data = AIService.generate_meeting_summary(item.title, item.transcript_text or item.title)
    summary_record = MeetingSummary(
        meeting_id=new_m.id,
        executive_summary=ai_data["executive_summary"],
        key_points_json=json.dumps(ai_data["key_points"]),
        decisions_json=json.dumps(ai_data["decisions"]),
        action_items_json=json.dumps(ai_data["action_items"]),
        risks_json=json.dumps(ai_data["risks"])
    )
    db.add(summary_record)
    db.commit()
    db.refresh(summary_record)

    return MeetingResponse(
        id=new_m.id,
        title=new_m.title,
        category=new_m.category,
        tint=new_m.tint,
        source_type=new_m.source_type,
        duration_seconds=new_m.duration_seconds,
        created_at=new_m.created_at,
        summary=summary_record.executive_summary,
        action_items=ai_data["action_items"]
    )

# ----------------- Tasks Endpoints -----------------
@app.get(f"{settings.API_V1_STR}/tasks", response_model=List[TaskResponse])
def get_tasks(db: Session = Depends(get_db)):
    return db.query(Task).order_by(Task.created_at.desc()).all()

@app.post(f"{settings.API_V1_STR}/tasks", response_model=TaskResponse)
def create_task(task_in: TaskCreate, db: Session = Depends(get_db)):
    user = db.query(User).first()
    new_t = Task(
        user_id=user.id if user else 1,
        meeting_id=task_in.meeting_id,
        title=task_in.title,
        assignee=task_in.assignee,
        deadline=task_in.deadline,
        priority=task_in.priority
    )
    db.add(new_t)
    db.commit()
    db.refresh(new_t)
    return new_t

# ----------------- Ask Your Meetings (RAG Chat) -----------------
@app.post(f"{settings.API_V1_STR}/chat/ask", response_model=ChatResponse)
def ask_meetings(query: ChatQuery, db: Session = Depends(get_db)):
    meetings = db.query(Meeting).all()
    meeting_dicts = []
    for m in meetings:
        meeting_dicts.append({
            "id": m.id,
            "title": m.title,
            "summary": m.summary.executive_summary if m.summary else m.title
        })
    answer = AIService.answer_meeting_question(query.question, meeting_dicts)
    return ChatResponse(
        role="assistant",
        content=answer["content"],
        citations=answer["citations"]
    )

@app.get("/")
def root():
    return {
        "app": settings.PROJECT_NAME,
        "version": "1.0.0",
        "docs_url": f"{settings.API_V1_STR}/docs"
    }
