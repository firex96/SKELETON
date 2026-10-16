#!/usr/bin/env bash
# 장치 A — 형제 스켈레톤 발산 탐지
#
# docs/contract-surfaces.md 의 「표면」 표를 정본으로 삼아 3레포의 공통 표면을 대조한다.
# 목적은 "형제가 서로 달라진 것"의 상시 검출이다. 셋 다 똑같이 틀린 것은 장치 B 가 본다.
#
# exit 0 = 발산 없음 / 1 = DIVERGED·MISSING 있음 / 2 = 표 자체가 잘못됨

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SURFACES="${CONTRACT_SURFACES:-$ROOT/docs/contract-surfaces.md}"
# 형제 레포가 있는 디렉터리. 기본값은 워크스페이스 루트다.
# 격리 fixture 로 장치 자신을 검증할 때만 바꾼다(구현_설계 §3.4a).
SIBLING_ROOT="${SIBLING_ROOT:-$ROOT/..}"

# 레포 → base package 경로
repo_path() {
  case "$1" in
    public)   echo "$SIBLING_ROOT/spring-boot-public-api-skeleton" ;;
    internal) echo "$SIBLING_ROOT/spring-boot-internal-api-skeleton" ;;
    batch)    echo "$SIBLING_ROOT/spring-batch-skeleton" ;;
    *)        return 1 ;;
  esac
}
repo_base() {
  case "$1" in
    public)   echo "src/main/kotlin/com/rex/api/pub/skeleton" ;;
    internal) echo "src/main/kotlin/com/rex/api/internal/skeleton" ;;
    batch)    echo "src/main/kotlin/com/rex/batch/skeleton" ;;
    *)        return 1 ;;
  esac
}
repo_pkg() {
  case "$1" in
    public)   echo "com.rex.api.pub.skeleton" ;;
    internal) echo "com.rex.api.internal.skeleton" ;;
    batch)    echo "com.rex.batch.skeleton" ;;
    *)        return 1 ;;
  esac
}

[ -f "$SURFACES" ] || { echo "정본 표를 찾을 수 없다: $SURFACES" >&2; exit 2; }

DIVERGED=0
MISSING=0
EXPECTED=0
SAME=0

# ── 정규화: package/import 제거 → base package 를 <BASE> 로 → 공백 정리 → md5
normalize_md5() {
  local file="$1" pkg="$2"
  [ -f "$file" ] || { echo "__ABSENT__"; return; }
  grep -v -e '^package ' -e '^import ' "$file" \
    | sed -e "s/${pkg//./\\.}/<BASE>/g" -e 's/[[:space:]]*$//' \
    | awk 'BEGIN{blank=0} { if ($0=="") { blank++; if (blank>1) next } else blank=0; print }' \
    | md5 -q 2>/dev/null || true
}

# ── section 모드: 마크다운 문서에서 「제목」 절만 뽑아 정규화
section_md5() {
  local file="$1" heading="$2"
  [ -f "$file" ] || { echo "__ABSENT__"; return; }
  awk -v h="$heading" '
    index($0, h) > 0 && /^#+ / { inside=1; next }
    inside && /^#+ / { exit }
    inside { print }
  ' "$file" | sed -e 's/[[:space:]]*$//' \
    | awk 'BEGIN{blank=0} { if ($0=="") { blank++; if (blank>1) next } else blank=0; print }' \
    | md5 -q 2>/dev/null || true
}

# ── deps 모드: build.gradle.kts 에서 지정한 group:artifact 의 버전만 뽑는다
#    실태조사의 1번 발견이 버전 발산인데 full/section/symbols 로는 잡히지 않는다
#    (build 파일 전체는 레포마다 정당하게 다르다).
deps_map() {
  local file="$1" coords="$2"
  [ -f "$file" ] || { echo "__ABSENT__"; return; }
  local out=""
  for ga in $coords; do
    local v
    v=$(grep -oE "\"${ga}:[^\"]*\"" "$file" | head -1 | sed -E 's#.*:([^"]*)"#\1#')
    out="${out}${ga}=${v:-__MISSING__};"
  done
  echo "$out"
}

