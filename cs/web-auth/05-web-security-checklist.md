# 5. 웹 보안 체크리스트

## 목차
1. 인증 보안
2. HTTPS & TLS
3. 보안 헤더
4. CORS 올바른 설정
5. 의존성 보안
6. 시크릿 관리
7. 프론트엔드 OWASP Top 10
8. 면접 포인트

---

## 1. 인증 보안

### 1-1. 세션 고정(Session Fixation) 공격

```
공격 흐름:
  1. 공격자가 서버에 접속해 세션 ID 획득: sessionId=ATTACKER_ID
  2. 피해자에게 해당 세션 ID로 로그인 유도
     (URL 파라미터, JS 주입 등으로 쿠키 설정)
  3. 피해자가 로그인하면 공격자의 세션 ID가 인증된 세션이 됨
  4. 공격자가 동일 세션 ID로 피해자 계정 접근
```

방어: 로그인 성공 시 반드시 새 세션 ID를 발급합니다.

```javascript
app.post('/login', (req, res) => {
  // 인증 성공 후
  req.session.regenerate((err) => { // 새 세션 ID 발급!
    req.session.userId = user.id;
    res.json({ message: 'OK' });
  });
});
```

### 1-2. 브루트포스 방어: Rate Limiting

```javascript
const rateLimit = require('express-rate-limit');

// 로그인 엔드포인트: IP당 15분에 5회
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: { error: '너무 많은 로그인 시도입니다. 15분 후 다시 시도하세요.' },
  standardHeaders: true,
  legacyHeaders: false,
  // 실패한 요청만 카운트하려면 skipSuccessfulRequests: true
});

app.post('/login', loginLimiter, loginHandler);
```

계정 잠금 전략:

| 전략 | 설명 | 단점 |
|------|------|------|
| IP 기반 제한 | IP당 N회 초과 시 차단 | VPN, NAT 우회 가능 |
| 계정 기반 잠금 | 계정당 N회 실패 시 잠금 | DoS로 정상 사용자 잠금 가능 |
| CAPTCHA | 실패 N회 후 CAPTCHA 요구 | UX 저하 |
| 점진적 지연 | 실패마다 대기 시간 증가 | 균형적 |

### 1-3. MFA (Multi-Factor Authentication)

```
인증 요소 3가지:
  1. 지식 (Something you know): 비밀번호, PIN
  2. 소지 (Something you have): OTP 기기, 스마트폰
  3. 속성 (Something you are): 지문, 얼굴 인식

MFA = 이 중 2가지 이상 조합
```

TOTP(Time-based OTP) 구현:

```javascript
const speakeasy = require('speakeasy');
const QRCode = require('qrcode');

// 1. 비밀 키 생성 (사용자 등록 시)
const secret = speakeasy.generateSecret({ name: 'MyApp' });
const qrDataUrl = await QRCode.toDataURL(secret.otpauth_url);
// → QR 코드를 사용자에게 표시 (Google Authenticator 등으로 등록)

// 2. OTP 검증 (로그인 시)
const isValid = speakeasy.totp.verify({
  secret: secret.base32,
  encoding: 'base32',
  token: userInputOTP,
  window: 1, // 30초 앞뒤 허용
});
```

---

## 2. HTTPS & TLS

### 2-1. HTTPS가 중요한 이유

```
HTTP (평문):
  브라우저 → 네트워크 → 서버
  공격자가 중간에서 패킷 스니핑 → 비밀번호, 세션 ID, 개인정보 탈취

HTTPS (TLS 암호화):
  브라우저 → [암호화된 데이터] → 서버
  공격자가 가로채도 복호화 불가
```

### 2-2. HSTS (HTTP Strict Transport Security)

```
응답 헤더:
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
```

브라우저가 해당 도메인에는 항상 HTTPS로만 접속하도록 강제합니다.
첫 방문 시 HTTP로 접속하면 리다이렉트를 당하기 전에 공격받을 수 있는데 (SSL Stripping), preload 목록에 등록하면 브라우저가 처음부터 HTTPS를 사용합니다.

### 2-3. Let's Encrypt (무료 TLS 인증서)

```bash
# Certbot으로 인증서 발급 (nginx)
certbot --nginx -d example.com -d www.example.com

# 자동 갱신 (90일 만료, cron으로 자동 갱신)
certbot renew --dry-run
```

---

## 3. 보안 헤더

### 헤더 일람

```nginx
# Nginx 보안 헤더 설정 예시
server {
  # Content-Security-Policy
  # 허용된 소스에서만 리소스 로드 (XSS 방어의 핵심)
  add_header Content-Security-Policy "
    default-src 'self';
    script-src  'self' https://cdn.example.com;
    style-src   'self' 'unsafe-inline';
    img-src     'self' data: https:;
    font-src    'self';
    connect-src 'self' https://api.example.com;
    frame-ancestors 'none';
  " always;

  # 클릭재킹 방어 (iframe 삽입 차단)
  add_header X-Frame-Options "DENY" always;

  # MIME 스니핑 방어
  add_header X-Content-Type-Options "nosniff" always;

  # Referrer 정책 (민감한 URL이 외부에 노출 안 되도록)
  add_header Referrer-Policy "strict-origin-when-cross-origin" always;

  # Permissions Policy (카메라, 마이크, 위치 등 기능 제한)
  add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;
}
```

