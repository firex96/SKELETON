#!/usr/bin/env bash
# 스택 간 오류 코드 대조
#
# docs/error-codes.md 를 정본으로 삼아 Kotlin public·internal 의 enums/ErrorCode.kt 와
# asp-net-core 의 Common/Errors/ErrorCode.cs 를 대조한다. 같은 이름의 코드가 스택마다 다른 status·구분 코드·제목을
# 갖거나, 같은 구분 코드를 다른 이름이 쓰면 게이트웨이·클라이언트가 스택에 따라 다른 응답을 받는다.
#
#   ① 「공통 코드」 표의 코드는 public·asp 에 같은 status·구분 코드·제목으로 있다(internal 은 가진 것만 대조)
#   ② 세 파일을 합쳐 같은 구분 코드를 다른 이름이 쓰지 않는다
#   ③ 정본에 없는 이름이 Kotlin 과 asp 양쪽에 있으면 실패한다(공통이 되었으면 정본에 올린다)
#   ④ 공통 코드가 아닌 구분 코드는 「스택 전용 코드」 표에 예약돼 있어야 한다
#   ⑤ 파싱한 항목 수가 원본의 항목 수와 같다(줄바꿈된 항목이 조용히 빠지지 않게)
#   ⑥ public·internal 에 함께 있는 이름은 Kotlin 전용 코드라도 status·구분 코드·제목이 같다
#   ⑦ 「공통 코드」의 구분 코드는 「스택 전용 코드」 예약 목록에 없다(공통으로 옮긴 코드의 예약이 남지 않게)
#
# exit 0 = 일치 / 1 = 위반 / 2 = 입력 파일 없음
# 입력 경로를 환경변수로 바꿀 수 있다(음성 확인용):
#   SIBLING_ROOT · ERROR_CODE_TABLE · PUBLIC_ERROR_CODE · INTERNAL_ERROR_CODE · ASP_ERROR_CODE

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIBLING_ROOT="${SIBLING_ROOT:-$ROOT/..}"
TABLE="${ERROR_CODE_TABLE:-$ROOT/docs/error-codes.md}"
PUBLIC="${PUBLIC_ERROR_CODE:-$SIBLING_ROOT/spring-boot-public-api-skeleton/src/main/kotlin/com/rex/api/pub/skeleton/enums/ErrorCode.kt}"
INTERNAL="${INTERNAL_ERROR_CODE:-$SIBLING_ROOT/spring-boot-internal-api-skeleton/src/main/kotlin/com/rex/api/internal/skeleton/enums/ErrorCode.kt}"
ASP="${ASP_ERROR_CODE:-$SIBLING_ROOT/asp-net-core-skeleton/src/common/AspNetCoreSkeletonApplication.Common/Errors/ErrorCode.cs}"

for f in "$TABLE" "$PUBLIC" "$INTERNAL" "$ASP"; do
  [ -f "$f" ] || { echo "입력 파일이 없다: $f" >&2; exit 2; }
done

# 각 입력을 「출처|이름|status|구분 코드|제목」 줄로 만든다.
kotlin_codes() { # $1 = 출처, $2 = 파일
  grep -oE '^[[:space:]]+[A-Z][A-Z0-9_]*\([0-9]+, "[A-Z0-9]+", "[^"]*"' "$2" |
    sed -E "s/^[[:space:]]+([A-Z][A-Z0-9_]*)\(([0-9]+), \"([A-Z0-9]+)\", \"([^\"]*)\"/$1|\1|\2|\3|\4/"
}
asp_codes() { # $1 = 파일
  grep -oE 'new\("[A-Z][A-Z0-9_]*", [0-9]+, "[A-Z0-9]+", "[^"]*"\)' "$1" |
    sed -E 's/new\("([A-Z][A-Z0-9_]*)", ([0-9]+), "([A-Z0-9]+)", "([^"]*)"\)/asp|\1|\2|\3|\4/'
}
# 정본 표 — 「공통 코드」 행은 table|이름|status|구분 코드|제목, 「스택 전용 코드」 행은 reserved|구분 코드 목록
table_codes() {
  awk '
    /^## / { section = $0; next }
    /^\| [A-Za-z]/ && section == "## 공통 코드" && $2 ~ /^[A-Z][A-Z0-9_]*$/ {
      n = split($0, c, "|"); for (i = 2; i < n; i++) gsub(/^ +| +$/, "", c[i])
      print "table|" c[2] "|" c[3] "|" c[4] "|" c[5]
    }
    /^\| / && section ~ /^## 스택 전용 코드/ && $0 !~ /^\| (스택|---)/ {
      n = split($0, c, "|"); gsub(/^ +| +$/, "", c[3]); print "reserved|" c[3]
    }
  ' "$TABLE"
}

