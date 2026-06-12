# 6. Web Storage 심화

## 목차
1. 스토리지 종류 비교
2. IndexedDB 패턴 (idb 라이브러리)
3. Cache API (Service Worker와 조합)
4. Origin Private File System (OPFS)
5. 면접 포인트

---

## 1. 스토리지 종류 비교

| 항목 | localStorage | sessionStorage | IndexedDB | Cache API | OPFS |
|------|-------------|---------------|-----------|-----------|------|
| 용량 | ~5–10MB | ~5MB | 수백MB~GB | 수백MB~GB | GB+ |
| 구조 | key-value (string) | key-value (string) | 객체 DB | Request/Response | 파일 시스템 |
| 비동기 | 동기 | 동기 | 비동기 | 비동기 | 비동기 |
| Worker 접근 | 불가 | 불가 | 가능 | 가능 | 가능 |
| 영속성 | 영구 | 탭 종료 시 삭제 | 영구 | 영구 | 영구 |

---

## 2. IndexedDB 패턴 (idb 라이브러리)

로우레벨 IndexedDB API는 verbose하므로 `idb` 라이브러리로 래핑해 사용하는 것이 일반적이다.

```bash
npm install idb
```

### DB 초기화

```js
import { openDB } from 'idb';

const dbPromise = openDB('my-app-db', 2, {
  upgrade(db, oldVersion, newVersion, transaction) {
    // version 1: notes 스토어 생성
    if (oldVersion < 1) {
      const notesStore = db.createObjectStore('notes', {
        keyPath: 'id',
        autoIncrement: true,
      });
      notesStore.createIndex('by-date', 'createdAt');
      notesStore.createIndex('by-tag', 'tags', { multiEntry: true });
    }
    // version 2: 컬럼 추가 (기존 데이터 마이그레이션)
    if (oldVersion < 2) {
      const store = transaction.objectStore('notes');
      store.createIndex('by-title', 'title');
    }
  },
  blocked() {
    alert('이전 탭을 닫아주세요. DB 업그레이드를 위해 필요합니다.');
  },
  blocking() {
    // 이 탭이 다른 탭의 업그레이드를 막고 있음
    db.close();
    location.reload();
  },
});
```

### CRUD 작업

```js
const db = await dbPromise;

// Create
const id = await db.add('notes', {
  title: '제목',
  content: '내용',
  tags: ['js', 'web'],
  createdAt: new Date(),
});

// Read
const note = await db.get('notes', id);
const allNotes = await db.getAll('notes');

// Index로 조회
const byDate = await db.getAllFromIndex('notes', 'by-date');
const tagged = await db.getAllFromIndex('notes', 'by-tag', 'js');

// Update
await db.put('notes', { ...note, title: '수정된 제목' });

// Delete
await db.delete('notes', id);

// Count
const count = await db.count('notes');
```

### 트랜잭션 (Atomic 작업)

```js
const db = await dbPromise;

// 여러 작업을 하나의 트랜잭션으로 묶기
const tx = db.transaction(['notes', 'tags'], 'readwrite');

try {
  await tx.objectStore('notes').add({ title: '새 노트', tagId: 1 });
  await tx.objectStore('tags').put({ id: 1, name: 'js', count: 5 });
  await tx.done; // 커밋
} catch (err) {
  // 자동 롤백
  console.error('트랜잭션 실패:', err);
}
```

### 커서로 대량 데이터 처리

```js
const db = await dbPromise;
const tx = db.transaction('notes', 'readonly');
let cursor = await tx.store.openCursor();

while (cursor) {
  console.log(cursor.key, cursor.value);
  cursor = await cursor.continue();
}
```

---

## 3. Cache API (Service Worker와 조합)

```js
// 캐시에 저장
const cache = await caches.open('api-cache-v1');
await cache.put('/api/config', new Response(JSON.stringify(config), {
  headers: { 'Content-Type': 'application/json' },
}));

// 조회
const cached = await caches.match('/api/config');
if (cached) {
  const data = await cached.json();
}

// URL 추가 (자동 fetch 후 저장)
await cache.add('/static/logo.png');
await cache.addAll(['/index.html', '/app.js', '/style.css']);

// 삭제
await cache.delete('/api/old-endpoint');

// 캐시 목록 확인
const cacheNames = await caches.keys();
```

### 캐시 전략 패턴

