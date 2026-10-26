# 기획서 — public-api (`../spring-boot-public-api-skeleton`)

- 상위 계획: [`설계_계획.md`](설계_계획.md) · 근거: [`리뷰_이력.md`](리뷰_이력.md)
- 파생 영향도 분류: 규약 변경 (설계 계획 §3)

## 1. 요구사항

| 키 | 요구사항 | 검증 |
|---|---|---|
| P1 | 업무 예외는 모두 `CodedException` 을 상속한다. HTTP 상태·`code`·`divisionCode` 는 예외가 가진 `errorCode` 하나가 정한다 | `ExceptionTest` — 각 예외의 `errorCode` |
| P2 | 새 업무 코드는 `ErrorCode` 항목 하나와 `throw CodedException(ErrorCode.X)` 한 줄로 만들 수 있다. 전용 예외 클래스·전용 핸들러가 필요 없다 | `ErrorResponseContractIntegrationTest` — `CodedException` 직접 던짐 |
| P3 | 공통 예외에는 문자열 code 를 받는 통로가 없다. `ExceptionCode`·`ErrorMessageService`·`DefaultErrorMessageService`·`ErrorMessageDto` 가 없다 | 컴파일 + 잔존 `rg` hit 0 |
| P4 | `ErrorResponseModel` 로 나가는 모든 오류 응답에서 본문 `status` 는 HTTP 상태와 같다. 필터 체인 단계의 `SecurityErrorResponseWriter` 는 이미 `errorCode.status` 로 상태를 정하므로 바꾸지 않는다. OAuth2 프로토콜 엔드포인트의 RFC 6749 본문은 대상이 아니다 | `ErrorResponseContractIntegrationTest` |
| P5 | 모든 `ErrorCode` 항목의 status 는 400~599 이고 `divisionCode` 는 서로 다르다 | `ErrorCodeContractTest` |
| P6 | HTTP 상태는 지금과 하나도 다르지 않다. 바뀌는 것은 §3 표의 본문 값뿐이다 | `GlobalExceptionHandlerTest` — 상태 단언 유지 |
| P7 | 인증 예외의 응답(상태·`code`·`divisionCode`·`reason`)은 지금과 같다 | `GlobalExceptionHandlerTest` — 인증 예외 케이스 |
| P8 | README·CLAUDE.md·`docs/ERROR_CODES.md` 등 문서가 새 규칙과 §3 응답을 그대로 적는다 | 문서 대조 + 잔존 `rg` |

## 2. 예외 계층

```
RuntimeException
└── CodedException(errorCode, message = errorCode.message, cause = null)   ← open, 직접 던질 수 있다
    ├── ClientBadRequestException(message, cause)        BAD_REQUEST_ERROR 400 G001
    │   └── InvalidRequestParameterException(message)    BAD_REQUEST_ERROR 400 G001
    ├── ItemNotFoundException(message, cause)            NOT_FOUND_ERROR 404 G009
    ├── ApiCallException(message, errorCode = EXTERNAL_API_ERROR, cause)   502 G014 / 503 G016
    └── AuthException(errorCode, message, cause)         ← abstract
        ├── AuthenticationException · UnauthorizedException · InvalidTokenException   UNAUTHORIZED_ERROR 401 G007A
        ├── ForbiddenException · AuthorizationException                               FORBIDDEN_ERROR 403 G008
        ├── DuplicateUserException · DuplicateResourceException                       CONFLICT_ERROR 409 G008A
        ├── ResourceNotFoundException                                                 NOT_FOUND_ERROR 404 G009
        ├── AccountLockedException                                                    ACCOUNT_LOCKED_ERROR 423 AUTH001
        └── MfaException(errorCode, message)                                          MFA001~MFA006
```

- `OAuth2Exception` 은 이 계층 밖이다 — RFC 6749 본문을 쓰는 OAuth2 엔드포인트 전용이다.
- 예외를 던지는 계층은 바뀌지 않는다(BizService·EntityService·MappingService·Client). 핸들러는 `handler/GlobalExceptionHandler.kt` 하나다.