### Content-Security-Policy 상세

```
지시문                설명
─────────────────────────────────────────────────────
default-src 'self'   기본: 현재 도메인에서만 허용
script-src           JS 로드 허용 출처
style-src            CSS 로드 허용 출처
img-src              이미지 로드 허용 출처
connect-src          fetch/XHR 요청 허용 대상
frame-ancestors      iframe에 삽입될 수 있는 출처
report-uri /csp-report  위반 시 리포트 전송 URL
```

### 헤더 검사 도구

- `https://securityheaders.com` — 보안 헤더 점수 확인
- `https://observatory.mozilla.org` — Mozilla 보안 스캐너

---

## 4. CORS 올바른 설정

### CORS란

브라우저의 Same-Origin Policy(동일 출처 정책)를 교차 출처에서도 안전하게 허용하는 메커니즘입니다.

### 잘못된 설정

```javascript
// 절대 하지 말 것
app.use(cors({
  origin: '*',              // 모든 출처 허용 → 인증 요청과 함께 사용하면 위험
  credentials: true,        // Access-Control-Allow-Credentials: true와 함께 *는 에러
}));
```

### 올바른 설정

```javascript
const allowedOrigins = [
  'https://app.example.com',
  'https://www.example.com',
  process.env.NODE_ENV === 'development' ? 'http://localhost:3000' : null,
].filter(Boolean);

app.use(cors({
  origin: (origin, callback) => {
    // origin이 없으면 서버-서버 요청 (Postman 등)
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error(`CORS 차단: ${origin}`));
    }
  },
  credentials: true,           // 쿠키/인증 헤더 허용
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  maxAge: 86400,               // Preflight 캐시 (초)
}));
```

### CORS vs CSRF 차이

```
CORS: 브라우저가 교차 출처 요청을 제어하는 정책
  → 서버가 허용한 출처에서만 브라우저가 응답을 읽을 수 있음
  → 서버로 요청 자체는 이미 전달됨 (GET/POST)

CSRF: 사용자의 인증 정보를 이용한 위조 요청 공격
  → CORS와 별개 — SameSite Cookie로 방어
```

---

## 5. 의존성 보안

### npm audit

```bash
# 취약점 확인
npm audit

# 자동 수정 (minor/patch 범위)
npm audit fix

# 강제 업그레이드 (major 포함, 호환성 테스트 필요)
npm audit fix --force

# JSON 형태로 CI/CD에서 파싱
npm audit --json | jq '.vulnerabilities | length'
```

### GitHub Dependabot

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"     # 매주 PR 생성
    open-pull-requests-limit: 10
    groups:
      dev-dependencies:
        patterns: ["@types/*", "eslint*", "jest*"]
```

### Supply Chain Attack 방어

```bash
# package-lock.json 또는 yarn.lock 반드시 커밋
# → 의존성 버전 고정 (예상치 못한 업데이트 방지)

# npm ci (lock 파일 기준 엄격 설치, CI 권장)
npm ci

# 패키지 출처 확인
npm info <package> | grep -E "maintainers|homepage"
```

---

## 6. 시크릿 관리

### .env 파일 관리

```bash
# .gitignore에 반드시 포함
.env
.env.local
.env.production
.env*.local

# .env.example 파일은 커밋 (키 이름만, 값 없이)
DATABASE_URL=
JWT_SECRET=
GOOGLE_CLIENT_SECRET=
```

### 환경변수 검증

```javascript
// 시작 시 필수 환경변수 확인
const requiredEnvVars = [
  'DATABASE_URL',
  'JWT_SECRET',
  'SESSION_SECRET',
];

requiredEnvVars.forEach((varName) => {
  if (!process.env[varName]) {
    console.error(`환경변수 누락: ${varName}`);
    process.exit(1);
  }
});
```

### 시크릿이 커밋된 경우 대응

```bash
# 1. 즉시 해당 시크릿 교체/폐기 (가장 중요!)
# 2. git 히스토리에서 제거
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .env" \
  --prune-empty --tag-name-filter cat -- --all

# 또는 BFG Repo-Cleaner 사용 (더 빠름)
bfg --delete-files .env
git push origin --force --all
```

---

## 7. 프론트엔드 OWASP Top 10 (웹 앱 관점)

### A01: Broken Access Control

```javascript
// 잘못된 예: 프론트엔드에서만 권한 체크
if (user.role === 'admin') {
  // 실제 API 호출 → 서버에서 권한 확인 안 함
  await deleteUser(userId);
}

// 올바른 예: 서버에서 반드시 권한 검증
// 프론트엔드의 체크는 UX 목적일 뿐
app.delete('/api/users/:id', requireAdmin, deleteUserHandler);
```

### A02: Cryptographic Failures

- 민감 데이터를 localStorage에 저장하지 않기
- HTTPS 강제 (HSTS 적용)
- 비밀번호는 bcrypt/Argon2로 해시

### A03: Injection (XSS 포함)

```javascript
// XSS 방어
// React: JSX는 기본적으로 이스케이프 처리
// dangerouslySetInnerHTML은 사용자 입력에 절대 사용 금지
const safeContent = DOMPurify.sanitize(userInput); // html sanitizer 사용

