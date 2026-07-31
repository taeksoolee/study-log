# CVE-2023-38545 - curl SOCKS5 Heap Overflow

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2023-38545 |
| CVSS | 9.8 (Critical, 일부 평가 7.5 High) |
| 영향 소프트웨어 | curl / libcurl |
| 영향 버전 | 7.69.0 ~ 8.3.0 |
| 수정 버전 | 8.4.0 |
| 공격 유형 | Heap Buffer Overflow → RCE |
| 발견일 | 2023-10-11 |

## 영향 범위 & 심각성

curl은 사실상 모든 운영체제, 컨테이너, IoT 장치에 설치된 HTTP 클라이언트다. libcurl은 수천 개의 소프트웨어에 링크되어 있다.

**실제 영향:**
- curl 창시자 Daniel Stenberg가 "오랜 시간 동안 가장 심각한 curl 취약점"으로 규정
- 모든 주요 Linux 배포판, macOS, Windows, Docker 이미지에 영향
- SOCKS5 프록시를 사용하는 모든 환경에서 잠재적으로 악용 가능
- CI/CD 파이프라인, 빌드 시스템, 마이크로서비스 간 통신에서 광범위하게 사용
- 실제 대규모 악용 보고는 제한적 (SOCKS5 프록시 사용 조건 필요)

## 취약점 기술 분석

### 근본 원인

curl이 SOCKS5 프록시를 통해 호스트명을 해석할 때, 호스트명 길이가 로컬 버퍼를 초과하면 힙 오버플로우가 발생한다.

**메커니즘:**
1. SOCKS5h 프로토콜은 호스트명 해석을 프록시에 위임
2. curl이 "느린 SOCKS5 핸드셰이크" 모드로 전환될 때 호스트명을 힙 버퍼에 복사
3. 호스트명이 255바이트를 초과하면 원래 로컬 해석으로 폴백
4. 그러나 폴백 과정에서 이미 긴 호스트명이 작은 힙 버퍼에 복사됨

### 코드 레벨 분석

```c
// 문제의 로직 (단순화)
if(hostname_len > 255) {
    // 프록시에서 해석 불가 → 로컬 해석으로 폴백
    // 그러나 이미 할당된 작은 버퍼에 긴 호스트명을 복사!
    memcpy(socks->buffer, hostname, hostname_len);  // OVERFLOW!
}
```

### 핵심 문제

- **버퍼 크기 검증 누락**: SOCKS5 프로토콜의 255바이트 호스트명 제한과 내부 버퍼 크기 불일치
- **상태 머신 전환 시 크기 검증**: 느린 핸드셰이크 모드 전환 시 버퍼 크기 재검증 미수행
- **폴백 로직의 위험**: 프록시 해석 실패 시 로컬 해석으로 넘어가는 과정에서 오버플로우

## 공격 시나리오

### 공격 조건

- 피해자가 SOCKS5 프록시(socks5h://)를 사용해야 함
- 공격자가 리다이렉트 등을 통해 긴 호스트명으로 요청을 유도할 수 있어야 함

### 단계별 공격

1. **환경 확인**: 대상이 SOCKS5 프록시를 통해 외부 요청을 하는지 확인
2. **악성 리다이렉트**: HTTP 302 응답으로 256바이트 이상의 호스트명을 가진 URL로 리다이렉트
3. **힙 오버플로우 트리거**: curl이 SOCKS5 핸드셰이크 중 힙 버퍼 오버플로우 발생
4. **코드 실행**: 오버플로우된 데이터로 프로그램 제어 흐름 탈취

```
# 악성 리다이렉트 서버 (교육 목적)
HTTP/1.1 302 Found
Location: http://AAAA...AAAA(256+ chars).evil.com/payload
```

### 영향 범위 제한 요소
- SOCKS5h 프록시 사용이 전제 조건
- 일반적인 HTTP/HTTPS 프록시에서는 트리거되지 않음

## 방어 방법

### 즉시 조치
1. **curl 8.4.0 이상으로 업그레이드**
2. OS 패키지 매니저를 통한 긴급 업데이트:
```bash
# Debian/Ubuntu
sudo apt update && sudo apt upgrade curl libcurl4

# RHEL/CentOS
sudo yum update curl libcurl

# macOS
brew upgrade curl
```

### 장기 대책
- SOCKS5 프록시 사용 환경의 curl 버전 일괄 점검
- 컨테이너 이미지의 curl 버전 확인 및 리빌드
- libcurl을 링크하는 자체 애플리케이션 재컴파일
- 프록시 환경 변수(ALL_PROXY, HTTPS_PROXY) 설정 감사

### 컨테이너 환경 점검
```bash
# Docker 이미지 내 curl 버전 확인
docker run --rm image:tag curl --version

# 취약 버전 포함 이미지 식별
trivy image --severity HIGH,CRITICAL image:tag | grep curl
```

## 교훈

1. **유비쿼터스 소프트웨어의 위험**: curl처럼 모든 곳에 존재하는 소프트웨어의 취약점은 영향 범위가 측정 불가
2. **프로토콜 경계값 처리**: SOCKS5의 255바이트 제한 같은 프로토콜 스펙과 구현 버퍼의 일관성 유지 필수
3. **상태 머신의 복잡성**: 비동기 핸드셰이크에서 상태 전환 시 불변 조건(invariant) 재검증 필요
4. **공급망 영향**: 하나의 라이브러리 취약점이 수천 개 다운스트림 프로젝트에 전파
5. **메모리 안전 언어 전환**: curl도 Rust/메모리 안전 백엔드 도입을 검토 중

## 참고 자료

- [NVD - CVE-2023-38545](https://nvd.nist.gov/vuln/detail/CVE-2023-38545)
- [curl 공식 블로그 - CVE-2023-38545](https://curl.se/blog/2023-10-11.html)
- [Daniel Stenberg 발표 영상](https://daniel.haxx.se/blog/2023/10/11/how-i-made-a-heap-overflow-in-curl/)
- [curl Advisory](https://curl.se/docs/CVE-2023-38545.html)
