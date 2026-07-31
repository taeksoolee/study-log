# CVE-2024-28849 - follow-redirects Private Data Exposure

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2024-28849 |
| CVSS | 6.5 (Medium) |
| 영향 패키지 | follow-redirects |
| 영향 버전 | < 1.15.6 |
| 수정 버전 | 1.15.6 |
| 공격 유형 | Information Disclosure (Authorization Header Leak) |
| 발견일 | 2024-03-14 |

## 왜 프론트엔드 개발자가 알아야 하는가

`follow-redirects`는 **axios의 핵심 의존성**이다. axios를 사용하는 모든 Node.js 애플리케이션이 간접적으로 영향을 받는다:

- Next.js API Routes에서 axios로 외부 API 호출
- BFF(Backend For Frontend)에서의 API 프록시
- SSR에서 데이터 페칭
- CI/CD 스크립트에서의 HTTP 요청

이 취약점은 HTTP 리다이렉트가 cross-origin으로 발생할 때, `Authorization` 헤더를 리다이렉트 대상에 그대로 전송하여 인증 토큰이 제3자에게 노출된다.

## 취약점 기술 분석

HTTP 리다이렉트(301, 302, 307, 308) 시, 보안 모범 사례는 다른 origin으로 리다이렉트될 때 민감한 헤더(`Authorization`, `Cookie` 등)를 제거하는 것이다.

`follow-redirects`는 이 처리가 불완전했다:

```javascript
// follow-redirects 내부 동작 (단순화)
// 리다이렉트 시 Authorization 헤더 처리 로직의 결함

// 원래 요청: https://api.service.com/data
//   → Authorization: Bearer eyJhbGci...
// 리다이렉트 응답: 302 → https://attacker-controlled.com/
//   → Authorization 헤더가 그대로 전송됨!
```

특히 호스트명은 다르지만 `username:password` 형식의 URL이나 특정 조건에서 헤더 제거 로직이 우회되는 문제였다.

## 공격 시나리오

```javascript
const axios = require('axios');

// 프론트엔드 BFF: 외부 API에 인증된 요청을 보냄
async function fetchExternalData(token) {
  const response = await axios.get('https://api.trusted-service.com/data', {
    headers: {
      Authorization: `Bearer ${token}`
    },
    // follow-redirects가 자동으로 리다이렉트 처리
  });
  return response.data;
}

// 공격 시나리오:
// 1. 공격자가 trusted-service.com의 특정 엔드포인트를 제어
//    (또는 DNS 하이재킹, 중간자 공격)
// 2. 302 리다이렉트 응답을 attacker.com으로 반환
// 3. follow-redirects가 Authorization 헤더를 포함하여 attacker.com에 요청
// 4. 공격자가 Bearer 토큰 탈취

// 공격자 서버
// app.get('/collect', (req, res) => {
//   const stolen = req.headers.authorization;
//   // Bearer eyJhbGci... 토큰 수집!
// });
```

## 방어 방법

### 즉시 조치
```bash
npm install follow-redirects@1.15.6
# axios 사용 시 간접 업데이트
npm update follow-redirects
npm ls follow-redirects  # 버전 확인
```

### 코드 레벨 방어
```javascript
// ✅ axios에서 리다이렉트 수동 제어
const axios = require('axios');

const response = await axios.get(url, {
  headers: { Authorization: `Bearer ${token}` },
  maxRedirects: 0, // 자동 리다이렉트 비활성화
  validateStatus: (status) => status < 400,
});

// 리다이렉트 응답을 직접 처리
if (response.status === 302) {
  const redirectUrl = new URL(response.headers.location);
  const originalUrl = new URL(url);
  
  // cross-origin 리다이렉트 시 Authorization 제거
  const headers = redirectUrl.origin === originalUrl.origin
    ? { Authorization: `Bearer ${token}` }
    : {}; // 다른 origin이면 인증 헤더 제거
    
  return axios.get(redirectUrl.href, { headers });
}
```

### 장기 전략
- 민감한 요청에서는 자동 리다이렉트를 비활성화하고 수동 처리
- API 클라이언트에 리다이렉트 정책을 명시적으로 설정
- 네트워크 레벨에서 예상치 못한 리다이렉트 모니터링

## 교훈 & 프론트엔드 적용 포인트

1. **리다이렉트는 보안 경계를 넘을 수 있다**: 자동 리다이렉트가 편리하지만, 민감한 데이터가 의도치 않은 목적지로 전달될 수 있다.
2. **간접 의존성도 보안 위협이다**: axios를 안전하게 사용해도, 하위 의존성의 결함이 영향을 미친다.
3. **인증 토큰은 최소 범위로 전송하라**: 리다이렉트 시 인증 정보가 어디로 가는지 항상 인지해야 한다.
4. **`npm ls`로 간접 의존성을 확인하라**: 직접 설치하지 않은 패키지도 프로젝트의 보안에 영향을 미친다.

## 참고 자료

- [NVD - CVE-2024-28849](https://nvd.nist.gov/vuln/detail/CVE-2024-28849)
- [GitHub Advisory - GHSA-cxjh-pqwp-8mfp](https://github.com/advisories/GHSA-cxjh-pqwp-8mfp)
- [follow-redirects npm](https://www.npmjs.com/package/follow-redirects)
- [Fetch Standard - HTTP Redirect handling](https://fetch.spec.whatwg.org/#http-redirect-fetch)
