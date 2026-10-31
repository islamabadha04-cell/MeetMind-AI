from fastapi import FastAPI, Depends, HTTPException, status, File, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any
from datetime import datetime
import json

from app.core.config import settings
from app.db.session import engine, Base, get_db
from app.models.models import (
    User, Meeting, MeetingSummary, Task, ChatMessage,
    KnowledgeDocument, DocumentChunk, MeetingMemory, MeetingChunk
)
from app.schemas.schemas import (
    UserRegister, UserLogin, Token, UserProfile,
    MeetingCreate, MeetingResponse, TaskCreate, TaskResponse,
    ChatQuery, ChatResponse,
    SemanticSearchQuery, SemanticSearchResponse,
    MeetingComparisonRequest, MeetingComparisonResponse,
    KnowledgeDocResponse, MemoryItemCreate, MemoryItemResponse
)
from app.core.security import get_password_hash, verify_password, create_access_token
from app.services.ai_service import AIService
from app.services.document_service import DocumentService
from app.services.search_service import SearchService
from app.services.memory_service import MemoryService

# Initialize DB tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.PROJECT_NAME,
    version="2.0.0",
    description="Next-Generation AI Meeting Assistant & Cross-Meeting Intelligence Platform (Phase 2)",
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

# Seed default demo user, meetings, documents, and memories if empty
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

        # Check Meeting 1
        m1 = db.query(Meeting).filter(Meeting.title.like("%Cowlar Sprint%")).first()
        if not m1:
            m1 = Meeting(
                user_id=user.id,
                title="Cowlar Sprint Architecture Review",
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
                decisions_json=json.dumps(["Approved soft pastel design language", "Selected Gemini 2.5 Flash model"]),
                action_items_json=json.dumps(["Finalize schema definitions", "Review mobile audio waveforms"]),
                risks_json=json.dumps(["Cellular latency spikes during high traffic"])
            )
            db.add(sum1)
            db.commit()

        # Check Meeting 2
        m2 = db.query(Meeting).filter(Meeting.title.like("%Pakistan Gateway%")).first()
        if not m2:
            m2 = Meeting(
                user_id=user.id,
                title="Client Commercials Pakistan Gateway Sync",
                category="General",
                tint="peach",
                source_type="audio_recording",
                duration_seconds=1260
            )
            db.add(m2)
            db.commit()
            db.refresh(m2)

            sum2 = MeetingSummary(
                meeting_id=m2.id,
                executive_summary="Finalized payment gateway checkout for Pakistani users with JazzCash, Easypaisa, and Raast instant settlement.",
                key_points_json=json.dumps(["Enabled 1-click clipboard copy", "Zero gateway surcharge on Raast"]),
                decisions_json=json.dumps(["Approved JazzCash and Easypaisa direct transfer", "Confirmed instant Pro tier activation"]),
                action_items_json=json.dumps(["Deploy checkout modal to production", "Send confirmation email"]),
                risks_json=json.dumps(["Pending bank settlement webhook latency"])
            )
            db.add(sum2)
            db.commit()

        # Check Knowledge Documents
        if db.query(KnowledgeDocument).count() == 0:
            doc1 = KnowledgeDocument(
                user_id=user.id,
                title="MeetMind_Company_Policy_2026.pdf",
                file_type="pdf",
                file_size=42800,
                category="Company Policy",
                status="indexed",
                chunk_count=2,
                raw_text="MeetMind AI Company Policy 2026: Standard working hours are flexible with core hours from 11:00 AM to 4:00 PM PKT. Annual leave allowance is 20 days paid leave with 10 days sick/casual leave. All customer meeting recordings are strictly isolated by tenant."
            )
            db.add(doc1)
            db.commit()
            db.refresh(doc1)

            c1 = DocumentChunk(
                document_id=doc1.id,
                chunk_index=1,
                page_number=1,
                text="Standard working hours are flexible with core hours from 11:00 AM to 4:00 PM PKT. Annual leave allowance is 20 days paid leave with 10 days sick/casual leave."
            )
            c2 = DocumentChunk(
                document_id=doc1.id,
                chunk_index=2,
                page_number=2,
                text="All customer meeting recordings are strictly isolated by tenant. Deleting a meeting permanently purges all audio and transcript fragments."
            )
            db.add(c1)
            db.add(c2)
            db.commit()

        # Check Memories
        if db.query(MeetingMemory).count() == 0:
            mem1 = MeetingMemory(
                user_id=user.id,
                category="Important Decisions",
                fact_statement="Approved JazzCash, Easypaisa, and Raast instant payment channels with instant Pro tier activation.",
                meeting_id=m2.id if m2 else 1,
                meeting_title=m2.title if m2 else "Commercials Sync",
                timestamp="02:30",
                confidence="0.98"
            )
            mem2 = MeetingMemory(
                user_id=user.id,
                category="Financial Discussions",
                fact_statement="Pricing set at 3,900 PKR/month for Pro and 11,500 PKR/month for Enterprise with Raast 0% surcharge.",
                meeting_id=m2.id if m2 else 1,
                meeting_title=m2.title if m2 else "Commercials Sync",
                timestamp="03:15",
                confidence="0.96"
            )
            mem3 = MeetingMemory(
                user_id=user.id,
                category="Deadlines",
                fact_statement="Sprint delivery deadline locked for Friday 5:00 PM PKT.",
                meeting_id=m1.id if m1 else 1,
                meeting_title=m1.title if m1 else "Sprint Review",
                timestamp="04:20",
                confidence="0.92"
            )
            db.add(mem1)
            db.add(mem2)
            db.add(mem3)
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

    # Auto-extract and populate meeting memories
    extracted_memories = MemoryService.extract_memories_from_meeting(
        item.title,
        ai_data["executive_summary"],
        ai_data["decisions"],
        ai_data["action_items"]
    )
    for mem in extracted_memories:
        db.add(MeetingMemory(
            user_id=user.id if user else 1,
            category=mem["category"],
            fact_statement=mem["fact_statement"],
            meeting_id=new_m.id,
            meeting_title=new_m.title,
            timestamp=mem["timestamp"],
            confidence=mem["confidence"]
        ))

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

