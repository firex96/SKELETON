# 규약 표면 정본

이 문서는 **스크립트가 읽는 정본**이다. 사람이 읽는 설명은 최소로 하고, 표를 기계 판독 가능한 형태로 유지한다.

- **장치 A**(`scripts/sibling-diff.sh`) — 「표면」 표를 읽어 형제 3레포의 **발산**을 검출한다.
- **장치 B**(`scripts/contract-coverage.sh`) — 「대응」 표를 읽어 **규약 표면에 그것을 지나가는 테스트가 있는지**를 강제한다.

두 장치는 목적이 다르다. **A 는 형제가 서로 달라진 것**을, **B 는 셋 다 똑같이 틀린 것**을 잡는다. 후자는 대조로는 절대 잡히지 않는다.

## 레포 식별자

| 식별자 | 경로 | base package |
|---|---|---|
| `public` | `../spring-boot-public-api-skeleton` | `com.rex.api.pub.skeleton` |
| `internal` | `../spring-boot-internal-api-skeleton` | `com.rex.api.internal.skeleton` |
| `batch` | `../spring-batch-skeleton` | `com.rex.batch.skeleton` |

## 표면

`repos` 가 `3` 이면 셋 다. `mode` 는 `full`(파일 전체) · `section`(문서의 한 절) · `symbols`(지정 상수만) · `deps`(지정 의존성 버전만) · **`props`(지정 `override` 선언만)**.
`path` 는 `full` 이면 base package 이하 상대 경로(`<BASE>` 를 쓰면 `props` 처럼 레포 루트 기준 — 테스트 소스셋 파일), `section` 이면 `파일#절제목`, `symbols` 면 `파일@상수1,상수2`, `deps` 면 **레포 루트 기준** `파일@group:artifact,group:artifact`, `props` 면 **레포 루트 기준** `파일@선언1,선언2` 이며 경로에 **`<BASE>`** 토큰(레포 base package 경로)을 쓸 수 있다.

**`symbols`·`deps`·`props` 에는 `expected_diff` 를 둘 수 없다** — 부분집합 자체가 계약이라 예외 자리가 없다(스크립트가 표를 거부한다).

**`deps` 는 좌표가 3레포 어디에도 없으면 `MISSING`(실패)이다** — 「셋 다 없으니 같다」로 통과시키면 좌표를 교체한 뒤 **아무것도 감시하지 않으면서 SAME** 이 된다.
`expected_diff` 가 비어 있지 않으면 그 차이는 **정당한 것**으로 보고 종료 코드에 반영하지 않는다. **사유 없는 예외는 두지 않는다.**

