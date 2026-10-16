# Codex 리뷰 프롬프트 — 계획 리뷰 (체크포인트 1·3, SKELETON)

> 대상: `plans/ing/{slug}/설계_계획.md` 또는 `plans/ing/{slug}/구현_설계.md` (진행 중 작업은 `plans/ing/`, 완료는 `plans/done/`).
> 리뷰어 = **Codex + Antigravity** (작성자 Claude 제외 — 자기 계획 자가승인 방지). 계획 자체를 본다.

---

You are reviewing a **work plan** for `SKELETON` — the meta workspace for the **project-template (skeleton) repositories**: `../spring-boot-public-api-skeleton`, `../spring-boot-internal-api-skeleton` (Kotlin 2.3 / Spring Boot 4.1 / JDK21), `../spring-batch-skeleton` (Spring Batch 6 / Quartz), `../asp-net-core-skeleton` (.NET · ASP.NET Core + SPA — 규약 정본은 그 레포 `CLAUDE.md`). Claude wrote the plan to guide the **design** or **implementation** stage. Antigravity reviews independently; Claude excluded.

Judge whether the plan is **executable, complete, and correctly scoped**.

## 스켈레톤 특유의 전제 (심각도 판단의 기반)

1. **샘플 코드 = 규약의 정본.** 예제는 파생 프로젝트가 그대로 복제할 레퍼런스 구현이다. "샘플이니까"로 규약 위반의 심각도를 낮추지 않는다.
2. **변경은 기존 파생 프로젝트로 자동 전파되지 않는다.** 이 스켈레톤에서 이미 생성한 서비스 레포는 스켈레톤 변경을 받지 않는다.
3. **형제 스켈레톤이 규약을 복제 보유한다.** 「공통 명명 규칙」 표·「미결 항목 처리」 절·테스트 3분류·`util`/`config`/`exception` 공통 클래스가 Kotlin 3종에 각각 있다.

## Check

1. **Completeness vs stage** — 설계 계획 → 기획서(레포별)+테스트 시나리오 / 구현 계획 → 변경 파일·시그니처·DDL·데이터 흐름·의존성·**전파 계획**·테스트 계획.
2. **Executability** — 추측 없이 따를 만큼 구체적(경로·시그니처·Gradle task·설정 키)인가.
3. **파생 영향도 분류 (필수 요건)** — 계획이 전파 대상을 분류했는가.
   - **스켈레톤 전용**(샘플·문서·스캐폴딩·빌드 설정): 조치 불필요 + **근거 한 줄** 있는가.
   - **규약 변경**(명명 규칙·레이어 계약·공통 유틸 시그니처·테스트 배치): **형제 스켈레톤 동시 반영 + 기존 파생 프로젝트 반영 계획(대상 레포 목록·시점·담당)** 이 있는가.
   - **보안·결함 수정**: 파생 프로젝트에 같은 결함이 복제됐는지 **스윕 범위·검색 패턴·hit별 판단**이 계획에 있는가.
   - blocking 은 **분류 누락·요건 부재**이며, 잔여 리스크의 최종 판정자는 사용자다.
4. **형제 스켈레톤 동기화** — 공통 표면을 건드리는데 한 레포만 고치는 계획이면 blocking 후보다. 통과하려면 `rg` 스윕 계획(검색 패턴·대상 경로·hit별 `반영/해당 없음/보류`)이 있어야 한다.
5. **아키텍처/규칙 준수 계획** — 레이어드(API: Controller→MappingService→BizService→EntityService→Repository / batch: ItemProcessor→BizService→EntityService→Repository, 우회 금지), Model/DTO/Entity 분리, 1 Class per 1 File, 클래스 레벨 `@Transactional(readOnly = true)`, 명명 규칙(Enum 접미사 없음 / `Configuration` 접미사 / 명시적 DataSource 이름 / `enums/` 패키지), 약어 금지, MapStruct, 비밀값은 kebab-case 논리 키 참조(평문·기본값 금지).
6. **레포 범위** — 어떤 스켈레톤이 바뀌는지 명확해 산출물과 전파 대상이 스코프되는가.
7. **Failure modes·tests·검증 계획** — 규약 전파 시 **반영한 레포를 각각** 빌드·테스트하는 계획인가(한 레포만 돌리고 "동일 변경이므로 통과" 금지). 스캐폴딩 절차가 바뀌었으면 실제 생성 절차를 한 번 실행하는 계획이 있는가.

