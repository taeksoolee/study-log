# Iterator (이터레이터 패턴)

## 목차
1. [개념](#1-개념)
2. [JS Symbol.iterator와의 연결](#2-js-symboliterator와의-연결)
3. [커스텀 이터레이터 구현](#3-커스텀-이터레이터-구현)
4. [제너레이터를 활용한 이터레이터](#4-제너레이터를-활용한-이터레이터)
5. [실용 예시 — 페이지네이션 이터레이터](#5-실용-예시--페이지네이션-이터레이터)
6. [면접 포인트](#6-면접-포인트)

---

## 1. 개념

> 컬렉션의 내부 구조를 노출하지 않고 **순차적으로 요소에 접근**하는 방법을 제공한다.

**언제 쓰는가?**
- 다양한 컬렉션 타입을 일관된 방법으로 순회할 때
- 컬렉션의 구현 세부사항을 감출 때
- 여러 순회 방식이 필요할 때 (전위, 후위, 역순 등)
- 지연 평가(lazy evaluation)가 필요할 때

**JS 내장 이터러블 프로토콜**
```javascript
// [Symbol.iterator]() 메서드를 가진 객체 = 이터러블
// next() 메서드를 가진 객체 = 이터레이터
// { value, done } 을 반환하는 객체 = 이터레이터 결과
```

---

## 2. JS Symbol.iterator와의 연결

```typescript
// JS의 모든 이터러블은 이터레이터 패턴을 구현
const arr = [1, 2, 3];
const str = 'Hello';
const map = new Map([['a', 1], ['b', 2]]);
const set = new Set([1, 2, 3]);

// for...of 는 이터레이터 프로토콜을 사용
for (const item of arr) { console.log(item); }
for (const char of str) { console.log(char); }

// 이터레이터를 직접 사용
const iterator = arr[Symbol.iterator]();
console.log(iterator.next()); // { value: 1, done: false }
console.log(iterator.next()); // { value: 2, done: false }
console.log(iterator.next()); // { value: 3, done: false }
console.log(iterator.next()); // { value: undefined, done: true }

// 스프레드 연산자도 이터레이터 프로토콜 사용
const copy = [...arr];
const [first, ...rest] = arr;
```

---

## 3. 커스텀 이터레이터 구현

```typescript
// 범위(Range) 이터레이터
class Range implements Iterable<number> {
  constructor(
    private start: number,
    private end: number,
    private step: number = 1,
  ) {}

  [Symbol.iterator](): Iterator<number> {
    let current = this.start;
    const end = this.end;
    const step = this.step;

    return {
      next(): IteratorResult<number> {
        if (current <= end) {
          const value = current;
          current += step;
          return { value, done: false };
        }
        return { value: undefined as any, done: true };
      },
    };
  }
}

// 사용 — for...of, 스프레드, 구조분해 모두 사용 가능
const range = new Range(1, 10, 2);
for (const n of range) {
  console.log(n); // 1, 3, 5, 7, 9
}

console.log([...new Range(0, 4)]); // [0, 1, 2, 3, 4]

// 트리 이터레이터 — 복잡한 자료구조 순회
class TreeNode<T> {
  children: TreeNode<T>[] = [];
  constructor(public value: T) {}
}

class Tree<T> implements Iterable<T> {
  constructor(private root: TreeNode<T>) {}

  // 깊이 우선 순회 (DFS)
  [Symbol.iterator](): Iterator<T> {
    const stack: TreeNode<T>[] = [this.root];
    return {
      next(): IteratorResult<T> {
        if (stack.length === 0) {
          return { value: undefined as any, done: true };
        }
        const node = stack.pop()!;
        // 역순으로 push (오른쪽 먼저 push → 왼쪽 먼저 처리)
        for (let i = node.children.length - 1; i >= 0; i--) {
          stack.push(node.children[i]);
        }
        return { value: node.value, done: false };
      },
    };
  }
}

// 트리 구성
const root = new TreeNode('root');
const child1 = new TreeNode('child1');
const child2 = new TreeNode('child2');
child1.children.push(new TreeNode('leaf1'), new TreeNode('leaf2'));
root.children.push(child1, child2);

const tree = new Tree(root);
console.log([...tree]); // ['root', 'child1', 'leaf1', 'leaf2', 'child2']
```

---

## 4. 제너레이터를 활용한 이터레이터

제너레이터 함수는 이터레이터를 훨씬 간결하게 만든다.

```typescript
// 제너레이터로 구현한 Range
function* range(start: number, end: number, step = 1): Generator<number> {
  for (let i = start; i <= end; i += step) {
    yield i;
  }
}

// 무한 수열 이터레이터
function* fibonacci(): Generator<number> {
  let [a, b] = [0, 1];
  while (true) {
    yield a;
    [a, b] = [b, a + b];
  }
}

// 처음 10개의 피보나치 수
function take<T>(iterable: Iterable<T>, n: number): T[] {
  const result: T[] = [];
  for (const item of iterable) {
    result.push(item);
    if (result.length >= n) break;
  }
  return result;
}

console.log(take(fibonacci(), 10));
// [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]

// 제너레이터 파이프라인 — 지연 평가
function* map<T, U>(iterable: Iterable<T>, fn: (item: T) => U): Generator<U> {
  for (const item of iterable) {
    yield fn(item);
  }
}

function* filter<T>(iterable: Iterable<T>, predicate: (item: T) => boolean): Generator<T> {
  for (const item of iterable) {
    if (predicate(item)) yield item;
  }
}

// 1~1000 중 짝수의 제곱 중 처음 5개 — 전체를 배열로 만들지 않음 (지연 평가)
const result = take(
  map(
    filter(range(1, 1000), n => n % 2 === 0),
    n => n * n,
  ),
  5,
);
console.log(result); // [4, 16, 36, 64, 100]
```

---

## 5. 실용 예시 — 페이지네이션 이터레이터

```typescript
// API 페이지네이션을 이터레이터로 추상화
async function* fetchAllPages<T>(
  url: string,
  pageSize = 20,
): AsyncGenerator<T[]> {
  let page = 1;
  let hasMore = true;

  while (hasMore) {
    const response = await fetch(`${url}?page=${page}&limit=${pageSize}`);
    const data = await response.json();

    yield data.items as T[];

    hasMore = data.hasNextPage;
    page++;
  }
}

// 사용 — 모든 페이지를 자동으로 순회
interface User { id: number; name: string; }

async function processAllUsers() {
  for await (const users of fetchAllPages<User>('/api/users')) {
    for (const user of users) {
      console.log(`처리: ${user.name}`);
    }
  }
}

// 커서 기반 이터레이터
async function* cursorPagination<T>(
  fetcher: (cursor: string | null) => Promise<{ items: T[]; nextCursor: string | null }>,
): AsyncGenerator<T> {
  let cursor: string | null = null;

  do {
    const { items, nextCursor } = await fetcher(cursor);
    for (const item of items) {
      yield item; // 아이템 하나씩 yield
    }
    cursor = nextCursor;
  } while (cursor !== null);
}
```

---

## 6. 면접 포인트

**Q1. 이터레이터 패턴이란 무엇인가요?**
> 컬렉션의 내부 구현을 노출하지 않고 순차적으로 요소에 접근하는 방법을 제공하는 패턴입니다. 다양한 자료구조를 일관된 인터페이스로 순회할 수 있습니다.

**Q2. JS의 Symbol.iterator와 이터레이터 패턴의 관계는?**
> `Symbol.iterator`가 이터레이터 프로토콜로, GoF 이터레이터 패턴의 JS 구현입니다. 이를 구현하면 `for...of`, 스프레드, 구조분해 등 모든 이터러블 문법을 사용할 수 있습니다.

**Q3. 이터레이터와 제너레이터의 차이는?**
> 이터레이터는 `next()`를 가진 객체입니다. 제너레이터는 `function*`으로 정의되어 자동으로 이터레이터를 반환하는 함수입니다. 제너레이터가 이터레이터를 더 간결하게 구현할 수 있게 해줍니다.

**Q4. 이터레이터의 지연 평가(lazy evaluation) 장점은?**
> 전체 컬렉션을 메모리에 올리지 않고 필요할 때만 다음 값을 계산합니다. 무한 수열이나 대용량 데이터 처리, 네트워크 페이지네이션에서 메모리 효율이 높습니다.

---

[← Command](./02-command.md) | [← 행동 패턴 목차](./README.md) | [다음: Mediator →](./04-mediator.md)
