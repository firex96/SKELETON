# 기획서 — batch (`../spring-batch-skeleton`)

- 상위 계획: [`설계_계획.md`](설계_계획.md) · 근거: [`리뷰_이력.md`](리뷰_이력.md)
- 파생 영향도 분류: 규약 변경 + 결함 수정 (설계 계획 §4)

batch 의 응답 모델은 `code`·`message`·`details`·`timestamp` 이고, 코드 체계(`AUTH_001`·`JOB_001`·`COMMON_001`)가 API 스켈레톤과 다르다. 공통 코드표의 대조 대상이 아니다. 응답 문구는 원래 영문이고 이번에도 영문을 유지한다.

## 1. 요구사항

| 키 | 요구사항 | 검증 |
|---|---|---|
| B1 | 없는 실행 ID 조회는 웹훅 `GET /api/v1/jobs/executions/{id}` 와 관리자 `GET /admin/api/executions/{id}` 둘 다 404 `JOB_002` 오류 모델(`details` `jobExecutionId: {id}`)로 응답한다 | 통합 테스트 (두 경로) |
| B2 | `JobExplorer.getJobExecution` 이 없는 id 에 던지는 `EmptyResultDataAccessException` 은 「없음」으로 다룬다. 그 밖의 데이터 접근 예외는 그대로 전파한다 | 통합 테스트 · 확장 함수 unit 테스트 |
| B3 | 응답 `message`·`details` 에는 사용자에게 보여도 되는 문장만 싣는다. 5xx 업무 예외와 캐치올은 `message` 에 `errorCode.message`, Spring Batch 예외(`JobInstanceAlreadyCompleteException`·`JobRestartException`)는 지금의 고정 문구(`Job instance already complete`·`Job cannot be restarted`)를 싣는다. 모두 `details` 를 비운다(예외 메시지에는 Job 파라미터 값이 들어간다) | `GlobalExceptionHandlerTest` |
| B4 | 업무 예외 4xx 의 `message` 는 예외 메시지, `details` 는 예외가 실은 값(경로 변수·거부 키 이름)이다 — 지금과 같다 | `GlobalExceptionHandlerTest` |
| B5 | `ForbiddenException` 은 메시지 인자를 받지 않는다. 응답 `message` 는 `FORBIDDEN.message` 이고 `CodedException` 핸들러가 처리한다(전용 핸들러 삭제) | `GlobalExceptionHandlerTest` · 기존 웹훅 인가 통합 테스트 |
| B6a | `JobAdminBizService.getJobExecution`·`AdminMappingService.getJobExecution` 은 non-null 을 돌려주고 없으면 `JobExecutionNotFoundException` 을 던진다. `AdminApiController` 의 null 분기를 없앤다 | 통합 테스트 |
| B6 | `InvalidJobParameterException` 은 전용 핸들러를 유지한다(응답 `message` 에 Job 이름이 든 예외 메시지 대신 코드 문구) | `GlobalExceptionHandlerTest` |
| B7 | 모든 오류 로그는 4xx `warn`·5xx `error`(스택)다 | 코드 검토 |
| B8 | 테스트 소스셋도 파일당 최상위 클래스 하나다 | `OneClassPerFileConventionTest` |
| B9 | README·CLAUDE.md 가 바뀐 규칙을 적는다 | 문서 대조 |

## 2. 응답 변화

| 상황 | 지금 (HTTP · code · message · details) | 바뀐 뒤 |
|---|---|---|
| 웹훅 없는 실행 조회 | 500 · `COMMON_999` · `Internal server error` · 예외 메시지 | 404 · `JOB_002` · `Job execution not found: {id}` · `jobExecutionId: {id}` |
| 관리자 없는 실행 조회 | 500 추정 — 같은 `JobExplorer.getJobExecution` 예외(구현 첫 단계에서 재현). 코드상 null 분기는 404 · 빈 본문 | 404 · `JOB_002` 오류 모델(위와 같음) |
| `BatchProcessException` | 500 · `BATCH_001` · 예외 메시지 | 500 · `BATCH_001` · `Batch process failed` |
| `JobInstanceAlreadyCompleteException` | 409 · `JOB_003` · `Job instance already complete` · 예외 메시지 | `details` 없음 |
| `JobRestartException` | 409 · `JOB_003` · `Job cannot be restarted` · 예외 메시지 | `details` 없음 |
| 캐치올 | 500 · `COMMON_999` · `Internal server error` · 예외 메시지 | `details` 없음 |
| `ForbiddenException` | 403 · `AUTH_002` · 코드 문구 | 같음(핸들러만 바뀜) |

관리자 화면(`templates/admin/execution-detail.html`)은 `AdminApi.get` 이 실패 응답을 예외로 받아 `NOT_FOUND` 배지를 그린다. 404 본문이 빈 값에서 오류 모델로 바뀌어도 화면 동작은 같다.
