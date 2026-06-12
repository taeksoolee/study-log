# 3. OAuth 2.0 & OpenID Connect

## 목차
1. OAuth 2.0이란
2. 주요 역할자
3. 인가 코드 플로우 (Authorization Code Flow)
4. PKCE (Proof Key for Code Exchange)
5. Implicit Flow (구식)
6. Client Credentials Flow
7. OpenID Connect (OIDC)
8. 소셜 로그인 구현 흐름
9. 프론트엔드 구현: NextAuth.js / Auth.js
10. 면접 포인트

---

## 1. OAuth 2.0이란

OAuth 2.0은 **인가(Authorization) 프레임워크**입니다. 사용자가 자신의 자격증명(비밀번호)을 제3자 앱에 직접 제공하지 않고도, 제한된 권한을 위임할 수 있게 합니다(RFC 6749).

```
"Google 계정으로 로그인" 버튼을 눌렀을 때:
  → 우리 앱이 사용자의 Google 이메일/프로필을 읽을 수 있도록
    사용자가 Google에 권한을 위임
  → 우리 앱은 사용자의 Google 비밀번호를 알 필요 없음
```

---

## 2. 주요 역할자

| 역할 | 설명 | 예시 |
|------|------|------|
| **Resource Owner** | 자원의 소유자 (사용자) | Google 계정 사용자 |
| **Client** | 권한을 요청하는 앱 | 우리가 만드는 웹 앱 |
| **Authorization Server** | 권한 부여 서버 | Google OAuth 서버 |
| **Resource Server** | 보호된 자원을 가진 서버 | Google API 서버 |

---

## 3. 인가 코드 플로우 (Authorization Code Flow)

가장 안전한 플로우로, 브라우저 기반 앱의 표준 방식입니다.

```
사용자 브라우저          우리 서버 (Client)       Google OAuth 서버
      │                        │                          │
      │ 1. "Google로 로그인" 클릭
      │─────────────────────→ │
      │                        │ 2. 인가 URL 생성
      │                        │    client_id, redirect_uri,
      │                        │    scope, state, response_type=code
      │ 3. 리다이렉트 (Google 로그인 페이지로)
      │←──────────────────── │
      │──────────────────────────────────────────────────→│
      │                                                    │
      │ 4. 사용자가 Google에 로그인 + 권한 동의
      │──────────────────────────────────────────────────→│
      │                                                    │
      │ 5. 리다이렉트: redirect_uri?code=AUTH_CODE&state=...
      │←─────────────────────────────────────────────────│
      │─────────────────────→ │
      │                        │ 6. code를 Authorization Server에 교환
      │                        │─────────────────────────────────────→│
      │                        │   POST /token
      │                        │   { code, client_id, client_secret,
      │                        │     redirect_uri, grant_type }
      │                        │←────────────────────────────────────│
      │                        │   { access_token, refresh_token, id_token }
      │                        │
      │                        │ 7. Access Token으로 API 호출
      │                        │─────────────────────────────────────→│ (Resource Server)
      │                        │←────────────────────────────────────│
      │                        │   사용자 프로필 데이터
      │←──────────────────── │
      │ 8. 로그인 완료 (세션 생성)
```

### 핵심 포인트

- `code`는 브라우저를 통해 전달되지만, **짧은 유효 시간**(수 분) + **1회 사용**
- `client_secret`은 서버-서버 통신에서만 사용 → 브라우저에 노출 안 됨
- `state` 파라미터: CSRF 방어용 랜덤 값

---

## 4. PKCE (Proof Key for Code Exchange)

SPA나 모바일 앱은 `client_secret`을 안전하게 보관할 수 없습니다(브라우저/앱에 포함되므로 추출 가능). PKCE는 `client_secret` 없이 인가 코드 플로우를 안전하게 사용하는 방법입니다(RFC 7636).

### PKCE 동작 원리