# ── props 모드: override val/fun <NAME> 선언 중 지정된 이름만 뽑는다.
#    테스트 설정 클래스처럼 "공유해야 하는 선언"과 "레포별로 다른 것이 정당한 선언"이
#    한 파일에 섞여 있을 때 쓴다. 목록 밖 선언은 무시한다.
props_map() {
  local file="$1" names="$2"
  [ -f "$file" ] || { echo "__ABSENT__"; return; }
  local out=""
  for n in $names; do
    local v
    # 선언 한 줄만 보면 안 된다 — 우변이 여러 줄일 수 있다.
    #   override fun extensions(): List<Extension> =
    #       listOf(
    #           SpringExtension,
    #       )
    # 괄호가 균형을 이룰 때까지 모으고, `=` 뒤에 내용이 생길 때까지 이어 붙인다.
    # (grep -E 의 [^\n] 은 "역슬래시와 n 을 제외" 로 해석돼 첫 n 에서 잘린다 — 쓰지 않는다.)
    v=$(awk -v name="$n" '
      function bal(s,   i,c,d) { d=0; for (i=1;i<=length(s);i++) { c=substr(s,i,1); if (c=="(") d++; else if (c==")") d-- } return d }
      $0 ~ ("override (val|fun) " name "([^A-Za-z0-9_]|$)") { buf=$0; got=1; next }
      got {
        # 우변이 아직 안 나왔거나(= 로 끝남) 괄호가 안 닫혔으면 계속 모은다.
        if (buf ~ /=[[:space:]]*$/ || bal(buf) != 0) { buf = buf " " $0; next }
        print buf; exit
      }
      END { if (got) print buf }
    ' "$file" | head -1 | sed -E "s/[[:space:]]+/ /g; s/\([[:space:]]+/(/g; s/[[:space:]]*,?[[:space:]]*\)/)/g; s/^ //; s/ \$//")
    out="${out}${n}=[${v:-__ABSENT__}];"
  done
  echo "$out"
}

# ── symbols 모드: const val NAME = "value" 중 지정된 이름만 뽑는다
symbols_map() {
  local file="$1" names="$2"
  [ -f "$file" ] || { echo "__ABSENT__"; return; }
  local out=""
  for n in $names; do
    local v
    v=$(grep -oE "const val ${n}[[:space:]]*=[[:space:]]*\"[^\"]*\"" "$file" | head -1 | sed -E 's/.*"([^"]*)"$/\1/')
    out="${out}${n}=${v:-__MISSING__};"
  done
  echo "$out"
}

report() { printf '  %-42s %s\n' "$1" "$2"; }

echo "장치 A — 형제 발산 탐지"
echo "정본: $SURFACES"
echo

# ── 표 파싱: | surface | path | repos | mode | expected_diff |
while IFS='|' read -r _ surface path repos mode expected _rest; do
  surface="$(echo "$surface" | sed -e 's/^ *//' -e 's/ *$//' -e 's/`//g')"
  path="$(echo "$path" | sed -e 's/^ *//' -e 's/ *$//' -e 's/`//g')"
  repos="$(echo "$repos" | sed -e 's/^ *//' -e 's/ *$//')"
  mode="$(echo "$mode" | sed -e 's/^ *//' -e 's/ *$//' -e 's/`//g' -e 's/\*//g')"
  expected="$(echo "$expected" | sed -e 's/^ *//' -e 's/ *$//')"

  [ -z "$surface" ] && continue
  case "$surface" in surface|---*|-*) continue ;; esac

  # 표 검증은 비교보다 먼저 한다.
  # 비교 결과 안에서 검사하면 "값이 우연히 같을 때" 잘못된 표가 조용히 통과한다
  # (④ 음성 시나리오 N-4 에서 실제로 그랬다).
  if [ -n "$expected" ] && [ "$expected" != "—" ] && [ "$expected" != "-" ]; then
    case "$mode" in
      symbols|deps|props)
        echo "표 거부: $mode 모드에는 expected_diff 를 둘 수 없다 ($surface)" >&2; exit 2 ;;
    esac
  fi

  # repos: "3" 이면 셋 다, 아니면 공백 구분 목록
  if [ "$repos" = "3" ]; then targets="public internal batch"; else targets="$repos"; fi

  sigs=""          # "repo\tsig" 줄 목록 (bash 3.2 에는 연관 배열이 없다)
  absent=""
  for r in $targets; do
    rp="$(repo_path "$r")" || { echo "알 수 없는 레포: $r ($surface)" >&2; exit 2; }
    base="$(repo_base "$r")"; pkg="$(repo_pkg "$r")"
    case "$mode" in
      full)
        # path 에 <BASE> 가 있으면 레포 루트 기준 경로로 치환한다(테스트 소스셋 파일 — props 와 같은 규칙). 없으면 main base package 이하.
        if echo "$path" | grep -q '<BASE>'; then
          f="$rp/$(echo "$path" | sed "s#<BASE>#$(echo "$base" | sed 's#src/main/kotlin/##')#")"
        else
          f="$rp/$base/$path"
        fi
        sig="$(normalize_md5 "$f" "$pkg")" ;;
      section) f="$rp/$(echo "$path" | cut -d'#' -f1)"; sig="$(section_md5 "$f" "$(echo "$path" | cut -d'#' -f2-)")" ;;
      symbols) f="$rp/$base/$(echo "$path" | cut -d'@' -f1)"; sig="$(symbols_map "$f" "$(echo "$path" | cut -d'@' -f2- | tr ',' ' ')")" ;;
      deps)    f="$rp/$(echo "$path" | cut -d'@' -f1)"; sig="$(deps_map "$f" "$(echo "$path" | cut -d'@' -f2- | tr ',' ' ')")" ;;
      props)
        # path 에 <BASE> 가 있으면 레포 base package 경로로 치환한다.
        # 테스트 소스셋(src/test/<set>/kotlin/<base>/…)은 main 과 경로 규칙이 다르다.
        rel="$(echo "$path" | cut -d'@' -f1 | sed "s#<BASE>#$(echo "$base" | sed 's#src/main/kotlin/##')#")"
        f="$rp/$rel"
        sig="$(props_map "$f" "$(echo "$path" | cut -d'@' -f2- | tr ',' ' ')")" ;;
      *) echo "알 수 없는 mode: '$mode' ($surface)" >&2; exit 2 ;;
    esac
    # 빈 추출을 서명으로 쓰면 "둘 다 아무것도 못 찾음" 이 SAME 으로 읽힌다 — fail-closed.
    EMPTY_MD5="d41d8cd98f00b204e9800998ecf8427e"
    if [ -z "$sig" ] || [ "$sig" = "$EMPTY_MD5" ] || [ "$sig" = "__ABSENT__" ]; then
      absent="$absent $r"
    fi
    sigs="${sigs}${r}	${sig}
