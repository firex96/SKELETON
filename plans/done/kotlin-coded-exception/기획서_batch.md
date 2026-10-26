# 기획서 — batch (`../spring-batch-skeleton`)

- 상위 계획: [`설계_계획.md`](설계_계획.md) · 근거: [`리뷰_이력.md`](리뷰_이력.md)
- 파생 영향도 분류: 규약 변경 (설계 계획 §3)

batch 의 `ErrorCode`(`status: HttpStatus`, `code`)와 `ErrorResponseModel`(`code`·`message`·`details`·`timestamp`)은 API 스켈레톤과 모양이 다르다. 이 모양은 바꾸지 않는다. 규약(부모 하나·핸들러 하나·상태는 `ErrorCode` 하나)만 맞춘다.

## 1. 요구사항

| 키 | 요구사항 | 검증 |
|---|---|---|
| B1 | 업무 예외는 모두 `CodedException` 을 상속한다. HTTP 상태와 `code` 는 `errorCode` 하나가 정한다 | `GlobalExceptionHandlerTest` |
| B2 | `BatchProcessException` 에 문자열 code 통로가 없다 | 컴파일 + 잔존 `rg` |
| B3 | 핸들러가 없어 500 `COMMON_999` 로 나가던 `ItemNotFoundException` 은 404 `COMMON_002`, `BatchProcessException` 은 500 `BATCH_001` 로 응답한다 | `GlobalExceptionHandlerTest` |
| B4 | `InvalidApiKeyException`·`JobNotFoundException`·`JobExecutionNotFoundException` 의 응답(상태·`code`·`message`·`details`)은 지금과 같다 | `GlobalExceptionHandlerTest` |
| B5 | `ForbiddenException`·`InvalidJobParameterException` 은 응답 `message` 에 예외 메시지를 싣지 않는다(지금과 같다) | `GlobalExceptionHandlerTest` |
| B6 | 모든 `ErrorCode` 항목의 status 는 4xx·5xx 이고 `code` 는 서로 다르다 | `ErrorCodeContractTest` |
| B7 | README·CLAUDE.md 가 새 규칙과 예외 목록을 적는다 | 문서 대조 + 잔존 `rg` |

## 2. 예외 계층

```
RuntimeException
└── CodedException(errorCode, message = errorCode.message, details = null, cause = null)
    ├── InvalidApiKeyException(message, cause)                 INVALID_API_KEY 401 AUTH_001
    ├── ForbiddenException(message)                            FORBIDDEN 403 AUTH_002        ← 전용 핸들러
    ├── InvalidJobParameterException(jobName, rejectedKeys)    INVALID_REQUEST 400 COMMON_001 ← 전용 핸들러, details = 거부 키 이름
    ├── JobNotFoundException(jobName)                          JOB_NOT_FOUND 404 JOB_001, details = "jobName: …"
    ├── JobExecutionNotFoundException(jobExecutionId)          JOB_EXECUTION_NOT_FOUND 404 JOB_002, details = "jobExecutionId: …"
    ├── ItemNotFoundException(message, cause) · (entityName, id)   ITEM_NOT_FOUND 404 COMMON_002   (신규 코드)
    └── BatchProcessException(message, cause)                  BATCH_PROCESS_ERROR 500 BATCH_001 (신규 코드)
```

- `details` 에는 요청에서 온 값(위조 가능)을 싣지 않는다. 경로 변수인 `jobName`·`jobExecutionId` 와 거부된 키 이름만 싣는다(지금과 같다).
- `BatchProcessException` 은 Step 안에서 던지는 예외다. Spring Batch 의 실패 처리는 타입에 의존하지 않으므로 Job 동작은 바뀌지 않는다. 관리자·웹훅 API 경로로 올라오면 500 `BATCH_001` 로 응답한다.

## 3. 핸들러 규칙

- `CodedException` 은 핸들러 하나가 받는다. 응답 `ErrorResponseModel(code = errorCode.code, message = ex.message ?: errorCode.message, details = ex.details)`, 상태 `errorCode.status`.
- `ForbiddenException`·`InvalidJobParameterException` 은 전용 핸들러가 받는다. 응답 `message` 는 `errorCode.message` 다. Forbidden 은 `details` 를 싣지 않고, InvalidJobParameter 는 거부 키 이름을 싣는다. Spring 이 더 구체적인 타입의 핸들러를 고른다.
- Spring Batch 예외(`JobInstanceAlreadyCompleteException`·`JobRestartException`)와 캐치올 핸들러는 그대로다.
- 로그: 4xx `warn`, 5xx `error`(스택 포함). 전용 핸들러의 구조화 로그는 그대로다.

## 4. 문서 요구사항

| 파일 | 내용 |
|---|---|
| `README.md` 「코딩 규약」 | 3레포 공통 예외 규칙 문장 |
| `CLAUDE.md` 「5. Exception Handling Pattern」 | `CodedException` 규칙, 예외 목록(§2), 전용 핸들러 두 개의 사유 |
