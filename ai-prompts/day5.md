# Day 5 ChatOps Bot

- Đã triển khai xác thực chữ ký Slack với `SLACK_SIGNING_SECRET`.
- Thêm xử lý callback Slack cho `url_verification` và `event_callback`.
- Xây dựng workflow ChatOps chỉ đọc:
  - truy vấn metric InsightHub từ `INSIGHTHUB_METRICS_URL`
  - phát hiện pod không khỏe thông qua `kubectl get pods --all-namespaces -o json`
  - ghi nhật ký mọi lần gọi công cụ vào `chatops-bot/chatops-audit.log`
- Thêm phân tầng quyền trong `chatops-bot/app/permissions.py`.
- Thêm bản ghi khởi tạo `chatops-bot/chatops-audit.log` và placeholder `LOOM-URL.txt` để xác minh.
- Cập nhật `chatops-bot/README.md` với hướng dẫn chạy.
