#!/usr/bin/env bash
# InsightHub — Smoke test cho v0
# Chạy SAU khi `docker compose up` đã chạy xong.
# Kiểm tra pipeline RAG end-to-end: health → upload → chat.

set -u

API="http://localhost:8000"
WEB="http://localhost:3000"
PASS=0
FAIL=0

green(){ printf "\033[32m%s\033[0m\n" "$1"; }
red(){ printf "\033[31m%s\033[0m\n" "$1"; }

echo "=== InsightHub v0 Smoke Test ==="
echo

# 1. API health
echo "[1] API liveness..."
if curl -sf "$API/healthz" >/dev/null; then
  green "    PASS — API sống"
  PASS=$((PASS+1))
else
  red "    FAIL — API không phản hồi $API/healthz"
  FAIL=$((FAIL+1))
fi

# 2. API readiness (DB)
echo "[2] API readiness (DB)..."
if curl -sf "$API/readyz" >/dev/null; then
  green "    PASS — DB sẵn sàng"
  PASS=$((PASS+1))
else
  red "    FAIL — DB chưa sẵn sàng"
  FAIL=$((FAIL+1))
fi

# 3. Web health
echo "[3] Web health..."
if curl -sf "$WEB/api/health" >/dev/null; then
  green "    PASS — Web sống"
  PASS=$((PASS+1))
else
  red "    FAIL — Web không phản hồi"
  FAIL=$((FAIL+1))
fi

# 4. Upload tài liệu mẫu
echo "[4] Upload tài liệu mẫu..."
HTTP_CODE=$(curl -s -o /tmp/upload.json -w "%{http_code}" -X POST "$API/documents" \
  -F "file=@sample-docs/so-tay-van-hanh.md" 2>/dev/null || echo "000")
UPLOAD=$(cat /tmp/upload.json 2>/dev/null || true)
if [ "$HTTP_CODE" = "202" ]; then
  DOC_ID=$(python3 -c "import sys,json; d=json.load(open('/tmp/upload.json')); print(d.get('id',''))" 2>/dev/null || true)
  STATUS=$(python3 -c "import sys,json; d=json.load(open('/tmp/upload.json')); print(d.get('status',''))" 2>/dev/null || true)
  if [ -n "$DOC_ID" ] && [ "$STATUS" = "pending" ]; then
    echo "    POST /documents → 202 Accepted, document id=$DOC_ID pending. Polling status..."
    for i in 1 2 3 4 5 6; do
      sleep 5
      STATUS=$(curl -sf "$API/documents/status/$DOC_ID" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status',''))" 2>/dev/null || true)
      if [ "$STATUS" = "ready" ]; then
        green "    PASS — Upload + ingest thành công (document ready)"
        PASS=$((PASS+1))
        break
      fi
      echo "    Waiting for ready... ($((i*5))s)"
    done
    if [ "$STATUS" != "ready" ]; then
      red "    FAIL — Document $DOC_ID không chuyển sang ready trong 30s. Response: $UPLOAD"
      FAIL=$((FAIL+1))
    fi
  else
    red "    FAIL — Upload không trả về document pending. Response: $UPLOAD"
    FAIL=$((FAIL+1))
  fi
elif [ "$HTTP_CODE" = "201" ]; then
  red "    FAIL — API vẫn trả 201 (sync upload), cần refactor async"
  FAIL=$((FAIL+1))
else
  red "    FAIL — Upload lỗi. HTTP $HTTP_CODE. Response: $UPLOAD"
  FAIL=$((FAIL+1))
fi

# 5. Chat query
echo "[5] Truy vấn RAG..."
CHAT=$(curl -sf -X POST "$API/chat" \
  -H "Content-Type: application/json" \
  -d '{"question":"InsightHub có mấy thành phần chính?"}' 2>/dev/null)
if echo "$CHAT" | grep -q '"answer"'; then
  green "    PASS — Chat trả về câu trả lời"
  PASS=$((PASS+1))
else
  red "    FAIL — Chat lỗi. Response: $CHAT"
  FAIL=$((FAIL+1))
fi

# 6. Metrics endpoint
echo "[6] Prometheus metrics..."
if curl -sf "$API/metrics" | grep -q "insighthub_"; then
  green "    PASS — /metrics expose số liệu"
  PASS=$((PASS+1))
else
  red "    FAIL — /metrics không có dữ liệu"
  FAIL=$((FAIL+1))
fi

echo
echo "=== Kết quả: $PASS PASS / $FAIL FAIL ==="
[ "$FAIL" -eq 0 ] && green "InsightHub v0 hoạt động đầy đủ." || red "Có lỗi — xem log: docker compose logs"
exit "$FAIL"
