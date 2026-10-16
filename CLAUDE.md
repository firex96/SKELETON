This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

본 파일은 매 세션 컨텍스트로 로드된다. **SKELETON 워크스페이스 진입 컨텍스트**.

---

## 정체성

**SKELETON** = 스켈레톤(프로젝트 템플릿) 레포들의 **워크스페이스 오케스트레이터**. 이 레포는 계획·설계·리뷰 메타만 관리하고, 실제 코드는 형제 스켈레톤 레포에 있다.

**관리 대상 = 레포명에 `skeleton` 이 붙은 레포.** 새 스켈레톤 레포가 생기면 이 문서의 표와 `.claude/settings.json` 의 `additionalDirectories` 에 함께 등록한다. 크로스리뷰 대상은 `.claude/cross-review-siblings` 에도 등록한다(글로벌 `cr-targets.sh` 내장 테이블보다 우선한다).

> 현재 관리 범위는 **Kotlin 3종 + ASP.NET Core 1종**(`asp-net-core-skeleton`)이다. asp-net-core 작업은 당분간 그 레포에서 직접 진행하고, 이 워크스페이스는 등록·크로스리뷰 대상 연결까지만 맡는다. `svelte-frontend-skeleton`(이 워크스페이스에 없음)은 **유보** 상태이며, 사유·복귀 조건은 [`docs/deferred-scope.md`](docs/deferred-scope.md) 에 있다.

### 스켈레톤이 일반 서비스 레포와 다른 점 (모든 판단의 전제)

1. **샘플 코드가 곧 규약의 정본이다.** 스켈레톤의 예제 코드는 "돌아가기만 하면 되는 데모"가 아니라 파생 프로젝트가 그대로 복제할 **레퍼런스 구현**이다. 샘플이 규약을 어기면 그 위반이 모든 파생 프로젝트로 복제된다 — 샘플 코드의 규약 위반은 프로덕션 결함과 같은 등급으로 다룬다.
2. **변경은 기존 파생 프로젝트로 자동 전파되지 않는다.** 스켈레톤을 고쳐도 이 스켈레톤에서 이미 생성해 갈라져 나온 서비스 레포는 그대로다. 신규 생성 프로젝트만 변경을 받는다. → **파생 영향도 분류**가 필수다(아래).
3. **형제 스켈레톤끼리 규약을 복제 보유한다.** 한 곳만 고치면 나머지가 조용히 어긋난다 — 이 워크스페이스에서 가장 흔한 결함 클래스다(아래).

## Workspace 구조 (메타 + 코드레포 분리)

이 레포(`SKELETON`)는 **문서/계획/메타만** 관리한다. 실 코드는 형제 레포에 있고, 워크스페이스는 참조만 한다.

```
<any-parent>/
├── SKELETON/                                     ← 이 레포 (plans·docs·계획) — 메타/전파 작업 진입점
├── spring-boot-public-api-skeleton/              ← 형제 (Kotlin 2.3 / Spring Boot 4.1 / JDK21, 대외 API)
├── spring-boot-internal-api-skeleton/            ← 형제 (Kotlin 2.3 / Spring Boot 4.1 / JDK21, 내부 API)
├── spring-batch-skeleton/                        ← 형제 (Kotlin 2.3 / Spring Boot 4.1 / Spring Batch 6 / Quartz)
└── asp-net-core-skeleton/                        ← 형제 (.NET · ASP.NET Core + SPA, `dotnet new` 템플릿)
```

### Claude 실행 경로

| 작업 유형 | 실행 위치 | 이유 |
|---|---|---|
| 규약 변경·형제 스켈레톤 동시 반영·계획/설계 | `SKELETON/` | plans + 형제 스켈레톤 전부(additionalDirectories) 한 컨텍스트 |
| 단일 스켈레톤 내부 작업 | 해당 형제 레포 또는 `SKELETON/` | 해당 레포의 `CLAUDE.md` 가 컨텍스트 |
| asp-net-core 작업 | 당분간 `../asp-net-core-skeleton` | 그 레포 `CLAUDE.md` 가 정본. 이 레포는 크로스리뷰 대상 해석·관리 대상 등록만 맡는다 |

- 형제 레포는 `.claude/settings.json` `additionalDirectories` 등록 + `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`. Kotlin 3종은 각자 `CLAUDE.md` 를 갖고 있고 **그 파일이 해당 스켈레톤 규약의 정본**이다 — 만지기 전에 읽는다.
- **레포를 변경하면 그 레포 `CLAUDE.md`·`README.md` 를 같은 커밋에서 동기화한다.**
- 사용자에게 경로 표기 시 상대경로(`../spring-batch-skeleton/...`) 우선.
- 코드 커밋은 **해당 형제 레포에서만** 한다. 이 레포는 형제 코드를 추적하지 않는다(`.gitignore`). 형제 레포에서 git 명령을 쓸 때는 반드시 그 경로로 `cd` 한 뒤 실행한다.

