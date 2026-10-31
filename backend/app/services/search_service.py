import math
import re
import json
import hashlib
from typing import List, Dict, Any, Optional, Tuple
import urllib.request
import urllib.error
from app.core.config import settings

# Semantic Concept Dictionary for Intent & Synonym Expansion
SEMANTIC_SYNONYMS = {
    "payment": ["invoice", "dues", "budget", "billing", "settlement", "jazzcash", "easypaisa", "raast", "fee", "cost", "pkr", "dollars"],
    "delay": ["late", "behind schedule", "postponed", "overdue", "pushed back", "blocker", "tight deadline", "pending"],
    "budget": ["cost", "expense", "funds", "pricing", "financial", "allocation", "dollars", "quote", "rate"],
    "complaint": ["issue", "problem", "dissatisfied", "feedback", "criticism", "error", "bug", "escalation"],
    "decision": ["approved", "agreed", "finalized", "resolved", "selected", "decided", "concluded"],
    "deadline": ["due date", "timeline", "schedule", "friday", "monday", "sprint", "milestone", "delivery"],
    "performance": ["kpi", "metrics", "productivity", "throughput", "velocity", "quality", "evaluation"]
}

# In-Memory LRU Embedding Cache to prevent duplicate API costs
EMBEDDING_CACHE: Dict[str, List[float]] = {}
MAX_CACHE_SIZE = 5000

