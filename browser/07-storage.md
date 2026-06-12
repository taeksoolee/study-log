# 7. 브라우저 스토리지 (Cookie, localStorage, sessionStorage, IndexedDB)

## 목차
1. 스토리지 비교 개요
2. Cookie
3. localStorage / sessionStorage
4. IndexedDB
5. 사용 시나리오
6. 면접 포인트

---

## 1. 스토리지 비교 개요

### 특징 비교표

| 특성 | Cookie | localStorage | sessionStorage | IndexedDB |
|------|--------|--------------|----------------|-----------|
| 저장 용량 | ~4KB | ~5-10MB | ~5-10MB | ~수백MB+ |
| 만료 | 설정 가능 | 없음 (영구) | 탭/창 닫힐 때 | 없음 (영구) |
| 서버 전송 | 자동 (HTTP 헤더) | X | X | X |
| 접근 범위 | 도메인/경로 설정 | 도메인 | 도메인 + 탭 | 도메인 |
| JS 접근 | 제한적 (HttpOnly) | O | O | O |
| 동기/비동기 | 동기 | 동기 | 동기 | 비동기 |
| 구조화 데이터 | X (문자열) | X (문자열) | X (문자열) | O (객체) |
| 트랜잭션 | X | X | X | O |
| 인덱싱 | X | X | X | O |

### 저장 위치 개념도

```
Browser
├── HTTP 요청/응답
│   └── Cookie (서버와 자동 교환)
│
└── Web Storage API
    ├── localStorage  (도메인 공유, 영구)
    ├── sessionStorage (탭별 독립, 임시)
    └── IndexedDB (대용량 구조화 데이터)
```

---

## 2. Cookie

### 개념
- 서버가 `Set-Cookie` 응답 헤더로 설정, 브라우저가 저장
- 이후 동일 도메인 요청마다 `Cookie` 요청 헤더에 자동 포함
- 주로 **세션 관리, 인증 토큰, 사용자 설정** 저장에 사용

### Cookie 속성

```http
Set-Cookie: sessionId=abc123;
            Expires=Wed, 09 Jun 2027 10:18:14 GMT;
            Max-Age=86400;
            Domain=example.com;
            Path=/;
            Secure;
            HttpOnly;
            SameSite=Lax
```

| 속성 | 설명 |
|------|------|
| `Expires` | 만료 날짜 (절대 시간) |
| `Max-Age` | 만료 시간 (초 단위, Expires보다 우선) |
| `Domain` | 쿠키를 전송할 도메인 (서브도메인 포함 가능) |
| `Path` | 쿠키를 전송할 URL 경로 |
| `Secure` | HTTPS 연결에서만 전송 |
| `HttpOnly` | JS에서 접근 불가 (XSS 방어) |
| `SameSite` | 크로스 사이트 요청 제어 (Lax/Strict/None) |

### JavaScript 코드 예제

```javascript
// --- 쿠키 설정 ---
function setCookie(name, value, options = {}) {
  const {
    expires,
    maxAge,
    domain,
    path = '/',
    secure = false,
    sameSite = 'Lax',
  } = options;

  let cookie = `${encodeURIComponent(name)}=${encodeURIComponent(value)}`;

  if (expires instanceof Date) {
    cookie += `; Expires=${expires.toUTCString()}`;
  }
  if (maxAge !== undefined) {
    cookie += `; Max-Age=${maxAge}`;
  }
  if (domain) {
    cookie += `; Domain=${domain}`;
  }
  cookie += `; Path=${path}`;
  if (secure) cookie += '; Secure';
  cookie += `; SameSite=${sameSite}`;

  document.cookie = cookie;
}

// --- 쿠키 읽기 ---
function getCookie(name) {
  const nameEq = `${encodeURIComponent(name)}=`;
  const cookies = document.cookie.split('; ');

  for (const cookie of cookies) {
    if (cookie.startsWith(nameEq)) {
      return decodeURIComponent(cookie.slice(nameEq.length));
    }
  }
  return null;
}

// --- 쿠키 삭제 ---
function deleteCookie(name, path = '/') {
  // Max-Age=0 또는 과거 Expires로 설정하면 삭제됨
  document.cookie = `${encodeURIComponent(name)}=; Max-Age=0; Path=${path}`;
}

// --- 모든 쿠키 읽기 ---
function getAllCookies() {
  return document.cookie
    .split('; ')
    .filter(Boolean)
    .reduce((acc, cookie) => {
      const [key, ...vals] = cookie.split('=');
      acc[decodeURIComponent(key)] = decodeURIComponent(vals.join('='));
      return acc;
    }, {});
}

// 사용 예
setCookie('theme', 'dark', { maxAge: 60 * 60 * 24 * 30 }); // 30일
console.log(getCookie('theme')); // "dark"
deleteCookie('theme');

// --- Cookie Store API (최신, 비동기) ---
async function modernCookieUsage() {
  await cookieStore.set({
    name: 'sessionId',
    value: 'xyz789',
    expires: Date.now() + 86400e3,
    sameSite: 'strict',
  });

  const cookie = await cookieStore.get('sessionId');
  console.log(cookie?.value);

  await cookieStore.delete('sessionId');
}
```

