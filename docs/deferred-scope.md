# 관리 범위에서 유보한 스켈레톤

두 레포는 관리 대상에서 **제외한 것이 아니라 유보**한 것이다. 아래 복귀 조건이 충족되면 이 워크스페이스 범위로 되돌린다. 유보는 **이 워크스페이스의 관리·리뷰 범위**에 대한 것이지 레포를 지우거나 옮긴다는 뜻이 아니다.

| 레포 | 유보 사유 | 미루는 이득 | 복귀 조건 |
|---|---|---|---|
| `asp-net-core-skeleton` | 이 워크스페이스의 리뷰 렌즈·형제 대조 장치는 Kotlin 3종 기준이다. .NET 스택의 규약 표면·검증 명령을 이 워크스페이스 문서로 아직 옮기지 않았다 | 렌즈 없이 범위에 넣으면 크로스리뷰가 **Kotlin 기준으로 .NET 코드를 판정**하게 된다 | 그 레포 `CLAUDE.md` 의 규약에서 리뷰 렌즈·검증 명령을 이 워크스페이스로 옮기고, 원격이 정해질 때 |
| `svelte-frontend-skeleton` | 이 워크스페이스(형제 위치)에 없다 | 레포가 없으면 **Workspace Setup 문서와 크로스리뷰 대상 해석이 성립하지 않는다** | 공개 원격이 생기고 형제 위치에 clone 될 때 |

## asp-net-core-skeleton — 확인된 사실

확인 시점: 2026-10-16, 커밋 `3952cf1`.

- 로컬 경로 `../asp-net-core-skeleton` 에 git 레포로 있다. **원격이 설정돼 있지 않다.**
- 자체 `CLAUDE.md`·`AGENTS.md`·`README.md`·`CHANGELOG.md` 가 있다. 규약의 정본은 그 레포 `CLAUDE.md` 다.
- 솔루션 `AspNetCoreSkeletonApplication.slnx`. `src/{common,web-application,internal-api,batch,spa}`, `test/{unit-tests,integration-tests,functional-tests}` — Kotlin 3종의 `src/test/{unit,integration,e2e}` 에 대응하는 테스트 3분류다.
- 로컬 인프라는 `docker compose up -d`, 통합 테스트는 Docker 가 필요하다. SPA 는 여러 클라이언트(`SpaClient` 로 선택, 기본 angular)를 둔다 — 복귀하면 UI 산출물 대상이 된다.

## 복귀 시 되살릴 것

- `CLAUDE.md` · `AGENTS.md` — 스택 표, 검증 명령 표, 핵심 규칙 항목(.NET 절 / 프론트 절)
- `CROSS-REVIEW.md` — 이 레포 구성, 레포별 결정적 검증 렌즈 표, 빌드·검증 명령, 인접 결함 스윕의 레포 수, 티어링의 **화면 변경** 항목, 그리고 **UI 산출물 체크포인트 조건** — 현재 범위에는 UI 스켈레톤이 없어 비활성이다
- `README.md` — 관리 대상 표, 표준 레이아웃, Workspace Setup clone 명령, 빌드·검증 명령
- `.claude/settings.json` 의 `additionalDirectories`, `.claude/cross-review-siblings`, `.gitignore` 의 오클론 가드
- 리뷰 루브릭 렌즈 — `.codex/review-{plan,design,correctness-security}.md`, `.agents/skills/{plan-review,design-doc-review,code-review,runtime-verification}/SKILL.md`
- **`design-doc-review` 는 UI 스켈레톤 복귀 시 목업 시각 검증 절을 되살려야 한다** — 현재는 문서 리뷰 전용으로 축소돼 있다
