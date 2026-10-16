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