"
  done

  if [ -n "$absent" ]; then
    report "$surface" "MISSING($(echo $absent))"
    MISSING=$((MISSING+1)); continue
  fi

  # deps 는 "좌표가 공통 표면이다" 라는 선언이다. 셋 다 없으면 표가 stale 한 것이지
  # 「일치」가 아니다 — 그대로 두면 전환 후 아무것도 감시하지 않으면서 SAME 으로 통과한다.
  if [ "$mode" = "deps" ] && ! printf '%s' "$sigs" | grep -qv '__MISSING__;$'; then
    report "$surface" "MISSING(전 레포에 좌표 없음 — 표가 낡았다)"
    MISSING=$((MISSING+1)); continue
  fi

  uniq_count=$(printf '%s' "$sigs" | awk -F'\t' 'NF>1{print $2}' | sort -u | wc -l | tr -d ' ')

  if [ "$uniq_count" -le 1 ]; then
    report "$surface" "SAME"; SAME=$((SAME+1))
  elif [ -n "$expected" ] && [ "$expected" != "—" ] && [ "$expected" != "-" ]; then
    report "$surface" "EXPECTED-DIFF($expected)"; EXPECTED=$((EXPECTED+1))
  else
    report "$surface" "DIVERGED($(echo $targets))"
    printf '%s' "$sigs" | awk -F'\t' 'NF>1{printf "      %-10s %s\n", $1, $2}'
    DIVERGED=$((DIVERGED+1))
  fi
done < <(sed -n '/^## 표면/,/^## /p' "$SURFACES" | grep '^|')

echo
echo "SAME=$SAME  EXPECTED-DIFF=$EXPECTED  DIVERGED=$DIVERGED  MISSING=$MISSING"

if [ $((DIVERGED + MISSING)) -gt 0 ]; then exit 1; fi
exit 0
