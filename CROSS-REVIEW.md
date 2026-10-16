# 크로스 리뷰 워크플로우 — SKELETON (스켈레톤 워크스페이스 — Kotlin 3레포 + ASP.NET Core 1레포)

> Claude Code 가 작성·구현·결정적 검증을 담당하고 Codex 가 독립 승인 리뷰를 수행한다.
> Antigravity 는 계획·설계·코드 승인 리뷰와 **읽기 전용 실패 시나리오 생성자·Major/Critical finding 의 인접 결함 탐색자**로 사용한다.
> 메타 파일은 git 추적, 판정 출력(`.claude/review-out`)만 로컬. 래퍼는 글로벌(`~/.claude/scripts/`), ③ attestation 만 프로젝트 로컬(`.claude/scripts/cr-checkpoint3.sh`)이다.

## 진입점

- `/cross-review ing/<slug>` — 글로벌 크로스리뷰 계약(`~/.claude/skills/cross-review/SKILL.md`)을 그대로 따른다. 이 레포는 전용 entry point 를 두지 않는다. **슬러그 인자는 `ing/<slug>` 로 준다** — 글로벌 스킬이 `plans/$1/…` 를 조립하므로, 진행 중 산출물이 `plans/ing/` 아래 있는 이 레포에서는 그렇게 넣어야 경로가 맞는다(스킬 수정 없이 동작).
- ③ 구현 계획 게이트는 `bash .claude/scripts/cr-checkpoint3.sh plans/ing/<slug>/구현_설계.md` 로 attestation 한다.
- **①②④ 게이트를 직접 돌리는 명령은 글로벌 래퍼 `cr-gate.sh` 다.** `/cross-review` 가 부르는 것과 같은 것이며, 재현·자동화를 위해 여기 적는다. **`plan`·`design` 은 대상 인자가 필수**이고(`cr-codex.sh` 가 `${1:?}` 로 요구한다) `code`·`runtime` 은 대상이 워크스페이스 전체라 인자가 없다.
  ```bash
  bash ~/.claude/scripts/cr-gate.sh plan   plans/ing/<slug>/설계_계획.md  # ①
  bash ~/.claude/scripts/cr-gate.sh design plans/ing/<slug>               # ② 파일 또는 디렉터리
  bash ~/.claude/scripts/cr-gate.sh code                                  # ④
  ```
  통과 조건은 `plan`·`design` 이 마지막 비공백 줄 `DECISION: Approve`, `code` 가 `VERDICT: PASS` 이며, 요약 줄의 `CR-GATE-RESULT: APPROVED` 로 판정한다. **`status=OK` 는 실행 형식이 정상이라는 뜻일 뿐 승인이 아니다.** 이 명령이 문서에 없으면 ① 에서 「게이트 명령이 정본과 불일치」로 blocking 된다.
- 리뷰어 binding 의 정본은 [`AGENTS.md`](AGENTS.md) 의 **Current binding** 표다 — R1=Claude(main) / R2=Codex / R3=Antigravity.
- **④ code 게이트의 리뷰 대상에는 이 레포(`.`) 자신이 포함된다** — 형제 3레포 + SKELETON. 리뷰어가 확인해야 하는 **형제 스윕 근거**(`plans/ing/{slug}/구현_설계.md` 의 검색 패턴·대상 경로·hit별 판정)가 이 레포에 있기 때문이다. 다른 메타 워크스페이스는 `plans/` 를 코드 리뷰에서 배제할 수 있지만 SKELETON 은 반대로 간다 — 스윕 근거가 리뷰의 **필수 입력**이다. `.` 을 빼면 ④ 에서 "스윕 근거가 컨텍스트에 없다" 가 반복 blocking 된다.

## 이 레포 구성

SKELETON — **워크스페이스 오케스트레이터**. 실제 코드는 형제 스켈레톤 3개(크로스리뷰 대상 해석은 `.claude/cross-review-siblings`):

- `../spring-boot-public-api-skeleton` — Kotlin 2.3 / Spring Boot 4.1 / JDK21 (대외 API 템플릿)
- `../spring-boot-internal-api-skeleton` — Kotlin 2.3 / Spring Boot 4.1 / JDK21 (내부 API 템플릿)
- `../spring-batch-skeleton` — Spring Boot 4.1 / Spring Batch 6.0 / Quartz 2.5, Multi-DataSource (배치 템플릿)
- `../asp-net-core-skeleton` — .NET · ASP.NET Core + SPA, `dotnet new` 템플릿. 작업은 당분간 그 레포에서 진행하고, 이 워크스페이스는 리뷰 대상 해석만 맡는다. 규약 정본은 그 레포 `CLAUDE.md`

