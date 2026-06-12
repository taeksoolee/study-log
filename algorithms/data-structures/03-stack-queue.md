# 3. 스택과 큐 (Stack & Queue)

## 목차
1. Stack 개념과 JavaScript 구현
2. Queue 개념과 JavaScript 구현
3. 단조 스택 (Monotonic Stack)
4. Deque (Double-ended Queue)
5. 활용 패턴
   - 괄호 유효성 검사
   - BFS에서 큐 활용
   - 히스토그램에서 최대 직사각형
6. 면접 포인트

---

## 1. Stack 개념과 JavaScript 구현

Stack은 **LIFO(Last In, First Out)** 원칙을 따르는 선형 자료구조입니다.
가장 마지막에 추가된 요소가 가장 먼저 제거됩니다.
책을 쌓아두고 꺼내는 방식, 또는 브라우저 뒤로 가기 기록과 동일한 구조입니다.

### 핵심 연산

| 연산    | 설명                         | 시간복잡도 |
|--------|------------------------------|------------|
| push   | 스택의 top에 요소 추가        | O(1)       |
| pop    | 스택의 top에서 요소 제거 및 반환 | O(1)    |
| peek   | top 요소 확인 (제거하지 않음) | O(1)       |
| isEmpty | 비어있는지 확인              | O(1)       |

### 배열 기반 Stack 구현

JavaScript의 배열은 `push`/`pop`이 O(1)이므로 Stack으로 바로 사용 가능합니다.

```js
class Stack {
  constructor() {
    this._data = [];
  }

  // 요소 추가 O(1)
  push(value) {
    this._data.push(value);
    return this;
  }

  // 요소 제거 및 반환 O(1)
  pop() {
    if (this.isEmpty()) return undefined;
    return this._data.pop();
  }

  // top 확인 O(1)
  peek() {
    if (this.isEmpty()) return undefined;
    return this._data[this._data.length - 1];
  }

  // 비어있는지 확인 O(1)
  isEmpty() {
    return this._data.length === 0;
  }

  // 크기 반환
  get size() {
    return this._data.length;
  }

  // 배열로 반환 (디버깅용) — [bottom, ..., top] 순서
  toArray() {
    return [...this._data];
  }
}

// 사용 예시
const stack = new Stack();
stack.push(1).push(2).push(3);
console.log(stack.peek());    // 3
console.log(stack.pop());     // 3
console.log(stack.toArray()); // [1, 2]
console.log(stack.size);      // 2
```

### 연결 리스트 기반 Stack 구현

```js
class StackNode {
  constructor(value) {
    this.value = value;
    this.next = null;
  }
}

class LinkedStack {
  constructor() {
    this.top = null;
    this.length = 0;
  }

  push(value) {
    const node = new StackNode(value);
    node.next = this.top;
    this.top = node;
    this.length++;
    return this;
  }

  pop() {
    if (!this.top) return undefined;
    const value = this.top.value;
    this.top = this.top.next;
    this.length--;
    return value;
  }

  peek() {
    return this.top ? this.top.value : undefined;
  }

  isEmpty() {
    return this.length === 0;
  }
}
```

---

## 2. Queue 개념과 JavaScript 구현

Queue는 **FIFO(First In, First Out)** 원칙을 따르는 선형 자료구조입니다.
가장 먼저 추가된 요소가 가장 먼저 제거됩니다.
은행 창구 줄서기, 인쇄 대기열, BFS 탐색에서 활용됩니다.

### 핵심 연산

| 연산     | 설명                          | 시간복잡도             |
|---------|-------------------------------|----------------------|
| enqueue | 큐의 rear에 요소 추가          | O(1)                 |
| dequeue | 큐의 front에서 요소 제거 및 반환 | O(1) (연결 리스트)    |
| front   | front 요소 확인 (제거 안 함)   | O(1)                 |
| isEmpty | 비어있는지 확인                | O(1)                 |

### 배열 기반 Queue (주의: dequeue가 O(n))