@app.post(f"{settings.API_V1_STR}/meetings/transcribe-audio")
async def transcribe_audio_file(
    file: UploadFile = File(...),
    title: Optional[str] = Form(None)
):
    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Empty audio file provided")
    
    file_name = file.filename or "uploaded_recording.wav"
    mime_type = file.content_type or "audio/wav"
    ai_result = AIService.transcribe_and_summarize_audio(contents, file_name, mime_type)
    
    return {
        "status": "success",
        "filename": file_name,
        "title": title or file_name.rsplit(".", 1)[0],
        "transcript": ai_result.get("transcript", ""),
        "executive_summary": ai_result.get("executive_summary", ""),
        "key_points": ai_result.get("key_points", []),
        "decisions": ai_result.get("decisions", []),
        "action_items": ai_result.get("action_items", []),
        "risks": ai_result.get("risks", [])
    }

# ----------------- PHASE 2: Multi-Meeting Semantic Search -----------------
@app.post(f"{settings.API_V1_STR}/search/meetings", response_model=SemanticSearchResponse)
def search_meetings(query: SemanticSearchQuery, db: Session = Depends(get_db)):
    meetings = db.query(Meeting).all()
    meeting_dicts = []
    for m in meetings:
        meeting_dicts.append({
            "id": m.id,
            "title": m.title,
            "category": m.category,
            "date": m.created_at.strftime("%b %d, %Y"),
            "summary": m.summary.executive_summary if m.summary else "",
            "decisions": json.loads(m.summary.decisions_json) if (m.summary and m.summary.decisions_json) else [],
            "action_items": json.loads(m.summary.action_items_json) if (m.summary and m.summary.action_items_json) else []
        })
    res = SearchService.hybrid_search_meetings(
        query=query.query,
        meetings=meeting_dicts,
        mode=query.mode or "hybrid",
        category_filter=query.category or "all",
        limit=query.limit or 10
    )
    return res