---

## 3. localStorage / sessionStorage

### 개념
- **Web Storage API**의 두 가지 구현체
- 키-값 쌍으로 **문자열**만 저장 (객체는 JSON 직렬화 필요)
- 동기 API (대용량 작업 시 메인 스레드 블로킹 주의)

### 차이점

| | localStorage | sessionStorage |
|-|--------------|----------------|
| 수명 | 브라우저/탭을 닫아도 유지 | 탭/창을 닫으면 삭제 |
| 탭 간 공유 | 동일 도메인의 모든 탭에서 공유 | 탭마다 독립 (새 탭으로 열면 별도) |
| 용도 | 사용자 설정, 테마, 언어 | 임시 폼 데이터, 단계별 마법사 |

### 코드 예제

```javascript
// --- 기본 API ---
// setItem / getItem / removeItem / clear / key / length

localStorage.setItem('username', 'Alice');
console.log(localStorage.getItem('username')); // "Alice"
localStorage.removeItem('username');
localStorage.clear(); // 전체 삭제

// --- 객체 저장 (JSON 직렬화) ---
const user = { id: 1, name: 'Alice', role: 'admin' };
localStorage.setItem('user', JSON.stringify(user));

const stored = localStorage.getItem('user');
const parsed = stored ? JSON.parse(stored) : null;

// --- 유틸리티 래퍼 ---
const storage = {
  set(key, value) {
    try {
      localStorage.setItem(key, JSON.stringify(value));
    } catch (e) {
      if (e.name === 'QuotaExceededError') {
        console.error('스토리지 용량 초과');
      }
    }
  },

  get(key, defaultValue = null) {
    try {
      const item = localStorage.getItem(key);
      return item !== null ? JSON.parse(item) : defaultValue;
    } catch {
      return defaultValue;
    }
  },

  remove(key) {
    localStorage.removeItem(key);
  },

  // TTL(만료 시간) 지원 래퍼
  setWithExpiry(key, value, ttlMs) {
    this.set(key, { value, expiry: Date.now() + ttlMs });
  },

  getWithExpiry(key) {
    const item = this.get(key);
    if (!item) return null;
    if (Date.now() > item.expiry) {
      this.remove(key);
      return null;
    }
    return item.value;
  },
};

// --- storage 이벤트 (다른 탭 변경 감지) ---
window.addEventListener('storage', (event) => {
  console.log('키:', event.key);
  console.log('이전 값:', event.oldValue);
  console.log('새 값:', event.newValue);
  console.log('출처:', event.url);
  // 같은 탭에서는 발생하지 않음 - 다른 탭 변경 시 발생
});

// --- sessionStorage 예제 ---
// 탭별 독립 상태 저장
function saveFormProgress(step, data) {
  sessionStorage.setItem(`form_step_${step}`, JSON.stringify(data));
}

function restoreFormProgress(step) {
  const data = sessionStorage.getItem(`form_step_${step}`);
  return data ? JSON.parse(data) : null;
}
```

