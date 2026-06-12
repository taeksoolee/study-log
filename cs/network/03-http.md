# 3. HTTP

## 목차
1. HTTP 버전별 진화
2. HTTP 헤더
3. HTTP 상태 코드
4. HTTP 캐싱
5. 쿠키 (Cookie)
6. HTTPS와 TLS
7. 면접 포인트

---

## 1. HTTP 버전별 진화

### HTTP/0.9 (1991)
- GET 메서드만 지원
- HTML 파일만 전송

### HTTP/1.0 (1996)
- 요청마다 새로운 TCP 연결 수립 후 종료
- 헤더 도입 (Content-Type 등)
- POST, HEAD 메서드 추가

```
문제: 연결마다 3-way handshake + TLS handshake 오버헤드
     이미지 10개면 10번의 TCP 연결
```

### HTTP/1.1 (1997, 현재도 널리 사용)

```
HTTP/1.0의 문제 해결:
  - Keep-Alive: TCP 연결 재사용 (기본 활성화)
  - 파이프라이닝(Pipelining): 응답 기다리지 않고 여러 요청 전송
    → 단, HOL(Head-of-Line) Blocking 문제

HOL Blocking:
  요청: [A][B][C] 순서로 파이프라이닝
  응답: [A가 느리면] [A 대기][B 대기][C 대기]
  → A가 블로킹되면 B, C도 대기

추가 기능:
  - 청크 전송(Chunked Transfer Encoding): Content-Length 없이 스트리밍
  - Host 헤더 필수: 가상 호스팅 가능 (하나의 IP, 여러 도메인)
  - 조건부 요청: If-Modified-Since, ETag
  - 범위 요청: Range 헤더 (동영상 탐색)
  - 캐시 제어: Cache-Control 헤더
```

### HTTP/2 (2015)

```
핵심: 바이너리 프레이밍 + 멀티플렉싱

1. 바이너리 프로토콜:
   텍스트 기반 → 바이너리 프레임 단위
   더 효율적인 파싱, 오류 감소

2. 멀티플렉싱 (Multiplexing):
   하나의 TCP 연결에서 여러 스트림 동시 처리
   각 요청이 독립 스트림 → HOL Blocking 해결 (L7 레벨)

   Stream 1: [요청 A] ─────────────────── [응답 A]
   Stream 2:    [요청 B] ──── [응답 B]
   Stream 3:       [요청 C] ──────── [응답 C]
   (하나의 TCP 연결에서 동시에)

3. 헤더 압축 (HPACK):
   중복 헤더 테이블로 압축
   Cookie, User-Agent 같은 큰 헤더 재전송 비용 감소

4. 서버 푸시 (Server Push):
   클라이언트 요청 없이 서버가 미리 리소스 전송
   HTML 응답 시 CSS, JS를 미리 푸시

5. 스트림 우선순위:
   중요한 리소스에 높은 우선순위 부여

단점: TCP 레벨 HOL Blocking 잔존
  패킷 손실 시 TCP는 전체 스트림 대기
```

### HTTP/3 (2022, 표준화)

```
핵심: QUIC 프로토콜 (UDP 기반)

1. QUIC (Quick UDP Internet Connections):
   TCP 대신 UDP 기반 → OS 커널 의존도 낮음
   애플리케이션 레벨에서 신뢰성, 혼잡제어 구현

2. TCP HOL Blocking 완전 해결:
   스트림별 독립 재전송
   한 스트림의 패킷 손실이 다른 스트림에 영향 없음

3. 0-RTT 연결 재개:
   이전 연결 정보 캐시 → 재연결 시 핸드셰이크 없이 데이터 전송
   (HTTP/2는 최소 1-RTT, TLS 포함 2-RTT)

4. 연결 마이그레이션 (Connection Migration):
   IP 변경 시 연결 유지 (Connection ID 기반)
   Wi-Fi → 4G 전환 시 끊김 없음

5. 내장 TLS 1.3:
   별도 TLS 핸드셰이크 불필요, QUIC에 통합

HTTP/1.1, 2 vs HTTP/3:
  기반 전송: TCP        → UDP(QUIC)
  TLS:       별도        → 내장
  HOL:       있음(2는 부분 해결) → 없음
  재연결:    1~2 RTT    → 0-RTT 가능
```

---

## 2. HTTP 헤더

### 요청 헤더 (Request Headers)

