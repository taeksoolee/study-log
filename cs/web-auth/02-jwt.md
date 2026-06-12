# 2. JWT (JSON Web Token)

## 목차
1. JWT란 무엇인가
2. JWT 구조 상세
3. JWT 검증 과정
4. 서명 알고리즘: HS256 vs RS256
5. Access Token + Refresh Token 패턴
6. JWT 저장 위치: localStorage vs HttpOnly Cookie
7. JWT 무효화 문제
8. 면접 포인트

---

## 1. JWT란 무엇인가

JWT(JSON Web Token)는 당사자 간에 정보를 JSON 형태로 안전하게 전송하기 위한 **자가수용적(Self-contained) 토큰** 표준입니다(RFC 7519).

세션 방식과의 핵심 차이: 서버가 상태를 저장하지 않아도 됩니다.

```
세션 방식: 서버가 상태 저장 → 클라이언트는 ID만 보유
JWT 방식:  서버는 무상태  → 클라이언트가 정보(토큰)를 보유
```

---

## 2. JWT 구조 상세

JWT는 `.`으로 구분된 세 부분으로 구성됩니다.

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
.
eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ
.
SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c

[Header].[Payload].[Signature]
```

각 부분은 **Base64URL 인코딩**입니다 (암호화가 아닙니다!).

### 2-1. Header

```json
{
  "alg": "HS256",  // 서명 알고리즘 (HS256, RS256 등)
  "typ": "JWT"     // 토큰 타입
}
```

### 2-2. Payload (Claims)

```json
{
  // 등록된 클레임 (표준)
  "iss": "https://auth.example.com",  // 발급자 (Issuer)
  "sub": "1234567890",                 // 주제/사용자 ID (Subject)
  "aud": "https://api.example.com",   // 대상 (Audience)
  "exp": 1735689600,                  // 만료 시각 (Expiration) - Unix 타임스탬프
  "iat": 1735686000,                  // 발급 시각 (Issued At)
  "nbf": 1735686000,                  // 유효 시작 시각 (Not Before)

  // 공개 클레임 (사용자 정의)
  "name": "John Doe",
  "email": "john@example.com",
  "role": "admin"
}
```

> **주의**: Payload는 Base64URL 디코딩으로 누구나 읽을 수 있습니다. 민감한 정보(비밀번호, 카드번호 등)는 절대 포함하지 마세요.

### 2-3. Signature

```
HMACSHA256(
  base64UrlEncode(header) + "." + base64UrlEncode(payload),
  secret
)
```

서명은 토큰이 **변조되지 않았음**을 검증하는 데 사용됩니다. 비밀 키 없이는 유효한 서명을 만들 수 없습니다.

---

## 3. JWT 검증 과정

```
클라이언트                              서버
    │                                     │
    │── GET /api/data ──────────────────→ │
    │   Authorization: Bearer <JWT>       │
    │                                     │
    │                                     │ 1. JWT 분리: Header.Payload.Signature
    │                                     │
    │                                     │ 2. Header에서 알고리즘 확인 (HS256)
    │                                     │
    │                                     │ 3. 서명 재계산
    │                                     │    HMAC(header.payload, secretKey)
    │                                     │
    │                                     │ 4. 계산된 서명 == 받은 서명? 검증
    │                                     │
    │                                     │ 5. exp(만료) 확인
    │                                     │
    │                                     │ 6. iss, aud 확인 (선택)
    │                                     │
    │← 200 OK (데이터) ──────────────── │
```

```javascript
// Node.js에서 JWT 생성 및 검증
const jwt = require('jsonwebtoken');

// 토큰 생성
const token = jwt.sign(
  { sub: user.id, role: user.role },
  process.env.JWT_SECRET,
  { expiresIn: '15m', issuer: 'my-auth-server' }
);

