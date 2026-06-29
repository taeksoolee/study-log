# 12. 유니온 파인드 (Union-Find / Disjoint Set)

> 🎨 **[인터랙티브 시각화](./visualizer/09-union-find.html)** — union/find와 경로 압축을 포레스트로 확인하세요.

## 목차
1. [개념: 서로소 집합](#1-개념-서로소-집합)
2. [기본 구현 (find / union)](#2-기본-구현-find--union)
3. [최적화 1: 경로 압축](#3-최적화-1-경로-압축-path-compression)
4. [최적화 2: 랭크/크기 기준 합치기](#4-최적화-2-랭크크기-기준-합치기-union-by-ranksize)
5. [응용: 사이클 탐지 · 연결 요소 · MST](#5-응용-사이클-탐지--연결-요소--mst)
6. [시간복잡도](#6-시간복잡도)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 개념: 서로소 집합

유니온 파인드는 **서로 겹치지 않는 집합(disjoint set)들**을 관리하며 두 연산을 빠르게 한다.

- **find(x)**: x가 속한 집합의 대표(루트)를 찾는다.
- **union(a, b)**: a와 b가 속한 두 집합을 하나로 합친다.

"두 원소가 같은 그룹인가?"(`find(a) === find(b)`)를 거의 O(1)에 답한다. 그래프 연결성, 사이클 탐지, 크루스칼 MST의 핵심 자료구조.

---

## 2. 기본 구현 (find / union)

각 원소가 부모를 가리키는 `parent` 배열로 트리 숲(forest)을 만든다. 루트는 자기 자신을 가리킨다.

```javascript
class DSU {
  constructor(n) {
    this.parent = Array.from({length: n}, (_, i) => i); // 처음엔 각자 독립
  }
  find(x) {
    while (this.parent[x] !== x) x = this.parent[x]; // 루트까지 따라 올라감
    return x;
  }
  union(a, b) {
    const ra = this.find(a), rb = this.find(b);
    if (ra === rb) return false;   // 이미 같은 집합 (→ 사이클 신호)
    this.parent[rb] = ra;          // 한쪽 루트를 다른 루트 밑에
    return true;
  }
  connected(a, b) { return this.find(a) === this.find(b); }
}
```

> 최적화 없는 순수 버전은 트리가 한쪽으로 길어지면 find가 O(n)까지 나빠진다. 그래서 아래 두 최적화를 거의 항상 함께 쓴다.

---

## 3. 최적화 1: 경로 압축 (Path Compression)

find 도중 거쳐간 노드들을 **루트에 직접 연결**해 트리를 납작하게 만든다.

```javascript
find(x) {
  if (this.parent[x] !== x) {
    this.parent[x] = this.find(this.parent[x]); // 결과를 부모로 갱신
  }
  return this.parent[x];
}
```

이후 같은 원소의 find는 한두 번 점프로 끝난다. 트리 높이가 점점 1에 수렴.

---

## 4. 최적화 2: 랭크/크기 기준 합치기 (Union by Rank/Size)

union 시 **작은 트리를 큰 트리 밑에** 붙여 높이 증가를 막는다.

```javascript
class DSU {
  constructor(n) {
    this.parent = Array.from({length: n}, (_, i) => i);
    this.size = new Array(n).fill(1);   // 각 집합의 원소 수
  }
  find(x) {
    while (this.parent[x] !== x) {
      this.parent[x] = this.parent[this.parent[x]]; // 경로 절반 압축
      x = this.parent[x];
    }
    return x;
  }
  union(a, b) {
    let ra = this.find(a), rb = this.find(b);
    if (ra === rb) return false;
    if (this.size[ra] < this.size[rb]) [ra, rb] = [rb, ra]; // 큰 쪽이 루트
    this.parent[rb] = ra;
    this.size[ra] += this.size[rb];
    return true;
  }
}
```

> 경로 압축 + 랭크/크기 합치기를 **둘 다** 적용하면 연산당 평균 거의 상수 시간이 된다.

---

## 5. 응용: 사이클 탐지 · 연결 요소 · MST

### 무방향 그래프 사이클 탐지
간선 `(a,b)`를 union할 때 이미 `find(a)===find(b)`면 이 간선이 사이클을 만든다.

```javascript
function hasCycle(n, edges) {
  const dsu = new DSU(n);
  for (const [a, b] of edges) {
    if (!dsu.union(a, b)) return true; // 합치기 실패 = 이미 연결됨 = 사이클
  }
  return false;
}
```

### 연결 요소 개수
모든 간선을 union한 뒤 서로 다른 루트의 수를 센다.

### 크루스칼 MST
간선을 가중치 오름차순 정렬 → 사이클을 만들지 않는 간선만 union으로 채택. 유니온 파인드가 사이클 판정을 맡는다.

---

## 6. 시간복잡도

| 구현 | find/union |
|------|-----------|
| 순수 | O(n) 최악 |
| 경로 압축 + 랭크 합치기 | **O(α(n))** ≈ 상수 |

α(n)은 **역 애커만 함수**로, 현실의 모든 n에서 4 이하다. 사실상 상수로 취급한다.

---

## 7. 면접 포인트

**Q. 유니온 파인드는 어떤 문제에 쓰나요?**
> 동적으로 합쳐지는 서로소 집합의 연결성 질의. "두 노드가 같은 그룹인가", 무방향 그래프 사이클 탐지, 연결 요소 개수, 크루스칼 MST 등에 쓴다.

**Q. 두 가지 핵심 최적화는?**
> ① 경로 압축: find 중 거친 노드를 루트에 직접 연결해 트리를 납작하게 한다. ② 랭크/크기 기준 합치기: 작은 트리를 큰 트리 밑에 붙여 높이 증가를 막는다. 둘을 함께 쓰면 연산당 평균 거의 상수(O(α(n)))다.

**Q. α(n)(역 애커만)이 상수로 취급되는 이유는?**
> 역 애커만 함수는 극도로 느리게 증가해 우주의 원자 수 규모의 n에서도 5를 넘지 않는다. 따라서 실무·코테에서는 사실상 O(1)로 본다.

**Q. 유니온 파인드로 무방향 그래프 사이클을 어떻게 찾나요?**
> 각 간선 (a,b)를 union하기 전에 `find(a)===find(b)`인지 본다. 이미 같은 집합인데 또 간선이 들어오면 그 간선이 사이클을 형성한다. union이 "이미 연결됨"으로 실패하는 순간이 사이클이다.

**Q. DFS 사이클 탐지 대신 유니온 파인드를 쓰는 경우는?**
> 간선이 스트리밍처럼 점진적으로 추가되며 그때마다 연결성/사이클을 물어야 할 때(동적). DFS는 그래프가 고정된 상태에서 한 번 훑는 데 적합하다. 크루스칼처럼 간선을 하나씩 채택하는 과정에도 유니온 파인드가 맞다.
