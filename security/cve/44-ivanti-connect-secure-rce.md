# CVE-2025-0282 — Ivanti Connect Secure RCE

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2025-0282 |
| CVSS | 9.0 (Critical) |
| 영향 소프트웨어 | Ivanti Connect Secure, Ivanti Policy Secure, Ivanti Neurons for ZTA |
| 영향 버전 | Connect Secure 22.7R2 ~ 22.7R2.4, Policy Secure 22.7R1 ~ 22.7R1.2, Neurons for ZTA 22.7R2 ~ 22.7R2.3 |
| 수정 버전 | Connect Secure 22.7R2.5+, Policy Secure 22.7R1.3+ |
| 공격 유형 | Remote Code Execution (Stack-based Buffer Overflow) |
| 발견일 | 2025-01-08 |
| 공개 주체 | Ivanti / Mandiant (Google) |

## 영향 범위 & 심각성

### 왜 개발자가 알아야 하는가

Ivanti Connect Secure(구 Pulse Secure)는 **기업 VPN 솔루션**의 대표 제품이다. 원격 근무하는 개발자가 회사 네트워크에 접속할 때 사용하는 바로 그 VPN이다.

이 취약점이 악용되면:
- VPN 어플라이언스 자체가 장악됨
- VPN을 통해 접속하는 **모든 사용자의 크리덴셜이 탈취**됨
- 회사 내부 네트워크에 대한 무제한 접근 가능
- 개발자의 원격 접속 세션이 감청될 수 있음

### 실제 피해 규모

- **Mandiant 보고**: 중국 APT 그룹 UNC5337이 2024년 12월 중순부터 제로데이로 악용
- **CISA**: 2025년 1월 8일 긴급 지시(Emergency Directive 25-01) 발령
- **Shadowserver 기준**: 인터넷에 노출된 Ivanti Connect Secure 약 3,600대+
- **피해 조직**: 미국 정부기관, 방산업체, 통신사, 기술기업 등

### 공격 타임라인

| 시점 | 이벤트 |
|------|--------|
| 2024-12 중순 | UNC5337(중국 APT) 제로데이 악용 시작 |
| 2025-01-08 | Ivanti 보안 권고 공개 |
| 2025-01-08 | CISA 긴급 지시 ED-25-01 발령 |
| 2025-01-09 | Mandiant 상세 분석 보고서 공개 |
| 2025-01-10 | PoC 코드 공개, 공격 급증 |
| 2025-01-15 | 다수의 APT 그룹이 동시 악용 확인 |
| 2025-01-22 | Ivanti 추가 패치 및 Integrity Checker Tool 배포 |

## 취약점 기술 분석

### 근본 원인: 스택 기반 버퍼 오버플로우

Ivanti Connect Secure의 웹 인터페이스에서 사용자 인증 전 단계에서 처리하는 특정 HTTP 요청 파라미터에서 **길이 검증 없이 스택 버퍼에 복사**하는 코드가 존재했다.

### 공격 메커니즘

```
┌─────────────────────────────────────────────────────────┐
│ 1. 타깃 Ivanti VPN 어플라이언스의 HTTPS 포트 접근       │
│    (일반적으로 443 또는 8443)                            │
├─────────────────────────────────────────────────────────┤
│ 2. 인증 전 웹 컴포넌트에 조작된 HTTP 요청 전송          │
│    - 특정 파라미터에 오버사이즈 데이터 삽입              │
│    - 스택 버퍼 오버플로우 트리거                         │
├─────────────────────────────────────────────────────────┤
│ 3. Return address 덮어쓰기 → ROP 체인 실행             │
│    - ASLR/NX 우회를 위한 정교한 ROP 가젯 활용          │
│    - 쉘코드 실행으로 이어짐                              │
├─────────────────────────────────────────────────────────┤
│ 4. 시스템 레벨 코드 실행                                 │
│    - 웹셸 설치                                          │
│    - VPN 세션 데이터베이스 접근                          │
│    - 사용자 크리덴셜 수집                                │
│    - 내부 네트워크로 터널링                               │
└─────────────────────────────────────────────────────────┘
```

### UNC5337의 실제 공격 도구

Mandiant가 분석한 공격 도구 체인:

1. **SPAWN 말웨어 패밀리**:
   - `SPAWNANT`: 설치 프로그램 (persistence)
   - `SPAWNMOLE`: 터널링 도구 (traffic proxy)
   - `SPAWNSNAIL`: SSH 백도어
   - `SPAWNSLOTH`: 로그 변조 도구

2. **DRYHOOK**: 크리덴셜 수집기 — VPN 로그인 시 평문 비밀번호 캡처
3. **PHASEJAM**: 웹셸 — 어플라이언스에 지속적 접근 유지

