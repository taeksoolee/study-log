# CVE-2024-3094 - xz-utils Backdoor (공급망 공격)

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2024-3094 |
| CVSS | 10.0 (Critical) |
| 영향 소프트웨어 | xz-utils (liblzma) |
| 영향 버전 | 5.6.0, 5.6.1 |
| 수정 버전 | 5.6.1+git (5.6.0/5.6.1 완전 제거 후 이전 버전으로 다운그레이드) |
| 공격 유형 | 공급망 공격 → SSH 인증 우회 → RCE |
| 발견일 | 2024-03-29 |

## 영향 범위 & 심각성

역대 가장 정교한 오픈소스 공급망 공격으로, 거의 모든 Linux 배포판의 SSH 인프라를 장악할 뻔한 사건이다.

- **발견**: Microsoft 엔지니어 Andres Freund가 SSH 로그인 0.5초 지연을 이상하게 여겨 발견
- 백도어가 안정 배포판(Debian stable, Fedora 등)에 포함되었으면 인터넷 SSH 서버 대부분 장악 가능
- 실제로 Fedora 40/Rawhide, Debian testing/unstable에 잠시 포함됨
- 공격자 "Jia Tan"이 **2년 이상** 프로젝트에 기여하며 신뢰를 쌓은 후 백도어 삽입
- 리눅스 서버 인프라 전체의 SSH 인증을 우회할 수 있는 최악의 시나리오

## 취약점 기술 분석

### 근본 원인

xz-utils의 빌드 시스템에 악성 코드가 삽입되었다. 소스 코드 자체가 아닌 **배포용 tarball의 빌드 스크립트**에 숨겨진 형태였다.

```bash
# 악성 빌드 스크립트 체인 (간략화)
# 1. tests/files/ 디렉토리의 바이너리 테스트 파일에 암호화된 백도어 페이로드 숨김
# 2. m4/build-to-host.m4 스크립트가 빌드 시 페이로드 추출
# 3. 추출된 코드가 liblzma에 링크되는 공유 라이브러리로 컴파일
# 4. systemd를 통해 sshd가 liblzma를 로드 → 백도어 활성화
```

### 백도어 메커니즘

1. `liblzma.so`에 악성 코드가 포함되어 빌드됨
2. systemd 기반 Linux에서 `sshd`가 `libsystemd` → `liblzma` 경로로 간접 로드
3. 백도어가 `RSA_public_decrypt` 함수를 후킹(IFUNC resolver)
4. 특정 공개키로 서명된 SSH 인증 요청을 감지하면 인증을 우회하고 명령 실행
5. 공격자의 개인키를 가진 자만이 백도어 활성화 가능 (일반 스캔으로 탐지 불가)

## 공격 시나리오

```
사전 준비 (2년간):
- 공격자가 xz-utils 프로젝트에 정상적인 기여 시작
- 기존 메인테이너에 대한 사회공학적 압박 (번아웃 유도)
- 공동 메인테이너 권한 획득

공격 실행:
1단계: 테스트 바이너리 파일에 암호화된 백도어 페이로드 숨김
2단계: 빌드 시스템(m4 매크로)에 페이로드 추출 로직 삽입
3단계: xz 5.6.0/5.6.1 tarball 릴리스
4단계: Linux 배포판들이 새 버전을 패키징
5단계: 사용자가 업데이트 → sshd에 백도어가 로드됨
6단계: 공격자가 특수 SSH 키로 인증 없이 root 접근

(실제로는 5단계에서 발견되어 6단계 대규모 악용은 미수에 그침)
```

## 방어 방법

1. **즉시 다운그레이드**: xz-utils 5.4.x 이하로 롤백
2. **영향 확인**: `xz --version`으로 5.6.0/5.6.1 사용 여부 확인
3. **재현 가능 빌드(Reproducible Build)**: tarball과 git 소스 차이 검증
4. **SBOM & 의존성 감사**: 모든 시스템 라이브러리의 버전 추적
5. **다중 메인테이너 정책**: 중요 프로젝트에 단일 메인테이너 방지
6. **서명 검증**: 릴리스의 GPG 서명과 메인테이너 신원 교차 확인
7. **SSH 모니터링**: SSH 인증 실패/성공 로그 이상 패턴 감시

## 교훈

- **오픈소스 공급망의 취약성**: 핵심 인프라가 소수 자원봉사자에 의존하는 구조적 문제
- **신뢰는 점진적으로 구축, 순간적으로 악용**: 2년간 정상 기여 후 백도어 삽입
- **빌드 시스템도 감사 대상**: 소스 코드만 리뷰해서는 빌드 스크립트의 악성 코드를 발견 불가
- **tarball ≠ git 소스**: 릴리스 tarball에만 존재하는 코드가 있을 수 있음
- **우연한 발견의 행운**: 0.5초 성능 저하를 파고든 엔지니어의 호기심이 재앙을 막음
- **오픈소스 펀딩과 지속가능성**: 핵심 유틸리티의 메인테이너 번아웃 문제 해결 필요

## 참고 자료

- [Openwall - Original Disclosure](https://www.openwall.com/lists/oss-security/2024/03/29/4)
- [NVD - CVE-2024-3094](https://nvd.nist.gov/vuln/detail/CVE-2024-3094)
- [CISA Alert](https://www.cisa.gov/news-events/alerts/2024/03/29/reported-supply-chain-compromise-affecting-xz-utils-data-compression-library)
- [Ars Technica - Timeline](https://arstechnica.com/security/2024/04/what-we-know-about-the-xz-utils-backdoor-that-almost-infected-the-world/)
- [GitHub - xz backdoor analysis](https://gist.github.com/thesamesam/223949d5a074ebc3dce9ee78baad9e27)
