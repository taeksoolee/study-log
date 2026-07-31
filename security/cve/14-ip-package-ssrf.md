# CVE-2023-42282 - ip Package SSRF

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2023-42282 |
| CVSS | 9.8 (Critical) |
| 영향 패키지 | ip |
| 영향 버전 | ≤ 2.0.0 |
| 수정 버전 | 2.0.1 |
| 공격 유형 | SSRF (Server-Side Request Forgery) |
| 발견일 | 2024-02-08 |

## 왜 프론트엔드 개발자가 알아야 하는가

`ip` 패키지는 npm에서 주간 1,700만+ 다운로드를 기록하는 IP 주소 유틸리티다. Node.js 생태계에서 광범위하게 사용된다:

- Express/Koa 미들웨어에서 프라이빗 네트워크 접근 제어
- SSRF 방어를 위한 내부 IP 필터링
- Rate limiting에서의 IP 분류
- Webpack DevServer, Create React App 등 개발 도구에서도 간접 의존

`isPrivate()` 함수가 특정 IP 형식을 올바르게 판별하지 못해, SSRF 방어 로직을 완전히 무력화할 수 있다.

## 취약점 기술 분석

`ip.isPrivate()` 함수는 IPv4 주소를 10진수 옥텟 형식(`127.0.0.1`)으로만 검사한다. 그러나 IPv4 주소는 여러 형식으로 표현 가능하다:

- 10진수: `127.0.0.1`
- 8진수: `0177.0000.0000.0001`
- 16진수: `0x7f.0x00.0x00.0x01`
- 정수: `2130706433`

```javascript
const ip = require('ip'); // ≤ 2.0.0

// 정상 동작
ip.isPrivate('127.0.0.1');    // true ✓
ip.isPrivate('10.0.0.1');     // true ✓

// 취약점: 대체 표기법을 인식하지 못함
ip.isPrivate('0x7f.0x00.0x00.0x01');  // false ✗ (실제로는 127.0.0.1!)
ip.isPrivate('0177.0.0.1');            // false ✗ (실제로는 127.0.0.1!)
```

## 공격 시나리오

```javascript
const ip = require('ip');
const axios = require('axios');

// SSRF 방어 미들웨어 (취약)
async function fetchUrl(targetUrl) {
  const { hostname } = new URL(targetUrl);

  if (ip.isPrivate(hostname)) {
    throw new Error('내부 네트워크 접근 차단');
  }

  return axios.get(targetUrl);
}

// 공격: 8진수 표기로 내부 서비스 접근
// 0177.0.0.1 === 127.0.0.1
fetchUrl('http://0177.0.0.1:3000/admin/secrets');
// → isPrivate() 우회하여 localhost에 접근!

// AWS 메타데이터 접근 (169.254.169.254)
fetchUrl('http://0251.0376.0251.0376/latest/meta-data/iam/');
// → 클라우드 인스턴스 IAM 자격 증명 탈취
```

## 방어 방법

### 즉시 조치
```bash
npm install ip@2.0.1
# 또는 대안 라이브러리로 전환
npm install ipaddr.js
```

### 코드 레벨 방어
```javascript
const ipaddr = require('ipaddr.js');
const dns = require('dns').promises;

async function preventSSRF(targetUrl) {
  const { hostname } = new URL(targetUrl);

  // DNS 해석 후 실제 IP로 검증
  const addresses = await dns.resolve4(hostname);

  for (const addr of addresses) {
    const parsed = ipaddr.parse(addr);
    const range = parsed.range();
    const blocked = ['private', 'loopback', 'linkLocal', 'uniqueLocal'];
    if (blocked.includes(range)) {
      throw new Error(`내부 네트워크 접근 차단: ${addr}`);
    }
  }

  return fetch(targetUrl);
}
```

### 장기 전략
- DNS Rebinding 방어: DNS 해석 결과를 고정하고, 연결 시 IP 재검증
- 네트워크 레벨: 아웃바운드 트래픽을 프록시를 통해 필터링
- 모든 IP 입력을 정규화(canonical) 형식으로 변환 후 검증

## 교훈 & 프론트엔드 적용 포인트

1. **IP 주소는 단순 문자열이 아니다**: 여러 표기법으로 같은 주소를 나타낼 수 있으며, 정규화가 필수다.
2. **방어 로직의 완전성을 검증하라**: "이 함수가 안전하겠지"라는 가정은 위험하다.
3. **다운로드 수 ≠ 보안 품질**: 인기 있는 패키지도 기본적인 보안 결함을 가질 수 있다.
4. **SSRF는 클라우드 환경에서 치명적이다**: AWS/GCP 메타데이터 서비스 접근으로 인프라 전체가 위험해진다.

## 참고 자료

- [NVD - CVE-2023-42282](https://nvd.nist.gov/vuln/detail/CVE-2023-42282)
- [GitHub Advisory - GHSA-78xj-cgh5-2h22](https://github.com/advisories/GHSA-78xj-cgh5-2h22)
- [ip npm package](https://www.npmjs.com/package/ip)
- [ipaddr.js - 안전한 대안](https://www.npmjs.com/package/ipaddr.js)
