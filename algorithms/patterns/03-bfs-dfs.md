# 3. BFS / DFS 탐색 패턴

## 목차
1. BFS vs DFS 비교
2. BFS 템플릿 (JavaScript)
3. DFS 템플릿 (JavaScript)
4. visited 배열 관리
5. 예제 문제
   - 섬의 개수 (Number of Islands) - DFS
   - 최단 경로 (Binary Matrix) - BFS
   - 이진 트리 최대 깊이 - DFS
6. 면접 포인트

---

## 1. BFS vs DFS 비교

| 구분 | BFS (너비 우선 탐색) | DFS (깊이 우선 탐색) |
|------|----------------------|----------------------|
| 자료구조 | 큐 (Queue) | 스택 (Stack) / 재귀 |
| 탐색 방식 | 가까운 노드부터 탐색 | 가능한 깊이까지 탐색 |
| 최단 경로 | 보장됨 (비가중 그래프) | 보장 안 됨 |
| 공간복잡도 | O(V) - 최악 경우 전체 레벨 | O(H) - 트리 높이 |
| 적합한 경우 | 최단 경로, 레벨 순회 | 경로 존재 여부, 사이클 감지, 위상 정렬 |

### 언제 BFS를 쓸까?
- 두 노드 사이의 **최단 거리**를 구할 때
- **레벨 순서(level-order)** 탐색이 필요할 때
- 가중치 없는 그래프에서 최적 경로 탐색

### 언제 DFS를 쓸까?
- **모든 경로** 탐색이 필요할 때
- **사이클 감지**, 위상 정렬
- 미로 탐색, 백트래킹
- 연결 컴포넌트(Connected Component) 탐색

---

## 2. BFS 템플릿 (JavaScript)

```javascript
/**
 * BFS 기본 템플릿
 * @param {any} start - 시작 노드
 * @param {Map|Object} graph - 인접 리스트
 */
function bfs(start, graph) {
  const visited = new Set();
  const queue = [start];
  visited.add(start);

  while (queue.length > 0) {
    const node = queue.shift(); // O(n) — 성능 중요 시 deque 사용

    // 현재 노드 처리
    console.log(node);

    for (const neighbor of graph[node] || []) {
      if (!visited.has(neighbor)) {
        visited.add(neighbor);
        queue.push(neighbor);
      }
    }
  }
}

/**
 * BFS - 레벨(거리) 추적 템플릿
 * 최단 거리 계산에 유용
 */
function bfsWithLevel(start, graph) {
  const visited = new Set();
  const queue = [[start, 0]]; // [노드, 거리]
  visited.add(start);

  while (queue.length > 0) {
    const [node, dist] = queue.shift();

    console.log(`노드: ${node}, 거리: ${dist}`);

    for (const neighbor of graph[node] || []) {
      if (!visited.has(neighbor)) {
        visited.add(neighbor);
        queue.push([neighbor, dist + 1]);
      }
    }
  }
}

/**
 * BFS - 효율적인 큐 구현 (포인터 방식)
 * queue.shift()는 O(n)이므로 큰 입력에서 포인터 방식 권장
 */
function bfsOptimized(start, graph) {
  const visited = new Set();
  const queue = [start];
  let head = 0;
  visited.add(start);

  while (head < queue.length) {
    const node = queue[head++]; // O(1)

    for (const neighbor of graph[node] || []) {
      if (!visited.has(neighbor)) {
        visited.add(neighbor);
        queue.push(neighbor);
      }
    }
  }
}
```

---

## 3. DFS 템플릿 (JavaScript)

```javascript
/**
 * DFS - 재귀 템플릿
 */
function dfsRecursive(node, graph, visited = new Set()) {
  if (visited.has(node)) return;
  visited.add(node);

  // 현재 노드 처리
  console.log(node);

  for (const neighbor of graph[node] || []) {
    dfsRecursive(neighbor, graph, visited);
  }
}

/**
 * DFS - 스택(반복) 템플릿
 * 재귀 깊이 제한(call stack overflow)을 피할 때 사용
 */
function dfsIterative(start, graph) {
  const visited = new Set();
  const stack = [start];

  while (stack.length > 0) {
    const node = stack.pop();

    if (visited.has(node)) continue;
    visited.add(node);

    // 현재 노드 처리
    console.log(node);

    for (const neighbor of graph[node] || []) {
      if (!visited.has(neighbor)) {
        stack.push(neighbor);
      }
    }
  }
}

/**
 * DFS - 2D 그리드 탐색 템플릿
 * 상하좌우 방향 이동
 */
function dfsGrid(grid, row, col, visited) {
  const rows = grid.length;
  const cols = grid[0].length;

  // 경계 및 유효성 체크
  if (row < 0 || row >= rows || col < 0 || col >= cols) return;
  if (visited[row][col]) return;
  if (grid[row][col] === 0) return; // 방문 불가 조건

  visited[row][col] = true;

  const directions = [[-1, 0], [1, 0], [0, -1], [0, 1]]; // 상하좌우
  for (const [dr, dc] of directions) {
    dfsGrid(grid, row + dr, col + dc, visited);
  }
}
```

