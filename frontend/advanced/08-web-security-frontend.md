# 웹 보안 실전 (프론트엔드 관점)

> 이론이 아닌 실전 — 프론트엔드 개발자가 직접 설정하고 방어하는 구체적 패턴을 다룹니다.

---

## 개요

`browser/08-security.md`에서 XSS, CSRF, CORS의 **이론적 원리**를 다뤘다면, 이 문서에서는 프론트엔드 개발자가 **실제로 설정하고 방어하는 구체적 패턴**에 집중한다.

다루는 주제:
- CSP(Content Security Policy) 설계와 배포 전략
- Subresource Integrity(SRI)
- 3rd-party 스크립트 격리
- Supply Chain Attack 방어
- CORS 실전 트러블슈팅
- 보안 헤더 종합
- 실전 코드 예제 (Next.js 중심)

---

## Content Security Policy (CSP) 실전

### CSP란?

CSP는 HTTP 응답 헤더를 통해 **브라우저에게 "어떤 출처의 리소스를 로드해도 되는지"** 명시적으로 지시하는 보안 메커니즘이다.

```
Content-Security-Policy: default-src 'self'; script-src 'self' https://cdn.example.com;
```

**핵심 효과:**
- 인라인 스크립트 실행 차단 → XSS 공격의 영향을 크게 줄임
- 허용되지 않은 외부 리소스 로드 차단
- 공격자가 스크립트를 주입해도 실행 불가

### 디렉티브 종류

| 디렉티브 | 역할 | 예시 |
|----------|------|------|
| `default-src` | 다른 디렉티브가 없을 때 기본값 | `'self'` |
| `script-src` | JavaScript 소스 제한 | `'self' 'nonce-abc123'` |
| `style-src` | CSS 소스 제한 | `'self' 'unsafe-inline'` |
| `img-src` | 이미지 소스 제한 | `'self' data: https:` |
| `connect-src` | fetch/XHR/WebSocket 대상 제한 | `'self' https://api.example.com` |
| `font-src` | 폰트 파일 소스 제한 | `'self' https://fonts.gstatic.com` |
| `frame-src` | iframe 소스 제한 | `'none'` |
| `object-src` | Flash/Java 플러그인 (보통 차단) | `'none'` |
| `base-uri` | `<base>` 태그 제한 | `'self'` |
| `form-action` | form 제출 대상 제한 | `'self'` |

**소스 값:**

| 값 | 의미 |
|----|------|
| `'self'` | 현재 도메인 |
| `'none'` | 모든 소스 차단 |
| `'unsafe-inline'` | 인라인 스크립트/스타일 허용 (비권장) |
| `'unsafe-eval'` | eval() 허용 (비권장) |
| `'nonce-<value>'` | 특정 nonce 가진 요소만 허용 |
| `'sha256-<hash>'` | 특정 해시의 인라인 코드만 허용 |
| `'strict-dynamic'` | nonce 가진 스크립트가 로드한 것도 허용 |

### Nonce 기반 CSP (권장)

```
Content-Security-Policy: script-src 'nonce-abc123' 'strict-dynamic'; object-src 'none'; base-uri 'self';
```

**Nonce 방식의 장점:**
- 인라인 스크립트를 안전하게 허용 가능
- 화이트리스트 방식보다 우회가 어려움
- `strict-dynamic`과 조합하면 동적 로드도 안전하게 허용