## 파생 영향도 분류 (CRITICAL — 계획·설계·구현 전 단계에서 요구)

스켈레톤의 "소비자"는 두 종류이고 **취급이 다르다.**

| 소비자 | 전파 방식 | 요건 |
|---|---|---|
| **미래 프로젝트** (앞으로 이 스켈레톤에서 생성) | 자동 — 머지되면 반영 | 별도 조치 없음 |
| **기존 파생 프로젝트** (이미 갈라져 나온 서비스 레포) | **자동 전파 없음** | 아래 분류·요건 필수 |

변경 계획은 **전파 대상 분류**를 먼저 적는다. 분류가 없으면 리뷰어는 blocking 으로 지적한다.

- **스켈레톤 전용** — 샘플 코드·문서·스캐폴딩·빌드 설정 등 파생 프로젝트가 자기 것을 이미 갖고 있는 표면. 조치 불필요. **근거를 한 줄 남긴다.**
- **규약 변경** — 명명 규칙, 레이어 계약, 공통 유틸/설정 클래스 시그니처, 테스트 배치 규칙 등 파생 프로젝트도 따라야 하는 표면. **형제 스켈레톤 동시 반영 + 기존 파생 프로젝트 반영 계획(대상 레포 목록·시점·담당)** 이 없으면 blocking.
- **보안·결함 수정** — 파생 프로젝트에 **같은 결함이 복제돼 있는지** 스윕 범위와 결과(대상 레포·검색 패턴·hit별 판단)를 남긴다. "스켈레톤만 고쳤다"로 끝내지 않는다.

분류와 잔여 리스크 수용의 **최종 판정자는 사용자**다. 리뷰어는 분류 누락·요건 부재를 blocking 으로 지적한다.

## 형제 스켈레톤 동기화 (1급 결함 클래스)

Kotlin 3종(`public-api` / `internal-api` / `batch`)은 같은 규약을 **각자 복제 보유**한다. 현재 확인된 복제 표면:

- 각 레포 `CLAUDE.md` 의 「공통 명명 규칙 (모든 스켈레톤 프로젝트 공통)」 표 — 3곳 동일
- 「미결 항목 처리」 절 — 3곳 동일 (스켈레톤 밖 파생 레포까지 포함하면 더 넓다)
- 테스트 3분류(`src/test/unit` · `src/test/integration` · `src/test/e2e`)와 Gradle task 구성
- `util/` · `config/` · `exception/` 의 공통 클래스, `StringEnum`/`AbstractStringEnumConverter` 패턴
- 각 레포 `.claude/rules/conventions.md` 의 「데이터베이스」「타입 선언」 두 절과 「환경 설정」 아래 「설정값·비밀값 규약」 하위 절 — 3곳 동일 (`section` 표면)
- `config/MapstructConfiguration.kt`(`unmappedTargetPolicy = ERROR`) — 3곳 동일, `persistence/jdbc/entity/main/ProductJdbcEntity.kt` — public·internal 2곳 동일 (`full` 표면. batch 는 같은 엔티티를 `sub/` 에 둔다)

**규칙:** 공통 표면을 고쳤으면 **같은 작업 안에서** 형제 스켈레톤 전부를 `rg` 로 스윕하고, hit 별로 `반영 / 해당 없음 / 보류(사유)` 를 남긴다.

**스윕만으로는 부족하다 — 두 장치를 함께 돌린다.**

| 장치 | 목적 | 명령 |
|---|---|---|
| **A 발산 탐지** | 형제가 **서로 달라진 것** | `bash scripts/sibling-diff.sh` — 발산 있으면 exit 1 |
| **B 복제 결함 탐지** | 형제가 **셋 다 똑같이 틀린 것** | `bash scripts/contract-coverage.sh --repo <public\|internal\|batch>` — 규약 표면에 그것을 지나가는 테스트가 있는지. 없거나 **실행되지 않으면** FAIL. public·internal 은 e2e 때문에 그 레포의 `docker compose up -d` 를 먼저 띄운다(세 compose 가 같은 호스트 포트를 써서 레포마다 하나씩 돌린다). 6379 를 다른 컨테이너가 쓰고 있으면 `REDIS_PORT=6380 docker compose up -d` 처럼 바꿔 띄우고, 실행할 때도 같은 값을 준다(`REDIS_PORT=6380 bash scripts/contract-coverage.sh --repo public`) — compose 포트와 `local` 프로필의 `redis-port` 가 둘 다 이 변수를 읽는다 |

정본 표는 [`docs/contract-surfaces.md`](docs/contract-surfaces.md) 다.