```js
// 간단하지만 dequeue가 O(n)인 방식 — 소규모 문제에서만 사용
class SimpleQueue {
  constructor() {
    this._data = [];
  }

  enqueue(value) {
    this._data.push(value);  // O(1)
  }

  // shift()는 배열 앞에서 제거 후 모든 요소를 앞당기므로 O(n)
  dequeue() {
    return this._data.shift(); // O(n) — 주의
  }

  front() {
    return this._data[0];
  }

  isEmpty() {
    return this._data.length === 0;
  }

  get size() {
    return this._data.length;
  }
}
```

### 연결 리스트 기반 Queue (O(1) dequeue 보장)

```js
class QueueNode {
  constructor(value) {
    this.value = value;
    this.next = null;
  }
}

class Queue {
  constructor() {
    this.head = null; // front
    this.tail = null; // rear
    this.length = 0;
  }

  // 뒤에 추가 O(1)
  enqueue(value) {
    const node = new QueueNode(value);
    if (!this.tail) {
      this.head = node;
      this.tail = node;
    } else {
      this.tail.next = node;
      this.tail = node;
    }
    this.length++;
    return this;
  }

  // 앞에서 제거 O(1)
  dequeue() {
    if (!this.head) return undefined;

    const value = this.head.value;
    this.head = this.head.next;
    if (!this.head) this.tail = null;
    this.length--;
    return value;
  }

  front() {
    return this.head ? this.head.value : undefined;
  }

  isEmpty() {
    return this.length === 0;
  }

  get size() {
    return this.length;
  }
}

// 사용 예시
const queue = new Queue();
queue.enqueue(1).enqueue(2).enqueue(3);
console.log(queue.front());    // 1
console.log(queue.dequeue());  // 1
console.log(queue.dequeue());  // 2
console.log(queue.size);       // 1
```

---

## 3. 단조 스택 (Monotonic Stack)

단조 스택은 스택 내부가 항상 단조 증가(Monotonically Increasing) 또는
단조 감소(Monotonically Decreasing) 순서를 유지하도록 관리하는 스택입니다.

**핵심 아이디어**: 새로운 요소를 push하기 전에 조건을 위반하는 기존 요소를 pop합니다.
"다음 더 큰 원소", "이전 더 작은 원소" 등의 문제를 O(n)으로 해결합니다.

### 단조 스택 원리

```
단조 감소 스택에서 [2, 1, 5, 3, 4] 처리 과정:

요소 2: 스택 [2]       (비어있으므로 push)
요소 1: 스택 [2, 1]    (2 >= 1이므로 push 가능)
요소 5: 스택 [5]       (1 < 5, 2 < 5 → 1, 2 pop 후 push)
요소 3: 스택 [5, 3]    (5 >= 3이므로 push)
요소 4: 스택 [5, 4]    (3 < 4 → 3 pop 후 push)
```

### 예제: 다음 더 큰 원소 (Next Greater Element)

각 요소의 오른쪽에서 처음으로 자신보다 큰 원소를 찾습니다.

```js
function nextGreaterElements(arr) {
  const n = arr.length;
  const result = new Array(n).fill(-1); // 기본값 -1 (없으면 -1)
  const stack = []; // 인덱스를 저장하는 단조 감소 스택

  for (let i = 0; i < n; i++) {
    // 현재 요소가 스택의 top 요소보다 크면 → top이 찾던 "다음 큰 원소"
    while (stack.length > 0 && arr[stack[stack.length - 1]] < arr[i]) {
      const idx = stack.pop();
      result[idx] = arr[i];
    }
    stack.push(i);
  }

  return result;
}

console.log(nextGreaterElements([2, 1, 5, 3, 4]));
// [5, 5, -1, 4, -1]
// 2의 다음 큰 원소: 5
// 1의 다음 큰 원소: 5
// 5의 다음 큰 원소: 없음 (-1)
// 3의 다음 큰 원소: 4
// 4의 다음 큰 원소: 없음 (-1)
```