| surface | path | repos | mode | expected_diff |
|---|---|---|---|---|
| AbstractStringEnumConverter | converter/AbstractStringEnumConverter.kt | 3 | full | |
| StringEnum | enums/StringEnum.kt | 3 | full | |
| StringEnumUtil | enums/StringEnumUtil.kt | 3 | full | |
| Constant | constant/Constant.kt@KEY_TRACE_ID,KEY_USER_ID,HEADER_TRACE_ID | 3 | symbols | |
| Constant(API) | constant/Constant.kt@HEADER_USER_ID | public internal | symbols | |
| BaseAuditedEntity | persistence/jpa/entity/backbone/BaseAuditedEntity.kt | 3 | full | |
| SimpleAuditorAware | persistence/jpa/entity/backbone/SimpleAuditorAware.kt | 3 | full | |
| AuditConfiguration | config/persistence/AuditConfiguration.kt | 3 | full | |
| TraceIdFilter | filter/TraceIdFilter.kt | 3 | full | |
| AuditProperties | config/audit/AuditProperties.kt | 3 | full | |
| AuditorContext | context/AuditorContext.kt | 3 | full | |
| AuditorContextTaskDecorator | config/AuditorContextTaskDecorator.kt | 3 | full | |
| HeaderAuditorContextFilter | filter/HeaderAuditorContextFilter.kt | internal batch | full | |
| WebClientUtil | util/WebClientUtil.kt | 3 | full | |
| README 코딩 규약 | README.md#코딩 규약 | 3 | section | |
| CLAUDE.md 공통 명명 규칙(참조) | CLAUDE.md#공통 명명 규칙 | 3 | section | |
| CLAUDE.md 미결 항목 처리 | CLAUDE.md#미결 항목 처리 | 3 | section | |
| CLAUDE.md 코드 정리·재검증 범위 | CLAUDE.md#코드 정리·재검증 범위 | 3 | section | |
| conventions 설정값·비밀값 규약 | .claude/rules/conventions.md#설정값·비밀값 규약 | 3 | section | |
| conventions 데이터베이스 | .claude/rules/conventions.md#데이터베이스 | 3 | section | |
| conventions 타입 선언 | .claude/rules/conventions.md#타입 선언 | 3 | section | |
| UnresolvedPlaceholderGuard | config/UnresolvedPlaceholderGuard.kt | 3 | full | |
| MapstructConfiguration | config/MapstructConfiguration.kt | 3 | full | |
| ProductJdbcEntity | persistence/jdbc/entity/main/ProductJdbcEntity.kt | public internal | full | |
| CodedException | exception/CodedException.kt | public internal | full | |
| ClientBadRequestException | exception/ClientBadRequestException.kt | public internal | full | |
| ItemNotFoundException | exception/ItemNotFoundException.kt | public internal | full | |
| InvalidRequestParameterException | exception/InvalidRequestParameterException.kt | public internal | full | |
| ApiCallException | exception/ApiCallException.kt | public internal | full | |
| ErrorReason | handler/ErrorReason.kt | public internal | full | |
| AbstractBlankStringEnumConverter | converter/AbstractBlankStringEnumConverter.kt | 3 | full | |
| AbstractDefaultStringEnumConverter | converter/AbstractDefaultStringEnumConverter.kt | 3 | full | |
| KotestProjectConfig(unit) | src/test/unit/kotlin/<BASE>/config/KotestUnitProjectConfig.kt@extensions | 3 | props | |
| ServiceNamingConventionTest | src/test/unit/kotlin/<BASE>/convention/ServiceNamingConventionTest.kt | 3 | full | |
| LayeringConventionTest | src/test/unit/kotlin/<BASE>/convention/LayeringConventionTest.kt | 3 | full | |
| OneClassPerFileConventionTest | src/test/unit/kotlin/<BASE>/convention/OneClassPerFileConventionTest.kt | 3 | full | |
| KotestProjectConfig(integration) | src/test/integration/kotlin/<BASE>/config/KotestIntegrationProjectConfig.kt@extensions | 3 | props | |
| KotestProjectConfig(e2e) | src/test/e2e/kotlin/<BASE>/config/KotestE2eProjectConfig.kt@extensions | public internal | props | |
| 공통 테스트 의존성 버전 | build.gradle.kts@com.ninja-squad:springmockk,io.mockk:mockk,io.kotest:kotest-runner-junit5,io.kotest:kotest-extensions-spring,io.github.classgraph:classgraph | 3 | deps | |

`ProductJdbcEntity` 는 public·internal 만 대조한다 — batch 는 같은 엔티티를 `persistence/jdbc/entity/sub/` 에 두고 KDoc 의 스키마 이름 한 줄이 달라, `full` 모드의 단일 경로로는 비교할 수 없다. batch 쪽은 이 장치가 감시하지 않는다.

### `symbols` 모드가 필요한 이유

`Constant` 는 레포별로 정당하게 다른 상수를 갖는다(batch 의 `KEY_JOB_NAME`·`KEY_STEP_NAME` 등). 파일 전체 md5 는 항상 다르고, 그렇다고 전체를 `expected_diff` 로 넘기면 **공통 상수의 값이 달라져도 통과한다.**

그래서 **이름을 명시한 부분집합만** 대조한다. 목록에 있는 이름이 없거나 값이 다르면 `DIVERGED`, 목록 밖 상수는 무시한다. **`symbols` 모드에는 `expected_diff` 를 둘 수 없다** — 부분집합 자체가 계약이라 예외 사유를 둘 자리가 없다(스크립트가 표를 거부한다).

## 대응

장치 B 가 읽는다. `assert_pattern` 은 **` / ` 로 구분된 리터럴 목록**이며 스크립트가 `grep -qF` 로 각각을 찾는다.

**두 가지를 지킨다.**