**B 가 필요한 이유**: 대조는 「셋 다 똑같이 틀린 것」을 통과시킨다. `spring-boot-411-upgrade` 에서 파생까지 퍼진 결함 5건이 전부 그랬고, 공통점은 **테스트가 없었다**는 것이다. 그중 하나(`TraceIdFilter`)는 **파일이 있는데 실행되지 않는** 상태였다 — B 의 「도달」검사가 그것을 잡는다.

`rg` 로 스윕할 때 **alternation 을 `\|` 로 쓰지 않는다.** rust regex 에서 그것은 리터럴 파이프이며, 어떤 항목도 찾지 못하고 **hit 0 이 「해당 없음」으로 기록된다.** 대안은 `-e` 를 여러 번 쓴다. 같은 이유로 zsh 에서 `for d in $LIST` 도 쓰지 않는다(단어 분할이 일어나지 않는다). 눈으로 훑어 "없는 것 같다"는 근거가 되지 않는다 — 검색 패턴·대상 경로·hit별 판단이 기록으로 남아야 "다 훑었다"가 성립한다.

형제 동기화는 장치 A·B 와 `rg` 스윕으로만 한다 — 파일을 복사하는 스크립트는 「셋 다 똑같이 틀린 것」을 퍼뜨리는 도구라 두지 않는다.

**장치 A·B 와 복제 표면은 Kotlin 3종 전용이다.** `asp-net-core-skeleton` 은 같은 규약 계열(계층 `Controller → MappingService → BizService → EntityService`, 비밀값 출처 프로필, 테스트 3분류)이지만 언어가 달라 파일 대조 대상이 아니다. 규약을 개념 수준에서 바꾸는 변경이면 asp-net-core 를 **수동 대조 대상**으로 계획에 적고, 반영 여부를 hit 판정과 같은 형식(`반영 / 해당 없음 / 보류(사유)`)으로 남긴다.

## 작업 산출물 위치 (plans/)

- **`plans/ing/<slug>/`** — 진행 중. 새 작업은 여기서 시작한다. 게이트 명령의 인자도 이 경로다: `bash .claude/scripts/cr-checkpoint3.sh plans/ing/<slug>/구현_설계.md`, `/cross-review ing/<slug>`(글로벌 스킬이 `plans/$1/` 를 조립하므로 슬러그에 `ing/` 를 붙인다).
- **`plans/done/<slug>/`** — 완료. **완료 판정은 셋이 모두 성립할 때다**: 검증 리포트가 있다 · 관련 커밋이 대상 브랜치(형제 레포 `main`)에 들어갔다 · 미결 항목이 없거나 티켓(식별자·담당·시점)으로 이관됐다. 이동은 `git mv` 로 하고, **살아 있는 문서**(`docs/`·루트 지침·`CROSS-REVIEW.md`)의 링크를 같은 커밋에서 갱신한다. 이동한 플랜 문서 **내부**의 옛 경로 서술은 기록이므로 고치지 않는다.
- 훅·스크립트는 경로에 의존하지 않는다(`cr-checkpoint3.sh` 는 인자 경로, 편집 게이트 훅의 `plans/*` 는 하위 경로 포함). 규칙을 바꿀 때 코드를 고칠 필요는 없고 이 절과 `README.md` 「문서 가이드」를 함께 고친다.

## 구현 계획 체크포인트 3

- 버그픽스/리팩터/additive 이상 구현 계획에는 `<!-- CHECKPOINT3: required -->` 를, ④만 적용되는 타이포/1줄/문서에는 `<!-- CHECKPOINT3: not-required -->` 를 포함한다. marker 가 없으면 fail-closed 로 pending 이다.
- `required` 계획은 `bash .claude/scripts/cr-checkpoint3.sh plans/ing/<slug>/구현_설계.md` 가 **Codex·Antigravity 양쪽** 상태 `OK` + 마지막 비공백 줄 `DECISION: Approve` 를 attestation(`CR-CHECKPOINT3-STATUS: APPROVED`)하기 전 코드 변경을 시작하지 않는다.
- 엔진이 **실제로** unavailable 할 때만 엔진별 폴백으로 통과한다 — `CR_CP3_ALLOW_CODEX_UNAVAILABLE=1` · `CR_CP3_ALLOW_AGY_UNAVAILABLE=1`(래퍼 부재 포함). 폴백·독립승인 수(`independent_reviews`)는 `checkpoint3-gate.json` 에 기록되고, 둘 다 폴백이면 독립 검증 0으로 경고한다. **엔진이 살아 있는데 지적을 피하려고 쓰는 것이 아니다** — 실행 실패 시 직전 라운드의 stale `Approve` 는 승인으로 읽히지 않는다.
- 상세 흐름은 [`CROSS-REVIEW.md`](CROSS-REVIEW.md) 를 따른다. 이 훅은 우발적 이탈 방지용이며 임의 Bash 우회를 봉쇄하는 보안 경계는 아니다.