// SQL Injection 방어: Prepared Statements 사용
// 잘못된 예
db.query(`SELECT * FROM users WHERE id = ${userId}`);
// 올바른 예
db.query('SELECT * FROM users WHERE id = $1', [userId]);
```

### A07: Identification and Authentication Failures

- 브루트포스 방어 (Rate Limiting)
- 약한 비밀번호 거부
- 기본 자격증명 변경
- MFA 지원

### A09: Security Logging and Monitoring Failures

```javascript
// 보안 관련 이벤트 로깅
logger.warn({
  event: 'LOGIN_FAILURE',
  userId: req.body.email,
  ip: req.ip,
  userAgent: req.headers['user-agent'],
  timestamp: new Date().toISOString(),
});

// 알림 설정: 짧은 시간에 다수 로그인 실패 감지
```

---

## 프론트엔드 보안 체크리스트 요약

```
인증/세션
  [ ] 세션 ID는 로그인 시 재발급
  [ ] 쿠키: HttpOnly + Secure + SameSite=Lax
  [ ] 로그인 Rate Limiting 적용
  [ ] 중요 작업에 재인증 요구

토큰
  [ ] JWT Payload에 민감한 정보 없음
  [ ] Access Token 만료 시간 ≤ 1시간
  [ ] Refresh Token은 HttpOnly Cookie에 저장
  [ ] Token Rotation 구현

HTTPS
  [ ] HTTPS 강제 (HTTP → HTTPS 리다이렉트)
  [ ] HSTS 헤더 설정
  [ ] TLS 1.2 이상 사용

보안 헤더
  [ ] Content-Security-Policy 설정
  [ ] X-Frame-Options: DENY
  [ ] X-Content-Type-Options: nosniff
  [ ] Referrer-Policy 설정

입력/출력
  [ ] 사용자 입력 서버 측 검증
  [ ] dangerouslySetInnerHTML 사용 시 DOMPurify 적용
  [ ] SQL/NoSQL Injection: Prepared Statements 사용
  [ ] 파일 업로드: 타입/크기 검증, 저장 경로 분리

의존성/시크릿
  [ ] npm audit 정기 실행 (CI/CD 통합)
  [ ] .env 파일 .gitignore에 포함
  [ ] 환경변수 시작 시 검증
  [ ] 시크릿 관리 도구 사용 (Vault, AWS SSM 등)

CORS
  [ ] 와일드카드(*) 대신 화이트리스트 사용
  [ ] credentials: true 시 명시적 출처 지정
```

---

## 8. 면접 포인트

**Q. XSS와 CSRF의 차이점과 각 방어 방법은?**

> XSS(Cross-Site Scripting)는 공격자가 악성 스크립트를 웹 페이지에 삽입해 피해자 브라우저에서 실행하는 공격입니다. 방어: CSP 헤더, 입력 이스케이프, HttpOnly 쿠키. CSRF(Cross-Site Request Forgery)는 피해자가 인증된 상태에서 공격자 사이트가 의도치 않은 요청을 위조하는 공격입니다. 방어: SameSite 쿠키, CSRF 토큰, Origin 헤더 검증.

**Q. Content-Security-Policy가 무엇이고 왜 중요한가요?**

> CSP는 브라우저에 허용된 리소스 출처를 알려주는 HTTP 응답 헤더입니다. 인라인 스크립트나 외부 도메인에서 로드된 스크립트를 차단해 XSS 공격의 피해를 줄입니다. 공격자가 스크립트를 주입해도 CSP가 허용하지 않은 출처에서는 실행되지 않습니다.

**Q. HTTPS를 사용하면 모든 보안 문제가 해결되나요?**

> 아닙니다. HTTPS는 전송 중 데이터를 암호화해 도청과 중간자 공격을 방어하지만, XSS, CSRF, SQL Injection, 취약한 비밀번호 저장 등의 애플리케이션 레벨 취약점은 별도로 방어해야 합니다.

**Q. 프론트엔드에서 권한 체크를 하면 되지 않나요?**

> 프론트엔드의 권한 체크는 UX 목적으로만 유효합니다. 사용자가 브라우저 개발자 도구로 JS 코드를 수정하거나 직접 API를 호출하면 우회가 가능합니다. 모든 권한 검증은 반드시 서버 측에서 수행해야 합니다.

**Q. Supply Chain Attack이 무엇이고 어떻게 방어하나요?**

> npm 패키지와 같은 서드파티 의존성을 통해 악성 코드가 삽입되는 공격입니다. 2021년 ua-parser-js, 2022년 node-ipc 사례가 있습니다. 방어: package-lock.json 커밋으로 버전 고정, npm audit 정기 실행, Dependabot으로 취약점 업데이트, 신뢰할 수 없는 패키지 최소화, npm ci로 lock 파일 기준 설치.