# ⑤ 원본 항목 수와 파싱 수를 맞춘다 — 형식이 다른 항목(줄바꿈 등)은 대조에서 빠지므로 여기서 실패시킨다.
parse_failed=0
check_count() { # $1 = 출처, $2 = 원본 항목 수, $3 = 파싱 수
  if [ "$2" -ne "$3" ]; then
    echo "  파싱 누락: $1 — 항목 $2개 중 $3개만 읽었다(한 줄 형식이 아닌 항목이 있다)"
    parse_failed=1
  fi
}
check_count public "$(grep -cE '^[[:space:]]+[A-Z][A-Z0-9_]*\(' "$PUBLIC")" "$(kotlin_codes public "$PUBLIC" | wc -l | tr -d " ")"
check_count internal "$(grep -cE '^[[:space:]]+[A-Z][A-Z0-9_]*\(' "$INTERNAL")" "$(kotlin_codes internal "$INTERNAL" | wc -l | tr -d " ")"
check_count asp "$(grep -cE 'public static readonly ErrorCode [A-Za-z][A-Za-z0-9]* = new\(' "$ASP")" "$(asp_codes "$ASP" | wc -l | tr -d " ")"

{
  table_codes
  kotlin_codes public "$PUBLIC"
  kotlin_codes internal "$INTERNAL"
  asp_codes "$ASP"
} | awk -F'|' -v parse_failed="$parse_failed" '
  # 「G002 · G003」·「MFA001 ~ MFA006」 를 펼쳐 예약 구분 코드 집합에 넣는다
  function reserve(list,    parts, i, range, prefix, from, to, width, k) {
    gsub(/ /, "", list); split(list, parts, "·")
    for (i in parts) {
      if (split(parts[i], range, "~") == 2) {
        prefix = range[1]; sub(/[0-9]+$/, "", prefix)
        from = substr(range[1], length(prefix) + 1); to = substr(range[2], length(prefix) + 1); width = length(from)
        for (k = from + 0; k <= to + 0; k++) reserved[sprintf("%s%0" width "d", prefix, k)] = 1
      } else if (parts[i] != "") reserved[parts[i]] = 1
    }
  }
  $1 == "reserved" { reserve($2); next }
  {
    key = $1 SUBSEP $2
    status[key] = $3; div[key] = $4; title[key] = $5
    if ($1 == "table") { order[++count] = $2; commonDiv[$4] = 1; next }
    if ($1 == "asp") inAsp[$2] = 1; else inKotlin[$2] = 1
    if (($4 in divName) && divName[$4] != $2) collision[$4] = divName[$4] " · " $2
    else divName[$4] = $2
  }
  function check(src, name, required,    key, t) {
    key = src SUBSEP name; t = "table" SUBSEP name
    if (!(key in status)) {
      if (required) { failed = 1; return "MISSING" }
      return "-"
    }
    if (status[key] != status[t] || div[key] != div[t] || title[key] != title[t]) {
      failed = 1
      return "DIFF(" status[key] " " div[key] " \"" title[key] "\")"
    }
    return "OK"
  }
  END {
    failed = parse_failed + 0
    printf "스택 간 오류 코드 대조\n정본: 공통 코드 %d개\n\n", count
    printf "  %-24s %-6s %-8s %-14s %-14s %-14s\n", "이름", "HTTP", "코드", "public", "internal", "asp"
    for (i = 1; i <= count; i++) {
      n = order[i]; t = "table" SUBSEP n
      printf "  %-24s %-6s %-8s %-14s %-14s %-14s\n", n, status[t], div[t], check("public", n, 1), check("internal", n, 0), check("asp", n, 1)
    }
    for (d in collision) { printf "\n  구분 코드 충돌: %s — %s\n", d, collision[d]; failed = 1 }
    for (n in inAsp) if ((n in inKotlin) && !(("table" SUBSEP n) in status)) {
      printf "\n  정본에 없는 공통 이름: %s — docs/error-codes.md 「공통 코드」에 올린다\n", n; failed = 1
    }
    for (k in status) {
      split(k, part, SUBSEP)
      if (part[1] != "public") continue
      other = "internal" SUBSEP part[2]
      if ((other in status) && (status[k] != status[other] || div[k] != div[other] || title[k] != title[other])) {
        printf "\n  Kotlin 형제 불일치: %s — public(%s %s \"%s\") · internal(%s %s \"%s\")\n", part[2], status[k], div[k], title[k], status[other], div[other], title[other]
        failed = 1
      }
    }
    for (d in divName) if (!(d in commonDiv) && !(d in reserved)) {
      printf "\n  예약되지 않은 구분 코드: %s (%s) — docs/error-codes.md 「스택 전용 코드」에 예약한다\n", d, divName[d]; failed = 1
    }
    for (d in commonDiv) if (d in reserved) {
      printf "\n  공통 코드가 예약 목록에도 있다: %s — 공통이 되었으면 「스택 전용 코드」에서 지운다\n", d; failed = 1
    }
    printf "\n%s\n", failed ? "RESULT: MISMATCH" : "RESULT: OK"
    exit failed ? 1 : 0
  }
'
