# CVE-2023-26159 - follow-redirects SSRF

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2023-26159 |
| CVSS | 7.4 (High) |
| 영향 패키지 | follow-redirects |
| 영향 버전 | < 1.15.4 |
| 수정 버전 | 1.15.4 |
| 공격 유형 | Server-Side Request Forgery (SSRF) |
| 발견일 | 2024-01-02 |

## 왜 프론트엔드 개발자가 알아야 하는가

follow-redirects는 HTTP 리다이렉트를 자동으로 따라가는 패키지로, 매우 핵심적인 위치에 있다:

1. **axios**: Node.js 환경에서 HTTP 요청 시 내부적으로 follow-redirects 사용
2. **Next.js API Routes**: axios를 사용하는 서버사이드 코드
3. **BFF(Backend For Frontend)**: Node.js 서버에서 외부 API 호출 시
4. **SSR 데이터 페칭**: getServerSideProps, 서버 컴포넌트에서의 API 호출
5. **Node.js 기반 프록시**: 프론트엔드 개발 서버의 프록시 설정

npm 주간 다운로드 1억+ 건. axios만으로도 프론트엔드 프로젝트 대부분이 간접 영향을 받는다.

## 취약점 기술 분석

follow-redirects가 리다이렉트 URL을 파싱할 때 URL의 호스트명 추출에 결함이 있다. 공격자가 특수하게 조작된 URL로 리다이렉트시키면, 라이브러리가 원래 의도한 호스트 대신 내부 네트워크의 다른 호스트에 요청을 보내게 된다.

```javascript
// 취약점의 핵심 - URL 파싱 불일치
// follow-redirects가 사용하는 url.parse()와 실제 HTTP 요청의 해석 차이

const url = require('url');

// 악성 URL 예시
const maliciousURL = 'http://attacker.com%40internal-server.local/';

// url.parse()의 해석:
// host: 'attacker.com%40internal-server.local'
// → attacker.com으로의 요청이라고 판단

// 실제 HTTP 요청 시:
// %40 → @ 디코딩
// → user: attacker.com, host: internal-server.local
// → internal-server.local로 요청 발생!

// 또 다른 패턴
const bypass = 'http://attacker.com///internal-api:8080/admin';
// 파서에 따라 host 추출이 다르게 동작
```

핵심 원인:
- `url.parse()`(레거시)와 `new URL()`(WHATWG)의 파싱 차이
- URL 인코딩/디코딩 시점의 불일치
- 호스트명 검증 이후 실제 요청까지의 갭(gap)
- 리다이렉트 체인에서 호스트 변경 검증 우회

## 공격 시나리오

```javascript
// 시나리오 1: axios를 사용하는 BFF에서의 SSRF

// 프론트엔드에서 URL을 받아 서버에서 메타데이터를 가져오는 기능
// (링크 프리뷰, OG 태그 파싱 등)
app.post('/api/link-preview', async (req, res) => {
  const { url } = req.body;
  
  // URL 검증 (우회 가능!)
  if (isExternalURL(url)) {
    // axios 내부에서 follow-redirects 사용
    const response = await axios.get(url);
    // 파싱하여 메타데이터 반환
    res.json(extractMeta(response.data));
  }
});

// 공격자의 요청
// POST /api/link-preview
// { "url": "http://attacker.com/redirect" }
// 
// attacker.com이 리다이렉트 응답:
// Location: http://attacker.com%40169.254.169.254/latest/meta-data/
// 
// follow-redirects가 이를 따라가면:
// → AWS 메타데이터 서비스에 접근
// → IAM 자격증명 탈취 가능!

// 시나리오 2: 이미지 프록시
app.get('/api/image-proxy', async (req, res) => {
  const imageURL = req.query.src;
  // SSRF를 통해 내부 서비스에 접근 가능
  const image = await axios.get(imageURL, { responseType: 'stream' });
  image.data.pipe(res);
});
```

## 방어 방법

### 즉각 조치
```bash
npm ls follow-redirects
npm install follow-redirects@^1.15.4
npm audit fix

# axios를 사용하는 경우
npm ls axios  # axios가 어떤 follow-redirects를 사용하는지 확인
```

```json
{
  "overrides": {
    "follow-redirects": ">=1.15.4"
  }
}
```

### 코드 레벨 방어
```javascript
// SSRF 방어: 서버에서 외부 URL 요청 시
const { URL } = require('url');
const dns = require('dns').promises;

async function safeFetch(inputURL) {
  const parsed = new URL(inputURL);
  
  // 1. 프로토콜 제한
  if (!['http:', 'https:'].includes(parsed.protocol)) {
    throw new Error('Invalid protocol');
  }
  
  // 2. 내부 IP 차단
  const addresses = await dns.resolve(parsed.hostname);
  for (const addr of addresses) {
    if (isPrivateIP(addr)) {
      throw new Error('Internal IP not allowed');
    }
  }
  
  // 3. 리다이렉트 비활성화 또는 제한
  const response = await axios.get(inputURL, {
    maxRedirects: 0, // 리다이렉트 비허용
    // 또는 커스텀 검증
    beforeRedirect: (options) => {
      const redirectURL = new URL(options.href);
      if (isPrivateHost(redirectURL.hostname)) {
        throw new Error('Redirect to internal host blocked');
      }
    }
  });
  
  return response;
}

function isPrivateIP(ip) {
  return /^(10\.|172\.(1[6-9]|2\d|3[01])\.|192\.168\.|127\.|169\.254\.)/.test(ip);
}
```

### 장기 전략
- 외부 URL을 요청하는 서비스를 별도 네트워크 세그먼트에 격리
- 아웃바운드 프록시를 통해 내부 네트워크 접근 차단
- AWS IMDSv2 사용 (토큰 필요하므로 SSRF로 접근 어려움)
- URL 검증 로직을 요청 직전에 수행 (TOCTOU 방지)

## 교훈 & 프론트엔드 적용 포인트

1. **링크 프리뷰 = SSRF 위험**: OG 태그 파싱, 이미지 프록시 등은 SSRF의 대표적 벡터
2. **URL 파싱의 복잡성**: 파서마다 해석이 다르며, 이 차이가 보안 우회로 이어짐
3. **리다이렉트는 위험**: 리다이렉트를 따라가면 최초 검증을 우회할 수 있음
4. **클라우드 메타데이터**: SSRF + 클라우드 환경 = 자격증명 탈취 (169.254.169.254)
5. **axios의 기본 동작 이해**: maxRedirects 기본값이 5로, 자동으로 리다이렉트를 따라감

## 참고 자료

- [NVD - CVE-2023-26159](https://nvd.nist.gov/vuln/detail/CVE-2023-26159)
- [GitHub Advisory GHSA-jchw-25xp-jwwc](https://github.com/advisories/GHSA-jchw-25xp-jwwc)
- [follow-redirects GitHub](https://github.com/follow-redirects/follow-redirects)
- [Snyk Advisory](https://security.snyk.io/vuln/SNYK-JS-FOLLOWREDIRECTS-6141137)
