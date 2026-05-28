# Nhật ký AI Prompt — Day 1

Tệp này ghi lại ít nhất ba lần tương tác prompt AI được dùng trong quá trình refactor Day 1 của InsightHub.

## Prompt 1 — Tách worker ingestion
**Mục tiêu:** Refactor luồng ingest tài liệu khỏi API và chuyển sang worker chạy nền riêng.

**Prompt:**
"Tôi cần refactor InsightHub để API nhận upload nhanh và một ingestion worker xử lý tài liệu bất đồng bộ. Dùng Redis và ARQ, giữ API bằng FastAPI, và thêm service ingestion-worker trong docker-compose. Thêm endpoint polling trạng thái cho tài liệu upload."

**Kết quả:**
- Thêm `ingestion-worker/` với mã worker ARQ.
- Sửa `api/app/routers/documents.py` trả `202 Accepted` và enqueue job ingest.
- Thêm endpoint kiểm tra trạng thái tài liệu để hỗ trợ luồng async.

## Prompt 2 — Sửa Docker compose và build worker
**Mục tiêu:** Khắc phục lỗi build Docker và runtime sau khi thêm ingestion worker.

**Prompt:**
"Dockerfile của ingestion worker đang bị lỗi do build context sai và lệnh ARQ chưa đúng. Sửa Dockerfile và cấu hình docker-compose để image worker build và khởi động đúng với Redis."

**Kết quả:**
- Cập nhật `ingestion-worker/Dockerfile` sao chép file từ context đúng.
- Sửa lệnh khởi động worker ARQ.
- Xác nhận `docker compose up --build` khởi động được `api`, `web`, `redis`, `postgres`, và `ingestion-worker`.

## Prompt 3 — Xác nhận upload async trong smoke test
**Mục tiêu:** Cập nhật script smoke test để phù hợp với hành vi ingest async.

**Prompt:**
"Luồng upload Day 1 bây giờ trả 202 và xử lý tài liệu bất đồng bộ. Cập nhật script smoke test để poll trạng thái tài liệu cho đến khi nó sẵn sàng, thay vì mong đợi hoàn thành đồng bộ ngay lập tức."

**Kết quả:**
- Cập nhật `scripts/smoke-test.sh` chấp nhận `202 Accepted`.
- Thêm polling để xác minh tài liệu upload đạt trạng thái `ready`.
- Xác nhận smoke test hiện báo `6 PASS / 0 FAIL`.

## Ghi chú
- Tệp này được viết ngắn gọn và nêu rõ các quyết định prompt/response chính trong Day 1.
- Nó hỗ trợ yêu cầu artifact Day 1 về nhật ký prompt.
