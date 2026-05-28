"""
InsightHub API — Documents router
Upload tài liệu và xem trạng thái.

⚠️  Day 1 refactor: endpoint upload hiện gọi ingest ĐỒNG BỘ.
Sau refactor sẽ: lưu metadata → enqueue ARQ job → trả về 202 ngay.
"""
import logging
import os

from arq.connections import RedisSettings, create_pool
from fastapi import APIRouter, HTTPException, UploadFile

from app.core.db import get_conn
from app.core.metrics import documents_total, ingestion_errors_total
# from app.services.ingestion import ingest_document_sync # Xóa dòng này

logger = logging.getLogger("insighthub.routers.documents")
router = APIRouter(prefix="/documents", tags=["documents"])

ALLOWED_EXT = (".txt", ".md", ".pdf")
MAX_SIZE_MB = 10

# Khởi tạo Redis connection pool
# Lý tưởng là dùng FastAPI lifespan events để quản lý pool này một cách đúng đắn
# Nhưng để đơn giản cho ví dụ refactor này, chúng ta sẽ khởi tạo trực tiếp
async def get_redis_pool():
    redis_settings = RedisSettings(
        host=os.getenv('REDIS_HOST', 'redis'),
        port=int(os.getenv('REDIS_PORT', 6379)),
        password=os.getenv('REDIS_PASSWORD', 'insighthub'),
        database=int(os.getenv('REDIS_DB', 0))
    )
    return await create_pool(redis_settings)

redis_pool = None

@router.on_event("startup")
async def startup_event():
    global redis_pool
    redis_pool = await get_redis_pool()
    logger.info("Redis connection pool initialized for API.")

@router.on_event("shutdown")
async def shutdown_event():
    if redis_pool:
        await redis_pool.close()
        logger.info("Redis connection pool closed for API.")


@router.post("", status_code=202) # Thay đổi status_code thành 202
async def upload_document(file: UploadFile):
    if not file.filename or not file.filename.lower().endswith(ALLOWED_EXT):
        raise HTTPException(400, f"Chỉ chấp nhận: {', '.join(ALLOWED_EXT)}")

    content = await file.read()
    if len(content) > MAX_SIZE_MB * 1024 * 1024:
        raise HTTPException(413, f"File vượt quá {MAX_SIZE_MB}MB")

    # Lưu metadata, trạng thái 'pending'
    with get_conn() as conn:
        row = conn.execute(
            "INSERT INTO documents (filename, status) VALUES (%s, 'pending') RETURNING id",
            (file.filename,),
        ).fetchone()
        document_id = row[0]
    
    # Enqueue job vào Redis cho ingestion-worker xử lý bất đồng bộ
    try:
        if redis_pool is None:
            raise RuntimeError("Redis connection pool not initialized.")
        await redis_pool.enqueue_job('ingest_document_job', str(document_id), content, file.filename)
        logger.info(f"Enqueued ingestion job for document_id: {document_id}, file_name: {file.filename}")
    except Exception as exc:
        ingestion_errors_total.inc()
        # Cập nhật trạng thái tài liệu sang 'failed' nếu enqueue thất bại
        with get_conn() as conn:
            conn.execute("UPDATE documents SET status = 'failed' WHERE id = %s", (document_id,))
        raise HTTPException(500, f"Không thể enqueue ingestion job: {exc}") from exc

    return {
        "id": document_id,
        "filename": file.filename,
        "status": "pending", # Trả về trạng thái 'pending'
        "chunk_count": 0, # Không có chunk_count ngay lập tức
    }


@router.get("")
async def list_documents():
    with get_conn() as conn:
        rows = conn.execute(
            "SELECT id, filename, status, chunk_count, created_at "
            "FROM documents ORDER BY created_at DESC"
        ).fetchall()

    # Cập nhật gauge cho Prometheus
    counts: dict[str, int] = {}
    for r in rows:
        counts[r[2]] = counts.get(r[2], 0) + 1
    for status in ("pending", "ready", "failed"):
        documents_total.labels(status=status).set(counts.get(status, 0))

    return [
        {
            "id": r[0],
            "filename": r[1],
            "status": r[2],
            "chunk_count": r[3],
            "created_at": r[4].isoformat() if r[4] else None,
        }
        for r in rows
    ]


@router.get("/status/{document_id}")
async def get_document_status(document_id: int):
    with get_conn() as conn:
        row = conn.execute(
            "SELECT status, chunk_count FROM documents WHERE id = %s", (document_id,)
        ).fetchone()
    if row is None:
        raise HTTPException(404, "Không tìm thấy tài liệu")
    return {
        "id": document_id,
        "status": row[0],
        "chunk_count": row[1] if row[1] is not None else 0,
    }


@router.delete("/{document_id}", status_code=204)
async def delete_document(document_id: int):
    with get_conn() as conn:
        result = conn.execute(
            "DELETE FROM documents WHERE id = %s RETURNING id", (document_id,)
        ).fetchone()
    if result is None:
        raise HTTPException(404, "Không tìm thấy tài liệu")