## 공격 시나리오

### 개발자 관점에서의 위험

```
Ivanti VPN 장악 (CVE-2025-0282)
    ↓
DRYHOOK으로 개발자 VPN 로그인 크리덴셜 캡처
    ↓
개발자 계정으로 내부 네트워크 접근
    ↓
├── Git 서버 (GitHub Enterprise / GitLab) 접근
├── CI/CD (Jenkins / GitHub Actions self-hosted runner) 접근
├── 내부 API / 마이크로서비스 접근
├── 데이터베이스 접근
└── 클라우드 콘솔 (AWS/GCP/Azure) 내부 접근
```

### 특히 위험한 상황

- **SSO 연동**: VPN 인증이 회사 SSO와 연동된 경우, 탈취된 크리덴셜로 모든 SaaS 접근 가능
- **Split tunneling 미사용**: 모든 트래픽이 VPN을 통과하는 경우, 개발자의 모든 활동 감청 가능
- **MFA 세션 탈취**: VPN 세션 쿠키를 직접 탈취하면 MFA도 우회 가능

## 방어 방법

### 1. 즉시 업데이트

```bash
# Ivanti Connect Secure 22.7R2.5 이상으로 업그레이드
# 인프라/보안팀에 긴급 패치 요청
```

### 2. Integrity Checker Tool 실행

Ivanti가 제공하는 ICT(Integrity Checker Tool)로 침해 여부 확인:
- 파일시스템 무결성 검사
- 알려진 웹셸 패턴 탐지
- 비정상 프로세스 확인

### 3. 침해 의심 시 대응

- VPN 어플라이언스 격리 (네트워크 분리)
- 모든 VPN 사용자 비밀번호 강제 리셋
- 인증서/토큰 전체 로테이션
- Factory reset 후 클린 이미지로 재설치

### 4. 개발자가 직접 할 수 있는 조치

```bash
# 1. VPN 비밀번호 즉시 변경
# 2. SSH 키 로테이션
ssh-keygen -t ed25519 -C "new-key-after-ivanti"

# 3. Git 토큰 재발급
gh auth refresh

# 4. AWS/클라우드 자격증명 로테이션
aws iam create-access-key --user-name myuser
aws iam delete-access-key --user-name myuser --access-key-id OLD_KEY

# 5. npm/registry 토큰 재발급
npm token revoke <old-token>
npm token create
```

### 5. 장기 대응

- VPN 어플라이언스를 Zero Trust Network Access(ZTNA)로 대체 검토
- VPN 접속 시 디바이스 검증 강화
- VPN 로그인에 하드웨어 키(YubiKey) 기반 MFA 적용
- VPN 트래픽 이상 탐지 시스템 구축

## 교훈

### 1. VPN은 단일 실패점(Single Point of Failure)이다

모든 원격 접속이 하나의 VPN을 통과하면, 그 VPN이 뚫리는 순간 모든 것이 무너진다. Zero Trust 아키텍처는 이 문제를 해결하기 위한 패러다임이다.

### 2. 국가 수준 APT 그룹은 VPN을 가장 먼저 노린다

네트워크 경계 장비(VPN, 방화벽)는 국가 수준 공격자의 1순위 타깃이다. 내부 네트워크 접근의 가장 효율적인 경로이기 때문이다.

### 3. 패치 전 악용(Zero-day)의 현실

이 취약점은 패치 공개 전 최소 3주 동안 악용되었다. "패치 나오면 적용하겠다"는 전략으로는 국가급 위협에 대응할 수 없다. 이상 행위 탐지(NDR/EDR)가 보완적으로 필요하다.

### 4. 보안은 개발자의 책임이기도 하다

VPN 침해로 인한 소스코드 유출, 공급망 공격은 궁극적으로 개발 조직에 큰 피해를 준다. 인프라 보안 상태에 관심을 갖고, 보안팀과 협력하여 개발 환경의 안전을 확보해야 한다.

## 참고 자료

- [Ivanti Security Advisory — CVE-2025-0282](https://forums.ivanti.com/s/article/Security-Advisory-Ivanti-Connect-Secure-Policy-Secure-ZTA-Gateways)
- [CISA Emergency Directive 25-01](https://www.cisa.gov/news-events/directives/ed-25-01)
- [Mandiant — Exploitation of CVE-2025-0282](https://cloud.google.com/blog/topics/threat-intelligence/ivanti-connect-secure-cve-2025-0282)
- [NIST NVD — CVE-2025-0282](https://nvd.nist.gov/vuln/detail/CVE-2025-0282)
- [Volexity — Active Exploitation Analysis](https://www.volexity.com/blog/2025/01/ivanti-connect-secure-exploitation/)