## 검증 명령 (변경한 레포만)

| 대상 | 명령 (해당 레포 루트) |
|---|---|
| Kotlin 3종 공통 | `./gradlew ktlintFormat` → `./gradlew build` — **ktlint 강제**, 커밋 전 필수 |
| Kotlin 유닛만 | `./gradlew test` (`src/test/unit`, MockK·Kotest·FixtureMonkey, Spring Context 없음) |
| Kotlin 통합 | `./gradlew integrationTest` (**Docker 필요** — Testcontainers MySQL) |
| Kotlin 전체 | `./gradlew check` — `ktlint + test + integrationTest` (3종 공통) |
| Kotlin e2e | `./gradlew e2eTest` — public-api·internal-api, `docker compose up -d` 선행, `check` 에 묶지 않는다 |
| .NET | `dotnet build AspNetCoreSkeletonApplication.slnx` → `dotnet test --solution AspNetCoreSkeletonApplication.slnx` (IntegrationTests 는 **Docker 필요**) |
| .NET SPA | 바꾼 `src/spa/<클라이언트>` 에서 `npm ci && npm run build && npm test` (Angular 는 `npm test -- --watch=false`) |
| .NET 템플릿 | 템플릿 조건 주석·`.template.config` 를 바꿨으면 custom hive 로 `dotnet new install . --debug:custom-hive <임시>` → `dotnet new aspnet-spa-skeleton …` 실생성 확인 |

- 특정 테스트만: `./gradlew test --tests "com.rex.<module>.skeleton.*TestClassName"` · `./gradlew integrationTest --tests "*IntegrationTest"`.
- 형제 레포별 세부 명령·주의사항의 정본은 **각 레포 `CLAUDE.md`** 다. 이 표와 어긋나면 형제 레포 쪽이 이긴다(그리고 이 표를 고친다).

## 코드 정리·재검증 범위

- `/simplify` 는 구현자가 테스트 통과 후, 산출물 리뷰(④/PR) 전에 1회 실행한다. 단일 파일 수준의 소규모 변경은 생략 가능. 실행 후 테스트를 재확인한다. 리뷰어는 읽기·판정 전용이므로 실행하지 않는다 — 가독성 문제는 Request Changes 로 돌려보낸다.
- 리뷰·검증에서 발견한 문제를 수정한 뒤의 재검증은 변경 범위에 맞춘다. 검증 리포트(④ 증거)에 재검증 범위와 근거(변경 파일 → 영향 경로)를 적는다. "처음부터 전체" 는 횡단 변경일 때만 한다.

| 수정의 변경 범위 | 재검증 범위 |
|---|---|
| 국소 — 단일 스켈레톤의 단일 모듈 내부, 공용 코드 미변경 | 해당 레포 검증 명령 재실행 + 변경 지점과 그것을 쓰는 경로 |
| 공통 — 공용 설정·베이스 클래스·공용 라이브러리 | 사용처를 Grep 으로 열거해 적고, 그 경로들을 재검증 |
| 횡단 — 규약 변경·형제 스켈레톤 전파·인증/보안 계층 | 처음부터 전체 재검증 — 3 형제 레포 `./gradlew check` + 형제 동기화(`scripts/sibling-diff.sh`) 확인 |

## 핵심 규칙 (스켈레톤 공통 — 모든 구현 작업)

정본은 각 형제 레포 `CLAUDE.md` 다. 아래는 리뷰·계획 시 참조할 요약이며, **여기와 형제 레포가 어긋나면 그 자체가 동기화 결함**이다.
### 명명

| 항목 | 규칙 | 올바른 예 | 잘못된 예 |
|---|---|---|---|
| **Enum 클래스** | 접미사 없이 명명 | `ProductStatus`, `OrderType` | `ProductStatusEnum` |
| **Configuration 클래스** | `Configuration` 접미사 | `SecurityConfiguration` | `SecurityConfig` |
| **DataSource 파라미터** | 명시적 이름 | `mainDataSource`, `subDataSource` | `dataSource` |
| **enum 패키지** | `enums/` | `...enums.SampleStatus` | `enum/` (Java 예약어 — MapStruct 빌드 실패) |

- 클래스 접미사: `~~~Dto` / `~~~Model` / `~~~JpaEntity` / `~~~JdbcEntity` / `~~~JpaRepository` / `~~~JdbcRepository` / `~~~JpaEntityService` / `~~~JdbcEntityService` / `~~~BizService` / `~~~MappingService` / `~~~Client` / `~~~Mapper` / `~~~Configuration`. 맨 `Service` 접미사는 쓰지 않는다.
- **약어 금지** — 역할 코드·Enum 값·상수는 풀네임(`ADMINISTRATOR`, `TEAM_LEADER`).