// 토큰 검증
try {
  const decoded = jwt.verify(token, process.env.JWT_SECRET, {
    issuer: 'my-auth-server',
  });
  console.log(decoded.sub); // 사용자 ID
} catch (err) {
  if (err.name === 'TokenExpiredError') {
    // 만료된 토큰
  } else if (err.name === 'JsonWebTokenError') {
    // 유효하지 않은 토큰
  }
}
```

---

## 4. 서명 알고리즘: HS256 vs RS256

### HS256 (HMAC-SHA256) — 대칭 키

```
서명:   HMAC(data, secret)
검증:   HMAC(data, secret) == signature
```

- 하나의 비밀 키로 서명과 검증을 모두 수행
- 토큰 생성자와 검증자가 같을 때 적합 (단일 서버)
- 비밀 키가 노출되면 토큰 위조 가능

### RS256 (RSA-SHA256) — 비대칭 키

```
서명:   RSA_Sign(data, privateKey)     → 인증 서버만 가능
검증:   RSA_Verify(data, publicKey)    → 누구나 가능
```

- 개인 키(private key)로 서명, 공개 키(public key)로 검증
- 마이크로서비스에서 인증 서버만 토큰을 발급하고, 각 서비스는 공개 키로 검증
- 공개 키는 노출되어도 안전

```
인증 서버 (private key 보유)
    │
    │ 토큰 서명
    ▼
서비스 A (public key로 검증)
서비스 B (public key로 검증)
서비스 C (public key로 검증)
```

---

## 5. Access Token + Refresh Token 패턴

JWT의 단점(무효화 어려움)을 보완하기 위한 표준 패턴입니다.

### 토큰 역할

| 토큰 | 만료 시간 | 저장 위치 | 역할 |
|------|-----------|-----------|------|
| **Access Token** | 짧음 (15분~1시간) | 메모리 또는 쿠키 | API 요청 인증 |
| **Refresh Token** | 길음 (7일~30일) | HttpOnly Cookie | Access Token 재발급 |

### 전체 흐름

```
1. 로그인
   클라이언트 ─── POST /login ──────────→ 서버
                { id, password }
   클라이언트 ←── 200 OK ─────────────── 서버
                { accessToken: "eyJ..." }
                Set-Cookie: refreshToken=...; HttpOnly; Secure

2. API 요청
   클라이언트 ─── GET /api/me ───────────→ 서버
                Authorization: Bearer <accessToken>
   클라이언트 ←── 200 OK ─────────────── 서버

3. Access Token 만료 시 (Silent Refresh)
   클라이언트 ─── POST /auth/refresh ───→ 서버
                Cookie: refreshToken=...    (자동 전송)
   클라이언트 ←── 200 OK ─────────────── 서버
                { accessToken: "eyJ..." }  (새 Access Token)
                Set-Cookie: refreshToken=... (Token Rotation)
```

### Token Rotation

Refresh Token을 재사용하면 탈취 위험이 있으므로, Refresh Token을 사용할 때마다 새 Refresh Token을 발급합니다.

```javascript
// Refresh Token Rotation 구현 예시
app.post('/auth/refresh', async (req, res) => {
  const refreshToken = req.cookies.refreshToken;

  try {
    const decoded = jwt.verify(refreshToken, process.env.REFRESH_SECRET);

    // 이미 사용된 토큰이면 거부 (DB에서 확인)
    const isValid = await RefreshTokenStore.check(refreshToken);
    if (!isValid) {
      // 토큰 재사용 감지 → 해당 사용자의 모든 세션 무효화
      await RefreshTokenStore.revokeAll(decoded.sub);
      return res.status(401).json({ error: 'Token reuse detected' });
    }

    // 기존 Refresh Token 무효화
    await RefreshTokenStore.revoke(refreshToken);

    // 새 토큰 발급
    const newAccessToken = jwt.sign(
      { sub: decoded.sub },
      process.env.JWT_SECRET,
      { expiresIn: '15m' }
    );
    const newRefreshToken = jwt.sign(
      { sub: decoded.sub },
      process.env.REFRESH_SECRET,
      { expiresIn: '7d' }
    );

    await RefreshTokenStore.save(newRefreshToken, decoded.sub);

    res.cookie('refreshToken', newRefreshToken, {
      httpOnly: true, secure: true, sameSite: 'lax',
      maxAge: 7 * 24 * 60 * 60 * 1000,
    });
    res.json({ accessToken: newAccessToken });
  } catch {
    res.status(401).json({ error: 'Invalid refresh token' });
  }
});
```

---

## 6. JWT 저장 위치: localStorage vs HttpOnly Cookie

### localStorage

```javascript
localStorage.setItem('accessToken', token);
const token = localStorage.getItem('accessToken');
```

| 장점 | 단점 |
|------|------|
| 구현 단순 | **XSS 공격에 취약** |
| 도메인 제한 없음 | 악성 스크립트가 토큰 직접 탈취 가능 |

### HttpOnly Cookie

```
Set-Cookie: accessToken=eyJ...; HttpOnly; Secure; SameSite=Lax
```

| 장점 | 단점 |
|------|------|
| JS 접근 불가 → XSS 방어 | **CSRF 공격에 노출** (SameSite로 방어) |
| 자동 전송 | 도메인/경로 제한 |

### 권장 패턴

```
Access Token  → 메모리(변수)에 저장
                - 짧은 만료 시간이므로 메모리 저장 허용
                - 페이지 새로고침 시 Refresh Token으로 재발급

