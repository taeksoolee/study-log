# 5. WebSocket, SSE, Long Polling

## 목차
1. 실시간 통신의 배경
2. Long Polling
3. WebSocket
4. SSE (Server-Sent Events)
5. 기술 비교
6. 사용 시나리오 선택 기준
7. 면접 포인트

---

## 1. 실시간 통신의 배경

HTTP는 기본적으로 클라이언트가 요청하고 서버가 응답하는 단방향 요청-응답 모델이다. 채팅, 알림, 실시간 대시보드처럼 서버가 능동적으로 데이터를 푸시해야 하는 상황에서는 이 모델이 적합하지 않다.

이를 해결하기 위한 기술이 순서대로 등장했다:

```
Polling → Long Polling → SSE / WebSocket
(낮은 실시간성)              (높은 실시간성)
```

---

## 2. Long Polling

### 개념

클라이언트가 서버에 요청을 보내고, 서버는 새 데이터가 생길 때까지 응답을 보류(hold)한다. 응답을 받으면 클라이언트는 즉시 다음 요청을 보내는 방식으로 실시간성을 흉내낸다.

```
일반 Polling:
클라이언트: "새 메시지 있어?" → 서버: "없음" (즉시 응답)
클라이언트: "새 메시지 있어?" → 서버: "없음" (즉시 응답)
... (일정 간격으로 반복, 불필요한 요청 다수 발생)

Long Polling:
클라이언트: "새 메시지 있어?" → 서버: (대기 중...)
... (새 메시지 도착)
서버: "메시지 있음!" → 클라이언트: (즉시 다음 요청 전송)
```

### 클라이언트 코드 예제 (JavaScript)

```javascript
// Long Polling 클라이언트 구현
async function longPoll(lastMessageId) {
  try {
    const response = await fetch(`/api/messages?after=${lastMessageId}`, {
      signal: AbortSignal.timeout(30000), // 30초 타임아웃
    });

    if (!response.ok) {
      throw new Error(`HTTP error: ${response.status}`);
    }

    const data = await response.json();

    if (data.messages.length > 0) {
      // 새 메시지 처리
      data.messages.forEach((msg) => displayMessage(msg));
      lastMessageId = data.messages.at(-1).id;
    }

    // 즉시 다음 요청 전송
    longPoll(lastMessageId);
  } catch (error) {
    if (error.name === "TimeoutError") {
      // 타임아웃: 재연결
      longPoll(lastMessageId);
    } else {
      // 에러: 잠시 후 재시도
      console.error("Long polling error:", error);
      setTimeout(() => longPoll(lastMessageId), 3000);
    }
  }
}

longPoll(0); // 시작
```

### 서버 코드 예제 (Node.js / Express)

```javascript
const express = require("express");
const app = express();

// 대기 중인 클라이언트 응답 객체 목록
const pendingClients = [];
const messages = [];

// Long Polling 엔드포인트
app.get("/api/messages", (req, res) => {
  const afterId = parseInt(req.query.after) || 0;
  const newMessages = messages.filter((m) => m.id > afterId);

  if (newMessages.length > 0) {
    // 즉시 응답
    return res.json({ messages: newMessages });
  }

  // 새 메시지가 없으면 대기
  const client = { res, afterId };
  pendingClients.push(client);

  // 타임아웃 후 빈 응답 (클라이언트가 재연결하도록)
  const timeout = setTimeout(() => {
    const idx = pendingClients.indexOf(client);
    if (idx !== -1) pendingClients.splice(idx, 1);
    res.json({ messages: [] });
  }, 25000); // 25초

  req.on("close", () => {
    clearTimeout(timeout);
    const idx = pendingClients.indexOf(client);
    if (idx !== -1) pendingClients.splice(idx, 1);
  });
});

// 새 메시지 발행 (내부 API)
app.post("/api/messages", express.json(), (req, res) => {
  const message = { id: messages.length + 1, ...req.body, timestamp: Date.now() };
  messages.push(message);

  // 대기 중인 클라이언트에게 즉시 응답
  pendingClients.forEach(({ res: clientRes, afterId }) => {
    if (message.id > afterId) {
      clientRes.json({ messages: [message] });
    }
  });
  pendingClients.length = 0;

  res.status(201).json(message);
});

app.listen(3000);
```

