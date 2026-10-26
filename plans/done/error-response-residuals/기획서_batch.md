# 기획서 — spring-batch-skeleton

상위 계획: [`설계_계획.md`](설계_계획.md).

## B1. 상태 기반 일괄 처리

### 새 코드 (`enums/ErrorCode.kt`, 「일반」 묶음)

| 이름 | HTTP | 코드 | message |
|---|---|---|---|
| `PATH_NOT_FOUND` | 404 | COMMON_003 | Requested path not found |
| `METHOD_NOT_ALLOWED` | 405 | COMMON_004 | Method not allowed |
| `NOT_ACCEPTABLE` | 406 | COMMON_005 | Requested response format not available |
| `PAYLOAD_TOO_LARGE` | 413 | COMMON_006 | Request body too large |
| `UNSUPPORTED_MEDIA_TYPE` | 415 | COMMON_007 | Unsupported request content type |
| `SERVICE_UNAVAILABLE` | 503 | COMMON_008 | Service temporarily unavailable |

### 상태 → 코드 (`ErrorCode.fromStatus`)

- 400 `INVALID_REQUEST` · 404 `PATH_NOT_FOUND` · 405·406·413·415·503 위 새 코드 · 500 `INTERNAL_ERROR`. 그 밖의 4xx → `INVALID_REQUEST`(400), 5xx → `INTERNAL_ERROR`(500).
- 업무 코드(`JOB_NOT_FOUND`·`INVALID_API_KEY` 등)는 고르지 않는다.

### 처리 (`handler/GlobalExceptionHandler.kt`)

- 캐치올: `ex is ErrorResponse` → `fromStatus` 코드, `message` = 그 코드의 `message`, `details` 없음. 상태가 같으면 `ErrorResponse.headers` 를 싣는다(public P1 과 같은 규칙).
- `NoResourceFoundException`(없는 경로)도 `ErrorResponse`(404)라 위 규칙으로 404 `PATH_NOT_FOUND` 가 된다.
- 새 전용 핸들러 둘:
  - `MethodArgumentTypeMismatchException`(경로 변수·쿼리 값이 타입에 맞지 않음): 400 `INVALID_REQUEST`, `message` = 코드 문구, `details` = 파라미터 **이름만**(`InvalidJobParameterException` 과 같은 규칙 — 값은 싣지 않는다). 상위 타입 `TypeMismatchException` 으로 잡지 않는다 — 그 하위 `ConversionNotSupportedException`(변환기 부재, 서버 결함)은 캐치올 500 으로 남는다. public·internal 도 같은 타입을 잡는다.
  - `HttpMessageNotReadableException`(본문 형식 오류): 400 `INVALID_REQUEST`, `details` 없음.
- 지금: 위 경우가 모두 캐치올 500 `COMMON_999` 다.

## B2. `JobExplorer.getJobExecution` 직접 호출 금지 규약 테스트

- 새 파일 `src/test/unit/kotlin/com/rex/batch/skeleton/convention/JobExecutionLookupConventionTest.kt`.
- 규칙: `src/main/kotlin` 에서 `JobExplorer` 의 `getJobExecution(` 호출은 `util/JobExplorerExtensions.kt` 에서만 허용한다. 없는 id 에 예외를 던지는 Spring Batch 동작을 한 곳(`requireJobExecution`)에서만 다루기 위해서다.
- 판정 방식은 소스 검사다(기존 `OneClassPerFileConventionTest` 와 같은 방식, 바이트코드 도구 의존성 없음). `JobExplorer` 타입 프로퍼티·파라미터 이름을 그 파일에서 모은 뒤 `<이름>.getJobExecution(` 호출을 찾는다. 그러면 BizService 자신의 `getJobExecution` 메서드 호출(`jobAdminBizService.getJobExecution(…)`)과 구분된다. 정확한 정규식은 ③ 에서 정한다.
- 자기 검증(규약 테스트 관례): 위반 예제 문자열에서 판정이 hit 하고, BizService 호출 예제에서는 hit 하지 않는 단언을 함께 둔다. 실제 소스에서 검사한 파일 수 하한(`MIN_MAIN`)을 둬 「아무것도 안 훑고 통과」를 막는다.
- 장치 B: `docs/contract-surfaces.md` 「batch 실행 조회 경로」 행에 이 테스트를 대응시킨다.

## B3. 문서

- README·`CLAUDE.md` 예외 절에 공통 문장(「처리하지 않는 프레임워크 예외도 그 HTTP 상태와 그 상태의 코드로 응답한다」)을 넣는다. `CLAUDE.md:215` 예외 목록 옆에 새 일반 코드를 적는다.
- `CLAUDE.md:212` 의 「전용 핸들러는 하나뿐」 서술을 바꾼다. 전용 핸들러의 범주를 적는다. 응답에 예외 메시지를 내면 안 되는 업무 예외(`InvalidJobParameterException`), Spring Batch 예외(`JobInstanceAlreadyCompleteException`·`JobRestartException`, 기존 유지), 상태만으로는 400 이 되지 않는 요청 오류(타입 불일치·본문 형식 오류)다. 그 밖의 프레임워크 예외는 상태 기반으로 처리한다. README 의 같은 서술도 함께 바꾼다.
- `CLAUDE.md` 규약 테스트 목록에 `JobExecutionLookupConventionTest` 를 추가한다.