**Next.js에서 nonce 설정:**

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // 매 요청마다 새 nonce 생성 (crypto-safe random)
  const nonce = Buffer.from(crypto.randomUUID()).toString('base64');
  
  const cspHeader = `
    default-src 'self';
    script-src 'self' 'nonce-${nonce}' 'strict-dynamic';
    style-src 'self' 'nonce-${nonce}';
    img-src 'self' blob: data:;
    font-src 'self';
    object-src 'none';
    base-uri 'self';
    form-action 'self';
    frame-ancestors 'none';
    upgrade-insecure-requests;
  `.replace(/\s{2,}/g, ' ').trim();

  const response = NextResponse.next();
  
  // 헤더에 nonce 전달 (서버 컴포넌트에서 사용)
  response.headers.set('x-nonce', nonce);
  response.headers.set('Content-Security-Policy', cspHeader);
  
  return response;
}
```

```tsx
// app/layout.tsx — nonce를 스크립트에 전달
import { headers } from 'next/headers';

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const headersList = await headers();
  const nonce = headersList.get('x-nonce') ?? '';

  return (
    <html lang="ko">
      <body>
        {children}
        <script nonce={nonce} src="/analytics.js" />
      </body>
    </html>
  );
}
```

**`strict-dynamic` 신뢰 체인:**
- nonce가 있는 스크립트가 동적으로 생성한 스크립트도 자동 허용
- CDN URL을 일일이 화이트리스트할 필요 없음
- 단, `document.write()`로 삽입한 스크립트는 차단

### CSP 배포 전략

프로덕션에 CSP를 바로 적용하면 기존 기능이 깨질 수 있다. 단계적으로 배포한다:

```
1단계: Report-Only 모드
────────────────────────
Content-Security-Policy-Report-Only: ...정책...; report-uri /csp-report;

→ 위반해도 차단하지 않음, 리포트만 수집

2단계: 위반 분석
────────────────
- 어떤 스크립트/스타일이 위반하는지 로그 확인
- 정당한 리소스 → 정책에 추가
- 불필요한 인라인 → nonce로 전환

3단계: 정책 강화
────────────────
- unsafe-inline 제거
- 허용 도메인 최소화

4단계: Enforce 모드 전환
────────────────────────
Content-Security-Policy: ...정책...;

→ 위반 시 실제 차단
```

**Report 엔드포인트 예시:**

```typescript
// pages/api/csp-report.ts (Next.js API Route)
import type { NextApiRequest, NextApiResponse } from 'next';

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method === 'POST') {
    const report = req.body['csp-report'] || req.body;
    console.warn('[CSP Violation]', {
      blockedUri: report['blocked-uri'],
      violatedDirective: report['violated-directive'],
      documentUri: report['document-uri'],
    });
    // → Sentry, Datadog 등으로 전송
  }
  res.status(204).end();
}
```

---

## Subresource Integrity (SRI)

CDN에서 로드하는 외부 리소스가 **변조되지 않았음을 검증**하는 메커니즘이다.

### 동작 원리

```html
<script 
  src="https://cdn.example.com/lib@3.0.0/lib.min.js"
  integrity="sha384-oqVuAfXRKap7fdgcCY5uykM6+R9GqQ8K/uxy9rx7HNQlGYl1kPzQho1wx4JwY8w"
  crossorigin="anonymous">
</script>

<link 
  rel="stylesheet"
  href="https://cdn.example.com/styles.css"
  integrity="sha256-abcdef123456..."
  crossorigin="anonymous">
```

**브라우저 동작:**
1. 리소스 다운로드
2. SHA 해시 계산
3. `integrity` 값과 비교
4. 불일치 → 로드 차단 + 네트워크 에러

### 자동 생성

```bash
# CLI로 해시 생성
cat lib.min.js | openssl dgst -sha384 -binary | openssl base64 -A

# 또는 shasum 사용
shasum -b -a 384 lib.min.js | awk '{print $1}' | xxd -r -p | base64
```

**Webpack 플러그인:**

```javascript
// webpack.config.js
const SriPlugin = require('webpack-subresource-integrity');

