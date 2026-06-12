# 08. 비동기 처리 (Async)

## 목차
1. [Callback과 Callback Hell](#1-callback과-callback-hell)
2. [Promise](#2-promise)
3. [Promise 유틸리티 메서드](#3-promise-유틸리티-메서드)
4. [Async / Await](#4-async--await)
5. [에러 전파](#5-에러-전파)
6. [면접 포인트](#면접-포인트)

---

## 1. Callback과 Callback Hell

### 콜백 기반 비동기

초기 JS에서 비동기 완료 후 실행할 코드를 콜백으로 전달했다.

```js
function fetchUser(userId, callback) {
  setTimeout(() => {
    callback(null, { id: userId, name: 'Alice' }); // (error, result)
  }, 1000);
}

fetchUser(1, (err, user) => {
  if (err) return console.error(err);
  console.log(user);
});
```

### Callback Hell (콜백 지옥)

여러 비동기 작업을 순차적으로 처리할 때 중첩이 깊어지는 문제.

```js
// 유저 정보 → 게시글 → 댓글을 순서대로 가져오는 경우
fetchUser(1, (err, user) => {
  if (err) return handleError(err);
  fetchPosts(user.id, (err, posts) => {
    if (err) return handleError(err);
    fetchComments(posts[0].id, (err, comments) => {
      if (err) return handleError(err);
      fetchLikes(comments[0].id, (err, likes) => {
        if (err) return handleError(err);
        // 점점 오른쪽으로 밀려나는 피라미드 형태
        console.log(likes);
      });
    });
  });
});
```

**문제점:**
- 가독성 저하 (피라미드 of doom)
- 에러 처리 중복
- 흐름 제어 어려움 (병렬 실행, 취소 등)

---

## 2. Promise

Promise는 비동기 작업의 **최종 완료 또는 실패**를 나타내는 객체다.

### Promise 상태

```
Pending  →  Fulfilled (resolve 호출)
         →  Rejected  (reject 호출)
```

한 번 `Fulfilled` 또는 `Rejected` 상태가 되면 **변경 불가(settled)**.

```js
const promise = new Promise((resolve, reject) => {
  // 비동기 작업 수행
  const success = true;

  if (success) {
    resolve('성공 데이터'); // Fulfilled로 전환
  } else {
    reject(new Error('실패 이유')); // Rejected로 전환
  }
});

promise
  .then(data => console.log('성공:', data))   // 'Fulfilled' 처리
  .catch(err => console.error('실패:', err)); // 'Rejected' 처리
```

### Promise 체이닝

`.then()`은 항상 새로운 Promise를 반환하므로 체인이 가능하다.

```js
function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function fetchUser(id) {
  return delay(500).then(() => ({ id, name: 'Alice', postId: 10 }));
}

function fetchPost(postId) {
  return delay(300).then(() => ({ id: postId, title: '첫 번째 글', commentId: 5 }));
}

function fetchComment(commentId) {
  return delay(200).then(() => ({ id: commentId, text: '좋은 글이네요!' }));
}

// 콜백 지옥을 Promise 체이닝으로 해결
fetchUser(1)
  .then(user => fetchPost(user.postId))
  .then(post => fetchComment(post.commentId))
  .then(comment => console.log(comment.text)) // '좋은 글이네요!'
  .catch(err => console.error('에러:', err));  // 체인 어디서든 발생한 에러 처리
```

### `.then()` 반환값 규칙

```js
Promise.resolve(1)
  .then(v => v + 1)           // 값 반환 → 해당 값으로 resolve된 Promise
  .then(v => Promise.resolve(v * 2)) // Promise 반환 → 그 Promise를 기다림
  .then(v => { throw new Error('에러') }) // throw → rejected Promise
  .then(v => console.log('실행 안 됨'))
  .catch(err => console.log('잡힘:', err.message)); // '잡힘: 에러'
```

---

## 3. Promise 유틸리티 메서드

### `Promise.all()` - 모두 성공해야 통과

```js
const p1 = Promise.resolve(1);
const p2 = delay(100).then(() => 2);
const p3 = delay(200).then(() => 3);

// 모두 fulfilled일 때 결과 배열 반환
Promise.all([p1, p2, p3])
  .then(([a, b, c]) => console.log(a, b, c)) // 1 2 3
  .catch(err => console.error('하나라도 실패:', err));

// 하나라도 reject되면 즉시 reject
Promise.all([
  Promise.resolve(1),
  Promise.reject(new Error('실패')),
  Promise.resolve(3)
]).catch(err => console.log(err.message)); // '실패'
```

### `Promise.race()` - 가장 빠른 것

```js
// 가장 먼저 settled된 Promise의 결과를 따름
Promise.race([
  delay(300).then(() => '느림'),
  delay(100).then(() => '빠름'),
  delay(200).then(() => '중간')
]).then(result => console.log(result)); // '빠름'

// 타임아웃 구현에 활용
function withTimeout(promise, ms) {
  const timeout = new Promise((_, reject) =>
    setTimeout(() => reject(new Error(`${ms}ms 초과`)), ms)
  );
  return Promise.race([promise, timeout]);
}

withTimeout(fetchUser(1), 200)
  .then(user => console.log(user))
  .catch(err => console.log(err.message)); // 조건에 따라 타임아웃 발생
```

### `Promise.allSettled()` - 모두 완료될 때까지 (성공/실패 무관)

```js
// 성공/실패 모두 기다린 후 상태 배열 반환
Promise.allSettled([
  Promise.resolve('성공'),
  Promise.reject(new Error('실패')),
  Promise.resolve(42)
]).then(results => {
  results.forEach(result => {
    if (result.status === 'fulfilled') {
      console.log('성공:', result.value);
    } else {
      console.log('실패:', result.reason.message);
    }
  });
});
// 성공: 성공
// 실패: 실패
// 성공: 42
```

### `Promise.any()` - 하나라도 성공하면

```js
// 하나라도 fulfilled되면 그 값을 resolve
// 모두 reject되면 AggregateError를 reject
Promise.any([
  Promise.reject(new Error('에러1')),
  delay(100).then(() => '성공!'),
  Promise.reject(new Error('에러2'))
]).then(result => console.log(result)); // '성공!'

// 모두 실패
Promise.any([
  Promise.reject(new Error('에러1')),
  Promise.reject(new Error('에러2'))
]).catch(err => {
  console.log(err instanceof AggregateError); // true
  console.log(err.errors);                    // [Error: 에러1, Error: 에러2]
});
```

| 메서드 | 성공 조건 | 실패 조건 | 용도 |
|--------|-----------|-----------|------|
| `Promise.all` | 전부 성공 | 하나라도 실패 | 여러 요청을 병렬로, 모두 필요할 때 |
| `Promise.race` | 가장 먼저 settled | 가장 먼저 rejected | 타임아웃, 경쟁 |
| `Promise.allSettled` | 전부 settled | 없음 | 결과 집계 (실패 허용) |
| `Promise.any` | 하나라도 성공 | 전부 실패 | 여러 소스 중 빠른 것 |

---

## 4. Async / Await

`async/await`는 Promise 위에서 동작하는 **문법적 설탕**으로, 비동기 코드를 동기 코드처럼 읽힌다.

```js
// Promise 체이닝 버전
function loadData() {
  return fetchUser(1)
    .then(user => fetchPost(user.postId))
    .then(post => fetchComment(post.commentId))
    .then(comment => comment.text);
}

// async/await 버전 (동일한 동작)
async function loadData() {
  const user    = await fetchUser(1);
  const post    = await fetchPost(user.postId);
  const comment = await fetchComment(post.commentId);
  return comment.text; // 자동으로 Promise.resolve(comment.text) 반환
}

loadData().then(text => console.log(text));
```

### `async` 함수의 반환값

```js
async function example() {
  return 42; // Promise.resolve(42)와 동일
}

async function example2() {
  return Promise.resolve(42); // 그대로 전달
}

async function example3() {
  throw new Error('실패'); // Promise.reject(new Error('실패'))와 동일
}

example().then(v => console.log(v));   // 42
example3().catch(e => console.log(e.message)); // '실패'
```

### 병렬 처리 with async/await

```js
// 순차 처리 (느림) - 각 await가 끝날 때까지 기다림
async function sequential() {
  const user1 = await fetchUser(1); // 500ms
  const user2 = await fetchUser(2); // 500ms (user1 완료 후 시작)
  return [user1, user2]; // 총 ~1000ms
}

// 병렬 처리 (빠름) - 동시에 시작
async function parallel() {
  const [user1, user2] = await Promise.all([
    fetchUser(1), // 동시 시작
    fetchUser(2)  // 동시 시작
  ]);
  return [user1, user2]; // 총 ~500ms
}

// await를 잘못 쓴 패턴
async function badParallel() {
  const p1 = fetchUser(1); // Promise 시작 (await 안 씀)
  const p2 = fetchUser(2); // Promise 시작 (await 안 씀)
  const user1 = await p1;  // 기다림
  const user2 = await p2;  // 이미 거의 완료됨
  return [user1, user2]; // 사실상 병렬이지만 권장하지 않는 스타일
}
```

---

## 5. 에러 전파

### Promise 체인에서의 에러 전파

```js
Promise.resolve()
  .then(() => { throw new Error('1번에서 에러'); })
  .then(() => console.log('2번: 실행 안 됨'))  // 건너뜀
  .then(() => console.log('3번: 실행 안 됨'))  // 건너뜀
  .catch(err => {
    console.log('catch:', err.message); // 'catch: 1번에서 에러'
    return '복구됨'; // catch에서 값을 반환하면 이후 체인이 정상 진행
  })
  .then(v => console.log('4번:', v)); // '4번: 복구됨'
```

### async/await에서의 에러 처리

```js
// try/catch 사용
async function loadData() {
  try {
    const user = await fetchUser(1);
    const post = await fetchPost(user.postId);
    return post;
  } catch (err) {
    console.error('데이터 로드 실패:', err.message);
    return null; // 기본값 반환
  } finally {
    console.log('항상 실행'); // 성공/실패 무관
  }
}

// catch 메서드 사용
async function loadData2() {
  const user = await fetchUser(1).catch(err => {
    console.warn('유저 로드 실패, 기본값 사용');
    return { id: 0, name: '게스트', postId: null }; // 기본값
  });

  if (!user.postId) return null;
  return fetchPost(user.postId);
}
```

### 처리되지 않은 Promise 거부 (Unhandled Rejection)

```js
// 위험: catch 없는 rejected Promise
async function danger() {
  throw new Error('처리 안 된 에러');
}
danger(); // UnhandledPromiseRejectionWarning

// 안전: 반드시 catch 처리
danger().catch(err => console.error(err));

// 전역 핸들러 (최후의 수단)
process.on('unhandledRejection', (reason, promise) => {
  console.error('처리되지 않은 거부:', reason);
});

window.addEventListener('unhandledrejection', (event) => {
  console.error('처리되지 않은 거부:', event.reason);
  event.preventDefault(); // 브라우저 콘솔 에러 숨기기
});
```

---

## 면접 포인트

**Q. Promise의 세 가지 상태는?**
> `Pending`(대기), `Fulfilled`(이행), `Rejected`(거부). 한 번 Fulfilled 또는 Rejected가 되면 상태가 변하지 않는다(immutable). `.then()`은 Fulfilled 시, `.catch()`는 Rejected 시 실행된다.

**Q. `Promise.all`과 `Promise.allSettled`의 차이는?**
> `Promise.all`은 하나라도 reject되면 즉시 reject되어 나머지 결과를 알 수 없다. `Promise.allSettled`는 모두 완료될 때까지 기다린 후 각각의 성공/실패 상태를 배열로 반환한다. 독립적인 여러 작업의 결과를 모두 확인할 때는 `allSettled`를 사용한다.

**Q. async/await는 내부적으로 어떻게 동작하나요?**
> `async` 함수는 항상 Promise를 반환한다. `await`는 해당 Promise가 settled될 때까지 함수 실행을 일시 중단하고, 이후 코드를 Microtask로 등록한다. 이벤트 루프를 블로킹하지 않으므로 다른 코드가 실행될 수 있다.

**Q. async/await에서 병렬 처리는 어떻게 하나요?**
> `await`를 각각 사용하면 순차 실행된다. 병렬로 실행하려면 `Promise.all()`에 Promise 배열을 넘기거나, 먼저 Promise를 생성(시작)하고 나중에 `await`한다. 독립적인 작업이라면 항상 `Promise.all()`을 활용하는 것이 성능상 유리하다.

**Q. Promise 체인에서 에러는 어떻게 전파되나요?**
> 체인 중 어디서든 throw가 발생하거나 rejected Promise가 반환되면 이후 `.then()`은 건너뛰고 가장 가까운 `.catch()`로 이동한다. `.catch()` 내에서 값을 반환하면 이후 체인이 정상 진행된다. async/await에서는 `try/catch`로 동일하게 처리한다.
