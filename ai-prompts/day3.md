# Nhật ký AI Prompt — Day 3

Tệp này ghi lại ít nhất ba lần tương tác prompt AI dùng trong Day 3 để tạo Terraform module và pipeline.

## Prompt 1 — Sinh Terraform module cho InsightHub
**Mục tiêu:** Sinh Terraform module cho InsightHub với RDS PostgreSQL, Redis, và namespace Kubernetes trên cluster sẵn có.

**Prompt:**
"Tạo Terraform module trong thư mục `infra/` cho InsightHub. Yêu cầu:
- EKS namespace `insighthub` (cluster đã có sẵn, không tạo cluster mới)
- RDS PostgreSQL 16, không public, encryption at rest bật, single-AZ
- ElastiCache Redis, không public, encryption at rest + transit
- Dùng default VPC cho lab nếu cần, tránh hardcode secret
- Viết biến đầu vào, output, và cấu trúc module rõ ràng."

**Kết quả:**
- Tạo `infra/main.tf`, `infra/variables.tf`, `infra/outputs.tf`
- Dùng `aws_default_vpc` và `aws_default_subnet_ids` để làm việc với lab môi trường
- Sinh security group, subnet group, Postgres instance, Redis cluster, và Kubernetes namespace.

## Prompt 2 — Sinh GitHub Actions pipeline cho IaC
**Mục tiêu:** Tạo workflow CI/CD `.github/workflows/iac.yml` để chạy terraform fmt, tflint, checkov và terraform plan.

**Prompt:**
"Tạo GitHub Actions workflow cho IaC. Pipeline cần các stage: fmt, lint, scan, plan. Dùng `hashicorp/setup-terraform`, cài `tflint`, cài `checkov`, và chạy `terraform plan` trên thư mục `infra/`."

**Kết quả:**
- Tạo `.github/workflows/iac.yml` với 4 job: fmt, lint, scan, plan
- Pipeline định nghĩa rõ stage và dependency order
- Cấu hình `terraform init -backend=false` để chạy trên GitHub mà không cần backend

## Prompt 3 — Kiểm tra policy-as-code
**Mục tiêu:** Thêm bước kiểm tra an toàn IaC bằng Checkov.

**Prompt:**
"Kiểm tra Terraform module bằng Checkov và chắc chắn không có HIGH severity issue trong `infra/`. Viết workflow để cài `checkov` và chạy `checkov -d infra/`."

**Kết quả:**
- Workflow `scan` cài Python và Checkov
- Command `checkov -d infra/` có trong pipeline
- Artifact Day 3 có policy-as-code scan

## Ghi chú
- Tệp này hỗ trợ Day 3 prompt log.
- Prompt mô tả rõ mục tiêu, yêu cầu, và kết quả mỗi bước.
