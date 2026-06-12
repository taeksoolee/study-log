# 2. 연결 리스트 (Linked List)

## 목차
1. 연결 리스트 개념과 배열 비교
2. 단방향 연결 리스트 JavaScript 구현
3. 양방향 연결 리스트 JavaScript 구현
4. 시간복잡도 분석
5. 자주 나오는 패턴
   - 중간 노드 찾기 (Fast/Slow 포인터)
   - 역순으로 뒤집기
   - 사이클 감지 (Floyd 알고리즘)
   - 두 리스트 병합
6. 면접 포인트

---

## 1. 연결 리스트 개념과 배열 비교

연결 리스트(Linked List)는 노드(Node)들이 포인터(참조)로 연결된 선형 자료구조입니다.
각 노드는 데이터(value)와 다음 노드를 가리키는 포인터(next)를 가집니다.

### 배열 vs 연결 리스트

| 특성               | 배열 (Array)             | 연결 리스트 (Linked List)     |
|-------------------|--------------------------|-------------------------------|
| 메모리 구조        | 연속된 메모리 공간        | 분산된 메모리 (포인터로 연결)  |
| 인덱스 접근        | O(1)                     | O(n)                          |
| 검색               | O(n)                     | O(n)                          |
| 앞에 삽입/삭제     | O(n)                     | O(1)                          |
| 끝에 삽입/삭제     | O(1)*                    | O(1) (tail 포인터 유지 시)    |
| 중간 삽입/삭제     | O(n)                     | O(1) (노드 위치를 알 때)      |
| 추가 메모리        | 없음                      | 포인터 저장을 위한 추가 공간  |
| 캐시 효율          | 높음 (연속 메모리)        | 낮음 (분산 메모리)            |

**언제 연결 리스트가 유리한가?**
- 삽입/삭제가 빈번하고, 특히 앞부분에서 자주 발생하는 경우
- 크기를 미리 알 수 없어 동적 크기 조정이 필요한 경우
- Stack, Queue 구현 시 (특히 O(1) 보장이 필요할 때)

---

## 2. 단방향 연결 리스트 JavaScript 구현

### Node 클래스

```js
class ListNode {
  constructor(value) {
    this.value = value;
    this.next = null;
  }
}
```

### 단방향 연결 리스트 (Singly Linked List)

```js
class SinglyLinkedList {
  constructor() {
    this.head = null;
    this.tail = null;
    this.length = 0;
  }

  // 끝에 노드 추가 O(1)
  push(value) {
    const node = new ListNode(value);
    if (!this.head) {
      this.head = node;
      this.tail = node;
    } else {
      this.tail.next = node;
      this.tail = node;
    }
    this.length++;
    return this;
  }

  // 끝에서 노드 제거 O(n) — tail의 이전 노드를 찾아야 함
  pop() {
    if (!this.head) return undefined;

    let current = this.head;
    let prev = null;

    while (current.next) {
      prev = current;
      current = current.next;
    }

    if (prev) {
      prev.next = null;
      this.tail = prev;
    } else {
      // 노드가 하나였던 경우
      this.head = null;
      this.tail = null;
    }

    this.length--;
    return current.value;
  }

  // 앞에 노드 추가 O(1)
  unshift(value) {
    const node = new ListNode(value);
    if (!this.head) {
      this.head = node;
      this.tail = node;
    } else {
      node.next = this.head;
      this.head = node;
    }
    this.length++;
    return this;
  }

  // 앞에서 노드 제거 O(1)
  shift() {
    if (!this.head) return undefined;

    const value = this.head.value;
    this.head = this.head.next;
    if (!this.head) this.tail = null;
    this.length--;
    return value;
  }

  // 인덱스로 노드 접근 O(n)
  get(index) {
    if (index < 0 || index >= this.length) return null;

    let current = this.head;
    let i = 0;

    while (i < index) {
      current = current.next;
      i++;
    }

    return current;
  }

  // 인덱스 위치 값 변경 O(n)
  set(index, value) {
    const node = this.get(index);
    if (!node) return false;
    node.value = value;
    return true;
  }

  // 특정 인덱스에 삽입 O(n)
  insert(index, value) {
    if (index < 0 || index > this.length) return false;
    if (index === 0) return !!this.unshift(value);
    if (index === this.length) return !!this.push(value);

    const node = new ListNode(value);
    const prev = this.get(index - 1);
    node.next = prev.next;
    prev.next = node;
    this.length++;
    return true;
  }

  // 특정 인덱스 노드 제거 O(n)
  remove(index) {
    if (index < 0 || index >= this.length) return undefined;
    if (index === 0) return this.shift();
    if (index === this.length - 1) return this.pop();

    const prev = this.get(index - 1);
    const removed = prev.next;
    prev.next = removed.next;
    this.length--;
    return removed.value;
  }

  // 배열로 변환 (디버깅용)
  toArray() {
    const result = [];
    let current = this.head;
    while (current) {
      result.push(current.value);
      current = current.next;
    }
    return result;
  }
}

// 사용 예시
const list = new SinglyLinkedList();
list.push(1).push(2).push(3);
console.log(list.toArray()); // [1, 2, 3]
list.unshift(0);
console.log(list.toArray()); // [0, 1, 2, 3]
list.insert(2, 1.5);
console.log(list.toArray()); // [0, 1, 1.5, 2, 3]
```

