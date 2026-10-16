# MapStruct × Kotlin data class — `val` 이 조용히 비는 조건과 규약

> **자기완결 문서.** MapStruct + Kotlin 을 쓰는 파생 프로젝트에 이 파일을 그대로 가져가 규약과 검출 테스트를 적용할 수 있다.

## 요약

1. **`val` 자체는 문제가 아니다.** MapStruct(1.4+)는 대상에 파라미터 없는 생성자가 없으면 **생성자 매핑**을 쓰고, Kotlin `val` 을 정상적으로 채운다.
2. **문제는 「모든 파라미터에 기본값」이다.** 그러면 Kotlin 이 JVM 에 파라미터 없는 생성자를 추가로 만들고, MapStruct 는 그것을 골라 **setter 로 채우려** 한다. `val` 은 setter 가 없으니 **빈 객체가 반환**되며, 컴파일 에러도 경고도 없다.
3. 흔히 쓰는 「DTO/Model 은 `var` 필수, `val` 금지」 규칙은 이 증상을 겪고 나온 **우회책**이다. 원인을 규약으로 적으면 `val`(불변)을 유지하면서 같은 사고를 막을 수 있고, 검출 테스트로 고정할 수 있다.

## 증상

```java
// build/generated/source/kapt/main/.../mapper/calendar/LocalTimeMapperImpl.java — 전부-기본값 val data class 를 대상으로 한 생성물
LocalTimeModel localTimeModel = new LocalTimeModel();
return localTimeModel;            // hour · minute · second · nano 전부 미매핑
```


## 원인 — 두 규칙의 결합

| 규칙 | 내용 |
|---|---|
| **MapStruct 생성자 선택** (1.4+ 「Using Constructors」) | ① `@Default` 가 붙은 생성자가 있으면 그것 ② 아니면 public 생성자가 하나면 그것 ③ **파라미터 없는 생성자가 있으면 그것을 쓰고 나머지는 무시** ④ 그 외 복수면 컴파일 에러 |
| **Kotlin no-arg 생성자 생성** | 주 생성자의 **모든** 파라미터에 기본값이 있으면 JVM 에 파라미터 없는 생성자를 추가로 생성한다 (`kotlin-noarg`/`kotlin-jpa` 플러그인이 붙은 클래스도 같다) |

둘이 만나면: 전부-기본값 data class → no-arg 생성자 존재 → MapStruct 가 ③ 을 택함 → setter 탐색 → `val` 은 쓸 수 있는 프로퍼티가 0개 → **"unmapped target" 으로도 잡히지 않는다**(쓸 대상 자체가 없으므로) → 빈 객체.

`var` 로 바꾸면 setter 가 생겨 동작한다. 그래서 「`var` 필수」가 효과는 있지만, **원인(전부 기본값)** 은 규약에 남지 않는다.

## 실측 근거

| 대상 | 관찰 |
|---|---|
| 스켈레톤 생성물 `build/…/*MapperImpl.java` | 기본값이 일부뿐인 `val` data class 는 생성자 매핑 — 값을 지역변수로 모아 `new XxxDto(…)`. **`val` 로 정상 동작** |
| 전부-기본값 `val` data class + 매퍼 | 생성물이 `new XxxModel();` 만 하고 반환 — 모든 프로퍼티 미매핑, 컴파일 경고 없음 |
| MapStruct 버전 | 스켈레톤 3종 **1.6.3** (생성자 매핑 지원) |


> **역사적 배경.** MapStruct 1.4(2020-09) 이전에는 생성자 매핑이 없어 스타일과 무관하게 no-arg 생성자 + setter(`var`)가 필수였다. 「`var` 필수」기억의 일부는 그 시절 것이다. 지금은 해당하지 않는다.

## 규약 — 원인으로 적는다 (스켈레톤 채택 문구)

- DTO/Model 은 **data class + `val` + 생성자 매핑**이다. MapStruct 는 주 생성자로 채운다.
- **프로퍼티는 non-null 을 기본으로 한다.** 도메인상 없을 수 있는 값만 `?` 로 두고, 그때도 `= null` 기본값을 습관적으로 붙이지 않는다. 「전부 optional」 Model 은 설계 냄새다.
- **모든 파라미터에 기본값을 주지 않는다.** 전부 기본값이면 Kotlin 이 파라미터 없는 생성자를 만들고 MapStruct 가 setter 경로로 떨어져 `val` 이 채워지지 않는다. 정말 전부 optional 이어야 하면 생성자에 MapStruct 의 `@Default` 를 붙여 생성자 매핑을 강제한다:
  ```kotlin
  annotation class Default   // MapStruct 는 이름이 Default 인 어떤 어노테이션이든 인식한다

  data class PeriodModel @Default constructor(
      val from: LocalDate? = null,
      val to: LocalDate? = null,
  )
  ```
- `@MappingTarget` 갱신 매핑(기존 객체를 채우는 매퍼)을 쓸 때만 그 대상 프로퍼티를 `var` 로 선언한다.
- `MapstructConfiguration` 의 `unmappedTargetPolicy` 는 이 결함을 잡지 못한다(쓸 대상이 0개라 미매핑 보고가 없다). **검출은 아래 테스트가 한다.**

