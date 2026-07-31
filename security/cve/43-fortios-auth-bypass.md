# CVE-2024-55591 — FortiOS Authentication Bypass

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2024-55591 |
| CVSS | 9.8 (Critical) |
| 영향 소프트웨어 | Fortinet FortiOS, FortiProxy |
| 영향 버전 | FortiOS 7.0.0~7.0.16, FortiProxy 7.0.0~7.0.19, 7.2.0~7.2.12 |
| 수정 버전 | FortiOS 7.0.17+, FortiProxy 7.0.20+, 7.2.13+ |
| 공격 유형 | Authentication Bypass → super_admin 권한 획득 |
| 발견일 | 2025-01-14 |
| 공개 주체 | Fortinet PSIRT |

## 영향 범위 & 심각성

### 왜 프론트엔드 개발자가 알아야 하는가

FortiGate 방화벽은 기업 네트워크의 경계 보안을 담당하는 핵심 장비다. 이 취약점을 통해 공격자가 방화벽 관리자 권한을 획득하면:

- 회사 내부 네트워크 전체 접근 가능
- VPN 사용자 크리덴셜 탈취
- 네트워크 트래픽 감청
- 개발/스테이징/프로덕션 서버 직접 접근

**프론트엔드 개발자의 로컬 개발환경, Git 저장소, CI/CD 파이프라인 모두 위험에 노출**된다.

### 실제 피해 규모

- **Shodan 기준**: 인터넷에 노출된 FortiGate 관리 인터페이스 약 50만대+
- **Arctic Wolf 보고**: 2024년 11월부터 대규모 악용 캠페인 탐지
- **CISA**: 2025년 1월 Known Exploited Vulnerabilities 등재
- **피해 산업**: 금융, 의료, 제조, IT 서비스 등 광범위

### 공격 타임라인

| 시점 | 이벤트 |
|------|--------|
| 2024-11 중순 | 제로데이 악용 시작 (Arctic Wolf 탐지) |
| 2025-01-14 | Fortinet 공식 보안 권고 공개 |
| 2025-01-15 | CISA KEV 등재 |
| 2025-01-16 | PoC 코드 공개, 대규모 스캐닝 급증 |
| 2025-01-20 | 전 세계적으로 수천 대의 FortiGate가 이미 침해된 것으로 추정 |

## 취약점 기술 분석

### 근본 원인: Node.js WebSocket 핸들러의 인증 우회

FortiOS의 관리 인터페이스는 내부적으로 Node.js 기반 WebSocket 서비스를 사용한다. 이 WebSocket 엔드포인트(`/websocket`)에서 **인증 검증 없이 특정 요청을 처리**하는 결함이 존재했다.

### 공격 메커니즘

```
┌─────────────────────────────────────────────────┐
│ 1. FortiGate 관리 인터페이스에 WebSocket 연결    │
│    (포트 443 또는 관리 포트)                      │
├─────────────────────────────────────────────────┤
│ 2. 특수 조작된 WebSocket 메시지 전송             │
│    - jsconsole (Node.js 콘솔) 엔드포인트 악용    │
│    - 인증 토큰 없이 관리자 세션 생성 요청         │
├─────────────────────────────────────────────────┤
│ 3. FortiOS가 요청을 인증된 것으로 처리           │
│    - super_admin 권한의 관리자 계정 생성          │
│    - 또는 기존 관리자 비밀번호 변경               │
├─────────────────────────────────────────────────┤
│ 4. 생성된 계정으로 전체 방화벽 제어              │
│    - 방화벽 정책 변경                            │
│    - VPN 사용자 정보 탈취                        │
│    - SSL-VPN 포탈에 백도어 설치                   │
└─────────────────────────────────────────────────┘
```

### 기술적 세부사항

```javascript
// 취약한 WebSocket 핸들러 (개념적 설명)
// FortiOS 내부 Node.js 서비스

ws.on('message', (data) => {
  const msg = JSON.parse(data);
  
  // ❌ 취약점: jsconsole 요청에 대한 인증 검증 누락
  if (msg.type === 'jsconsole') {
    // 인증 토큰 검증 없이 관리 명령 실행
    executeAdminCommand(msg.command);
  }
});
```