---

## 4. visited 배열 관리

```javascript
// 방법 1: Set 사용 (노드 ID가 다양할 때)
const visited = new Set();
visited.add(nodeId);
visited.has(nodeId);

// 방법 2: 2D boolean 배열 (그리드 탐색)
const visited = Array.from({ length: rows }, () => new Array(cols).fill(false));
visited[r][c] = true;

// 방법 3: 원본 그리드 수정 (공간 절약, 단 원본 훼손)
// grid[r][c] = '#'; // 방문 표시
// 탐색 후 복원이 필요하면 백트래킹 패턴 사용

// 방법 4: 색 기반 DFS (사이클 감지)
// 0: 미방문, 1: 방문 중(회색), 2: 완료(흑색)
const color = new Array(n).fill(0);

function dfsColor(node) {
  color[node] = 1; // 방문 중
  for (const next of graph[node]) {
    if (color[next] === 1) return true; // 사이클 감지
    if (color[next] === 0) dfsColor(next);
  }
  color[node] = 2; // 완료
  return false;
}
```

---

## 5. 예제 문제

### 5-1. 섬의 개수 (Number of Islands) - DFS

**문제:** `'1'`(육지)과 `'0'`(물)로 이루어진 2D 그리드에서 섬의 개수를 반환하라.
연결된 육지들이 하나의 섬을 이룬다.

```javascript
/**
 * @param {string[][]} grid
 * @return {number}
 * 시간복잡도: O(M * N)
 * 공간복잡도: O(M * N) - 재귀 스택
 */
function numIslands(grid) {
  if (!grid || grid.length === 0) return 0;

  const rows = grid.length;
  const cols = grid[0].length;
  let count = 0;

  function dfs(r, c) {
    // 경계 체크 또는 물이면 종료
    if (r < 0 || r >= rows || c < 0 || c >= cols || grid[r][c] !== '1') {
      return;
    }

    // 방문 표시 (원본 수정)
    grid[r][c] = '#';

    // 상하좌우 탐색
    dfs(r - 1, c);
    dfs(r + 1, c);
    dfs(r, c - 1);
    dfs(r, c + 1);
  }

  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      if (grid[r][c] === '1') {
        count++;
        dfs(r, c); // 연결된 육지 모두 방문 처리
      }
    }
  }

  return count;
}

// 테스트
const grid = [
  ['1','1','0','0','0'],
  ['1','1','0','0','0'],
  ['0','0','1','0','0'],
  ['0','0','0','1','1'],
];
console.log(numIslands(grid)); // 3
```

---

### 5-2. 최단 경로 (Shortest Path in Binary Matrix) - BFS

**문제:** `n x n` 이진 행렬에서 좌상단(0,0)에서 우하단(n-1,n-1)까지 8방향으로 이동 가능할 때
`0`인 셀만 지나는 최단 경로 길이를 반환하라. 경로가 없으면 -1을 반환.

```javascript
/**
 * @param {number[][]} grid
 * @return {number}
 * 시간복잡도: O(N^2)
 * 공간복잡도: O(N^2)
 */
function shortestPathBinaryMatrix(grid) {
  const n = grid.length;

  // 시작 또는 끝이 막혀있는 경우
  if (grid[0][0] === 1 || grid[n - 1][n - 1] === 1) return -1;

  // [행, 열, 현재까지 경로 길이]
  const queue = [[0, 0, 1]];
  grid[0][0] = 1; // 방문 표시

  // 8방향 이동
  const directions = [
    [-1, -1], [-1, 0], [-1, 1],
    [ 0, -1],          [ 0, 1],
    [ 1, -1], [ 1, 0], [ 1, 1],
  ];

  let head = 0;
  while (head < queue.length) {
    const [r, c, dist] = queue[head++];

    if (r === n - 1 && c === n - 1) return dist; // 도착

    for (const [dr, dc] of directions) {
      const nr = r + dr;
      const nc = c + dc;

      if (nr >= 0 && nr < n && nc >= 0 && nc < n && grid[nr][nc] === 0) {
        grid[nr][nc] = 1; // 방문 표시
        queue.push([nr, nc, dist + 1]);
      }
    }
  }

  return -1; // 경로 없음
}

// 테스트
console.log(shortestPathBinaryMatrix([[0,1],[1,0]])); // 2
console.log(shortestPathBinaryMatrix([[0,0,0],[1,1,0],[1,1,0]])); // 4
```

