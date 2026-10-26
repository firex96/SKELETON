# 기획서 — spring-boot-public-api-skeleton

상위 계획: [`설계_계획.md`](설계_계획.md). 근거: [`리뷰_이력.md`](리뷰_이력.md).

## P1. 상태 기반 일괄 처리

### 새 코드 (`enums/ErrorCode.kt`)

| 이름 | HTTP | 구분 코드 | 제목(`resultMessage`) |
|---|---|---|---|
| `METHOD_NOT_ALLOWED_ERROR` | 405 | G017 | Method Not Allowed |
| `NOT_ACCEPTABLE_ERROR` | 406 | G018 | Not Acceptable |
| `PAYLOAD_TOO_LARGE_ERROR` | 413 | G019 | Payload Too Large |
| `UNSUPPORTED_MEDIA_TYPE_ERROR` | 415 | G020 | Unsupported Media Type |

`SERVICE_UNAVAILABLE_ERROR`(503 G016)는 그대로 두고 공통 코드가 된다(SKELETON 코드표).

### 상태 → 코드 (`ErrorCode.fromStatus`)

| 상태 | 코드 |
|---|---|
| 400 | `BAD_REQUEST_ERROR` |
| 401 | `UNAUTHORIZED_ERROR` |
| 403 | `FORBIDDEN_ERROR` |
| 404 | `NOT_FOUND_ERROR` |
| 405 · 406 · 413 · 415 | 위 새 코드 |
| 409 | `CONFLICT_ERROR` |
| 423 | `ACCOUNT_LOCKED_ERROR` |
| 500 | `INTERNAL_SERVER_ERROR` |
| 502 | `EXTERNAL_API_ERROR` |
| 503 | `SERVICE_UNAVAILABLE_ERROR` |
| 그 밖의 4xx | `BAD_REQUEST_ERROR` (400) |
| 그 밖의 5xx | `INTERNAL_SERVER_ERROR` (500) |

### 처리

- 캐치올(`Exception`) 핸들러가 `ex is ErrorResponse` 이면 `fromStatus(ex.statusCode.value())` 로 코드를 고르고 `ErrorReason.forStatus(code.status)` 문장으로 응답한다.
- 코드 상태가 원래 상태와 같으면 `ErrorResponse.headers` 를 응답에 싣는다. 405 의 `Allow`, 415 의 `Accept` 가 여기에 해당한다(RFC 9110). 대체 코드로 바뀐 경우에는 싣지 않는다.
- 덮는 예외(Spring 기본): `HttpRequestMethodNotSupportedException` 405 · `HttpMediaTypeNotSupportedException` 415 · `HttpMediaTypeNotAcceptableException` 406 · `MaxUploadSizeExceededException` 413 · `AsyncRequestTimeoutException` 503 · `MissingPathVariableException` 500 · `MissingServletRequestPartException`·`ServletRequestBindingException`·`HandlerMethodValidationException` 400 · `ResponseStatusException`(임의 상태).
- 지금의 전용 핸들러(404·바인딩·검증·헤더·타입 불일치·본문)는 그대로 우선한다.

### 문장 (`handler/ErrorReason.kt`, internal 과 같은 파일)

| 상태 | 문장 |
|---|---|
| 401 · 403 | `AUTHENTICATION_REQUIRED` 「인증이 필요합니다」 · `ACCESS_FORBIDDEN` 「접근 권한이 없습니다」 — `AccessDenial` 과 같은 상수 |
| 404 | `PATH_NOT_FOUND` (기존) |
| 405 | 「허용되지 않는 요청 방식입니다.」 |
| 406 | 「요청한 응답 형식을 제공할 수 없습니다.」 |
| 413 | 「요청 본문이 너무 큽니다.」 |
| 409 | 「요청이 현재 상태와 충돌합니다.」 |
| 415 | 「지원하지 않는 요청 본문 형식입니다.」 |
| 423 | 「요청한 대상이 잠겨 있습니다.」 |
| 그 밖의 4xx | `BAD_REQUEST` (기존) |
| 5xx | `respond` 가 `forServerError` 로 고른다 (P3) |

## P2. 401·403 코드·문장 짝 (`enums/AccessDenial.kt`)

- `enum class AccessDenial(val errorCode: ErrorCode, val reason: String)` — `AUTHENTICATION_REQUIRED(UNAUTHORIZED_ERROR, "인증이 필요합니다")` · `ACCESS_FORBIDDEN(FORBIDDEN_ERROR, "접근 권한이 없습니다")`. 문장 값은 지금과 같다.
- 쓰는 곳: `SecurityConfiguration` 진입점·거부 핸들러, `SecurityErrorResponseWriter.write(response, denial: AccessDenial)`, `GlobalExceptionHandler` 의 `AccessDeniedException` 핸들러(익명 → `AUTHENTICATION_REQUIRED`, 그 밖 → `ACCESS_FORBIDDEN`).
- `ErrorReason.UNAUTHORIZED`·`FORBIDDEN` 은 `AUTHENTICATION_REQUIRED`·`ACCESS_FORBIDDEN` 으로 이름을 바꾸고 `AccessDenial` 이 이 상수를 참조한다(문장 값의 출처는 하나, 짝은 `AccessDenial`). 테스트(e2e `ErrorResponseFormatE2ETest`, 통합 `GlobalExceptionHandlerTest`)는 `AccessDenial.*.reason` 을 단언한다.
- `SecurityErrorResponseWriter` 가 다른 코드로 쓰이는 곳이 있으면 ③ 에서 시그니처를 정한다(사전 스윕 hit 는 두 곳뿐).

