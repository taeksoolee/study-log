# CVE-2024-6387 - OpenSSH regreSSHion

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2024-6387 |
| CVSS | 8.1 (High) |
| 영향 소프트웨어 | OpenSSH (sshd) |
| 영향 버전 | 8.5p1 ~ 9.7p1 (glibc 기반 Linux) |
| 수정 버전 | 9.8p1 |
| 공격 유형 | Race Condition → RCE (root 권한) |
| 발견일 | 2024-07-01 |

## 영향 범위 & 심각성

OpenSSH는 사실상 모든 Linux/Unix 서버의 원격 접속 표준이다. sshd는 인터넷에 직접 노출되는 서비스로, 이 취약점은 인증 없이 root 권한으로 RCE를 달성할 수 있다.

**실제 영향:**
- Qualys 연구팀이 발견, "regreSSHion"이라 명명 (regression + SSH)
- Shodan 기준 1,400만 대 이상의 sshd가 인터넷에 노출
- 2006년 수정된 CVE-2006-5051의 회귀(regression) — 14년 만에 재발견
- glibc 기반 Linux 시스템에서 실증됨 (32비트에서 ~6시간, 64비트에서 이론적으로 가능)
- 실제 대규모 악용 보고는 제한적이나, 국가급 공격자에겐 충분히 실용적

## 취약점 기술 분석

### 근본 원인

sshd의 `SIGALRM` 시그널 핸들러에서 async-signal-unsafe 함수를 호출하는 race condition이다.

**메커니즘:**
1. 클라이언트가 SSH 연결을 시작하되 인증을 완료하지 않음
2. `LoginGraceTime`(기본 120초) 타임아웃 시 `SIGALRM` 발생
3. 시그널 핸들러가 `syslog()` → `malloc()`/`free()` 호출
4. 메인 코드가 `malloc()`/`free()` 실행 중에 시그널이 끼어들면 힙 상태가 손상됨
5. 손상된 힙을 통해 임의 코드 실행

### 핵심 문제

```c
// 시그널 핸들러에서 호출되면 안 되는 함수들
static void grace_alarm_handler(int sig) {
    // syslog()는 내부적으로 malloc/free를 호출 — async-signal-unsafe!
    syslog(LOG_INFO, "Timeout before authentication");
    _exit(1);
}
```

- **async-signal-safety 위반**: 시그널 핸들러에서 비안전 함수 호출
- **회귀 버그**: 2006년 수정되었으나 2020년 리팩토링 시 다시 도입 (commit D1310b2)
- **힙 조작 난이도**: ASLR/PIE 우회가 필요하나, 반복 시도로 극복 가능

## 공격 시나리오

### 단계별 공격

1. **대상 식별**: 취약한 OpenSSH 버전 실행 중인 서버 탐색
2. **반복 연결**: 수천~수만 회 SSH 연결 시도 (인증 미완료 상태 유지)
3. **Race Condition 트리거**: `LoginGraceTime` 타임아웃과 힙 연산 타이밍 일치 유도
4. **힙 손상 → 코드 실행**: 손상된 힙 메타데이터를 통해 제어 흐름 탈취

### 공격 특성
```
시도 횟수: 32비트 glibc Linux에서 ~10,000회 (평균 6~8시간)
64비트: 이론적으로 가능하나 ASLR로 인해 훨씬 많은 시도 필요
탐지: 대량의 실패 연결 로그 생성 — 탐지 가능
```

### 제약 조건
- glibc 기반 Linux에서만 실증됨 (musl libc, BSD 계열은 영향 적음)
- `LoginGraceTime 0` 설정 시 취약하지 않음 (단, DoS에는 노출)
- 최신 64비트 시스템에서는 실용적 공격 난이도 높음

## 방어 방법

### 즉시 조치
1. **OpenSSH 9.8p1 이상으로 업그레이드**
2. 업그레이드 불가 시 `sshd_config`에서 임시 완화:
```
# /etc/ssh/sshd_config
LoginGraceTime 0
```
> 주의: LoginGraceTime 0은 DoS 위험 증가 (연결 자원 무한 점유)

### 장기 대책
- SSH 접근을 Jump Host/Bastion으로 제한
- fail2ban/sshguard로 반복 연결 시도 차단
- 네트워크 레벨에서 SSH 포트 접근을 IP 화이트리스트로 제한
- 패치 자동화 파이프라인 구축 (unattended-upgrades 등)
- 커널 보안 강화: ASLR, SELinux/AppArmor 활성화

### 탐지 방법
```bash
# 비정상적으로 많은 SSH 연결 시도 탐지
journalctl -u sshd | grep "Timeout before authentication" | wc -l
```

## 교훈

1. **회귀 버그의 위험**: 한번 수정된 취약점도 리팩토링 시 다시 도입될 수 있음
2. **시그널 핸들러 안전성**: async-signal-unsafe 함수 호출은 잠재적 RCE로 이어짐
3. **기초 인프라의 중요성**: sshd 하나의 취약점이 전 세계 서버에 영향
4. **깊은 방어**: SSH 서비스를 직접 노출하지 않는 아키텍처(Zero Trust, Bastion) 필수
5. **코드 리뷰 시 보안 회귀 점검**: 과거 보안 패치가 유지되고 있는지 확인하는 프로세스 필요

## 참고 자료

- [NVD - CVE-2024-6387](https://nvd.nist.gov/vuln/detail/CVE-2024-6387)
- [Qualys 연구 보고서 - regreSSHion](https://www.qualys.com/2024/07/01/cve-2024-6387/regresshion.txt)
- [OpenSSH 9.8 릴리스 노트](https://www.openssh.com/txt/release-9.8)
- [Qualys 블로그](https://blog.qualys.com/vulnerabilities-threat-research/2024/07/01/regresshion-remote-unauthenticated-code-execution-vulnerability-in-openssh-server)