class SearchService:
    @staticmethod
    def get_embedding(text: str) -> List[float]:
        """
        Generates dense vector embeddings with in-memory caching.
        Uses Google Gemini text-embedding-004 when GEMINI_API_KEY is configured.
        Falls back to normalized 64-dimensional feature projection vectorizer offline.
        """
        text_clean = text.strip()
        if not text_clean:
            return [0.0] * 64

        cache_key = hashlib.sha256(text_clean.encode("utf-8")).hexdigest()
        if cache_key in EMBEDDING_CACHE:
            return EMBEDDING_CACHE[cache_key]

        vector = None

        # 1. Attempt Google Gemini text-embedding-004 if API key configured
        if settings.GEMINI_API_KEY:
            try:
                url = f"https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key={settings.GEMINI_API_KEY}"
                payload = {
                    "model": "models/text-embedding-004",
                    "content": {"parts": [{"text": text_clean[:2000]}]}
                }
                req = urllib.request.Request(
                    url,
                    data=json.dumps(payload).encode("utf-8"),
                    headers={"Content-Type": "application/json"},
                    method="POST"
                )
                with urllib.request.urlopen(req, timeout=5.0) as resp:
                    data = json.loads(resp.read().decode("utf-8"))
                    if "embedding" in data and "values" in data["embedding"]:
                        vector = data["embedding"]["values"]
            except Exception:
                vector = None

        # 2. Deterministic 64-dimensional normalized feature vector projection fallback
        if not vector:
            dim = 64
            vec = [0.0] * dim
            tokens = re.findall(r'\b\w+\b', text_clean.lower())
            
            # Substring trigrams + word hash projection
            for token in tokens:
                h = int(hashlib.md5(token.encode('utf-8')).hexdigest(), 16)
                idx = h % dim
                vec[idx] += 1.0
                if len(token) >= 3:
                    for i in range(len(token) - 2):
                        tri = token[i:i+3]
                        tri_h = int(hashlib.md5(tri.encode('utf-8')).hexdigest(), 16)
                        vec[tri_h % dim] += 0.5
            
            # L2 Normalization
            norm = math.sqrt(sum(x * x for x in vec))
            if norm > 0:
                vector = [round(x / norm, 5) for x in vec]
            else:
                vector = [0.0] * dim

        if len(EMBEDDING_CACHE) < MAX_CACHE_SIZE:
            EMBEDDING_CACHE[cache_key] = vector

        return vector

    @staticmethod
    def cosine_similarity(v1: List[float], v2: List[float]) -> float:
        """
        Computes cosine similarity between two float vectors.
        """
        if not v1 or not v2 or len(v1) != len(v2):
            return 0.0
        dot_product = sum(a * b for a, b in zip(v1, v2))
        norm1 = math.sqrt(sum(a * a for a in v1))
        norm2 = math.sqrt(sum(b * b for b in v2))
        if norm1 == 0.0 or norm2 == 0.0:
            return 0.0
        return max(0.0, min(1.0, dot_product / (norm1 * norm2)))

    @staticmethod
    def hybrid_search_meetings(
        query: str,
        meetings: List[Dict[str, Any]],
        mode: str = "hybrid",
        category_filter: str = "all",
        limit: int = 10
    ) -> Dict[str, Any]:
        """
        Executes hybrid (keyword BM25 + dense vector cosine similarity) multi-meeting retrieval.
        Applies Reciprocal Rank Fusion (RRF with k=60) to merge lexical and vector search lists.
        """
        clean_query = query.lower().strip()
        query_tokens = set(re.findall(r'\b\w+\b', clean_query))

        # Expand query tokens with semantic synonyms
        expanded_concepts = set(query_tokens)
        for token in query_tokens:
            if token in SEMANTIC_SYNONYMS:
                expanded_concepts.update(SEMANTIC_SYNONYMS[token])

        # Generate query dense embedding
        query_vector = SearchService.get_embedding(clean_query)

        candidate_turns: List[Dict[str, Any]] = []

        for m in meetings:
            m_id = m.get("id", 1)
            m_title = m.get("title", "Meeting")
            m_date = m.get("date", "Recent")
            m_category = m.get("category", "Meetings")
            m_summary = m.get("summary", "")
            m_transcript = m.get("transcript", "")

            if category_filter != "all" and m_category.lower() != category_filter.lower():
                continue

            turns = []
            if m_transcript:
                sentences = [s.strip() for s in m_transcript.split(".") if len(s.strip()) > 5]
                for idx, sent in enumerate(sentences):
                    speaker = "Speaker 1 (Emily)" if idx % 2 == 0 else "Speaker 2 (Client)"
                    time_sec = idx * 15 + 10
                    mins = time_sec // 60
                    secs = time_sec % 60
                    turns.append({
                        "speaker": speaker,
                        "time": f"{mins:02d}:{secs:02d}",
                        "text": sent + "."
                    })
            else:
                turns.append({
                    "speaker": "AI Synthesizer",
                    "time": "00:00",
                    "text": m_summary
                })

            for turn in turns:
                turn_text = turn["text"]
                turn_tokens = set(re.findall(r'\b\w+\b', turn_text.lower()))

                # 1. Lexical BM25 approximation
                kw_overlap = len(query_tokens.intersection(turn_tokens))
                kw_score = kw_overlap / max(1, len(query_tokens))

                concept_overlap = len(expanded_concepts.intersection(turn_tokens))
                concept_score = concept_overlap / max(1, len(expanded_concepts))
                lexical_score = (0.6 * kw_score) + (0.4 * concept_score)

                # 2. Dense Vector Cosine Similarity
                turn_vector = SearchService.get_embedding(turn_text)
                vector_sim = SearchService.cosine_similarity(query_vector, turn_vector)

                # Title relevance bonus
                title_bonus = 0.15 if any(t in m_title.lower() for t in query_tokens) else 0.0

                candidate_turns.append({
                    "meeting_id": m_id,
                    "meeting_title": m_title,
                    "date_str": m_date,
                    "speaker": turn["speaker"],
                    "timestamp": turn["time"],
                    "excerpt": turn_text,
                    "lexical_score": lexical_score + title_bonus,
                    "vector_sim": vector_sim + title_bonus,
                    "kw_matches": kw_overlap
                })

        if not candidate_turns:
            return {
                "query": query,
                "total_matches": 0,
                "ai_synthesis": f"No direct or semantic references matching '{query}' were found.",
                "results": []
            }

        # 3. Reciprocal Rank Fusion (RRF) with k = 60
        k = 60
        # Sort by lexical score
        sorted_by_lex = sorted(candidate_turns, key=lambda x: x["lexical_score"], reverse=True)
        # Sort by vector similarity
        sorted_by_vec = sorted(candidate_turns, key=lambda x: x["vector_sim"], reverse=True)

        lex_rank_map = {id(item): r + 1 for r, item in enumerate(sorted_by_lex)}
        vec_rank_map = {id(item): r + 1 for r, item in enumerate(sorted_by_vec)}

        hits = []
        for item in candidate_turns:
            item_id = id(item)
            r_lex = lex_rank_map[item_id]
            r_vec = vec_rank_map[item_id]

            if mode == "keyword":
                final_score = item["lexical_score"]
                match_type = "keyword"
            elif mode == "semantic":
                final_score = item["vector_sim"]
                match_type = "semantic"
            else: # hybrid RRF
                rrf_score = (1.0 / (k + r_lex)) + (1.0 / (k + r_vec))
                final_score = rrf_score * 30.0 # scale to ~0.0 - 1.0 range
                match_type = "hybrid"

            # Threshold check
            if final_score > 0.15 or item["kw_matches"] > 0 or item["vector_sim"] > 0.40:
                hits.append({
                    "meeting_id": item["meeting_id"],
                    "meeting_title": item["meeting_title"],
                    "date_str": item["date_str"],
                    "speaker": item["speaker"],
                    "timestamp": item["timestamp"],
                    "excerpt": item["excerpt"],
                    "relevance_score": min(0.99, round(final_score, 2)),
                    "match_type": match_type
                })

        # Sort by final score descending
        hits.sort(key=lambda x: x["relevance_score"], reverse=True)
        top_hits = hits[:limit]

        # Contextual AI Synthesis
        if top_hits:
            lead = top_hits[0]
            ai_synthesis = (
                f"Found {len(hits)} relevant meeting excerpts matching '{query}'. "
                f"Primary discussion was identified in '{lead['meeting_title']}' at timestamp {lead['timestamp']} "
                f"by {lead['speaker']}: \"{lead['excerpt']}\""
            )
        else:
            ai_synthesis = (
                f"No direct or semantic references matching '{query}' were found across historical meetings. "
                f"Try searching broader terms like 'budget', 'timeline', 'deliverables', or check your filters."
            )

        return {
            "query": query,
            "total_matches": len(hits),
            "ai_synthesis": ai_synthesis,
            "results": top_hits
        }
