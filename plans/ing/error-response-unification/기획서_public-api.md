# 기획서 — public-api (`../spring-boot-public-api-skeleton`)

- 상위 계획: [`설계_계획.md`](설계_계획.md) · 근거: [`리뷰_이력.md`](리뷰_이력.md)
- 파생 영향도 분류: 규약 변경 + 결함 수정 (설계 계획 §4)

## 1. 요구사항

| 키 | 요구사항 | 검증 |
|---|---|---|
| P1 | `UNAUTHORIZED_ERROR` 의 구분 코드는 G015, `CONFLICT_ERROR` 는 G013 이다. 상태(401·409)와 이름은 그대로다 | `ErrorResponseContractIntegrationTest` · `scripts/error-code-parity.sh` |
| P2 | `ErrorResponseModel` 의 `reason`·`resultMessage` 는 언제나 사용자에게 보여도 되는 문장이다. 내부·외부 기술 정보 — 클래스·패키지 이름, 예외 클래스 이름·메시지, SQL, URL, 스택, 외부 시스템의 응답 문구 — 를 담지 않는다. 요청이 보낸 식별자(로그인 ID·코드·경로 변수 id)를 메시지 대상으로 되돌려 주는 것은 허용한다 | `ErrorResponseContractIntegrationTest` — Jackson·타입 불일치·5xx 케이스에서 `com.rex`·`Exception`·`java.` 이 `reason`·`resultMessage` 에 없다 · `ErrorCodeContractTest` — 모든 `ErrorCode.message` 에 `Exception`·`.` 패키지 표기·한글 설명문이 없다 |
| P3 | 업무 예외 4xx 의 `reason` 은 예외 메시지 그대로다. 업무 예외 메시지에는 하위 예외 메시지(`e.message`)나 외부 시스템 응답 문구를 합치지 않는다 — 상세는 로그와 `cause` 에 남긴다 | `GlobalExceptionHandlerTest` · §3a 의 소셜 인증 테스트 |
| P4 | 5xx 의 `reason` 은 고정 문장이다(§3). 원래 메시지는 로그에만 남는다 | `GlobalExceptionHandlerTest` · `ErrorResponseContractIntegrationTest` |
| P5 | 헤더 누락은 400 `NOT_VALID_HEADER_ERROR` G012 다 | `GlobalExceptionHandlerTest` |
| P6 | 외부 API 연결 실패(원인 사슬에 `WebClientRequestException`)는 503 `SERVICE_UNAVAILABLE_ERROR`, 그 밖의 외부 API 실패는 502 `EXTERNAL_API_ERROR` 다 — 경로(`ExampleWebClient` 경유·직접 호출)와 무관 | `ExampleWebClientTest` · `GlobalExceptionHandlerTest` |
| P7 | 모든 오류 로그는 4xx `warn`(원래 메시지, 스택 없음), 5xx `error`(스택 포함)다 | 코드 검토(로그 호출이 `respond` 한 곳) |
| P8 | 필터 체인(엔트리포인트·거부 핸들러)과 `AccessDeniedException` 핸들러의 401·403 문구가 같다 | `GlobalExceptionHandlerTest` · 기존 `ErrorResponseFormatE2ETest` |
| P9 | 테스트 소스셋의 `.kt` 파일도 최상위 클래스가 하나다 | `OneClassPerFileConventionTest` |
| P10 | 문서(README·CLAUDE.md·`docs/ERROR_CODES.md`·`TROUBLESHOOTING.md`·`INTEGRATION_GUIDE.md`)가 바뀐 코드·문구 규칙·실제 성공 응답을 적는다 | 문서 대조 + 재스윕 |
| P11 | 공통 코드(`docs/error-codes.md`)의 `ErrorCode.message` 는 asp `ErrorCode.cs` 의 제목과 같다 | `scripts/error-code-parity.sh` |

HTTP 상태는 연결 실패 경로(502 → 503)만 바뀐다. 그 밖에 바뀌는 것은 401·409 의 `divisionCode`, 헤더 누락의 `code`·`divisionCode`, 연결 실패 경로의 502 → 503(§2), 프레임워크·5xx 의 `reason` 문구, 그리고 `resultMessage`(코드 제목) 문구다.

## 2. 응답 변화

