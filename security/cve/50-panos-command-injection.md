# CVE-2024-3400 - Palo Alto PAN-OS GlobalProtect 커맨드 인젝션

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2024-3400 |
| CVSS | 10.0 (Critical) |
| 영향 소프트웨어 | Palo Alto Networks PAN-OS (GlobalProtect) |
| 영향 버전 | PAN-OS 10.2, 11.0, 11.1 (특정 빌드) |
| 수정 버전 | PAN-OS 10.2.9-h1, 11.0.4-h1, 11.1.2-h3 |
| 공격 유형 | OS Command Injection → Root RCE |
| 발견일 | 2024-04-12 (제로데이 악용 확인) |

## 영향 범위 & 심각성

### 왜 치명적인가

Palo Alto Networks 방화벽은 **기업 네트워크의 최전방 보안 장비**다. GlobalProtect는 VPN 게이트웨이 기능을 제공하며, 이 장비가 장악되면:

- 방화벽 뒤의 **전체 내부 네트워크**가 공격자에게 노출
- 트래픽 감청, 규칙 변경, 백도어 설치 가능
- 보안 장비 자체가 공격 거점이 되는 최악의 시나리오

### 실제 피해

- **2024년 4월 제로데이로 악용** — 패치 전 이미 실전 공격에 사용됨
- 국가 지원 APT 그룹(UTA0218)이 정부기관과 기업을 타겟팅
- CISA 긴급 지시(Emergency Directive) 발령 — 연방기관 즉시 조치 명령
- Volexity에 의해 최초 발견, 이미 수주간 악용된 상태였음

### 영향 규모

- 전 세계 Palo Alto 방화벽 약 150,000대가 인터넷에 노출 (Shodan)
- GlobalProtect가 활성화된 모든 장비가 영향
- 기업, 정부, 군사 네트워크에서 광범위 사용
- VPN 포털은 설계상 인터넷에 노출되어야 하므로 회피 불가

## 취약점 기술 분석

### 근본 원인

GlobalProtect의 세션 처리에서 **사용자 입력(Cookie 값)이 OS 명령에 직접 삽입**된다.

### 기술적 메커니즘

1. **SESSID 쿠키 처리**: GlobalProtect가 HTTP 요청의 SESSID 쿠키 값을 처리
2. **경로 조작**: 쿠키 값이 파일 시스템 경로 생성에 사용됨
3. **디렉토리 생성**: 조작된 경로로 `mkdir` 호출 → 경로 순회로 임의 위치에 파일/디렉토리 생성
4. **명령 주입**: 특수 문자를 통해 OS 명령 주입 → root 권한으로 실행

### 2단계 익스플로잇

```
Stage 1: 경로 순회를 통한 임의 파일 생성 (정보 유출)
Stage 2: 명령 주입을 통한 root 권한 코드 실행
```

### 왜 root인가

- PAN-OS의 GlobalProtect 서비스는 root 권한으로 동작
- 방화벽 OS 특성상 모든 핵심 서비스가 높은 권한 보유
- 권한 상승 없이 바로 최고 권한 획득

## 공격 시나리오

### 공격 단계

```
1. 정찰: GlobalProtect 포털 발견 (인터넷에 노출된 VPN 게이트웨이)
2. 버전 확인: HTTP 응답에서 PAN-OS 버전 식별
3. Stage 1: 조작된 SESSID 쿠키로 파일 생성 → 취약점 확인
4. Stage 2: 명령 주입 페이로드로 역쉘 또는 웹쉘 배치
5. 지속성: cron job, 설정 변경으로 백도어 영속화
6. 내부 침투: 방화벽을 통한 내부 네트워크 전면 접근
```

### 실제 관찰된 공격자 행위 (UTA0218)

- 방화벽 설정 파일 탈취 (인증정보, 네트워크 토폴로지)
- 내부 Active Directory 서버 공격
- 횡적 이동 후 데이터 유출
- 다른 Palo Alto 장비로도 확산

### 타임라인

```
3월 중순: 최초 악용 시작 (추정)
4월 10일: Volexity가 이상 징후 탐지
4월 12일: Palo Alto Networks 권고 발표 (패치 미제공)
4월 14일: 핫픽스 배포 시작
4월 15일: CISA Emergency Directive 발령
```

## 방어 방법

### 즉시 조치

1. **핫픽스 적용**: PAN-OS 10.2.9-h1, 11.0.4-h1, 11.1.2-h3 이상으로 업데이트
2. **Threat Prevention**: Threat ID 95187, 95189, 95191 시그니처 활성화
3. **텔레메트리 비활성화**: 임시 완화 (패치 전)
4. **침해 조사**: 이미 악용되었을 가능성 확인 (로그, 설정 변경 점검)

### 장기 대책

- 방화벽/VPN 장비의 패치 SLA를 최우선으로 설정 (24시간 이내)
- 관리 인터페이스와 데이터 플레인 분리
- 방화벽 자체에 대한 모니터링 체계 구축 (설정 변경, 비정상 프로세스)
- 제로 트러스트 아키텍처로 방화벽 단일 실패점 의존도 감소
- 다중 벤더 전략 또는 보안 장비 이중화 검토

### 탐지 방법

- GlobalProtect 로그에서 비정상 SESSID 패턴 탐색
- 방화벽 장비에서 예기치 않은 프로세스/파일 생성 감지
- 외부에서 방화벽으로의 비정상 요청 패턴 모니터링
- 설정 변경 이력 감사 (자동화된 변경 탐지)

## 교훈

1. **보안 장비 ≠ 안전**: 방화벽, VPN, IDS 등 보안 장비 자체가 최고 가치 타겟
2. **VPN은 설계상 노출됨**: 외부 접근이 필수인 서비스는 특별히 강화해야 함
3. **입력 검증의 절대 원칙**: 어떤 컴포넌트든 사용자 입력을 OS 명령에 직접 넣으면 안 됨
4. **제로데이 대응 체계**: 패치 전 공격에 대비한 탐지/격리 능력 필요
5. **공급망 신뢰의 한계**: 신뢰하는 보안 벤더 제품도 독립적 모니터링 대상
6. **보안 장비 모니터링**: "누가 감시자를 감시하는가" — 방화벽도 감시 대상에 포함

## 참고 자료

- [Palo Alto Networks 보안 권고](https://security.paloaltonetworks.com/CVE-2024-3400)
- [CISA Emergency Directive ED-24-02](https://www.cisa.gov/emergency-directive-24-02)
- [Volexity 위협 분석](https://www.volexity.com/blog/2024/04/12/zero-day-exploitation-of-unauthenticated-remote-code-execution-vulnerability-in-globalprotect-cve-2024-3400/)
- [NVD CVE-2024-3400](https://nvd.nist.gov/vuln/detail/CVE-2024-3400)
- [Unit 42 위협 브리핑](https://unit42.paloaltonetworks.com/)
