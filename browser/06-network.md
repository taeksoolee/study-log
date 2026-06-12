# 6. 네트워크 (HTTP/HTTPS, WebSocket, SSE, CORS)

## 목차
1. HTTP vs HTTPS
2. HTTP 메서드
3. 주요 상태코드
4. WebSocket
5. SSE (Server-Sent Events)
6. CORS
7. 면접 포인트

---

## 1. HTTP vs HTTPS

### HTTP (HyperText Transfer Protocol)
- 클라이언트와 서버 간 데이터를 주고받는 프로토콜
- 평문(Plain Text) 전송 → 도청, 변조에 취약
- 기본 포트: **80**

### HTTPS (HTTP Secure)
- HTTP에 **TLS(Transport Layer Security)** 암호화 계층을 추가한 프로토콜
- 데이터 암호화, 서버 인증, 무결성 보장
- 기본 포트: **443**

### TLS/SSL 핸드셰이크 과정

```
Client                                 Server
  |                                      |
  |------ ClientHello -----------------> |  (지원 TLS 버전, 암호화 방식 목록)
  |                                      |
  |<----- ServerHello ------------------|  (선택된 TLS 버전, 암호화 방식)
  |<----- Certificate ------------------|  (서버 인증서, 공개키 포함)
  |<----- ServerHelloDone --------------|
  |                                      |
  |------ ClientKeyExchange -----------> |  (Pre-Master Secret, 서버 공개키로 암호화)
  |------ ChangeCipherSpec -----------> |
  |------ Finished -------------------> |  (핸드셰이크 완료, 대칭키 암호화 시작)
  |                                      |
  |<----- ChangeCipherSpec -------------|
  |<----- Finished --------------------|
  |                                      |
  |<===== 암호화된 HTTP 통신 ============>|
```

### HTTP/1.1 vs HTTP/2 vs HTTP/3

| 버전 | 특징 |
|------|------|
| HTTP/1.1 | 텍스트 기반, Keep-Alive, 파이프라이닝(HOL Blocking 문제) |
| HTTP/2 | 바이너리 프레이밍, 멀티플렉싱, 헤더 압축(HPACK), 서버 푸시 |
| HTTP/3 | QUIC(UDP 기반), 0-RTT 연결, 연결 마이그레이션 |

---

## 2. HTTP 메서드

### 메서드 비교표

| 메서드 | 용도 | 멱등성 | 안전성 | 바디 |
|--------|------|--------|--------|------|
| GET | 리소스 조회 | O | O | X |
| POST | 리소스 생성 | X | X | O |
| PUT | 리소스 전체 교체 | O | X | O |
| PATCH | 리소스 부분 수정 | X | X | O |
| DELETE | 리소스 삭제 | O | X | X |
| OPTIONS | 지원 메서드 확인 | O | O | X |
| HEAD | 응답 헤더만 조회 | O | O | X |

> **멱등성(Idempotent)**: 동일한 요청을 여러 번 보내도 결과가 동일
> **안전성(Safe)**: 서버 상태를 변경하지 않음

### 코드 예제

```javascript
const BASE_URL = 'https://api.example.com';

// GET - 리소스 조회
async function getUser(id) {
  const res = await fetch(`${BASE_URL}/users/${id}`);
  return res.json();
}

// POST - 리소스 생성
async function createUser(data) {
  const res = await fetch(`${BASE_URL}/users`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  return res.json();
}

// PUT - 리소스 전체 교체
async function replaceUser(id, data) {
  const res = await fetch(`${BASE_URL}/users/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  return res.json();
}