### 예제: 일별 온도 — 더 따뜻해지는 날까지 대기 일수

```js
function dailyTemperatures(temps) {
  const n = temps.length;
  const result = new Array(n).fill(0);
  const stack = []; // 인덱스를 저장하는 단조 감소 스택

  for (let i = 0; i < n; i++) {
    while (stack.length > 0 && temps[stack[stack.length - 1]] < temps[i]) {
      const idx = stack.pop();
      result[idx] = i - idx; // 대기 일수 = 현재 인덱스 - 저장된 인덱스
    }
    stack.push(i);
  }

  return result;
}

console.log(dailyTemperatures([73, 74, 75, 71, 69, 72, 76, 73]));
// [1, 1, 4, 2, 1, 1, 0, 0]
```

---

## 4. Deque (Double-ended Queue)

Deque는 양쪽 끝에서 삽입과 삭제가 모두 가능한 자료구조입니다.
Stack과 Queue의 기능을 모두 포함합니다.
슬라이딩 윈도우 최댓값/최솟값 문제에서 자주 활용됩니다.

### 양방향 연결 리스트 기반 Deque 구현

```js
class DequeNode {
  constructor(value) {
    this.value = value;
    this.prev = null;
    this.next = null;
  }
}

class Deque {
  constructor() {
    this.head = null;
    this.tail = null;
    this.length = 0;
  }

  // 앞에 추가 O(1)
  pushFront(value) {
    const node = new DequeNode(value);
    if (!this.head) {
      this.head = node;
      this.tail = node;
    } else {
      node.next = this.head;
      this.head.prev = node;
      this.head = node;
    }
    this.length++;
  }

  // 뒤에 추가 O(1)
  pushBack(value) {
    const node = new DequeNode(value);
    if (!this.tail) {
      this.head = node;
      this.tail = node;
    } else {
      node.prev = this.tail;
      this.tail.next = node;
      this.tail = node;
    }
    this.length++;
  }

  // 앞에서 제거 O(1)
  popFront() {
    if (!this.head) return undefined;
    const value = this.head.value;
    this.head = this.head.next;
    if (this.head) this.head.prev = null;
    else this.tail = null;
    this.length--;
    return value;
  }

  // 뒤에서 제거 O(1)
  popBack() {
    if (!this.tail) return undefined;
    const value = this.tail.value;
    this.tail = this.tail.prev;
    if (this.tail) this.tail.next = null;
    else this.head = null;
    this.length--;
    return value;
  }

  peekFront() {
    return this.head ? this.head.value : undefined;
  }

  peekBack() {
    return this.tail ? this.tail.value : undefined;
  }

  isEmpty() {
    return this.length === 0;
  }
}
```

### Deque 활용: 슬라이딩 윈도우 최댓값

크기 k의 슬라이딩 윈도우에서 각 위치의 최댓값을 O(n)으로 구합니다.

```js
function maxSlidingWindow(nums, k) {
  const result = [];
  const deque = []; // 인덱스를 저장하는 단조 감소 덱

  for (let i = 0; i < nums.length; i++) {
    // 윈도우를 벗어난 인덱스 제거 (앞에서)
    while (deque.length > 0 && deque[0] < i - k + 1) {
      deque.shift();
    }

    // 현재 요소보다 작은 값의 인덱스 제거 (뒤에서)
    // → 덱이 단조 감소 순서를 유지하도록
    while (deque.length > 0 && nums[deque[deque.length - 1]] < nums[i]) {
      deque.pop();
    }

    deque.push(i);

    // 첫 번째 윈도우가 완성된 이후부터 결과에 추가
    if (i >= k - 1) {
      result.push(nums[deque[0]]); // 덱의 front가 현재 윈도우 최댓값
    }
  }

  return result;
}

console.log(maxSlidingWindow([1, 3, -1, -3, 5, 3, 6, 7], 3));
// [3, 3, 5, 5, 6, 7]
```

---

## 5. 활용 패턴

### 5-1. 괄호 유효성 검사 (Valid Parentheses)