```http
GET /api/users/123 HTTP/1.1
Host: api.example.com
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) ...
Accept: application/json
Accept-Language: ko-KR,ko;q=0.9,en-US;q=0.8
Accept-Encoding: gzip, deflate, br
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
Content-Type: application/json
Content-Length: 45
Cache-Control: no-cache
Referer: https://www.example.com/users
Origin: https://www.example.com
Cookie: session=abc123; theme=dark
If-None-Match: "etag-value-123"
If-Modified-Since: Wed, 21 Oct 2025 07:28:00 GMT
Range: bytes=0-1023
Connection: keep-alive
```

### 응답 헤더 (Response Headers)

```http
HTTP/1.1 200 OK
Content-Type: application/json; charset=UTF-8
Content-Length: 1234
Content-Encoding: gzip
Cache-Control: public, max-age=3600, stale-while-revalidate=600
ETag: "abc123def456"
Last-Modified: Tue, 20 Oct 2025 14:00:00 GMT
Expires: Thu, 22 Oct 2025 14:00:00 GMT
Location: /api/users/456        (3xx 리다이렉트 시)
Set-Cookie: session=xyz; Path=/; HttpOnly; Secure; SameSite=Strict
Access-Control-Allow-Origin: https://www.example.com
Access-Control-Allow-Methods: GET, POST, PUT, DELETE
Vary: Accept-Encoding, Accept-Language
X-Request-ID: req-abc-123
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'self'
```

### CORS 관련 헤더

```http
# Preflight 요청 (OPTIONS)
OPTIONS /api/data HTTP/1.1
Origin: https://app.example.com
Access-Control-Request-Method: POST
Access-Control-Request-Headers: Authorization, Content-Type

# Preflight 응답
HTTP/1.1 204 No Content
Access-Control-Allow-Origin: https://app.example.com
Access-Control-Allow-Methods: GET, POST, PUT
Access-Control-Allow-Headers: Authorization, Content-Type
Access-Control-Max-Age: 86400   ← Preflight 캐시 시간 (초)
```

---

## 3. HTTP 상태 코드

### 1xx - 정보

| 코드 | 의미 |
|------|------|
| 100 Continue | 요청 헤더 받음, 본문 계속 전송 가능 |
| 101 Switching Protocols | WebSocket 업그레이드 시 |

### 2xx - 성공

| 코드 | 의미 | 용도 |
|------|------|------|
| 200 OK | 성공 | GET, POST 일반 성공 |
| 201 Created | 리소스 생성됨 | POST로 생성 성공, Location 헤더 포함 |
| 204 No Content | 성공, 응답 본문 없음 | DELETE, PUT 성공 후 내용 없을 때 |
| 206 Partial Content | 부분 내용 | Range 요청 응답 (동영상 스트리밍) |

### 3xx - 리다이렉션

| 코드 | 의미 | 특징 |
|------|------|------|
| 301 Moved Permanently | 영구 이동 | 브라우저가 새 URL 캐시, POST→GET 변환 |
| 302 Found | 임시 이동 | POST→GET 변환 (비표준이지만 관행) |
| 303 See Other | 다른 URL 보기 | POST 후 GET으로 리다이렉트 (PRG 패턴) |
| 304 Not Modified | 변경 없음 | 캐시 사용 지시 |
| 307 Temporary Redirect | 임시 이동 | 메서드 유지 (POST→POST) |
| 308 Permanent Redirect | 영구 이동 | 메서드 유지 (POST→POST) |

### 4xx - 클라이언트 오류

| 코드 | 의미 |
|------|------|
| 400 Bad Request | 잘못된 요청 문법 |
| 401 Unauthorized | 인증 필요 (로그인 안 됨) |
| 403 Forbidden | 권한 없음 (인증은 됐지만 접근 거부) |
| 404 Not Found | 리소스 없음 |
| 405 Method Not Allowed | 허용되지 않는 HTTP 메서드 |
| 409 Conflict | 리소스 충돌 (중복 생성 등) |
| 410 Gone | 영구 삭제됨 |
| 422 Unprocessable Entity | 유효성 검사 실패 |
| 429 Too Many Requests | 요청 횟수 초과 (Rate Limiting) |

### 5xx - 서버 오류

| 코드 | 의미 |
|------|------|
| 500 Internal Server Error | 서버 내부 오류 |
| 501 Not Implemented | 서버가 해당 기능 미구현 |
| 502 Bad Gateway | 프록시/게이트웨이 오류 |
| 503 Service Unavailable | 서버 과부하 또는 점검 중 |
| 504 Gateway Timeout | 프록시 응답 타임아웃 |