---

## 3. 양방향 연결 리스트 JavaScript 구현

양방향 연결 리스트(Doubly Linked List)는 각 노드가 이전 노드(prev)와
다음 노드(next)를 모두 참조합니다. 뒤에서부터 탐색이 가능하여 pop이 O(1)입니다.
단, 포인터를 두 개 유지해야 하므로 메모리 사용량이 늘어납니다.

```js
class DListNode {
  constructor(value) {
    this.value = value;
    this.prev = null;
    this.next = null;
  }
}

class DoublyLinkedList {
  constructor() {
    this.head = null;
    this.tail = null;
    this.length = 0;
  }

  // 끝에 노드 추가 O(1)
  push(value) {
    const node = new DListNode(value);
    if (!this.head) {
      this.head = node;
      this.tail = node;
    } else {
      node.prev = this.tail;
      this.tail.next = node;
      this.tail = node;
    }
    this.length++;
    return this;
  }

  // 끝에서 노드 제거 O(1) — 단방향과 달리 O(1) 보장
  pop() {
    if (!this.tail) return undefined;

    const value = this.tail.value;
    const newTail = this.tail.prev;

    if (newTail) {
      newTail.next = null;
      this.tail = newTail;
    } else {
      this.head = null;
      this.tail = null;
    }

    this.length--;
    return value;
  }

  // 앞에 노드 추가 O(1)
  unshift(value) {
    const node = new DListNode(value);
    if (!this.head) {
      this.head = node;
      this.tail = node;
    } else {
      node.next = this.head;
      this.head.prev = node;
      this.head = node;
    }
    this.length++;
    return this;
  }

  // 앞에서 노드 제거 O(1)
  shift() {
    if (!this.head) return undefined;

    const value = this.head.value;
    const newHead = this.head.next;

    if (newHead) {
      newHead.prev = null;
      this.head = newHead;
    } else {
      this.head = null;
      this.tail = null;
    }

    this.length--;
    return value;
  }

  // 인덱스로 노드 접근 — 중간에서 앞뒤 방향 선택으로 최대 n/2 O(n)
  get(index) {
    if (index < 0 || index >= this.length) return null;

    let current;
    if (index <= this.length / 2) {
      current = this.head;
      for (let i = 0; i < index; i++) current = current.next;
    } else {
      current = this.tail;
      for (let i = this.length - 1; i > index; i--) current = current.prev;
    }

    return current;
  }

  toArray() {
    const result = [];
    let current = this.head;
    while (current) {
      result.push(current.value);
      current = current.next;
    }
    return result;
  }
}
```

---

## 4. 시간복잡도 분석

| 연산                | 단방향 (Singly) | 양방향 (Doubly) |
|--------------------|-----------------|-----------------|
| 앞에 삽입 (unshift) | O(1)            | O(1)            |
| 앞에서 삭제 (shift) | O(1)            | O(1)            |
| 끝에 삽입 (push)   | O(1)            | O(1)            |
| 끝에서 삭제 (pop)  | O(n)            | O(1)            |
| 중간 접근 (get)    | O(n)            | O(n/2) ≈ O(n)   |
| 중간 삽입/삭제     | O(n)            | O(n)            |
| 검색               | O(n)            | O(n)            |

---

## 5. 자주 나오는 패턴

### 5-1. 중간 노드 찾기 (Fast/Slow 포인터)

