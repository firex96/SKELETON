# 스택 공통 오류 코드표

API 스켈레톤(public-api · internal-api · asp-net-core)이 함께 쓰는 오류 코드의 **정본**이다. 게이트웨이·클라이언트가 스택과 무관하게 같은 코드·상태·제목을 보게 하려는 표다.

- 대조: `bash scripts/error-code-parity.sh` — 아래 「공통 코드」 표와 public·internal `enums/ErrorCode.kt`, asp `Common/Errors/ErrorCode.cs` 를 대조한다. 어긋나면 exit 1.
- batch 는 대상이 아니다 — 응답 모델과 코드 체계(`AUTH_001`·`JOB_001`·`COMMON_001`)가 다른 관리자·웹훅 API 다.
- 새 코드를 두 스택 이상에 두게 되면 먼저 이 표에 올린다. 한 스택에만 두는 코드는 「스택 전용 코드」 표에 번호를 예약한다 — 다른 스택이 같은 구분 코드를 다른 뜻으로 쓰지 않게 하기 위해서다.
- 제목(`message`)은 응답에 그대로 나가는 사람이 읽는 문구다(Kotlin `resultMessage`, asp ProblemDetails `title`).

## 공통 코드

| 이름 | HTTP | 구분 코드 | 제목 |
|---|---|---|---|
| BAD_REQUEST_ERROR | 400 | G001 | Bad Request |
| FORBIDDEN_ERROR | 403 | G008 | Forbidden |
| NOT_FOUND_ERROR | 404 | G009 | Not Found |
| NOT_VALID_ERROR | 400 | G011 | One or more validation errors occurred |
| CONFLICT_ERROR | 409 | G013 | Conflict |
| EXTERNAL_API_ERROR | 502 | G014 | Bad Gateway |
| UNAUTHORIZED_ERROR | 401 | G015 | Unauthorized |
| SERVICE_UNAVAILABLE_ERROR | 503 | G016 | Service Unavailable |
| METHOD_NOT_ALLOWED_ERROR | 405 | G017 | Method Not Allowed |
| NOT_ACCEPTABLE_ERROR | 406 | G018 | Not Acceptable |
| PAYLOAD_TOO_LARGE_ERROR | 413 | G019 | Payload Too Large |
| UNSUPPORTED_MEDIA_TYPE_ERROR | 415 | G020 | Unsupported Media Type |
| ACCOUNT_LOCKED_ERROR | 423 | AUTH001 | Account Locked |
| INTERNAL_SERVER_ERROR | 500 | G999 | Internal Server Error |

internal-api 는 인증이 없어 `CONFLICT_ERROR`·`UNAUTHORIZED_ERROR`·`ACCOUNT_LOCKED_ERROR` 를 두지 않는다. 대조는 가진 코드만 한다.

## 스택 전용 코드 (번호 예약)

| 스택 | 구분 코드 |
|---|---|
| Kotlin (public·internal) | G002 · G003 · G004 · G005 · G006 · G007 · G010 · G012 |
| Kotlin public | MFA001 ~ MFA006 |
| asp-net-core | AUTH002 ~ AUTH006 |

정본 값의 이력: Kotlin public 의 `UNAUTHORIZED_ERROR`(G007A → G015)·`CONFLICT_ERROR`(G008A → G013)를 asp 값에 맞추고 제목을 asp 제목으로 통일했다(오류 응답 정리 2차 작업, 2026-10-26). 프레임워크가 정하는 상태(405·406·413·415·503)의 코드 G016~G020 을 공통 코드로 두었다 — Kotlin 은 처리하지 않는 Spring 예외를, asp 는 상태 코드 응답을 이 코드로 응답한다(오류 응답 정리 3차 작업, 2026-10-26).