### 단점

- 각 연결마다 HTTP 오버헤드(헤더) 발생
- 서버가 많은 연결을 동시에 hold해야 하므로 메모리/스레드 소비
- 메시지가 순간적으로 폭발하면 연결 수 급증

---

## 3. WebSocket

### 개념

WebSocket은 HTTP 핸드셰이크 이후 TCP 연결을 유지하며 양방향 전이중(full-duplex) 통신을 제공하는 프로토콜이다. RFC 6455로 표준화되어 있다.

### 핸드셰이크 과정 (HTTP Upgrade)

WebSocket 연결은 HTTP `Upgrade` 요청으로 시작한다.

```
1. 클라이언트 → 서버: HTTP Upgrade 요청

GET /chat HTTP/1.1
Host: server.example.com
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
Sec-WebSocket-Version: 13
Origin: http://example.com

2. 서버 → 클라이언트: 101 Switching Protocols

HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=

3. 이후: TCP 연결 위에서 WebSocket 프레임 송수신 (HTTP 오버헤드 없음)
```

`Sec-WebSocket-Accept`는 `Sec-WebSocket-Key` + 고정 GUID를 SHA-1 해싱한 값으로, 연결 의도를 검증한다.

### 클라이언트 코드 예제 (브라우저)

```javascript
const ws = new WebSocket("wss://server.example.com/chat");

// 연결 수립
ws.addEventListener("open", (event) => {
  console.log("WebSocket 연결됨");
  ws.send(JSON.stringify({ type: "join", room: "general" }));
});

// 메시지 수신
ws.addEventListener("message", (event) => {
  const data = JSON.parse(event.data);
  console.log("수신:", data);
  displayMessage(data);
});

// 에러 처리
ws.addEventListener("error", (event) => {
  console.error("WebSocket 에러:", event);
});

// 연결 종료
ws.addEventListener("close", (event) => {
  console.log(`연결 종료: code=${event.code}, reason=${event.reason}`);
  // 자동 재연결 로직
  setTimeout(() => reconnect(), 3000);
});

// 메시지 전송
function sendMessage(text) {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify({ type: "message", text }));
  }
}

// WebSocket readyState 상수
// WebSocket.CONNECTING = 0
// WebSocket.OPEN       = 1
// WebSocket.CLOSING    = 2
// WebSocket.CLOSED     = 3
```

### 서버 코드 예제 (Node.js / ws 라이브러리)

```javascript
const { WebSocketServer } = require("ws");
const http = require("http");

const server = http.createServer();
const wss = new WebSocketServer({ server });

const rooms = new Map(); // room → Set<WebSocket>

wss.on("connection", (ws, req) => {
  console.log("클라이언트 연결:", req.socket.remoteAddress);

  ws.on("message", (rawData) => {
    const data = JSON.parse(rawData.toString());

    switch (data.type) {
      case "join":
        if (!rooms.has(data.room)) rooms.set(data.room, new Set());
        rooms.get(data.room).add(ws);
        ws.currentRoom = data.room;
        broadcast(data.room, { type: "system", text: "새 유저가 입장했습니다." }, ws);
        break;

      case "message":
        broadcast(ws.currentRoom, { type: "message", text: data.text });
        break;
    }
  });

  ws.on("close", (code, reason) => {
    console.log(`연결 종료: ${code} ${reason}`);
    if (ws.currentRoom) {
      rooms.get(ws.currentRoom)?.delete(ws);
    }
  });

  ws.on("error", (err) => console.error("WebSocket 에러:", err));

  // Heartbeat: 연결 유지 확인
  ws.isAlive = true;
  ws.on("pong", () => { ws.isAlive = true; });
});

// 특정 방에 브로드캐스트
function broadcast(room, data, exclude = null) {
  const clients = rooms.get(room);
  if (!clients) return;
  const message = JSON.stringify(data);
  clients.forEach((client) => {
    if (client !== exclude && client.readyState === 1) {
      client.send(message);
    }
  });
}

// Heartbeat 인터벌 (죽은 연결 감지)
const heartbeat = setInterval(() => {
  wss.clients.forEach((ws) => {
    if (!ws.isAlive) return ws.terminate();
    ws.isAlive = false;
    ws.ping();
  });
}, 30000);

wss.on("close", () => clearInterval(heartbeat));
server.listen(3000);
```

