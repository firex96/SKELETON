# 기획서 — internal-api (`../spring-boot-internal-api-skeleton`)

- 상위 계획: [`설계_계획.md`](설계_계획.md) · 근거: [`리뷰_이력.md`](리뷰_이력.md)
- 파생 영향도 분류: 규약 변경 (설계 계획 §3)

internal-api 의 `exception/` 공통 파일은 public-api 와 package·import 경로만 다르고 같다. 이 작업 뒤에도 같다(장치 A `full` 표면으로 감시).

## 1. 요구사항

[`기획서_public-api.md`](기획서_public-api.md) §1 의 P1~P6·P8 을 그대로 적용한다. P7(인증 예외)은 해당 없음 — internal-api 에는 인증 예외가 없다.

## 2. 예외 계층

```
RuntimeException
└── CodedException(errorCode, message = errorCode.message, cause = null)
    ├── ClientBadRequestException(message, cause)        BAD_REQUEST_ERROR 400 G001
    │   └── InvalidRequestParameterException(message)    BAD_REQUEST_ERROR 400 G001
    ├── ItemNotFoundException(message, cause)            NOT_FOUND_ERROR 404 G009
    └── ApiCallException(message, errorCode = EXTERNAL_API_ERROR, cause)   502 G014 / 503 G016
```

## 3. 응답 변화

public-api §3 표에서 `WebClientRequestException` 행을 뺀 것과 같다 — internal-api 에는 그 핸들러가 없다. `ErrorCode` 변경도 public-api §3 과 같다.

internal-api `ErrorCode` 에는 public-api 의 `UNAUTHORIZED_ERROR`·`CONFLICT_ERROR`·`ACCOUNT_LOCKED_ERROR`·`MFA_*` 가 없다. 이 차이는 이번 작업에서 바꾸지 않는다.

## 4. 핸들러 규칙

public-api §4 와 같다. `AccessDeniedException`·`WebClientRequestException` 핸들러는 internal-api 에 없다.

## 5. 문서 요구사항

| 파일 | 내용 |
|---|---|
| `README.md` 「코딩 규약」 | 3레포 공통 예외 규칙 문장 |
| `CLAUDE.md` 「5. Exception Handling Pattern」 | 규칙·예외 목록·검출 테스트 (기존 영문 서술 유지) |
