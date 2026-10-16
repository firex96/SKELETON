# Codex 리뷰 프롬프트 — 설계 산출물 리뷰 (체크포인트 2, SKELETON)

> 대상: `plans/ing/{slug}/` 산출물 — 기획서(레포별) · 테스트 시나리오 (진행 중 작업은 `plans/ing/`, 완료는 `plans/done/`).
> 리뷰어 = **Claude + Codex + Antigravity (3중)**. 코드는 아직 없다 — 문서를 본다.
> (현재 범위에 UI 스켈레톤이 없어 목업·디자인 시스템 산출물은 비활성이다.)

---

You are reviewing the **design deliverables** for a `SKELETON` change — the meta workspace for the **project-template (skeleton) repositories** (Kotlin/Spring public-api·internal-api·batch). Claude + Antigravity review independently. Focus on **contract/architecture correctness, propagation completeness, and consistency**.

## 스켈레톤 특유의 전제

1. **샘플 코드 = 규약의 정본.** 설계가 정하는 예제 구조는 모든 파생 프로젝트가 복제한다.
2. **변경은 기존 파생 프로젝트로 자동 전파되지 않는다.** 설계는 전파 대상과 방법을 명시해야 한다.
3. **형제 스켈레톤이 규약을 복제 보유한다.** 설계가 공통 규약을 바꾸면 형제 전부에 대한 반영 설계가 있어야 한다.

## Check

1. **기획서(레포별)** — 요구사항이 검증 가능한가. 대상 스켈레톤이 명시됐는가. 레이어드 계약(API: Controller→MappingService→BizService→EntityService→Repository / batch: ItemProcessor→BizService→EntityService→Repository), Model/DTO/Entity 분리, 1 Class per 1 File, 클래스 레벨 `@Transactional(readOnly = true)`, MapStruct, 명명 규칙(Enum 접미사 없음 / `Configuration` 접미사 / 명시적 DataSource 이름 / `enums/` 패키지), 약어 금지가 지켜지는가. batch 면 Job/Step 멱등성·Quartz 트리거·Multi-DataSource 경계, API 면 Flyway 범위·엔드포인트 계약.
2. **파생 영향도 분류 (필수 요건)** — 설계에 전파 대상 분류(**스켈레톤 전용** / **규약 변경** / **보안·결함 수정**)와 그에 맞는 요건이 있는가. 규약 변경이면 대상 레포 목록·시점·담당이 있는가. 분류 누락·요건 부재는 blocking.
3. **형제 스켈레톤 일관성** — 공통 규약을 바꾸는 설계인데 한 레포만 다루면 blocking 후보. 형제 3종(public-api / internal-api / batch)에 대한 반영 설계와 `rg` 스윕 범위가 있는가.
4. **테스트 시나리오** — Unit(`src/test/unit`) / Integration(`src/test/integration`, Testcontainers) / E2E 배치가 스켈레톤 규약과 맞는가. 엣지(빈 목록, 매핑 실패, enum 변환, Multi-DataSource 경계, Job 재실행 멱등성) 커버.
5. **일관성** — 기획서 ↔ 테스트 시나리오 ↔ 전파 계획 ↔ 대상 레포 `CLAUDE.md` 규약 사이에 모순이 없는가. 같은 계약이 두 문서에서 다른 값으로 적혀 있지 않은가. **설계가 형제 레포 `CLAUDE.md` 와 어긋나면 그 자체가 지적 대상이다.**

## Blocking 기준 — 목적 달성 지향 (필수)

- 이 리뷰의 목적은 설계가 **선언한 목표를 달성 가능하게 하는가**이지, 문서의 완결성 그 자체가 아니다.
- Critical/Major(blocking)는 다음 중 하나일 때만 부여한다: (a) 설계대로 실행하면 슬라이스의 선언된 목표가 달성되지 않거나 검증 불가능해지는 결함, (b) 제품 불변식·정직성 게이트·역할 분리 계약 위반, (c) 증거·판정의 무결성을 훼손하는 결함.
- **파생 영향도 분류 누락과 형제 동기화 누락은 (a)(b) 에 해당한다.**
- 그 외 — 문서화 상세도, 절차 정교화, 재현성 개선 제안, 설계 밖 시나리오 보강 — 는 Minor(non-blocking)로 보고한다.
- 다른 정본 문서·스크립트가 해당 내용을 이미 담고 있고 설계가 이를 참조하면, 설계 본문에 중복 기술이 없다는 이유로 blocking을 만들지 않는다.

> 이 기준은 아래 Exhaustiveness 보다 **먼저** 적용된다. 전수 보고 의무는 심각도를 올리는 근거가 아니다.

## Exhaustiveness (필수)

- 제공된 **현재 revision**과 이 문서 상단에 명시된 리뷰 범위에서 확인한 모든 근거 있는 이슈를 한 응답에 보고한다. Top-N 제한이나 출력 절약을 목적으로 발견한 이슈를 고의로 보류하거나 라운드별로 분할하지 않는다.
- 추측이나 문서화되지 않은 스타일 선호는 이슈로 만들지 않는다. 각 이슈에 위반 규칙, 영향, 근거, 수정 방향을 명시한다.
- 심각도는 **Critical/Major/Minor**로 분류한다. Critical과 Major는 blocking, Minor는 non-blocking이다. Minor 및 범위 내 문서 정합성 이슈도 생략하지 않되, 전수 보고가 모든 Minor의 수정을 요구한다는 뜻은 아니다.
- 라인 지정이 가능하면 `file:line`을 사용하고, 멀티 레포면 `repo:file:line`으로 구분한다. 불가능하면 경로, 심볼, UI 노드, 명령 결과, 누락 산출물과 해당 요구사항 근거를 제시한다.
- 동일 원인·동일 수정 방법·동일 심각도의 반복만 한 항목으로 묶고, 확인된 모든 위치를 나열한다.
- 자료 누락, 도구 실패, 컨텍스트 또는 출력 한계로 범위 전체를 검토하지 못했으면 `REVIEW STATUS: INCOMPLETE`로 판정하고 미검토 범위를 나열한다. 이 경우 Approve/PASS를 내리지 않는다.
- 재리뷰에서는 수정된 revision을 다시 검토한다. 새로 도입되거나 드러난 이슈 및 이전에 누락된 이슈는 숨기지 말고 `newly introduced`, `newly exposed`, `previously missed`로 원인을 표시해 보고한다.

## Output

```
## Codex Design Review — {slug} (SKELETON)

### REVIEW STATUS: COMPLETE | INCOMPLETE

### 기획서(레포별) / 테스트 시나리오
- ...
### 파생 영향도 분류 · 형제 스켈레톤 일관성
- ...
### Blocking Findings (Critical/Major)
- ...
### Non-blocking Findings (Minor)
- ...
DECISION: Approve | Request Changes
```

Request Changes on 계약/아키텍처 위반, **파생 영향도 분류·전파 설계 부재**, **형제 스켈레톤 반영 누락**, 약어 사용, 명명 규칙 위반, 테스트 커버리지 공백, 대상 레포 `CLAUDE.md` 와의 모순.