```js
// 1. Cache First (오프라인 우선)
async function cacheFirst(request) {
  const cached = await caches.match(request);
  return cached || fetch(request);
}

// 2. Network First (최신 데이터 우선)
async function networkFirst(request, cacheName) {
  try {
    const response = await fetch(request);
    const cache = await caches.open(cacheName);
    cache.put(request, response.clone()); // 클론해서 저장 (body는 한 번만 읽힘)
    return response;
  } catch {
    return caches.match(request);
  }
}

// 3. Stale While Revalidate (빠른 응답 + 백그라운드 갱신)
async function staleWhileRevalidate(request, cacheName) {
  const cache = await caches.open(cacheName);
  const cached = await cache.match(request);

  const networkPromise = fetch(request).then(response => {
    cache.put(request, response.clone());
    return response;
  });

  return cached || networkPromise;
}
```

---

## 4. Origin Private File System (OPFS)

OPFS는 origin에 격리된 파일 시스템으로, 일반 파일 시스템과 달리 브라우저 내부에서만 접근 가능하다.
Web Worker에서 동기 API를 사용할 수 있어 SQLite 같은 라이브러리 포팅에 사용된다.

```js
// 루트 디렉토리 접근
const root = await navigator.storage.getDirectory();

// 파일 생성/열기
const fileHandle = await root.getFileHandle('data.json', { create: true });

// 쓰기
const writable = await fileHandle.createWritable();
await writable.write(JSON.stringify({ key: 'value' }));
await writable.close();

// 읽기
const file = await fileHandle.getFile();
const text = await file.text();
const data = JSON.parse(text);

// 디렉토리 생성
const dir = await root.getDirectoryHandle('images', { create: true });

// 파일 목록
for await (const [name, handle] of root.entries()) {
  console.log(name, handle.kind); // 'file' | 'directory'
}

// 삭제
await root.removeEntry('data.json');
await root.removeEntry('images', { recursive: true });
```

### Worker에서 동기 API (고성능)

```js
// worker.js — Web Worker 내에서만 사용 가능
const root = await navigator.storage.getDirectory();
const fileHandle = await root.getFileHandle('db.sqlite', { create: true });

// createSyncAccessHandle: 동기 읽기/쓰기 (Worker only)
const accessHandle = await fileHandle.createSyncAccessHandle();

const buffer = new DataView(new ArrayBuffer(1024));
const bytesRead = accessHandle.read(buffer, { at: 0 });

accessHandle.write(new TextEncoder().encode('hello'), { at: 0 });
accessHandle.flush();
accessHandle.close();
```

### 저장 용량 확인

```js
const estimate = await navigator.storage.estimate();
console.log(`사용: ${estimate.usage} bytes`);
console.log(`할당: ${estimate.quota} bytes`);
console.log(`여유: ${estimate.quota - estimate.usage} bytes`);
```

---

## 5. 면접 포인트

**Q. localStorage와 sessionStorage의 차이는?**

`localStorage`는 같은 origin의 모든 탭에서 공유되고 영구 저장된다. `sessionStorage`는 같은 탭(정확히는 같은 browsing context) 내에서만 공유되고 탭을 닫으면 삭제된다. 새 탭에서 열거나 `window.open()`으로 열면 별개의 sessionStorage를 가진다.

**Q. IndexedDB를 직접 사용하지 않고 idb를 쓰는 이유는?**

네이티브 IndexedDB는 콜백 기반이고, 트랜잭션 관리가 복잡하다. `idb`는 Promise 기반의 얇은 래퍼로, 타입스크립트 지원도 우수하다. 성능 오버헤드는 거의 없다.

**Q. Cache API와 IndexedDB의 차이는?**

Cache API는 `Request/Response` 쌍을 저장하는 HTTP 캐시 전용 스토리지다. IndexedDB는 임의 JS 객체를 저장하는 범용 DB다. 네트워크 응답 캐싱에는 Cache API, 앱 데이터 저장에는 IndexedDB를 사용한다.

**Q. OPFS가 File System Access API와 다른 점은?**

File System Access API(`showOpenFilePicker()` 등)는 사용자가 선택한 실제 파일 시스템에 접근한다. OPFS는 브라우저가 관리하는 origin별 격리된 가상 파일 시스템이다. OPFS는 권한 없이 접근 가능하고, Worker에서 동기 API를 지원해 SQLite.wasm 등의 기반으로 활용된다.
