# MEETMIND AI — Company Knowledge Base & Universal RAG Implementation

**Version:** 2.0.0 (Phase 2)  
**Status:** In Production  
**Live Application:** [https://meetmind-ai-74519.web.app](https://meetmind-ai-74519.web.app)

---

## 1. Overview & Architecture

MeetMind AI's **Universal Retrieval-Augmented Generation (RAG)** platform allows organizations to upload company documents (contracts, PRDs, policies, financial proposals, specifications) and query both their unstructured documentation and historical meeting audio transcripts simultaneously.

```
┌─────────────────────────────────┐      ┌─────────────────────────────────┐
│       Company Documents         │      │       Meeting Transcripts       │
│    (PDF, DOCX, CSV, TXT)        │      │    (Diarized Audio Turns)       │
└────────────────┬────────────────┘      └────────────────┬────────────────┘
                 ▼                                        ▼
    Document Parsing Service                 Transcript Chunker Service
     (pypdf, python-docx, csv)               (250 words / 40-word overlap)
                 │                                        │
                 ▼                                        ▼
    Sliding-Window Chunker                   Temporal Turn Chunker
                 │                                        │
                 └──────────────────┬─────────────────────┘
                                    ▼
                         Vector & Lexical Store
                     (Embeddings + Metadata Tags)
                                    │
                                    ▼
                    Dual-Scope Filter & Retriever
               [Scope: Meetings | Docs | Universal]
                                    │
                                    ▼
                     Anti-Hallucination Guardrail
                    (Context Relevance Threshold)
                                    │
                                    ▼
                     Gemini 2.5 Flash Synthesis
                 (Strict Citations & Multilingual)
```

---

## 2. Document Processing Pipeline

The backend parsing engine is implemented in `backend/app/services/document_service.py` and supports four major document formats with zero client data leakage:

### 2.1 Supported Formats & Parsers
1. **PDF (`.pdf`):** Parsed using `pypdf.PdfReader`. Extracts text on a page-by-page basis while preserving page numbers for citation mapping.
2. **Word Documents (`.docx`):** Parsed using `docx.Document` (`python-docx`). Extracts paragraph text and table cell contents in reading order.
3. **Plain Text (`.txt`, `.md`):** Decoded via UTF-8 with automatic fallback handling.
4. **Structured CSV (`.csv`):** Parsed line-by-line with header row binding to format tabular rows into intelligible semantic statements.

### 2.2 Sliding Window Chunking Strategy
To avoid splitting sentences or losing relational context across document boundaries, text is divided using a sliding-window strategy:
- **Chunk Size:** 250 words
- **Chunk Overlap:** 40 words
- **Page & Location Preservation:** Each chunk retains `document_id`, `page_number`, `chunk_index`, and `source_filename`.

### 2.3 Document Lifecycle States
Every document in the Knowledge Base tracks its lifecycle status with real-time UI indicators:
- `Uploaded`: File received in memory or storage; queued for parsing.
- `Processing`: Text extraction and chunking actively underway.
- `Indexed`: All chunks embedded, indexed, and available for real-time RAG search.
- `Failed`: Error detected during parsing (with error details recorded in metadata).

---

## 3. Scope-Aware Universal Retrieval

The Ask AI interface allows users to target their retrieval scope via the **Multi-Source Scope Switcher**:
1. **My Meetings Scope (`meetings`):** Retrieves solely from the user's recorded audio transcripts and meeting notes.
2. **Company Knowledge Scope (`docs`):** Retrieves solely from indexed organizational documents in the Knowledge Base.
3. **Universal Scope (`universal`):** Retrieves across both meeting discussions and company documentation to identify alignments, discrepancies, or missing agreements.

---

## 4. Anti-Hallucination Guardrails

To prevent LLM confabulation, MeetMind AI enforces strict anti-hallucination protocols at both system prompt and prompt-construction levels:

### 4.1 Strict Grounding Directives
The system prompt explicitly commands the model:
> *"Ground every single statement strictly on the provided Context excerpts. If the information is not present in the context, do NOT invent, assume, or extrapolate dates, numbers, budgets, or decisions. You MUST reply: 'I could not find sufficient information in your connected meetings or company documents to answer this accurately.' Explain what is missing."*

### 4.2 Retrieval Relevance Threshold
If the hybrid retrieval pipeline returns zero chunks exceeding the similarity threshold (score $< 0.15$), the model refuses to guess and alerts the user immediately, prompting them to upload the relevant contract or record the relevant sync.

---

## 5. Clickable Verified Citations

Every statement generated by the Universal RAG system is verified by exact source references:
- **Meeting Excerpts:** Rendered as clickable pill tags: `[Meeting: "Client Milestone Sync" @ 04:15]`. Clicking this badge immediately opens the meeting details, navigates to the 04:15 mark, and syncs audio playback.
- **Document Excerpts:** Rendered as document citation badges: `[Doc: "Company_Master_Contract_2026.pdf", Page 3]`.

---

## 6. Multilingual RAG

The RAG engine natively responds in:
- **English:** Formal, technical, or executive business English.
- **Urdu Nastaliq (اردو):** Rendered in clean typography with right-to-left formatting.
- **Roman Urdu:** Colloquial Pakistani corporate style (e.g., *"Meeting me client ne payment delay ki waja se Milestone 2 hold karne ka kaha..."*).