### 구조

- **1 Class per 1 File** — 최상위 `class`·`interface`·`object`(enum·data·annotation 포함)는 파일에 하나. 예외는 Kotlin extension 파일과 `sealed` 계층(sealed 타입 + 직접 하위 타입)뿐이고 `typealias`·`fun main` 은 세지 않는다. 관련 파일은 하위 패키지로 묶는다. 검출 `OneClassPerFileConventionTest`(3레포).
- **레이어드** — API 스켈레톤: `Controller → MappingService → BizService → EntityService → Repository`, 계층 우회 금지 — Controller 는 MappingService 만 주입하고 `~Model` 을 응답(요청 본문은 `~Dto` 허용; 주입 허용 목록은 MappingService 와 `config/`·`util/` 의 요청 경계 보조만), MappingService 는 BizService·Mapper·Properties 만 주입, BizService 는 Repository 를 직접 주입하지 않으며 외부 API 어댑터는 `client/~Client`(BizService 아래), Entity 는 EntityService 위로 올라가지 않는다. batch 스켈레톤: `ItemProcessor → BizService → EntityService → Repository`(관리자·웹훅 API 는 `Controller → MappingService → BizService`). 검출 `ServiceNamingConventionTest`·`LayeringConventionTest`(3레포).
- **Model / DTO / Entity 분리** — Entity 는 상위 계층에 노출 금지. 변환은 MapStruct.
- **트랜잭션** — 클래스 레벨 `@Transactional(readOnly = true)` 기본, 변경 메서드에만 `@Transactional`. **모든 `@Transactional` 에 `transactionManager` 명시(primary 포함)** — 데이터소스가 여럿이라 묵시는 primary 로 가고, 다른 데이터소스의 리포지토리는 그 트랜잭션 밖에서 돈다(`@Modifying` 예외·파생 `deleteBy…` 조용한 무효·커넥션 2개). 경계는 BizService·EntityService(MappingService 금지). 검출 `TransactionManagerConventionTest`(3레포). **`@Async` 도 같은 프록시 규칙** — 같은 클래스 안 호출은 동기로 돈다. 비동기는 별도 빈(`ExampleAsyncProxyWorker`)으로. 검출 `AsyncSelfInvocationConventionTest`(public·internal).
- **String Enum** — `StringEnum` 인터페이스 + `AbstractStringEnumConverter`(JPA) + `StringEnumUtil.fromValue()`.

### .NET (asp-net-core-skeleton)

- 규칙의 정본은 [`../asp-net-core-skeleton/CLAUDE.md`](../asp-net-core-skeleton/CLAUDE.md) 와 그 README 「코딩 규약」·「요청 흐름」이다. 이 문서에는 요약 사본을 두지 않는다.

### 스택 주의

- Spring Boot 4.1 / Spring Batch 6.0 패키지 재배치(`org.springframework.batch.infrastructure.item.*`, `org.springframework.batch.core.job.*` 등), Jackson 3(`tools.jackson`), Kotlin 2.3.

### 설정값·비밀값 규칙

애플리케이션 yml 은 비밀값과 환경마다 달라지는 값을 **kebab-case 논리 키**(`${db-writer-password}`, `${db-host}`)로만 참조한다. 값은 환경변수(Spring 이 `DB_WRITER_PASSWORD` 를 `db-writer-password` 로 대응시킨다) 또는 비밀값 출처 프로필 — `aws`(Secrets Manager) · `azure`(Key Vault) · `gcp`(Secret Manager) — 이 채운다. 비밀(계정·비밀번호·API 키·토큰·서명키)에는 기본값을 두지 않는다 — 키 오타·미등록은 `UnresolvedPlaceholderGuard` 가 기동 실패로 드러낸다. 비밀이 아닌 값(포트·타임아웃·cron)은 yml 에 값으로 적거나 논리 키에 기본값을 둔다. 자격증명 평문은 어느 yml 에도 적지 않으며 `local` 프로필의 docker compose 계정만 예외다. 로컬 인프라(MySQL·Redis)는 `docker compose up -d` 로 띄우고, 통합 테스트는 Testcontainers 로 격리한다.

예외는 둘이다 — 프로필 활성화(`SPRING_PROFILES_ACTIVE` / `--spring.profiles.active`)와 비밀 저장소 위치(`AWS_SECRET_ID` · `AZURE_KEYVAULT_ENDPOINT` · `GCP_PROJECT_ID`)는 실행 선택이라 환경변수 이름 그대로 쓰고, 테스트 소스셋(`src/test/**`)의 고정 테스트 값과 선택적 e2e 계정 환경변수는 애플리케이션 설정이 아니라 허용한다.