## 3. 응답 변화

HTTP 상태는 그대로다. 본문만 바뀐다.

| 상황 | HTTP | 본문 지금 (`status` · `code` · `divisionCode`) | 바뀐 뒤 |
|---|---|---|---|
| 검증 실패 (`MethodArgumentNotValidException`·`ConstraintViolationException`·`MethodArgumentTypeMismatchException`·`IllegalArgumentException`) | 400 | 404 · `NOT_VALID_ERROR` · G011 | 400 · `NOT_VALID_ERROR` · G011 |
| `NullPointerException` | 500 | 404 · `NULL_POINT_ERROR` · G010 | 500 · 같음 |
| `IOException` | 500 | 400 · `IO_ERROR` · G005 | 500 · 같음 |
| `ApiCallException` 기본 | 502 | 500 · `INTERNAL_SERVER_ERROR` · G999 | 502 · `EXTERNAL_API_ERROR` · G014 |
| `ApiCallException(errorCode = SERVICE_UNAVAILABLE_ERROR)` | 503 | 500 · `INTERNAL_SERVER_ERROR` · G999 | 503 · `SERVICE_UNAVAILABLE_ERROR` · G016 |
| `WebClientRequestException` (외부 API 연결 실패) | 503 | 500 · `INTERNAL_SERVER_ERROR` · G999 | 503 · `SERVICE_UNAVAILABLE_ERROR` · G016 |
| 그 밖의 모든 오류 | 같음 | 같음 | 같음 |

`ErrorCode` 변경:
- status 교정: `IO_ERROR` 500 · `NULL_POINT_ERROR` 500 · `NOT_VALID_ERROR` 400 · `NOT_VALID_HEADER_ERROR` 400.
- 추가: `EXTERNAL_API_ERROR(502, "G014")` · `SERVICE_UNAVAILABLE_ERROR(503, "G016")`.
- 삭제: `INSERT_ERROR` · `UPDATE_ERROR` · `DELETE_ERROR` (status 200, 사용처 0).

## 4. 핸들러 규칙

- `CodedException` 은 핸들러 하나가 받는다. 응답은 `ErrorResponseModel.of(errorCode, ex.message)`, HTTP 상태는 `errorCode.status`.
- 프레임워크 예외(검증·Jackson·404 경로·`AccessDeniedException`·`WebClientRequestException`·캐치올)는 각자 핸들러가 `ErrorCode` 를 고르고, 응답 상태는 그 코드의 status 로 정한다. HTTP 상태를 코드와 따로 정하는 핸들러는 없다.
- 업무 예외(`CodedException`) 로그: 4xx 는 `warn`(구분 코드·예외 이름·메시지), 5xx 는 `error`(스택 포함). 업무 예외의 4xx 응답 `reason` 은 예외 메시지이므로 사용자에게 보여도 되는 문장으로 쓴다(지금과 같은 규칙).
- 프레임워크 예외 핸들러는 지금의 로그 수준과 `reason` 구성(`MethodArgumentNotValidException` 의 `필드: 메시지` 조합 등)을 유지한다. 바뀌는 것은 응답 상태를 `errorCode.status` 로 정하는 것뿐이다.

## 5. 문서 요구사항

| 파일 | 내용 |
|---|---|
| `README.md` 「코딩 규약」 | 예외 규칙 문장 교체 (3레포 공통 문장, `테스트_시나리오.md` 의 문서 시나리오) |
| `CLAUDE.md` 「5. Exception Handling Pattern」 | 규칙·예외 목록·검출 테스트 |
| `docs/ERROR_CODES.md` | §3 의 status·코드 반영, G014·G016 추가(상단 「HTTP 상태 코드」 표에 502·503 행 포함), 9999 삭제, 인증 예외 절(`AuthenticationException` 예시의 잘못된 `"divisionCode": "G008"` → `G007A`), 「새 에러 코드 추가」 절 |
| `docs/INTEGRATION_GUIDE.md` · `docs/API_REFERENCE.md` · `docs/TROUBLESHOOTING.md` | §3 과 다른 응답 예시가 있으면 교정 |
