# 5. 그래프 (Graph)

## 목차
1. 그래프 기본 개념
2. 그래프 표현 방식
3. BFS (너비 우선 탐색)
4. DFS (깊이 우선 탐색)
5. 위상 정렬 (Topological Sort)
6. Union-Find (Disjoint Set)
7. 면접 포인트

---

## 1. 그래프 기본 개념

그래프는 정점(Vertex/Node)과 엣지(Edge)로 구성된 자료구조다. 트리는 그래프의 특수한 형태(사이클 없는 연결 그래프)다.

### 그래프 분류

| 기준 | 종류 | 설명 |
|------|------|------|
| 방향성 | 방향 그래프 (Directed) | 엣지에 방향이 있음 (A → B) |
| | 무방향 그래프 (Undirected) | 엣지에 방향이 없음 (A — B) |
| 가중치 | 가중치 그래프 (Weighted) | 엣지에 비용/거리 정보 포함 |
| | 비가중치 그래프 (Unweighted) | 엣지에 비용 없음 |
| 연결성 | 연결 그래프 (Connected) | 모든 정점 쌍 사이에 경로 존재 |
| | 비연결 그래프 (Disconnected) | 일부 정점 사이에 경로 없음 |

### 핵심 용어
- **차수(Degree)**: 정점에 연결된 엣지 수. 방향 그래프에서는 진입 차수(in-degree)와 진출 차수(out-degree)로 구분
- **경로(Path)**: 정점 간 연결된 엣지의 순서
- **사이클(Cycle)**: 시작 정점으로 돌아오는 경로
- **DAG(Directed Acyclic Graph)**: 방향이 있고 사이클이 없는 그래프. 위상 정렬 적용 가능

---

## 2. 그래프 표현 방식

### 인접 행렬 (Adjacency Matrix)

V×V 2차원 배열로 표현. `matrix[i][j] = 1`이면 i에서 j로의 엣지 존재.

```javascript
class GraphMatrix {
  constructor(vertices) {
    this.V = vertices;
    this.matrix = Array.from({ length: vertices }, () => Array(vertices).fill(0));
  }

  addEdge(u, v, weight = 1) {
    this.matrix[u][v] = weight;
    this.matrix[v][u] = weight; // 무방향 그래프
  }

  hasEdge(u, v) {
    return this.matrix[u][v] !== 0;
  }

  getNeighbors(u) {
    const neighbors = [];
    for (let v = 0; v < this.V; v++) {
      if (this.matrix[u][v] !== 0) neighbors.push(v);
    }
    return neighbors;
  }
}
```

### 인접 리스트 (Adjacency List)

Map 또는 배열로 각 정점의 이웃 목록을 저장.

```javascript
class GraphList {
  constructor() {
    this.adjacencyList = new Map();
  }

  addVertex(vertex) {
    if (!this.adjacencyList.has(vertex)) {
      this.adjacencyList.set(vertex, []);
    }
  }

  addEdge(u, v, weight = 1) {
    this.addVertex(u);
    this.addVertex(v);
    this.adjacencyList.get(u).push({ node: v, weight });
    this.adjacencyList.get(v).push({ node: u, weight }); // 무방향 그래프
  }

  getNeighbors(vertex) {
    return this.adjacencyList.get(vertex) || [];
  }
}
```

### 인접 행렬 vs 인접 리스트 비교

| 항목 | 인접 행렬 | 인접 리스트 |
|------|-----------|-------------|
| 공간 복잡도 | O(V²) | O(V + E) |
| 엣지 존재 확인 | O(1) | O(degree) |
| 이웃 목록 조회 | O(V) | O(degree) |
| 엣지 추가 | O(1) | O(1) |
| 적합한 경우 | 밀집 그래프 (Dense) | 희소 그래프 (Sparse) |

---

## 3. BFS (너비 우선 탐색)

BFS는 시작 정점에서 가까운 정점부터 방문한다. 큐(Queue)를 사용하며, 비가중치 그래프의 최단 경로 탐색에 활용된다.

**시간복잡도**: O(V + E)  
**공간복잡도**: O(V)

```javascript
function bfs(graph, start) {
  const visited = new Set();
  const queue = [start];
  const result = [];

  visited.add(start);

  while (queue.length) {
    const vertex = queue.shift(); // O(n) — 실제 구현 시 deque 사용 권장
    result.push(vertex);

    for (const { node } of graph.getNeighbors(vertex)) {
      if (!visited.has(node)) {
        visited.add(node);
        queue.push(node);
      }
    }
  }
  return result;
}

// 최단 경로 (비가중치)
function bfsShortestPath(graph, start, end) {
  const visited = new Set([start]);
  const queue = [[start, [start]]]; // [현재 노드, 경로]

  while (queue.length) {
    const [vertex, path] = queue.shift();
    if (vertex === end) return path;

    for (const { node } of graph.getNeighbors(vertex)) {
      if (!visited.has(node)) {
        visited.add(node);
        queue.push([node, [...path, node]]);
      }
    }
  }
  return null; // 경로 없음
}

// 사용 예시
const g = new GraphList();
['A','B','C','D','E'].forEach(v => g.addVertex(v));
g.addEdge('A', 'B');
g.addEdge('A', 'C');
g.addEdge('B', 'D');
g.addEdge('C', 'E');

console.log(bfs(g, 'A'));                      // ['A', 'B', 'C', 'D', 'E']
console.log(bfsShortestPath(g, 'A', 'E'));     // ['A', 'C', 'E']
```