Fast 포인터는 두 칸씩, Slow 포인터는 한 칸씩 이동하면
Fast가 끝에 도달했을 때 Slow는 중간에 위치합니다.

```js
function findMiddle(head) {
  let slow = head;
  let fast = head;

  while (fast !== null && fast.next !== null) {
    slow = slow.next;
    fast = fast.next.next;
  }

  return slow; // 중간 노드
}

// 테스트용 리스트 생성 헬퍼
function createList(arr) {
  const dummy = new ListNode(0);
  let cur = dummy;
  for (const v of arr) {
    cur.next = new ListNode(v);
    cur = cur.next;
  }
  return dummy.next;
}

const head = createList([1, 2, 3, 4, 5]);
console.log(findMiddle(head).value); // 3

const head2 = createList([1, 2, 3, 4, 5, 6]);
console.log(findMiddle(head2).value); // 4 (짝수일 때 오른쪽 중간)
```

---

### 5-2. 역순으로 뒤집기 (Reverse)

세 개의 포인터(prev, current, next)를 사용하여 노드의 방향을 역전합니다.

```js
function reverseList(head) {
  let prev = null;
  let current = head;

  while (current !== null) {
    const nextTemp = current.next; // 다음 노드 임시 저장
    current.next = prev;           // 방향 역전
    prev = current;                // prev를 한 칸 전진
    current = nextTemp;            // current를 한 칸 전진
  }

  return prev; // 새로운 head
}

// 재귀 버전
function reverseListRecursive(head) {
  if (head === null || head.next === null) return head;

  const newHead = reverseListRecursive(head.next);
  head.next.next = head; // 다음 노드가 현재 노드를 가리키게 함
  head.next = null;       // 현재 노드의 next를 null로

  return newHead;
}

// 연결 리스트를 배열로 출력하는 헬퍼
function listToArray(head) {
  const result = [];
  while (head) {
    result.push(head.value);
    head = head.next;
  }
  return result;
}

const head = createList([1, 2, 3, 4, 5]);
const reversed = reverseList(head);
console.log(listToArray(reversed)); // [5, 4, 3, 2, 1]
```

---

### 5-3. 사이클 감지 (Floyd's Cycle Detection Algorithm)

Floyd의 토끼와 거북이 알고리즘입니다.
Fast/Slow 포인터가 같은 노드에서 만나면 사이클이 존재합니다.

```js
// 사이클 존재 여부 확인
function hasCycle(head) {
  let slow = head;
  let fast = head;

  while (fast !== null && fast.next !== null) {
    slow = slow.next;
    fast = fast.next.next;

    if (slow === fast) return true; // 사이클 발견
  }

  return false;
}

// 사이클 시작 노드 찾기
function detectCycleStart(head) {
  let slow = head;
  let fast = head;
  let hasCycle = false;

  // 1단계: 사이클 감지
  while (fast !== null && fast.next !== null) {
    slow = slow.next;
    fast = fast.next.next;
    if (slow === fast) {
      hasCycle = true;
      break;
    }
  }

  if (!hasCycle) return null;

  // 2단계: 사이클 시작점 찾기
  // head에서 포인터 하나를 시작, 만난 지점에서 포인터 하나를 시작
  // 둘이 한 칸씩 이동하면 사이클 시작점에서 만남
  let pointer = head;
  while (pointer !== slow) {
    pointer = pointer.next;
    slow = slow.next;
  }

  return slow; // 사이클 시작 노드
}
```

---

### 5-4. 두 정렬 리스트 병합 (Merge Two Sorted Lists)

두 개의 정렬된 연결 리스트를 하나의 정렬된 리스트로 합칩니다.

```js
// 반복(Iterative) 방식
function mergeTwoLists(l1, l2) {
  const dummy = new ListNode(0); // 더미 헤드 노드
  let current = dummy;

  while (l1 !== null && l2 !== null) {
    if (l1.value <= l2.value) {
      current.next = l1;
      l1 = l1.next;
    } else {
      current.next = l2;
      l2 = l2.next;
    }
    current = current.next;
  }

  // 남은 노드 연결
  current.next = l1 !== null ? l1 : l2;

  return dummy.next;
}

// 재귀(Recursive) 방식
function mergeTwoListsRecursive(l1, l2) {
  if (l1 === null) return l2;
  if (l2 === null) return l1;

  if (l1.value <= l2.value) {
    l1.next = mergeTwoListsRecursive(l1.next, l2);
    return l1;
  } else {
    l2.next = mergeTwoListsRecursive(l1, l2.next);
    return l2;
  }
}

// 테스트
const l1 = createList([1, 3, 5]);
const l2 = createList([2, 4, 6]);
const merged = mergeTwoLists(l1, l2);
console.log(listToArray(merged)); // [1, 2, 3, 4, 5, 6]
```