Refresh Token → HttpOnly Cookie에 저장
                - SameSite=Lax로 CSRF 방어
                - Secure로 HTTPS 강제
```

```javascript
// React에서 Access Token을 메모리에 관리
let accessToken = null;

export const setAccessToken = (token) => { accessToken = token; };
export const getAccessToken = () => accessToken;

// Axios 인터셉터로 자동 갱신
axios.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      const res = await axios.post('/auth/refresh', {}, { withCredentials: true });
      setAccessToken(res.data.accessToken);
      error.config.headers['Authorization'] = `Bearer ${res.data.accessToken}`;
      return axios(error.config);
    }
    return Promise.reject(error);
  }
);
```

---

## 7. JWT 무효화 문제

JWT는 서버가 상태를 저장하지 않으므로 발급된 토큰을 즉시 무효화하기 어렵습니다.

### 문제 시나리오

```
1. 사용자가 로그아웃
2. Access Token 만료까지 (최대 1시간) 해당 토큰은 여전히 유효
3. 탈취된 토큰으로 API 요청 가능
```

### 해결 방법

| 방법 | 설명 | 비용 |
|------|------|------|
| **짧은 만료 시간** | Access Token을 15분 이하로 설정 | 낮음 |
| **블랙리스트** | 무효화된 토큰을 Redis에 저장, 요청마다 확인 | 중간 (Stateless 이점 상실) |
| **Refresh Token 폐기** | Logout 시 Refresh Token만 DB에서 삭제 | 낮음 (Access Token 만료 대기) |
| **짧은 Access Token + Refresh Rotation** | 실질적 보안 충분 | 낮음 (권장) |

---

## 8. 면접 포인트

**Q. JWT의 Payload는 암호화되나요?**

> 아닙니다. Base64URL 인코딩만 적용되어 누구나 디코딩할 수 있습니다. Signature는 무결성 검증용으로, 변조 여부만 확인합니다. 민감한 정보는 Payload에 포함하지 않아야 합니다.

**Q. Access Token을 어디에 저장해야 하나요?**

> 메모리(JS 변수)에 저장하는 것이 가장 안전합니다. localStorage는 XSS에 취약하고, Cookie는 CSRF에 노출됩니다. Refresh Token은 HttpOnly Cookie에 저장하고, 페이지 로드 시 Refresh Token으로 Access Token을 재발급받는 Silent Refresh 패턴을 사용합니다.

**Q. JWT를 로그아웃 직후 무효화할 수 없는 이유는?**

> JWT는 서버가 상태를 저장하지 않는 Stateless 구조이므로, 발급된 토큰은 만료 전까지 유효합니다. 즉시 무효화가 필요하면 Redis 블랙리스트를 사용하지만, 이 경우 Stateless 이점이 사라집니다. 일반적으로 Access Token 만료 시간을 짧게 설정하고 Refresh Token 폐기로 실질적인 보안을 확보합니다.

**Q. HS256과 RS256의 차이와 사용 시나리오는?**

> HS256은 하나의 비밀 키로 서명/검증하므로 단일 서버에 적합합니다. RS256은 개인 키로 서명하고 공개 키로 검증하므로, 인증 서버 하나가 여러 마이크로서비스에 토큰을 발급할 때 각 서비스는 공개 키만 가지고 독립적으로 검증할 수 있어 마이크로서비스 환경에 적합합니다.

**Q. Token Rotation이란 무엇이고 왜 필요한가요?**

> Refresh Token을 사용할 때마다 새 Refresh Token을 발급하고 기존 것을 무효화하는 패턴입니다. Refresh Token이 탈취되어 재사용되면 서버가 이를 감지하고 해당 사용자의 모든 세션을 무효화할 수 있어 보안성이 높아집니다.
