import os
import logging
from arq.connections import RedisSettings
from dotenv import load_dotenv

# Import modules from the copied 'app' directory
from app.core.db import get_conn
from app.services.chunking import chunk_text
from app.services.embeddings import embed

# For PDF extraction
import io
from pypdf import PdfReader

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def extract_text(filename: str, content: bytes) -> str:
    """Trích text từ file. Hỗ trợ .txt, .1md, .pdf."""
    lower = filename.lower()
    if lower.endswith((".txt", ".md")):
        return content.decode("utf-8", errors="ignore")
    if lower.endswith(".pdf"):
        reader = PdfReader(io.BytesIO(content))
        return "\n".join(page.extract_text() or "" for page in reader.pages)
    raise ValueError(f"Định dạng không hỗ trợ: {filename}")


def _update_status(document_id: int, status: str, chunk_count: int = 0):
    with get_conn() as conn:
        conn.execute(
            "UPDATE documents SET status = %s, chunk_count = %s WHERE id = %s",
            (status, chunk_count, document_id),
        )


async def ingest_document_job(ctx, document_id: str, file_content: bytes, file_name: str) -> int:
    logger.info(f"Processing ingestion job for document_id: {document_id}, file_name: {file_name}")
    doc_id_int = int(document_id) # Convert to int for DB operations
    try:
        text = extract_text(file_name, file_content)
        chunks = chunk_text(text)
        if not chunks:
            logger.warning("Document %s không có nội dung", doc_id_int)
            _update_status(doc_id_int, "ready", chunk_count=0)
            return 0

        # Embed theo batch — embedding API là bottleneck chính
        vectors = embed(chunks, input_type="document")

        with get_conn() as conn:
            with conn.transaction():
                for chunk, vector in zip(chunks, vectors):
                    conn.execute(
                        """
                        INSERT INTO chunks (document_id, chunk_text, embedding)
                        VALUES (%s, %s, %s::vector)
                        """,
                        (doc_id_int, chunk, vector),
                    )
                conn.execute(
                    "UPDATE documents SET status = 'ready', chunk_count = %s WHERE id = %s",
                    (len(chunks), doc_id_int),
                )
        logger.info("Document %s: %d chunks ingested successfully", doc_id_int, len(chunks))
        return len(chunks)
    except Exception as e:
        logger.error(f"Error ingesting document {doc_id_int}: {e}", exc_info=True)
        _update_status(doc_id_int, "failed") # Cập nhật trạng thái failed nếu có lỗi
        raise # Re-raise to let ARQ handle retries


class WorkerSettings:
    functions = [ingest_document_job]
    redis_settings = RedisSettings(
        host=os.getenv('REDIS_HOST', 'redis'),
        port=int(os.getenv('REDIS_PORT', 6379)),
        password=os.getenv('REDIS_PASSWORD', 'insighthub'),
        database=int(os.getenv('REDIS_DB', 0))
    )
    max_jobs = 10
    max_tries = 3 # Example: retry a failed job 3 times
    job_timeout = 600 # 10 minutes timeout for ingestion jobs
    keep_result = 3600 # Keep job results for 1 hour


async def main():
    # This main function is typically not called directly when running with arq worker CLI
    # But useful for testing or custom setup
    logger.info("Ingestion Worker starting...")
    # No need to create pool here, ARQ worker CLI handles it


if __name__ == '__main__':
    logger.info("Running worker.py directly (for testing/development).")
    # In a production Docker setup, ARQ CLI will manage this
    # For now, this placeholder ensures the file is valid Python
    # To run ARQ worker, use: arq worker worker.WorkerSettings
