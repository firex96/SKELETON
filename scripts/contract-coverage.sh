#!/usr/bin/env bash
# 장치 B — 복제 결함 탐지
#
# "형제가 셋 다 똑같이 틀린 것"은 대조로 잡히지 않는다. 잡으려면 규약 표면에
# 그것을 실제로 지나가는 테스트가 있어야 한다. 이 스크립트는 그것을 강제한다.
#
# 검사: 존재(파일) → 도달(그 소스셋의 태스크가 실제로 실행) → 실행량 → 실질(단언 신호)
#
# exit 0 = 전부 PASS(또는 사유 갖춘 WARN) / 1 = FAIL 있음 / 2 = 대응표가 잘못됨
#
# 주의: 과거 XML 로 도달 검사가 통과하는 것을 막기 위해 build/test-results 를 지우고
#       테스트를 직접 실행한다. --no-run 은 이미 방금 실행한 결과를 재사용할 때만 쓴다.
#
# 전제: public·internal 은 check 에 e2eTest 가 묶여 있지 않아 따로 돌린다. e2e 는 그 레포의
#       docker compose(MySQL·Redis) 위에서 돈다. 세 레포의 compose 가 같은 호스트 포트를 쓰므로
#       레포마다 compose 를 띄우고 --repo 로 하나씩 실행한다.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SURFACES="${CONTRACT_SURFACES:-$ROOT/docs/contract-surfaces.md}"
RUN_TESTS=1
ONLY_REPO=""

while [ $# -gt 0 ]; do
  case "$1" in
    --no-run) RUN_TESTS=0 ;;
    --repo)
      shift; ONLY_REPO="${1:-}"
      # 알 수 없는 값이면 모든 레포를 건너뛰어 PASS=0/FAIL=0 exit 0 이 된다 — fail-open 이다.
      case "$ONLY_REPO" in
        public|internal|batch) ;;
        *) echo "알 수 없는 --repo 값: '$ONLY_REPO' (public|internal|batch)" >&2; exit 2 ;;
      esac
      ;;
    *) echo "usage: contract-coverage.sh [--no-run] [--repo public|internal|batch]" >&2; exit 2 ;;
  esac
  shift
done

repo_path() {
  case "$1" in
    public)   echo "$ROOT/../spring-boot-public-api-skeleton" ;;
    internal) echo "$ROOT/../spring-boot-internal-api-skeleton" ;;
    batch)    echo "$ROOT/../spring-batch-skeleton" ;;
    *) return 1 ;;
  esac
}
# 소스셋 → gradle 태스크. 이 결속을 검사에 넣는 것이 도달 검사의 핵심이다.
task_of() {
  case "$1" in
    unit) echo "test" ;; integration) echo "integrationTest" ;; e2e) echo "e2eTest" ;;
    *) return 1 ;;
  esac
}

[ -f "$SURFACES" ] || { echo "정본 표를 찾을 수 없다: $SURFACES" >&2; exit 2; }

FAIL=0; PASS=0; WARN=0

# ── 1·2단계: 과거 XML 제거 후 테스트 실행
if [ "$RUN_TESTS" -eq 1 ]; then
  for r in public internal batch; do
    [ -n "$ONLY_REPO" ] && [ "$r" != "$ONLY_REPO" ] && continue
    rp="$(repo_path "$r")"
    echo "[$r] build/test-results 제거 후 테스트 실행"
    rm -rf "$rp/build/test-results"
    if [ "$r" = "batch" ]; then tasks="test integrationTest"; else tasks="check e2eTest"; fi
    # 로그는 레포 트리 밖에 둔다 — 절대 경로·환경 정보가 담기고 커밋될 이유가 없다.
    log="${TMPDIR:-/tmp}/contract-coverage-$r.log"
    ( cd "$rp" && ./gradlew $tasks ) > "$log" 2>&1
    echo "[$r] rc=$? (로그: $log)"
  done
fi

report() { printf '  %-8s %-46s %s\n' "$1" "$2" "$3"; }

# enforced=no 는 「이 표면에 아직 테스트가 없음을 사유·담당·시점과 함께 알고 있다」는 뜻이다.
# 존재·도달·실행량·실질 어느 단계에서 걸려도 WARN 으로 낮춘다. FAIL 로 두면 수용 기준을
# 영원히 만족할 수 없다(④ 에서 실제로 실행해 보고 발견한 모순).
fail_or_warn() {  # $1=label $2=사유
  if [ "$enforced" = "no" ]; then
    report WARN "$1" "$2 — $note"; WARN=$((WARN+1))
  else
    report FAIL "$1" "$2"; FAIL=$((FAIL+1))
  fi
}