## 검출 장치 — 생성물 검사 테스트

컴파일러·MapStruct 모두 경고하지 않으므로 **생성된 소스를 검사하는 유닛 테스트**를 둔다. 스켈레톤 3종에 넣고 `SKELETON/docs/contract-surfaces.md` 「대응」 표에 등록한다(장치 B).

```kotlin
// src/test/unit/kotlin/<base>/mapper/MapStructConstructorMappingTest.kt (스케치)
class MapStructConstructorMappingTest : StringSpec({
    "생성된 MapperImpl 은 DTO·Model 을 파라미터 없는 생성자로 만들지 않는다" {
        val generated = Paths.get("build/generated/source/kapt/main")
        val offenders = Files.walk(generated).filter { it.toString().endsWith("MapperImpl.java") }
            .flatMap { path ->
                Files.readAllLines(path).asSequence()
                    .filter { Regex("""new \w+(Dto|Model)\(\);""").containsMatchIn(it) }
                    .map { "${generated.relativize(path)}: ${it.trim()}" }.asStream()
            }.toList()
        offenders.shouldBeEmpty()
    }
})
```

- 대상 패턴 `new <X>(Dto|Model)();` — setter 경로의 유일한 서명이다. 생성자 경로는 항상 인자를 갖는다.
- kapt 산출물은 `compileKotlin` 뒤에 존재하므로 `test` 태스크 순서상 항상 있다. 파일이 하나도 없으면 실패시킨다(「검사할 것이 없어서 통과」방지).

## 함정 둘 더 — `is`-prefix Boolean, JPA no-arg 생성자

### `is`-prefix Boolean 은 생성자 매핑에서 조용히 `false` 가 된다

Kotlin `val isActive: Boolean` 의 getter 는 `isActive()` 다. MapStruct 는 JavaBeans 규칙으로 getter `isActive()` 에서 **소스 프로퍼티명 `active`** 를 뽑는다. 타깃이 `data class` 면 생성자 파라미터 이름이 `isActive` 라 이름이 맞지 않아 **미매핑**이고, `unmappedTargetPolicy = IGNORE` 아래서는 경고도 없이 `boolean isActive = false;` 가 생성자에 들어간다. 세터 타깃(JPA 엔티티 `setActive`)은 이름이 맞아 저장은 정상이고 **조회 응답만 틀린다** — 그래서 오래 숨는다.

스켈레톤 실측(kapt 생성물에서 `boolean isX = false;` 선언 뒤 재할당 없음): public `SecurityMapperImpl` `isActive`(toDto·toModel)·`isPermanent`·`isLocked`, `AuthMapperImpl` `isCurrentSession`, batch `JobScheduleConfigMapperImpl` `isEnabled` — 차단 IP 목록·계정 잠금·세션 목록·스케줄 목록 응답이 항상 `false` 였다. 수정은 `@Mapping(source = "active", target = "isActive")` 명시. `unmappedTargetPolicy = ERROR` 였다면 컴파일 단계에서 드러났다.

### JPA no-arg 생성자는 초기화식을 실행하지 않는다

`kotlin("plugin.jpa")` 가 `@Entity` 에 만들어 주는 합성 no-arg 생성자는 **`super(); return` 뿐**이다(`javap -c` 로 `BlockedIpEntity()` 확인; kotlin-noarg 의 `invokeInitializers` 기본값 `false`). MapStruct 가 엔티티를 `new X()` + setter 로 채울 때 `ignore` 되거나 소스가 없는 프로퍼티는 `var blockedAt: LocalDateTime = LocalDateTime.now()` 같은 초기화식과 **무관하게 `null`/`0`** 이다. 「JpaEntity body 프로퍼티는 ignore 해도 기본값이 남는다」는 전제는 틀렸다 — non-null 타깃 `ignore` 금지는 Entity 에도 그대로 적용한다(`@Id` 만 예외).

### `unmappedTargetPolicy = ERROR` 와 non-null 타깃

- 소스에 없는 타깃은 `@Mapping(target, ignore = true)` 를 **써야 컴파일**된다 — 미매핑이 침묵으로 지나가지 않는다.
- `ignore` 는 **nullable 타깃과 `@Id`** 에만. non-null 타깃은 `source`·`expression`·`constant` 로 명시.
- nullable 소스 → non-null 타깃은 `source` 만 명시해도 `null` 이 생성자에 들어간다. `expression`(null-safe)·`defaultValue`·`defaultExpression`, 또는 non-null 을 반환하는 `@Named` 변환으로만 닫는다.
- MapStruct 애노테이션은 `RetentionPolicy.CLASS` 라 런타임 리플렉션으로는 검사할 수 없다 — 검사 테스트는 ClassGraph 로 클래스 파일의 invisible 애노테이션을 읽는다(`MapStructConstructorMappingTest` M-3~M-5).