---

## 4. HTTP 캐싱

### Cache-Control 헤더

```http
# 응답에서 캐시 지시
Cache-Control: max-age=3600          # 3600초 동안 유효 (신선도)
Cache-Control: s-maxage=86400        # 공유 캐시(CDN) 유효 시간
Cache-Control: no-cache              # 캐시하되 재검증 필요 (ETag 사용)
Cache-Control: no-store              # 캐시 금지 (개인정보 등)
Cache-Control: private               # 브라우저만 캐시 (CDN 금지)
Cache-Control: public                # 공유 캐시 허용
Cache-Control: must-revalidate       # 만료 후 반드시 재검증
Cache-Control: stale-while-revalidate=600  # 만료 후 600초간 오래된 캐시 사용하면서 백그라운드 갱신
Cache-Control: immutable             # 변경 없음 보장 (버전 포함 파일명에 유용)
```

### ETag와 조건부 요청

```http
# 1. 최초 요청
GET /api/posts/1 HTTP/1.1

# 1. 응답
HTTP/1.1 200 OK
ETag: "abc123"
Last-Modified: Tue, 20 Oct 2025 14:00:00 GMT
Cache-Control: no-cache
[응답 본문]

# 2. 재요청 (캐시 검증)
GET /api/posts/1 HTTP/1.1
If-None-Match: "abc123"
If-Modified-Since: Tue, 20 Oct 2025 14:00:00 GMT

# 2a. 변경 없으면 (304 - 본문 없음, 빠름)
HTTP/1.1 304 Not Modified
ETag: "abc123"

# 2b. 변경 있으면 (200 - 새 내용 전달)
HTTP/1.1 200 OK
ETag: "xyz789"
[새 응답 본문]
```

### 캐시 버스팅 (Cache Busting)

```html
<!-- 파일 내용 해시를 파일명에 포함 → 변경 시 URL 변경 → 즉시 새 파일 요청 -->
<link rel="stylesheet" href="/static/app.a1b2c3d4.css">
<script src="/static/app.e5f6g7h8.js"></script>

<!-- Cache-Control: max-age=31536000, immutable (1년 캐시) -->
<!-- 빌드 시마다 해시가 바뀌므로 항상 최신 파일 보장 -->
```

---

## 5. 쿠키 (Cookie)

```http
# 서버 → 클라이언트: 쿠키 설정
Set-Cookie: session=abc123; Path=/; Domain=example.com; Max-Age=3600; HttpOnly; Secure; SameSite=Strict

# 클라이언트 → 서버: 쿠키 전송 (자동)
Cookie: session=abc123; theme=dark; lang=ko
```

### 쿠키 속성

| 속성 | 설명 |
|------|------|
| `Path=/` | 해당 경로와 하위 경로에서만 전송 |
| `Domain=example.com` | 해당 도메인(서브도메인 포함)에 전송 |
| `Max-Age=3600` | 만료까지 초 단위 (0이면 즉시 삭제) |
| `Expires=날짜` | 만료 날짜 (없으면 세션 쿠키) |
| `HttpOnly` | JS에서 접근 불가 (XSS 방어) |
| `Secure` | HTTPS에서만 전송 |
| `SameSite=Strict` | 동일 사이트 요청에서만 전송 (CSRF 방어) |
| `SameSite=Lax` | 안전한 크로스 사이트 GET에서는 전송 |
| `SameSite=None; Secure` | 모든 크로스 사이트에서 전송 (서드파티 쿠키) |

### 쿠키 vs Web Storage

| | Cookie | localStorage | sessionStorage |
|--|--------|--------------|----------------|
| 서버 전송 | 자동 | 수동 | 수동 |
| 용량 | ~4KB | ~5-10MB | ~5MB |
| 만료 | 설정 가능 | 영구 | 탭 닫으면 삭제 |
| 접근 | JS+HTTP | JS | JS |
| 보안 | HttpOnly 옵션 | JS만 | JS만 |

---

## 6. HTTPS와 TLS

### TLS 1.3 Handshake 흐름

```
클라이언트                                 서버
    │                                        │
    │──── ClientHello ─────────────────────▶│
    │   TLS 버전, 지원 암호화 스위트          │
    │   Client Random, 키 교환 파라미터       │
    │                                        │
    │ ◀── ServerHello + EncryptedExtensions ─│
    │   선택된 암호화 스위트, Server Random   │
    │   서버 인증서, 서버 공개키              │
    │                                        │
    │   [클라이언트: 인증서 검증]             │
    │   - 루트 CA까지 체인 검증              │
    │   - 만료일 확인                        │
    │   - 폐기 확인 (OCSP/CRL)              │
    │                                        │
    │──── Finished ────────────────────────▶│
    │   (대칭키로 암호화됨)                  │
    │                                        │
    ║══════ 대칭키로 암호화된 HTTP 통신 ══════║
```