echo
echo "장치 B — 규약 표면 ↔ 필수 테스트"
echo

while IFS='|' read -r _ surface repos test_class source_set patterns enforced note _rest; do
  surface="$(echo "$surface" | sed -e 's/^ *//' -e 's/ *$//')"
  repos="$(echo "$repos" | sed -e 's/^ *//' -e 's/ *$//')"
  test_class="$(echo "$test_class" | sed -e 's/^ *//' -e 's/ *$//' -e 's/`//g')"
  source_set="$(echo "$source_set" | sed -e 's/^ *//' -e 's/ *$//')"
  patterns="$(echo "$patterns" | sed -e 's/^ *//' -e 's/ *$//')"
  enforced="$(echo "$enforced" | sed -e 's/^ *//' -e 's/ *$//')"
  note="$(echo "$note" | sed -e 's/^ *//' -e 's/ *$//')"

  [ -z "$surface" ] && continue
  case "$surface" in surface|---*|-*) continue ;; esac

  # enforced=no 는 사유·담당·시점 셋이 모두 있어야 한다
  if [ "$enforced" = "no" ]; then
    case "$note" in
      *사유=*담당=*시점=*) : ;;
      *) echo "표 거부: enforced=no 인데 사유·담당·시점이 갖춰지지 않았다 ($surface)" >&2; exit 2 ;;
    esac
  fi

  task="$(task_of "$source_set")" || { echo "알 수 없는 source_set: $source_set ($surface)" >&2; exit 2; }
  if [ "$repos" = "3" ]; then targets="public internal batch"; else targets="$repos"; fi

  for r in $targets; do
    [ -n "$ONLY_REPO" ] && [ "$r" != "$ONLY_REPO" ] && continue
    rp="$(repo_path "$r")" || { echo "알 수 없는 레포: $r" >&2; exit 2; }
    label="$surface [$r]"

    # 존재
    src="$(find "$rp/src/test/$source_set" -name "${test_class}.kt" 2>/dev/null | head -1)"
    if [ -z "$src" ]; then
      fail_or_warn "$label" "존재: src/test/$source_set 에 ${test_class}.kt 없음"; continue
    fi

    # 도달 — 소스셋에 대응하는 태스크의 결과여야 한다
    xml="$(ls "$rp/build/test-results/$task"/*"${test_class}.xml" 2>/dev/null | head -1)"
    if [ -z "$xml" ]; then
      fail_or_warn "$label" "도달: build/test-results/$task 에 결과 없음(실행되지 않았다)"; continue
    fi

    # 실행량
    read -r tests failures errors skipped <<EOF
$(python3 - "$xml" <<'PY'
import sys, re
head = open(sys.argv[1], encoding="utf-8", errors="replace").read(4000)
m = re.search(r'<testsuite\b[^>]*>', head)
a = m.group(0) if m else ""
g = lambda k: (re.search(k+r'="(\d+)"', a) or [0,'0'])[1]
print(g("tests"), g("failures"), g("errors"), g("skipped"))
PY
)
EOF
    # skipped 를 검사하지 않으면 @Disabled 테스트가 "실행됐다" 로 통과한다.
    # 실행되지 않은 것을 실행된 것으로 세는 순간 도달 검사의 의미가 사라진다.
    executed=$(( ${tests:-0} - ${skipped:-0} ))
    if [ "$executed" -lt 1 ] || [ "${failures:-1}" -ne 0 ] || [ "${errors:-1}" -ne 0 ]; then
      fail_or_warn "$label" "실행량: tests=$tests skipped=$skipped 실행=$executed failures=$failures errors=$errors"; continue
    fi

    # 실질 — assert_pattern 은 " / " 로 구분된 목록. alternation 을 쓰지 않는다.
    missing=""
    OLDIFS="$IFS"; IFS='/'
    for pat in $patterns; do
      pat="$(echo "$pat" | sed -e 's/^ *//' -e 's/ *$//')"
      [ -z "$pat" ] && continue
      grep -qF -- "$pat" "$src" || missing="$missing $pat"
    done
    IFS="$OLDIFS"

    if [ -n "$missing" ]; then
      fail_or_warn "$label" "실질: 단언 신호 부재 ($(echo $missing))"; continue
    fi

    report PASS "$label" "실행=$executed/$tests"
    PASS=$((PASS+1))
  done
done < <(sed -n '/^## 대응/,$p' "$SURFACES" | grep '^|')

echo
echo "PASS=$PASS  WARN=$WARN  FAIL=$FAIL"
[ "$FAIL" -gt 0 ] && exit 1
exit 0
