# CVE-2023-32233 - Linux Kernel Netfilter nf_tables UAF

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2023-32233 |
| CVSS | 7.8 (High) |
| 영향 소프트웨어 | Linux Kernel (Netfilter nf_tables) |
| 영향 버전 | Linux Kernel 3.18 ~ 6.3.1 |
| 수정 버전 | 6.3.2, 6.2.16, 6.1.29, 5.15.113, 5.10.180, 5.4.243, 4.19.283 |
| 공격 유형 | Local Privilege Escalation (LPE) |
| 발견일 | 2023-05-08 |

## 영향 범위 & 심각성

Linux 커널의 Netfilter 서브시스템은 방화벽, NAT, 패킷 필터링의 핵심으로, 거의 모든 Linux 시스템에 영향을 미쳤다.

- **로컬 권한 상승**: 일반 사용자(unprivileged)가 root 권한 획득 가능
- **컨테이너 탈출**: 컨테이너 내부에서 호스트 커널 공격으로 탈출 가능
- 모든 주요 Linux 배포판(Ubuntu, Debian, RHEL, CentOS, Fedora) 영향
- 클라우드 환경의 공유 커널에서 테넌트 간 격리 위반 가능
- 10년 이상 된 커널(3.18~)부터 존재하여 레거시 시스템도 취약
- 공개 PoC 익스플로잇이 빠르게 공개되어 실제 악용 위험 높음

## 취약점 기술 분석

### 근본 원인

nf_tables의 익명(anonymous) set 처리에서 **use-after-free** 취약점이 발생한다. 배치(batch) 요청 처리 시 set을 추가하고 삭제하는 과정에서 참조 카운팅 오류가 발생한다.

```c
// 문제의 핵심: nf_tables batch 처리
// 1. 배치에서 익명 set을 바인딩하는 규칙 추가
// 2. 같은 배치에서 해당 규칙 삭제
// 3. set의 참조 카운터가 올바르게 감소하지 않아 해제 후에도 접근 가능

// 커널 내부 (간략화)
struct nft_set *set = nft_set_lookup(...);
// set이 이미 해제된 메모리를 가리킬 수 있음 (UAF)
nft_set_elem_init(set, ...);  // 해제된 메모리에 쓰기 → 커널 힙 손상
```

### 익스플로잇 메커니즘

1. Netfilter의 batch API를 통해 UAF 조건 생성
2. 해제된 메모리 영역을 커널 힙 스프레이로 재점유
3. 조작된 커널 객체를 통해 임의 읽기/쓰기 원시(primitive) 획득
4. `modprobe_path` 또는 `cred` 구조체 덮어쓰기로 root 권한 획득

## 공격 시나리오

```c
// 익스플로잇 개념 (교육 목적 의사코드)
// CAP_NET_ADMIN이 필요하지만, user namespace를 통해 unprivileged에서도 가능

// 1. User namespace 생성 (unprivileged)
unshare(CLONE_NEWUSER | CLONE_NEWNET);

// 2. nftables 배치 요청 구성
struct nftnl_batch *batch = nftnl_batch_alloc();
// 규칙 + 익명 set 추가
nftnl_batch_add(batch, NFT_MSG_NEWRULE, rule_with_set);
// 같은 배치에서 규칙 삭제 → set의 UAF 트리거
nftnl_batch_add(batch, NFT_MSG_DELRULE, same_rule);

// 3. 커널 힙 스프레이 (해제된 set 메모리 재점유)
spray_kernel_objects();

// 4. UAF를 통해 커널 메모리 조작 → root 획득
overwrite_modprobe_path("/tmp/pwn");
trigger_modprobe();  // root로 /tmp/pwn 실행됨
```

```
실제 공격 흐름:
1단계: 일반 사용자로 로그인 (또는 컨테이너 내부)
2단계: User namespace 생성으로 CAP_NET_ADMIN 획득
3단계: nftables batch API로 UAF 트리거
4단계: 커널 힙 스프레이로 해제된 메모리 제어
5단계: 커널 임의 쓰기로 root 권한 획득
6단계: 컨테이너인 경우 호스트 파일시스템 접근으로 탈출
```

## 방어 방법

1. **커널 업데이트**: 수정된 커널 버전으로 즉시 업데이트
2. **User Namespace 제한**: unprivileged user namespace 비활성화
   ```bash
   sysctl -w kernel.unprivileged_userns_clone=0
   ```
3. **nf_tables 모듈 비활성화** (가능한 경우):
   ```bash
   echo "install nf_tables /bin/false" >> /etc/modprobe.d/disable-nftables.conf
   ```
4. **Seccomp 프로파일**: 컨테이너에서 nftables 관련 syscall 차단
5. **커널 보안 강화**: KASLR, SMEP, SMAP, CONFIG_SLAB_FREELIST_HARDENED 활성화
6. **컨테이너 런타임 보안**: gVisor, Kata Containers 등 커널 격리 솔루션 검토

## 교훈

- **User Namespace는 공격 표면 확대**: unprivileged 사용자도 커널 기능에 접근 가능
- **복잡한 배치 처리의 위험**: 트랜잭셔널 API에서 참조 카운팅 오류는 UAF로 직결
- **컨테이너 ≠ 보안 경계**: 커널 취약점 앞에서 컨테이너 격리는 무력화됨
- **커널 보안의 중요성**: 모든 사용자/컨테이너가 공유하는 커널은 최우선 패치 대상
- **LTS 커널 사용 권장**: 보안 패치가 꾸준히 백포트되는 LTS 커널 사용

## 참고 자료

- [NVD - CVE-2023-32233](https://nvd.nist.gov/vuln/detail/CVE-2023-32233)
- [Linux Kernel Git Commit (수정)](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=c1592a89942e9678f7d9c8030efa777c0d57edab)
- [PoC Exploit - GitHub](https://github.com/Liuk3r/CVE-2023-32233)
- [Openwall OSS-Security](https://www.openwall.com/lists/oss-security/2023/05/08/4)
- [Ubuntu Security Notice](https://ubuntu.com/security/CVE-2023-32233)