```javascript
// 1. code_verifier 생성 (랜덤 문자열, 43~128자)
const codeVerifier = generateRandomString(64);
// → "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"

// 2. code_challenge 생성 (code_verifier의 SHA-256 해시, Base64URL)
const codeChallenge = base64URLEncode(sha256(codeVerifier));
// → "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"

// 3. 인가 요청 시 code_challenge 포함
const authUrl = `https://accounts.google.com/o/oauth2/v2/auth?
  client_id=...&
  redirect_uri=...&
  response_type=code&
  scope=openid email profile&
  code_challenge=${codeChallenge}&
  code_challenge_method=S256&
  state=${state}`;

// 4. 토큰 교환 시 code_verifier 포함
const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
  method: 'POST',
  body: new URLSearchParams({
    grant_type: 'authorization_code',
    code: authorizationCode,
    redirect_uri: REDIRECT_URI,
    client_id: CLIENT_ID,
    code_verifier: codeVerifier, // client_secret 대신
  }),
});
```

```
공격자가 인가 코드를 가로채도:
  → code_verifier 없이는 토큰 교환 불가
  → code_challenge는 해시값이므로 역산 불가
```

---

## 5. Implicit Flow (구식, 지양)

Access Token을 URL Fragment(`#`)로 직접 반환하는 방식입니다.

```
https://app.example.com/callback#access_token=TOKEN&token_type=Bearer
```

| 문제점 | 설명 |
|--------|------|
| 브라우저 히스토리에 토큰 노출 | URL이 히스토리에 남음 |
| Refresh Token 없음 | 토큰 갱신 불편 |
| 서버 검증 없음 | 중간자 공격 취약 |

현재 OAuth 2.0 보안 모범 사례(RFC 9700)에서는 **Implicit Flow 사용을 금지**하고 PKCE를 적용한 Authorization Code Flow를 권장합니다.

---

## 6. Client Credentials Flow

사용자가 없는 **서버-서버 통신**에서 사용합니다.

```
서비스 A (Client)                    인증 서버
    │                                    │
    │── POST /token ────────────────────→│
    │   grant_type=client_credentials   │
    │   client_id=...                   │
    │   client_secret=...               │
    │                                    │
    │←── { access_token: "..." } ──────│
    │                                    │
    │── API 요청 (Bearer Token) ────────→│ 서비스 B
```

사용 사례: CI/CD 파이프라인, 백그라운드 Job, 마이크로서비스 간 통신

---

## 7. OpenID Connect (OIDC)

OAuth 2.0은 **인가** 프로토콜입니다. "사용자가 누구인지"는 알 수 없습니다. OIDC는 OAuth 2.0 위에 **인증** 레이어를 추가합니다.

### ID Token

OIDC는 Access Token 외에 **ID Token**(JWT 형식)을 추가로 발급합니다.

```json
// ID Token Payload 예시
{
  "iss": "https://accounts.google.com",
  "sub": "110169484474386276334",    // Google 사용자 고유 ID
  "aud": "client_id_here",
  "exp": 1735689600,
  "iat": 1735686000,
  "email": "user@example.com",
  "email_verified": true,
  "name": "홍길동",
  "picture": "https://lh3.googleusercontent.com/..."
}
```

### OAuth 2.0 vs OIDC 비교

| 항목 | OAuth 2.0 | OIDC |
|------|-----------|------|
| 목적 | 인가 (권한 위임) | 인증 (신원 확인) + 인가 |
| 발급 토큰 | Access Token | Access Token + ID Token |
| 사용자 정보 | /userinfo API 별도 호출 | ID Token에 포함 |
| Scope | resource scopes | `openid`, `profile`, `email` |

---

## 8. 소셜 로그인 구현 흐름 (Google 예시)

### 프론트엔드 흐름

```javascript
// 1. 인가 요청 URL 생성 (PKCE 적용)
async function initiateGoogleLogin() {
  const codeVerifier = generateCodeVerifier();
  const codeChallenge = await generateCodeChallenge(codeVerifier);
  const state = generateRandomString(32);

  // PKCE 정보를 sessionStorage에 임시 저장
  sessionStorage.setItem('pkce_verifier', codeVerifier);
  sessionStorage.setItem('oauth_state', state);

  const params = new URLSearchParams({
    client_id: GOOGLE_CLIENT_ID,
    redirect_uri: `${window.location.origin}/auth/callback`,
    response_type: 'code',
    scope: 'openid email profile',
    state,
    code_challenge: codeChallenge,
    code_challenge_method: 'S256',
  });

  window.location.href = `https://accounts.google.com/o/oauth2/v2/auth?${params}`;
}

