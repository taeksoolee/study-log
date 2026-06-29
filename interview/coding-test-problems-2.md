# 17. 코딩 테스트 고급 대표 문제

> [기본 대표문제](./coding-test-problems.md)의 후속. MST·SCC·고급 DP·정수론 등 [고급 패턴](../algorithms/patterns/README.md)을 실전 문제로 연결한다.

## 목차
1. [설계 — LRU 캐시](#1-설계--lru-캐시)
2. [MST — 네트워크 연결 최소 비용](#2-mst--네트워크-연결-최소-비용)
3. [고급 DP — 편집 거리](#3-고급-dp--편집-거리)
4. [고급 DP — 동전 교환(최소 개수)](#4-고급-dp--동전-교환최소-개수)
5. [그래프 — 코스 스케줄 II (위상 정렬)](#5-그래프--코스-스케줄-ii-위상-정렬)
6. [힙 — 중앙값 스트림](#6-힙--중앙값-스트림)
7. [정수론 — 모듈러 거듭제곱](#7-정수론--모듈러-거듭제곱)
8. [구간 — 회의실 배정(스위프)](#8-구간--회의실-배정스위프)
9. [고급 유형 식별 치트시트](#9-고급-유형-식별-치트시트)

---

## 1. 설계 — LRU 캐시

**신호:** "고정 용량 + 가장 오래 안 쓴 것 제거", get/put O(1).
**접근:** 해시맵(키→노드) + 이중 연결 리스트(최근 순). JS는 **`Map`이 삽입 순서를 보존**해 더 간단.

```javascript
class LRUCache {
  constructor(capacity) { this.cap = capacity; this.map = new Map(); }
  get(key) {
    if (!this.map.has(key)) return -1;
    const val = this.map.get(key);
    this.map.delete(key); this.map.set(key, val); // 최근 사용으로 이동(맨 뒤)
    return val;
  }
  put(key, val) {
    if (this.map.has(key)) this.map.delete(key);
    else if (this.map.size >= this.cap)
      this.map.delete(this.map.keys().next().value); // 가장 오래된 것(맨 앞) 제거
    this.map.set(key, val);
  }
}
// get/put O(1)
```

---

## 2. MST — 네트워크 연결 최소 비용

**신호:** "모든 노드를 최소 비용으로 연결".
**접근:** 크루스칼([패턴 19](../algorithms/patterns/19-mst.md)) — 간선 정렬 + 유니온 파인드.

```javascript
function minCostConnect(n, connections) {  // [u, v, cost]
  connections.sort((a, b) => a[2] - b[2]);
  const dsu = new DSU(n);
  let cost = 0, used = 0;
  for (const [u, v, w] of connections) {
    if (dsu.union(u, v)) { cost += w; used++; }
  }
  return used === n - 1 ? cost : -1;        // 다 연결 못 하면 -1
}
```

---

## 3. 고급 DP — 편집 거리

**신호:** "한 문자열을 다른 것으로 바꾸는 최소 연산", "유사도".
**접근:** 2D DP([패턴 20 §4](../algorithms/patterns/20-advanced-dp.md)). 삽입·삭제·교체.

```javascript
function minDistance(a, b) {
  const m = a.length, n = b.length;
  const dp = Array.from({length: m+1}, (_, i) => [i, ...Array(n).fill(0)]);
  for (let j = 0; j <= n; j++) dp[0][j] = j;
  for (let i = 1; i <= m; i++)
    for (let j = 1; j <= n; j++)
      dp[i][j] = a[i-1] === b[j-1] ? dp[i-1][j-1]
        : 1 + Math.min(dp[i-1][j], dp[i][j-1], dp[i-1][j-1]);
  return dp[m][n];
}
```

---

## 4. 고급 DP — 동전 교환(최소 개수)

**신호:** "금액을 만드는 최소 동전 수"(무한 개수).
**접근:** 1D DP, 각 동전을 정순으로(무한 배낭).

```javascript
function coinChange(coins, amount) {
  const dp = new Array(amount + 1).fill(Infinity);
  dp[0] = 0;
  for (const c of coins)
    for (let x = c; x <= amount; x++)          // 정순 = 동전 재사용 허용
      dp[x] = Math.min(dp[x], dp[x - c] + 1);
  return dp[amount] === Infinity ? -1 : dp[amount];
}
// O(amount × coins)
```

> [배낭 §7](./coding-test-problems.md)의 0/1 배낭은 **역순**(1회), 동전(무한)은 **정순**. 이 방향 차이가 핵심.

---

## 5. 그래프 — 코스 스케줄 II (위상 정렬)

**신호:** "선수과목/의존성을 만족하는 순서".
**접근:** Kahn 위상 정렬([패턴 13](../algorithms/patterns/13-topological-sort.md)). 사이클이면 불가능.

```javascript
function findOrder(numCourses, prerequisites) {
  const adj = Array.from({length: numCourses}, () => []);
  const indeg = new Array(numCourses).fill(0);
  for (const [c, pre] of prerequisites) { adj[pre].push(c); indeg[c]++; }
  const q = []; for (let i = 0; i < numCourses; i++) if (!indeg[i]) q.push(i);
  const order = []; let h = 0;
  while (h < q.length) {
    const u = q[h++]; order.push(u);
    for (const v of adj[u]) if (--indeg[v] === 0) q.push(v);
  }
  return order.length === numCourses ? order : []; // 사이클이면 빈 배열
}
```

---

## 6. 힙 — 중앙값 스트림

**신호:** "스트림에서 실시간 중앙값".
**접근:** 두 힙 — 최대 힙(작은 절반) + 최소 힙(큰 절반)을 균형 유지.

```javascript
class MedianFinder {
  constructor() { this.lo = new MaxHeap(); this.hi = new MinHeap(); } // lo≤hi
  addNum(x) {
    this.lo.push(x);
    this.hi.push(this.lo.pop());               // lo 최대를 hi로 (정렬 보장)
    if (this.hi.size() > this.lo.size()) this.lo.push(this.hi.pop()); // 균형
  }
  findMedian() {
    return this.lo.size() > this.hi.size()
      ? this.lo.peek()
      : (this.lo.peek() + this.hi.peek()) / 2;
  }
}
// add O(log n), find O(1)
```

---

## 7. 정수론 — 모듈러 거듭제곱

**신호:** "a^b mod m"(큰 지수), 경우의 수 mod 1e9+7.
**접근:** 빠른 거듭제곱([패턴 22 §5](../algorithms/patterns/22-number-theory.md)).

```javascript
function modPow(a, b, m) {
  a = BigInt(a) % BigInt(m); b = BigInt(b); const M = BigInt(m);
  let r = 1n;
  while (b > 0n) { if (b & 1n) r = r * a % M; a = a * a % M; b >>= 1n; }
  return r;
}
// O(log b)
```

---

## 8. 구간 — 회의실 배정(스위프)

**신호:** "겹치는 구간 최대 동시 수", "필요한 회의실 수".
**접근:** 시작·종료를 분리해 정렬 후 스위프(시작 +1, 종료 -1의 최대 동시값).

```javascript
function minMeetingRooms(intervals) {
  const starts = intervals.map(i => i[0]).sort((a,b)=>a-b);
  const ends   = intervals.map(i => i[1]).sort((a,b)=>a-b);
  let rooms = 0, max = 0, e = 0;
  for (let s = 0; s < starts.length; s++) {
    while (e < ends.length && ends[e] <= starts[s]) { rooms--; e++; } // 끝난 회의 비움
    rooms++; max = Math.max(max, rooms);
  }
  return max;
}
// O(n log n)
```

---

## 9. 고급 유형 식별 치트시트

| 신호 | 유형/패턴 |
|------|----------|
| 고정 용량 + 최근성 제거, O(1) 접근 | LRU(해시+이중연결리스트/Map) |
| 모든 노드 최소 비용 연결 | MST(크루스칼/프림) |
| 두 문자열 변환·유사도 | 편집 거리/LCS DP |
| 금액·합을 만드는 최소/경우의 수 | 배낭/동전 DP |
| 선후 관계 순서·의존성 | 위상 정렬 |
| 실시간 중앙값/상위 K | 두 힙 / 힙 |
| 큰 지수 mod, 경우의 수 mod | 모듈러 거듭제곱 |
| 겹치는 구간 최대 동시 수 | 스위프 라인 |
| 방향 그래프 강결합 묶음 | SCC |
| 부분집합 상태(N≤20) | 비트마스크 DP |

> 고급 문제일수록 **자료구조 조합**(해시+리스트, 두 힙, 정렬+스위프)이 답인 경우가 많다. "어떤 연산을 O(1)/O(log n)으로 만들어야 하나"를 먼저 묻자.
