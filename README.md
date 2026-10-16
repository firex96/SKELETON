# SKELETON

**스켈레톤(프로젝트 템플릿) 레포**들의 문서/계획/메타 레포.

> **이 레포는 문서/계획/메타 정보만 관리합니다.** 실제 코드는 별도 git 레포에 있습니다 — 자세한 구조는 [Workspace Setup](#workspace-setup) 참고.

관리 대상 판정 기준은 단순합니다: **레포명에 `skeleton` 이 붙은 레포.** 새 스켈레톤 레포가 생기면 아래 표, [`CLAUDE.md`](CLAUDE.md), [`AGENTS.md`](AGENTS.md), `.claude/settings.json` 의 `additionalDirectories`, `.claude/cross-review-siblings`, `.gitignore` 에 함께 등록합니다.

> **현재 범위는 Kotlin 3종입니다.** `asp-net-core-skeleton`(공개판 기준 복귀 판정 전)과 `svelte-frontend-skeleton`(이 워크스페이스에 없음)은 **유보** 상태이며, 사유와 복귀 조건은 [`docs/deferred-scope.md`](docs/deferred-scope.md) 에 있습니다. 레포가 형제 위치에 있더라도 이 워크스페이스의 관리·리뷰 범위에서만 빠진 것입니다.

## 관리 대상 스켈레톤

| 레포 | 스택 | 역할 |
|------|------|------|
| `spring-boot-public-api-skeleton` | Kotlin 2.3, Spring Boot 4.1, JDK 21, JPA+JDBC, MapStruct, Flyway, Kotest+MockK+FixtureMonkey | 대외 공개 API 템플릿 |
| `spring-boot-internal-api-skeleton` | 동일 | 내부 API 템플릿 |
| `spring-batch-skeleton` | Kotlin 2.3, Spring Boot 4.1, Spring Batch 6.0, Quartz 2.5, Multi-DataSource | 배치 템플릿 |

## 스켈레톤을 다룰 때의 전제

1. **샘플 코드가 곧 규약의 정본입니다.** 예제는 데모가 아니라 파생 프로젝트가 그대로 복제할 레퍼런스 구현입니다.
2. **스켈레톤 변경은 기존 파생 프로젝트로 자동 전파되지 않습니다.** 이미 갈라져 나온 서비스 레포는 그대로이고, 신규 생성 프로젝트만 변경을 받습니다. 그래서 모든 변경 계획은 **파생 영향도 분류**를 포함합니다.
3. **형제 스켈레톤끼리 규약을 복제 보유합니다.** 한 곳만 고치면 나머지가 조용히 어긋납니다 — 이 워크스페이스에서 가장 흔한 결함입니다.

상세는 [`CLAUDE.md`](CLAUDE.md) 와 [`AGENTS.md`](AGENTS.md) 를 참고하세요.

### 설정값·비밀값 규칙

- 애플리케이션 yml 은 비밀값과 환경마다 달라지는 값을 **kebab-case 논리 키**(`${db-writer-password}`)로만 참조합니다. 값은 환경변수 또는 비밀값 출처 프로필 `aws`(Secrets Manager) · `azure`(Key Vault) · `gcp`(Secret Manager)가 채웁니다.
- 비밀에는 기본값을 두지 않습니다 — 키 오타·미등록은 기동 실패로 드러납니다. 자격증명 평문은 어느 yml 에도 적지 않으며 `local` 프로필의 docker compose 계정만 예외입니다. 로컬 인프라는 `docker compose up -d`, 통합 테스트는 Testcontainers 입니다.
- 예외는 프로필 활성화(`SPRING_PROFILES_ACTIVE`)·비밀 저장소 위치(`AWS_SECRET_ID` · `AZURE_KEYVAULT_ENDPOINT` · `GCP_PROJECT_ID`) 환경변수와, 테스트 소스셋의 고정 테스트 값 둘뿐입니다.

정본은 형제 스켈레톤 3종의 `.claude/rules/conventions.md` 「환경 설정」 아래 「설정값·비밀값 규약」(글자 단위 동일, `scripts/sibling-diff.sh` 감시)입니다 — 예: [`../spring-boot-public-api-skeleton/.claude/rules/conventions.md`](../spring-boot-public-api-skeleton/.claude/rules/conventions.md).

같은 문서의 「데이터베이스」(식별자 `Long`/`BIGINT`, 업무 DDL FK 제약 금지)와 「타입 선언」(Model·DTO·JdbcEntity 는 `data class` + `val`, JPA Entity 는 `class` + `var`; nullable 은 DB 컬럼과 일치·`!!` 금지·전부-기본값 금지·Model `@field:JsonProperty` 전수; MapStruct `unmappedTargetPolicy = ERROR` — non-null 타깃은 매핑 명시, `is`-prefix Boolean 은 `@Mapping` 명시; JPA Join 금지)도 세 스켈레톤 공통 규약입니다.

## 프로젝트 구조 (표준 레이아웃)

네 레포를 **동일한 부모 폴더 아래 형제로** 배치합니다. 부모 폴더 이름은 자유 (예: `Git`, `work`, `code`).

```
<any-parent>/
├── SKELETON/                                     ← 이 레포 (문서/계획)
│   ├── plans/ing/{slug}/                         # 진행 중 작업의 기획·구현·검증 문서
│   ├── plans/done/{slug}/                        # 완료 작업 (검증 리포트 + 커밋 도달 + 미결 0 이면 이동)
│   ├── docs/                                     # 안정적인 정책·아키텍처 문서
│   ├── .claude/settings.json                     # additionalDirectories + 체크포인트3 훅
│   ├── .claude/hooks/                            # PostToolUse(ExitPlanMode) / PreToolUse(Write|Edit|Bash)
│   ├── .claude/scripts/cr-checkpoint3.sh          # ③ 구현계획 게이트 attestation
│   ├── .claude/cross-review-siblings             # 크로스리뷰 대상 형제 레포 (글로벌 내장 테이블보다 우선)
│   ├── .codex/review-*.md                        # Codex 리뷰 루브릭 (계획/설계/코드·보안)
│   ├── .agents/skills/*/SKILL.md                 # Antigravity 리뷰 루브릭 4종
│   ├── CLAUDE.md                                 # Claude Code 진입 컨텍스트
│   ├── AGENTS.md                                 # Codex·Antigravity 공통 중립 사실 + binding
│   ├── CROSS-REVIEW.md                           # 4-체크포인트 크로스리뷰 워크플로우
│   └── README.md
│
├── spring-boot-public-api-skeleton/              ← 별도 git 레포 (이 레포에서 .gitignore 됨)
├── spring-boot-internal-api-skeleton/            ← 별도 git 레포
└── spring-batch-skeleton/                        ← 별도 git 레포
```

각 레포는 독립적이며 자기 git 히스토리를 갖습니다. Claude Code 는 `SKELETON/.claude/settings.json` 의 `permissions.additionalDirectories` 에 **상대경로**(`../*-skeleton`)로 등록되어 있어, 이 레이아웃을 따라야 모든 머신에서 동일하게 동작합니다.

> ⚠️ **표준 레이아웃을 벗어나면 Claude 가 형제 레포에 접근하지 못합니다.** 폴더명을 바꾸거나 다른 경로에 clone 하지 마세요.

## Workspace Setup

신규 머신 또는 합류자 셋업 — **네 레포가 같은 부모 폴더의 형제가 되도록** clone:

```bash
# 부모 폴더는 어디든 무방 (예시: ~/Source/Git)
mkdir -p ~/Source/Git && cd ~/Source/Git

# 1) 문서/계획 레포 (이 레포)
git clone https://github.com/firex96/SKELETON.git

# 2) 스켈레톤 코드 레포 (형제 위치에)
git clone https://github.com/firex96/spring-boot-public-api-skeleton.git
git clone https://github.com/firex96/spring-boot-internal-api-skeleton.git
git clone https://github.com/firex96/spring-batch-skeleton.git

# 3) 검증 — 네 폴더가 형제로 보여야 함
ls -d SKELETON spring-*-skeleton
```

clone 후 첫 Claude Code 세션에서 `additionalDirectories` 가 정상 해석되는지 한 번 확인하세요(형제 레포의 파일 Read 시도).

## 빌드·검증 명령

변경한 레포만 실행합니다. 단 **규약 전파 변경은 반영한 레포를 전부** 실행합니다.

```bash
# Kotlin 3종 — ktlint 강제, 커밋 전 필수
cd ../spring-boot-public-api-skeleton   && ./gradlew ktlintFormat && ./gradlew build
cd ../spring-boot-internal-api-skeleton && ./gradlew ktlintFormat && ./gradlew build
cd ../spring-batch-skeleton             && ./gradlew ktlintFormat && ./gradlew test && ./gradlew integrationTest
```

- `./gradlew test` = 유닛만(`src/test/unit`). `integrationTest` 는 **Docker 필요**(Testcontainers MySQL). `check` = `ktlint + test + integrationTest`(3종 공통). public/internal API 의 `e2eTest` 는 `docker compose up -d` 선행, `check` 에 묶지 않습니다.
- 각 레포의 세부 명령·주의사항 정본은 해당 레포의 `CLAUDE.md` 입니다.

## 브랜치 전략

- `main`: 기본 브랜치
- 작업은 feature 브랜치에서 진행하고, 여러 스켈레톤에 걸친 전파 작업은 `plans/ing/{slug}/` 에 각 레포 PR 링크를 함께 기록합니다 (예: "public-api PR #12 / internal-api PR #8 / batch PR #5").

## 문서 가이드

| 문서 | 용도 |
|------|------|
| [`CLAUDE.md`](CLAUDE.md) | Claude Code 진입 컨텍스트 (매 세션 자동 로드) — 워크스페이스 구조, 파생 영향도 분류, 형제 동기화 규칙, 검증 명령, 산출물 분리 원칙 |
| [`AGENTS.md`](AGENTS.md) | Codex·Antigravity 공통 중립 사실 + 리뷰어 Current binding |
| [`CROSS-REVIEW.md`](CROSS-REVIEW.md) | 4-체크포인트 크로스리뷰 워크플로우, 티어링, 레포별 결정적 검증 렌즈 |
| `.codex/review-*.md` | Codex 리뷰 루브릭 (계획 / 설계 / 코드·보안) |
| `.agents/skills/*/SKILL.md` | Antigravity 리뷰 루브릭 (계획 / 설계 / 코드 / 런타임) |
| `plans/ing/{slug}/` | **진행 중** 작업의 기획·구현·검증 산출물. 새 작업은 여기서 시작하고, 게이트 명령도 이 경로를 인자로 받습니다 (`/cross-review ing/{slug}`) |
| `plans/done/{slug}/` | **완료** 작업. 검증 리포트가 있고 · 관련 커밋이 대상 브랜치에 들어갔고 · 미결 항목이 없거나 티켓으로 이관됐을 때 `git mv` 로 옮기며, `docs/`·루트 지침의 링크를 같은 커밋에서 갱신합니다 (이동한 문서 내부의 옛 경로는 기록으로 둡니다) |
| [`docs/deferred-scope.md`](docs/deferred-scope.md) | 관리 범위에서 유보한 스켈레톤 — 사유·확인된 사실·복귀 조건 |
| [`docs/mapstruct-kotlin-constructor-mapping.md`](docs/mapstruct-kotlin-constructor-mapping.md) | MapStruct × Kotlin data class — `val` 이 조용히 비는 조건(전부 기본값 → no-arg 생성자), 규약, 검출 테스트 |
| `docs/` | 안정적인 정책·아키텍처 문서 |


## MySQL 스키마 범위

- 로컬 MySQL 은 각 형제 레포의 `docker compose up -d` 로 띄웁니다. 업무 테이블 DDL 정본은 각 레포 `src/main/resources/db/manual/create-*.sql`(docker compose 초기화·Testcontainers 공용)입니다.
- Flyway 는 public-api 의 `skeleton_auth` 와 batch 의 `skeleton_batch` 만 관리합니다. internal-api 는 Flyway 를 쓰지 않습니다.
- 계정은 공통 `skeleton_reader`/`skeleton_writer`(런타임)와 `skeleton_admin`(Flyway)입니다. 문자셋·콜레이션은 `utf8mb4` / `utf8mb4_0900_ai_ci` 입니다.
- 세부 정본은 각 레포 `CLAUDE.md` 「MySQL 스키마 및 계정」입니다.
