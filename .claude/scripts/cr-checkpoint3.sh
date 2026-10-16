#!/usr/bin/env bash
# Run and attest checkpoint 3 for an implementation plan. The companion
# PreToolUse hook unblocks source edits only after this wrapper records APPROVED.
#
# 2026-07-28: Antigravity 승인권 복원에 맞춰 게이트를 양쪽 엔진 검사로 바꿨다.
#   이전에는 Codex 만 확인하고 편집 잠금을 풀어, 계약(③ = Codex + Antigravity 둘 다 Approve)과
#   어긋난 채로 구현이 시작될 수 있었다.
# 2026-08-07: Codex 폴백을 추가해 두 엔진 폴백을 대칭으로 만들었다.
#   이전에는 codex 미설치(래퍼 부재 포함) 시 자력 해제 수단이 없어, 엔진을 쓰지 않는 팀원이
#   플랜 모드를 쓰면 편집이 영구 차단됐다. 폴백은 각각 별도 환경변수로 의식적으로 켜야 하고
#   전부 checkpoint3-gate.json 에 기록된다.

set -euo pipefail

PLAN_INPUT="${1:?usage: cr-checkpoint3.sh <implementation-plan-path>}"
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

case "$PLAN_INPUT" in
  /*) PLAN_FILE="$PLAN_INPUT" ;;
  *) PLAN_FILE="$ROOT/$PLAN_INPUT" ;;
esac

[ -f "$PLAN_FILE" ] || {
  echo "implementation plan is not a file: $PLAN_FILE" >&2
  exit 2
}
PLAN_FILE="$(cd "$(dirname "$PLAN_FILE")" && pwd -P)/$(basename "$PLAN_FILE")"

OUT_DIR="$ROOT/.claude/review-out"
STATE_FILE="$OUT_DIR/checkpoint3-gate.json"
CODEX_STATUS="$OUT_DIR/codex-plan.status"
CODEX_RESULT="$OUT_DIR/codex-plan.md"
AGY_STATUS="$OUT_DIR/antigravity-plan.status"
AGY_RESULT="$OUT_DIR/antigravity-plan.md"
CODEX_WRAPPER="${CR_CODEX_WRAPPER:-$HOME/.claude/scripts/cr-codex.sh}"
AGY_WRAPPER="${CR_AGY_WRAPPER:-$HOME/.claude/scripts/cr-antigravity.sh}"

ALLOW_CODEX_UNAVAIL="${CR_CP3_ALLOW_CODEX_UNAVAILABLE:-0}"
ALLOW_AGY_UNAVAIL="${CR_CP3_ALLOW_AGY_UNAVAILABLE:-0}"

# ── 래퍼 부재 = 엔진 미설치. 해당 폴백을 의식적으로 켠 경우에만 unavailable 로 넘긴다.
#    그냥 통과시키면 설치가 깨진 것을 "리뷰 없음"으로 조용히 바꿔치기하게 된다.
CODEX_WRAPPER_OK=true
[ -x "$CODEX_WRAPPER" ] || [ -f "$CODEX_WRAPPER" ] || CODEX_WRAPPER_OK=false
AGY_WRAPPER_OK=true
[ -x "$AGY_WRAPPER" ] || [ -f "$AGY_WRAPPER" ] || AGY_WRAPPER_OK=false

if [ "$CODEX_WRAPPER_OK" != true ] && [ "$ALLOW_CODEX_UNAVAIL" != 1 ]; then
  {
    echo "missing review wrapper: $CODEX_WRAPPER"
    echo "  codex 를 쓰지 않는 환경이면: CR_CP3_ALLOW_CODEX_UNAVAILABLE=1 bash .claude/scripts/cr-checkpoint3.sh <plan>"
  } >&2
  exit 2
fi
if [ "$AGY_WRAPPER_OK" != true ] && [ "$ALLOW_AGY_UNAVAIL" != 1 ]; then
  {
    echo "missing review wrapper: $AGY_WRAPPER"
    echo "  agy 를 쓰지 않는 환경이면: CR_CP3_ALLOW_AGY_UNAVAILABLE=1 bash .claude/scripts/cr-checkpoint3.sh <plan>"
  } >&2
  exit 2
fi

grep -Fqx '<!-- CHECKPOINT3: required -->' "$PLAN_FILE" || {
  echo "implementation plan must declare <!-- CHECKPOINT3: required -->: $PLAN_FILE" >&2
  exit 2
}

last_nonblank_line() {
  awk 'NF { line = $0 } END { print line }' "$1" | tr -d '\r'
}

# ── 두 엔진을 모두 실행한다. 한쪽이 실패해도 다른 쪽 판정을 남겨 진단을 돕는다.
#    래퍼가 없어 건너뛴 엔진은 rc=127 로 남겨 직전 라운드의 stale 판정이 통과로 읽히지 않게 한다.
#    두 엔진은 서로 다른 판정 파일에 쓰고 각자 lock 을 잡으므로 **병렬이 안전하다.**
#    직렬로 돌리면 ③ 게이트가 편집을 막는 시간이 sum(codex, agy) 다 → max 로 줄인다.
#    출력은 뒤섞이지 않게 각자 버퍼에 받아 순서대로 방출한다.
set +e
RC_CODEX=127
RC_AGY=127
CODEX_PID=""; AGY_PID=""; CODEX_TEE=""; AGY_TEE=""
if [ "$CODEX_WRAPPER_OK" = true ]; then
  CODEX_TEE="$(mktemp)"; bash "$CODEX_WRAPPER" plan "$PLAN_FILE" >"$CODEX_TEE" 2>&1 & CODEX_PID=$!
fi
if [ "$AGY_WRAPPER_OK" = true ]; then
  AGY_TEE="$(mktemp)"; bash "$AGY_WRAPPER" plan "$PLAN_FILE" >"$AGY_TEE" 2>&1 & AGY_PID=$!
fi
[ -n "$CODEX_PID" ] && { wait "$CODEX_PID"; RC_CODEX=$?; }
[ -n "$AGY_PID"   ] && { wait "$AGY_PID";   RC_AGY=$?;   }
[ -n "$CODEX_TEE" ] && { cat "$CODEX_TEE"; rm -f "$CODEX_TEE"; }
[ -n "$AGY_TEE"   ] && { cat "$AGY_TEE";   rm -f "$AGY_TEE";   }
set -e

CODEX_OK=false
CODEX_STATE="MISSING"
[ -f "$CODEX_STATUS" ] && CODEX_STATE="$(sed -n 's/^CR-CODEX-STATUS: //p' "$CODEX_STATUS" | tail -1)"
[ "$CODEX_WRAPPER_OK" = true ] || CODEX_STATE="WRAPPER-MISSING"
if [ "$RC_CODEX" -eq 0 ] \
  && [ -f "$CODEX_STATUS" ] && [ -f "$CODEX_RESULT" ] \
  && grep -qx 'CR-CODEX-STATUS: OK' "$CODEX_STATUS" \
  && [ "$(last_nonblank_line "$CODEX_RESULT")" = 'DECISION: Approve' ]; then
  CODEX_OK=true
fi

AGY_OK=false
AGY_STATE="MISSING"
[ -f "$AGY_STATUS" ] && AGY_STATE="$(sed -n 's/^CR-ANTIGRAVITY-STATUS: //p' "$AGY_STATUS" | tail -1)"
[ "$AGY_WRAPPER_OK" = true ] || AGY_STATE="WRAPPER-MISSING"
if [ "$RC_AGY" -eq 0 ] \
  && [ -f "$AGY_STATUS" ] && [ -f "$AGY_RESULT" ] \
  && grep -qx 'CR-ANTIGRAVITY-STATUS: OK' "$AGY_STATUS" \
  && [ "$(last_nonblank_line "$AGY_RESULT")" = 'DECISION: Approve' ]; then
  AGY_OK=true
fi

# ── 폴백: ①③ 은 Claude 대행 승인을 만들지 않는다(자기 계획 자가승인 금지).
#    엔진이 unavailable 이면 계약상 "남은 승인 + 사용자 확인"이 필요한데 스크립트가 확인을
#    대신할 수 없으므로, 사용자가 의식적으로 환경변수를 세팅한 경우에만 통과시키고 기록에 남긴다.
CODEX_FALLBACK=false
if [ "$CODEX_OK" != true ] && [ "$ALLOW_CODEX_UNAVAIL" = 1 ]; then
  CODEX_FALLBACK=true
fi
AGY_FALLBACK=false
if [ "$AGY_OK" != true ] && [ "$ALLOW_AGY_UNAVAIL" = 1 ]; then
  AGY_FALLBACK=true
fi

CODEX_PASS=false
if [ "$CODEX_OK" = true ] || [ "$CODEX_FALLBACK" = true ]; then CODEX_PASS=true; fi
AGY_PASS=false
if [ "$AGY_OK" = true ] || [ "$AGY_FALLBACK" = true ]; then AGY_PASS=true; fi

INDEPENDENT=0
[ "$CODEX_OK" = true ] && INDEPENDENT=$((INDEPENDENT + 1))
[ "$AGY_OK" = true ] && INDEPENDENT=$((INDEPENDENT + 1))

echo "[checkpoint3] codex=$CODEX_OK (status=$CODEX_STATE)  antigravity=$AGY_OK (status=$AGY_STATE)  독립승인=$INDEPENDENT/2"

if [ "$CODEX_PASS" != true ] || [ "$AGY_PASS" != true ]; then
  {
    if [ "$CODEX_OK" != true ]; then
      echo "    → Codex 미승인(status=$CODEX_STATE). $CODEX_RESULT 지적을 반영한 뒤 재실행."
      echo "      엔진이 정말 unavailable 이라 나머지 승인만으로 진행하려면 사용자 확인이 필요하다."
      echo "      확인했다면: CR_CP3_ALLOW_CODEX_UNAVAILABLE=1 bash .claude/scripts/cr-checkpoint3.sh <plan>"
    fi
    if [ "$AGY_OK" != true ]; then
      echo "    → Antigravity 미승인(status=$AGY_STATE). $AGY_RESULT 확인."
      echo "      엔진이 정말 unavailable 이라 나머지 승인만으로 진행하려면 사용자 확인이 필요하다."
      echo "      확인했다면: CR_CP3_ALLOW_AGY_UNAVAILABLE=1 bash .claude/scripts/cr-checkpoint3.sh <plan>"
    fi
    echo "      (폴백은 checkpoint3-gate.json 에 기록된다.)"
    echo 'CR-CHECKPOINT3-STATUS: NOT-APPROVED'
  } >&2
  exit 4
fi

mkdir -p "$OUT_DIR"
PLAN_HASH="$(shasum -a 256 "$PLAN_FILE" | awk '{print $1}')"
TMP_FILE="$(mktemp "$OUT_DIR/.checkpoint3-gate.XXXXXX")"

JQ_SET='.state = "approved"
  | .reviewed_plan_file = $planFile
  | .reviewed_plan_sha256 = $planHash
  | .approved_at = $approvedAt
  | .codex_status = $codexState
  | .codex_decision = (if $codexOk == "true" then "Approve" else "unavailable" end)
  | .codex_fallback = ($codexFallback == "true")
  | .antigravity_status = $agyState
  | .antigravity_decision = (if $agyOk == "true" then "Approve" else "unavailable" end)
  | .antigravity_fallback = ($agyFallback == "true")
  | .independent_reviews = ($independent | tonumber)'

JQ_ARGS=(
  --arg planFile "$PLAN_FILE" --arg planHash "$PLAN_HASH"
  --arg approvedAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  --arg codexState "$CODEX_STATE" --arg codexOk "$CODEX_OK" --arg codexFallback "$CODEX_FALLBACK"
  --arg agyState "$AGY_STATE" --arg agyOk "$AGY_OK" --arg agyFallback "$AGY_FALLBACK"
  --arg independent "$INDEPENDENT"
)

if [ -f "$STATE_FILE" ]; then
  jq "${JQ_ARGS[@]}" "$JQ_SET" "$STATE_FILE" > "$TMP_FILE"
else
  jq -n "${JQ_ARGS[@]}" "{version: 1} | $JQ_SET" > "$TMP_FILE"
fi

mv "$TMP_FILE" "$STATE_FILE"
if [ "$CODEX_FALLBACK" = true ]; then
  echo "[checkpoint3] ⚠️ Codex unavailable($CODEX_STATE) — 사용자 확인 폴백으로 통과."
fi
if [ "$AGY_FALLBACK" = true ]; then
  echo "[checkpoint3] ⚠️ Antigravity unavailable($AGY_STATE) — 사용자 확인 폴백으로 통과."
fi
if [ "$INDEPENDENT" -eq 0 ]; then
  echo "[checkpoint3] ⛔ 독립 승인 0개 — 이 통과에는 외부 검증이 전혀 없다. 계획 품질은 전적으로 작성자 책임이다."
fi
echo 'CR-CHECKPOINT3-STATUS: APPROVED'
