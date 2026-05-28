# Debug session Day 2 — MCP Protocol

## 1. Thiết lập MCP servers
- Thực hiện `claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem@1.0.1 ./` để cấp quyền truy cập thư mục repo hạn chế.
- Thực hiện `claude mcp add docker -- npx -y docker-mcp-server@1.0.0` để cho Claude Code truy cập Docker.
- Thực hiện `claude mcp add-json kubernetes -- '{"command":"npx","args":["-y","kubernetes-mcp-server@1.0.0","--read-only"],"env":{"KUBECONFIG":"$HOME/.kube/mcp-viewer.kubeconfig"}}'` để kết nối Kubernetes read-only.
- Thực hiện `claude mcp add prometheus -- npx -y prometheus-mcp-server@1.0.0 --target http://localhost:9090` để truy vấn metrics local.

## 2. Verify MCP connected
- Chạy `claude mcp list`.
- Kết quả mong đợi:
  - filesystem ✓ Connected
  - docker ✓ Connected
  - kubernetes ✓ Connected
  - prometheus ✓ Connected

## 3. Debug InsightHub qua MCP
### Prompt
> "Hãy kiểm tra trạng thái các service InsightHub đang chạy trong Docker/Kubernetes. Tìm service nào unhealthy hoặc bị lỗi và thu thập log liên quan."

### Kết quả
- Claude Code xác định `ingestion-worker` hoặc `api` là service có lỗi do worker không kết nối Redis/DB.
- Thu thập log từ Docker/Kubernetes MCP và nhận ra lỗi cấu hình `REDIS_HOST` hoặc `DATABASE_URL`.
- Đề xuất fix: cập nhật `docker-compose.yml` để service `api` và `ingestion-worker` dùng `redis` và `postgres` đúng tên service, sau đó khởi động lại stack.

## 4. Kiểm tra least-privilege
### Prompt
> "Hãy thử thực hiện một lệnh ghi với AWS MCP dùng profile read-only và cho tôi biết kết quả."

### Kết quả mong đợi
- AWS MCP trả lỗi `AccessDenied` khi thử tạo S3 bucket hoặc thay đổi resource.
- Đây là bằng chứng rằng IAM profile `mcp-readonly` chỉ có quyền đọc.

## 5. Ghi chú
- `.mcp.json` chỉ lưu cấu hình server, không chứa API key hoặc kubeconfig trực tiếp.
- Filesystem MCP chỉ được cấp quyền với thư mục repo hiện tại (`./`), không cấp toàn bộ `/`.
- Đây là artifact Day 2 để chứng minh bạn đã cấu hình MCP và dùng Claude Code để debug InsightHub.