---

### 5-3. 이진 트리 최대 깊이 - DFS

**문제:** 이진 트리의 최대 깊이(루트에서 가장 먼 리프 노드까지의 노드 수)를 반환하라.

```javascript
/**
 * 이진 트리 노드 정의
 */
class TreeNode {
  constructor(val, left = null, right = null) {
    this.val = val;
    this.left = left;
    this.right = right;
  }
}

/**
 * DFS - 재귀 방식 (간결)
 * @param {TreeNode} root
 * @return {number}
 * 시간복잡도: O(N)
 * 공간복잡도: O(H) - H는 트리 높이
 */
function maxDepth(root) {
  if (root === null) return 0;
  return 1 + Math.max(maxDepth(root.left), maxDepth(root.right));
}

/**
 * BFS - 레벨 순회 방식 (반복)
 * 각 레벨을 완전히 처리하며 깊이 카운트
 */
function maxDepthBFS(root) {
  if (root === null) return 0;

  const queue = [root];
  let depth = 0;

  while (queue.length > 0) {
    const levelSize = queue.length; // 현재 레벨의 노드 수
    depth++;

    for (let i = 0; i < levelSize; i++) {
      const node = queue.shift();
      if (node.left) queue.push(node.left);
      if (node.right) queue.push(node.right);
    }
  }

  return depth;
}

// 테스트
//       3
//      / \
//     9  20
//        / \
//       15   7
const root = new TreeNode(3,
  new TreeNode(9),
  new TreeNode(20,
    new TreeNode(15),
    new TreeNode(7)
  )
);
console.log(maxDepth(root));    // 3
console.log(maxDepthBFS(root)); // 3
```

---

## 6. 면접 포인트

### Q1. BFS와 DFS의 공간복잡도 차이를 설명하세요.

- **BFS:** 큐에 같은 레벨의 노드를 모두 저장하므로 최악의 경우 O(V). 균형 잡힌 트리에서 마지막 레벨은 N/2개의 노드를 가질 수 있음.
- **DFS:** 재귀 호출 스택에 현재 경로만 저장하므로 O(H). 편향 트리에서는 O(N), 균형 트리에서는 O(log N).
- **결론:** 넓고 얕은 그래프 → DFS가 공간 효율적. 깊고 좁은 그래프 → BFS가 공간 효율적.

### Q2. 재귀 DFS 대신 반복 DFS를 사용해야 하는 경우는?

JavaScript는 기본 콜 스택 크기가 약 10,000~15,000이므로 매우 깊은 그래프(노드 수가 수만 개)에서 `Maximum call stack size exceeded` 오류 발생 가능. 이 경우 명시적 스택(배열)을 사용한 반복 DFS를 사용.

### Q3. 최단 경로 문제에서 반드시 BFS를 사용해야 하나요?

비가중 그래프(모든 간선 가중치 동일)에서는 BFS가 최단 경로를 보장합니다. 가중 그래프에서는 다익스트라(Dijkstra) 또는 벨만-포드(Bellman-Ford) 알고리즘을 사용해야 합니다.

### Q4. visited 배열을 언제 추가하느냐가 왜 중요한가요?

- **큐에 넣을 때** visited 표시: 중복 탐색 방지 (권장 방식)
- **꺼낼 때** visited 표시: 같은 노드가 큐에 여러 번 들어갈 수 있어 성능 저하

```javascript
// 좋은 방식: 큐에 넣을 때 바로 방문 표시
if (!visited.has(neighbor)) {
  visited.add(neighbor); // 여기서 표시
  queue.push(neighbor);
}

// 나쁜 방식: 꺼낼 때 방문 표시 (중복 큐 삽입 발생)
const node = queue.shift();
if (visited.has(node)) continue;
visited.add(node); // 늦은 표시
```

### Q5. 그래프에 사이클이 있을 때 DFS 처리 방법은?

방향 그래프에서 사이클 감지에는 3색 마킹(흰색/회색/검정)이 유효합니다. 회색 노드(현재 탐색 중)를 다시 방문하면 사이클이 존재합니다. 무방향 그래프에서는 부모 노드를 제외한 방문 노드를 재방문하면 사이클입니다.

### 핵심 요약

| 항목 | BFS | DFS |
|------|-----|-----|
| 최단 경로 | O | X |
| 구현 | 큐(반복) | 재귀 or 스택 |
| 공간 | O(W) W=너비 | O(H) H=높이 |
| 사이클 감지 | 가능 | 3색 마킹 권장 |
| 연결 요소 수 | 가능 | 가능 |