여는 괄호는 스택에 push하고, 닫는 괄호가 나오면 스택의 top과 매칭합니다.

```js
function isValidParentheses(s) {
  const stack = [];
  const pairs = {
    ')': '(',
    ']': '[',
    '}': '{'
  };

  for (const ch of s) {
    if (ch === '(' || ch === '[' || ch === '{') {
      stack.push(ch); // 여는 괄호 push
    } else {
      // 닫는 괄호: 스택이 비어있거나 top이 매칭 안 되면 false
      if (stack.length === 0 || stack[stack.length - 1] !== pairs[ch]) {
        return false;
      }
      stack.pop();
    }
  }

  return stack.length === 0; // 스택이 비어야 유효
}

console.log(isValidParentheses('()[]{}'));  // true
console.log(isValidParentheses('([{}])'));  // true
console.log(isValidParentheses('(]'));      // false
console.log(isValidParentheses('([)'));     // false
```

### 5-2. BFS에서 큐 활용 (Breadth-First Search)

BFS는 그래프/트리에서 현재 노드와 가장 가까운 노드부터 탐색합니다.
Queue를 사용하여 탐색 순서를 관리합니다.

```js
// 그래프를 인접 리스트로 표현
const graph = {
  A: ['B', 'C'],
  B: ['A', 'D', 'E'],
  C: ['A', 'F'],
  D: ['B'],
  E: ['B', 'F'],
  F: ['C', 'E']
};

function bfs(graph, start) {
  const visited = new Set();
  const queue = [start];
  const result = [];

  visited.add(start);

  while (queue.length > 0) {
    const node = queue.shift(); // O(n) — 실제 BFS에서는 연결 리스트 Queue 권장
    result.push(node);

    for (const neighbor of graph[node]) {
      if (!visited.has(neighbor)) {
        visited.add(neighbor);
        queue.push(neighbor);
      }
    }
  }

  return result;
}

console.log(bfs(graph, 'A')); // ['A', 'B', 'C', 'D', 'E', 'F']

// 이진 트리 레벨 순회 (Level Order Traversal)
function levelOrder(root) {
  if (!root) return [];

  const result = [];
  const queue = [root];

  while (queue.length > 0) {
    const levelSize = queue.length;
    const currentLevel = [];

    for (let i = 0; i < levelSize; i++) {
      const node = queue.shift();
      currentLevel.push(node.val);

      if (node.left) queue.push(node.left);
      if (node.right) queue.push(node.right);
    }

    result.push(currentLevel);
  }

  return result;
}
```

### 5-3. 히스토그램에서 최대 직사각형 (Largest Rectangle in Histogram)

단조 스택을 활용하여 각 막대를 높이로 하는 최대 넓이 직사각형을 O(n)으로 찾습니다.

**아이디어**: 단조 증가 스택을 유지하면서, 현재 막대가 이전 막대보다 낮아지는 순간
스택에서 pop하며 그 막대를 높이로 하는 최대 너비를 계산합니다.

```js
function largestRectangleArea(heights) {
  const stack = []; // 인덱스를 저장하는 단조 증가 스택
  let maxArea = 0;

  // 마지막에 남은 스택을 처리하기 위해 heights 뒤에 0을 추가
  const h = [...heights, 0];

  for (let i = 0; i < h.length; i++) {
    // 현재 높이가 스택 top의 높이보다 낮으면
    // → top이 나타낼 수 있는 최대 직사각형을 계산
    while (stack.length > 0 && h[stack[stack.length - 1]] > h[i]) {
      const height = h[stack.pop()];
      // 너비: 스택이 비었으면 현재 인덱스까지, 아니면 현재와 새 top 사이
      const width = stack.length === 0 ? i : i - stack[stack.length - 1] - 1;
      maxArea = Math.max(maxArea, height * width);
    }
    stack.push(i);
  }

  return maxArea;
}

console.log(largestRectangleArea([2, 1, 5, 6, 2, 3])); // 10
// 인덱스 2~3의 높이 5,6으로 너비 2 → 5*2=10
console.log(largestRectangleArea([2, 4]));              // 4
```