module.exports = {
  output: { crossOriginLoading: 'anonymous' },
  plugins: [
    new SriPlugin({ hashFuncNames: ['sha384'] }),
  ],
};
```

### 주의사항
- CDN이 버전별 고정 URL을 제공해야 함 (latest 사용 금지)
- `crossorigin="anonymous"` 필수 (CORS 응답 필요)
- 해시가 맞지 않으면 fallback 로직 필요

---

## 3rd-Party 스크립트 격리

### 위험

3rd-party 스크립트(Analytics, 광고, 채팅 위젯, A/B 테스트)는 두 가지 위험을 내포한다:

**보안 위험:**
- 메인 페이지와 동일한 DOM 접근 권한 → XSS 벡터
- 쿠키, localStorage 접근 가능
- 공급업체가 해킹당하면 우리 사이트도 침해됨 (Magecart 공격 사례)

**성능 위험:**
- 메인 스레드 점유 → INP(Interaction to Next Paint) 저하
- 동기 스크립트로 렌더링 차단
- 예측 불가능한 네트워크 요청

### 격리 전략

#### 1. Sandbox iframe (가장 강력한 격리)

```html
<!-- 3rd-party 콘텐츠를 별도 origin으로 격리 -->
<iframe 
  src="https://widget.example.com/chat"
  sandbox="allow-scripts allow-forms"
  loading="lazy"
  style="border: none; width: 300px; height: 400px;">
</iframe>
```

`sandbox` 속성 플래그:
- `allow-scripts`: JS 실행 허용
- `allow-forms`: form 제출 허용
- `allow-same-origin`: 부모와 동일 origin 취급 (주의!)
- `allow-popups`: window.open 허용
- 플래그 없으면 모든 것 차단

#### 2. Partytown (Web Worker로 3rd-party 이동)

```tsx
// Next.js + Partytown 설정
import { Partytown } from '@builder.io/partytown/react';

export default function RootLayout() {
  return (
    <html>
      <head>
        <Partytown forward={['dataLayer.push']} />
        {/* type="text/partytown"으로 Worker에서 실행 */}
        <script
          type="text/partytown"
          dangerouslySetInnerHTML={{
            __html: `
              (function(w,d,s,l,i){/* GTM snippet */})(window,document,'script','dataLayer','GTM-XXXX');
            `,
          }}
        />
      </head>
      <body>{/* ... */}</body>
    </html>
  );
}
```

**Partytown 장점:**
- 3rd-party가 메인 스레드를 차지하지 않음
- DOM 접근은 Proxy를 통해 제한적으로 허용
- Google Analytics, GTM 등 지원

#### 3. Permissions Policy

```
Permissions-Policy: camera=(), microphone=(), geolocation=(self), payment=(self "https://pay.example.com")
```

- 3rd-party iframe이 민감한 API를 사용하는 것을 원천 차단
- HTTP 헤더 또는 iframe의 `allow` 속성으로 설정

#### 4. CSP로 허용 도메인 제한

```
Content-Security-Policy: 
  script-src 'self' https://www.googletagmanager.com;
  connect-src 'self' https://www.google-analytics.com;
  frame-src https://widget.example.com;
```

---

## Supply Chain Attack 방어

### npm 패키지 위협

| 공격 유형 | 설명 | 실제 사례 |
|-----------|------|-----------|
| Typosquatting | `lodash` → `1odash` | `event-stream` (2018) |
| 메인테이너 탈취 | 계정 해킹 후 악성 코드 삽입 | `ua-parser-js` (2021) |
| postinstall 악용 | 설치 시 악성 스크립트 실행 | `node-ipc` (2022) |
| 의존성 혼동 | 내부 패키지명을 public에 등록 | Dependency Confusion |

### 방어 전략

#### lockfile 커밋

```bash
# package-lock.json 또는 pnpm-lock.yaml은 반드시 커밋
git add package-lock.json

# CI에서는 clean install 사용
npm ci  # (npm install이 아님!)
pnpm install --frozen-lockfile
```

#### npm audit 자동화

```yaml
# .github/workflows/security.yml
name: Security Audit
on:
  push:
    branches: [main]
  schedule:
    - cron: '0 9 * * 1'  # 매주 월요일

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npm audit --audit-level=high
      - name: Socket.dev 분석
        uses: SocketDev/socket-security-action@v1
