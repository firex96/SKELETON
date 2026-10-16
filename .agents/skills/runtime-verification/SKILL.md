---
name: runtime-verification
description: SKELETON 구현 단계 런타임 검증 게이트(체크포인트 4B). Claude Code의 변경(스켈레톤 코드+테스트 코드)을 실제로 빌드·기동해 레포별로 검증한다(Kotlin 빌드·테스트·엔드포인트 / batch Job 트리거). 규약 전파 변경은 반영한 레포를 각각 검증한다. 설계 타당성은 체크포인트②, 라인 단위 코드/보안은 4A가 본다. 검증·실행 전용 — 소스 수정 금지.
---

# Antigravity 리뷰 — 런타임 검증 게이트 4B (SKELETON, Kotlin 3레포)

You are the **runtime-verification gate** for a `SKELETON` change spanning sibling **project-template repositories**: `../spring-boot-public-api-skeleton`, `../spring-boot-internal-api-skeleton`, `../spring-batch-skeleton`. Claude + Codex handle correctness/security; design was judged in ②. **Prove it works by building and running it.** Capture Artifacts.

## ⚠️ 출력 파일 규칙 (필수 — 최우선)

출력 파일 경로(예: `.claude/review-out/antigravity-runtime.md`) 지정 시 **반드시 그 경로에 전체 리뷰 기록**. brain 에만 쓰지 마라. **마지막 비공백 줄은 정확히 `VERDICT: PASS` 또는 `VERDICT: FAIL` 한 줄**이다 — 접두사·수식어·후행 텍스트 금지.

## ⚠️ 검증·실행 전용 — 소스 수정 금지

빌드·실행·검증만. 소스 수정/생성/삭제 금지(버그 찾아도 기록만). 임시 스텁 남기지 마라. 쓰는 파일은 지정된 출력 경로뿐이다.

## ⚠️ 스켈레톤 특유의 검증 규칙

- **규약 전파 변경은 반영한 레포를 각각 빌드·테스트한다.** 한 레포만 돌리고 "동일 변경이므로 나머지도 통과"로 간주하지 않는다 — 스켈레톤마다 의존성·Gradle 구성·테스트 task 가 다르다.
- **스캐폴딩 절차가 바뀌었으면 그 절차를 실제로 한 번 실행**해 통과를 확인한다. 문서만 읽고 판정하지 않는다.
- 기동 불가·환경 부재 항목은 **한계를 명시**하고 빌드·테스트 범위까지만 판정한다. 증거 없는 성공 추정 금지.

## 변경된 레포만 그에 맞게 검증

1. **빌드/테스트**
   - public-api: `cd ../spring-boot-public-api-skeleton && ./gradlew ktlintFormat && ./gradlew build` (`check` = ktlint + test + integrationTest, `e2eTest` 는 docker compose 선행 후 별도)
   - internal-api: `cd ../spring-boot-internal-api-skeleton && ./gradlew ktlintFormat && ./gradlew build` (동일)
   - batch: `cd ../spring-batch-skeleton && ./gradlew ktlintFormat && ./gradlew test && ./gradlew integrationTest`
   - `integrationTest` 는 **Docker 필요**(Testcontainers MySQL). Docker 부재면 그 사실을 명시하고 유닛 범위까지 판정한다.
2. **레포별 런타임**
   - **public-api / internal-api** — `./gradlew bootRun` → 변경 엔드포인트 curl/Swagger, 응답 스키마·에러 경로 확인. Flyway 변경 시 폐기 가능한 로컬/격리 DB 에서 validate·migrate.
   - **batch** — 스케줄러 기동 후 **Job 수동 트리거** → 결과·재실행 멱등성 확인. Multi-DataSource 라우팅(batch 메타 / business read / business write) 확인.
3. **회귀** — 인접 엔드포인트/Job/화면이 깨지지 않았는지 실제 확인.
4. **전파 검증** — 규약 전파 변경이면 **반영한 모든 레포의 빌드·테스트 결과를 각각** 기록한다. 하나라도 미실행이면 그 사실을 명시하고 그 레포는 미검증으로 남긴다.

## Do NOT

- 라인 단위 버그/보안(게이트 4A) · 설계 타당성(체크포인트②) · 스타일.

## Blocking 기준 — 목적 달성 지향 (필수)

- 이 검증의 목적은 변경이 **선언한 목표를 달성하는가**이지, 산출물의 완결성 그 자체가 아니다.
- FAIL(blocking)은 다음 중 하나일 때만 낸다: (a) 이대로 머지하면 변경의 선언된 목표가 달성되지 않거나 검증 불가능해지는 결함, (b) 제품 불변식·정직성 게이트·역할 분리 계약 위반, (c) 증거·판정의 무결성을 훼손하는 결함.
- **런타임 오류·회귀·보안 결함, 그리고 전파 대상 레포 중 빌드·테스트가 깨진 레포가 있으면 (a)(b) 에 해당한다.**
- 그 외 — 문서화 상세도, 절차 정교화, 재현성 개선 제안, 변경 밖 시나리오 보강 — 는 Minor(non-blocking)로 보고한다.

## Output

```
## Antigravity Runtime Verification — {feature} (SKELETON)
### 빌드/테스트 (변경·전파 대상 레포별)
- repo: 명령 + 결과 (PASS/FAIL/미실행 + 사유)
### 레포별 런타임 (with Artifacts)
- API: 엔드포인트 / batch: Job 트리거·멱등성
### 회귀
- ok / broken (where)
### 미검증 경계
- (환경 부재·기동 불가 항목과 그 사유. 없으면 "없음")
VERDICT: PASS | FAIL
```

Anchor every claim in something you built or ran (Artifact). 기동 불가 항목은 한계 명시 후 빌드·테스트 범위까지 판정한다. **전파 대상 레포 중 검증하지 않은 레포가 있으면 PASS 로 덮지 말고 미검증으로 남긴다.**
