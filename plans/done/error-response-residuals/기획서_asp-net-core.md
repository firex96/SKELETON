# 기획서 — asp-net-core-skeleton

상위 계획: [`설계_계획.md`](설계_계획.md). 이 레포의 규칙 정본은 `../asp-net-core-skeleton/CLAUDE.md` 다(규약 테스트 `UnitTests/Conventions/`, 템플릿 `#if` 주석 보존, 「규칙에 예외 케이스를 두지 않는다」).

## 현재 동작 (2026-10-26 실행 확인)

같은 라우팅 구성(`[ApiController]` + `AddProblemDetails` + `UseExceptionHandler` + `UseStatusCodePages` + `MapFallbackToFile`)으로 만든 최소 앱에 요청한 결과다(스크래치 앱, 레포 미변경).

| 요청 | 응답 |
|---|---|
| 스크래치 앱의 GET 전용 `/api/products/{id}` 에 DELETE (실제 Server 의 같은 경로에는 DELETE 가 있다) | 405 ProblemDetails, `Allow: GET, HEAD` — 폴백이 가로채지 않는다 |
| `GET /api/nothing` (없는 API 경로) | **200 `text/html`(SPA 화면)** — 404 가 아니다 |
| `POST /api/products` `text/plain` | 415 ProblemDetails |
| `POST /api/products` `{"price":"abc"}` | 400, `errors`: `"$.price": ["The JSON value could not be converted to Req. Path: $.price | LineNumber: 0 | BytePositionInLine: 25."]`, `"r": ["The r field is required."]` |
| `POST /api/products` `{}` | 400, `errors`: `"Name": ["The Name field is required."]` |

이 레포에서는 405·415 의 코드가 `FromStatus` 대체값 G001 이 된다(`ByStatus` 에 없음).

## A1. 코드 (`Common/Errors/ErrorCode.cs`)

- 정적 필드 다섯 개를 추가하고 `ByStatus` 에 넣는다.
  - `MethodNotAllowed` `("METHOD_NOT_ALLOWED_ERROR", 405, "G017", "Method Not Allowed")`
  - `NotAcceptable` `("NOT_ACCEPTABLE_ERROR", 406, "G018", "Not Acceptable")`
  - `PayloadTooLarge` `("PAYLOAD_TOO_LARGE_ERROR", 413, "G019", "Payload Too Large")`
  - `UnsupportedMediaType` `("UNSUPPORTED_MEDIA_TYPE_ERROR", 415, "G020", "Unsupported Media Type")`
  - `ServiceUnavailable` `("SERVICE_UNAVAILABLE_ERROR", 503, "G016", "Service Unavailable")`
- 상태 범위 계약: `ByStatus` 에 없는 상태의 ProblemDetails 는 대체 코드(4xx `BadRequest`, 5xx `InternalServerError`)를 붙인다. 이때 `ProblemDetails.Status`·`Title`·응답 상태 코드를 그 코드의 값으로 바꾼다(`CustomizeProblemDetails`, 응답 시작 전). 상태와 코드가 어긋난 응답은 나가지 않는다.

## A2. 예외 (`Common/Web/GlobalExceptionHandler.cs`)

- `BadHttpRequestException`: `FromStatus(exception.StatusCode)` 의 코드로 응답한다. 4xx `Detail` 은 상태별 고정 문장이다. 예외 메시지에는 매개변수·타입 이름이 들어가므로 쓰지 않는다. 지금은 500 이다.
- 고정 문장은 `Common/Web` 의 정적 클래스 하나에 둔다(이름은 ③). 어조는 asp 업무 문구와 같다.
  - 400: 「요청을 처리할 수 없어요. 보낸 값을 확인해 주세요.」
  - 405: 「이 주소에서 지원하지 않는 요청 방식이에요.」
  - 406: 「요청한 응답 형식을 제공할 수 없어요.」
  - 413: 「요청 본문이 너무 커요.」
  - 415: 「지원하지 않는 요청 본문 형식이에요.」
  - 그 밖의 4xx 는 400 문장을 쓴다.

## A3. MVC 검증 문구 (`AddSkeletonWeb`)

`errors` 의 값은 사용자 문장이고, 필드 키는 그대로 둔다(SPA 가 필드에 붙인다).