# ----------------- PHASE 2: Meeting Comparison Matrix -----------------
@app.post(f"{settings.API_V1_STR}/meetings/compare", response_model=MeetingComparisonResponse)
def compare_meetings_endpoint(req: MeetingComparisonRequest, db: Session = Depends(get_db)):
    mA = db.query(Meeting).filter(Meeting.id == req.meeting_a_id).first()
    mB = db.query(Meeting).filter(Meeting.id == req.meeting_b_id).first()
    if not mA or not mB:
        raise HTTPException(status_code=404, detail="One or both selected meetings not found")
    
    dict_a = {
        "id": mA.id,
        "title": mA.title,
        "date": mA.created_at.strftime("%b %d, %Y"),
        "summary": mA.summary.executive_summary if mA.summary else "",
        "decisions": json.loads(mA.summary.decisions_json) if (mA.summary and mA.summary.decisions_json) else [],
        "action_items": json.loads(mA.summary.action_items_json) if (mA.summary and mA.summary.action_items_json) else []
    }
    dict_b = {
        "id": mB.id,
        "title": mB.title,
        "date": mB.created_at.strftime("%b %d, %Y"),
        "summary": mB.summary.executive_summary if mB.summary else "",
        "decisions": json.loads(mB.summary.decisions_json) if (mB.summary and mB.summary.decisions_json) else [],
        "action_items": json.loads(mB.summary.action_items_json) if (mB.summary and mB.summary.action_items_json) else []
    }
    return AIService.compare_meetings(dict_a, dict_b)

# ----------------- PHASE 2: Company Knowledge Base -----------------
@app.get(f"{settings.API_V1_STR}/knowledge/documents", response_model=List[KnowledgeDocResponse])
def list_knowledge_documents(db: Session = Depends(get_db)):
    return db.query(KnowledgeDocument).order_by(KnowledgeDocument.created_at.desc()).all()

@app.post(f"{settings.API_V1_STR}/knowledge/upload")
async def upload_knowledge_document(
    file: UploadFile = File(...),
    category: Optional[str] = Form("General Policy"),
    db: Session = Depends(get_db)
):
    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Empty document uploaded")

    filename = file.filename or "uploaded_doc.txt"
    ext = filename.lower().rsplit(".", 1)[-1] if "." in filename else "txt"
    raw_text, chunks = DocumentService.extract_text_and_chunks(contents, filename)

    user = db.query(User).first()
    new_doc = KnowledgeDocument(
        user_id=user.id if user else 1,
        title=filename,
        file_type=ext,
        file_size=len(contents),
        category=category or "General Policy",
        status="indexed",
        chunk_count=len(chunks),
        raw_text=raw_text[:10000] # store excerpt
    )
    db.add(new_doc)
    db.commit()
    db.refresh(new_doc)

    for c in chunks:
        db.add(DocumentChunk(
            document_id=new_doc.id,
            chunk_index=c["chunk_index"],
            page_number=c["page_number"],
            text=c["text"]
        ))
    db.commit()

    return {
        "status": "success",
        "document_id": new_doc.id,
        "title": new_doc.title,
        "chunks_indexed": len(chunks)
    }

@app.delete(f"{settings.API_V1_STR}/knowledge/documents/{{doc_id}}")
def delete_knowledge_document(doc_id: int, db: Session = Depends(get_db)):
    doc = db.query(KnowledgeDocument).filter(KnowledgeDocument.id == doc_id).first()
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    db.delete(doc)
    db.commit()
    return {"status": "success", "message": f"Document {doc_id} and associated chunks deleted"}

# ----------------- PHASE 2: Meeting Memory Engine -----------------
@app.get(f"{settings.API_V1_STR}/memory", response_model=List[MemoryItemResponse])
def get_memories(db: Session = Depends(get_db)):
    mems = db.query(MeetingMemory).order_by(MeetingMemory.updated_at.desc()).all()
    res = []
    for m in mems:
        revisions = json.loads(m.revisions_json) if m.revisions_json else []
        res.append(MemoryItemResponse(
            id=m.id,
            category=m.category,
            fact_statement=m.fact_statement,
            meeting_id=m.meeting_id,
            meeting_title=m.meeting_title or "",
            timestamp=m.timestamp or "00:00",
            confidence=m.confidence or "0.95",
            revisions=revisions,
            created_at=m.created_at,
            updated_at=m.updated_at
        ))
    return res

