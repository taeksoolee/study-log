# 13. 코딩 테스트 빈출 유형별 대표 문제

> [코테 가이드](./coding-test-guide.md)가 전략·자료구조라면, 이 문서는 **유형 → 신호 → 접근 → 복잡도**를 대표 문제로 연결한다. 패턴 이론은 [algorithms/patterns](../algorithms/patterns/README.md) 참고.

## 목차
1. [배열/해시 — 두 수의 합](#1-배열해시--두-수의-합)
2. [투 포인터 — 정렬된 배열의 세 수의 합](#2-투-포인터--정렬된-배열의-세-수의-합)
3. [슬라이딩 윈도우 — 최장 중복 없는 부분 문자열](#3-슬라이딩-윈도우--최장-중복-없는-부분-문자열)
4. [이진 탐색 — 매개변수 탐색](#4-이진-탐색--매개변수-탐색)
5. [BFS/DFS — 섬의 개수](#5-bfsdfs--섬의-개수)
6. [최단 경로 — 다익스트라](#6-최단-경로--다익스트라)
7. [DP — 계단/배낭](#7-dp--계단배낭)
8. [힙 — K번째 큰 수 / 머지](#8-힙--k번째-큰-수--머지)
9. [스택 — 유효한 괄호 / 모노토닉 스택](#9-스택--유효한-괄호--모노토닉-스택)
10. [유형 식별 치트시트](#10-유형-식별-치트시트)

---

## 1. 배열/해시 — 두 수의 합

**신호:** "합이 target인 두 원소", O(n) 요구.
**접근:** 해시맵에 `target - x`를 찾으며 한 번 순회.

```javascript
function twoSum(nums, target) {
  const seen = new Map();
  for (let i = 0; i < nums.length; i++) {
    if (seen.has(target - nums[i])) return [seen.get(target - nums[i]), i];
    seen.set(nums[i], i);
  }
}
// 시간 O(n), 공간 O(n). 정렬돼 있으면 투 포인터로 공간 O(1).
```

---

## 2. 투 포인터 — 정렬된 배열의 세 수의 합

**신호:** 정렬된 배열, "합이 0/target인 쌍·삼중".
**접근:** 한 원소 고정 후 나머지를 양끝 포인터로 좁힘.

```javascript
function threeSum(nums) {
  nums.sort((a, b) => a - b);
  const res = [];
  for (let i = 0; i < nums.length - 2; i++) {
    if (i > 0 && nums[i] === nums[i-1]) continue;   // 중복 스킵
    let l = i + 1, r = nums.length - 1;
    while (l < r) {
      const sum = nums[i] + nums[l] + nums[r];
      if (sum === 0) { res.push([nums[i], nums[l], nums[r]]); l++; r--;
        while (l < r && nums[l] === nums[l-1]) l++;
        while (l < r && nums[r] === nums[r+1]) r--;
      } else if (sum < 0) l++;
      else r--;
    }
  }
  return res;
}
// 정렬 O(n log n) + 이중 O(n²) = O(n²)
```

---

## 3. 슬라이딩 윈도우 — 최장 중복 없는 부분 문자열

**신호:** "연속 부분 배열/문자열의 최대/최소 길이".
**접근:** 가변 윈도우 + 집합/맵으로 조건 유지.

```javascript
function lengthOfLongest(s) {
  const last = new Map(); let start = 0, best = 0;
  for (let i = 0; i < s.length; i++) {
    if (last.has(s[i]) && last.get(s[i]) >= start) start = last.get(s[i]) + 1;
    last.set(s[i], i);
    best = Math.max(best, i - start + 1);
  }
  return best;
}
// 시간 O(n)
```

---

## 4. 이진 탐색 — 매개변수 탐색

**신호:** "최댓값을 최소화" / "K개로 나눌 때 최소 ~", 단조 결정 함수.
**접근:** 답 범위를 이진 탐색, 결정 함수로 가능 여부 판정.

```javascript
// 예: 책 M권을 K명에게 나눠줄 때 한 명이 받는 최대 페이지의 최소 (분할)
function minLargestSplit(pages, k) {
  let lo = Math.max(...pages), hi = pages.reduce((a,b)=>a+b,0);
  const canSplit = (limit) => {     // limit 이하로 k그룹에 담기는가?
    let groups = 1, cur = 0;
    for (const p of pages) {
      if (cur + p > limit) { groups++; cur = 0; }
      cur += p;
    }
    return groups <= k;
  };
  while (lo < hi) {
    const mid = lo + ((hi - lo) >> 1);
    if (canSplit(mid)) hi = mid; else lo = mid + 1;
  }
  return lo;
}
// 시간 O(n log(sum))
```

---

## 5. BFS/DFS — 섬의 개수

**신호:** 격자, "연결된 덩어리 수 / 영역 채우기".
**접근:** 미방문 1을 만날 때마다 카운트 + 인접 1을 모두 방문 처리(flood fill).

```javascript
function numIslands(grid) {
  const R = grid.length, C = grid[0].length; let count = 0;
  const DIR = [[1,0],[-1,0],[0,1],[0,-1]];
  const bfs = (sr, sc) => {
    const q = [[sr, sc]]; grid[sr][sc] = '0'; let h = 0;
    while (h < q.length) {
      const [r, c] = q[h++];
      for (const [dr, dc] of DIR) {
        const nr = r+dr, nc = c+dc;
        if (nr>=0&&nr<R&&nc>=0&&nc<C&&grid[nr][nc]==='1') { grid[nr][nc]='0'; q.push([nr,nc]); }
      }
    }
  };
  for (let r=0;r<R;r++) for (let c=0;c<C;c++) if (grid[r][c]==='1') { count++; bfs(r,c); }
  return count;
}
// 시간 O(R·C)
```

---

## 6. 최단 경로 — 다익스트라

**신호:** 가중 그래프, "최소 비용/시간 경로". → [패턴 14](../algorithms/patterns/14-shortest-path.md)
**접근:** 최소 힙으로 가장 가까운 정점부터 확정. 음수 간선이면 벨만-포드.

핵심 골격(우선순위 큐 + 완화)은 패턴 문서의 구현을 그대로 적용한다. 신호 식별이 핵심: "각 칸 이동 비용이 다름", "환승 비용" 등이면 다익스트라.

---

## 7. DP — 계단/배낭

**신호:** "경우의 수", "최대/최소 가치", 부분 문제가 겹침(최적 부분 구조).
**접근:** 상태 정의 → 점화식 → 베이스 케이스.

```javascript
// 0/1 배낭: 무게 W 한도에서 가치 최대
function knapsack(weights, values, W) {
  const dp = new Array(W + 1).fill(0);
  for (let i = 0; i < weights.length; i++)
    for (let w = W; w >= weights[i]; w--)        // 1D는 역순(각 물건 1회)
      dp[w] = Math.max(dp[w], dp[w - weights[i]] + values[i]);
  return dp[W];
}
// 시간 O(n·W)
```

> 1D 배낭에서 **w를 역순**으로 도는 이유: 정순이면 같은 물건을 여러 번 담는 무한 배낭이 된다.

---

## 8. 힙 — K번째 큰 수 / 머지

**신호:** "상위 K개", "스트림에서 K번째", "여러 정렬 리스트 병합".
**접근:** 크기 K 최소 힙 유지(상위 K), 또는 멀티웨이 머지. JS는 힙이 없어 직접 구현([코테 가이드 §4](./coding-test-guide.md#4-직접-구현-최소-힙--우선순위-큐)).

```javascript
// K번째 큰 수: 크기 K 최소 힙 — 힙 꼭대기가 답
function kthLargest(nums, k) {
  const h = new MinHeap();
  for (const x of nums) { h.push(x); if (h.size() > k) h.pop(); }
  return h.peek();
}
// 시간 O(n log k)
```

---

## 9. 스택 — 유효한 괄호 / 모노토닉 스택

**신호:** "짝 맞추기", "다음 큰 원소(next greater)", "최근 것부터 처리".
**접근:** 괄호는 매칭 스택, "다음 큰 수"는 단조 스택.

```javascript
// 다음 큰 원소: 각 원소의 오른쪽 첫 번째 더 큰 값
function nextGreater(nums) {
  const res = new Array(nums.length).fill(-1), st = []; // 인덱스 단조 감소 스택
  for (let i = 0; i < nums.length; i++) {
    while (st.length && nums[st[st.length-1]] < nums[i]) res[st.pop()] = nums[i];
    st.push(i);
  }
  return res;
}
// 시간 O(n) — 각 인덱스 push/pop 1회
```

---

## 10. 유형 식별 치트시트

| 문제 속 신호 | 유형 |
|------------|------|
| 합/존재 여부 O(n) | 해시맵 |
| 정렬된 배열의 쌍/삼중 | 투 포인터 |
| 연속 구간 최대/최소 길이 | 슬라이딩 윈도우 |
| 정렬+값/경계 찾기, "최대를 최소화" | 이진 탐색 / 매개변수 탐색 |
| 격자 연결 덩어리·최단 칸 이동 | BFS/DFS |
| 가중 그래프 최소 비용 | 다익스트라/벨만포드 |
| 경우의 수·최적 가치, 겹치는 부분문제 | DP |
| 상위 K·스트림 K번째·다중 병합 | 힙 |
| 짝 맞추기·다음 큰 원소 | 스택/단조 스택 |
| 그룹 연결성·사이클(무방향) | 유니온 파인드 |
| 선후 관계·의존성 순서 | 위상 정렬 |
| 부분집합 상태(N≤20) | 비트마스크 DP |
| 문자열 패턴 매칭 | KMP/라빈카프 |

> 면접/코테 첫 30초: **제약(N) + 자료의 정렬 여부 + 묻는 것(최대/개수/존재/경로)** 세 가지로 유형을 좁힌다.
