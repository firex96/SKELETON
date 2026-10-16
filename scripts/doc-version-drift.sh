#!/usr/bin/env bash
# 문서 버전 표류 검사
#
# 빌드 파일을 정본으로 삼아 문서가 적은 버전과 대조한다.
# 목적은 "빌드는 올렸는데 문서는 그대로"의 상시 검출이다.
#
# 왜 필요한가: 2026-08-31 실측에서 세 스켈레톤 README 의 Spring Boot·Kotlin 버전이
# 전부 틀렸고, internal 은 메이저 한 세대(3.4.7 vs 4.1.1)가 뒤처져 있었다.
# 워크스페이스 진입 문서(SKELETON/CLAUDE.md)도 낡아 매 세션 잘못된 전제로 시작했다.
#
# exit 0 = 표류 없음 / 1 = DRIFT 있음 / 2 = 정본을 못 읽음(fail-closed)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIBLING_ROOT="${SIBLING_ROOT:-$ROOT/..}"

repo_path() {
  case "$1" in
    public)   echo "$SIBLING_ROOT/spring-boot-public-api-skeleton" ;;
    internal) echo "$SIBLING_ROOT/spring-boot-internal-api-skeleton" ;;
    batch)    echo "$SIBLING_ROOT/spring-batch-skeleton" ;;
    *)        return 1 ;;
  esac
}

DRIFT=0
CHECKED=0

report() {
  printf '  %-8s %-12s %-14s 빌드=%-10s 문서=%-10s\n' "$1" "$2" "$3" "$4" "$5"
}

# ── 정본 추출 ────────────────────────────────────────────────────────────
# 빈 추출을 "일치"로 읽으면 좌표가 바뀐 순간 아무것도 감시하지 않으면서 통과한다.
# 그래서 정본이 비면 exit 2 로 막는다(fail-closed).

truth_spring_boot() {
  sed -n 's/.*id("org\.springframework\.boot") version "\([^"]*\)".*/\1/p' "$1/build.gradle.kts" | head -1
}
truth_kotlin() {
  sed -n 's/.*val kotlinVersion = "\([^"]*\)".*/\1/p' "$1/build.gradle.kts" | head -1
}
truth_gradle() {
  sed -n 's|.*/gradle-\([0-9][0-9.]*\)-bin\.zip.*|\1|p' "$1/gradle/wrapper/gradle-wrapper.properties" | head -1
}
truth_java() {
  sed -n 's/.*JavaLanguageVersion\.of(\([0-9]*\)).*/\1/p' "$1/build.gradle.kts" | head -1
}
truth_ktlint() {
  sed -n 's/.*version\.set("\([^"]*\)").*/\1/p' "$1/build.gradle.kts" | head -1
}

# ── 문서 추출 ────────────────────────────────────────────────────────────
# 공통 골격의 스택 표 서식 하나만 읽는다.
#
#   | Spring Boot | 4.1.1 |
#
# 서식을 통일한 이유가 이것이다 — 두 가지를 파싱하면 한쪽이 조용히 빠진다.
doc_version() {
  local file="$1" label="$2"
  [ -f "$file" ] || { echo "__ABSENT__"; return; }
  awk -F'|' -v l="$label" '
    { gsub(/^[ \t]+|[ \t]+$/, "", $2); gsub(/^[ \t]+|[ \t]+$/, "", $3) }
    $2 == l { print $3; exit }
  ' "$file"
}

echo "########## 스켈레톤 3레포 README — 정확히 일치해야 한다"
for r in public internal batch; do
  rp="$(repo_path "$r")"
  readme="$rp/README.md"

  sb="$(truth_spring_boot "$rp")"; kt="$(truth_kotlin "$rp")"
  gr="$(truth_gradle "$rp")";      jv="$(truth_java "$rp")"
  kl="$(truth_ktlint "$rp")"

  for pair in "Spring Boot:$sb" "Kotlin:$kt" "Gradle:$gr" "Java:$jv" "ktlint:$kl"; do
    label="${pair%%:*}"; truth="${pair#*:}"
    if [ -z "$truth" ]; then
      echo "  [$r] 정본을 못 읽었다: $label — 좌표가 바뀌었는지 확인하라" >&2
      exit 2
    fi
    doc="$(doc_version "$readme" "$label")"
    CHECKED=$((CHECKED + 1))
    if [ "$doc" = "__ABSENT__" ]; then
      report "$r" "$label" "README없음" "$truth" "-"; DRIFT=$((DRIFT + 1))
    elif [ -z "$doc" ]; then
      report "$r" "$label" "표기없음" "$truth" "-"; DRIFT=$((DRIFT + 1))
    elif [ "$doc" != "$truth" ]; then
      report "$r" "$label" "DRIFT" "$truth" "$doc"; DRIFT=$((DRIFT + 1))
    fi
  done
done

echo "########## 워크스페이스 문서 — minor 까지만 본다"
# 패치를 올릴 때마다 워크스페이스 문서를 건드리지 않으려는 것이다.
# 셋이 같은 버전을 쓰므로 public 을 대표로 삼는다 — 다르면 장치 A 가 먼저 잡는다.
pub="$(repo_path public)"
SB_MINOR="$(truth_spring_boot "$pub" | cut -d. -f1,2)"
KT_MINOR="$(truth_kotlin "$pub" | cut -d. -f1,2)"
[ -n "$SB_MINOR" ] && [ -n "$KT_MINOR" ] || { echo "  정본 minor 추출 실패" >&2; exit 2; }

for f in "$ROOT/CLAUDE.md" "$ROOT/README.md"; do
  rel="${f#"$ROOT"/}"
  for pair in "Spring Boot:$SB_MINOR" "Kotlin:$KT_MINOR"; do
    label="${pair%%:*}"; want="${pair#*:}"
    CHECKED=$((CHECKED + 1))
    # 그 이름 뒤에 붙은 버전 숫자를 전부 뽑아 하나라도 minor 가 다르면 표류다.
    found="$(grep -o -E "$label [0-9]+\.[0-9]+" "$f" 2>/dev/null | sed "s/^$label //" | sort -u)"
    if [ -z "$found" ]; then
      report "$rel" "$label" "표기없음" "$want" "-"; DRIFT=$((DRIFT + 1)); continue
    fi
    for v in $found; do
      [ "$v" = "$want" ] || { report "$rel" "$label" "DRIFT" "$want" "$v"; DRIFT=$((DRIFT + 1)); }
    done
  done
done

echo
echo "CHECKED=$CHECKED  DRIFT=$DRIFT"
[ "$DRIFT" -eq 0 ] || exit 1
