# MLOps Overview for InsightHub

## Mindset
MLOps starts với mindset rằng model là một service, không phải chỉ là code. Điều này nghĩa là chúng ta phải monitor latency, data drift và version giống như service bình thường.

## Lifecycle
Một pipeline MLOps đầy đủ gồm: development, training, validation, deployment, monitoring, và rollback. Mỗi bước cần có checkpoint và audit trail.

## Registry
Model registry lưu lại version, metadata, và artifact. Nếu cần rollback, ta phải biết model nào đang production và model nào đã được test.

## Approval
Không deploy model tự động nếu không có review. Approval process cho MLOps giống như change control của infra: test, docs, và stakeholder sign-off.

## Drift
MLOps cần detect drift dữ liệu và drift hiệu suất. Khi metric drift xảy ra, cần cảnh báo ngay và bắt đầu root cause analysis.

## Rollback
Rollback strategy phải sẵn sàng khi model gây ra regression. Điều này bao gồm cả monitoring trigger và manual rollback path.

## Ownership
Mỗi model cần có owner rõ ràng. DevOps hỗ trợ vận hành, nhưng team ML phải chịu trách nhiệm chất lượng model.