- **JSON 입력 오류.** `JsonOptions.AllowInputFormatterExceptionMessages = false` 로 둔다. 그러면 모델 오류에 예외만 남고 메시지는 비어 있다. 이어서 `ApiBehaviorOptions.InvalidModelStateResponseFactory` 를 둔다. 이 팩터리는 기본 `ProblemDetailsFactory` 로 `ValidationProblemDetails` 를 만들되, 예외에서 온(메시지가 빈) 오류를 고정 문장 「값의 형식이 올바르지 않아요.」로 바꾼다. 필수 JSON 속성 누락(`[JsonRequired]`)도 이 경로로 간다.
- **모델 바인딩 문구.** `MvcOptions.ModelBindingMessageProvider` 의 접근자 전부를 한국어 문장으로 정한다. 요청 값(`{0}` 시도값)은 싣지 않는다. 대상은 `MissingBindRequiredValue`·`MissingKeyOrValue`·`MissingRequestBodyRequiredValue`·`ValueMustNotBeNull`·`AttemptedValueIsInvalid`·`NonPropertyAttemptedValueIsInvalid`·`UnknownValueIsInvalid`·`NonPropertyUnknownValueIsInvalid`·`ValueIsInvalid`·`ValueMustBeANumber`·`NonPropertyValueMustBeANumber` 다.
- **DataAnnotations 기본 문구.** 메시지를 지정하지 않은 검증 특성에 한국어 기본 문구를 준다. 방법은 `MvcOptions.ModelMetadataDetailsProviders` 에 검증 메타데이터 제공자를 두어 `ErrorMessage` 가 비었을 때만 채우는 것이다. 문구는 필드 키 아래 보이므로 필드 이름을 넣지 않는다.
  - `Required` 「값을 넣어 주세요.」
  - `StringLength`·`MaxLength` 「{최대}자 이하로 넣어 주세요.」(최소가 있으면 「{최소}~{최대}자로 넣어 주세요.」)
  - `MinLength` 「{최소}자 이상 넣어 주세요.」
  - `Range` 「{최소} 이상 {최대} 이하로 넣어 주세요.」
  - `EmailAddress`·`Url`·`RegularExpression` 「형식이 올바르지 않아요.」
  - 그 밖의 특성은 「값이 올바르지 않아요.」
- **본문 매개변수 자체의 required 오류.** 「The r field is required.」처럼 매개변수 이름이 키·문구로 나가는 중복 오류는 내지 않는다. 방법(암묵 required 억제 또는 팩터리에서 제거)은 ③ 에서 모델 전수 스윕 뒤 정한다.
- **열거형 바인더.** `StringEnumModelBinderProvider` 의 모델 오류 문구를 「지원하지 않는 값이에요.」로 바꾼다(요청 값·C# 타입 이름 제거).

최소 API(인증 엔드포인트)는 개발 환경이 아니면 본문 형식 오류에 본문 없는 400 을 내고, `UseStatusCodePages` 가 `BadRequest` 로 채운다(내부 정보 없음). 개발 환경에서는 `BadHttpRequestException` 이 되므로 A2 가 처리한다.

## A4. 없는 API 경로 (Server)

- Server `Program.cs` 의 SPA 폴백 패턴에서 `api` 경로를 뺀다: `app.MapFallbackToFile("{*path:nonfile:regex(^(?!api(/|$)))}", "/index.html")`. 없는 `/api/...` GET 은 어떤 엔드포인트에도 맞지 않아 본문 없는 404 가 되고, `UseStatusCodePages` 가 404 `NOT_FOUND_ERROR` 로 채운다.
- 같은 최소 앱으로 세 방식을 실행해 비교했고, 이 방식을 골랐다(근거: 리뷰_이력.md 「없는 API 경로」). 결과는 아래와 같다.
  - GET 전용 경로에 DELETE → 405 `Allow` 유지
  - `GET /api/nothing`·`GET /api` → 404 problem+json
  - `GET /some/page`·`GET /apiary/x` → SPA
  - `GET /missing.js` → 404 (지금과 같음)
- 한계(지금과 같은 동작): .NET 10 `MapFallbackToFile` 은 GET·HEAD 만 받는다. 그래서 없는 `/api/...` 에 POST 같은 다른 메서드를 보내면 404 가 아니라 405(`Allow: GET, HEAD`)다. 경로 제약이 메서드 판정 뒤에 평가되기 때문이다. 상태와 코드는 일치한다(405 G017).
- InternalApi·Batch 는 SPA 폴백이 없어 해당 없음이다.

## A5. 문서

- README 「에러 응답」 표에 다음 행을 추가한다.
  - 프레임워크 상태 405·406·413·415·503 → 그 상태의 코드
  - `BadHttpRequestException`
  - 목록 밖 상태 → 대체 코드와 그 상태
  - 없는 API 경로 404
- 같은 절에 「`errors`·`detail` 은 사용자 문장 — 기술 정보는 로그에만」 규칙을 넣는다.
- `CLAUDE.md` 에 해당 규칙이 있으면 같은 커밋에서 동기화한다.
- SPA 클라이언트는 바꾸지 않는다. `errors` 값을 그대로 보여 주는 지금 동작이 사용자 문장과 맞는다.

## A6. 기존 테스트 영향 (사전 스윕)

- `-e 'field is required' -e 'could not be converted' -e '코드가 아니다' -e G001 -e BAD_REQUEST_ERROR -e 405 -e 415` (asp `test`, `--type cs`): `ErrorResponseTests.cs:13` 1건이다. 업무 예외의 G001 이고 바뀌지 않는다.
- 영어 기본 문구를 단언하는 테스트는 없다. `EnumCodeBindingTests` 는 400·`NOT_VALID_ERROR` 만 단언한다(③ 에서 문구 단언을 추가).
