# 13. 위상 정렬 (Topological Sort)

> 🎨 **[인터랙티브 시각화](./visualizer/11-topological-sort.html)** — 진입차수·큐 기반 Kahn 동작을 확인하세요.

## 목차
1. [개념: 의존성 순서 정하기](#1-개념-의존성-순서-정하기)
2. [Kahn 알고리즘 (BFS, 진입차수)](#2-kahn-알고리즘-bfs-진입차수)
3. [DFS 기반 위상 정렬](#3-dfs-기반-위상-정렬)
4. [사이클 탐지](#4-사이클-탐지)
5. [응용 사례](#5-응용-사례)
6. [시간복잡도와 두 방식 비교](#6-시간복잡도와-두-방식-비교)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 개념: 의존성 순서 정하기

위상 정렬은 **방향 비순환 그래프(DAG)**의 정점들을, 모든 간선 `u → v`에 대해 u가 v보다 앞에 오도록 일렬로 세우는 것이다. "선수과목을 먼저 듣는 수강 순서", "빌드 의존성 순서"가 대표 예.

- **DAG에서만** 가능하다. 사이클이 있으면 순서를 정할 수 없다(→ 사이클 탐지에 활용).
- 정답이 **여러 개**일 수 있다(부분 순서).

```
A → C,  B → C,  C → D   ⇒  [A, B, C, D] 또는 [B, A, C, D]
```

---

## 2. Kahn 알고리즘 (BFS, 진입차수)

각 정점의 **진입차수(in-degree, 들어오는 간선 수)**를 세고, 진입차수 0인 정점부터 큐로 처리한다.

```javascript
function topoSortKahn(n, edges) {
  const adj = Array.from({length: n}, () => []);
  const indeg = new Array(n).fill(0);
  for (const [u, v] of edges) {   // u → v
    adj[u].push(v);
    indeg[v]++;
  }
  const queue = [];
  for (let i = 0; i < n; i++) if (indeg[i] === 0) queue.push(i);

  const order = [];
  while (queue.length) {
    const u = queue.shift();      // (성능엔 deque 권장)
    order.push(u);
    for (const v of adj[u]) {
      if (--indeg[v] === 0) queue.push(v); // 선행 다 끝나면 큐에
    }
  }
  // 모든 정점을 못 담았으면 사이클 존재
  return order.length === n ? order : null;
}
```

> 직관: "지금 당장 들을 수 있는(선행 없는) 과목"을 큐에 넣고, 처리할 때마다 그 과목을 선행으로 하던 과목들의 카운트를 깎는다.

---

## 3. DFS 기반 위상 정렬

각 정점에서 DFS를 끝낸 **후위(post-order)** 순서로 스택에 쌓고, 마지막에 뒤집는다.

```javascript
function topoSortDFS(n, edges) {
  const adj = Array.from({length: n}, () => []);
  for (const [u, v] of edges) adj[u].push(v);

  const state = new Array(n).fill(0); // 0=미방문,1=방문중,2=완료
  const order = [];
  let hasCycle = false;

  function dfs(u) {
    state[u] = 1;                 // 방문 중
    for (const v of adj[u]) {
      if (state[v] === 1) hasCycle = true;   // 방문 중 정점 재방문 = 사이클
      else if (state[v] === 0) dfs(v);
    }
    state[u] = 2;                 // 완료
    order.push(u);                // 후위 순서로 추가
  }
  for (let i = 0; i < n; i++) if (state[i] === 0) dfs(i);

  return hasCycle ? null : order.reverse(); // 뒤집어야 위상 순서
}
```

---

## 4. 사이클 탐지

위상 정렬은 사이클 판정과 동전의 양면이다.

- **Kahn**: 큐가 비었는데 `order.length < n`이면, 진입차수가 0이 되지 못한 정점들이 서로 물려 있다 → 사이클.
- **DFS**: "방문 중(state=1)" 정점으로 가는 간선(back edge)을 만나면 사이클.

> 무방향 그래프 사이클은 유니온 파인드/DFS로, **방향 그래프** 사이클은 위상 정렬(또는 DFS 3색)로 푼다는 점을 구분하라.

---

## 5. 응용 사례

- **수강신청/선수과목 순서** (LeetCode "Course Schedule").
- **빌드 시스템·패키지 의존성** 해석 순서(Make, npm, 번들러의 모듈 그래프).
- **작업 스케줄링**: 선행 작업 제약이 있는 태스크 순서.
- **스프레드시트 수식** 재계산 순서(셀 의존성).

---

## 6. 시간복잡도와 두 방식 비교

| | Kahn (BFS) | DFS |
|--|-----------|-----|
| 시간 | O(V + E) | O(V + E) |
| 공간 | 진입차수 + 큐 | 재귀 스택 + 상태 |
| 사이클 탐지 | 처리 수 < V | back edge(방문중) |
| 장점 | 반복문, 스택오버플로 없음 | 구현 간결, 다른 DFS와 결합 쉬움 |

> 정점이 매우 많으면 재귀 DFS는 스택 오버플로 위험이 있어 Kahn(BFS) 쪽이 안전하다.

---

## 7. 면접 포인트

**Q. 위상 정렬은 어떤 그래프에서 가능한가요?**
> 방향 비순환 그래프(DAG)에서만 가능하다. 사이클이 있으면 "먼저"의 순서를 정할 수 없다. 그래서 위상 정렬 시도가 실패하면 그래프에 사이클이 있다는 뜻이다.

**Q. Kahn 알고리즘의 핵심 아이디어는?**
> 진입차수 0인(선행이 없는) 정점부터 큐에 넣어 처리하고, 처리할 때마다 인접 정점의 진입차수를 1씩 줄여 0이 되면 큐에 넣는다. 모든 정점을 담지 못하면 사이클이 있는 것이다.

**Q. Kahn과 DFS 방식의 사이클 탐지 차이는?**
> Kahn은 처리한 정점 수가 전체보다 적으면 사이클. DFS는 "방문 중" 상태인 정점으로 되돌아가는 back edge를 만나면 사이클이다.

**Q. 무방향 그래프 사이클과 방향 그래프 사이클 판정은 어떻게 다른가요?**
> 무방향은 유니온 파인드나 DFS(부모 제외 방문 정점 재방문)로, 방향 그래프는 위상 정렬 실패 또는 DFS 3색(미방문/방문중/완료)에서 방문중 정점 재방문으로 판정한다.

**Q. 정점이 매우 많을 때 어떤 방식이 안전한가요?**
> 재귀 DFS는 깊이가 깊으면 스택 오버플로가 날 수 있어, 반복문 기반의 Kahn(BFS) 위상 정렬이 더 안전하다. 둘 다 시간복잡도는 O(V+E)로 같다.
