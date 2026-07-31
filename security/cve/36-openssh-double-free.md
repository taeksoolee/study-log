# CVE-2023-25136 - OpenSSH Pre-Auth Double Free

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2023-25136 |
| CVSS | 6.5 (Medium) |
| 영향 소프트웨어 | OpenSSH (sshd) |
| 영향 버전 | 9.1 |
| 수정 버전 | 9.2 |
| 공격 유형 | Double Free → DoS (잠재적 RCE) |
| 발견일 | 2023-02-02 |

## 영향 범위 & 심각성

OpenSSH 9.1 단일 버전에만 영향을 미치지만, 인증 전(pre-authentication) 단계에서 발생한다는 점이 중요하다.

**실제 영향:**
- OpenSSH 9.1을 사용하는 모든 서버가 잠재적 대상
- 직접적인 RCE 달성은 어렵지만 DoS(서비스 거부)는 비교적 쉬움
- sshd의 권한 분리(privsep) 아키텍처가 RCE 영향을 제한
- 보안 연구자들이 실제 RCE PoC를 부분적으로 시연
- regreSSHion(CVE-2024-6387)과 함께 OpenSSH의 메모리 안전성 문제를 부각

## 취약점 기술 분석

### 근본 원인

SSH 키 교환(key exchange) 과정에서 `options.kex_algorithms` 처리 시 double-free가 발생한다.

**메커니즘:**
1. 클라이언트가 SSH 핸드셰이크 시 KEX_INIT 메시지를 전송
2. 서버가 호환되는 알고리즘을 매칭하는 과정에서 메모리 할당
3. 특정 에러 경로에서 이미 해제된 메모리를 다시 해제(double-free)
4. 이는 인증 전 단계에서 발생하므로 자격 증명 없이 트리거 가능

### 코드 레벨 분석

```c
// 문제의 코드 경로 (단순화)
char *proposal = kex_alg_list(';');
// ... 매칭 실패 시 ...
free(proposal);  // 첫 번째 해제
// ... 에러 핸들링 경로 ...
free(proposal);  // 두 번째 해제 — double-free!
```

### 핵심 문제

- **에러 핸들링 경로의 메모리 관리 결함**: 정상 경로와 에러 경로에서 동일 포인터 해제
- **privsep이 영향 제한**: 취약 코드가 권한 분리된 자식 프로세스에서 실행됨
- **힙 레이아웃 조작 난이도**: double-free를 RCE로 전환하려면 정밀한 힙 조작 필요

### 왜 RCE가 어려운가

1. **권한 분리(privsep)**: 취약한 코드는 sandbox된 unprivileged 프로세스에서 실행
2. **ASLR**: 힙/스택 주소 랜덤화로 안정적 익스플로잇 어려움
3. **힙 보호**: glibc의 tcache/fastbin 보호 메커니즘
4. **제한된 제어**: double-free만으로는 임의 쓰기까지의 경로가 복잡

## 공격 시나리오

### DoS 공격

1. **대상 식별**: OpenSSH 9.1을 실행하는 서버 버전 확인
2. **KEX_INIT 조작**: 특수 구성된 알고리즘 목록으로 SSH 핸드셰이크 시도
3. **에러 경로 유도**: 서버가 double-free를 수행하여 crash

```python
# DoS 개념 시연 (교육 목적)
import socket

def trigger_double_free(target, port=22):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((target, port))
    banner = s.recv(256)
    # 조작된 KEX_INIT 패킷 전송
    # (실제 페이로드는 SSH 프로토콜 구조에 맞춰 정교하게 구성)
    crafted_kex_init = build_malicious_kex_init()
    s.send(crafted_kex_init)
    s.close()
```

### 잠재적 RCE 경로
- double-free → 힙 메타데이터 조작 → 임의 쓰기 → 코드 실행
- 현실적으로는 수천 회 시도 + 특정 힙 상태 필요

## 방어 방법

### 즉시 조치
1. **OpenSSH 9.2 이상으로 업그레이드**
2. 업그레이드 불가 시 SSH 접근을 제한된 IP에서만 허용

### 장기 대책
- SSH 서비스를 Bastion Host 뒤에 배치
- 네트워크 레벨 접근 제어 (Security Group, iptables)
- SSH 버전을 최신으로 유지하는 자동 패치 정책
- sshd crash 모니터링 알림 설정

```bash
# sshd crash 감지
journalctl -u sshd --since "1 hour ago" | grep -i "segfault\|double free\|crash"
```

### 추가 강화
- `MaxStartups` 설정으로 동시 미인증 연결 제한:
```
# /etc/ssh/sshd_config
MaxStartups 10:30:60
```

## 교훈

1. **권한 분리의 가치**: privsep 아키텍처가 메모리 취약점의 영향을 크게 제한
2. **메모리 안전 언어의 필요성**: C로 작성된 보안 소프트웨어의 근본적 한계
3. **에러 핸들링 코드의 위험**: 정상 경로보다 에러 경로에서 취약점이 더 많이 발생
4. **단일 버전 취약점도 중요**: 영향 범위가 좁아도 pre-auth 취약점은 심각
5. **방어 심층화**: 코드 결함이 있더라도 아키텍처 수준 방어가 피해를 제한

## 참고 자료

- [NVD - CVE-2023-25136](https://nvd.nist.gov/vuln/detail/CVE-2023-25136)
- [OpenSSH 9.2 릴리스 노트](https://www.openssh.com/txt/release-9.2)
- [JFrog 기술 분석](https://jfrog.com/blog/openssh-pre-auth-double-free-cve-2023-25136-writeup-and-proof-of-concept/)
- [OpenSSH Git Commit](https://github.com/openssh/openssh-portable/commit/5c46e78)
