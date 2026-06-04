# Nhật ký AI Prompt — Day 4

Tệp này ghi lại các prompt AI cho Day 4, khi triển khai observability và anomaly detection cho InsightHub.

## Prompt 1 — Tạo ServiceMonitor cho Prometheus
**Mục tiêu:** Cho Prometheus scrape endpoint `/metrics` của InsightHub API trên cluster.

**Prompt:**
"Tạo ServiceMonitor manifest trong thư mục `observability/` để kube-prometheus-stack scrape service API của InsightHub trong namespace `insighthub` trên port `http` và path `/metrics` mỗi 30s."

**Kết quả:**
- Tạo `observability/servicemonitor.yaml`
- Chứa selector match label `app: insighthub`
- Chạy trong namespace `insighthub`
- Scrape endpoint `/metrics` interval 30s

## Prompt 2 — Tạo rules anomaly detection với Prometheus
**Mục tiêu:** Thiết lập recording rules và alert rule để phát hiện spike latency dựa trên band anomaly.

**Prompt:**
"Tạo PrometheusRule YAML trong `observability/` để tính
- `insighthub_llm_call_latency_seconds_baseline`
- `insighthub_llm_call_latency_seconds_stddev`
- `insighthub_llm_call_latency_seconds_upper_band`
- `insighthub_llm_call_latency_seconds_lower_band`

Sau đó tạo alert `InsightHubLLMLatencyAnomaly` khi metric `insighthub_llm_call_latency_seconds` vượt `upper_band` trong 5 phút."

**Kết quả:**
- Tạo `observability/anomaly-rules.yaml`
- Bao gồm recording rules và alert rule
- Hỗ trợ detection cho LLM latency anomalies

## Prompt 3 — Tạo Grafana dashboard observable
**Mục tiêu:** Sinh dashboard JSON cho InsightHub với các panel RED.

**Prompt:**
"Tạo Grafana dashboard JSON trong `observability/grafana-dashboards/` cho InsightHub. Dashboard cần ít nhất 9 panels, bao gồm:
- RAG query latency p95/p99
- LLM call latency p95
- LLM latency upper band
- Ingestion queue depth
- Documents pending/ready
- Ingestion error rate
- Token usage output"

**Kết quả:**
- Tạo `observability/grafana-dashboards/insighthub-dashboard.json`
- Dashboard có 9 panels

## Prompt 4 — Viết RCA reports cho incidents
**Mục tiêu:** Tạo 3 báo cáo RCA cho incident injection.

**Prompt:**
"Viết 3 báo cáo RCA JSON cho InsightHub, mỗi báo cáo có:
- summary
- top_hypotheses
- evidence
- recommendation

Các incident: LLM latency spike, ingestion queue backlog, database error."

**Kết quả:**
- Tạo `rca-reports/incident-latency-spike.json`
- Tạo `rca-reports/incident-queue-backlog.json`
- Tạo `rca-reports/incident-db-error.json`

## Prompt 5 — Ghi notes MLOps overview
**Mục tiêu:** Tạo ghi chú MLOps ngắn gọn cho Day 4.

**Prompt:**
"Tạo một file markdown `mlops-overview-notes.md` với các block concept: Mindset, Lifecycle, Registry, Approval, Drift, Rollback, Ownership."

**Kết quả:**
- Tạo `mlops-overview-notes.md`
- File chứa 7 block concept MLOps cơ bản

## Ghi chú
- Tệp này phục vụ làm nhật ký prompt cho Day 4.
- Các prompt ghi lại mục tiêu và kết quả để dễ duy trì và review.