```

#### 의존성 핀닝

```json
// package.json — exact 버전 사용
{
  "dependencies": {
    "react": "18.2.0",      // ✅ exact
    "next": "14.1.0"        // ✅ exact
  }
}
```

```bash
# npm 기본 설정을 exact로 변경
npm config set save-exact true
# 또는 .npmrc에 추가
echo "save-exact=true" >> .npmrc
```

#### postinstall 스크립트 차단

```ini
# .npmrc
ignore-scripts=true
```

```bash
# 필요한 패키지만 선택적으로 스크립트 허용
npm rebuild esbuild  # esbuild는 postinstall이 필요
```

#### 의존성 리뷰 도구

- **Renovate / Dependabot**: 자동 업데이트 PR + 변경사항 diff
- **Socket.dev**: 행동 분석 (네트워크 호출, fs 접근 감지)
- **Snyk**: 취약점 DB 기반 스캔
- **npm provenance**: 빌드 출처 증명 (npm v9.5+)

---

## CORS 실전 트러블슈팅

### 흔한 에러와 해결

#### 1. Preflight (OPTIONS) 실패

```
Access to fetch at 'https://api.example.com/data' from origin 'https://app.example.com' 
has been blocked by CORS policy: Response to preflight request doesn't pass access control check
```

**원인:** 서버가 OPTIONS 요청에 적절한 헤더를 응답하지 않음

**해결 (서버측):**
```typescript
// Express 예시
app.options('*', (req, res) => {
  res.set({
    'Access-Control-Allow-Origin': 'https://app.example.com',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400', // preflight 캐시 24시간
  });
  res.status(204).end();
});
```

#### 2. credentials 모드에서 와일드카드 금지

```
The value of the 'Access-Control-Allow-Origin' header must not be the wildcard '*' 
when the request's credentials mode is 'include'.
```

**원인:** `credentials: 'include'` 사용 시 `Access-Control-Allow-Origin: *` 불가

**해결:**
```typescript
// 동적으로 요청 Origin 반영
app.use((req, res, next) => {
  const allowedOrigins = ['https://app.example.com', 'https://admin.example.com'];
  const origin = req.headers.origin;
  
  if (origin && allowedOrigins.includes(origin)) {
    res.set('Access-Control-Allow-Origin', origin);
    res.set('Access-Control-Allow-Credentials', 'true');
  }
  next();
});
```

#### 3. 개발 환경 프록시

```typescript
// vite.config.ts
export default defineConfig({
  server: {
    proxy: {
      '/api': {
        target: 'https://api.example.com',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
      },
    },
  },
});
```

#### 4. Next.js middleware로 CORS 설정

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const allowedOrigins = ['https://app.example.com'];

export function middleware(request: NextRequest) {
  const origin = request.headers.get('origin') ?? '';
  const isAllowed = allowedOrigins.includes(origin);

  // Preflight 처리
  if (request.method === 'OPTIONS') {
    return new NextResponse(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': isAllowed ? origin : '',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Allow-Credentials': 'true',
        'Access-Control-Max-Age': '86400',
      },
    });
  }

  const response = NextResponse.next();
  if (isAllowed) {
    response.headers.set('Access-Control-Allow-Origin', origin);
    response.headers.set('Access-Control-Allow-Credentials', 'true');
  }
  return response;
}

export const config = { matcher: '/api/:path*' };
```

---

## 기타 보안 헤더

| 헤더 | 값 | 역할 |
|------|---|------|
| `X-Content-Type-Options` | `nosniff` | MIME 스니핑 방지 (JS를 이미지로 위장하는 공격 차단) |
| `X-Frame-Options` | `DENY` | Clickjacking 방지 (iframe 임베딩 차단) |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` | HSTS — HTTP 접속을 HTTPS로 강제 |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | 다른 사이트로 이동 시 전체 URL 노출 방지 |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=()` | 브라우저 API 사용 제한 |
| `X-DNS-Prefetch-Control` | `off` | DNS prefetch를 통한 정보 유출 방지 |

---

## 실전 코드 예제

### Next.js에서 보안 헤더 설정 (next.config.js)

```javascript
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-DNS-Prefetch-Control',
            value: 'on',
          },
          {
            key: 'Strict-Transport-Security',
            value: 'max-age=63072000; includeSubDomains; preload',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=(self), payment=(self)',
          },
        ],
      },
    ];
  },
};

module.exports = nextConfig;
```

