# 기획서 — internal-api (`../spring-boot-internal-api-skeleton`)

- 상위 계획: [`설계_계획.md`](설계_계획.md) · 근거: [`리뷰_이력.md`](리뷰_이력.md)
- 파생 영향도 분류: 규약 변경 + 결함 수정 (설계 계획 §4)

## 1. 요구사항

[`기획서_public-api.md`](기획서_public-api.md) §1 의 P2~P7·P9·P10 을 그대로 적용한다.
- P1(구분 코드 통일): 해당 없음 — internal `ErrorCode` 에는 `UNAUTHORIZED_ERROR`·`CONFLICT_ERROR` 가 없다. 공통 코드표의 다른 공통 코드는 이미 같은 값이다(`scripts/error-code-parity.sh` 가 internal 도 대조한다).
- P8(필터 체인 문구): 해당 없음 — internal 에는 인증·`AccessDeniedException` 이 없다.
- P10 의 문서는 `README.md`·`CLAUDE.md` 뿐이다(internal 에는 `docs/ERROR_CODES.md` 가 없다).

## 2. 응답 변화

| 상황 | 지금 | 바뀐 뒤 |
|---|---|---|
| 헤더 누락 | 400 · `REQUEST_BODY_MISSING_ERROR` · G002 | 400 · `NOT_VALID_HEADER_ERROR` · G012 |
| `JacksonException` 단독 | 400 · `REQUEST_BODY_MISSING_ERROR` · G002 | 400 · `JACKSON_PROCESS_ERROR` · G007 |
| `ExampleWebClient` 연결 실패 | 502 · `EXTERNAL_API_ERROR` · G014 | 503 · `SERVICE_UNAVAILABLE_ERROR` · G016 |
| 외부 API 직접 호출의 연결 실패(`WebClientRequestException` 이 핸들러까지 옴) | 500 · `INTERNAL_SERVER_ERROR` · G999 (캐치올) | 503 · `SERVICE_UNAVAILABLE_ERROR` · G016 — public 과 같은 핸들러 추가 |

## 3. 응답 문구

public 기획서 §3 표에서 인증 없음·권한 없음 두 행을 뺀 것과 같다. 코드 제목(`resultMessage`)은 public 기획서 §4 표에서 internal 에 있는 코드만 같은 값으로 바꾼다. P11 도 적용한다. `handler/ErrorReason.kt` 는 public 과 같은 파일이다(장치 A `full` 표면).