관리 대상 판정 기준: **레포명에 `skeleton` 이 붙은 레포.** 산출물(설계 계획·기획서·테스트 시나리오·구현 설계·리뷰 이력·검증 리포트)은 진행 중이면 `plans/ing/{slug}/`, 완료되면 `plans/done/{slug}/` 에 누적(추적). 완료 판정과 이동 규칙은 [`CLAUDE.md`](CLAUDE.md) 「작업 산출물 위치」.

> `svelte-frontend-skeleton` 은 **유보** 상태다(사유·복귀 조건: [`docs/deferred-scope.md`](docs/deferred-scope.md)). 크로스리뷰 대상이 아니다.

## 스켈레톤 특유의 리뷰 전제 (다른 레포와 다른 부분)

1. **샘플 코드 = 규약의 정본.** 예제 코드의 규약 위반은 파생 프로젝트 전체로 복제된다 — "샘플이니까"로 심각도를 낮추지 않는다.
2. **파생 영향도 분류가 필수 요건이다.** 스켈레톤 변경은 기존 파생 프로젝트로 자동 전파되지 않는다. 분류(스켈레톤 전용 / 규약 변경 / 보안·결함 수정)와 그에 맞는 요건이 없으면 blocking. 상세는 [`AGENTS.md`](AGENTS.md) §파생 영향도 분류.
3. **형제 스켈레톤 동기화가 1급 결함 클래스다.** 공통 표면을 한 레포에서만 고친 변경은 그 자체로 blocking 후보다. 통과하려면 `rg` 스윕의 **검색 패턴·대상 경로·hit별 `반영/해당 없음/보류(사유)`** 가 기록돼 있어야 한다.

## 4개 체크포인트 (계획 → 산출물, 두 번 반복)

| # | 체크포인트 | 산출물 | 승인 리뷰 | 통과 조건 |
|---|-----------|--------|-----------|------|
| 1 | **설계 계획** | 작업 계획(팀 구성·접근법·전파 대상 분류) | **R2 + R3** (main 불참) | 양쪽 Approve + Major 이상 disposition |
| 2 | **설계 산출물** | 기획서(레포별) · 테스트 시나리오 | **R1 + R2 + R3** | 셋 다 Approve + Major 이상 disposition |
| 3 | **구현 계획** | 구현_설계(변경 파일·시그니처·DDL·**전파 계획**·테스트 계획) | **R2 + R3** (main 불참) | 양쪽 Approve → `cr-checkpoint3.sh` = `APPROVED` |
| 4 | **구현 산출물** | ① 코드 ② 테스트 코드 | 코드·보안=**R1+R2+R3** / 런타임=**결정적 검증(R1)** + R3 | 코드 리뷰 PASS + 결정적 검증 PASS + Major 이상 disposition |

**UI 산출물(목업)은 asp-net-core SPA 화면을 바꾸는 작업에서만 ② 에 포함한다.** Kotlin 3종에는 UI 가 없다.

## 왜 역할을 분리하는가

- **계획 리뷰(①·③) = R2+R3 승인, main 제외** (자기 계획 자가승인 방지).
- **산출물 리뷰(②·④) = main 동참.** 단 **main 의 PASS 가 R2/R3 의 FAIL 을 덮지 못한다**.
- **구현 산출물(④) 렌즈 분리.** 코드·보안은 R1+R2+R3, 런타임은 R1 이 실제 명령과 관찰값으로 판정한다.
- evidence-backed Critical/Major 후보는 `VALIDATED`, `DISMISSED — 근거`, `DEFERRED — 티켓/담당/시점` 중 하나로 disposition 하기 전까지 통과시키지 않는다.

## Major/Critical 인접 결함 스윕

구체적인 Major/Critical finding 이 확정되면, 수정 전에 같은 근본 원인·패턴·경계의 형제 지점을 찾는다.

1. **결함 클래스를 한 줄로 명시한다.** "이 파일의 이 줄"이 아니라 "무엇이 무엇과 어긋나는 종류의 결함인가"로 적는다.
2. **결정적으로 스윕한다.** 그 클래스에 대응하는 `rg` 패턴을 **형제 스켈레톤 3개 전부**에 적용하고, 검색 패턴·대상 경로·모든 hit 의 `수정/해당 없음/보류` 판단을 남긴다. 눈으로 훑어 "없는 것 같다"는 근거가 되지 않는다.
3. **시드와 검증된 형제 지점을 한 패치로 수정**한 뒤 관련 테스트와 재리뷰를 실행한다.

