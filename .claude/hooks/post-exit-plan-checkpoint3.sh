#!/usr/bin/env bash
# PostToolUse(ExitPlanMode): approved plan's declared checkpoint tier is recorded
# before the next tool call. The companion PreToolUse hook consumes this state.
# Hook failures must not reject a completed plan approval.

set +e

INPUT="$(cat 2>/dev/null || echo '')"
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
OUT_DIR="${CHECKPOINT3_OUT_DIR:-$ROOT/.claude/review-out}"
STATE_FILE="${CHECKPOINT3_STATE_FILE:-$OUT_DIR/checkpoint3-gate.json}"
SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)"
PLAN_FILE="$(printf '%s' "$INPUT" | jq -r '.tool_response.filePath // .tool_input.planFilePath // empty' 2>/dev/null)"
PLAN="$(printf '%s' "$INPUT" | jq -r '.tool_response.plan // empty' 2>/dev/null)"

case "$PLAN" in
  *'<!-- CHECKPOINT3: required -->'*)
    STATE="pending"
    MARKER_STATE="required"
    ;;
  *'<!-- CHECKPOINT3: not-required -->'*)
    STATE="not-required"
    MARKER_STATE="not-required"
    ;;
  *)
    # A missing or unreadable declaration must not silently bypass checkpoint 3.
    STATE="pending"
    MARKER_STATE="missing"
    printf '%s\n' '[checkpoint-3] implementation-plan tier marker is missing; defaulting to pending. Add exactly <!-- CHECKPOINT3: required --> or <!-- CHECKPOINT3: not-required --> to the approved plan.' >&2
    ;;
esac

mkdir -p "$OUT_DIR" || exit 0
EXIT_PLAN_HASH="$(printf '%s' "$PLAN" | shasum -a 256 | awk '{print $1}')"
TMP_FILE="$(mktemp "$OUT_DIR/.checkpoint3-gate.XXXXXX")" || exit 0

jq -n \
  --arg state "$STATE" \
  --arg markerState "$MARKER_STATE" \
  --arg sessionId "$SESSION_ID" \
  --arg planFile "$PLAN_FILE" \
  --arg exitPlanHash "$EXIT_PLAN_HASH" \
  --arg recordedAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{version: 1, state: $state, marker_state: $markerState, session_id: $sessionId, exit_plan_file: $planFile, exit_plan_sha256: $exitPlanHash, recorded_at: $recordedAt}' \
  > "$TMP_FILE" || {
    rm -f "$TMP_FILE"
    exit 0
  }

mv "$TMP_FILE" "$STATE_FILE"
exit 0
