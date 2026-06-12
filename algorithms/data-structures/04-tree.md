# 4. 트리 (Tree)

## 목차
1. 트리 기본 개념
2. 이진 탐색 트리 (BST)
3. 트리 순회 (Traversal)
4. 재귀 vs 반복 순회
5. MaxHeap
6. 트라이 (Trie)
7. 면접 포인트

---

## 1. 트리 기본 개념

트리는 계층적 구조를 표현하는 비선형 자료구조다. 노드(Node)와 엣지(Edge)로 구성되며, 하나의 루트(Root)에서 시작해 자식 노드로 뻗어 나간다.

### 핵심 용어

| 용어 | 설명 |
|------|------|
| 루트(Root) | 트리의 최상위 노드, 부모가 없음 |
| 리프(Leaf) | 자식이 없는 노드 |
| 높이(Height) | 루트에서 가장 깊은 리프까지의 엣지 수 |
| 깊이(Depth) | 루트에서 특정 노드까지의 엣지 수 |
| 차수(Degree) | 노드의 자식 수 |
| 서브트리(Subtree) | 특정 노드와 그 자손들로 이루어진 트리 |

### 트리의 특성
- 노드 N개 -> 엣지는 N-1개
- 임의의 두 노드 사이에 유일한 경로가 존재
- 사이클이 없는 연결 그래프

---

## 2. 이진 탐색 트리 (BST)

이진 탐색 트리는 각 노드가 최대 2개의 자식을 가지며, 왼쪽 서브트리의 모든 값은 부모보다 작고, 오른쪽 서브트리의 모든 값은 부모보다 크다.

### 시간복잡도

| 연산 | 평균 | 최악 (편향 트리) |
|------|------|-----------------|
| 탐색 | O(log n) | O(n) |
| 삽입 | O(log n) | O(n) |
| 삭제 | O(log n) | O(n) |

```javascript
class BSTNode {
  constructor(value) {
    this.value = value;
    this.left = null;
    this.right = null;
  }
}

class BST {
  constructor() {
    this.root = null;
  }

  // 삽입
  insert(value) {
    const node = new BSTNode(value);
    if (!this.root) {
      this.root = node;
      return this;
    }

    let current = this.root;
    while (true) {
      if (value === current.value) return this; // 중복 무시
      if (value < current.value) {
        if (!current.left) { current.left = node; return this; }
        current = current.left;
      } else {
        if (!current.right) { current.right = node; return this; }
        current = current.right;
      }
    }
  }

  // 탐색
  search(value) {
    let current = this.root;
    while (current) {
      if (value === current.value) return current;
      current = value < current.value ? current.left : current.right;
    }
    return null;
  }

  // 삭제
  delete(value) {
    this.root = this._deleteNode(this.root, value);
  }

  _deleteNode(node, value) {
    if (!node) return null;

    if (value < node.value) {
      node.left = this._deleteNode(node.left, value);
    } else if (value > node.value) {
      node.right = this._deleteNode(node.right, value);
    } else {
      // 삭제 대상 노드 발견
      // 케이스 1: 자식이 없는 경우
      if (!node.left && !node.right) return null;
      // 케이스 2: 자식이 하나인 경우
      if (!node.left) return node.right;
      if (!node.right) return node.left;
      // 케이스 3: 자식이 둘인 경우 -> 오른쪽 서브트리의 최솟값(중위 후계자)으로 대체
      const minRight = this._findMin(node.right);
      node.value = minRight.value;
      node.right = this._deleteNode(node.right, minRight.value);
    }
    return node;
  }

  _findMin(node) {
    while (node.left) node = node.left;
    return node;
  }
}

// 사용 예시
const bst = new BST();
[5, 3, 7, 1, 4, 6, 8].forEach(v => bst.insert(v));
console.log(bst.search(4));  // BSTNode { value: 4, ... }
bst.delete(3);
```

---

## 3. 트리 순회 (Traversal)

### 전위 순회 (Preorder): 루트 → 왼쪽 → 오른쪽

```javascript
function preorder(node, result = []) {
  if (!node) return result;
  result.push(node.value);       // 루트 처리
  preorder(node.left, result);   // 왼쪽 서브트리
  preorder(node.right, result);  // 오른쪽 서브트리
  return result;
}
// [5, 3, 1, 4, 7, 6, 8]
```

### 중위 순회 (Inorder): 왼쪽 → 루트 → 오른쪽

BST에서 중위 순회를 하면 정렬된 결과를 얻는다.

```javascript
function inorder(node, result = []) {
  if (!node) return result;
  inorder(node.left, result);    // 왼쪽 서브트리
  result.push(node.value);       // 루트 처리
  inorder(node.right, result);   // 오른쪽 서브트리
  return result;
}
// [1, 3, 4, 5, 6, 7, 8]
```

