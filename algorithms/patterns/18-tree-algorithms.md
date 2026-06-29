# 18. 트리 알고리즘 (트리 DP · LCA)

> [트리 자료구조](../data-structures/04-tree.md)에서 순회·BST·힙을 다뤘다. 여기서는 코테 고난도 단골인 **트리 DP**와 **최소 공통 조상(LCA)**을 다룬다.

## 목차
1. [트리 순회 = DFS](#1-트리-순회--dfs)
2. [트리 DP — 서브트리 정보 모으기](#2-트리-dp--서브트리-정보-모으기)
3. [예제: 트리의 지름](#3-예제-트리의-지름)
4. [LCA — 최소 공통 조상](#4-lca--최소-공통-조상)
5. [LCA — 이진 상승 (Binary Lifting)](#5-lca--이진-상승-binary-lifting)
6. [오일러 투어 & 깊이 활용](#6-오일러-투어--깊이-활용)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 트리 순회 = DFS

트리는 사이클 없는 연결 그래프라 방문 체크 대신 **부모만 제외**하면 된다. 정점 수가 크면 재귀 깊이 주의(반복 DFS 고려).

```javascript
function dfs(u, parent, adj) {
  for (const v of adj[u]) {
    if (v === parent) continue;   // 부모로 되돌아가지 않음
    dfs(v, u, adj);
  }
}
```

---

## 2. 트리 DP — 서브트리 정보 모으기

각 노드의 답을 **자식들의 답으로부터** 후위(post-order)로 합친다. "서브트리 크기", "서브트리 최대 합", "트리에서 독립집합 최대" 등.

```javascript
// 예: 각 노드를 루트로 하는 서브트리의 노드 수
function subtreeSize(u, parent, adj, size) {
  size[u] = 1;
  for (const v of adj[u]) {
    if (v === parent) continue;
    subtreeSize(v, u, adj, size);
    size[u] += size[v];        // 자식 결과를 합산 (후위)
  }
}
```

트리 DP 점화식의 전형: `dp[u] = f(dp[자식들])`. 노드 상태가 "포함/미포함" 둘로 갈리는 문제(트리에서 최대 독립집합)는 `dp[u][0/1]`로 둔다.

---

## 3. 예제: 트리의 지름

트리의 지름(가장 먼 두 노드 거리)은 트리 DP 또는 **"두 번의 BFS/DFS"**로 O(n)에 구한다.

```javascript
// 방법: 임의 점에서 가장 먼 점 a를 찾고, a에서 가장 먼 점까지 거리 = 지름
function diameter(adj, n) {
  const bfsFar = (s) => {
    const dist = new Array(n).fill(-1); dist[s] = 0;
    const q = [s]; let head = 0, far = s;
    while (head < q.length) {
      const u = q[head++];
      for (const v of adj[u]) if (dist[v] === -1) {
        dist[v] = dist[u] + 1;
        if (dist[v] > dist[far]) far = v;
        q.push(v);
      }
    }
    return [far, dist[far]];
  };
  const [a] = bfsFar(0);       // 1차: 한 끝점 a
  const [, d] = bfsFar(a);     // 2차: a에서 최대 거리 = 지름
  return d;
}
```

> "임의 점에서 가장 먼 점은 반드시 지름의 한 끝"이라는 성질을 이용. 가중치 트리면 BFS 대신 DFS로 거리 누적.

---

## 4. LCA — 최소 공통 조상

두 노드 u, v의 공통 조상 중 **가장 깊은** 노드. 트리에서 두 노드 간 거리, 경로 질의의 기본. `dist(u,v) = depth[u] + depth[v] - 2·depth[lca]`.

- 단순법: 깊은 쪽을 같은 깊이까지 올리고, 둘이 만날 때까지 함께 한 칸씩 올림 → 질의당 O(높이). 질의가 많으면 느리다.
- 빠른 법: **이진 상승**으로 전처리 O(n log n), 질의 O(log n).

---

## 5. LCA — 이진 상승 (Binary Lifting)

각 노드의 `2^k`번째 조상을 미리 계산(`up[k][v]`). 점프를 2의 거듭제곱 단위로 해 O(log n) 질의.

```javascript
const LOG = 17;                 // 2^17 > 최대 노드 수
function preprocess(adj, n, root) {
  const up = Array.from({length: LOG}, () => new Array(n).fill(-1));
  const depth = new Array(n).fill(0);
  // DFS로 부모(up[0])와 depth 채우기
  const stack = [[root, -1]];
  while (stack.length) {
    const [u, p] = stack.pop();
    up[0][u] = p;
    for (const v of adj[u]) if (v !== p) { depth[v] = depth[u] + 1; stack.push([v, u]); }
  }
  for (let k = 1; k < LOG; k++)          // 2^k 조상 = 2^(k-1) 조상의 2^(k-1) 조상
    for (let v = 0; v < n; v++)
      up[k][v] = up[k-1][v] === -1 ? -1 : up[k-1][up[k-1][v]];
  return { up, depth };
}

function lca(u, v, up, depth) {
  if (depth[u] < depth[v]) [u, v] = [v, u];
  let diff = depth[u] - depth[v];
  for (let k = 0; k < LOG; k++) if ((diff >> k) & 1) u = up[k][u]; // 같은 깊이로
  if (u === v) return u;
  for (let k = LOG - 1; k >= 0; k--)     // 함께 점프 (만나기 직전까지)
    if (up[k][u] !== up[k][v]) { u = up[k][u]; v = up[k][v]; }
  return up[0][u];                       // 그 부모가 LCA
}
```

---

## 6. 오일러 투어 & 깊이 활용

- **오일러 투어(Euler tour)**: DFS 진입/이탈 시각(in/out)을 기록하면 "u가 v의 조상인가?"를 `in[u] ≤ in[v] && out[v] ≤ out[u]`로 O(1) 판정. 서브트리를 배열 구간으로 평탄화해 세그먼트 트리와 결합(서브트리 합 질의).
- LCA를 오일러 투어 + 구간 최소(Sparse Table/세그먼트 트리)로도 구현 가능.

---

## 7. 면접 포인트

**Q. 트리 DP의 일반적 형태는?**
> 각 노드의 답을 자식들의 답으로 정의해 후위 순회로 합친다(`dp[u] = f(dp[children])`). 노드가 두 상태(포함/미포함)를 가지면 `dp[u][0/1]`로 둔다. 서브트리 크기·최대 독립집합·서브트리 합이 대표 예다.

**Q. 트리의 지름을 O(n)에 구하는 방법은?**
> 임의의 점에서 가장 먼 점 a를 찾고(1차 탐색), a에서 가장 먼 거리를 구하면(2차 탐색) 그게 지름이다. "임의 점에서 가장 먼 점은 지름의 한 끝"이라는 성질을 이용한다.

**Q. LCA를 빠르게 구하는 이진 상승(binary lifting)의 원리는?**
> 각 노드의 2^k번째 조상을 `up[k][v]=up[k-1][up[k-1][v]]`로 전처리(O(n log n))한 뒤, 두 노드를 같은 깊이로 맞추고 2의 거듭제곱 단위로 함께 점프해 만나기 직전까지 올린다. 질의당 O(log n).

**Q. 두 노드의 거리를 LCA로 어떻게 구하나요?**
> `dist(u,v) = depth[u] + depth[v] - 2·depth[lca(u,v)]`. 경로가 LCA를 거치므로 양쪽 깊이에서 공통 조상 깊이를 두 번 뺀다.

**Q. 오일러 투어는 무엇에 쓰나요?**
> DFS in/out 시각으로 서브트리를 배열의 연속 구간으로 평탄화한다. "조상 관계 O(1) 판정", "서브트리 합/갱신을 세그먼트 트리로 O(log n)" 같은 트리 구간 질의에 쓴다.
