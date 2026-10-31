# MEETMIND AI — Vector Search & Embedding Engine Setup Guide

**Version:** 2.0.0 (Phase 2)  
**Status:** In Production  
**Live Application:** [https://meetmind-ai-74519.web.app](https://meetmind-ai-74519.web.app)

---

## 1. Architecture & Provider Abstraction

MeetMind AI uses an **embedding provider abstraction layer** (`backend/app/services/search_service.py`) that decouples vector indexing from proprietary model vendors. This allows development and production environments to switch dynamically between Google Gemini, OpenAI, or local open-source embeddings with zero changes to application logic.

```
                      Text Chunk / Query
                              │
                              ▼
                 Embedding Abstraction Layer
                 (search_service.get_embedding)
                              │
         ┌────────────────────┼────────────────────┐
         ▼                    ▼                    ▼
   Google Cloud           OpenAI API           Local / Self-Hosted
text-embedding-004   text-embedding-3-small     all-MiniLM-L6-v2
 (768 dimensions)      (1536 dimensions)        (384 dimensions)
         │                    │                    │
         └────────────────────┼────────────────────┘
                              ▼
                      Vector Storage Layer
         ┌────────────────────┼────────────────────┐
         ▼                    ▼                    ▼
 PostgreSQL + pgvector     Firestore +       ChromaDB / Qdrant
  (Unified Relational)   Vertex Vector Search  (Specialized Store)
```

---

## 2. Supported Embedding Providers

| Provider | Model Name | Dimensions | Free Tier / Cost | Use Case |
|---|---|---|---|---|
| **Google Cloud (Default)** | `text-embedding-004` | 768 | Generous Free Quota in Google AI Studio | **Production Recommended** (native GCP integration, bilingual Urdu/English accuracy) |
| **OpenAI** | `text-embedding-3-small` | 1536 | $0.02 / 1M tokens | Alternative commercial cloud provider |
| **Local HuggingFace** | `all-MiniLM-L6-v2` | 384 | 100% Free / Local CPU | Offline, air-gapped, or zero-cost local testing |

---

## 3. Vector Database Integration Options

### Option A: PostgreSQL with `pgvector` (Recommended for High Concurrency)
For deployments using managed Cloud SQL or PostgreSQL:

1. Enable the extension:
   ```sql
   CREATE EXTENSION IF NOT EXISTS vector;
   ```
2. Define vector column on `meeting_chunks` and `document_chunks`:
   ```sql
   ALTER TABLE meeting_chunks ADD COLUMN embedding vector(768);
   ALTER TABLE document_chunks ADD COLUMN embedding vector(768);
   ```
3. Create HNSW or IVFFlat index for sub-millisecond retrieval:
   ```sql
   CREATE INDEX idx_meeting_chunks_vector ON meeting_chunks 
   USING hnsw (embedding vector_cosine_ops) 
   WITH (m = 16, ef_construction = 64);
   ```
4. Querying by Cosine Distance:
   ```sql
   SELECT chunk_text, speaker, timestamp_label,
          1 - (embedding <=> :query_vector) AS cosine_similarity
   FROM meeting_chunks
   WHERE meeting_id = :meeting_id
   ORDER BY embedding <=> :query_vector ASC
   LIMIT 5;
   ```

### Option B: Firebase Firestore Vector Search
For serverless Firebase deployments:

1. Install the **Vector Search with Firebase Extension** or use Google Cloud Vertex AI Vector Search.
2. In Firestore documents:
   ```json
   {
     "meetingId": "m-102",
     "chunkText": "Milestone 2 payment delayed pending UAT signoff",
     "embedding": [0.0142, -0.0531, 0.0891, ...],
     "speaker": "Client (Tariq Khan)",
     "timestamp": "04:15"
   }
   ```
3. Execute Vector Query via Firebase SDK:
   ```javascript
   import { getFirestore, findNeighbors } from 'firebase/firestore';
   
   const vectorQuery = coll.findNeighbors({
     vectorField: 'embedding',
     queryVector: queryEmbedding,
     limit: 5,
     distanceMeasure: 'COSINE'
   });
   ```

### Option C: Lightweight Hybrid Engine (Built-in Development & Testing)
MeetMind AI includes an embedded in-memory cosine and lexical fusion engine for fast unit testing and zero-cost guest sandbox environments:
- Cosine similarity computed directly:
  $$\text{Sim}(\mathbf{A}, \mathbf{B}) = \frac{\sum_{i=1}^n A_i B_i}{\sqrt{\sum_{i=1}^n A_i^2} \sqrt{\sum_{i=1}^n B_i^2}}$$
- Combined with BM25 token frequencies via Reciprocal Rank Fusion ($k=60$).

---

## 4. Environment Configuration

To configure vector search credentials in `backend/.env`:

```env
# Vector Search Configuration
VECTOR_SEARCH_PROVIDER=gemini        # 'gemini', 'openai', or 'local'
GEMINI_API_KEY=your_gemini_api_key_here
OPENAI_API_KEY=optional_openai_key

# Vector Database Configuration
VECTOR_DB_TYPE=sqlite_embedded      # 'sqlite_embedded', 'pgvector', or 'firestore'
PGVECTOR_URL=postgresql://user:pass@localhost:5432/meetmind
EMBEDDING_DIMENSION=768
SIMILARITY_THRESHOLD=0.65
```

---

## 5. Chunking & Indexing Tuning Parameters

| Parameter | Recommended Value | Reason |
|---|---|---|
| **Chunk Size** | 250 words (~320 tokens) | Sufficient context for complete conversational points without diluting semantic density. |
| **Chunk Overlap** | 40 words | Guarantees that statements split across boundaries retain full contextual coherence. |
| **Top-K Retrieval** | 5 chunks | Balances maximum information density with LLM context window limits and low latency. |
| **Min Similarity Threshold** | 0.65 (Cosine) | Prevents irrelevant chunks from contaminating LLM synthesis, enabling anti-hallucination guardrails. |