### 후위 순회 (Postorder): 왼쪽 → 오른쪽 → 루트

디렉토리 삭제, 수식 트리 계산에 활용된다.

```javascript
function postorder(node, result = []) {
  if (!node) return result;
  postorder(node.left, result);  // 왼쪽 서브트리
  postorder(node.right, result); // 오른쪽 서브트리
  result.push(node.value);       // 루트 처리
  return result;
}
// [1, 4, 3, 6, 8, 7, 5]
```

### 레벨 순서 순회 (Level Order / BFS)

큐를 사용해 같은 레벨의 노드를 먼저 방문한다.

```javascript
function levelOrder(root) {
  if (!root) return [];
  const result = [];
  const queue = [root];

  while (queue.length) {
    const levelSize = queue.length;
    const level = [];

    for (let i = 0; i < levelSize; i++) {
      const node = queue.shift();
      level.push(node.value);
      if (node.left) queue.push(node.left);
      if (node.right) queue.push(node.right);
    }
    result.push(level);
  }
  return result;
}
// [[5], [3, 7], [1, 4, 6, 8]]
```

---

## 4. 재귀 vs 반복 순회

재귀는 간결하지만 깊은 트리에서 스택 오버플로우 위험이 있다. 반복 구현은 명시적 스택을 사용한다.

### 반복 중위 순회 (Iterative Inorder)

```javascript
function iterativeInorder(root) {
  const result = [];
  const stack = [];
  let current = root;

  while (current || stack.length) {
    // 왼쪽 끝까지 내려가며 스택에 쌓기
    while (current) {
      stack.push(current);
      current = current.left;
    }
    // 스택에서 꺼내 처리
    current = stack.pop();
    result.push(current.value);
    // 오른쪽으로 이동
    current = current.right;
  }
  return result;
}
```

### 반복 전위 순회 (Iterative Preorder)

```javascript
function iterativePreorder(root) {
  if (!root) return [];
  const result = [];
  const stack = [root];

  while (stack.length) {
    const node = stack.pop();
    result.push(node.value);
    // 오른쪽을 먼저 push해야 왼쪽이 먼저 처리됨
    if (node.right) stack.push(node.right);
    if (node.left) stack.push(node.left);
  }
  return result;
}
```

---

## 5. MaxHeap

힙(Heap)은 완전 이진 트리 형태의 자료구조로, 부모 노드가 항상 자식 노드보다 크거나 같은(MaxHeap) 또는 작거나 같은(MinHeap) 성질을 가진다. 우선순위 큐 구현에 사용된다.

배열로 표현할 때 인덱스 i의 노드:
- 왼쪽 자식: `2*i + 1`
- 오른쪽 자식: `2*i + 2`
- 부모: `Math.floor((i-1) / 2)`

```javascript
class MaxHeap {
  constructor() {
    this.heap = [];
  }

  // 삽입: O(log n)
  insert(value) {
    this.heap.push(value);
    this._bubbleUp(this.heap.length - 1);
  }

  _bubbleUp(idx) {
    while (idx > 0) {
      const parentIdx = Math.floor((idx - 1) / 2);
      if (this.heap[parentIdx] >= this.heap[idx]) break;
      // 부모와 교환
      [this.heap[parentIdx], this.heap[idx]] = [this.heap[idx], this.heap[parentIdx]];
      idx = parentIdx;
    }
  }

  // 최댓값 추출: O(log n)
  extractMax() {
    if (!this.heap.length) return null;
    const max = this.heap[0];
    const last = this.heap.pop();

    if (this.heap.length) {
      this.heap[0] = last;
      this._sinkDown(0);
    }
    return max;
  }

  _sinkDown(idx) {
    const length = this.heap.length;

    while (true) {
      const left = 2 * idx + 1;
      const right = 2 * idx + 2;
      let largest = idx;

      if (left < length && this.heap[left] > this.heap[largest]) largest = left;
      if (right < length && this.heap[right] > this.heap[largest]) largest = right;
      if (largest === idx) break;

      [this.heap[largest], this.heap[idx]] = [this.heap[idx], this.heap[largest]];
      idx = largest;
    }
  }

  peek() {
    return this.heap[0] ?? null;
  }

  size() {
    return this.heap.length;
  }
}

// 사용 예시
const heap = new MaxHeap();
[3, 1, 4, 1, 5, 9, 2, 6].forEach(v => heap.insert(v));
console.log(heap.extractMax()); // 9
console.log(heap.extractMax()); // 6
console.log(heap.peek());       // 5
```

---

## 6. 트라이 (Trie)

