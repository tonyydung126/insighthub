#!/usr/bin/env bash
# InsightHub — Verify Day 2 (MCP Protocol)
set -u

PASS=0; FAIL=0
green(){ printf "\033[32m%s\033[0m\n" "$1"; }
red(){ printf "\033[31m%s\033[0m\n" "$1"; }
ok(){ green "  [PASS] $1"; PASS=$((PASS+1)); }
ng(){ red "  [FAIL] $1"; FAIL=$((FAIL+1)); }

echo "=== InsightHub — Verify Day 2 (MCP) ==="

# .mcp.json valid + ≥4 servers
if [ -f .mcp.json ]; then
  if command -v jq >/dev/null 2>&1; then
    JSON_OK=$(jq empty .mcp.json >/dev/null 2>&1 && echo yes || true)
  else
    JSON_OK=$(python3 - <<'PY'
import json
try:
    json.load(open('.mcp.json'))
    print('yes')
except Exception:
    pass
PY
  )
  fi

  if [ "$JSON_OK" = "yes" ]; then
    ok ".mcp.json valid JSON"

    if command -v jq >/dev/null 2>&1; then
      COUNT=$(jq '.mcpServers | length' .mcp.json)
    else
      COUNT=$(python3 - <<'PY'
import json
data=json.load(open('.mcp.json'))
print(len(data.get('mcpServers', {})))
PY
    )
    fi

    if [ "$COUNT" -ge 4 ]; then
      ok ".mcp.json có $COUNT MCP server (≥4)"
    else
      ng ".mcp.json chỉ có $COUNT server (cần ≥4)"
    fi

    if command -v jq >/dev/null 2>&1; then
      if jq -r '.mcpServers[].args[]?' .mcp.json | grep -qE '@latest|@main' ; then
        ng "Có server dùng @latest hoặc @main (KHÔNG pin version)"
      else
        ok "Tất cả MCP server version pinned"
      fi
    else
      if python3 - <<'PY'
import json, re
data=json.load(open('.mcp.json'))
ok = True
for server in data.get('mcpServers', {}).values():
    for arg in server.get('args', []):
        if re.search(r'@latest|@main', arg):
            ok = False
            break
    if not ok:
        break
if ok:
    print('yes')
PY
      then
        ok "Tất cả MCP server version pinned"
      else
        ng "Có server dùng @latest hoặc @main (KHÔNG pin version)"
      fi
    fi
  else
    ng ".mcp.json không valid JSON"
  fi
else
  ng ".mcp.json không tồn tại"
fi

# claude mcp list (nếu Claude Code installed)
if command -v claude >/dev/null 2>&1; then
  if claude mcp list 2>&1 | grep -qE "✓|Connected"; then
    ok "claude mcp list shows Connected servers"
  else
    ng "claude mcp list — không server nào Connected"
  fi
fi

# debug-session log
if [ -f debug-session-day2.md ] || [ -f docs/debug-session-day2.md ]; then
  ok "debug-session-day2.md tồn tại"
else
  ng "debug-session-day2.md không tồn tại (1 case study)"
fi

# Allow-list check
if [ -f .mcp.json ]; then
  if command -v jq >/dev/null 2>&1; then
    if jq -r '.mcpServers.filesystem.args[]?' .mcp.json 2>/dev/null | grep -qE '^/$|^\$HOME$|/home/[^/]+$' ; then
      ng "Filesystem MCP allow-list quá rộng (root, $HOME)"
    else
      ok "Filesystem MCP allow-list hợp lý"
    fi
  else
    FILESYSTEM_ARGS=$(python3 - <<'PY'
import json
data=json.load(open('.mcp.json'))
for arg in data.get('mcpServers', {}).get('filesystem', {}).get('args', []):
    print(arg)
PY
)
    if echo "$FILESYSTEM_ARGS" | grep -qE '^/$|^\$HOME$|/home/[^/]+$'; then
      ng "Filesystem MCP allow-list quá rộng (root, $HOME)"
    else
      ok "Filesystem MCP allow-list hợp lý"
    fi
  fi
fi

echo
 echo "=== Kết quả: $PASS PASS / $FAIL FAIL ==="
[ "$FAIL" -eq 0 ] && green "✅ Day 2 OK" || { red "❌ Có FAIL — xem Day2-Spec.md"; exit 1; }