> **공허한 신호의 예 ①** — 「Job 트리거 인가(경로)」를 `admin/api / 403`, 「(플래그 off)」를 `webhook.enabled=false / 403` 으로 적으면 **둘 다 공허하다** — `/` 로 쪼개져 `admin`·`api`·`403` 같은 흔한 토큰이 되고, 해당 단언이 통째로 사라져도 다른 텍스트로 통과한다. 그래서 오류 코드·상태 단언 리터럴을 쓴다.
>
> **공허한 신호의 예 ②** — 「사용자 식별 사슬」·「감사 헤더 기본 불신」은 `AuditProbeConfiguration` 을 신호로 둔다. 두 스펙은 **실제 요청을 지나야** 필터 등록·순서까지 검증한다. 이 신호가 없으면 **필터를 직접 호출하는 형태로 되돌아가도** 행이 통과한다.

- **정규식·`rg` 인자 형식을 쓰지 않는다.** `-e PATTERN` 이나 alternation `\|` 을 적으면 그 문자열 자체를 리터럴로 찾아 **항상 실패**한다.
- **신호에 `/` 를 넣지 않는다.** 구분자라서 쪼개진다 — `admin/api` 는 `admin` 과 `api` 두 토큰이 되고, 흔한 토큰은 다른 단언에도 있어 **신호가 공허해진다.** 그 표면에서만 나오는 식별자를 고른다.

`enforced` 가 `no` 면 단언 부재가 WARN 에 그친다. **`no` 는 사유·담당·시점 셋이 모두 있을 때만 쓴다** — 하나라도 없으면 스크립트가 표를 거부한다.