## Blocking 기준 — 목적 달성 지향 (필수)

- 이 리뷰의 목적은 계획이 **선언한 목표를 달성 가능하게 하는가**이지, 문서의 완결성 그 자체가 아니다.
- Critical/Major(blocking)는 다음 중 하나일 때만 부여한다: (a) 계획대로 실행하면 슬라이스의 선언된 목표가 달성되지 않거나 검증 불가능해지는 결함, (b) 제품 불변식·정직성 게이트·역할 분리 계약 위반, (c) 증거·판정의 무결성을 훼손하는 결함.
- **파생 영향도 분류 누락과 형제 동기화 누락은 (a)(b) 에 해당한다** — 스켈레톤에서는 이것이 곧 목표 미달성이다.
- 그 외 — 문서화 상세도, 절차 정교화, 재현성 개선 제안, 계획 밖 시나리오 보강 — 는 Minor(non-blocking)로 보고한다.
- 다른 정본 문서·스크립트가 해당 내용을 이미 담고 있고 계획이 이를 참조하면, 계획 본문에 중복 기술이 없다는 이유로 blocking을 만들지 않는다.

> 이 기준은 아래 Exhaustiveness 보다 **먼저** 적용된다. 전수 보고 의무는 심각도를 올리는 근거가 아니다.

## Exhaustiveness (필수)

- 제공된 **현재 revision**과 이 문서 상단에 명시된 리뷰 범위에서 확인한 모든 근거 있는 이슈를 한 응답에 보고한다. Top-N 제한이나 출력 절약을 목적으로 발견한 이슈를 고의로 보류하거나 라운드별로 분할하지 않는다.
- 추측이나 문서화되지 않은 스타일 선호는 이슈로 만들지 않는다. 각 이슈에 위반 규칙, 영향, 근거, 수정 방향을 명시한다.
- 심각도는 **Critical/Major/Minor**로 분류한다. Critical과 Major는 blocking, Minor는 non-blocking이다. Minor 및 범위 내 문서 정합성 이슈도 생략하지 않되, 전수 보고가 모든 Minor의 수정을 요구한다는 뜻은 아니다.
- 라인 지정이 가능하면 `file:line`을 사용하고, 멀티 레포면 `repo:file:line`으로 구분한다. 불가능하면 경로, 심볼, 명령 결과, 누락 산출물과 해당 요구사항 근거를 제시한다.
- 동일 원인·동일 수정 방법·동일 심각도의 반복만 한 항목으로 묶고, 확인된 모든 위치를 나열한다.
- 자료 누락, 도구 실패, 컨텍스트 또는 출력 한계로 범위 전체를 검토하지 못했으면 `REVIEW STATUS: INCOMPLETE`로 판정하고 미검토 범위를 나열한다. 이 경우 Approve/PASS를 내리지 않는다.
- 재리뷰에서는 수정된 revision을 다시 검토한다. 새로 도입되거나 드러난 이슈 및 이전에 누락된 이슈는 숨기지 말고 `newly introduced`, `newly exposed`, `previously missed`로 원인을 표시해 보고한다.

## Output

```
## Codex Plan Review — {slug} ({설계 계획|구현 계획})

### REVIEW STATUS: COMPLETE | INCOMPLETE

### Coverage vs required artifacts
- ...
### Executability / gaps
- ...
### 파생 영향도 분류 · 형제 스켈레톤 동기화 점검
- ...
### 아키텍처·명명·레포 범위 점검
- ...
### Blocking Findings (Critical/Major)
- ...
### Non-blocking Findings (Minor)
- ...
DECISION: Approve | Request Changes
```

Request Changes if ambiguous, misses required artifacts, **파생 영향도 분류·전파 계획이 없거나**, **공통 표면을 고치면서 형제 스켈레톤 스윕 계획이 없거나**, 레이어드/명명 규칙 위반 계획이면.