정본은 형제 스켈레톤 3종의 `.claude/rules/conventions.md` 「환경 설정」 아래 「설정값·비밀값 규약」(글자 단위 동일, `scripts/sibling-diff.sh` 감시)이다 — 예: [`../spring-boot-public-api-skeleton/.claude/rules/conventions.md`](../spring-boot-public-api-skeleton/.claude/rules/conventions.md). 같은 문서의 「데이터베이스」(식별자 `Long`/`BIGINT`, 업무 DDL FK 제약 금지)·「타입 선언」(Model·DTO·JdbcEntity 는 `data class` + `val`, JPA Entity 는 `class` + `var`; nullable 은 DB 컬럼과 일치·`!!` 금지·전부-기본값 금지·Model `@field:JsonProperty` 전수; MapStruct `unmappedTargetPolicy = ERROR` — non-null 타깃은 매핑 명시, `is`-prefix Boolean 은 `@Mapping` 명시; JPA Join 금지)도 공통 규약이다.

---

## 산출물 분리 원칙 — 설계서는 "무엇", 리뷰 이력은 "왜"

크로스리뷰 라운드가 쌓이면 지적·근거·번복 이력이 설계서 본문으로 흘러들어가 문서가 몇 배로 불어나고, **정작 읽어야 할 구현 계약이 근거 문단에 묻힌다.** 그 상태에서는 사용자도 리뷰어도 설계서를 끝까지 읽지 않게 되고, 같은 문단 안에서 규범이 서로 모순되는 것도 발견되지 않는다. 그래서 다음을 강제한다.

### `구현_설계.md` 에 쓰는 것 (규범만)

- 만들 것: 파일 경로, 클래스·메서드 시그니처, DDL/DML, 데이터 흐름, 의존성, 설정 키와 기본값
- 지켜야 할 계약: 불변식, 트랜잭션 경계, 인가 범위, 타임아웃·상한값, 실패 시 동작
- **파생 영향도 분류와 전파 계획** (대상 레포 목록·시점·담당)
- 진행 순서·게이트·롤백 기준
- 각 계약은 **하나의 값·하나의 지시**로 단정한다. "A 로 한다(다만 B 도 가능)" 식의 병기 금지.

### `리뷰_이력.md` 로 보내는 것 (근거)

- 리뷰어별·라운드별 지적 원문과 판정(반영/기각), 기각 근거
- 왜 그 값·그 방식을 골랐는지, 검토했으나 채택하지 않은 대안
- **결정 번복**: 이전 결정과 뒤집은 이유(설계서에는 최종 결정만 남긴다)
- 폐기된 설계 이력(설계서 본문에 취소선으로 남기지 않는다)

### 참조 방식

- 설계서에서 근거가 필요하면 **한 줄 링크만** 둔다: `(근거: 리뷰_이력.md "「제목」")`. 근거 본문을 설계서로 되가져오지 않는다.
- 참조는 **행 번호(`§230`)가 아니라 제목·식별자 앵커**로 건다. 행 번호는 편집할 때마다 어긋나 stale 참조를 양산한다.
- 리뷰 라운드 표기(`Codex ③ r81 Major` 등)는 리뷰 이력에만 둔다.

### 적용 시점

- 각 크로스리뷰 라운드의 지적을 반영할 때, **그 자리에서** 규범은 설계서에 / 근거는 리뷰 이력에 나눠 쓴다. 나중에 정리하지 않는다.
- 설계서가 근거로 부풀었다면 다음 라운드 제출 **전에** 분리한다.

---

## 미결 항목 처리

- 지적을 "별도 티켓" 으로 미루려면 **티켓 식별자·담당·시점**을 함께 적는다. 셋 중 하나라도 없으면 그것은 티켓이 아니라 **미해결로 방치한 것**이므로, 지금 처리하거나 사용자에게 판단을 요청한다.
- "나중에 한다" 를 선택할 때는 **미루는 이득**을 한 줄로 적는다. 적을 수 없으면 미루지 않는다.
- 문서에 남긴 미결 항목은 다음 게이트에서 다시 확인한다.

---

## 목적 중심 실행

- 새 독립 작업을 시작할 때 요청과 대화 맥락에서 사용자가 실제로 해결하려는 문제 또는 얻으려는 상태를 추론해 한 문장으로 밝힌다. 사용자가 정정하면 즉시 반영하고, 그 목적을 작업 내내 판단 기준으로 삼는다.
  - 목적을 밝히는 것은 확인 대기가 아니다. 해석에 따라 결과가 갈릴 때만 묻고, 답을 기다리는 동안에도 안전하게 할 수 있는 일은 계속한다. 플랜 모드에서는 계획의 Context 첫 문장이 이 역할을 한다.