---

## 4. IndexedDB

### 개념
- 브라우저 내장 **NoSQL 데이터베이스** (키-값 + 구조화 객체 저장)
- 비동기 API, 트랜잭션 지원, 인덱싱 가능
- 대용량 데이터, 오프라인 앱, PWA에 적합
- 직접 API 사용은 복잡하여 **idb** 같은 라이브러리 활용 권장

### 기본 사용 예제

```javascript
// --- 네이티브 IndexedDB API ---
function openDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('MyAppDB', 1); // DB명, 버전

    // 최초 생성 또는 버전 업그레이드 시 실행
    request.onupgradeneeded = (event) => {
      const db = event.target.result;

      // Object Store 생성 (테이블 개념)
      if (!db.objectStoreNames.contains('users')) {
        const store = db.createObjectStore('users', {
          keyPath: 'id',      // 기본 키 필드
          autoIncrement: false,
        });
        // 인덱스 생성 (빠른 검색용)
        store.createIndex('email', 'email', { unique: true });
        store.createIndex('name', 'name', { unique: false });
      }
    };

    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

// --- CRUD 작업 ---
async function dbOperations() {
  const db = await openDB();

  // 데이터 추가 (readwrite 트랜잭션)
  async function addUser(user) {
    return new Promise((resolve, reject) => {
      const tx = db.transaction('users', 'readwrite');
      const store = tx.objectStore('users');
      const req = store.add(user);
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  // 데이터 조회 (readonly 트랜잭션)
  async function getUser(id) {
    return new Promise((resolve, reject) => {
      const tx = db.transaction('users', 'readonly');
      const store = tx.objectStore('users');
      const req = store.get(id);
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  // 인덱스로 검색
  async function getUserByEmail(email) {
    return new Promise((resolve, reject) => {
      const tx = db.transaction('users', 'readonly');
      const index = tx.objectStore('users').index('email');
      const req = index.get(email);
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  // 전체 조회 (커서)
  async function getAllUsers() {
    return new Promise((resolve, reject) => {
      const tx = db.transaction('users', 'readonly');
      const store = tx.objectStore('users');
      const req = store.getAll();
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  // 데이터 수정
  async function updateUser(user) {
    return new Promise((resolve, reject) => {
      const tx = db.transaction('users', 'readwrite');
      const store = tx.objectStore('users');
      const req = store.put(user); // put: 없으면 추가, 있으면 교체
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  // 데이터 삭제
  async function deleteUser(id) {
    return new Promise((resolve, reject) => {
      const tx = db.transaction('users', 'readwrite');
      const store = tx.objectStore('users');
      const req = store.delete(id);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  }

  await addUser({ id: 1, name: 'Alice', email: 'alice@example.com' });
  const user = await getUser(1);
  console.log(user);
}

// --- idb 라이브러리 활용 (추천) ---
import { openDB } from 'idb';

const db = await openDB('MyAppDB', 1, {
  upgrade(db) {
    const store = db.createObjectStore('users', { keyPath: 'id' });
    store.createIndex('email', 'email');
  },
});

await db.add('users', { id: 1, name: 'Alice', email: 'alice@example.com' });
const user = await db.get('users', 1);
await db.put('users', { ...user, name: 'Alicia' });
await db.delete('users', 1);

// 트랜잭션으로 여러 작업 묶기
const tx = db.transaction('users', 'readwrite');
await Promise.all([
  tx.store.add({ id: 2, name: 'Bob', email: 'bob@example.com' }),
  tx.store.add({ id: 3, name: 'Carol', email: 'carol@example.com' }),
  tx.done,
]);
```

---

## 5. 사용 시나리오

### Cookie
- **인증 토큰(세션 ID, Refresh Token)**: `HttpOnly + Secure + SameSite=Strict` 설정으로 XSS/CSRF 방어
- **서버 사이드 렌더링(SSR)**: 서버에서 요청 시 쿠키를 함께 받아 인증 처리
- **GDPR 동의 여부**: 짧은 수명의 쿠키로 추적 동의 저장
- **A/B 테스트 그룹**: 사용자 그룹 배정 유지