---

## 4. DFS (깊이 우선 탐색)

DFS는 한 방향으로 최대한 깊이 탐색하다가 막히면 되돌아온다. 재귀 또는 명시적 스택으로 구현한다.

**시간복잡도**: O(V + E)  
**공간복잡도**: O(V) (재귀 스택 포함)

### 재귀 구현

```javascript
function dfsRecursive(graph, start, visited = new Set()) {
  visited.add(start);
  const result = [start];

  for (const { node } of graph.getNeighbors(start)) {
    if (!visited.has(node)) {
      result.push(...dfsRecursive(graph, node, visited));
    }
  }
  return result;
}
```

### 반복 구현 (명시적 스택)

```javascript
function dfsIterative(graph, start) {
  const visited = new Set();
  const stack = [start];
  const result = [];

  while (stack.length) {
    const vertex = stack.pop();

    if (visited.has(vertex)) continue;
    visited.add(vertex);
    result.push(vertex);

    // 이웃을 역순으로 push해야 원래 순서대로 방문
    const neighbors = graph.getNeighbors(vertex);
    for (let i = neighbors.length - 1; i >= 0; i--) {
      if (!visited.has(neighbors[i].node)) {
        stack.push(neighbors[i].node);
      }
    }
  }
  return result;
}
```

### 연결 요소 (Connected Components) 탐색

```javascript
function findConnectedComponents(graph) {
  const visited = new Set();
  const components = [];

  for (const vertex of graph.adjacencyList.keys()) {
    if (!visited.has(vertex)) {
      const component = [];
      dfsForComponent(graph, vertex, visited, component);
      components.push(component);
    }
  }
  return components;
}

function dfsForComponent(graph, vertex, visited, component) {
  visited.add(vertex);
  component.push(vertex);
  for (const { node } of graph.getNeighbors(vertex)) {
    if (!visited.has(node)) dfsForComponent(graph, node, visited, component);
  }
}
```

---

## 5. 위상 정렬 (Topological Sort)

위상 정렬은 DAG(방향 비순환 그래프)에서 모든 간선 u→v에 대해 u가 v보다 앞에 오도록 정점을 선형으로 나열하는 것이다. 빌드 의존성, 강의 선수 과목, 작업 스케줄링 등에 활용된다.

### Kahn's Algorithm (BFS 기반)

진입 차수(in-degree)가 0인 정점부터 처리한다.

```javascript
function topologicalSort(vertices, edges) {
  // 인접 리스트와 진입 차수 초기화
  const adjacencyList = new Map();
  const inDegree = new Map();

  for (const v of vertices) {
    adjacencyList.set(v, []);
    inDegree.set(v, 0);
  }

  for (const [u, v] of edges) {
    adjacencyList.get(u).push(v);
    inDegree.set(v, inDegree.get(v) + 1);
  }

  // 진입 차수가 0인 정점을 큐에 추가
  const queue = [];
  for (const [v, degree] of inDegree) {
    if (degree === 0) queue.push(v);
  }

  const result = [];

  while (queue.length) {
    const vertex = queue.shift();
    result.push(vertex);

    for (const neighbor of adjacencyList.get(vertex)) {
      inDegree.set(neighbor, inDegree.get(neighbor) - 1);
      if (inDegree.get(neighbor) === 0) {
        queue.push(neighbor);
      }
    }
  }

  // 사이클 감지: 모든 정점이 처리되지 않은 경우
  if (result.length !== vertices.length) {
    throw new Error('그래프에 사이클이 존재합니다.');
  }

  return result;
}

// 사용 예시: 강의 수강 순서
const courses = ['A', 'B', 'C', 'D', 'E'];
const prerequisites = [['A', 'B'], ['A', 'C'], ['B', 'D'], ['C', 'D'], ['D', 'E']];
console.log(topologicalSort(courses, prerequisites));
// ['A', 'B', 'C', 'D', 'E']
```

---

## 6. Union-Find (Disjoint Set Union, DSU)

Union-Find는 여러 원소를 서로소 집합(disjoint set)으로 관리하는 자료구조다. 두 원소가 같은 집합에 속하는지 빠르게 확인하고, 두 집합을 합치는 연산을 효율적으로 수행한다.

