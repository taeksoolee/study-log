# CVE-2024-37079 - VMware vCenter Server DCERPC 힙 오버플로우 RCE

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2024-37079 |
| CVSS | 9.8 (Critical) |
| 영향 소프트웨어 | VMware vCenter Server, VMware Cloud Foundation |
| 영향 버전 | vCenter Server 7.0 U3 이전, 8.0 U2 이전 |
| 수정 버전 | vCenter Server 7.0 U3r, 8.0 U2d |
| 공격 유형 | Remote Code Execution (힙 오버플로우) |
| 발견일 | 2024-06-17 |

## 영향 범위 & 심각성

### 왜 치명적인가

VMware vCenter Server는 기업 가상화 인프라의 **중앙 관리 서버**다. ESXi 호스트 수십~수백 대를 관리하며, vCenter가 장악되면 전체 가상 머신(VM) 환경을 제어할 수 있다.

### 실제 피해

- 2025년 초 CISA KEV(Known Exploited Vulnerabilities) 카탈로그에 등재 — 실제 공격에 사용 확인
- 국가 지원 APT 그룹(특히 중국계)이 VMware 취약점을 조직적으로 악용하는 패턴 반복
- Fortune 500 기업 대다수가 VMware 인프라 사용 → 공격 표면 극대
- vCenter 하나를 장악하면 수백 대 VM의 스냅샷 탈취, 랜섬웨어 배포, 백도어 설치 가능

### 영향 규모

- 전 세계 수만 대의 vCenter 인스턴스가 인터넷에 노출 (Shodan 기준)
- 내부 네트워크 접근만으로도 공격 가능 (대부분 vCenter는 내부망에 위치)
- VMware Cloud Foundation 사용 조직도 동일하게 영향

## 취약점 기술 분석

### 근본 원인

vCenter Server의 **DCERPC(Distributed Computing Environment / Remote Procedure Calls)** 프로토콜 구현에서 힙 기반 버퍼 오버플로우가 발생한다.

### 기술적 메커니즘

1. **DCERPC 프래그먼트 처리**: vCenter는 DCERPC 요청 처리 시 프래그먼트된 패킷을 재조립
2. **길이 검증 부재**: 재조립 과정에서 패킷 크기 검증이 불완전
3. **힙 오버플로우**: 공격자가 조작한 크기의 프래그먼트 전송 시 힙 버퍼 초과 쓰기 발생
4. **코드 실행**: 힙 메타데이터 조작을 통해 임의 코드 실행 달성

### 왜 인증 없이 가능한가

- DCERPC 바인딩 과정은 인증 이전에 발생
- 네트워크 레벨에서 vCenter 포트(기본 443)에 접근 가능하면 공격 수행 가능
- TLS 위에서 동작하지만 인증서 검증만으로는 방어 불가

## 공격 시나리오

### 공격 단계

```
1. 정찰: vCenter Server 포트(443) 스캔 및 버전 확인
2. 연결: DCERPC 바인딩 요청 전송
3. 프래그먼트 조작: 힙 오버플로우를 유발하는 조작된 DCERPC 프래그먼트 전송
4. 힙 스프레이: 안정적인 코드 실행을 위한 힙 레이아웃 조작
5. RCE 달성: vCenter 프로세스 권한(root)으로 임의 명령 실행
6. 횡적 이동: ESXi 호스트 접근 → VM 장악 → 데이터 탈취/암호화
```

### 실제 공격 체인 예시

- vCenter 장악 → ESXi 호스트 SSH 활성화 → VM 디스크 직접 접근
- vCenter DB에서 모든 인증정보 추출 → 내부 네트워크 전체 장악
- VM 스냅샷을 외부로 유출 → 데이터베이스, 소스코드 등 대량 탈취

### 타임라인

```
2024-06-17: VMware 보안 권고 VMSA-2024-0012 공개 및 패치 배포
2024-06-18: PoC 개발 및 분석 시작 (보안 연구커뮤니티)
2024 하반기: 미패치 시스템 대상 스캐닝 활동 증가
2025 초: CISA KEV 등재 — 실제 공격 캠페인 확인
```

## 방어 방법

### 즉시 조치

1. **패치 적용**: vCenter Server 7.0 U3r 또는 8.0 U2d로 즉시 업데이트
2. **네트워크 격리**: vCenter 관리 인터페이스를 전용 관리 VLAN으로 분리
3. **방화벽 규칙**: vCenter 포트(443, 902)에 대한 접근을 관리자 IP만 허용

### 장기 대책

- vCenter를 인터넷에 절대 노출하지 않음 (VPN 뒤에 배치)
- 네트워크 세그멘테이션으로 관리 플레인 격리
- vCenter 접근 로그 모니터링 (비정상 DCERPC 트래픽 감지)
- VMware 보안 권고를 구독하고 패치 SLA를 72시간 이내로 설정

### 탐지 방법

- 비정상적으로 큰 DCERPC 프래그먼트 탐지 (IDS/IPS 룰)
- vCenter 프로세스의 비정상 자식 프로세스 생성 모니터링
- ESXi 호스트에서 예기치 않은 SSH 활성화 감지
- vCenter 서버 파일 무결성 모니터링 (FIM)
- vpxd 서비스 로그에서 비정상 DCERPC 세션 분석

## 교훈

1. **관리 서버는 최우선 패치 대상**: 인프라를 관리하는 서버가 뚫리면 게임 오버
2. **네트워크 접근 = 인증 아님**: 네트워크에 접근 가능하다는 것만으로 공격이 성립하는 취약점이 반복됨
3. **가상화 인프라의 단일 실패점**: vCenter는 SPOF — 이중화와 접근 제어가 필수
4. **DCERPC는 레거시 공격 표면**: Windows RPC와 유사한 복잡한 프로토콜은 지속적으로 취약점 발견
5. **제로데이 가정 방어**: 패치 전에도 네트워크 격리로 피해를 최소화할 수 있어야 함
6. **패치 후에도 침해 조사 필수**: 패치 이전에 이미 악용되었을 가능성을 항상 고려

## 참고 자료

- [VMware 보안 권고 VMSA-2024-0012](https://www.vmware.com/security/advisories/VMSA-2024-0012.html)
- [CISA KEV 카탈로그](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)
- [NVD CVE-2024-37079](https://nvd.nist.gov/vuln/detail/CVE-2024-37079)
- [Mandiant - 중국 APT의 VMware 타겟팅 분석](https://www.mandiant.com/)
- [Shodan vCenter 노출 현황](https://www.shodan.io/)
- [VMware vCenter Server 보안 강화 가이드](https://docs.vmware.com/en/VMware-vSphere/index.html)