## 공격 시나리오

### 실제 관찰된 공격 패턴

1. **정찰**: Shodan/Censys로 FortiGate 관리 인터페이스가 노출된 IP 스캔
2. **초기 접근**: WebSocket을 통한 인증 우회로 super_admin 계정 생성
3. **지속성 확보**: 
   - 새로운 로컬 관리자 계정 생성
   - SSL-VPN 포탈에 JavaScript 백도어 삽입
   - syslog 서버를 공격자 인프라로 변경
4. **횡이동**: VPN 사용자 크리덴셜로 내부 네트워크 접근
5. **목표 달성**: 
   - 랜섬웨어 배포
   - 데이터 유출
   - 암호화폐 채굴

### 프론트엔드 개발자에게 미치는 영향

```
방화벽 장악 → VPN 크리덴셜 탈취 → 개발자 계정으로 내부 접근
    ↓
- Git 저장소 접근 (소스코드 탈취)
- CI/CD 파이프라인 조작 (공급망 공격)
- 프로덕션 환경 변수/시크릿 접근
- npm/registry 토큰 탈취
```

## 방어 방법

### 1. 즉시 업데이트

```bash
# FortiOS 펌웨어 업데이트 (인프라팀 요청)
# FortiOS 7.0.17+ 또는 7.2.x 최신 버전으로 업그레이드
```

### 2. 관리 인터페이스 접근 제한 (업데이트 전 임시 조치)

- 관리 인터페이스를 인터넷에서 접근 불가능하도록 설정
- 관리 접근을 특정 IP/서브넷으로 제한
- HTTP/HTTPS 관리 비활성화하고 콘솔 접근만 허용

### 3. 침해 여부 확인

```bash
# FortiOS 로그에서 의심스러운 관리자 생성 확인
# diagnose sys admin list
# 알 수 없는 관리자 계정이 있는지 확인

# jsconsole 로그 확인
# grep "jsconsole" /var/log/fortigate.log
```

### 4. 개발자 관점 대응

- VPN 비밀번호 즉시 변경
- MFA 활성화 확인
- Git 토큰/SSH 키 로테이션
- CI/CD 시크릿 로테이션
- npm 2FA 활성화 확인

## 교훈

### 1. 네트워크 경계 장비의 관리 인터페이스는 인터넷에 노출하면 안 된다

"방화벽이니까 안전하다"는 생각이 가장 위험하다. 방화벽 자체가 공격 대상이 될 수 있으며, 관리 인터페이스는 반드시 격리된 관리 네트워크에서만 접근 가능해야 한다.

### 2. 인증 우회의 파급력

인증 한 단계가 무너지면 전체 시스템이 무너진다. 특히 최고 권한(super_admin)까지 한 번에 획득 가능한 취약점은 최악의 시나리오다.

### 3. 보안 장비 ≠ 보안

보안 장비도 소프트웨어이며, 소프트웨어에는 버그가 있다. "보안 장비를 썼으니 안전하다"는 잘못된 믿음이다. 보안 장비 자체의 업데이트와 감사도 필수다.

### 4. 개발자도 인프라 보안에 관심을 가져야 한다

프론트엔드 개발자라도 회사의 네트워크 보안 상태가 자신의 코드와 환경에 직접 영향을 미친다. 인프라팀과의 보안 커뮤니케이션이 중요하다.

## 참고 자료

- [Fortinet PSIRT Advisory — FG-IR-24-535](https://www.fortiguard.com/psirt/FG-IR-24-535)
- [CISA Advisory — CVE-2024-55591](https://www.cisa.gov/news-events/alerts/2025/01/15/fortinet-releases-security-updates)
- [Arctic Wolf — FortiGate Exploitation Campaign](https://arcticwolf.com/resources/blog/console-chaos-targets-fortinet-fortigate-firewalls)
- [NIST NVD — CVE-2024-55591](https://nvd.nist.gov/vuln/detail/CVE-2024-55591)
- [Shodan — Exposed FortiGate Interfaces](https://www.shodan.io/search?query=FortiGate)
