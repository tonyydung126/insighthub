# Nhật ký AI Prompt — Day 2

Tệp này ghi lại ít nhất ba lần tương tác prompt AI dùng trong Day 2 để cấu hình MCP và debug InsightHub.

## Prompt 1 — Cấu hình MCP server
**Mục tiêu:** Thiết lập tối thiểu 4 MCP server cho Claude Code: filesystem, docker, kubernetes, prometheus.

**Prompt:**
"Hướng dẫn tôi cấu hình `.mcp.json` để Claude Code có thể truy cập repository hiện tại, Docker, Kubernetes read-only qua kubeconfig, và Prometheus local. Giữ version server pin cụ thể, không dùng @latest hoặc @main."

**Kết quả:**
- Tạo `.mcp.json` với server `filesystem`, `docker`, `kubernetes`, `prometheus`.
- Pin version cho các gói MCP để tránh break giữa khóa.
- Sử dụng `KUBECONFIG` riêng cho Kubernetes read-only và hạn chế filesystem chỉ trong thư mục repo.

## Prompt 2 — Debug InsightHub qua MCP
**Mục tiêu:** Dùng Claude Code để phân tích lỗi InsightHub bằng các tool MCP đã cấu hình.

**Prompt:**
"Hãy kiểm tra trạng thái các service InsightHub đang chạy và xác định service nào unhealthy. Thu thập log từ Docker/Kubernetes MCP, tóm tắt nguyên nhân lỗi và đề xuất cách sửa."

**Kết quả:**
- Claude Code xác định vấn đề Service/Pod với InsightHub.
- Thu thập log từ Docker/Kubernetes và hiểu nguyên nhân gốc (ví dụ cấu hình kết nối Redis/DB sai hoặc worker không khởi động).
- Ghi nhận đâu là fix cần thiết cho `docker-compose.yml` hoặc config MCP.

## Prompt 3 — Kiểm tra least-privilege AWS MCP
**Mục tiêu:** Xác minh rằng AWS MCP profile chỉ có quyền read-only.

**Prompt:**
"Sử dụng AWS MCP profile read-only, thử thực hiện một hành động ghi (ví dụ tạo S3 bucket) và cho tôi biết kết quả. Nếu profile là read-only, lệnh phải bị từ chối."

**Kết quả:**
- AWS MCP trả lỗi `AccessDenied` cho hành động ghi.
- Xác nhận IAM profile `mcp-readonly` không cho phép ghi, chứng minh least-privilege hoạt động.

## Ghi chú
- Tệp này hỗ trợ artifact Day 2 về prompt log.
- Nội dung mô tả rõ mục tiêu, prompt, và outcome của từng bước cấu hình/kiểm tra MCP.