**응용: 연결 리스트 팰린드롬 확인**

```js
function isPalindromeList(head) {
  // 1. 중간 노드 찾기
  let slow = head;
  let fast = head;
  while (fast !== null && fast.next !== null) {
    slow = slow.next;
    fast = fast.next.next;
  }

  // 2. 후반부 역전
  let prev = null;
  let current = slow;
  while (current !== null) {
    const nextTemp = current.next;
    current.next = prev;
    prev = current;
    current = nextTemp;
  }

  // 3. 앞에서부터와 뒤에서부터 비교
  let left = head;
  let right = prev;
  while (right !== null) {
    if (left.value !== right.value) return false;
    left = left.next;
    right = right.next;
  }

  return true;
}

const head = createList([1, 2, 3, 2, 1]);
console.log(isPalindromeList(head)); // true
```

---

## 6. 면접 포인트

### Q1. 연결 리스트와 배열의 가장 큰 차이는?

배열은 연속된 메모리를 사용하여 인덱스로 O(1) 접근이 가능하지만,
삽입/삭제 시 요소 이동이 필요합니다. 연결 리스트는 분산된 메모리에 포인터로
연결되어 앞 삽입/삭제는 O(1)이지만, 인덱스 접근이 O(n)입니다.
실무에서는 캐시 효율성 때문에 대부분 배열이 유리하지만,
삽입/삭제 빈도가 높고 순차 접근이 주된 경우 연결 리스트가 유리합니다.

### Q2. 단방향과 양방향 연결 리스트의 trade-off는?

양방향 연결 리스트는 `pop()`이 O(1)인 것이 핵심 장점입니다.
단방향은 `pop()` 시 tail의 이전 노드를 찾기 위해 O(n) 순회가 필요합니다.
대신 양방향은 각 노드에 `prev` 포인터를 추가로 저장하므로
메모리 사용량이 약 1.5~2배 늘어납니다.

### Q3. Fast/Slow 포인터 패턴의 원리는?

Fast 포인터가 2배 빠르게 움직이면 전체 길이 n인 리스트에서
Fast가 끝(null)에 도달할 때 Slow는 n/2 지점(중간)에 있습니다.
사이클이 있으면 Fast가 Slow를 결국 따라잡게 됩니다 — 원형 트랙에서
더 빠른 주자가 느린 주자를 한 바퀴 앞서 만나는 것과 동일한 원리입니다.

### Q4. 더미 노드(Dummy Node)를 사용하는 이유는?

병합, 삭제 등의 연산에서 head 노드에 대한 특수 처리를 없애기 위해 사용합니다.
더미 노드를 head 앞에 두면 모든 실제 노드를 동일한 방식으로 처리할 수 있어
코드가 단순해집니다. 결과를 반환할 때는 `dummy.next`를 반환합니다.

### Q5. JavaScript에서 연결 리스트의 실용성은?

JavaScript에는 내장 LinkedList가 없으며, 대부분의 경우 배열(Array)이
충분히 효율적입니다. 하지만 알고리즘 문제에서 자주 출제되며,
JavaScript의 Array는 내부적으로 동적 배열이라 `unshift`가 O(n)인 반면
연결 리스트로 구현한 Queue는 O(1) dequeue가 가능합니다.
또한 LRU Cache 구현 등 실제 시스템 설계에서도 활용됩니다.

### Q6. Floyd 알고리즘에서 사이클 시작점을 찾는 수학적 근거는?

사이클 길이를 C, head에서 사이클 시작점까지의 거리를 F,
사이클 시작점에서 만남 지점까지의 거리를 a라 하면,
Fast는 Slow의 2배 이동: `2(F + a) = F + a + n*C`
정리하면: `F = n*C - a`
즉, head에서 한 포인터를 시작하고 만남 지점에서 다른 포인터를 시작해
둘 다 한 칸씩 이동하면 정확히 사이클 시작점에서 만납니다.