## P3. 5xx 문장 (`ErrorReason.forServerError`)

- 코드 상태가 502·503·504 이면 `EXTERNAL_SERVICE_ERROR`, 그 밖의 5xx 는 `SERVER_ERROR`. 코드 이름 비교를 없앤다. 지금 값과 결과가 같다(502 `EXTERNAL_API_ERROR`·503 `SERVICE_UNAVAILABLE_ERROR`).
- 503 `AsyncRequestTimeoutException` 도 외부 서비스 문장이 된다. 스켈레톤에 비동기 MVC 엔드포인트가 없어 받아들인다(근거: 리뷰_이력.md 「503 문장」).

## P4. 문서

- `docs/INTEGRATION_GUIDE.md`(CRLF) 전면 교정 — 설계 계획 §3.5. 실제 계약은 아래와 같다.
  - **경로:** context-path 가 없다. 포트는 8080 이다.
  - **회원 가입:** `POST /auth/signup` → 201 `AuthUserInfoModel`.
  - **로그인:** `POST /auth/login` → 200 `TokenResponseModel` 또는 202 `MfaChallengeModel`(`mfaToken`·`expiresIn`·`methods`). 202 를 받으면 `POST /auth/login/mfa` 로 `{mfaToken, method, code}` 를 보낸다.
  - **토큰 갱신:** `POST /auth/refresh` → `AccessTokenResponseModel`(새 refresh token 없음, 회전 없음).
  - **로그아웃:** `POST /auth/logout` → 204 빈 본문. access token 이 필요하다.
  - **내 정보:** `GET /users/me` → `AuthUserInfoModel`. 필드는 `id`(Long)·`loginId`·nullable `email`·`name`·`nickname`·`phone`·`profileImage`·`groups` 다.
  - **소셜 웹:** `GET /auth/oauth2/{provider}/authorize` → 서버 콜백 → `/demo/auth/callback` → `POST /auth/session/token`(세션 쿠키 + CSRF 헤더, 한 번). 같은 출처 전용이다(브라우저 체인 CORS 비활성).
  - **소셜 네이티브:** `POST /auth/oauth2/{provider}/login {code, deviceType?, deviceInfo?}` → 200 또는 202. access token·ID token 로그인은 지원하지 않는다.
  - **`client_credentials`:** `POST /oauth2/token` 으로 토큰을 받는다. 이 스켈레톤의 API(`/admin/**` 포함)는 이 토큰을 받지 않는다. 받는 쪽은 다른 자원 서버이고, 자기 클라이언트 자격으로 `POST /oauth2/introspect` 를 불러 검증한다. access token 은 HMAC 서명이라 JWKS(`/.well-known/jwks.json`, RS256 공개키)로는 검증되지 않는다. JWKS 는 ID token 검증용이다.
  - **인가 코드 + PKCE:** 토큰 교환은 시크릿을 가진 서버 측에서 한다(모든 클라이언트에 시크릿이 필요하다). 브라우저 단독 교환은 지원하지 않는다.
  - **401 재시도:** `/auth/login`·`/auth/refresh` 응답에는 재시도하지 않는다.
  - **문서 내부 정합:** `AuthApi`·`setTokens`·`fetchUser` 의 정의를 맞춘다.
- `docs/TROUBLESHOOTING.md:169,187`, `docs/SECURITY_CHECKLIST.md:220-222` 의 경로에서 `/api/v1` 을 뺀다. `CLAUDE.md:155` Controller 예시는 실제 `ProductRestController`(`/products`, `id: Long`)에 맞춘다.
- `docs/ERROR_CODES.md`(CRLF): G016 절에 「공통 코드」 표기, G017~G020 절 추가, 「HTTP 상태 코드」 표에 405·406·413·415 행, 「클라이언트 처리 가이드」 예시 경로 점검.
- README·`CLAUDE.md` 의 예외 절: 「처리하지 않는 프레임워크 예외도 그 HTTP 상태와 그 상태의 코드로 응답한다」 한 문장(3레포 같은 문장).
- `CLAUDE.md:424` 의 「필터 체인 문구도 `ErrorReason` 을 쓴다」 서술을 「401·403 은 `AccessDenial` 이 코드와 문장을 함께 정하고 필터 체인·핸들러가 그것만 쓴다」로 바꾼다. README 의 같은 서술도 함께 바꾼다.