// 2. 콜백 처리 (redirect_uri 페이지)
async function handleOAuthCallback() {
  const params = new URLSearchParams(window.location.search);
  const code = params.get('code');
  const state = params.get('state');

  // state 검증 (CSRF 방어)
  if (state !== sessionStorage.getItem('oauth_state')) {
    throw new Error('State mismatch: CSRF 공격 가능성');
  }

  // 백엔드에 code 전달 (서버에서 토큰 교환)
  const response = await fetch('/api/auth/google/callback', {
    method: 'POST',
    body: JSON.stringify({
      code,
      codeVerifier: sessionStorage.getItem('pkce_verifier'),
    }),
  });

  sessionStorage.removeItem('pkce_verifier');
  sessionStorage.removeItem('oauth_state');
}
```

---

## 9. 프론트엔드 구현: NextAuth.js / Auth.js

Next.js 환경에서는 Auth.js(구 NextAuth.js)로 OAuth를 간편하게 구현합니다.

```javascript
// app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth';
import GoogleProvider from 'next-auth/providers/google';
import GitHubProvider from 'next-auth/providers/github';

const handler = NextAuth({
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
    GitHubProvider({
      clientId: process.env.GITHUB_ID!,
      clientSecret: process.env.GITHUB_SECRET!,
    }),
  ],
  callbacks: {
    async jwt({ token, account }) {
      if (account) {
        token.accessToken = account.access_token;
      }
      return token;
    },
    async session({ session, token }) {
      session.accessToken = token.accessToken;
      return session;
    },
  },
});

export { handler as GET, handler as POST };
```

```tsx
// 클라이언트 컴포넌트에서 사용
'use client';
import { signIn, signOut, useSession } from 'next-auth/react';

export default function LoginButton() {
  const { data: session } = useSession();

  if (session) {
    return (
      <div>
        <p>{session.user?.name}님 환영합니다</p>
        <button onClick={() => signOut()}>로그아웃</button>
      </div>
    );
  }

  return <button onClick={() => signIn('google')}>Google로 로그인</button>;
}
```

---

## 10. 면접 포인트

**Q. OAuth 2.0은 인증인가요, 인가인가요?**

> 인가(Authorization) 프레임워크입니다. 사용자가 누구인지(인증)가 아니라, 제3자 앱에게 어떤 권한을 위임할지를 다룹니다. 인증이 필요하면 OAuth 2.0 위에 OIDC를 추가해 ID Token을 사용합니다.

**Q. Authorization Code Flow에서 code를 직접 Access Token으로 쓰지 않는 이유는?**

> code는 브라우저 URL을 통해 전달되어 히스토리, 로그, Referer 헤더에 노출될 수 있습니다. code를 Access Token으로 교환하는 단계는 서버-서버 통신(client_secret 포함)으로 수행하므로 Access Token이 브라우저에 노출되지 않습니다.

**Q. SPA에서 OAuth를 구현할 때 PKCE가 필요한 이유는?**

> SPA는 코드가 브라우저에 완전히 노출되므로 client_secret을 안전하게 보관할 수 없습니다. PKCE는 code_verifier/code_challenge 쌍으로 client_secret 없이도 인가 코드 탈취를 방어합니다.

**Q. state 파라미터의 역할은?**

> CSRF 방어용 랜덤 값입니다. 인가 요청 시 생성해 세션에 저장하고, 콜백에서 수신한 state와 비교합니다. 값이 다르면 요청을 위조한 것으로 판단해 거부합니다.

**Q. OIDC의 ID Token과 Access Token의 차이는?**

> ID Token은 사용자 신원 정보(누구인지)를 담은 JWT로 클라이언트가 사용합니다. Access Token은 Resource Server의 API를 호출할 때 사용하는 권한 증명입니다. ID Token으로 API를 호출하거나, Access Token으로 사용자 신원을 확인하는 용도로 사용하면 안 됩니다.
