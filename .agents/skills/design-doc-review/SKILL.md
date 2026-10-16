---
name: design-doc-review
description: SKELETON 설계 산출물 리뷰 게이트(체크포인트 2, 3중). plans/ing/{slug}/ 의 기획서(레포별)·테스트 시나리오를 검토하고 Approve/Request Changes를 낸다. Claude + Codex + Antigravity 3중. 대상은 Kotlin 스켈레톤(프로젝트 템플릿) 3레포 — public-api / internal-api / batch. 코드는 아직 없다. 현재 범위에 UI 스켈레톤이 없어 목업·디자인 시스템 산출물은 비활성이다.
---

# Antigravity 리뷰 — 설계 산출물 리뷰 게이트 2 (SKELETON)

You are reviewing the **design deliverables** for a `SKELETON` change — the meta workspace for the **Kotlin project-template (skeleton) repositories** (`spring-boot-public-api-skeleton`, `spring-boot-internal-api-skeleton`, `spring-batch-skeleton`, .NET `asp-net-core-skeleton`). Claude + Codex review independently. Code does not exist yet — you are judging documents.

## ⚠️ 출력 파일 규칙 (필수 — 최우선)

출력 파일 경로(예: `.claude/review-out/antigravity-design.md`) 지정 시 **반드시 그 경로에 전체 리뷰 기록**. brain 에만 쓰지 마라. **마지막 비공백 줄은 정확히 `DECISION: Approve` 또는 `DECISION: Request Changes` 한 줄**이다 — 접두사·수식어·후행 텍스트 금지.

## ⚠️ 읽기 전용

레포 읽기·검색만 한다. 소스 수정·터미널 명령·빌드·기동을 하지 않는다. 파일 쓰기는 지정된 출력 경로 하나뿐이다.

## 스켈레톤 특유의 전제 (판단의 기반)

1. **샘플 코드 = 규약의 정본.** 설계가 정하는 예제 구조는 모든 파생 프로젝트가 복제한다. 일회성 구현이 아니라 재사용 가능한 레퍼런스인가로 본다.
2. **변경은 기존 파생 프로젝트로 자동 전파되지 않는다.** 설계는 전파 대상과 방법을 명시해야 한다.
3. **형제 스켈레톤이 규약을 복제 보유한다.** 공통 규약을 바꾸는 설계면 형제 3종 전부에 대한 반영 설계가 있어야 한다.

## Check

1. **파생 영향도 분류** — 설계에 전파 대상 분류가 있는가.
   - **스켈레톤 전용**(샘플·문서·스캐폴딩·빌드 설정): 조치 불필요 + 근거 한 줄.
   - **규약 변경**(명명 규칙·레이어 계약·공통 유틸 시그니처·테스트 배치): 형제 동시 반영 + 기존 파생 프로젝트 반영 계획(대상 레포 목록·시점·담당).
   - **보안·결함 수정**: 파생 프로젝트 스윕 범위·검색 패턴·hit별 판단.
   - 분류 누락·요건 부재는 blocking.
2. **형제 스켈레톤 일관성** — 공통 규약을 바꾸는 설계인데 한 레포만 다루면 blocking 후보. 형제 3종(public-api / internal-api / batch) 반영 설계와 `rg` 스윕 범위가 있는가.
3. **기획서(레포별) 아키텍처 정합** — 레이어드 계약(API: Controller→MappingService→BizService→EntityService→Repository / batch: ItemProcessor→BizService→EntityService→Repository, 우회 금지), Model/DTO/Entity 분리(Entity 상위 노출 금지), 1 Class per 1 File, 트랜잭션 경계(클래스 레벨 `@Transactional(readOnly = true)`), MapStruct, 명명 규칙(Enum 접미사 없음 / `Configuration` 접미사 / 명시적 DataSource 이름 / `enums/` 패키지), 약어 금지. batch 면 Job/Step 멱등성·Quartz 트리거·Multi-DataSource 경계, API 면 Flyway 범위·엔드포인트 계약.
4. **정본 정합** — 설계가 대상 레포의 `CLAUDE.md` 와 어긋나면 그 자체가 지적 대상이다. 어긋난 쪽이 옳다면 그 `CLAUDE.md` 갱신도 설계에 포함돼야 한다.
5. **테스트 시나리오** — 배치 규약(`src/test/unit` 유닛 / `src/test/integration` Testcontainers / `src/test/e2e`) 준수. 엣지(빈 목록, 매핑 실패, enum 변환, Multi-DataSource 경계, Job 재실행 멱등성) 커버.
6. **일관성** — 기획서 ↔ 테스트 시나리오 ↔ 전파 계획 사이에 모순이 없는가. 같은 계약이 두 문서에서 다른 값으로 적혀 있지 않은가.
7. **UI 목업(asp-net-core SPA 화면 변경 시)** — 목업이 산출물에 있고, 화면 상태(빈 목록·오류·권한 없음·로딩)와 API 계약(필드·경로)이 기획서와 일치하는가. 목업이 없으면 blocking.

> **UI 산출물(목업·디자인 시스템)은 현재 범위에서 비활성이다** — 관리 대상에 UI 를 가진 스켈레톤이 없다. 유보된 프론트 스켈레톤이 복귀하면 목업 시각 검증(피그마 ↔ 렌더 1:1) 절을 되살린다.

## Blocking 기준 — 목적 달성 지향 (필수)

- 이 리뷰의 목적은 설계가 **선언한 목표를 달성 가능하게 하는가**이지, 문서의 완결성 그 자체가 아니다.
- Critical/Major(blocking)는 다음 중 하나일 때만 부여한다: (a) 설계대로 실행하면 슬라이스의 선언된 목표가 달성되지 않거나 검증 불가능해지는 결함, (b) 제품 불변식·정직성 게이트·역할 분리 계약 위반, (c) 증거·판정의 무결성을 훼손하는 결함.
- **파생 영향도 분류 누락과 형제 동기화 누락은 (a)(b) 에 해당한다.**
- 그 외 — 문서화 상세도, 절차 정교화, 재현성 개선 제안, 설계 밖 시나리오 보강 — 는 Minor(non-blocking)로 보고한다.
- 다른 정본 문서·스크립트가 해당 내용을 이미 담고 있고 설계가 이를 참조하면, 설계 본문에 중복 기술이 없다는 이유로 blocking을 만들지 않는다.

## Output

```
## Antigravity Design Review — {slug} (SKELETON)
### 파생 영향도 분류 · 형제 스켈레톤 일관성
- ...
### 기획서 아키텍처 정합 · 정본(CLAUDE.md) 정합
- ...
### 테스트 시나리오
- ...
### Issues (blocking) / Suggestions
- ...
DECISION: Approve | Request Changes
```

Request Changes if artifacts are inconsistent, **파생 영향도 분류·전파 설계가 없거나**, **형제 스켈레톤 반영이 빠졌거나**, 레이어드·명명 규칙 위반 설계이거나, 대상 레포 `CLAUDE.md` 와 모순되면. Record your independent view even if it overlaps Codex.
