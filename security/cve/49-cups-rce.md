# CVE-2024-47176 - CUPS 인쇄 시스템 원격 코드 실행

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2024-47176 |
| CVSS | 9.9 (Critical) |
| 영향 소프트웨어 | CUPS (cups-browsed 데몬) |
| 영향 버전 | cups-browsed ≤ 2.0.1 |
| 수정 버전 | cups-browsed 2.1.0 이상 (또는 배포판별 패치) |
| 공격 유형 | Remote Code Execution (체이닝) |
| 발견일 | 2024-09-26 |

## 영향 범위 & 심각성

### 왜 치명적인가

CUPS(Common Unix Printing System)는 **거의 모든 Linux 배포판과 macOS에 기본 설치**되는 인쇄 시스템이다. `cups-browsed` 데몬은 네트워크 프린터 자동 검색을 위해 UDP 631 포트를 열고 **모든 패킷을 신뢰**한다.

- 사실상 모든 Linux 서버와 데스크톱이 잠재적 영향
- macOS도 영향 — 개발자 로컬 머신 포함
- 4개 CVE가 체이닝되어 완전한 RCE 달성 (CVE-2024-47176, 47076, 47175, 47177)

### 실제 피해

- 2024년 9월 공개 당시 "다음 Log4Shell"이라는 경고와 함께 대규모 주목
- Shodan 기준 UDP 631 포트가 열린 시스템 수십만 대 발견
- 데이터센터의 Linux 서버 대부분이 CUPS 설치 (사용하지 않아도)
- 인터넷 직접 노출 시 단일 UDP 패킷으로 공격 시작 가능

### 영향 규모

- 모든 주요 Linux 배포판: Ubuntu, Debian, Fedora, RHEL, SUSE 등
- macOS (cups-browsed 활성화된 경우)
- 클라우드 VM 이미지에도 기본 포함된 경우 다수
- 컨테이너 환경에서는 대체로 미설치 (영향 적음)

## 취약점 기술 분석

### 근본 원인

`cups-browsed`가 **UDP 631 포트에서 받은 모든 패킷을 검증 없이 신뢰**하고, 공격자가 지정한 IPP(Internet Printing Protocol) URL로 연결을 시도한다.

### 4개 CVE 체이닝

| CVE | 역할 |
|-----|------|
| CVE-2024-47176 | cups-browsed가 임의 IPP 서버 연결 유도 |
| CVE-2024-47076 | libcupsfilters가 IPP 응답의 속성을 검증 없이 전달 |
| CVE-2024-47175 | libppd가 악성 속성을 PPD 파일에 기록 |
| CVE-2024-47177 | cups-filters의 foomatic-rip이 PPD의 명령을 실행 |

### 공격 흐름

```
공격자 UDP 패킷 → cups-browsed (프린터 등록)
    → 악성 IPP 서버 연결 → 조작된 프린터 속성 수신
    → PPD 파일에 명령 삽입 → 인쇄 시 foomatic-rip이 명령 실행
```

### 트리거 조건

- `cups-browsed`가 실행 중이고 UDP 631이 열려 있어야 함
- 실제 인쇄 작업이 발생해야 코드 실행 (공격자가 유도 가능)
- 또는 자동 프린터 설정이 활성화된 경우 자동 트리거

## 공격 시나리오

### 공격 단계

```
1. 스캔: UDP 631 포트가 열린 대상 발견
2. 패킷 전송: 조작된 UDP 브라우징 패킷 전송 (악성 IPP 서버 URL 포함)
3. 프린터 등록: cups-browsed가 공격자의 IPP 서버에 연결
4. 속성 주입: 악성 IPP 서버가 조작된 프린터 속성 반환
5. PPD 오염: 명령이 포함된 PPD 파일 생성
6. 트리거: 인쇄 작업 발생 시 (또는 유도 시) 임의 명령 실행
```

### macOS 개발자 시나리오

- 카페/공유 오피스 Wi-Fi에서 공격자가 UDP 패킷 전송
- 개발자 맥북에 악성 프린터 자동 등록
- 다음 인쇄 시 개발자 권한으로 명령 실행
- SSH 키, 소스코드, 클라우드 크레덴셜 탈취

## 방어 방법

### 즉시 조치

1. **cups-browsed 비활성화**: `sudo systemctl stop cups-browsed && sudo systemctl disable cups-browsed`
2. **UDP 631 차단**: 방화벽에서 인바운드 UDP 631 차단
3. **패치 적용**: 배포판별 보안 업데이트 적용

### macOS 조치

```bash
# cups-browsed 상태 확인
launchctl list | grep cups-browsed
# 비활성화
sudo launchctl unload /System/Library/LaunchDaemons/org.cups.cups-browsed.plist
```

### 장기 대책

- 서버에서 CUPS가 불필요하면 완전 제거
- 필요한 경우에도 cups-browsed는 비활성화 (수동 프린터 등록 사용)
- 네트워크 프린터 검색이 필요한 경우 별도 VLAN에서만 허용
- 클라우드 VM 이미지에서 불필요한 서비스 제거 (CIS 벤치마크)

### 탐지 방법

- UDP 631 포트로의 외부 패킷 모니터링
- cups-browsed의 비정상 외부 연결 시도 감지
- 새로운 프린터 자동 등록 이벤트 알림

## 교훈

1. **기본 설치 서비스의 위험**: 사용하지 않는 서비스도 공격 표면을 만든다
2. **UDP는 특히 위험**: 연결 상태가 없어 스푸핑/인젝션이 용이
3. **신뢰 체인의 취약함**: 4개 컴포넌트의 검증 부재가 체이닝되어 RCE 달성
4. **최소 설치 원칙**: 서버에는 필요한 것만 설치, 불필요한 데몬은 비활성화
5. **레거시 프로토콜 경계**: IPP/CUPS는 90년대 설계로 현대 보안 기준에 부합하지 않음
6. **개발자 머신도 타겟**: macOS 개발 환경도 예외 없이 보안 강화 필요

## 참고 자료

- [NVD CVE-2024-47176](https://nvd.nist.gov/vuln/detail/CVE-2024-47176)
- [발견자(evilsocket) 상세 분석](https://www.evilsocket.net/2024/09/26/Attacking-UNIX-systems-via-CUPS-Part-I/)
- [RedHat 보안 권고](https://access.redhat.com/security/vulnerabilities/RHSB-2024-002)
- [Ubuntu 보안 공지](https://ubuntu.com/security/notices)
- [CUPS 프로젝트](https://openprinting.github.io/cups/)
