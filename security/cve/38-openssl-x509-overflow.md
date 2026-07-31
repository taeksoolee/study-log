# CVE-2022-3602 - OpenSSL X.509 Buffer Overflow (Spooky SSL)

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2022-3602 |
| CVSS | 7.5 (High) |
| 영향 소프트웨어 | OpenSSL |
| 영향 버전 | 3.0.0 ~ 3.0.6 |
| 수정 버전 | 3.0.7 |
| 공격 유형 | Buffer Overflow → DoS / 잠재적 RCE |
| 발견일 | 2022-11-01 |

## 영향 범위 & 심각성

OpenSSL은 인터넷 TLS/SSL 통신의 기반이 되는 암호화 라이브러리다. 웹서버, 메일서버, VPN, IoT 장치 등 거의 모든 네트워크 소프트웨어가 의존한다.

**실제 영향:**
- 초기 "Critical"로 사전 공지 → 분석 후 "High"로 하향 (일명 "Spooky SSL", 할로윈 무렵 공개)
- OpenSSL 3.x 계열만 영향 (1.1.1 계열은 안전)
- Heartbleed(2014) 이후 최대 OpenSSL 보안 이슈로 주목받음
- 실제 RCE 달성은 대부분 플랫폼에서 스택 보호로 차단됨
- 서버/클라이언트 양측 모두 영향 가능 (인증서 검증 시 트리거)

## 취약점 기술 분석

### 근본 원인

X.509 인증서의 이메일 주소 필드에서 Punycode 디코딩 시 4바이트 스택 버퍼 오버플로우가 발생한다.

**메커니즘:**
1. X.509 인증서의 Name Constraint 검증 과정에서 이메일 주소를 Punycode 디코딩
2. `ossl_punycode_decode()` 함수가 디코딩된 문자열 길이를 잘못 계산
3. 스택에 할당된 고정 크기 버퍼를 최대 4바이트 초과 쓰기

### 코드 레벨 분석

```c
// 취약한 Punycode 디코딩 로직 (단순화)
unsigned int buf[MAX_LABEL_LENGTH];  // 스택 버퍼
// ... Punycode 디코딩 ...
// 길이 검증이 디코딩 후에 수행됨 — 이미 오버플로우 발생 후!
if(decoded_length > MAX_LABEL_LENGTH) {
    return error;  // 너무 늦음
}
```

### 왜 Critical에서 High로 하향되었나

1. **오버플로우 크기 제한**: 최대 4바이트만 초과 — 정밀한 제어 어려움
2. **스택 카나리(Stack Canary)**: 대부분의 현대 컴파일러가 스택 보호 삽입
3. **ASLR**: 주소 랜덤화로 안정적 익스플로잇 난이도 높음
4. **인증서 체인 검증 필요**: 신뢰할 수 있는 CA가 악성 인증서를 서명해야 함 (현실적으로 어려움)

### 관련 취약점

- **CVE-2022-3786**: 같은 코드의 다른 오버플로우 (`.` 문자로만 오버플로우 — DoS만 가능)

## 공격 시나리오

### 서버 공격 (클라이언트 인증서 검증 시)

1. 상호 TLS(mTLS) 환경에서 서버가 클라이언트 인증서를 검증
2. 악성 클라이언트가 Punycode 인코딩된 이메일 주소를 포함한 인증서 제출
3. 서버의 Name Constraint 검증 시 버퍼 오버플로우 트리거

### 클라이언트 공격 (서버 인증서 검증 시)

1. 악성 서버가 특수 조작된 인증서를 클라이언트에 제공
2. 클라이언트가 인증서 검증 시 오버플로우 발생
3. 단, 신뢰 체인이 유효해야 하므로 실질적 공격 난이도 높음

```
# 악성 인증서의 이메일 필드 예시 (교육 목적)
Subject Alternative Name:
  email: xn--[malicious punycode sequence]@example.com
```

### 현실적 영향
- 대부분의 환경에서 crash(DoS)로 그침
- 특정 임베디드 시스템(스택 보호 없음)에서는 RCE 가능성 존재

## 방어 방법

### 즉시 조치
1. **OpenSSL 3.0.7 이상으로 업그레이드**
2. OpenSSL 1.1.1 계열 사용 중이면 영향 없음 (별도 조치 불필요)

```bash
# 현재 OpenSSL 버전 확인
openssl version

# 시스템 내 OpenSSL 라이브러리 확인
find / -name "libssl.so*" -o -name "libcrypto.so*" 2>/dev/null
```

### 장기 대책
- 인증서 검증 설정에서 Name Constraint 처리 비활성화 (해당되는 경우)
- 컴파일 시 스택 보호(-fstack-protector-strong) 확인
- 의존성 라이브러리의 OpenSSL 버전 일괄 점검
- TLS 종단 장비(로드밸런서, 리버스 프록시)의 OpenSSL 버전 우선 패치

## 교훈

1. **Heartbleed의 교훈**: OpenSSL 취약점은 인터넷 전체에 영향 — 신속한 대응 체계 필수
2. **사전 공지의 양면성**: Critical로 예고했다가 High로 하향 → 보안 피로도 유발 가능
3. **현대 방어 기법의 효과**: 스택 카나리, ASLR 등이 버퍼 오버플로우의 실제 영향을 크게 줄임
4. **인코딩 처리의 위험**: Punycode, Unicode, URL 인코딩 등 변환 로직은 취약점의 온상
5. **라이브러리 버전 관리**: 시스템 전체에서 사용되는 암호화 라이브러리는 가장 먼저 패치

## 참고 자료

- [NVD - CVE-2022-3602](https://nvd.nist.gov/vuln/detail/CVE-2022-3602)
- [OpenSSL Security Advisory](https://www.openssl.org/news/secadv/20221101.txt)
- [DataDog 분석](https://securitylabs.datadoghq.com/articles/openssl-november-1-vulnerabilities/)
- [Cloudflare 블로그](https://blog.cloudflare.com/CVE-2022-3satisfying786-and-CVE-2022-3602/)