@app.post(f"{settings.API_V1_STR}/memory", response_model=MemoryItemResponse)
def create_memory(item: MemoryItemCreate, db: Session = Depends(get_db)):
    user = db.query(User).first()
    new_mem = MeetingMemory(
        user_id=user.id if user else 1,
        category=item.category,
        fact_statement=item.fact_statement,
        meeting_id=item.meeting_id,
        meeting_title=item.meeting_title or "",
        timestamp=item.timestamp or "00:00",
        confidence="0.95"
    )
    db.add(new_mem)
    db.commit()
    db.refresh(new_mem)
    return MemoryItemResponse(
        id=new_mem.id,
        category=new_mem.category,
        fact_statement=new_mem.fact_statement,
        meeting_id=new_mem.meeting_id,
        meeting_title=new_mem.meeting_title,
        timestamp=new_mem.timestamp,
        confidence=new_mem.confidence,
        revisions=[],
        created_at=new_mem.created_at,
        updated_at=new_mem.updated_at
    )

@app.put(f"{settings.API_V1_STR}/memory/{{memory_id}}", response_model=MemoryItemResponse)
def update_memory(memory_id: int, item: MemoryItemCreate, db: Session = Depends(get_db)):
    mem = db.query(MeetingMemory).filter(MeetingMemory.id == memory_id).first()
    if not mem:
        raise HTTPException(status_code=404, detail="Memory entry not found")
    
    # Save previous version in revisions
    revs = json.loads(mem.revisions_json) if mem.revisions_json else []
    revs.append({
        "fact_statement": mem.fact_statement,
        "category": mem.category,
        "updated_at": mem.updated_at.isoformat()
    })
    mem.revisions_json = json.dumps(revs)
    mem.fact_statement = item.fact_statement
    mem.category = item.category
    mem.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(mem)
    return MemoryItemResponse(
        id=mem.id,
        category=mem.category,
        fact_statement=mem.fact_statement,
        meeting_id=mem.meeting_id,
        meeting_title=mem.meeting_title,
        timestamp=mem.timestamp,
        confidence=mem.confidence,
        revisions=revs,
        created_at=mem.created_at,
        updated_at=mem.updated_at
    )

@app.delete(f"{settings.API_V1_STR}/memory/{{memory_id}}")
def delete_memory(memory_id: int, db: Session = Depends(get_db)):
    mem = db.query(MeetingMemory).filter(MeetingMemory.id == memory_id).first()
    if not mem:
        raise HTTPException(status_code=404, detail="Memory entry not found")
    db.delete(mem)
    db.commit()
    return {"status": "success", "message": f"Memory {memory_id} deleted"}

# ----------------- PHASE 2: Universal Multi-Source RAG Chat -----------------
@app.post(f"{settings.API_V1_STR}/chat/ask", response_model=ChatResponse)
def ask_universal_chat(query: ChatQuery, db: Session = Depends(get_db)):
    meetings = db.query(Meeting).all()
    meeting_dicts = []
    for m in meetings:
        meeting_dicts.append({
            "id": m.id,
            "title": m.title,
            "summary": m.summary.executive_summary if m.summary else m.title
        })

    docs = db.query(KnowledgeDocument).all()
    doc_dicts = []
    for d in docs:
        doc_dicts.append({
            "id": d.id,
            "title": d.title,
            "raw_text": d.raw_text or ""
        })

    answer = AIService.universal_rag_chat(
        query=query.question,
        scope=query.scope or "all",
        meetings=meeting_dicts,
        documents=doc_dicts,
        language=query.language or "en"
    )
    return ChatResponse(
        role="assistant",
        content=answer["content"],
        citations=answer["citations"],
        scope_used=answer.get("scope_used", "all")
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

@app.get("/")
def root():
    return {
        "app": settings.PROJECT_NAME,
        "version": "2.0.0",
        "docs_url": f"{settings.API_V1_STR}/docs"
    }
