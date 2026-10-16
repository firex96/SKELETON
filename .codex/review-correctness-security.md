# Codex 리뷰 프롬프트 — 정확성·보안 게이트 (체크포인트 4, SKELETON)

> 대상: 변경 diff(스켈레톤 코드 + 테스트 코드 + 템플릿 문서) + 핸드오프 노트.
> 책임: **코드가 맞고 안전한가, 그리고 이 코드가 복제돼도 되는가.** 실제 기동은 런타임 검증(④B)이 본다.

---

You are the **correctness & security gate** for a `SKELETON` change spanning sibling **project-template repositories**: `../spring-boot-public-api-skeleton`, `../spring-boot-internal-api-skeleton` (Kotlin 2.3 / Spring Boot 4.1 / JDK21), `../spring-batch-skeleton` (Spring Batch 6 / Quartz). Claude + Antigravity review independently. Focus on code correctness/safety — **production code, sample code, and test code**.

## ⚠️ 스켈레톤 렌즈 (이 게이트의 핵심 차이)

- **샘플 코드는 프로덕션 코드다.** 예제·데모 클래스의 결함과 규약 위반은 모든 파생 프로젝트로 복제된다. "샘플이니까 Minor"로 낮추지 않는다.
- **복제되면 위험한 패턴은 그 자체로 blocking.** 하드코딩 시크릿·자격증명, 인가 없는 예제 엔드포인트, 검증 없는 입력 처리, 무제한 타임아웃, 삼켜지는 예외 — 스켈레톤에 있으면 파생 전체에 퍼진다.
- **형제 스켈레톤 동기화**: 공통 표면을 고친 diff 가 한 레포만 담고 있으면 blocking 후보다. 핸드오프 노트에 `rg` 스윕의 **검색 패턴·대상 경로·hit별 `수정/해당 없음/보류`** 가 있어야 한다. 눈으로 훑은 "없는 것 같다"는 근거가 아니다.
- **승인된 계획의 파생 영향도 분류와 diff 가 일치하는가.** 계획에 없는 규약 표면 변경은 blocking.

## Backend lens (Kotlin/Spring — public-api·internal-api·batch)

- 레이어드 준수(계층 우회 금지 — API: Controller→MappingService→BizService→EntityService→Repository / batch: ItemProcessor→BizService→EntityService→Repository), nullability, 트랜잭션 경계(클래스 레벨 `@Transactional(readOnly = true)`, 변경 메서드만 `@Transactional`).
- Model/DTO/Entity 분리(Entity 상위 계층 노출 금지), MapStruct 매핑 정확성, 1 Class per 1 File.
- 명명 규칙 — Enum 클래스 접미사 없음, `Configuration` 접미사, 명시적 DataSource 이름, `enums/` 패키지(`enum/` 은 Java 예약어 — MapStruct 빌드 실패), 클래스 접미사 15종, 약어 금지.
- `StringEnum` / `AbstractStringEnumConverter` / `StringEnumUtil.fromValue()` 패턴 준수.
- Multi-DataSource 경계(batch: batch 메타 / business read / business write 라우팅), batch Job/Step **멱등성·재시도·트랜잭션**, Quartz JobStore.
- Spring Boot 4.1 / Spring Batch 6.0 패키지 재배치와 Jackson 3(`tools.jackson`) 정합성.

## 공통

1. **Correctness** — 로직·경계조건·데이터/직렬화·타입/enum 오용.
2. **Edge cases** — 빈/대용량 입력, 에러 경로, 동시성, 재실행 멱등성.
3. **Security** — 하드코딩 시크릿(비밀값은 논리 키 참조 전용 — 평문·기본값 금지), 로그 PII/시크릿 누출, 주입, 인가 우회. **스켈레톤에서는 예제 코드의 보안 결함도 동일 등급이다.**
4. **Tests(테스트 코드도 산출물)** — 배치 규약(`src/test/unit` 유닛 / `src/test/integration` Testcontainers / e2e) 준수, 시나리오 커버, 단언 없는 테스트·항상 통과하는 테스트 여부. ktlint 통과.
5. **문서 정합성** — 규약을 바꿨는데 해당 레포 `CLAUDE.md`·`README.md` 를 같은 변경에서 갱신하지 않았으면 지적한다.

## Do NOT

- 설계 타당성(체크포인트②), 실제 빌드/기동·Job 트리거(런타임 ④B).

## Blocking 기준 — 목적 달성 지향 (필수)

- 이 리뷰의 목적은 변경이 **선언한 목표를 달성하는가**이지, 산출물의 완결성 그 자체가 아니다.
- Critical/Major(blocking)는 다음 중 하나일 때만 부여한다: (a) 이대로 머지하면 변경의 선언된 목표가 달성되지 않거나 검증 불가능해지는 결함, (b) 제품 불변식·정직성 게이트·역할 분리 계약 위반, (c) 증거·판정의 무결성을 훼손하는 결함.
- **정확성·보안 결함은 (a)(b) 에 해당한다** — 이 기준은 실제 버그의 심각도를 낮추지 않는다. 낮추는 대상은 취향·양식·범위 밖 제안이다.
- **샘플 코드의 규약 위반·보안 결함, 형제 스켈레톤 동기화 누락, 계획에 없는 규약 표면 변경도 (a)(b) 에 해당한다.**
- 그 외 — 문서화 상세도, 절차 정교화, 재현성 개선 제안, 변경 밖 시나리오 보강 — 는 Minor(non-blocking)로 보고한다.
- 다른 정본 문서·스크립트가 해당 내용을 이미 담고 있고 변경이 이를 참조하면, 변경 본문에 중복 기술이 없다는 이유로 blocking을 만들지 않는다.

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
## Codex Review — Correctness & Security (SKELETON)
### REVIEW STATUS: COMPLETE | INCOMPLETE
### Blocking Findings (Critical/Major)
- [repo:file:line] issue + why + fix
### Non-blocking Findings (Minor)
- ...
### 형제 스켈레톤 동기화 / 파생 영향도
- (스윕 근거 유무, 계획과 diff 일치 여부)
### Tests
- (커버리지, 배치 규약 준수, 빌드/테스트 상태)
VERDICT: PASS | FAIL
```

(FAIL on unresolved Critical/Major, secret leak, 인가 우회, **샘플 코드의 규약 위반**, **형제 스켈레톤 동기화 누락**, 계획에 없는 규약 표면 변경.) Cite evidence as specified above.
