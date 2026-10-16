#!/usr/bin/env bash
# PreToolUse(Write|Edit|Bash): block source edits while the most recently
# approved implementation plan still requires checkpoint 3.

set +e

INPUT="$(cat 2>/dev/null || echo '')"
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
OUT_DIR="${CHECKPOINT3_OUT_DIR:-$ROOT/.claude/review-out}"
STATE_FILE="${CHECKPOINT3_STATE_FILE:-$OUT_DIR/checkpoint3-gate.json}"

[ -f "$STATE_FILE" ] || exit 0
STATE="$(jq -r '.state // empty' "$STATE_FILE" 2>/dev/null)"
[ "$STATE" = "pending" ] || exit 0

SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)"
STATE_SESSION_ID="$(jq -r '.session_id // empty' "$STATE_FILE" 2>/dev/null)"
[ -z "$SESSION_ID" ] || [ -z "$STATE_SESSION_ID" ] || [ "$SESSION_ID" = "$STATE_SESSION_ID" ] || exit 0

TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)"
FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)"

block() {
  printf '%s\n' '[checkpoint-3] 승인된 구현 플랜이 ③ 구현계획 크로스리뷰를 기다리고 있습니다. `bash .claude/scripts/cr-checkpoint3.sh plans/ing/<slug>/구현_설계.md`가 `APPROVED`로 끝나야 코드 변경을 할 수 있습니다.' >&2
  exit 2
}

is_non_code_artifact() {
  case "$1" in
    *'/../'*|*/'..'|'.')
      return 1
      ;;
    "$ROOT"/plans/*|"$ROOT"/.claude/rules/*|"$ROOT"/.claude/skills/*|*.md|*.txt)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_single_checkpoint_command() {
  case "$1" in
    *'~/.claude/scripts/cr-codex.sh plan'*|*'~/.claude/scripts/cr-antigravity.sh plan'*|*'.claude/scripts/cr-checkpoint3.sh'*)
      ;;
    *)
      return 1
      ;;
  esac
  case "$1" in
    *';'*|*'&&'*|*'||'*|*'|'*|*'>'*|*'<'*|*'`'*|*'$('* )
      return 1
      ;;
  esac
  return 0
}

case "$TOOL_NAME" in
  Write|Edit)
    case "$FILE_PATH" in
      /*) ;;
      *) FILE_PATH="$ROOT/$FILE_PATH" ;;
    esac
    is_non_code_artifact "$FILE_PATH" || block
    ;;
  Bash)
    is_single_checkpoint_command "$COMMAND" && exit 0
    case "$COMMAND" in
      *apply_patch*|*' >'*|*'>>'*|*'tee '*|*'sed -i'*|*'perl -pi'*|*'ruby -i'*|*'git apply'*|*'git checkout --'*|*'git restore '*)
        block
        ;;
    esac
    ;;
esac

exit 0
