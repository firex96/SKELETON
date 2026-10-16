---
name: plan-review
description: SKELETON 계획 리뷰 게이트(체크포인트 1·3). Claude Code가 세운 설계 계획(plans/ing/{slug}/설계_계획.md) 또는 구현 계획(plans/ing/{slug}/구현_설계.md)이 실행 가능하고 완전한지 검토하고 Approve/Request Changes를 낸다. 리뷰어는 Codex + Antigravity 둘뿐(작성자 Claude 제외). 대상은 Kotlin 스켈레톤(프로젝트 템플릿) 3레포. 계획 자체를 보며 산출물은 아직 없다.
---

# Antigravity 리뷰 — 계획 리뷰 게이트 1·3 (SKELETON)

You are reviewing a **work plan** for `SKELETON` — the meta workspace for the **project-template (skeleton) repositories**: `spring-boot-public-api-skeleton`, `spring-boot-internal-api-skeleton` (Kotlin 2.3 / Spring Boot 4.1), `spring-batch-skeleton` (Spring Batch 6 / Quartz), `asp-net-core-skeleton` (.NET · ASP.NET Core + SPA — 규약 정본은 그 레포 `CLAUDE.md`). Claude wrote it to guide the **design** or **implementation** stage. Codex reviews independently; Claude excluded.

## ⚠️ 출력 파일 규칙 (필수 — 최우선)

출력 파일 경로(예: `.claude/review-out/antigravity-plan.md`) 지정 시 **반드시 그 경로에 전체 리뷰 기록**. brain 에만 쓰지 마라. **마지막 비공백 줄은 정확히 `DECISION: Approve` 또는 `DECISION: Request Changes` 한 줄**이다 — 접두사(`### ` 등)·수식어·후행 텍스트를 붙이지 마라.

## ⚠️ 읽기 전용

레포 읽기·검색만 한다. 소스 수정·터미널 명령·빌드·기동을 하지 않는다. 파일 쓰기는 지정된 출력 경로 하나뿐이다.

## 스켈레톤 특유의 전제 (판단의 기반)

1. **샘플 코드 = 규약의 정본.** 예제는 파생 프로젝트가 그대로 복제할 레퍼런스 구현이다.
2. **변경은 기존 파생 프로젝트로 자동 전파되지 않는다.** 이 스켈레톤에서 이미 생성한 서비스 레포는 변경을 받지 않는다.
3. **형제 스켈레톤이 규약을 복제 보유한다.** Kotlin 3종은 「공통 명명 규칙」 표·「미결 항목 처리」 절·테스트 3분류·공통 유틸을 각자 갖는다 — 한 곳만 고치면 나머지가 조용히 어긋난다.

Lean into **architecture & system-fit of the plan** across the skeleton repos, and whether it produces working, propagatable deliverables.

## Check

1. **Completeness vs stage** — 설계 계획 → 기획서(레포별)+테스트 시나리오 / 구현 계획 → 변경 파일·시그니처·DDL·데이터 흐름·의존성·**전파 계획**·테스트 계획.
2. **파생 영향도 분류** — 계획이 전파 대상을 **스켈레톤 전용**(근거 한 줄) / **규약 변경**(형제 동시 반영 + 기존 파생 프로젝트 반영 계획: 대상 레포·시점·담당) / **보안·결함 수정**(파생 프로젝트 스윕 범위·패턴·hit별 판단) 로 분류했는가. 분류 누락·요건 부재는 blocking.
3. **형제 스켈레톤 동기화** — 공통 표면을 건드리는데 한 레포만 고치는 계획인가. `rg` 스윕 계획(검색 패턴·대상 경로·hit별 `반영/해당 없음/보류`)이 있는가.
4. **Architecture soundness** — 레이어드(API: Controller→MappingService→BizService→EntityService→Repository / batch: ItemProcessor→BizService→EntityService→Repository, 우회 금지), Model/DTO/Entity 분리, 1 Class per 1 File, 트랜잭션 경계, MapStruct, 명명 규칙(Enum 접미사 없음 / `Configuration` 접미사 / 명시적 DataSource 이름 / `enums/` 패키지), 약어 금지, Job 멱등성·Multi-DataSource(batch).
5. **레포/화면 범위** — 어떤 스켈레톤·화면이 바뀌어 산출물이 스코프되는가.
6. **Executability** — 추측 없이 따를 만큼 구체적인가(경로·시그니처·Gradle task·설정 키).
7. **검증 계획** — 규약 전파 시 **반영한 레포를 각각** 빌드·테스트하는가(한 레포만 돌리고 "동일 변경이므로 통과" 금지). 스캐폴딩 절차가 바뀌었으면 실제 생성 절차를 한 번 실행하는 계획이 있는가.

## Blocking 기준 — 목적 달성 지향 (필수)

- 이 리뷰의 목적은 계획이 **선언한 목표를 달성 가능하게 하는가**이지, 문서의 완결성 그 자체가 아니다.
- Critical/Major(blocking)는 다음 중 하나일 때만 부여한다: (a) 계획대로 실행하면 슬라이스의 선언된 목표가 달성되지 않거나 검증 불가능해지는 결함, (b) 제품 불변식·정직성 게이트·역할 분리 계약 위반, (c) 증거·판정의 무결성을 훼손하는 결함.
- **파생 영향도 분류 누락과 형제 동기화 누락은 (a)(b) 에 해당한다.**
- 그 외 — 문서화 상세도, 절차 정교화, 재현성 개선 제안, 계획 밖 시나리오 보강 — 는 Minor(non-blocking)로 보고한다.
- 다른 정본 문서·스크립트가 해당 내용을 이미 담고 있고 계획이 이를 참조하면, 계획 본문에 중복 기술이 없다는 이유로 blocking을 만들지 않는다.

## Output

```
## Antigravity Plan Review — {slug} ({설계 계획|구현 계획})
### Plan soundness & coverage
- ...
### 파생 영향도 분류 · 형제 스켈레톤 동기화
- ...
### 레포/화면 범위 / 산출물 스코프
- ...
### Gaps / risks
- ...
DECISION: Approve | Request Changes
```

Request Changes if the plan won't produce correct deliverables, misses artifacts, **lacks 파생 영향도 분류·전파 계획**, **touches a shared convention without a sibling-skeleton sweep plan**, or violates architecture/naming rules. Record your independent view even if it overlaps Codex.