| 상황 | 지금 (HTTP · code · divisionCode) | 바뀐 뒤 |
|---|---|---|
| 인증 실패 (필터 체인·`AuthenticationException` 등) | 401 · `UNAUTHORIZED_ERROR` · G007A | 401 · 같음 · **G015** |
| 충돌 (`DuplicateUserException` 등) | 409 · `CONFLICT_ERROR` · G008A | 409 · 같음 · **G013** |
| 헤더 누락 | 400 · `REQUEST_BODY_MISSING_ERROR` · G002 | 400 · **`NOT_VALID_HEADER_ERROR` · G012** |
| `JacksonException` 단독(본문 파싱 밖에서 올라온 경우) | 400 · `REQUEST_BODY_MISSING_ERROR` · G002 | 400 · **`JACKSON_PROCESS_ERROR` · G007** — 「본문 누락」이 아니라 형식 오류다 |
| `ExampleWebClient` 연결 실패 | 502 · `EXTERNAL_API_ERROR` · G014 | **503 · `SERVICE_UNAVAILABLE_ERROR` · G016** |

## 3. 응답 문구 (`reason`)

| 경우 | reason |
|---|---|
| 업무 예외 4xx (`CodedException`) | 예외 메시지 |
| 업무 예외 5xx 중 `EXTERNAL_API_ERROR`·`SERVICE_UNAVAILABLE_ERROR`, `WebClientRequestException` | 「외부 서비스가 응답하지 않아 요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.」 |
| 그 밖의 5xx (업무 예외 5xx, NPE, `IOException`, 캐치올) | 「일시적인 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.」 |
| `MethodArgumentNotValidException` | `필드: 검증 메시지` 를 `, ` 로 이은 것(필드는 `@JsonProperty` 이름) — 지금과 같다 |
| `ConstraintViolationException` | `파라미터: 검증 메시지` 를 `, ` 로 이은 것(파라미터는 propertyPath 마지막 노드) |
| `MethodArgumentTypeMismatchException` | 「'{파라미터 이름}' 값의 형식이 올바르지 않습니다.」 |
| `MissingServletRequestParameterException` | 「필수 파라미터 '{파라미터 이름}' 가 없습니다.」 |
| `MissingRequestHeaderException` | 「필수 헤더 '{헤더 이름}' 가 없습니다.」 |
| `HttpMessageNotReadableException` — Jackson 원인 있음 · `JsonParseException` · `JacksonException` | 「요청 본문의 형식이 올바르지 않습니다.」 |
| `HttpMessageNotReadableException` — Jackson 원인 없음 | 「요청 본문이 없습니다.」 |
| `IllegalArgumentException` | 「요청 값이 올바르지 않습니다.」 |
| `NoHandlerFoundException` · `NoResourceFoundException` | 「요청한 경로를 찾을 수 없습니다.」 |
| `NoSuchElementException` | 「요청한 대상을 찾을 수 없습니다.」 |
| `HttpClientErrorException.BadRequest` | 「잘못된 요청입니다.」 |
| 인증 없음 (필터 체인 · 익명의 `AccessDeniedException`) | 「인증이 필요합니다」 |
| 권한 없음 (필터 체인 · 인증된 `AccessDeniedException`) | 「접근 권한이 없습니다」 |

- 이 표의 프레임워크 오류 문장에는 파라미터·헤더·필드 이름(API 계약에 이미 드러난 이름)만 싣고 요청 값은 싣지 않는다. 업무 예외 메시지가 요청 식별자를 되돌려 주는 것은 P2 대로 허용한다.
- 문장은 public·internal 공용 `handler/ErrorReason.kt` 한 곳에 둔다.

## 3a. 업무 예외 메시지 교정 (착수 전 스윕 hit)

| 위치 | 지금 | 바뀐 뒤 (`reason`) | 상세 보존 |
|---|---|---|---|
| `service/auth/SocialAuthBizService.kt:91` | 「소셜 인증에 실패했습니다: ${e.message}」 | 「소셜 인증에 실패했습니다.」 | `cause = e`, 기존 `log.error("소셜 토큰 획득 실패: …")` 와 `auditBizService.logSocialLoginFailure(reason = …)` |
| `client/social/GoogleOAuth2Client.kt:79` | 「구글 토큰 발급 실패: ${error_description}」 | 「구글 토큰 발급에 실패했습니다.」 | 기존 `log.error("Google token error: {}", response)` |
| `client/social/KakaoOAuth2Client.kt:76` | 「카카오 토큰 발급 실패: ${error_description}」 | 「카카오 토큰 발급에 실패했습니다.」 | 기존 `log.error` |
| `client/social/NaverOAuth2Client.kt:74` | 「네이버 토큰 발급 실패: ${error_description}」 | 「네이버 토큰 발급에 실패했습니다.」 | 기존 `log.error` |
| `client/social/NaverOAuth2Client.kt:96` | 「네이버 사용자 정보 조회 실패: ${response.message}」 | 「네이버 사용자 정보 조회에 실패했습니다.」 | 기존 `log.error` |