### CSP nonce 미들웨어 구현 (완전 예제)

```typescript
// middleware.ts — 프로덕션용 CSP 미들웨어
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const nonce = Buffer.from(crypto.randomUUID()).toString('base64');

  // 개발 환경에서는 unsafe-eval 허용 (React Fast Refresh)
  const isDev = process.env.NODE_ENV === 'development';

  const csp = [
    `default-src 'self'`,
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${isDev ? " 'unsafe-eval'" : ''}`,
    `style-src 'self' 'nonce-${nonce}'`,
    `img-src 'self' blob: data: https:`,
    `font-src 'self' https://fonts.gstatic.com`,
    `connect-src 'self' https://api.example.com${isDev ? ' ws:' : ''}`,
    `frame-src 'none'`,
    `object-src 'none'`,
    `base-uri 'self'`,
    `form-action 'self'`,
    `frame-ancestors 'none'`,
    `upgrade-insecure-requests`,
  ].join('; ');

  const response = NextResponse.next();
  response.headers.set('x-nonce', nonce);
  response.headers.set('Content-Security-Policy', csp);

  return response;
}

export const config = {
  matcher: [
    // 정적 파일 제외
    '/((?!_next/static|_next/image|favicon.ico).*)',
  ],
};
```

### DOMPurify로 사용자 입력 sanitize

```typescript
// lib/sanitize.ts
import DOMPurify from 'dompurify';

// 허용할 태그와 속성을 명시적으로 지정
const ALLOWED_TAGS = ['b', 'i', 'em', 'strong', 'a', 'p', 'br', 'ul', 'ol', 'li', 'code', 'pre'];
const ALLOWED_ATTR = ['href', 'target', 'rel'];

export function sanitizeHTML(dirty: string): string {
  return DOMPurify.sanitize(dirty, {
    ALLOWED_TAGS,
    ALLOWED_ATTR,
    // href에 javascript: 프로토콜 차단
    FORBID_ATTR: ['onerror', 'onload', 'onclick'],
    ALLOW_DATA_ATTR: false,
  });
}

// React 컴포넌트에서 사용
export function SafeHTML({ html }: { html: string }) {
  return (
    <div
      dangerouslySetInnerHTML={{ __html: sanitizeHTML(html) }}
    />
  );
}
```

```typescript
// 서버 사이드에서도 sanitize (isomorphic-dompurify)
import createDOMPurify from 'isomorphic-dompurify';

// Node.js 환경에서도 동작
export function sanitizeOnServer(dirty: string): string {
  return createDOMPurify.sanitize(dirty, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'p'],
  });
}
```

### npm audit CI 자동화

```yaml
# .github/workflows/security-audit.yml
name: Security Audit

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 0 * * 1'  # 매주 월요일 00:00 UTC

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run npm audit
        run: npm audit --audit-level=high --omit=dev
        continue-on-error: true

      - name: Check for critical vulnerabilities
        run: |
          RESULT=$(npm audit --json --omit=dev 2>/dev/null | jq '.metadata.vulnerabilities.critical')
          if [ "$RESULT" != "0" ] && [ "$RESULT" != "null" ]; then
            echo "::error::Critical vulnerabilities found!"
            npm audit --omit=dev
            exit 1
          fi

      - name: License check
        run: npx license-checker --failOn 'GPL-3.0;AGPL-3.0'
