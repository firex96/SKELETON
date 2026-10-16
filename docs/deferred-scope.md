# 관리 범위에서 유보한 스켈레톤

아래 레포는 관리 대상에서 **제외한 것이 아니라 유보**한 것이다. 복귀 조건이 충족되면 이 워크스페이스 범위로 되돌린다. 유보는 **이 워크스페이스의 관리·리뷰 범위**에 대한 것이지 레포를 지우거나 옮긴다는 뜻이 아니다.

| 레포 | 유보 사유 | 미루는 이득 | 복귀 조건 |
|---|---|---|---|
| `svelte-frontend-skeleton` | 이 워크스페이스(형제 위치)에 없다 | 레포가 없으면 **Workspace Setup 문서와 크로스리뷰 대상 해석이 성립하지 않는다** | 공개 원격이 생기고 형제 위치에 clone 될 때 |

> `asp-net-core-skeleton` 은 2026-10-16 에 관리 범위로 들어왔다. 작업은 당분간 그 레포에서 직접 진행하고, 이 워크스페이스는 등록·크로스리뷰 대상 연결까지만 맡는다(`CLAUDE.md` 「정체성」).

## 복귀 시 되살릴 것

- `CLAUDE.md` · `AGENTS.md` — 관리 범위 문장, Workspace 트리, 실행 경로 표, 검증 명령 표, 핵심 규칙의 정본 포인터
- `CROSS-REVIEW.md` — 이 레포 구성, 레포별 결정적 검증 렌즈 표, 빌드·검증 명령, 인접 결함 스윕 범위, UI 산출물 조건(SPA 화면 변경 시 목업)
- `README.md` — 관리 대상 표, 표준 레이아웃, Workspace Setup clone 명령, 빌드·검증 명령
- `.claude/settings.json` 의 `additionalDirectories`, `.claude/cross-review-siblings`, `.gitignore` 의 오클론 가드
- 리뷰 루브릭 렌즈 — `.codex/review-{plan,design,correctness-security}.md`, `.agents/skills/{plan-review,design-doc-review,code-review,runtime-verification}/SKILL.md` 의 대상 레포 목록과 스택 렌즈
