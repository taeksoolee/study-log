# 09. 에러 처리 (Error Handling)

## 목차
1. [Error 종류](#1-error-종류)
2. [try / catch / finally](#2-try--catch--finally)
3. [커스텀 에러 클래스](#3-커스텀-에러-클래스)
4. [비동기 에러 처리](#4-비동기-에러-처리)
5. [에러 처리 전략](#5-에러-처리-전략)
6. [면접 포인트](#면접-포인트)

---

## 1. Error 종류

JavaScript 내장 에러 타입들:

| 에러 타입 | 발생 상황 | 예시 |
|-----------|-----------|------|
| `Error` | 일반 에러의 기반 클래스 | `new Error('메시지')` |
| `TypeError` | 잘못된 타입에 연산 | `null.property`, `undefined()` |
| `ReferenceError` | 선언되지 않은 변수 참조 | `console.log(undeclaredVar)` |
| `SyntaxError` | 잘못된 JS 문법 | `JSON.parse('{bad}')` |
| `RangeError` | 유효 범위 벗어남 | `new Array(-1)`, 재귀 초과 |
| `URIError` | URI 관련 함수 오용 | `decodeURIComponent('%')` |
| `EvalError` | `eval()` 관련 (거의 미사용) | - |

```js
// TypeError: 타입이 잘못됨
try {
  null.property;
} catch (e) {
  console.log(e instanceof TypeError); // true
  console.log(e.name);                 // 'TypeError'
  console.log(e.message);             // "Cannot read properties of null"
}

// ReferenceError: 변수를 찾을 수 없음
try {
  console.log(undeclaredVariable);
} catch (e) {
  console.log(e instanceof ReferenceError); // true
}

// RangeError: 범위를 벗어남
try {
  new Array(-1);
} catch (e) {
  console.log(e instanceof RangeError); // true
  console.log(e.message); // 'Invalid array length'
}

// SyntaxError: 파싱 불가한 JSON
try {
  JSON.parse('{ invalid json }');
} catch (e) {
  console.log(e instanceof SyntaxError); // true
}
```

### Error 객체의 프로퍼티

```js
const err = new Error('문제가 발생했습니다.');

console.log(err.name);    // 'Error'
console.log(err.message); // '문제가 발생했습니다.'
console.log(err.stack);   // 스택 트레이스 문자열
/*
Error: 문제가 발생했습니다.
    at Object.<anonymous> (/path/to/file.js:1:13)
    at Module._compile (...)
    ...
*/
```

---

## 2. try / catch / finally

### 기본 구조

```js
try {
  // 에러가 발생할 수 있는 코드
  const result = riskyOperation();
  console.log(result);
} catch (error) {
  // 에러 발생 시 실행 (error 객체 수신)
  console.error('에러 발생:', error.message);
} finally {
  // 성공/실패 무관하고 항상 실행
  // 리소스 정리, 로딩 상태 해제 등
  cleanup();
}
```

### `finally`의 특성

```js
function example() {
  try {
    return 'try'; // return 실행 직전
  } finally {
    console.log('finally 실행'); // return 전에 실행됨
    // return 'finally'; // 이렇게 하면 'try' 대신 'finally' 반환
  }
}

console.log(example());
// 'finally 실행'
// 'try'
```

```js
// finally에서 throw 시 try/catch의 에러를 덮어씀
function dangerous() {
  try {
    throw new Error('원래 에러');
  } finally {
    throw new Error('finally 에러'); // 원래 에러를 삼킴 (주의!)
  }
}

try {
  dangerous();
} catch (e) {
  console.log(e.message); // 'finally 에러' - 원래 에러는 사라짐
}
```

### 에러 타입에 따른 분기 처리

```js
function processData(data) {
  try {
    const parsed = JSON.parse(data);
    return parsed.value.toUpperCase();
  } catch (error) {
    if (error instanceof SyntaxError) {
      console.error('JSON 파싱 실패:', error.message);
      return null;
    }
    if (error instanceof TypeError) {
      console.error('데이터 구조 오류:', error.message);
      return '';
    }
    // 예상치 못한 에러는 다시 throw
    throw error;
  }
}
```

### 에러를 다시 던지기 (Re-throw)

```js
function fetchData(url) {
  try {
    return makeRequest(url);
  } catch (error) {
    // 알고 있는 에러만 처리
    if (error instanceof NetworkError) {
      console.warn('네트워크 에러, 재시도 중...');
      return retryRequest(url);
    }
    // 모르는 에러는 위로 전파
    throw error;
  }
}
```

---

## 3. 커스텀 에러 클래스

### 기본 커스텀 에러

```js
class AppError extends Error {
  constructor(message, code) {
    super(message);       // Error의 message 설정
    this.name = 'AppError';
    this.code = code;

    // V8 엔진: 스택 트레이스에서 이 생성자를 제외
    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, this.constructor);
    }
  }
}

class ValidationError extends AppError {
  constructor(field, message) {
    super(message, 'VALIDATION_ERROR');
    this.name = 'ValidationError';
    this.field = field;
  }
}

class NotFoundError extends AppError {
  constructor(resource, id) {
    super(`${resource} (id: ${id})를 찾을 수 없습니다.`, 'NOT_FOUND');
    this.name = 'NotFoundError';
    this.resource = resource;
    this.id = id;
  }
}

class NetworkError extends AppError {
  constructor(statusCode, message) {
    super(message, 'NETWORK_ERROR');
    this.name = 'NetworkError';
    this.statusCode = statusCode;
  }
}
```

### 커스텀 에러 활용

```js
function validateUser(user) {
  if (!user.name) {
    throw new ValidationError('name', '이름은 필수 입력 항목입니다.');
  }
  if (user.age < 0 || user.age > 150) {
    throw new ValidationError('age', '나이는 0~150 사이여야 합니다.');
  }
}

async function getUser(id) {
  const user = await db.find(id);
  if (!user) {
    throw new NotFoundError('User', id);
  }
  return user;
}

// 에러 처리
async function handleRequest(userId, userData) {
  try {
    validateUser(userData);
    const user = await getUser(userId);
    return { success: true, user };
  } catch (error) {
    if (error instanceof ValidationError) {
      return { success: false, status: 400, field: error.field, message: error.message };
    }
    if (error instanceof NotFoundError) {
      return { success: false, status: 404, message: error.message };
    }
    if (error instanceof NetworkError) {
      return { success: false, status: error.statusCode, message: '서버 오류' };
    }
    // 예상치 못한 에러
    console.error('예상치 못한 에러:', error);
    return { success: false, status: 500, message: '내부 서버 오류' };
  }
}
```

### `instanceof` 체크 주의사항

```js
// iFrame, Worker 등 다른 실행 컨텍스트에서는 instanceof가 실패할 수 있음
// error.name 비교가 더 안전한 경우도 있음

function isValidationError(error) {
  return error instanceof ValidationError ||
         error.name === 'ValidationError';
}
```

---

## 4. 비동기 에러 처리

### Promise에서의 에러

```js
// reject된 Promise를 처리하지 않으면 UnhandledPromiseRejection 경고
Promise.reject(new Error('미처리 에러')); // 위험!

// .catch()로 처리
Promise.reject(new Error('에러'))
  .catch(err => console.error('처리됨:', err.message));

// 체인 중간 에러
fetch('/api/data')
  .then(res => {
    if (!res.ok) throw new NetworkError(res.status, '요청 실패');
    return res.json();
  })
  .then(data => processData(data))
  .catch(err => {
    if (err instanceof NetworkError) {
      console.error('네트워크 에러:', err.statusCode);
    } else {
      console.error('예상치 못한 에러:', err);
    }
  });
```

### async/await에서의 에러

```js
// 방법 1: try/catch
async function loadUser(id) {
  try {
    const response = await fetch(`/api/users/${id}`);
    if (!response.ok) throw new NetworkError(response.status, '요청 실패');
    return await response.json();
  } catch (err) {
    console.error('로드 실패:', err);
    return null;
  }
}

// 방법 2: .catch() 체이닝
async function loadUser2(id) {
  const response = await fetch(`/api/users/${id}`)
    .catch(() => null); // fetch 자체 실패 처리

  if (!response?.ok) return null;
  return response.json().catch(() => null); // JSON 파싱 실패 처리
}

// 방법 3: 에러를 Result 타입으로 래핑
async function safeAsync(promise) {
  try {
    const data = await promise;
    return { ok: true, data };
  } catch (error) {
    return { ok: false, error };
  }
}

const { ok, data, error } = await safeAsync(fetchUser(1));
if (!ok) {
  console.error('실패:', error.message);
} else {
  console.log('성공:', data);
}
```

### 전역 에러 핸들러

```js
// Node.js
process.on('uncaughtException', (error) => {
  console.error('처리되지 않은 동기 에러:', error);
  // 프로세스를 안전하게 종료 (상태가 불안정할 수 있음)
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('처리되지 않은 Promise 거부:', reason);
  // 로깅 후 선택적으로 종료
});

// 브라우저
window.onerror = (message, source, lineno, colno, error) => {
  sendToErrorTracking({ message, source, lineno, colno, error });
  return true; // 브라우저 기본 에러 표시 방지
};

window.addEventListener('unhandledrejection', (event) => {
  console.error('Promise 거부:', event.reason);
  event.preventDefault();
});
```

---

## 5. 에러 처리 전략

### 에러 경계 (Error Boundary) 패턴

```js
// 함수 래퍼로 에러 경계 구현
function withErrorBoundary(fn, fallback) {
  return function(...args) {
    try {
      const result = fn(...args);
      // Promise인 경우 처리
      if (result instanceof Promise) {
        return result.catch(err => {
          console.error(`[ErrorBoundary] ${fn.name}:`, err);
          return typeof fallback === 'function' ? fallback(err) : fallback;
        });
      }
      return result;
    } catch (err) {
      console.error(`[ErrorBoundary] ${fn.name}:`, err);
      return typeof fallback === 'function' ? fallback(err) : fallback;
    }
  };
}

const safeParseJSON = withErrorBoundary(JSON.parse, null);
console.log(safeParseJSON('{"valid": true}')); // { valid: true }
console.log(safeParseJSON('invalid json'));     // null
```

### 재시도 (Retry) 패턴

```js
async function retry(fn, maxAttempts = 3, delay = 1000) {
  let lastError;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      console.warn(`시도 ${attempt}/${maxAttempts} 실패:`, error.message);

      if (attempt < maxAttempts) {
        // 지수 백오프 (exponential backoff)
        await new Promise(resolve => setTimeout(resolve, delay * attempt));
      }
    }
  }

  throw new Error(`${maxAttempts}번 시도 후 실패: ${lastError.message}`);
}

// 사용 예
const data = await retry(() => fetch('/api/data').then(r => r.json()), 3, 500);
```

---

## 면접 포인트

**Q. `try/catch`로 모든 에러를 잡을 수 있나요?**
> 동기 코드의 에러는 잡을 수 있지만, 비동기 콜백(setTimeout 등) 내부의 에러는 잡히지 않는다. `async/await`를 사용하면 `try/catch`로 비동기 에러도 처리할 수 있다. Promise에서는 `.catch()`가 필요하다.

**Q. 커스텀 에러 클래스를 만드는 이유는?**
> `instanceof`로 에러 타입을 구분해 적절히 처리하기 위해서다. 예를 들어 ValidationError는 400, NotFoundError는 404로 HTTP 응답을 다르게 보낼 수 있다. 에러에 추가 정보(field, statusCode 등)를 담아 더 풍부한 처리가 가능하다.

**Q. `finally`는 언제 사용하나요?**
> 성공/실패와 무관하게 반드시 실행해야 하는 정리(cleanup) 작업에 사용한다. 예: DB 커넥션 닫기, 파일 핸들 반환, 로딩 스피너 숨기기. `return`이나 `throw` 이후에도 실행된다. 단, `finally`에서 `throw`하면 이전 에러가 덮어씌워지므로 주의한다.

**Q. 에러를 잡은 후 다시 던지는(re-throw) 이유는?**
> 현재 컨텍스트에서 처리할 수 없는 에러를 상위 호출자에게 위임하기 위해서다. 알고 있는 타입(예: NetworkError)만 처리하고, 예상치 못한 에러는 다시 던져서 버그가 조용히 숨겨지지 않게 한다. 또한 에러에 추가 컨텍스트를 붙여 re-throw하면 디버깅이 쉬워진다.

**Q. `Promise`에서 에러 처리를 빠뜨리면 어떻게 되나요?**
> 브라우저에서는 콘솔에 경고가 뜨고 `unhandledrejection` 이벤트가 발생한다. Node.js에서는 `unhandledRejection` 이벤트가 발생하며, 최신 버전에서는 프로세스가 종료될 수도 있다. 모든 Promise 체인의 끝에는 반드시 `.catch()`를 붙이거나 `async/await`와 `try/catch`를 사용해야 한다.
