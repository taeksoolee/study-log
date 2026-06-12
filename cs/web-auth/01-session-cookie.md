# 1. 세션 기반 인증 & 쿠키

## 목차
1. 인증(Authentication) vs 인가(Authorization)
2. HTTP 무상태(Stateless)와 세션
3. 세션 동작 흐름
4. 쿠키 속성 상세
5. 세션 저장소: 메모리 vs Redis
6. 세션 하이재킹 공격과 방어
7. 세션 vs JWT 비교
8. 면접 포인트

---

## 1. 인증(Authentication) vs 인가(Authorization)

두 개념은 혼용되기 쉽지만 명확히 다릅니다.

| 구분 | 인증 (Authentication) | 인가 (Authorization) |
|------|----------------------|---------------------|
| 질문 | "당신이 누구입니까?" | "당신이 이것을 할 수 있습니까?" |
| 예시 | 로그인, 지문 인식 | 관리자 페이지 접근, 파일 수정 권한 |
| 영문 약어 | AuthN | AuthZ |
| 선후관계 | 먼저 수행 | 인증 이후에 수행 |

```
사용자 접근 요청
    │
    ▼
[인증] 아이디/비밀번호 확인 → 신원 확인 완료
    │
    ▼
[인가] 해당 리소스 접근 권한 확인 → 허용/거부
    │
    ▼
리소스 응답
```

---

## 2. HTTP 무상태(Stateless)와 세션

### HTTP는 왜 무상태인가?

HTTP 프로토콜은 각 요청이 독립적으로 처리됩니다. 서버는 이전 요청을 기억하지 않습니다.

```
클라이언트                    서버
    │                          │
    │── GET /login ──────────→ │  (1번 요청)
    │← 200 OK ─────────────── │
    │                          │
    │── GET /dashboard ──────→ │  (2번 요청)
    │                          │  서버: "이 사람이 누구지? 모르겠음"
    │← 401 Unauthorized ────── │
```

이 문제를 해결하기 위해 **세션(Session)** 또는 **토큰(Token)** 방식을 사용합니다.

### 세션이란?

서버가 사용자별 상태 정보를 서버 측 저장소에 보관하고, 클라이언트에게는 해당 세션을 식별하는 **세션 ID**만 쿠키로 전달하는 방식입니다.

---

## 3. 세션 동작 흐름

### 3-1. 로그인 (세션 생성)

```
클라이언트                         서버
    │                               │
    │── POST /login ───────────────→│
    │   { id: "user", pw: "1234" }  │
    │                               │ 1. 자격증명 검증
    │                               │ 2. 세션 생성 (sessionId: "abc123")
    │                               │ 3. 세션 저장소에 저장
    │                               │    { "abc123": { userId: 1, role: "user" } }
    │← 200 OK ──────────────────── │
    │  Set-Cookie: sessionId=abc123 │
```

### 3-2. 인증이 필요한 요청

```
클라이언트                         서버
    │                               │
    │── GET /dashboard ────────────→│
    │   Cookie: sessionId=abc123    │
    │                               │ 1. 쿠키에서 세션 ID 추출
    │                               │ 2. 세션 저장소 조회
    │                               │    → { userId: 1, role: "user" } 확인
    │← 200 OK (대시보드 데이터) ─── │
```

### 3-3. 로그아웃 (세션 삭제)

```
클라이언트                         서버
    │                               │
    │── POST /logout ──────────────→│
    │   Cookie: sessionId=abc123    │
    │                               │ 1. 세션 저장소에서 "abc123" 삭제
    │← 200 OK ──────────────────── │
    │  Set-Cookie: sessionId=; Max-Age=0  │
```

### Express.js 세션 구현 예시

```javascript
const express = require('express');
const session = require('express-session');

const app = express();

app.use(session({
  secret: process.env.SESSION_SECRET,  // 세션 서명 키
  resave: false,           // 변경 없으면 저장 안 함
  saveUninitialized: false, // 초기화 전까지 저장 안 함
  cookie: {
    httpOnly: true,  // JS 접근 차단
    secure: true,    // HTTPS에서만 전송
    sameSite: 'lax', // CSRF 방어
    maxAge: 1000 * 60 * 60 * 24, // 24시간
  },
}));

app.post('/login', (req, res) => {
  const { id, password } = req.body;
  // 자격증명 확인 후...
  req.session.userId = user.id;
  req.session.role = user.role;
  res.json({ message: '로그인 성공' });
});

app.post('/logout', (req, res) => {
  req.session.destroy((err) => {
    res.clearCookie('connect.sid');
    res.json({ message: '로그아웃 성공' });
  });
});
```

---

## 4. 쿠키 속성 상세

쿠키는 세션 ID를 클라이언트에 안전하게 저장하기 위한 핵심 수단입니다.

```
Set-Cookie: sessionId=abc123; HttpOnly; Secure; SameSite=Lax; Path=/; Domain=example.com; Expires=...
```

### 4-1. HttpOnly

```
HttpOnly가 없을 때:
  document.cookie  →  "sessionId=abc123" 반환 (XSS 공격에 노출)

HttpOnly가 있을 때:
  document.cookie  →  "" 반환 (JS에서 접근 불가)
```

JavaScript에서 접근할 수 없으므로 XSS(Cross-Site Scripting) 공격으로 세션 ID를 탈취하는 것을 방지합니다.

### 4-2. Secure

HTTPS 연결에서만 쿠키를 전송합니다. HTTP 연결에서는 전송되지 않아 네트워크 스니핑을 방어합니다.

