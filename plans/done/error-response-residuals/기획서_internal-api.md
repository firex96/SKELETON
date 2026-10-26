# 기획서 — spring-boot-internal-api-skeleton

상위 계획: [`설계_계획.md`](설계_계획.md).

## I1. 상태 기반 일괄 처리

- public P1 과 같다. 새 코드 G017~G020 을 둔다. internal 은 인증이 없어 401·409·423 코드가 없다.
- `fromStatus` 목록: 400 `BAD_REQUEST_ERROR` · 403 `FORBIDDEN_ERROR` · 404 `NOT_FOUND_ERROR` · 405·406·413·415 새 코드 · 500 `INTERNAL_SERVER_ERROR` · 502 `EXTERNAL_API_ERROR` · 503 `SERVICE_UNAVAILABLE_ERROR`. 그 밖의 4xx → `BAD_REQUEST_ERROR`, 5xx → `INTERNAL_SERVER_ERROR`.
- 캐치올·헤더 처리·문장은 public 과 같은 코드다. `handler/ErrorReason.kt` 는 public 과 package 외 동일(장치 A `full`).

## I2. 5xx 문장

- public P3 과 같다(같은 파일).
- `ErrorReason.UNAUTHORIZED`·`FORBIDDEN` 이 없어지는 것은 internal 에 영향이 없다(사전 스윕 hit 0).

## I3. 문서

- README·`CLAUDE.md` 예외 절에 public 과 같은 문장을 넣는다.
- `CLAUDE.md:187` 공통 예외 목록은 그대로 둔다(바뀌는 예외 없음).