### localStorage
- **사용자 설정**: 테마(다크/라이트), 언어, 폰트 크기
- **장기 캐시**: API 응답 캐싱 (단, TTL 직접 구현 필요)
- **장바구니**: 비로그인 사용자의 장바구니 데이터
- **JWT Access Token**: (단, XSS 취약 — HttpOnly 쿠키 권장)

### sessionStorage
- **단계별 폼(마법사)**: 각 스텝 데이터 임시 저장
- **페이지 이탈 방지**: 미저장 편집 내용 임시 보관
- **원타임 플래그**: 세션 내 특정 팝업 재표시 방지
- **탭별 독립 상태**: 같은 사이트를 여러 탭에서 다른 계정으로 사용

### IndexedDB
- **PWA 오프라인 데이터**: 캐시된 API 응답, 오프라인 큐
- **대용량 미디어**: 이미지, 동영상, 파일 캐싱
- **복잡한 로컬 데이터**: 메모 앱, 할일 앱의 대량 항목
- **오프라인 우선 앱**: 데이터를 로컬에 먼저 저장 후 서버 동기화

---

## 6. 면접 포인트

### Q1. localStorage와 sessionStorage의 차이는?
둘 다 Web Storage API로 문자열 키-값 저장이지만, localStorage는 탭/브라우저를 닫아도 영구 유지되고 동일 도메인의 모든 탭에서 공유됩니다. sessionStorage는 탭 단위로 독립되어 탭을 닫으면 삭제됩니다. 단계별 폼 같은 임시 데이터는 sessionStorage, 사용자 설정 같은 지속 데이터는 localStorage를 사용합니다.

### Q2. 쿠키의 HttpOnly와 Secure 속성이 왜 중요한가요?
`HttpOnly`는 JavaScript(`document.cookie`)로 쿠키를 읽지 못하게 하여 XSS 공격 시 세션 토큰 탈취를 방지합니다. `Secure`는 HTTPS 연결에서만 쿠키를 전송하여 네트워크 도청(중간자 공격)을 방지합니다. 인증 쿠키에는 두 속성을 반드시 설정해야 합니다.

### Q3. 인증 토큰을 어디에 저장해야 할까요?
Access Token은 짧은 수명으로 메모리 변수에 저장하거나 localStorage에 저장합니다. Refresh Token은 `HttpOnly + Secure` 쿠키에 저장하는 것이 가장 안전합니다. localStorage는 XSS에 취약하고, 쿠키는 CSRF에 취약하므로 `SameSite=Strict`와 CSRF 토큰을 함께 사용하는 것이 권장됩니다.

### Q4. IndexedDB를 직접 쓰지 않고 라이브러리를 쓰는 이유는?
네이티브 IndexedDB API는 콜백 기반의 복잡한 인터페이스를 가집니다. `idb` 라이브러리는 Promise/async-await 기반으로 간결하게 wrapping하여 생산성을 높입니다. Dexie.js는 더 나아가 쿼리 빌더와 React 훅까지 제공합니다.

### Q5. localStorage 용량이 초과되면 어떻게 되나요?
`QuotaExceededError` 예외가 발생합니다. 일반적으로 도메인당 5-10MB 제한이 있습니다. 용량 관리를 위해 불필요한 데이터를 삭제하거나, LRU(Least Recently Used) 캐시 전략을 구현하거나, 대용량은 IndexedDB로 이전해야 합니다. `try-catch`로 쓰기 실패를 반드시 처리해야 합니다.

### Q6. storage 이벤트는 어떤 용도로 사용하나요?
`window.addEventListener('storage', handler)`는 **다른 탭**에서 localStorage를 변경했을 때 발생합니다. 같은 탭에서는 발생하지 않습니다. 멀티 탭 환경에서 로그아웃 상태 동기화, 설정 변경 실시간 반영, 탭 간 메시지 전달에 활용됩니다.
