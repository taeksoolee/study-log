# 14. 최단 경로 (Shortest Path)

> 🎨 **인터랙티브 시각화: [다익스트라](./visualizer/10-dijkstra.html) · [플로이드-워셜](./visualizer/23-floyd-warshall.html)** — 거리 완화·갱신 과정을 확인하세요.

## 목차
1. [문제 분류와 알고리즘 선택](#1-문제-분류와-알고리즘-선택)
2. [다익스트라 (Dijkstra)](#2-다익스트라-dijkstra)
3. [벨만-포드 (Bellman-Ford)](#3-벨만-포드-bellman-ford)
4. [플로이드-워셜 (Floyd-Warshall)](#4-플로이드-워셜-floyd-warshall)
5. [BFS = 가중치 없는 그래프의 최단 경로](#5-bfs--가중치-없는-그래프의-최단-경로)
6. [비교 정리](#6-비교-정리)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 문제 분류와 알고리즘 선택

"무엇에서 무엇까지의 최단 거리인가"와 "가중치 성질"로 알고리즘이 갈린다.

| 상황 | 알고리즘 | 복잡도 |
|------|---------|--------|
| 가중치 없음 (간선 비용 동일) | BFS | O(V+E) |
| 양의 가중치, 단일 출발점 | 다익스트라 | O(E log V) |
| 음의 가중치 가능, 단일 출발점 | 벨만-포드 | O(V·E) |
| 모든 쌍 최단 경로 | 플로이드-워셜 | O(V³) |

> 첫 질문: "음의 간선이 있나?" 있으면 다익스트라는 틀린다 → 벨만-포드. "모든 쌍?"이면 플로이드.

---

## 2. 다익스트라 (Dijkstra)

양의 가중치 그래프에서 한 출발점→모든 정점 최단 거리. **현재까지 가장 가까운 정점을 확정**하며 확장(그리디). 우선순위 큐(최소 힙)로 가속.

```javascript
// graph[u] = [[v, w], ...]  (인접 리스트, w >= 0)
function dijkstra(graph, start, n) {
  const dist = new Array(n).fill(Infinity);
  dist[start] = 0;
  const pq = new MinHeap();         // [거리, 정점], 거리 기준 최소 힙
  pq.push([0, start]);

  while (pq.size()) {
    const [d, u] = pq.pop();
    if (d > dist[u]) continue;       // 이미 더 짧게 확정됨 → 스킵 (지연 삭제)
    for (const [v, w] of graph[u]) {
      if (dist[u] + w < dist[v]) {   // 완화(relaxation)
        dist[v] = dist[u] + w;
        pq.push([dist[v], v]);
      }
    }
  }
  return dist;
}
```

- **음의 간선에서 실패**: 한 번 확정한 정점을 다시 줄일 수 없다는 가정이 깨진다.
- `if (d > dist[u]) continue`로 낡은 큐 항목을 거른다(힙 안의 중복 허용 방식).

---

## 3. 벨만-포드 (Bellman-Ford)

음의 가중치를 허용하는 단일 출발점 최단 경로. 모든 간선을 **V-1번 반복 완화**한다.

```javascript
function bellmanFord(edges, start, n) {
  const dist = new Array(n).fill(Infinity);
  dist[start] = 0;
  for (let i = 0; i < n - 1; i++) {        // V-1회 반복
    for (const [u, v, w] of edges) {
      if (dist[u] !== Infinity && dist[u] + w < dist[v]) {
        dist[v] = dist[u] + w;
      }
    }
  }
  // V번째에도 완화되면 음수 사이클 존재
  for (const [u, v, w] of edges) {
    if (dist[u] !== Infinity && dist[u] + w < dist[v]) return null; // 음수 사이클
  }
  return dist;
}
```

> 핵심 능력: **음수 사이클 탐지**. 최단 경로가 정의되지 않는 경우(사이클 돌수록 거리 감소)를 잡아낸다. 최단 경로는 간선을 최대 V-1개 쓰므로 V-1번 완화면 충분하다.

---

## 4. 플로이드-워셜 (Floyd-Warshall)

모든 정점 쌍 간 최단 거리. **"k를 경유지로 허용했을 때"** 거리를 점진적으로 갱신하는 DP.

```javascript
function floydWarshall(dist, n) {  // dist[i][j] 초기화: 간선 없으면 Infinity, 자기자신 0
  for (let k = 0; k < n; k++)       // 경유 정점 k (가장 바깥!)
    for (let i = 0; i < n; i++)
      for (let j = 0; j < n; j++)
        if (dist[i][k] + dist[k][j] < dist[i][j])
          dist[i][j] = dist[i][k] + dist[k][j];
  return dist;
}
```

> 함정: **k 루프가 가장 바깥**이어야 한다(i, j보다 먼저). 순서를 바꾸면 틀린다. 음의 간선은 OK, 음수 사이클은 `dist[i][i] < 0`으로 탐지.

---

## 5. BFS = 가중치 없는 그래프의 최단 경로

모든 간선 비용이 같으면 BFS가 곧 최단 경로다(레벨 = 거리). 가중치가 0 또는 1만 있으면 **0-1 BFS**(덱)로 O(V+E).

```javascript
function bfsShortest(graph, start, n) {
  const dist = new Array(n).fill(-1);
  dist[start] = 0;
  const q = [start]; let head = 0;
  while (head < q.length) {
    const u = q[head++];
    for (const v of graph[u]) {
      if (dist[v] === -1) { dist[v] = dist[u] + 1; q.push(v); }
    }
  }
  return dist;
}
```

---

## 6. 비교 정리

| | 다익스트라 | 벨만-포드 | 플로이드-워셜 |
|--|-----------|----------|--------------|
| 출발점 | 단일 | 단일 | 전체 쌍 |
| 음의 간선 | ❌ | ✅ | ✅ |
| 음수 사이클 탐지 | ❌ | ✅ | ✅ |
| 복잡도 | O(E log V) | O(V·E) | O(V³) |
| 적합 | 큰 그래프, 양수 | 음수/사이클 검출 | 작고 조밀(V≤500) |

---

## 7. 면접 포인트

**Q. 다익스트라가 음의 간선에서 실패하는 이유는?**
> 다익스트라는 "가장 가까운 정점을 확정하면 더 줄어들지 않는다"는 그리디 가정에 의존한다. 음의 간선이 있으면 나중에 더 짧은 경로가 생길 수 있어 이 가정이 깨진다. 음수 간선이 있으면 벨만-포드를 쓴다.

**Q. 벨만-포드는 왜 V-1번 반복하나요?**
> 최단 경로는 사이클을 포함하지 않으므로 최대 V-1개의 간선으로 이루어진다. 한 번의 전체 완화로 최소 한 정점의 최단 거리가 확정되므로 V-1번이면 모두 확정된다. V번째에도 완화되면 음수 사이클이 있는 것이다.

**Q. 플로이드-워셜에서 k 루프를 가장 바깥에 두는 이유는?**
> `dist[i][j]`를 "0..k 정점만 경유지로 허용한 최단 거리"로 정의하는 DP다. k를 하나씩 늘리며 모든 (i,j)를 갱신해야 하므로 k가 가장 바깥이어야 한다. i나 j를 바깥에 두면 아직 갱신 안 된 중간값을 써서 틀린다.

**Q. 가중치가 모두 같은 그래프의 최단 경로는?**
> BFS면 충분하다(레벨이 곧 거리, O(V+E)). 다익스트라는 불필요한 오버헤드다. 가중치가 0/1뿐이면 0-1 BFS(덱)로 O(V+E)에 푼다.

**Q. 어떤 상황에 플로이드-워셜이 다익스트라보다 나은가요?**
> 모든 정점 쌍의 최단 거리가 필요하고 정점이 적을 때(대략 V≤500). 모든 쌍을 다익스트라로 V번 돌리는 것(O(V·E log V))보다 구현이 간단하고, 음의 간선도 처리한다.
