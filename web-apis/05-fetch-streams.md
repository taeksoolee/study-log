# 5. Fetch & Streams

## 목차
1. Fetch API 완전 가이드
2. AbortController로 요청 취소
3. ReadableStream 스트리밍 처리
4. AI 응답 스트리밍 예제
5. Request / Response 객체
6. 면접 포인트

---

## 1. Fetch API 완전 가이드

```js
const response = await fetch(url, options);
```

### 주요 옵션

```js
const response = await fetch('/api/data', {
  method: 'POST',              // GET | POST | PUT | PATCH | DELETE | ...

  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`,
    'X-Custom-Header': 'value',
  },

  body: JSON.stringify({ key: 'value' }),

  // 자격증명 포함 여부
  credentials: 'include',     // omit | same-origin | include

  // 캐시 정책
  cache: 'no-cache',          // default | no-store | reload | no-cache | force-cache | only-if-cached

  // 리다이렉트 처리
  redirect: 'follow',         // follow | manual | error

  // CORS 모드
  mode: 'cors',               // cors | no-cors | same-origin | navigate

  // Referrer 정책
  referrerPolicy: 'no-referrer-when-downgrade',

  // 우선순위 힌트
  priority: 'high',           // high | low | auto
});
```

### 응답 파싱

```js
const res = await fetch('/api/endpoint');

// 상태 확인
if (!res.ok) throw new Error(`HTTP error: ${res.status}`);

// 다양한 파싱 방법 (한 번만 호출 가능, body는 소비됨)
const json = await res.json();
const text = await res.text();
const blob = await res.blob();
const arrayBuffer = await res.arrayBuffer();
const formData = await res.formData();
```

### 에러 처리 패턴

```js
async function fetchWithRetry(url, options = {}, retries = 3) {
  for (let attempt = 0; attempt < retries; attempt++) {
    try {
      const res = await fetch(url, options);
      if (!res.ok) {
        if (res.status >= 500 && attempt < retries - 1) {
          await new Promise(r => setTimeout(r, 2 ** attempt * 1000)); // 지수 백오프
          continue;
        }
        throw new Error(`HTTP ${res.status}: ${res.statusText}`);
      }
      return res;
    } catch (err) {
      if (attempt === retries - 1) throw err;
    }
  }
}
```

---

## 2. AbortController로 요청 취소

```js
const controller = new AbortController();
const { signal } = controller;

// 5초 타임아웃
const timeoutId = setTimeout(() => controller.abort('timeout'), 5000);

try {
  const res = await fetch('/api/slow-endpoint', { signal });
  const data = await res.json();
  clearTimeout(timeoutId);
  return data;
} catch (err) {
  if (err.name === 'AbortError') {
    console.log('요청 취소됨:', err.message); // 'timeout' or 'user cancelled'
  } else {
    throw err;
  }
}
```

### AbortSignal.timeout() (최신 API)

```js
// AbortController 없이 타임아웃 설정
const res = await fetch('/api/data', {
  signal: AbortSignal.timeout(5000), // 5초 타임아웃
});
```

### React에서 컴포넌트 언마운트 시 취소

```js
useEffect(() => {
  const controller = new AbortController();

  async function loadData() {
    try {
      const res = await fetch('/api/items', { signal: controller.signal });
      const data = await res.json();
      setItems(data);
    } catch (err) {
      if (err.name !== 'AbortError') setError(err.message);
    }
  }

  loadData();
  return () => controller.abort();
}, []);
```

---

## 3. ReadableStream 스트리밍 처리

`response.body`는 `ReadableStream`이다. 대용량 응답이나 점진적 렌더링에 활용한다.

```js
const res = await fetch('/api/large-file');
const reader = res.body.getReader();
const decoder = new TextDecoder();
let received = 0;
const total = parseInt(res.headers.get('Content-Length') || '0');

