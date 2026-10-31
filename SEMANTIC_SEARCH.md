# MEETMIND AI — Multi-Meeting Semantic Search Architecture

**Version:** 2.0.0 (Phase 2)  
**Status:** In Production  
**Live Application:** [https://meetmind-ai-74519.web.app](https://meetmind-ai-74519.web.app)

---

## 1. Overview & Purpose

The **Multi-Meeting Semantic Search Engine** transforms MeetMind AI from an isolated per-meeting summarizer into an intelligent cross-meeting intelligence platform. Users can search across their entire historical meeting catalog using natural language queries such as:
- *"Find all meetings where payment delays were discussed"*
- *"Which meetings mentioned the project budget?"*
- *"Find every discussion about client complaints"*
- *"When was the delivery deadline changed?"*
- *"Find all meetings where the client rejected our proposal"*

The engine does not rely solely on exact keyword matches; it understands synonyms, related concepts, semantic context, and operational entities while ranking results by relevance and providing direct 1-click audio and transcript timeline seek.

---

## 2. Hybrid Retrieval Architecture

MeetMind AI uses a **hybrid retrieval model** that merges lexical BM25 token overlap with dense semantic embeddings and conceptual expansion.

```
                      User Natural Query
                              │
            ┌─────────────────┴─────────────────┐
            ▼                                   ▼
    Lexical / Keyword                   Dense / Semantic
     Token Extractor                     Synonym Expansion
  (TF-IDF / BM25 Weighting)           (Concept & Intent Matrix)
            │                                   │
            ▼                                   ▼
    Lexical Inverted Index              Vector Embedding Space
    (Transcript & Chunk DB)             (Gemini text-embedding-004)
            │                                   │
            └─────────────────┬─────────────────┘
                              ▼
                     Reciprocal Rank Fusion
                           (RRF)
                              │
                              ▼
                   Top-K Filtered Results
              (Date, Speaker, Project Filters)
                              │
                              ▼
                 AI Cross-Meeting Synthesis
              (Gemini Flash Multi-Hit Summary)
```

### 2.1 Lexical Search & BM25 Scoring
- Chunks are tokenized into lowercased n-grams with punctuation stripped.
- Term frequency ($TF$) and Inverse Document Frequency ($IDF$) score exact query term hits within meeting transcripts and chunk text.
- High weights are given to exact matches on speaker names, project codes, dates, and currency values.

### 2.2 Semantic & Conceptual Expansion
- The query is analyzed for semantic intent.
- Synonym rings and conceptual equivalents are expanded:
  - *"payment delays"* $\to$ `late payment`, `outstanding invoice`, `overdue`, `pending transfer`, `cash flow stall`, `reconciliation delay`.
  - *"budget"* $\to$ `cost`, `milestone fee`, `estimate`, `PKR`, `USD`, `allowance`, `runway`, `expense`.
  - *"deadline"* $\to$ `timeline`, `milestone`, `delivery date`, `sprint end`, `launch target`.
- Cosine similarity between chunk vector embeddings and query embedding is calculated:
  $$\text{Cosine Similarity} = \frac{\mathbf{u} \cdot \mathbf{v}}{\|\mathbf{u}\| \|\mathbf{v}\|}$$

### 2.3 Reciprocal Rank Fusion (RRF)
To combine dense semantic scores and lexical BM25 scores without calibration biases, results are merged using Reciprocal Rank Fusion:
$$RRF(d) = \sum_{m \in M} \frac{1}{k + r_m(d)}$$
where $k = 60$, and $r_m(d)$ is the rank of document $d$ in retrieval method $m$.

---

## 3. Chunking & Indexing Pipeline

1. **Transcript Segmentation:**
   - Raw meeting transcripts are segmented into temporal turns with start/end timestamps and assigned speaker labels.
   - Long turns are partitioned into overlapping windows: **250 words per chunk with a 40-word sliding window overlap** to maintain complete conversational context across chunk boundaries.
2. **Metadata Enrichment:**
   - Each chunk retains its parent `meeting_id`, `speaker`, `timestamp_seconds`, `timestamp_label` (e.g., `04:15`), and `meeting_date`.
3. **Storage Schema:**
   - Chunks are stored in the relational `meeting_chunks` table (SQLAlchemy) and cached locally in client storage for offline instant retrieval.

---

## 4. Search Filter Capabilities

The engine supports multi-faceted filtering:
- **Date Range:** Filter by start date and end date.
- **Meeting Scope:** Filter to specific project meetings or search all meetings.
- **Speaker Filter:** Filter specifically to turns spoken by a particular stakeholder (e.g., "Client", "Tariq", "Emily", "Hasnain").
- **Category / Tag:** Restrict results to Technical, Commercial, Executive, or All.

---

## 5. UI Result Presentation & Audio Timeline Seek

Each search result card displays:
1. **Meeting Header:** Title, formatted date, and match relevance badge (e.g., `96% Match`).
2. **Verbatim Excerpt:** Highlighted transcript passage showing exact spoken dialogue.
3. **Speaker Pill:** Speaker name (e.g., `Client (Tariq Khan)` or `Lead Architect`).
4. **Timestamp Badge:** Exact meeting time (e.g., `04:15`).
5. **Interactive Actions:**
   - **Open Meeting & Seek:** Instantly opens the Meeting Details modal, switches to the Diarized Transcript tab, scrolls smoothly to the target sentence, and seeks the interactive audio player to that exact second.
   - **View Full Transcript:** Opens the complete transcript view for context inspection.

---

## 6. AI Cross-Meeting Synthesis

When a search returns multiple relevant meetings, MeetMind AI's synthesis module generates an executive overview answering the user's intent across all returned meetings:
- Highlights the chronology of events (e.g., *"Payment delays were first flagged on Oct 12 during the Client Sync and escalated on Oct 28 due to milestone signoff stalls"*).
- Lists conflicting decisions or changing commitments between meetings.
- Strictly adheres to grounded facts without extrapolation.