- 새 조사·수정·검증을 시작하거나 범위를 넓히기 전에 원래 목적에 지금 필요한지, 드는 시간·토큰에 비해 얻는 근거가 충분한지 판단한다. 필요성을 한 문장으로 설명하지 못하면 하지 않고 목적에 직접 기여하는 작업으로 돌아간다.
- 하위 문제나 예외를 발견하면, 해결하지 않을 때 원래 목적이 막히거나 결과가 실질적으로 틀리거나 위험해지는지 판단한다. 그렇지 않으면 해결 자체를 새 목표로 삼지 않는다.
- 검증은 변경 범위와 실제 위험에 비례해 필요한 만큼만 한다. 지침·문구 수정은 변경 부분 대조와 의미·형식 확인이 기본이다 — 구체적 실패 위험이나 필수 게이트 없이 빌드·런타임 확인·반복 테스트·추가 리뷰로 넓히지 않는다.
- 추가 조사·예외 처리·테스트가 목적 달성을 늦출 것으로 보이면, 현재 결과의 정확성·안전성에 필수가 아닌 일은 후속 과제로 한 줄 기록만 하고 지금 하지 않는다.
- 단계가 바뀌거나, 새 문제가 생기거나, 사용자가 추가 지시를 하거나, 맥락이 요약되면 원래 목적을 다시 확인한다. 마칠 때는 한 일의 양이 아니라 사용자가 원한 상태가 실제로 이루어졌는지로 판단한다.
- 목적 중심 판단은 필수 검증과 승인·안전 게이트를 생략하는 근거가 아니다.

## 완주 — 보고하고 멈추지 않는다

- 보고는 작업의 체크포인트이지 종료 신호가 아니다. 중간 결과·진단·분석을 보고한 뒤에는 같은 턴에서 다음 단계를 이어 수행한다.
- 원 요청에서 따라 나오고 목적 달성에 필요한 되돌릴 수 있는 작업은 묻지 말고 수행한다. 작업을 마친 뒤 후속 제안을 덧붙이는 것은 괜찮지만, 착수 허락을 구하며 멈추지 않는다.
- 부득이 멈출 때는 무엇이 남았고 어디서 재개하는지 명시한다.

### "다음에 하겠습니다" 는 그 턴에 한다

- 가장 흔한 이탈은 다음 행동을 선언하고 턴을 끝내는 것이다. "이어서 X 하겠습니다" 라고 쓴 순간 그 턴에서 X 를 시작한다. 선언은 예고가 아니라 착수 신호다.
- 다음 구간을 문단으로 서술해 놓고 "이어서 진행한다" / "계속 진행한다" 로 턴을 끝내는 것이 대표 위반이다. 서술체(`~한다`)든 경어체(`~하겠습니다`)든 같다. 다음에 할 일을 그렇게 구체적으로 적을 수 있다는 것은 지금 시작할 수 있다는 증거다 — 적었으면 그 턴에 첫 툴콜까지 간다.
- 문장을 쓰기 전에 자문한다 — "이걸 지금 할 수 있나?" 할 수 있으면 쓰지 말고 한다. 할 수 없으면 왜 못 하는지 차단 요인을 이름으로 적는다. 둘 중 하나뿐이다.
- 턴을 끝내기 전 마지막 문단을 확인한다. 그것이 계획·질문·다음 단계 목록이거나 "이제 ~하겠습니다" / "~하면 됩니다" / "원하시면 진행하겠습니다" 류라면, 그 일을 지금 툴콜로 한다.
- 기계적 점검 — 턴의 마지막 문장이 다음 행동을 가리키는데(`~한다`·`~하겠습니다`·`~할 차례다`·`~이 남았다`·`다음은 ~이다`) 그 턴에 대응하는 툴콜이 없으면 위반이다. 툴콜을 하거나, 그 문장을 지운다.

### 멈춰도 되는 경우

1. 요청 범위를 전부 끝냈을 때
2. 답에 따라 다음 행동이 갈리는 질문을 실제로 물었을 때
3. 되돌리기 어렵거나 외부로 나가는 작업이라 확인이 필요할 때 (커밋·푸시·발송·삭제·배포)
4. 사용자만 답할 수 있는 입력에 막혔을 때 (자격증명, 진짜 범위 변경)
5. 계획·게이트 승인을 기다릴 때 (ExitPlanMode, 레포 프로세스가 정한 체크포인트)

- 완주 원칙은 확인이 필요한 작업(항목 3)과 승인 대기(항목 5)를 무효화하지 않는다.
- 이 목록은 하한이다. 레포 지침이 정지 조건을 더 두면 그것까지 함께 적용하며, 레포 쪽을 좁히는 근거로 쓰지 않는다.