### 인증서 체인 (Certificate Chain)

```
서버 인증서 (www.example.com)
    ↑ 서명
중간 CA 인증서 (DigiCert TLS RSA SHA256 2020 CA1)
    ↑ 서명
루트 CA 인증서 (DigiCert Global Root CA)
    ← 브라우저/OS에 내장된 신뢰 앵커
```

### 암호화 알고리즘

```
TLS 1.3 필수 지원 암호화 스위트:
  TLS_AES_256_GCM_SHA384
  TLS_CHACHA20_POLY1305_SHA256
  TLS_AES_128_GCM_SHA256

구성:
  키 교환: ECDHE (Elliptic Curve Diffie-Hellman Ephemeral)
           → Perfect Forward Secrecy 보장 (세션키 유출이 과거 통신 노출 없음)
  인증:    RSA 또는 ECDSA
  대칭 암호화: AES-GCM 또는 ChaCha20-Poly1305
  해시:    SHA-256 또는 SHA-384
```

### HSTS (HTTP Strict Transport Security)

```http
# 응답 헤더
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload

효과:
  - 한 번 방문 후 설정 기간 동안 브라우저가 항상 HTTPS 사용
  - HTTP 요청도 브라우저가 자동으로 HTTPS로 업그레이드
  - preload: HSTS Preload List에 등록하면 첫 방문도 HTTPS
```

---

## 7. 면접 포인트

### Q1. HTTP/1.1, HTTP/2, HTTP/3의 가장 큰 차이점은?

HTTP/1.1은 TCP 연결당 하나의 요청만 처리하며(파이프라이닝은 HOL blocking 문제), HTTP/2는 멀티플렉싱으로 하나의 TCP 연결에서 여러 요청을 동시 처리하지만 TCP 레벨 HOL blocking이 남아있습니다. HTTP/3은 UDP 기반 QUIC을 사용해 스트림별 독립 재전송으로 HOL blocking을 완전히 제거하고 0-RTT 재연결, 연결 마이그레이션을 지원합니다.

### Q2. 401 Unauthorized와 403 Forbidden의 차이는?

401은 인증(Authentication) 실패입니다. "당신이 누구인지 모릅니다. 로그인 하세요." 403은 인가(Authorization) 실패입니다. "당신이 누구인지는 알지만, 이 리소스에 접근할 권한이 없습니다."

### Q3. ETag와 Last-Modified 중 어떤 것이 더 정확한가요?

ETag가 더 정확합니다. Last-Modified는 1초 단위라 1초 내 여러 번 변경 시 감지 못합니다. 또한 내용이 같아도 타임스탬프가 다를 수 있습니다. ETag는 콘텐츠 해시 기반이므로 내용이 실제로 변경되었을 때만 달라집니다. 다만 ETag 생성 비용과 로드 밸런서 환경에서 서버마다 다른 ETag를 생성하는 문제가 있어 함께 사용하는 경우도 많습니다.

### Q4. `SameSite=Lax`와 `SameSite=Strict`의 차이는?

`Strict`는 다른 사이트에서 오는 모든 요청에 쿠키를 전송하지 않습니다. 외부 링크 클릭으로 사이트에 접근할 때도 쿠키가 없어 로그아웃 상태로 보입니다. `Lax`는 외부에서 링크 클릭(탐색 목적의 GET 요청)에는 쿠키를 전송하지만, `<img>` 태그나 폼 POST 같은 서브 리소스 요청에는 전송하지 않습니다. 세션 쿠키의 기본값으로 `Lax`가 많이 사용됩니다.

### Q5. HTTPS에서 Man-in-the-Middle 공격은 어떻게 방지하나요?

TLS 인증서 체인 검증으로 방지합니다. 서버의 인증서가 신뢰할 수 있는 CA에 의해 서명되었는지 확인하고, 인증서의 도메인이 접속 도메인과 일치하는지 확인합니다. 중간자가 가짜 인증서를 제시하면 브라우저가 CA 서명 검증에서 실패합니다. 추가로 HSTS, Certificate Pinning, HPKP(폐기됨) 등으로 더욱 강화할 수 있습니다.