while (true) {
  const { done, value } = await reader.read();
  if (done) break;

  received += value.length;
  const text = decoder.decode(value, { stream: true });
  appendToUI(text);

  if (total) {
    const progress = (received / total * 100).toFixed(1);
    updateProgressBar(progress);
  }
}
```

### ReadableStream 직접 생성

```js
function createCountStream(max) {
  let count = 0;
  return new ReadableStream({
    start(controller) {
      const interval = setInterval(() => {
        if (count >= max) {
          controller.close();
          clearInterval(interval);
        } else {
          controller.enqueue(new TextEncoder().encode(`data: ${count++}\n\n`));
        }
      }, 100);
    },
    cancel() {
      clearInterval(interval);
    },
  });
}
```

---

## 4. AI 응답 스트리밍 예제 (SSE / NDJSON)

OpenAI / Anthropic 등 AI API는 Server-Sent Events 형식으로 스트리밍 응답을 반환한다.

```js
async function streamChatResponse(prompt, onChunk, onDone) {
  const res = await fetch('/api/chat', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ prompt }),
    signal: AbortSignal.timeout(30000),
  });

  if (!res.ok) throw new Error(`API Error: ${res.status}`);

  const reader = res.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';

  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });

      // SSE 형식: "data: {...}\n\n"
      const lines = buffer.split('\n\n');
      buffer = lines.pop(); // 마지막 불완전한 청크 보존

      for (const line of lines) {
        if (!line.startsWith('data: ')) continue;
        const payload = line.slice(6);
        if (payload === '[DONE]') { onDone(); return; }

        try {
          const { delta } = JSON.parse(payload);
          if (delta?.content) onChunk(delta.content);
        } catch {
          // 파싱 실패 청크 무시
        }
      }
    }
  } finally {
    reader.releaseLock();
  }
}

// 사용
let fullText = '';
await streamChatResponse(
  '안녕하세요!',
  (chunk) => {
    fullText += chunk;
    document.querySelector('#output').textContent = fullText;
  },
  () => console.log('스트리밍 완료')
);
```

---

## 5. Request / Response 객체

### Request 객체 직접 생성

```js
const request = new Request('/api/data', {
  method: 'POST',
  headers: new Headers({ 'Content-Type': 'application/json' }),
  body: JSON.stringify({ id: 1 }),
});

// 요청 복제 (body는 한 번만 소비 가능하므로 재사용 시 필요)
const cloned = request.clone();

const response = await fetch(request);
```

### Headers 객체

```js
const headers = new Headers({
  'Content-Type': 'application/json',
});

headers.append('X-Custom', 'value');
headers.set('Authorization', `Bearer ${token}`);
headers.has('Content-Type'); // true
headers.get('content-type'); // 대소문자 무관
headers.delete('X-Custom');

// 순회
for (const [key, value] of headers) {
  console.log(key, value);
}
```

### Response 객체 직접 생성 (Service Worker, Mock)

```js
// Service Worker에서 커스텀 응답 반환
self.addEventListener('fetch', event => {
  if (event.request.url.includes('/api/mock')) {
    event.respondWith(
      new Response(JSON.stringify({ mocked: true }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      })
    );
  }
});

// 리다이렉트 응답
const redirect = Response.redirect('https://example.com', 301);
```

---

## 6. 면접 포인트

**Q. fetch와 XMLHttpRequest의 차이는?**

`fetch`는 Promise 기반, 스트리밍 지원, ServiceWorker에서 사용 가능, 더 깔끔한 API. `XHR`은 진행률 이벤트(`onprogress`)를 기본 지원하고 동기 요청이 가능하다(비권장). 파일 업로드 진행률 표시는 여전히 XHR이 더 편하거나, `fetch` + ReadableStream으로 구현해야 한다.

**Q. fetch가 네트워크 에러와 HTTP 에러를 구분하는 방식은?**

네트워크 에러(연결 불가, DNS 실패)는 Promise reject. HTTP 에러(4xx, 5xx)는 `res.ok === false`지만 Promise는 resolve된다. 따라서 `if (!res.ok) throw new Error(...)` 패턴이 필수다.

**Q. ReadableStream의 cancel()은 언제 호출되나?**

`reader.cancel()` 또는 `response.body.cancel()`을 직접 호출하거나, AbortController로 fetch를 중단할 때 호출된다. cancel 핸들러에서 리소스 정리(타이머, 연결 등)를 수행한다.

**Q. CORS preflight는 언제 발생하나?**

simple request 조건(GET/POST/HEAD + 허용된 헤더 + `application/x-www-form-urlencoded` 등)을 벗어나면 OPTIONS preflight 요청이 먼저 발생한다. `Content-Type: application/json` 사용 시 preflight가 발생하므로 서버에서 `Access-Control-Allow-Headers`에 포함해야 한다.
