import io
import csv
from typing import List, Dict, Any, Tuple
import pypdf
import docx

class DocumentService:
    @staticmethod
    def extract_text_and_chunks(file_bytes: bytes, filename: str, mime_type: str = "") -> Tuple[str, List[Dict[str, Any]]]:
        """
        Extracts raw text and structured sliding-window chunks from supported files:
        - PDF (via pypdf)
        - DOCX (via python-docx)
        - TXT / Markdown (UTF-8 decoded)
        - CSV (tabular row summary)
        """
        ext = filename.lower().rsplit(".", 1)[-1] if "." in filename else "txt"
        raw_text = ""
        chunks: List[Dict[str, Any]] = []

        if ext == "pdf":
            try:
                reader = pypdf.PdfReader(io.BytesIO(file_bytes))
                for page_idx, page in enumerate(reader.pages):
                    page_text = page.extract_text() or ""
                    raw_text += f"\n--- Page {page_idx + 1} ---\n" + page_text
                    
                    # Split page text into manageable chunks
                    page_chunks = DocumentService._chunk_text(page_text, max_words=250, overlap=40)
                    for c_idx, c_text in enumerate(page_chunks):
                        chunks.append({
                            "chunk_index": len(chunks) + 1,
                            "page_number": page_idx + 1,
                            "text": c_text
                        })
            except Exception as e:
                raw_text = f"Error reading PDF {filename}: {str(e)}"

        elif ext in ("docx", "doc"):
            try:
                doc = docx.Document(io.BytesIO(file_bytes))
                full_paragraphs = [p.text for p in doc.paragraphs if p.text.strip()]
                raw_text = "\n\n".join(full_paragraphs)
                
                doc_chunks = DocumentService._chunk_text(raw_text, max_words=250, overlap=40)
                for c_idx, c_text in enumerate(doc_chunks):
                    chunks.append({
                        "chunk_index": c_idx + 1,
                        "page_number": 1,
                        "text": c_text
                    })
            except Exception as e:
                raw_text = f"Error reading DOCX {filename}: {str(e)}"

        elif ext == "csv":
            try:
                text_stream = io.StringIO(file_bytes.decode("utf-8", errors="replace"))
                csv_reader = csv.reader(text_stream)
                rows = list(csv_reader)
                if rows:
                    headers = rows[0]
                    lines = [", ".join(headers)]
                    for r_idx, row in enumerate(rows[1:100]): # Cap at first 100 rows for preview
                        lines.append(f"Row {r_idx + 1}: " + ", ".join([f"{headers[i] if i < len(headers) else 'Col'}: {val}" for i, val in enumerate(row)]))
                    raw_text = "\n".join(lines)
                    
                    doc_chunks = DocumentService._chunk_text(raw_text, max_words=250, overlap=30)
                    for c_idx, c_text in enumerate(doc_chunks):
                        chunks.append({
                            "chunk_index": c_idx + 1,
                            "page_number": 1,
                            "text": c_text
                        })
            except Exception as e:
                raw_text = f"Error parsing CSV {filename}: {str(e)}"

        else: # TXT, MD, JSON, etc.
            try:
                raw_text = file_bytes.decode("utf-8", errors="replace")
                doc_chunks = DocumentService._chunk_text(raw_text, max_words=250, overlap=40)
                for c_idx, c_text in enumerate(doc_chunks):
                    chunks.append({
                        "chunk_index": c_idx + 1,
                        "page_number": 1,
                        "text": c_text
                    })
            except Exception as e:
                raw_text = f"Error reading text {filename}: {str(e)}"

        if not chunks and raw_text.strip():
            chunks.append({
                "chunk_index": 1,
                "page_number": 1,
                "text": raw_text[:1200]
            })

        return raw_text, chunks

    @staticmethod
    def _chunk_text(text: str, max_words: int = 250, overlap: int = 40) -> List[str]:
        words = text.split()
        if not words:
            return []
        if len(words) <= max_words:
            return [" ".join(words)]
        
        chunks = []
        i = 0
        while i < len(words):
            chunk = words[i:i + max_words]
            chunks.append(" ".join(chunk))
            i += (max_words - overlap)
        return chunks