---

## 6. 면접 포인트

### Q1. Stack과 Queue의 차이를 실생활 예시로 설명한다면?

- **Stack (LIFO)**: 브라우저 뒤로 가기 버튼, 함수 호출 스택(Call Stack),
  Ctrl+Z 실행 취소 기능. 마지막에 한 것을 먼저 되돌립니다.
- **Queue (FIFO)**: 프린터 인쇄 대기열, 고객 센터 대기, 운영체제의 프로세스 스케줄링,
  BFS 탐색. 먼저 들어온 것이 먼저 처리됩니다.

### Q2. JavaScript 배열로 Queue를 구현할 때의 문제점은?

JavaScript 배열의 `shift()`는 O(n) 연산입니다. 앞에서 요소를 제거하면
나머지 모든 요소의 인덱스를 재조정해야 하기 때문입니다.
대량의 데이터를 처리하는 Queue라면 연결 리스트 기반으로 구현하거나,
두 개의 스택으로 Queue를 시뮬레이션하는 방법을 사용해야 합니다.

### Q3. 두 스택으로 Queue를 구현하는 방법은?

```js
class QueueUsingStacks {
  constructor() {
    this.inbox = [];   // enqueue 스택
    this.outbox = [];  // dequeue 스택
  }

  enqueue(value) {
    this.inbox.push(value); // O(1)
  }

  dequeue() {
    // outbox가 비면 inbox 전체를 옮김
    // → 순서가 역전되어 FIFO 순서 달성
    if (this.outbox.length === 0) {
      while (this.inbox.length > 0) {
        this.outbox.push(this.inbox.pop());
      }
    }
    return this.outbox.pop(); // amortized O(1)
  }
}
```
enqueue는 항상 O(1)이고, dequeue는 평균 amortized O(1)입니다.
각 요소는 inbox에서 outbox로 정확히 한 번만 이동합니다.

### Q4. 단조 스택을 사용하는 문제의 특징은?

다음 패턴의 문제에서 단조 스택을 고려합니다:
- "다음 더 큰/작은 원소 찾기"
- "이전 더 큰/작은 원소 찾기"
- "각 요소가 범위의 최솟값/최댓값인 구간"
- 히스토그램 최대 직사각형, 빗물 받기(Trapping Rain Water)

핵심 단서: 각 원소에 대해 좌우의 경계가 되는 원소를 찾는 문제.
중첩 루프 O(n²)를 O(n)으로 줄일 수 있습니다.

### Q5. Deque와 단조 스택의 관계는?

단조 스택은 한쪽 끝에서만 연산이 일어나는 반면,
슬라이딩 윈도우 최댓값 문제에서는 앞에서 만료된 인덱스를 제거하고
뒤에서 더 작은 요소를 제거해야 합니다. 이처럼 양쪽 끝에서 조작이
필요한 경우 단조 덱(Monotonic Deque)을 사용합니다.

### Q6. 재귀 함수와 스택의 관계는?

모든 재귀 호출은 내부적으로 Call Stack을 사용합니다.
재귀 깊이가 깊으면 Stack Overflow가 발생합니다.
재귀로 작성된 DFS, 트리 순회 등은 명시적인 스택을 사용하여
반복문(iterative) 방식으로 변환할 수 있습니다.
이는 스택 오버플로우 방지와 꼬리 재귀 최적화가 없는 환경에서 유용합니다.

```js
// 재귀 DFS → 스택 기반 반복 DFS 변환 예시
function dfsIterative(root) {
  if (!root) return [];
  const result = [];
  const stack = [root];

  while (stack.length > 0) {
    const node = stack.pop();
    result.push(node.val);

    // 오른쪽을 먼저 push해야 왼쪽이 먼저 pop됨 (전위 순회 유지)
    if (node.right) stack.push(node.right);
    if (node.left) stack.push(node.left);
  }

  return result;
}
```
