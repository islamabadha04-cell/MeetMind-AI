const fs = require('fs');
let code = fs.readFileSync('backend/app/main.py', 'utf8');

const oldSeedRegex = /# Seed default demo user, meetings, documents, and memories if empty[\s\S]*?finally:/;

const newSeed = `# Seed default demo user, meetings, documents, and memories if empty
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
    finally:`;

code = code.replace(oldSeedRegex, newSeed);
fs.writeFileSync('backend/app/main.py', code, 'utf8');
console.log('Successfully updated startup_db_seed in backend/app/main.py');