스윕: `src/main` 의 업무 예외 생성 중 메시지에 `$` 보간이 있는 곳 39건(batch `details` 보간 3건 포함), 변수로 메시지를 넘기는 곳(`Exception\((e|ex|it|cause|error|t)\.message`) 0건. 위 5건 외의 보간은 요청이 보낸 식별자·남은 시간·개수라 **해당 없음**. `ExampleWebClient` 의 `ApiCallException("외부 API 호출 실패: ${e.message}")` 는 5xx 라 `reason` 이 고정 문장으로 바뀌므로 메시지는 로그용으로 남긴다 — **해당 없음**.

범위 밖: 소셜 콜백이 공급자의 `error`·`error_description` 을 데모 화면 리다이렉트 쿼리로 넘기는 경로(`SocialAuthController`)는 오류 응답 모델이 아닌 OAuth 관례의 전달이라 이번에 바꾸지 않는다.

## 4. 코드 제목 (`resultMessage` = `ErrorCode.message`)

public·internal 공통. 공통 코드는 asp 와 같은 값이다.

| 코드 | 지금 | 바뀐 뒤 |
|---|---|---|
| `BAD_REQUEST_ERROR` | Bad Request Exception | Bad Request |
| `REQUEST_BODY_MISSING_ERROR` | Required request body is missing | Request Body Missing |
| `INVALID_TYPE_VALUE` | ` Invalid Type Value` | Invalid Type Value |
| `MISSING_REQUEST_PARAMETER_ERROR` | Missing Servlet RequestParameter Exception | Missing Request Parameter |
| `IO_ERROR` | I/O Exception | I/O Error |
| `JSON_PARSE_ERROR` | JsonParseException | Malformed JSON |
| `JACKSON_PROCESS_ERROR` | tools.jackson.core Exception | Malformed Request Body |
| `UNAUTHORIZED_ERROR` (public) | Unauthorized Exception | Unauthorized |
| `ACCOUNT_LOCKED_ERROR` (public) | Account Locked Exception | Account Locked |
| `FORBIDDEN_ERROR` | Forbidden Exception | Forbidden |
| `CONFLICT_ERROR` (public) | Conflict Exception | Conflict |
| `NOT_FOUND_ERROR` | Not Found Exception | Not Found |
| `NULL_POINT_ERROR` | Null Point Exception | Internal Server Error |
| `NOT_VALID_ERROR` | handle Validation Exception | One or more validation errors occurred |
| `NOT_VALID_HEADER_ERROR` | Header에 데이터가 존재하지 않는 경우 | Missing Or Invalid Header |
| `INTERNAL_SERVER_ERROR` | Internal Server Error Exception | Internal Server Error |
| `MFA_*`·`EXTERNAL_API_ERROR`·`SERVICE_UNAVAILABLE_ERROR` | 이미 제목 형태 | 그대로 |

## 5. 문서 요구사항

| 파일 | 내용 |
|---|---|
| `README.md` 「코딩 규약」 | 예외 문장에 「오류 응답의 문구 필드에는 사용자에게 보여도 되는 문장만 싣는다 — 업무 예외 4xx 는 예외 메시지(하위 예외·외부 응답 문구를 합치지 않는다), 검증 실패는 필드별 검증 메시지, 그 밖은 고정 문장. 내부 상세는 로그에 남긴다」 추가 (3레포 같은 문장 — 레포별 필드 이름은 각 CLAUDE.md 에 둔다) |
| `CLAUDE.md` 「5. Exception Handling Pattern」 | 문구 규칙·로그 규칙·검출 테스트 |
| `docs/ERROR_CODES.md` | G015·G013, 코드 제목(§4)과 응답 예시의 `resultMessage`, 에러 응답 형식 표의 `reason` 정의, G012 원인에 헤더 누락, 5xx 고정 문장, 인증 예외 표 |
| `docs/TROUBLESHOOTING.md` | 401 예시 G015 |
| `docs/INTEGRATION_GUIDE.md` | 성공 응답은 `~Model` 그대로(래퍼 없음) — 예시와 클라이언트 코드(`ApiResponse<T>`) 교정, 오류 응답 예시의 G011 문구 |