// PATCH - 리소스 부분 수정
async function updateUser(id, partialData) {
  const res = await fetch(`${BASE_URL}/users/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(partialData),
  });
  return res.json();
}

// DELETE - 리소스 삭제
async function deleteUser(id) {
  const res = await fetch(`${BASE_URL}/users/${id}`, {
    method: 'DELETE',
  });
  return res.status === 204; // No Content
}
```

---

## 3. 주요 상태코드

### 2xx - 성공

| 코드 | 이름 | 설명 |
|------|------|------|
| 200 | OK | 요청 성공 |
| 201 | Created | 리소스 생성 성공 (POST, PUT) |
| 204 | No Content | 성공했지만 응답 바디 없음 (DELETE) |
| 206 | Partial Content | 범위 요청 성공 |

### 3xx - 리다이렉트

| 코드 | 이름 | 설명 |
|------|------|------|
| 301 | Moved Permanently | 영구 리다이렉트 (GET으로 변경됨) |
| 302 | Found | 임시 리다이렉트 |
| 304 | Not Modified | 캐시된 리소스 사용 (조건부 요청) |
| 307 | Temporary Redirect | 임시 리다이렉트 (메서드 유지) |
| 308 | Permanent Redirect | 영구 리다이렉트 (메서드 유지) |

### 4xx - 클라이언트 오류

| 코드 | 이름 | 설명 |
|------|------|------|
| 400 | Bad Request | 잘못된 요청 |
| 401 | Unauthorized | 인증 필요 |
| 403 | Forbidden | 인가 실패 (권한 없음) |
| 404 | Not Found | 리소스 없음 |
| 405 | Method Not Allowed | 허용되지 않은 메서드 |
| 409 | Conflict | 리소스 충돌 |
| 422 | Unprocessable Entity | 의미론적 오류 |
| 429 | Too Many Requests | 속도 제한 초과 |

### 5xx - 서버 오류

| 코드 | 이름 | 설명 |
|------|------|------|
| 500 | Internal Server Error | 서버 내부 오류 |
| 502 | Bad Gateway | 게이트웨이 오류 |
| 503 | Service Unavailable | 서비스 불가 (과부하/점검) |
| 504 | Gateway Timeout | 게이트웨이 타임아웃 |

---

## 4. WebSocket

### 개념
- HTTP를 통해 초기 핸드셰이크 후, **지속적인 양방향 통신** 채널을 유지
- 서버가 클라이언트에게 먼저 메시지를 보낼 수 있음 (Push)
- 실시간 채팅, 게임, 주식 시세 등에 활용

### 연결 과정

```
Client                          Server
  |                                |
  |-- HTTP Upgrade 요청 ---------->|  Upgrade: websocket
  |<-- 101 Switching Protocols ----|
  |                                |
  |<========= 양방향 통신 =========>|
  |                                |
  |-- Close Frame ---------------->|
  |<-- Close Frame ----------------|
```

### 코드 예제

```javascript
// --- 클라이언트 ---
const ws = new WebSocket('wss://chat.example.com/ws');

// 연결 이벤트
ws.addEventListener('open', () => {
  console.log('WebSocket 연결됨');
  ws.send(JSON.stringify({ type: 'join', room: 'general' }));
});

// 메시지 수신
ws.addEventListener('message', (event) => {
  const data = JSON.parse(event.data);
  console.log('수신:', data);
});

// 에러 처리
ws.addEventListener('error', (error) => {
  console.error('WebSocket 오류:', error);
});

// 연결 종료
ws.addEventListener('close', (event) => {
  console.log(`연결 종료: code=${event.code}, reason=${event.reason}`);
});

// 메시지 전송
function sendMessage(message) {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify({ type: 'message', content: message }));
  }
}

// 연결 종료
function disconnect() {
  ws.close(1000, '정상 종료');
}

// --- 재연결 로직 (Exponential Backoff) ---
class WebSocketManager {
  constructor(url) {
    this.url = url;
    this.retryDelay = 1000;
    this.maxDelay = 30000;
    this.connect();
  }

  connect() {
    this.ws = new WebSocket(this.url);

    this.ws.addEventListener('open', () => {
      this.retryDelay = 1000; // 성공 시 딜레이 초기화
    });

    this.ws.addEventListener('close', () => {
      setTimeout(() => {
        this.retryDelay = Math.min(this.retryDelay * 2, this.maxDelay);
        this.connect();
      }, this.retryDelay);
    });
  }
}
```

---

## 5. SSE (Server-Sent Events)

### 개념
- 서버에서 클라이언트로 **단방향** 실시간 스트리밍
- HTTP 연결을 유지하며 서버가 이벤트를 지속적으로 전송
- 자동 재연결 내장, 이벤트 ID 지원
- AI 응답 스트리밍, 알림, 실시간 로그에 적합

### WebSocket vs SSE 비교

| 특성 | WebSocket | SSE |
|------|-----------|-----|
| 방향 | 양방향 | 단방향 (서버 → 클라이언트) |
| 프로토콜 | ws:// / wss:// | HTTP/HTTPS |
| 재연결 | 직접 구현 | 자동 |
| 데이터 형식 | 바이너리/텍스트 | 텍스트(UTF-8) |
| 브라우저 지원 | 넓음 | 넓음 (IE 제외) |

### 코드 예제

```javascript
// --- 클라이언트 ---
const eventSource = new EventSource('https://api.example.com/stream');

// 기본 메시지 수신
eventSource.addEventListener('message', (event) => {
  console.log('데이터:', event.data);
  console.log('이벤트 ID:', event.lastEventId);
});

// 커스텀 이벤트 수신
eventSource.addEventListener('update', (event) => {
  const data = JSON.parse(event.data);
  console.log('업데이트:', data);
});

// 에러 처리
eventSource.addEventListener('error', (event) => {
  if (event.readyState === EventSource.CLOSED) {
    console.log('연결 종료됨');
  }
});

// 연결 종료
function stopStream() {
  eventSource.close();
}

// --- 서버 (Node.js Express) ---
app.get('/stream', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');

  let count = 0;
  const interval = setInterval(() => {
    // id 필드: 재연결 시 마지막 수신 ID 서버에 전달 (Last-Event-ID 헤더)
    res.write(`id: ${count}\n`);
    // event 필드: 커스텀 이벤트 이름
    res.write(`event: update\n`);
    // data 필드: 전송할 데이터 (\n\n으로 이벤트 종료)
    res.write(`data: ${JSON.stringify({ count, time: Date.now() })}\n\n`);
    count++;
  }, 1000);

  req.on('close', () => clearInterval(interval));
});
```

---

## 6. CORS (Cross-Origin Resource Sharing)

### 개념
- 브라우저의 **동일 출처 정책(SOP)** 으로 인해 다른 출처(Origin)의 리소스 접근이 기본 차단됨
- **Origin** = `프로토콜 + 호스트 + 포트` (셋 중 하나라도 다르면 다른 출처)
- CORS는 서버가 응답 헤더를 통해 특정 출처의 접근을 허용하는 메커니즘

### Preflight Request (사전 요청)

```
단순 요청(Simple Request) 조건:
- 메서드: GET, POST, HEAD
- 헤더: Accept, Content-Type(일부), 등 기본 헤더만
- Content-Type: text/plain, multipart/form-data, application/x-www-form-urlencoded

위 조건 미충족 시 → OPTIONS 메서드로 Preflight 요청 선행

Browser                           Server
  |                                  |
  |-- OPTIONS /api/data -----------> |
  |   Origin: https://app.com        |
  |   Access-Control-Request-Method  |
  |   Access-Control-Request-Headers |
  |                                  |
  |<-- 200 OK ---------------------- |
  |   Access-Control-Allow-Origin    |
  |   Access-Control-Allow-Methods   |
  |   Access-Control-Allow-Headers   |
  |   Access-Control-Max-Age: 86400  |  (Preflight 캐시 시간)
  |                                  |
  |-- POST /api/data --------------> |  (실제 요청)
  |<-- 200 OK ---------------------- |
```

### CORS 관련 헤더

```http
# 응답 헤더 (서버 → 클라이언트)
Access-Control-Allow-Origin: https://app.com   # 특정 출처 허용 (* 는 모든 출처)
Access-Control-Allow-Methods: GET, POST, PUT, DELETE
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Allow-Credentials: true          # 쿠키/인증 정보 포함 허용
Access-Control-Max-Age: 86400                   # Preflight 캐시 시간(초)
Access-Control-Expose-Headers: X-Custom-Header  # JS에서 접근 가능한 헤더 목록
```

### 코드 예제 - 해결 방법

```javascript
// 1. 서버 측 CORS 헤더 설정 (Express)
const cors = require('cors');

app.use(cors({
  origin: ['https://app.example.com', 'https://admin.example.com'],
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 86400,
}));

// 2. 클라이언트 - credentials 포함 요청
fetch('https://api.example.com/data', {
  method: 'GET',
  credentials: 'include',  // 쿠키 포함 (서버에서 Allow-Credentials: true 필요)
});

// 3. 개발 환경 - Vite 프록시 설정
// vite.config.js
export default {
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
      },
    },
  },
};

// 4. Next.js - rewrites 활용
// next.config.js
module.exports = {
  async rewrites() {
    return [
      { source: '/api/:path*', destination: 'https://api.example.com/:path*' },
    ];
  },
};
```

---

## 7. 면접 포인트

### Q1. HTTP와 HTTPS의 차이점은 무엇인가요?
HTTP는 평문 전송이라 도청과 변조에 취약합니다. HTTPS는 TLS 암호화 계층을 추가하여 데이터 기밀성, 서버 인증, 무결성을 보장합니다. TLS 핸드셰이크에서 인증서를 통해 서버를 검증하고, 비대칭 키 교환으로 대칭 세션 키를 수립한 뒤 이후 통신은 대칭 암호화로 진행됩니다.

### Q2. GET과 POST의 차이는?
GET은 데이터를 URL 쿼리스트링에 포함하며 안전하고 멱등적입니다. 브라우저/프록시에 캐시됩니다. POST는 요청 바디에 데이터를 담으며 서버 상태를 변경하고 멱등성이 없습니다. 민감한 데이터는 POST를 사용해야 합니다.

### Q3. PUT과 PATCH의 차이는?
PUT은 리소스 전체를 교체합니다 (전달하지 않은 필드는 null/제거). PATCH는 전달한 필드만 부분 수정합니다. PUT은 멱등적이나 PATCH는 구현에 따라 다릅니다.

### Q4. WebSocket과 SSE를 어떤 상황에 사용하나요?
양방향 실시간 통신(채팅, 게임, 협업 도구)에는 WebSocket, 서버에서 클라이언트로의 단방향 스트리밍(알림, AI 응답 스트리밍, 실시간 대시보드)에는 SSE가 적합합니다. SSE는 HTTP 기반이라 방화벽 통과가 용이하고 자동 재연결을 지원합니다.

### Q5. CORS Preflight가 발생하는 조건은?
단순 요청 조건(GET/POST/HEAD, 기본 헤더, 특정 Content-Type)을 벗어날 때 발생합니다. `Authorization` 헤더 포함, `Content-Type: application/json`, PUT/DELETE 메서드 사용 등이 Preflight를 유발합니다. `Access-Control-Max-Age`로 캐시 기간을 설정해 반복 요청을 줄일 수 있습니다.

### Q6. 301과 302 리다이렉트의 차이는?
301(영구)은 브라우저가 새 URL을 캐시하여 이후 요청은 서버를 거치지 않습니다. 원래 메서드가 GET으로 바뀔 수 있습니다. 302(임시)는 캐시되지 않으며 매번 서버에 확인합니다. 메서드 유지가 필요하면 307/308을 사용합니다.