### WebSocket 특징 요약

- 양방향 통신 (클라이언트 ↔ 서버 모두 능동적으로 전송 가능)
- 연결 수립 후 낮은 오버헤드 (최소 2바이트 프레임 헤더)
- TCP 기반, 기본 포트: 80(ws://), 443(wss://)
- 텍스트와 바이너리 데이터 모두 전송 가능

---

## 4. SSE (Server-Sent Events)

### 개념

SSE는 서버에서 클라이언트로만 데이터를 스트리밍하는 단방향 푸시 기술이다. 일반 HTTP 연결을 유지하면서 `text/event-stream` Content-Type으로 데이터를 지속적으로 전송한다.

브라우저의 `EventSource` API를 통해 사용하며, HTTP/2 환경에서 매우 효율적이다.

### 서버 코드 예제 (Node.js / Express)

```javascript
const express = require("express");
const app = express();

app.get("/api/notifications", (req, res) => {
  // SSE 헤더 설정
  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");
  res.setHeader("X-Accel-Buffering", "no"); // Nginx 버퍼링 비활성화
  res.flushHeaders();

  // 연결 즉시 확인 메시지 전송
  sendEvent(res, "connected", { message: "SSE 연결 성공" });

  // 주기적 데이터 전송 (예: 실시간 주가 데이터)
  const interval = setInterval(() => {
    const data = {
      price: (Math.random() * 100 + 50000).toFixed(0),
      timestamp: new Date().toISOString(),
    };
    sendEvent(res, "price-update", data);
  }, 1000);

  // Keep-alive (프록시 타임아웃 방지)
  const keepAlive = setInterval(() => {
    res.write(": keep-alive\n\n");
  }, 15000);

  // 클라이언트 연결 종료 시 정리
  req.on("close", () => {
    clearInterval(interval);
    clearInterval(keepAlive);
    console.log("SSE 클라이언트 연결 해제");
  });
});

// SSE 이벤트 포맷에 맞게 전송
function sendEvent(res, eventType, data, id = null) {
  if (id) res.write(`id: ${id}\n`);
  res.write(`event: ${eventType}\n`);
  res.write(`data: ${JSON.stringify(data)}\n\n`); // 반드시 \n\n으로 종료
}

app.listen(3000);
```

### SSE 데이터 포맷

```
# SSE 스트림 형식
id: 1
event: price-update
data: {"price": "51234", "timestamp": "2026-06-12T10:00:00Z"}

id: 2
event: price-update
data: {"price": "51300", "timestamp": "2026-06-12T10:00:01Z"}

: keep-alive

```

각 필드는 `\n`으로 구분하고, 이벤트 사이는 빈 줄(`\n\n`)로 구분한다.

### 클라이언트 코드 예제 (브라우저)

```javascript
const eventSource = new EventSource("/api/notifications");

// 연결 수립
eventSource.addEventListener("open", () => {
  console.log("SSE 연결됨");
});

// 특정 이벤트 타입 수신
eventSource.addEventListener("price-update", (event) => {
  const data = JSON.parse(event.data);
  console.log("가격 업데이트:", data.price);
  updatePriceDisplay(data);
});

eventSource.addEventListener("connected", (event) => {
  const data = JSON.parse(event.data);
  console.log(data.message);
});

// 기본 message 이벤트 (event 필드 없는 경우)
eventSource.addEventListener("message", (event) => {
  console.log("기본 메시지:", event.data);
});

// 에러 및 재연결
eventSource.addEventListener("error", (event) => {
  if (eventSource.readyState === EventSource.CLOSED) {
    console.log("SSE 연결 종료됨");
  } else {
    // 브라우저가 자동으로 재연결 시도 (Last-Event-ID 헤더 포함)
    console.log("SSE 에러, 재연결 중...");
  }
});

// 연결 종료
function stopSSE() {
  eventSource.close();
}
```

### SSE 자동 재연결

브라우저의 `EventSource`는 연결이 끊기면 자동으로 재연결을 시도한다. 서버가 `id` 필드를 설정하면, 재연결 시 `Last-Event-ID` 헤더로 마지막 수신 ID를 전달한다.

```javascript
// 서버: retry 간격 설정 (밀리초)
res.write("retry: 5000\n\n"); // 5초 후 재연결
```

---

## 5. 기술 비교

### 종합 비교표

| 구분 | Long Polling | WebSocket | SSE |
|------|-------------|-----------|-----|
| 통신 방향 | 단방향 (서버→클라이언트) | 양방향 | 단방향 (서버→클라이언트) |
| 프로토콜 | HTTP | WS (TCP 기반) | HTTP |
| 헤더 오버헤드 | 매 요청마다 발생 | 최초 1회 | 최초 1회 |
| 연결 유지 | 요청-응답 반복 | 영구 연결 | 영구 연결 |
| 자동 재연결 | 직접 구현 필요 | 직접 구현 필요 | 브라우저 내장 |
| 브라우저 지원 | 모든 브라우저 | IE10+ / 모던 브라우저 | IE 제외 모던 브라우저 |
| 프록시/방화벽 | HTTP이므로 투과성 높음 | 일부 프록시에서 차단 가능 | HTTP이므로 투과성 높음 |
| HTTP/2 멀티플렉싱 | 지원 | 불가 (별도 프로토콜) | 지원 (효율적) |
| 서버 구현 복잡도 | 중간 | 높음 | 낮음 |
| 데이터 형식 | JSON/텍스트 | 텍스트 + 바이너리 | 텍스트 |
| 적합한 연결 수 | 소규모 | 중대규모 | 대규모 (HTTP/2) |

### 지연 시간 비교

```
Long Polling: 요청 → 대기 → 응답 → 재요청 → ...
              (재요청 오버헤드 + 헤더 오버헤드)

WebSocket:    연결 → 프레임 → 프레임 → 프레임 → ...
              (최초 핸드셰이크 이후 2~14바이트 헤더만)

SSE:          연결 → 청크 → 청크 → 청크 → ...
              (HTTP 스트리밍, 헤더 1회)
```

---

## 6. 사용 시나리오 선택 기준

### Long Polling 적합 시나리오

- 레거시 브라우저 지원이 필수인 환경
- 메시지 빈도가 낮고 실시간성이 크게 중요하지 않은 경우
- 기존 HTTP 인프라(로드밸런서, 프록시)를 변경하기 어려운 경우
- 예: 관리자 알림, 배치 작업 상태 확인

```javascript
// 적합한 예: 5분마다 한 번 상태를 체크하는 경우
// → 일반 Polling으로도 충분하나, 즉각 반응이 필요하면 Long Polling 고려
```

### WebSocket 적합 시나리오

- 클라이언트와 서버가 모두 능동적으로 메시지를 보내야 하는 경우
- 지연 시간이 매우 중요한 경우 (게임, 트레이딩)
- 바이너리 데이터(이미지, 파일)를 스트리밍해야 하는 경우
- 예: 실시간 채팅, 멀티플레이어 게임, 협업 에디터(Figma, Notion), 라이브 트레이딩

```javascript
// 적합한 예: 실시간 협업 문서 편집
// → 클라이언트가 타이핑할 때마다 서버로 전송, 서버는 다른 참여자에게 브로드캐스트
ws.send(JSON.stringify({ type: "cursor-move", x: 100, y: 200 }));
ws.send(JSON.stringify({ type: "text-insert", pos: 42, text: "안녕" }));
```

### SSE 적합 시나리오

- 서버에서 클라이언트로만 데이터를 보내는 경우
- HTTP/2 환경에서 다수의 클라이언트를 효율적으로 처리해야 하는 경우
- 자동 재연결과 이벤트 ID 복구가 중요한 경우
- 예: 실시간 로그 스트리밍, 주식 시세, 스포츠 스코어, 진행 상황 표시, AI 응답 스트리밍

```javascript
// 적합한 예: AI 챗봇 응답 스트리밍 (ChatGPT 방식)
eventSource.addEventListener("token", (e) => {
  const { token } = JSON.parse(e.data);
  appendToAnswer(token); // 토큰이 생성될 때마다 화면에 추가
});
```

### 결정 트리

```
클라이언트도 서버에 데이터를 보내야 하는가?
    │
    ├── 예 → WebSocket
    │
    └── 아니오 (서버→클라이언트만)
            │
            ├── 구형 브라우저 지원 필요? → Long Polling
            │
            ├── HTTP/2 환경, 많은 동시 연결? → SSE
            │
            └── 단순 구현, 일반 환경? → SSE (기본 선택)
```

---

## 7. 면접 포인트

### Q1. WebSocket 핸드셰이크 과정을 설명하세요.

클라이언트가 `Upgrade: websocket` 헤더를 포함한 HTTP GET 요청을 보낸다. 서버가 `101 Switching Protocols`로 응답하면 TCP 연결이 WebSocket 프로토콜로 업그레이드된다. 이후 HTTP 오버헤드 없이 TCP 위에서 WebSocket 프레임을 주고받는다.

### Q2. Long Polling과 WebSocket의 차이점은 무엇인가요?

Long Polling은 매번 HTTP 연결을 새로 맺어 헤더 오버헤드가 크고, 단방향(서버→클라이언트) 통신만 가능하다. WebSocket은 최초 핸드셰이크 이후 TCP 연결을 유지하여 오버헤드가 최소화되고, 양방향 통신이 가능하다.

### Q3. SSE는 왜 WebSocket 대신 사용하나요?

SSE는 표준 HTTP 프로토콜을 사용하므로 프록시·방화벽 통과가 쉽고, HTTP/2 멀티플렉싱의 혜택을 받을 수 있다. 브라우저가 자동 재연결을 지원하고 구현이 간단하다. 서버에서 클라이언트로만 데이터를 보내면 충분한 경우(알림, 피드, AI 스트리밍 등)에는 WebSocket보다 SSE가 더 적합하다.

### Q4. WebSocket 연결이 끊겼을 때 어떻게 처리하나요?

`close` 이벤트 핸들러에서 재연결 로직을 구현한다. 일반적으로 지수 백오프(exponential backoff) 전략을 사용하여 재연결 간격을 점진적으로 늘린다. 서버 측에서는 Heartbeat(ping/pong)으로 죽은 연결을 감지하고 정리한다.

```javascript
let retryDelay = 1000;
function reconnect() {
  setTimeout(() => {
    const ws = new WebSocket(url);
    ws.onopen = () => { retryDelay = 1000; }; // 성공 시 초기화
    ws.onclose = () => {
      retryDelay = Math.min(retryDelay * 2, 30000); // 최대 30초
      reconnect();
    };
  }, retryDelay);
}
```

### Q5. HTTP/2 환경에서 SSE가 WebSocket보다 유리한 이유는 무엇인가요?

HTTP/2는 하나의 TCP 연결에서 여러 스트림을 멀티플렉싱할 수 있다. 따라서 SSE는 HTTP/2 위에서 다수의 이벤트 스트림을 효율적으로 처리할 수 있다. 반면 WebSocket은 HTTP/2의 멀티플렉싱을 활용하지 못하며, 별도의 TCP 연결을 사용한다.

### Q6. 대규모 실시간 시스템에서 WebSocket 서버 확장 시 주의점은 무엇인가요?

WebSocket은 연결이 특정 서버에 고정(sticky session)되는 특성이 있다. 수평 확장 시 Redis Pub/Sub 또는 메시지 큐(Kafka, RabbitMQ)를 도입하여 서버 간 메시지를 중계해야 한다. 로드밸런서도 WebSocket Upgrade를 지원하도록 설정해야 한다.

### 핵심 키워드 정리

| 키워드 | 설명 |
|--------|------|
| HTTP Upgrade | WebSocket 핸드셰이크의 시작, 101 상태 코드 |
| Full-duplex | WebSocket의 양방향 동시 통신 |
| EventSource | SSE를 위한 브라우저 내장 API |
| text/event-stream | SSE의 Content-Type |
| Heartbeat (ping/pong) | WebSocket 연결 생존 확인 메커니즘 |
| Last-Event-ID | SSE 재연결 시 마지막 수신 이벤트 ID |
| Sticky Session | WebSocket 확장 시 필요한 로드밸런서 설정 |