```

---

## 보안 체크리스트 (프론트엔드)

배포 전 반드시 확인해야 할 항목:

### 전송 보안
- [ ] HTTPS 강제 (HSTS 헤더 설정)
- [ ] Mixed content 없음 (HTTP 리소스 로드 차단)

### 콘텐츠 보안
- [ ] CSP 설정 (최소 Report-Only 모드)
- [ ] X-Content-Type-Options: nosniff
- [ ] X-Frame-Options: DENY
- [ ] Referrer-Policy 설정

### 입력/출력 보안
- [ ] 사용자 입력 sanitize (DOMPurify 등)
- [ ] `dangerouslySetInnerHTML` 사용 시 반드시 sanitize
- [ ] URL 파라미터를 DOM에 반영할 때 이스케이프

### 민감 데이터
- [ ] 소스맵 프로덕션 비활성화 또는 접근 제한
- [ ] `console.log`에 민감 정보 출력 안 함
- [ ] 환경변수 노출 확인 (`NEXT_PUBLIC_` 접두사 주의)
- [ ] API 키가 클라이언트 번들에 포함되지 않음

### 의존성
- [ ] `npm audit` 또는 `pnpm audit` 통과
- [ ] lockfile 커밋됨
- [ ] 불필요한 의존성 제거
- [ ] postinstall 스크립트 검토

### 인증/세션
- [ ] 토큰을 localStorage가 아닌 httpOnly 쿠키에 저장
- [ ] CSRF 토큰 적용 (상태 변경 요청)
- [ ] 세션 타임아웃 설정

---

## 면접 포인트

### Q1: CSP란 무엇이고 어떻게 설정하는가?
> CSP는 HTTP 응답 헤더로, 브라우저에게 허용된 리소스 출처를 명시한다. `script-src`, `style-src` 등 디렉티브로 세분화하며, nonce 기반 + strict-dynamic 조합이 현재 권장 방식이다. Report-Only → Enforce 순서로 단계적 배포한다.

### Q2: XSS를 프론트엔드에서 방어하는 방법은?
> 1) CSP로 인라인 스크립트 차단, 2) 사용자 입력은 DOMPurify로 sanitize, 3) React의 자동 이스케이프 활용 (dangerouslySetInnerHTML 최소화), 4) URL scheme 검증 (javascript: 차단), 5) httpOnly 쿠키로 토큰 보호.

### Q3: 3rd-party 스크립트의 보안 위험과 대응은?
> 3rd-party 스크립트는 메인 페이지와 동일한 권한을 가져 XSS 벡터가 된다. 대응: sandbox iframe으로 격리, Partytown으로 Worker 분리, CSP로 도메인 제한, SRI로 무결성 검증, Permissions Policy로 민감 API 접근 차단.

### Q4: npm supply chain attack이란? 어떻게 방어하는가?
> 악성 코드가 포함된 npm 패키지를 통한 공격. Typosquatting, 메인테이너 계정 탈취, postinstall 악용 등. 방어: lockfile 커밋 + CI에서 `npm ci`, exact 버전 핀닝, `ignore-scripts=true`, npm audit 자동화, Socket.dev로 행동 분석.

### Q5: SRI는 언제 사용하고 어떻게 동작하는가?
> CDN 등 외부 출처에서 로드하는 스크립트/스타일에 사용. integrity 속성에 SHA 해시를 명시하면, 브라우저가 다운로드한 파일의 해시를 비교해 불일치 시 로드를 차단한다. CDN이 해킹당해도 변조된 코드 실행을 방지.

### Q6: CORS preflight가 실패하는 원인과 해결 방법은?
> Preflight는 `Content-Type: application/json` 등 "simple request"가 아닌 요청 전에 OPTIONS를 보내는 것. 실패 원인: 서버가 OPTIONS에 `Access-Control-Allow-*` 헤더를 응답하지 않음, credentials 모드에서 `*` 와일드카드 사용, 허용되지 않은 헤더/메서드. 해결: 서버에서 명시적 CORS 설정.

---

## 참고 자료

- [MDN — Content Security Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP)
- [web.dev — Strict CSP](https://web.dev/strict-csp/)
- [OWASP — XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Scripting_Prevention_Cheat_Sheet.html)
- [Socket.dev — Supply Chain Security](https://socket.dev/blog)
- [Next.js — Content Security Policy](https://nextjs.org/docs/app/building-your-application/configuring/content-security-policy)
- [Partytown](https://partytown.builder.io/)
- [DOMPurify](https://github.com/cure53/DOMPurify)
- [Report URI](https://report-uri.com/) — CSP 리포트 수집 서비스
- [Security Headers](https://securityheaders.com/) — 보안 헤더 진단 도구