### 정지 사유가 아닌 것 — 그대로 진행한다

- 중간 발견이 흥미롭거나 규모가 커 보임 → 보고하고 본 작업을 이어간다. 발견 자체를 새 목표로 삼지 않는다
- 툴콜 실패 → 원인을 보고 재시도하거나 우회한다
- 정보 부족 → 묻기 전에 직접 조사한다
- 컨텍스트·세션이 길어짐 → 길이는 중단 사유가 아니다
- 서브에이전트 대기 → 다른 트랙을 진행하다 결과가 오면 반영한다
- 인접 결함 발견 → 목적을 막거나 결과를 틀리게 만들면 처리하고, 아니면 후속 과제로 한 줄 남긴다
- 조사가 다른 작업의 준비 단계였음 → 본 작업으로 넘어간다. 조사 자체가 요청이었을 때만 거기서 끝난다

### 남은 일을 나열할 때는 차단 여부까지 적는다

목록만 나열하면 전부 "다음에 할 일" 로 보이지만 실제로는 대부분 지금 할 수 있는 것들이다.

| 표기 | 뜻 | 행동 |
|---|---|---|
| ✅ 완전 자율 | 차단 없음 | 지금 한다. 나열하지 않는다 |
| ⚠️ 부분 자율 | 일부 차단 | 자율 부분을 먼저 끝낸다 |
| ⏸ 대기 | 선행 미완 | 선행을 먼저 한다 |
| ⛔ blocked | 사용자·외부 자원 필요 | 무엇이 필요한지 이름으로 적고 멈춘다 |

표는 목적 달성에 필요한 일만 대상이다. 필요 없는 일은 표에 올리지 않고 후속 과제로 한 줄 남긴다.

⛔ 는 차단 요인을 특정해야 성립한다. "확인이 필요합니다" 는 차단 요인이 아니다 — "운영 Key Vault 접근 권한", "최종 승인자 승인" 처럼 이름이 있어야 한다. 이름을 못 적으면 차단이 아니라 중도 방치다.

### 이 레포의 추가 정지 지점

- 크로스리뷰 게이트 미통과 — ③ attestation 전 코드 변경 금지.
- 커밋·푸시·머지·배포 — 사용자 지시 시에만. 코드 커밋은 해당 형제 레포에서만 한다.
- 사용자만 가능한 검증 — 권한 계정·외부 자원·육안 확인.
- 서버·인프라 실상 — 계정·경로·배포방식을 추측하거나 자가 프로비저닝하지 않는다. 모르면 묻는다.

정지 지점이 **아닌** 것 두 가지를 덧붙인다. **형제 스켈레톤 반영은 "남은 단계"다** — 한 레포만 고치고 "나머지도 같이 고쳐야 합니다" 로 끝내지 않는다. **게이트에 막혔으면 게이트가 정한 경로를 밟는다** — ③ 미통과는 attestation 실행, marker 누락은 marker 부여 후 재승인이다.


## MySQL 스키마 범위

- 로컬 MySQL 은 각 형제 레포의 `docker compose up -d` 로 띄운다. 스키마·계정은 `docker/mysql/init`, 업무 테이블 DDL 정본은 각 레포 `src/main/resources/db/manual/create-*.sql`(docker compose 초기화·Testcontainers 공용)이다.
- 스키마: public-api `skeleton_main`(@Primary, 수동 DDL) · `skeleton_auth`(Flyway) / internal-api `skeleton_main`(@Primary) · `skeleton_sub` / batch `skeleton_batch`(Primary, Spring Batch·Quartz 메타 — Flyway) · `skeleton_main` · `skeleton_sub`.
- Flyway 는 public-api 의 `skeleton_auth`(이력 `flyway_schema_history_public_api`, `spring.flyway.enabled` 기본 `false`·`local` 은 `true`)와 batch 의 `skeleton_batch`(이력 `flyway_schema_history_batch`, 기본 `true`)만 관리한다. internal-api 는 Flyway 를 쓰지 않는다.
- 계정은 공통 `skeleton_reader`/`skeleton_writer`(런타임)와 `skeleton_admin`(Flyway)이며, 논리 키 `db-{reader,writer,admin}-{username,password}` 로 참조한다. 지정한 catalog 이외 URL 은 연결 전에 거부하고, 자동 스키마 생성·baseline·repair 는 쓰지 않는다.
- 스키마·테이블의 문자셋·콜레이션은 `utf8mb4` / `utf8mb4_0900_ai_ci` 다. 이미 적용된 Flyway 마이그레이션 파일은 고치지 않고 새 버전을 추가한다 — 체크섬이 어긋난다.
- 형제 레포별 세부의 정본은 각 레포 `CLAUDE.md` 「MySQL 스키마 및 계정」이다.