> **이 레포에서 스윕 범위는 기본이 Kotlin 3레포 전체다.** 결함 클래스가 언어와 무관하면(인가 누락·비밀값 폴백·계층 우회 등) asp-net-core 도 스윕한다. 스켈레톤은 규약을 복제 보유하므로, 한 레포에서 발견된 결함 클래스는 형제에도 있다고 가정하는 편이 사실에 가깝다. 규약 변경·보안 결함이면 이 스켈레톤에서 생성한 기존 파생 프로젝트까지 스윕 범위를 넓히고, 넓히지 않았다면 **그 사실과 사유**를 남긴다.

후보가 없다고 승인하지 않는다. 근거가 부족하면 리뷰어 결과는 `INCOMPLETE` 이며, main 의 결정적 스윕도 생략하지 않는다.


## ④ 착수 전 확인 (장치 C)

크로스리뷰의 판정은 **리뷰어가 본 것**에만 근거한다. 산출물이 아니라 **리뷰 입력**이 비어 있으면 아무리 고쳐도 같은 지적이 반복된다.

| 확인 | 방법 |
|---|---|
| 리뷰 대상에 **스윕 근거가 있는 레포**가 포함됐는가 | `cr-targets.sh` 의 이 워크스페이스 항목에 `.`(SKELETON) 이 있는지. 스윕 기록은 `plans/ing/{slug}/구현_설계.md` 에 있다 |
| 그 근거가 **실제로 컨텍스트에 들어갔는가** | `.claude/review-out/code-context.md` 에서 해당 경로 언급을 **센다**. 0 이면 리뷰어는 그것을 보지 못한다 |

> **같은 지적이 3회 반복되면 산출물이 아니라 리뷰 입력을 의심한다.**
>
> 예: ④ 에서 「스윕 근거가 컨텍스트에 없다」가 라운드마다 반복될 때 문서를 더 쓰는 것으로는 풀리지 않는다. 원인이 리뷰 대상 해석에서 SKELETON 자신(`.`)이 빠진 것이라면 `code-context.md` 의 SKELETON 언급 수가 0 이다 — 실제로 세어 본다.

## 레포별 결정적 검증 렌즈 (④)

| 레포 | 런타임 검증 |
|--------|------------|
| `spring-boot-public-api-skeleton` | `ktlintFormat` + `build` + `check`(ktlint+test+integrationTest) + `e2eTest`(docker compose 선행) + 변경 엔드포인트 curl/Swagger |
| `spring-boot-internal-api-skeleton` | 동일 |
| `spring-batch-skeleton` | `ktlintFormat` + `test` + `integrationTest`(Docker) + **Job 트리거** 확인(스케줄러 기동 후 수동 트리거)·멱등성 |
| `asp-net-core-skeleton` | `dotnet build` + `dotnet test --solution`(IntegrationTests 는 Docker) + 바꾼 SPA `npm run build`·`npm test` + 변경 엔드포인트 확인 + 템플릿을 바꿨으면 custom hive 로 `dotnet new` 실생성 |

추가 결정적 검증은 변경 표면에 따라 적용한다.

- **스캐폴딩 유효성**: 템플릿에서 새 프로젝트를 만드는 절차가 바뀌었으면 그 절차를 **실제로 한 번 실행**해 통과를 확인한다. 문서만 고치고 끝내지 않는다.
- **규약 전파**: 형제 스켈레톤 반영 후 **각 레포에서 빌드·테스트를 각각** 돌린다. 한 레포만 돌리고 "동일 변경이므로 통과"로 간주하지 않는다.
- **migration**: 폐기 가능한 로컬/격리 DB 에서 validate 및 dry-run/migrate.
- **API 계약**: 생성 OpenAPI 또는 Controller 계약 테스트의 기준선 비교.
- nullability·트랜잭션 diff 패턴은 결함 확정이 아닌 정적 경보이며 테스트로 최종 판정.

## 빌드·검증 명령 (형제 레포에서)

```bash
cd ../spring-boot-public-api-skeleton   && ./gradlew ktlintFormat && ./gradlew build
cd ../spring-boot-internal-api-skeleton && ./gradlew ktlintFormat && ./gradlew build
cd ../spring-batch-skeleton             && ./gradlew ktlintFormat && ./gradlew test && ./gradlew integrationTest
cd ../asp-net-core-skeleton             && dotnet build AspNetCoreSkeletonApplication.slnx && dotnet test --solution AspNetCoreSkeletonApplication.slnx
```