### 4-3. SameSite

CSRF(Cross-Site Request Forgery) 공격을 방어합니다.

| 값 | 동작 |
|----|------|
| `Strict` | 같은 사이트 요청에서만 전송 (다른 사이트 링크 클릭 시도 미전송) |
| `Lax` | 같은 사이트 + 상위 레벨 GET 요청에서 전송 (기본값, 권장) |
| `None` | 모든 요청에서 전송 (반드시 Secure와 함께 사용) |

### 4-4. 나머지 속성

| 속성 | 설명 | 예시 |
|------|------|------|
| `Path` | 쿠키 전송 경로 제한 | `Path=/api` |
| `Domain` | 쿠키 유효 도메인 | `Domain=example.com` |
| `Expires` | 절대 만료 시각 | `Expires=Wed, 01 Jan 2025 00:00:00 GMT` |
| `Max-Age` | 상대 만료 시간(초) | `Max-Age=86400` (1일) |

---

## 5. 세션 저장소: 메모리 vs Redis

### 5-1. 메모리 저장 (단일 서버)

```
서버 프로세스 메모리
┌─────────────────────────────┐
│  세션 저장소                │
│  { "abc123": { userId: 1 } }│
│  { "def456": { userId: 2 } }│
└─────────────────────────────┘
```

문제점: 서버 재시작 시 세션 소멸, 다중 서버 환경에서 세션 공유 불가

### 5-2. Redis 세션 저장 (분산 서버 환경)

```
          로드 밸런서
         /           \
    서버 A            서버 B
       \               /
        \             /
         Redis 서버
     (공유 세션 저장소)
     { "abc123": ... }
```

어떤 서버로 요청이 라우팅되어도 Redis에서 동일한 세션을 조회할 수 있습니다.

```javascript
const RedisStore = require('connect-redis').default;
const { createClient } = require('redis');

const redisClient = createClient({ url: process.env.REDIS_URL });
await redisClient.connect();

app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
}));
```

---

## 6. 세션 하이재킹 공격과 방어

### 공격 시나리오

```
1. 공격자가 네트워크 스니핑 또는 XSS로 세션 ID 탈취
   → Cookie: sessionId=abc123

2. 공격자가 탈취한 세션 ID로 요청
   → 서버는 정상 사용자로 오인
```

### 방어 방법

| 방어 수단 | 설명 |
|-----------|------|
| **HttpOnly + Secure** | XSS 탈취 차단, HTTPS 전송 강제 |
| **세션 ID 재발급** | 로그인 성공 시 새 세션 ID 발급 (세션 고정 공격 방어) |
| **짧은 세션 만료** | 탈취된 세션의 유효 기간 최소화 |
| **IP/User-Agent 검증** | 세션 생성 시 기록, 이후 요청과 비교 (UX 주의) |
| **HTTPS 강제** | 네트워크 도청 차단 |

```javascript
// 로그인 성공 시 세션 고정 공격 방어: 세션 재생성
app.post('/login', (req, res) => {
  authenticateUser(req.body, (user) => {
    req.session.regenerate((err) => { // 새 세션 ID 발급
      req.session.userId = user.id;
      res.json({ message: '로그인 성공' });
    });
  });
});
```

---

## 7. 세션 vs JWT 비교

| 항목 | 세션 | JWT |
|------|------|-----|
| 상태 저장 위치 | 서버 (저장소 필요) | 클라이언트 (토큰 자체) |
| 확장성 | 분산 환경에서 Redis 등 필요 | 서버 상태 불필요 (Stateless) |
| 무효화 | 즉시 가능 (서버에서 삭제) | 어려움 (만료 전까지 유효) |
| 보안 | 서버가 제어 | 토큰 탈취 시 위험 |
| 크기 | 세션 ID만 전송 (작음) | 토큰 전체 전송 (큼) |
| 적합한 상황 | 일반 웹 앱, 즉시 로그아웃 필요 | 마이크로서비스, 모바일 API |

---

## 8. 면접 포인트

**Q. HTTP는 Stateless인데 로그인 상태를 어떻게 유지하나요?**

> 서버가 세션 저장소에 사용자 상태를 저장하고, 클라이언트에 세션 ID를 쿠키로 발급합니다. 이후 요청마다 쿠키의 세션 ID로 저장소를 조회해 상태를 복원합니다.

**Q. 세션 하이재킹을 어떻게 방어하나요?**

> HttpOnly로 JS 접근을 차단하고, Secure로 HTTPS 전송을 강제합니다. 로그인 시 세션 ID를 재발급(regenerate)해 세션 고정 공격도 방어합니다.

**Q. 쿠키의 SameSite 속성이 왜 중요한가요?**

> CSRF 공격을 방어합니다. `Lax` 설정 시 외부 사이트에서 시작된 POST 요청에는 쿠키가 전송되지 않아 의도치 않은 요청을 차단할 수 있습니다.

**Q. 분산 서버 환경에서 세션을 어떻게 관리하나요?**

> 메모리 대신 Redis와 같은 공유 저장소에 세션을 저장합니다. 어느 서버로 요청이 라우팅되어도 동일한 세션 데이터를 조회할 수 있습니다.

**Q. 세션을 선택할지 JWT를 선택할지 기준은?**

> 즉시 로그아웃/무효화가 중요하면 세션, 서버 Stateless 유지와 마이크로서비스 환경이면 JWT를 선택합니다. 대부분의 전통적인 웹 앱에서는 세션이 더 단순하고 안전합니다.