| surface | repos | test_class | source_set | assert_pattern | enforced | note |
|---|---|---|---|---|---|---|
| 인바운드 traceId 스캔 도달성 | 3 | TraceIdFilterScanReachabilityTest | unit | TraceIdFilter::class / package | yes | |
| 인바운드 traceId 빈 등록 | 3 | TraceIdFilterRegistrationIntegrationTest | integration | getBean / TraceIdFilter | yes | |
| 인바운드 traceId 값 검증 | 3 | TraceIdSanitizerTest | unit | isValid / sanitize | yes | |
| 인바운드 traceId 필터 동작 | 3 | TraceIdFilterBehaviorTest | unit | MDC / doFilter / HEADER_TRACE_ID | yes | |
| 아웃바운드 traceId 전파 | public internal | TraceIdPropagationFilterTest | unit | HEADER_TRACE_ID | yes | |
| Redis 캐시 직렬화 계약 | public internal | RedisCacheSerializerFactoryTest | unit | PolymorphicTypeValidator | yes | |
| Redis 캐시 빈 배선 | public internal | RedisCacheManagerWiringIntegrationTest | integration | RedisCacheManager / getBean | yes | |
| 오류 응답 계약 | public internal | ErrorResponseContractIntegrationTest | integration | divisionCode / resultMessage | yes | |
| ErrorCode 상태·구분 코드 불변식 | 3 | ErrorCodeContractTest | unit | ErrorCode.entries / shouldBeInRange | yes | |
| 본문 status 와 HTTP 상태 일치 | public internal | ErrorResponseContractIntegrationTest | integration | SERVICE_UNAVAILABLE_ERROR / G016 | yes | |
| batch CodedException 단일 핸들러 | batch | GlobalExceptionHandlerTest | unit | COMMON_002 / BATCH_001 | yes | |
| 응답 문구 사용자 문장 | public internal | ErrorResponseContractIntegrationTest | integration | MALFORMED_BODY / bodyHasNoInternals | yes | |
| 테스트 소스셋 1 Class per 1 File | 3 | OneClassPerFileConventionTest | unit | OC-5 / OC-6 / MIN_TEST | yes | |
| batch 없는 실행 조회 404 | batch | JobExecutionNotFoundIntegrationTest | integration | JOB_002 / jobExecutionId | yes | |
| 프레임워크 상태 응답 | public internal | FrameworkStatusResponseIntegrationTest | integration | METHOD_NOT_ALLOWED_ERROR / UNSUPPORTED_MEDIA_TYPE_ERROR | yes | |
| batch 프레임워크 상태 응답 | batch | GlobalExceptionHandlerTest | unit | COMMON_004 / COMMON_007 | yes | |
| batch 실행 조회 경로 | batch | JobExecutionLookupConventionTest | unit | JE-1 / requireJobExecution | yes | |
| WebClientUtil 동작 계약 | 3 | WebClientUtilTest | unit | NonRetryableException / RetryableException | yes | |
| Job 트리거 인가 | batch | JobTriggerAuthorizerTest | unit | allowedJobs / ForbiddenException / InvalidJobParameterException | yes | |
| Job 트리거 인가(경로) | batch | JobTriggerAuthorizationIntegrationTest | integration | AUTH_001 / AUTH_002 / isUnauthorized | yes | |
| Job 트리거 인가(플래그 off) | batch | WebhookDisabledJobTriggerAuthorizationIntegrationTest | integration | webhook.enabled=false / isForbidden | yes | |
| 관리자 조회 표면 인증 | batch | AdminApiReadAuthorizationIntegrationTest | integration | dashboard / isUnauthorized | yes | |
| 감사 필드 자동 주입 | 3 | AuditingIntegrationTest | integration | createdAt / createdBy | yes | |
| 사용자 식별 사슬(헤더→감사 컨텍스트→감사) | 3 | AuditorChainIntegrationTest | integration | HEADER_USER_ID / createdBy / AuditProbeConfiguration | yes | |
| 감사 헤더 기본 불신 | 3 | AuditorHeaderDistrustIntegrationTest | integration | HEADER_USER_ID / SYSTEM_USER_ID / AuditProbeConfiguration | yes | |
| 감사 주체 채널 분리 | 3 | SimpleAuditorAwareTest | unit | AuditorContext / SYSTEM_USER_ID / KEY_USER_ID | yes | |
| 배치 Job 추적(MDC) | batch | JobTraceListenerTest | unit | MDC / KEY_TRACE_ID | yes | |
| MapStruct 생성자 매핑 | 3 | MapStructConstructorMappingTest | unit | MapperImpl.java / shouldNotBeEmpty / MapperConfig / ignore mappings / nullable-source pairs | yes | |
| 선언 규약 | 3 | DeclarationStyleConventionTest | unit | isData / KMutableProperty1 / isOptional / JsonProperty | yes | |
| is-prefix Boolean 매핑 | public | SecurityMapperTest | unit | isActive / isPermanent / isLocked | yes | |
| is-prefix Boolean 매핑(세션) | public | AuthMapperTest | unit | isCurrentSession | yes | |
| is-prefix Boolean 매핑 | batch | JobScheduleConfigMapperTest | unit | isEnabled | yes | |
| is-prefix Boolean 매핑(HTTP 왕복) | batch | AdminApiScheduleConfigIntegrationTest | integration | isPrefixProbeEnabledJob / isEnabled | yes | |
| is-prefix Boolean 매핑(세션 HTTP 왕복) | public | UserSelfServiceE2ETest | e2e | isCurrentSession | yes | |
| 로그인 보호 집행 | public | AuthBizServiceLoginProtectionTest | unit | recordFailedAttempt / clearAttempts / AccountLockedException | yes | |
| 로그인 보호 집행(HTTP) | public | LoginProtectionE2ETest | e2e | AUTH001 / isLocked / remainingLockTimeSeconds | yes | |
| 관리자 e2e 실권한 경로 | public | AdminSecurityE2ETest | e2e | superAdminToken / HttpStatus.CREATED | yes | |
| 트랜잭션 매니저 명시 규약 | 3 | TransactionManagerConventionTest | unit | transactionManager / isNotProxyable / transactionManagerRef | yes | |
| @Async 자기 호출 금지 | public internal | AsyncSelfInvocationConventionTest | unit | selfCalls / isHidden / shouldNotBeEmpty | yes | |
| @Async 실제 비동기(Spring 컨텍스트) | public internal | ExampleAsyncProxyAsyncExecutionIntegrationTest | integration | CountDownLatch / eventually / COMPLETED | yes | |
| Flyway 위치 바인딩 | public | FlywayPropertiesBindingTest | unit | NoUnboundElementsBindHandler / shouldContainExactly | yes | |
| 세션 로그아웃 소유권 | public | SessionOwnershipE2ETest | e2e | FORBIDDEN / G008 / NO_CONTENT | yes | |
| 메일 발송 포트 | public | UserSelfBizServiceMailTest | unit | mailSender / RAW-1 / shouldThrow | yes | |
| auth 트랜잭션 매니저 바인딩(실제 DB) | public | AuthTransactionBindingIntegrationTest | integration | authTransactionManager / setRollbackOnly / removeUserFromGroup | yes | |
| OAuth2 리다이렉트 검증(HTTP) | public | OAuth2AuthorizationE2ETest | e2e | invalid_request / access_denied / refresh_token | yes | |
| 소셜 state 검증·1회 소비(브라우저 세션 결합, GETDEL) | public | SocialBrowserLoginIntegrationTest | integration | invalid_state / SKELETON_SESSION / callbackWithState | yes | |
| 소셜 콜백 토큰 쿼리 금지·세션 교환 1회 | public | SocialBrowserLoginIntegrationTest | integration | assertNoTokenInLocation / postSessionToken / exactly one | yes | |
| 401·403 단일 형식(필터 체인·메서드 보안 모두 ErrorResponseModel) | public | ErrorResponseFormatE2ETest | e2e | FORBIDDEN_ERROR / UNAUTHORIZED_ERROR / divisionCode | yes | |
| 인가 브라우저 흐름(로그인·동의 화면, 세션 인증) | public | OAuth2AuthorizationE2ETest | e2e | authorizeViaBrowser / submitConsent / access_denied | yes | |
| 토큰 엔드포인트 클라이언트 인증(시크릿 필수·basic·post) | public | OAuth2AuthorizationE2ETest | e2e | tokenRequest / WWW-Authenticate / invalid_client | yes | |
| 일괄 세션 폐기 뒤 토큰 즉시 무효(캐시 제거) | public | SessionOwnershipE2ETest | e2e | loginAgain / otherDevice / UNAUTHORIZED | yes | |
| 폐기 세션 캐시 경쟁 차단(커밋 뒤 표식 먼저·표식 없을 때만 캐시 쓰기) | public | SessionCacheRevocationTest | unit | session:revoked: / afterCommit / verifyOrder | yes | |
| 폐기 표식 조건부 캐시 쓰기(실제 Redis 클러스터·해시 태그) | public | SessionCacheRevocationIntegrationTest | integration | cacheSessionUnlessRevoked / staleReadBeforeRevocation / evictRevokedSessions | yes | |
| 토큰 scope 확대 금지(refresh·client_credentials) | public | OAuth2AuthorizationE2ETest | e2e | widened / openid admin / invalid_scope | yes | |
| email_verified 실제 판정(세 응답 경로) | public | EmailVerifiedE2ETest | e2e | email_verified / profileEmailVerified / requestVerificationTwice | yes | |
| discovery 광고 정합(광고값마다 실제 동작·클레임 일치) | public | DiscoveryConformanceE2ETest | e2e | response_types_supported / token_endpoint_auth_methods_supported / claims_supported | yes | |
| 2차 인증 게이트(켠 계정은 API·인가 서버 로그인 모두 세션 전에 challenge) | public | MfaE2ETest | e2e | browserAtSecondStep / HttpStatus.ACCEPTED / mfaToken / expireChallengesOf | yes | |
| 2차 인증 게이트(소셜 네이티브 202·콜백은 2단계 화면, 통과 전 토큰 교환 401) | public | SocialBrowserLoginIntegrationTest | integration | MFA_PROVIDER_ID / statusCode() shouldBe 202 / mfaCodes.next() | yes | |
| 2단계 코드 재사용 방지·challenge 1회 소비(같은 TOTP·서로 다른 복구 코드 동시) | public | MfaChallengeIntegrationTest | integration | results.count { it.isSuccess } shouldBe 1 / MfaMethod.RECOVERY / MFA_CHALLENGE_INVALID | yes | |
| 2단계 실패의 계정 잠금 공유(1단계 성공은 카운터를 지우지 않음·잠금이 코드보다 먼저) | public | MfaChallengeIntegrationTest | integration | getCurrentAttempts(user.loginId) shouldBe 3 / shouldThrow<AccountLockedException> | yes | |
| TOTP 계산(RFC 6238 부록 B 벡터·±1 구간) | public | TotpTest | unit | 287082 / 353130 / matchStep | yes | |
| TOTP 시크릿 암호화(AES-GCM·사용자 AAD·변조 거부) | public | MfaSecretCipherTest | unit | decrypt(8L, stored) / ByteArray(16) | yes | |
| 관리자 2차 인증 초기화(세션 전부 폐기·없으면 404) | public | MfaE2ETest | e2e | deleteWithAuth / superAdminToken / HttpStatus.NOT_FOUND | yes | |
| id_token auth_time 은 로그인 시각(직접 발급·동의 후 발급) | public | AuthTimeE2ETest | e2e | auth_time / loginFrom / authTime + 2 | yes | |
| 비밀번호 로그인 감사(성공·실패) | public | LoginAuditE2ETest | e2e | LOGIN_FAILURE / LOGIN_SUCCESS / INVALID_CREDENTIALS | yes | |
| 소셜 로그인의 차단 IP·계정 잠금 | public | SocialAuthBizServiceLoginProtectionTest | unit | shouldThrow<AccountLockedException> / shouldThrow<ForbiddenException> / recordFailedAttempt | yes | |
| 비밀번호 변경 뒤 다른 세션 폐기(/user/password/change) | public | UserSelfBizServicePasswordChangeTest | unit | PASSWORD_CHANGED_REASON / userSessionRevocationBizService.revokeAll | yes | |
| 세션 일괄 폐기 규칙(폐기 전에 모은 ID 만 폐기·같은 목록으로 캐시 제거) | public | UserSessionRevocationBizServiceTest | unit | exceptSessionId / evictRevokedSessions(listOf("phone", "laptop"), 7) | yes | |
| 1단계 출구의 관문(2차 인증 켜짐은 challenge 만·꺼짐은 출처별 카운터 정리) | public | MfaChallengeBizServiceGatewayTest | unit | afterFirstFactor / clearAttempts = true / clearAttempts = false | yes | |
| 인증 완료 지점(카운터 정리 여부·소셜 여부로 성공 감사 선택) | public | LoginCompletionBizServiceTest | unit | logSocialLoginSuccess / logLoginSuccess / clearAttempts = false | yes | |
| 읽지 못하는 세션 캐시는 DB 로 다시 읽음(배포 전 형식) | public | SessionCacheRevocationTest | unit | SR-L / redisTemplate.delete("session:{s1}") | yes | |
| Job 재실행 멱등 | batch | SampleJobRerunIntegrationTest | integration | readCount / writeCount / processedAt | yes | |
| 미해석 플레이스홀더 fail-fast | 3 | UnresolvedPlaceholderGuardTest | unit | Config resource / findUnresolved / IllegalStateException | yes | |
| 미해석 플레이스홀더 fail-fast 기동 경로(spring.factories) | 3 | UnresolvedPlaceholderGuardBootIntegrationTest | integration | SpringApplication / guardprobe / no-such-secret-for-guard-probe | yes | |
| 서비스 접미사 규약 | 3 | ServiceNamingConventionTest | unit | BizService / MappingService / EntityService | yes | |
| 계층 규약(컨트롤러·매핑·BizService·EntityService 경계) | 3 | LayeringConventionTest | unit | constructorParameterTypes / classifierNames / HTTP_WRAPPERS | yes | |
| 관리자 API 응답 계약(DTO 프로퍼티명 = JSON 키) | batch | AdminApiContractIntegrationTest | integration | shouldContainExactly / propertyNames / deleteJobInstance | yes | |
| 로그인 IP 신뢰 경계(X-Forwarded-For 는 신뢰 프록시 뒤에서만) | public | ClientIpResolverTest | unit | trustedProxies / X-Forwarded-For / remoteAddr | yes | |
| DDL 콜레이션(utf8mb4_0900_ai_ci — 새 DB 의 테이블·문자열 컬럼 전부) | public batch | MysqlSchemaInitializationIntegrationTest | integration | utf8mb4_0900_ai_ci / table_collation / collation_name | yes | |
| 파일당 최상위 클래스 하나(1 Class per 1 File) | 3 | OneClassPerFileConventionTest | unit | countableDeclarations / OC-1 violation / shouldBeEmpty | yes | |
| 데모 템플릿 ↔ API 계약(응답 필드·경로·요청 본문·이스케이프) | public | DemoTemplateContractTest | unit | JsonProperty / RequestMapping / RequestBody / unescapedInterpolations / inlineHandlerInterpolations / shouldBeEmpty | yes | |