트라이는 문자열 집합을 효율적으로 저장하고 탐색하는 트리 구조다. 각 노드는 문자 하나를 나타내며, 루트에서 특정 노드까지의 경로가 하나의 문자열 접두사를 나타낸다.

### 시간복잡도
- 삽입: O(m), m = 문자열 길이
- 탐색: O(m)
- 공간: O(알파벳 크기 × m × n), n = 문자열 수

```javascript
class TrieNode {
  constructor() {
    this.children = {};  // 문자 -> TrieNode
    this.isEnd = false;  // 단어의 끝 여부
  }
}

class Trie {
  constructor() {
    this.root = new TrieNode();
  }

  // 단어 삽입
  insert(word) {
    let node = this.root;
    for (const char of word) {
      if (!node.children[char]) {
        node.children[char] = new TrieNode();
      }
      node = node.children[char];
    }
    node.isEnd = true;
  }

  // 정확한 단어 탐색
  search(word) {
    let node = this.root;
    for (const char of word) {
      if (!node.children[char]) return false;
      node = node.children[char];
    }
    return node.isEnd;
  }

  // 접두사 탐색
  startsWith(prefix) {
    let node = this.root;
    for (const char of prefix) {
      if (!node.children[char]) return false;
      node = node.children[char];
    }
    return true;
  }

  // 접두사로 시작하는 모든 단어 반환
  findWordsWithPrefix(prefix) {
    let node = this.root;
    for (const char of prefix) {
      if (!node.children[char]) return [];
      node = node.children[char];
    }
    const results = [];
    this._dfs(node, prefix, results);
    return results;
  }

  _dfs(node, current, results) {
    if (node.isEnd) results.push(current);
    for (const [char, child] of Object.entries(node.children)) {
      this._dfs(child, current + char, results);
    }
  }
}

// 사용 예시
const trie = new Trie();
['apple', 'app', 'application', 'apply', 'banana'].forEach(w => trie.insert(w));

console.log(trie.search('app'));          // true
console.log(trie.search('ap'));           // false
console.log(trie.startsWith('ap'));       // true
console.log(trie.findWordsWithPrefix('app'));
// ['app', 'apple', 'application', 'apply']
```

---

## 7. 면접 포인트

### BST 관련

**Q. BST의 삭제 연산에서 자식이 2개인 경우 어떻게 처리하나요?**

오른쪽 서브트리에서 가장 작은 값(중위 후계자)이나 왼쪽 서브트리에서 가장 큰 값(중위 전임자)으로 대체한다. 이렇게 하면 BST 속성이 유지된다.

**Q. 균형 이진 탐색 트리(AVL, Red-Black Tree)가 필요한 이유는?**

일반 BST는 정렬된 데이터를 삽입할 경우 편향 트리(skewed tree)가 되어 O(n) 성능으로 저하된다. AVL Tree나 Red-Black Tree는 자동으로 균형을 맞춰 O(log n)을 보장한다.

### 순회 관련

**Q. 중위 순회(Inorder)의 활용 사례는?**

BST에서 중위 순회를 수행하면 정렬된 순서로 원소를 방문한다. BST를 정렬된 배열로 변환하거나, k번째 최솟값을 찾을 때 활용한다.

**Q. 전위 순회와 후위 순회는 각각 어디에 쓰이나요?**

- 전위 순회: 트리 복사, 직렬화/역직렬화
- 후위 순회: 트리 삭제(자식을 먼저 삭제), 수식 트리의 후위 표기 계산

### 힙 관련

**Q. 힙과 BST의 차이점은?**

힙은 부모-자식 간 대소 관계만 보장하고, BST처럼 왼쪽/오른쪽 방향 규칙이 없다. 힙은 최댓값/최솟값 추출에 최적화되어 있고, BST는 정렬된 탐색에 최적화되어 있다.

**Q. 힙 정렬(Heap Sort)의 시간복잡도는?**

O(n log n)이며 추가 메모리가 O(1)이다. 배열 전체를 힙으로 만드는 heapify가 O(n), 각 원소를 추출하는 과정이 O(n log n)이다.

### 트라이 관련

**Q. 해시맵 대신 트라이를 사용해야 하는 경우는?**

- 접두사 탐색이 필요한 경우 (자동완성)
- 공통 접두사를 공유하는 문자열이 많아 공간 절약이 필요한 경우
- 사전 순 정렬이 필요한 경우

해시맵은 O(m) 탐색이지만 접두사 탐색 자체가 불가능하고, 트라이는 접두사 탐색을 O(m)에 처리할 수 있다.

**Q. 트라이의 공간 복잡도 최적화 방법은?**

- 압축 트라이(Patricia Trie / Radix Tree): 단일 자식 노드들을 하나의 엣지로 압축
- 배열 대신 Map/Object 사용으로 실제 존재하는 자식만 저장
