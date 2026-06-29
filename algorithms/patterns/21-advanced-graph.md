# 21. 그래프 심화 (SCC · 이분 그래프 · 단절점)

> [BFS/DFS](./03-bfs-dfs.md)·[최단경로](./14-shortest-path.md)·[MST](./19-mst.md) 위에서, 그래프 구조 분석 알고리즘을 다룬다.

## 목차
1. [강한 연결 요소 (SCC)](#1-강한-연결-요소-scc)
2. [코사라주 알고리즘](#2-코사라주-알고리즘)
3. [타잔 알고리즘 (개념)](#3-타잔-알고리즘-개념)
4. [이분 그래프 판정](#4-이분-그래프-판정)
5. [단절점·다리 (Articulation Point·Bridge)](#5-단절점다리-articulation-pointbridge)
6. [오일러 경로](#6-오일러-경로)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 강한 연결 요소 (SCC)

**방향 그래프**에서 서로 도달 가능한(`u→v`이고 `v→u`인) 정점들의 최대 집합. SCC로 압축하면 그래프가 **DAG**가 되어 위상 정렬·2-SAT 등에 쓰인다.

```
A↔B, B→C, C→D, D→C  ⇒  SCC: {A,B}, {C,D}
```

두 표준: **코사라주**(2번 DFS, 구현 쉬움), **타잔**(1번 DFS, 빠름).

---

## 2. 코사라주 알고리즘

1. 원그래프 DFS로 **종료 순서**를 스택에 기록.
2. 모든 간선을 **뒤집은 역그래프** 생성.
3. 스택 역순(종료 늦은 것부터)으로 역그래프 DFS → 한 번에 닿는 정점들이 하나의 SCC.

```javascript
function kosaraju(n, adj) {
  const radj = Array.from({length: n}, () => []);
  for (let u = 0; u < n; u++) for (const v of adj[u]) radj[v].push(u); // 역간선

  const order = [], visited = new Array(n).fill(false);
  const dfs1 = (u) => { visited[u] = true;
    for (const v of adj[u]) if (!visited[v]) dfs1(v);
    order.push(u);                       // 종료 순서 기록
  };
  for (let u = 0; u < n; u++) if (!visited[u]) dfs1(u);

  const comp = new Array(n).fill(-1); let c = 0;
  const dfs2 = (u) => { comp[u] = c;
    for (const v of radj[u]) if (comp[v] === -1) dfs2(v);
  };
  for (let i = n - 1; i >= 0; i--) {       // 종료 늦은 정점부터
    const u = order[i];
    if (comp[u] === -1) { dfs2(u); c++; } // 새 SCC
  }
  return { comp, count: c };
}
// 시간 O(V + E)
```

---

## 3. 타잔 알고리즘 (개념)

DFS 한 번으로 SCC를 찾는다. 각 정점에 **방문 순서(disc)**와 **low-link**(자신/후손이 역간선으로 도달 가능한 가장 이른 정점)를 매긴다. `low[u] === disc[u]`이면 u가 SCC의 루트 → 스택에서 그 SCC를 떼어낸다. 단절점·다리 알고리즘과 같은 low-link 골격을 공유한다.

---

## 4. 이분 그래프 판정

정점을 두 색으로 칠해 **인접 정점이 다른 색**이 되게 할 수 있으면 이분 그래프. BFS/DFS로 2색칠, 충돌하면 아님. 홀수 길이 사이클이 없으면 이분이다.

```javascript
function isBipartite(n, adj) {
  const color = new Array(n).fill(0);    // 0 미방문, 1/-1 두 색
  for (let s = 0; s < n; s++) {
    if (color[s]) continue;
    color[s] = 1; const q = [s]; let h = 0;
    while (h < q.length) {
      const u = q[h++];
      for (const v of adj[u]) {
        if (!color[v]) { color[v] = -color[u]; q.push(v); }
        else if (color[v] === color[u]) return false; // 같은 색 인접 → 실패
      }
    }
  }
  return true;
}
// 시간 O(V + E)
```

> 응용: 이분 매칭(작업 배정), 두 그룹 분할 가능성 판정.

---

## 5. 단절점·다리 (Articulation Point·Bridge)

**무방향 그래프**에서:
- **단절점(cut vertex)**: 제거하면 연결 요소가 늘어나는 정점.
- **다리(bridge)**: 제거하면 연결 요소가 늘어나는 간선.

DFS의 `disc`/`low`로 O(V+E)에 찾는다. 간선 `(u,v)`에서 `low[v] > disc[u]`이면 **다리**, 자식 조건이 맞으면 u가 **단절점**. 네트워크 취약점(끊기면 분리되는 지점) 분석에 쓴다.

---

## 6. 오일러 경로

모든 **간선**을 정확히 한 번씩 지나는 경로(한붓그리기). 존재 조건:
- **오일러 회로**(시작=끝): 무방향은 모든 정점의 차수가 짝수, 방향은 모든 정점의 진입=진출 차수.
- **오일러 경로**(시작≠끝): 무방향은 홀수 차수 정점이 정확히 2개.
- (연결성 전제) 히어홀저(Hierholzer) 알고리즘으로 O(E)에 구성.

> 해밀턴 경로(모든 **정점** 한 번)는 NP-난해라 혼동 주의 — 오일러는 **간선**, 다항 시간.

---

## 7. 면접 포인트

**Q. SCC(강한 연결 요소)란?**
> 방향 그래프에서 서로 양방향으로 도달 가능한 정점들의 최대 집합이다. SCC 단위로 압축하면 그래프가 DAG가 되어 위상 정렬·2-SAT 등에 활용한다. 코사라주(2 DFS)나 타잔(1 DFS)으로 O(V+E)에 구한다.

**Q. 코사라주 알고리즘의 절차는?**
> ① 원그래프 DFS로 종료 순서를 스택에 쌓고, ② 간선을 뒤집은 역그래프를 만들고, ③ 종료가 늦은 정점부터 역그래프 DFS를 돌려 한 번에 닿는 집합을 SCC로 묶는다.

**Q. 이분 그래프는 어떻게 판정하나요?**
> BFS/DFS로 인접 정점을 번갈아 두 색으로 칠하다가 같은 색 인접이 나오면 이분이 아니다. 동치로, 홀수 길이 사이클이 없으면 이분 그래프다. O(V+E).

**Q. 단절점과 다리는 무엇이고 어떻게 찾나요?**
> 제거 시 그래프가 더 쪼개지는 정점(단절점)·간선(다리)이다. DFS의 방문 순서(disc)와 low-link로 O(V+E)에 찾는다. 간선 (u,v)에서 `low[v] > disc[u]`면 다리다. 네트워크 취약점 분석에 쓴다.

**Q. 오일러 경로와 해밀턴 경로의 차이는?**
> 오일러는 모든 간선을 한 번씩(한붓그리기) — 차수 조건으로 존재를 판정하고 다항 시간에 구성한다. 해밀턴은 모든 정점을 한 번씩 — NP-난해다. "간선이냐 정점이냐"가 핵심 구분이다.
