# GEMINI.md — BỘ NHỚ DỰ ÁN

> InsightHub — RAG Notebook. File này là "bộ nhớ dự án" cho AI agent, giúp AI làm việc chính xác hơn.

## 1. Dự án

InsightHub là một web app RAG Notebook cho phép người dùng upload tài liệu và hỏi đáp dựa trên nội dung tài liệu. Dự án này sẽ được DevOps-hóa thành một deployment production-grade xuyên suốt 7 ngày.

LLM và Embedding Provider: Google Gemini (mặc định cho lab).

## 2. Kiến trúc

### v0 (trước Day 1)
- 3 services: `web` (Next.js) -> `api` (FastAPI, ingestion sync) -> `postgres` (+pgvector).
- Vấn đề: Upload file lớn gây block API, không scale worker độc lập, thiếu queue.

### v1 (sau Day 1 refactor)
- 5 services, async với Redis queue: `web` -> `api` -> `enqueue` -> `redis` -> `ingestion-worker` -> `postgres` (+pgvector).
- `api` chỉ phục vụ chat và enqueue ingestion job.
- `ingestion-worker` xử lý chunking, embedding và lưu vào DB.

## 3. Quy ước code

- Python: Tuân theo PEP 8, dùng type hints.
- Commit message: conventional commits (feat:, fix:, refactor:...).
- Không hardcode secrets: Luôn dùng biến môi trường.

## 4. Lệnh thường dùng

```bash
cp .env.example .env             # Tạo file .env nếu chưa có
# Chỉnh sửa .env để thêm GEMINI_API_KEY
docker compose up --build        # Chạy toàn bộ stack
docker compose logs -f api       # Xem log của service api
bash scripts/smoke-test.sh       # Chạy smoke test
```

## 5. Lưu ý quan trọng cho AI agent

- `LLM_PROVIDER=gemini` và `EMBEDDING_PROVIDER=gemini` là bắt buộc.
- `GEMINI_API_KEY` phải được cung cấp trong `.env`.
- `EMBEDDING_DIM` phải khớp với `VECTOR(n)` trong `infra/db/init.sql` (mặc định 1024).
- `process_document()` trong worker phải idempotent (worker có thể retry).
- Không hardcode secrets.

## 6. Việc đang làm / TODO (Day 1)

- [x] Cấu hình `GEMINI_API_KEY` trong `.env`.
- [x] Chạy `docker compose up --build` và `smoke-test.sh` thành công.
- [ ] **REFACTOR**: Tách ingestion sync ra khỏi `api` thành `ingestion-worker/` + Redis queue.
- [ ] Tạo thư mục `ingestion-worker/` với `Dockerfile`, `worker.py`, `requirements.txt`.
- [ ] Cập nhật `docker-compose.yml` để có 5 service (thêm `redis` và `ingestion-worker`).
- [ ] Thêm 1 feature mới (ví dụ: hiển thị nguồn trích dẫn trong chat response).
- [ ] Lưu **AI prompt log** vào `ai-prompts/day1.md` (ít nhất 3 prompts có giải thích).