### 핵심 연산
- **find(x)**: x가 속한 집합의 루트(대표 원소) 반환
- **union(x, y)**: x와 y가 속한 두 집합을 합침

### 최적화 기법
- **경로 압축(Path Compression)**: find 시 모든 노드를 루트에 직접 연결
- **랭크 기반 합치기(Union by Rank)**: 트리 높이가 낮은 쪽을 높은 쪽에 합침

```javascript
class UnionFind {
  constructor(size) {
    this.parent = Array.from({ length: size }, (_, i) => i);
    this.rank = Array(size).fill(0);
    this.count = size; // 집합 수
  }

  // 경로 압축을 적용한 find
  find(x) {
    if (this.parent[x] !== x) {
      this.parent[x] = this.find(this.parent[x]); // 재귀적 경로 압축
    }
    return this.parent[x];
  }

  // 랭크 기반 union
  union(x, y) {
    const rootX = this.find(x);
    const rootY = this.find(y);

    if (rootX === rootY) return false; // 이미 같은 집합

    if (this.rank[rootX] < this.rank[rootY]) {
      this.parent[rootX] = rootY;
    } else if (this.rank[rootX] > this.rank[rootY]) {
      this.parent[rootY] = rootX;
    } else {
      this.parent[rootY] = rootX;
      this.rank[rootX]++;
    }

    this.count--;
    return true;
  }

  isConnected(x, y) {
    return this.find(x) === this.find(y);
  }
}

// 사용 예시: 크루스칼 알고리즘 (최소 신장 트리)
function kruskal(vertices, edges) {
  // 가중치 기준 오름차순 정렬
  edges.sort((a, b) => a[2] - b[2]);

  const uf = new UnionFind(vertices);
  const mst = [];
  let totalCost = 0;

  for (const [u, v, weight] of edges) {
    if (uf.union(u, v)) {
      mst.push([u, v, weight]);
      totalCost += weight;
    }
  }
  return { mst, totalCost };
}

// 예시: 4개 정점, 5개 엣지
const result = kruskal(4, [
  [0, 1, 10],
  [0, 2, 6],
  [0, 3, 5],
  [1, 3, 15],
  [2, 3, 4],
]);
console.log(result.mst);       // [[2,3,4], [0,3,5], [0,1,10]]
console.log(result.totalCost); // 19
```

---

## 7. 면접 포인트

### BFS vs DFS

**Q. BFS와 DFS는 각각 언제 사용하나요?**

- **BFS 적합**: 최단 경로 탐색 (비가중치), 레벨 순서 탐색, 두 노드 간의 최소 홉(hop) 수
- **DFS 적합**: 경로 존재 여부, 사이클 감지, 위상 정렬, 연결 요소 탐색, 백트래킹 문제

**Q. BFS에서 큐를 배열로 구현할 때의 문제점은?**

`Array.shift()`는 O(n)이다. 실제 성능이 중요한 경우 연결 리스트 기반 deque나 인덱스 포인터를 사용하는 방식으로 구현해야 O(1) dequeue를 달성할 수 있다.

### 그래프 표현

**Q. 언제 인접 행렬, 언제 인접 리스트를 사용하나요?**

엣지 수가 V²에 가까운 밀집 그래프(Dense Graph)에는 인접 행렬이 유리하다. 실제 대부분의 현실 그래프(소셜 네트워크, 도로 지도 등)는 희소 그래프(Sparse Graph)로, 인접 리스트가 공간 효율적이다. 특정 엣지의 빠른 존재 여부 확인이 필요하다면 인접 행렬을 선택한다.

### 위상 정렬

**Q. 위상 정렬은 결과가 유일한가요?**

아니다. 진입 차수가 0인 정점이 여러 개라면 처리 순서에 따라 다른 위상 정렬 결과가 나올 수 있다. 사이클이 없는 DAG라면 적어도 하나의 위상 정렬이 반드시 존재한다.

**Q. 사이클 감지 방법은?**

- Kahn's Algorithm: 처리된 정점 수가 전체 정점 수보다 적으면 사이클 존재
- DFS: 현재 방문 중인 노드(gray node)를 다시 방문하면 사이클 존재

### Union-Find

**Q. 경로 압축과 랭크 기반 합치기를 함께 사용하면 시간복잡도는?**

사실상 O(α(n)) amortized로, 여기서 α는 역 아커만 함수(Inverse Ackermann Function)다. 이 값은 실용적인 모든 n에 대해 5 이하이므로 거의 O(1)로 볼 수 있다.

**Q. Union-Find의 대표적인 활용 사례는?**

- 크루스칼 알고리즘 (MST): 사이클 생성 여부 확인
- 네트워크 연결 여부 판단
- 동치 관계 처리
- LeetCode "Number of Islands", "Redundant Connection" 류의 문제