`integrationTest` 는 Docker 필요(Testcontainers MySQL). 변경한 레포만 돌린다 — 단, **규약 전파 변경은 반영한 레포를 전부** 돌린다.

## 핵심 규칙 (리뷰 시 참고)

[`AGENTS.md`](AGENTS.md) §핵심 규칙 과 동일하며, 그쪽이 정본이다. 요약: 명명 규칙(Enum 접미사 없음 / `Configuration` 접미사 / 명시적 DataSource 이름 / `enums/` 패키지) · 약어 금지 · 레이어드 계층 우회 금지 · Model/DTO/Entity 분리 · 1 Class per 1 File · 클래스 레벨 `@Transactional(readOnly = true)` · Spring Boot 4.1/Batch 6.0 패키지 재배치 · Jackson 3 · 설정값·비밀값은 kebab-case 논리 키 참조(환경변수 또는 aws·azure·gcp 출처 프로필, 비밀은 기본값 없음, 예외 둘) · 식별자 `Long`/`BIGINT` · 업무 DDL FK 제약 금지 · Model `@field:JsonProperty` 전수·생성자 매핑(전부-기본값 금지) — 정본은 각 스켈레톤 `.claude/rules/conventions.md`. .NET 규칙의 정본은 `../asp-net-core-skeleton/CLAUDE.md`.

## 티어링 (효율 밸브)

| 변경 성격 | 적용 체크포인트 |
|----------|----------------|
| 타이포/1줄/문서 | ④ 만 |
| 버그픽스/리팩터/additive (단일 스켈레톤 내부) | ③④ |
| **규약 변경 / 형제 스켈레톤 전파 / 스캐폴딩 구조 변경** | ①②③④ 전체 |

판단 규칙: **"파생 프로젝트가 따라야 하는 규약·구조를 바꾸나?"** Yes 면 설계(①②)까지.

> 스켈레톤에서는 "작은 변경"의 기준이 다르다. 코드 몇 줄이라도 **파생 프로젝트가 복제할 규약**을 건드리면 전체 티어다.

구현 계획에는 티어를 훅이 판별할 수 있도록 `<!-- CHECKPOINT3: required -->`(③④) 또는 `<!-- CHECKPOINT3: not-required -->`(④만)를 포함한다. marker 가 없으면 fail-closed 로 pending 이다. `required` 계획은 `cr-checkpoint3.sh` 가 `CR-CHECKPOINT3-STATUS: APPROVED` 를 낸 뒤에야 코드 변경을 시작할 수 있다.

## STATUS 와 판정은 다른 축이다

- `CR-CODEX-STATUS: OK` / `CR-ANTIGRAVITY-STATUS: OK` 는 **실행 형식이 정상**이라는 뜻일 뿐 **승인이 아니다.**
- 통과는 **판정 파일의 마지막 비공백 줄**로만 판단한다 — ①②③ 은 `DECISION: Approve`, ④ 는 `VERDICT: PASS`.
- 그 판정은 **이번 실행이 만든 것**이어야 한다. 직전 라운드의 판정 파일·status 사이드카를 재사용해 통과시키지 않는다.

## 프롬프트·명령·실패 처리

- Codex: 계획 `.codex/review-plan.md` / 설계 `.codex/review-design.md` / 코드·보안 `.codex/review-correctness-security.md`.
- Antigravity: `.agents/skills/{plan-review,design-doc-review,code-review,runtime-verification}/SKILL.md`. 래퍼는 글로벌 `~/.claude/scripts/`.
- 판정 결과: `.claude/review-out/{codex,antigravity}-{plan|design|code|runtime}.md` (+ `.status` 사이드카). gitignore 대상.
- Antigravity 는 레포 읽기/검색만 수행하고 stdout 만 반환한다. 결과·로그·상태 파일은 Claude 측 래퍼가 작성한다.
- `INCOMPLETE`/`OFFTASK`/실행 실패는 권한 확대나 main 대행 PASS 없이 `unavailable` 로 기록한다.
- 엔진이 없으면 독립 승인 자체가 없는 것이므로 계획/설계/코드 체크포인트를 조건부 통과로 둔갑시키지 않는다. ③ 의 엔진별 폴백(`CR_CP3_ALLOW_{CODEX,AGY}_UNAVAILABLE=1`)은 **엔진이 실제로 unavailable 할 때** 사용자가 의식적으로 켜는 것이며, 폴백 사용은 `checkpoint3-gate.json` 에 기록된다.
