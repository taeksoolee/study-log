# 19. 코딩 테스트 대표 문제 3탄 (기하·문자열·덱·그리디)

> [1탄](./coding-test-problems.md)·[2탄](./coding-test-problems-2.md)에 이어, [기하](../algorithms/patterns/23-geometry.md)·[고급 문자열](../algorithms/patterns/24-advanced-string.md)·[모노토닉 덱](../algorithms/patterns/25-monotonic-stack-deque.md)·[고급 그리디](../algorithms/patterns/26-advanced-greedy.md)를 실전 문제로.

## 목차
1. [기하 — 선분 교차 / 다각형 넓이](#1-기하--선분-교차--다각형-넓이)
2. [스택 — 일일 온도](#2-스택--일일-온도)
3. [스택 — 히스토그램 최대 직사각형](#3-스택--히스토그램-최대-직사각형)
4. [덱 — 슬라이딩 윈도우 최댓값](#4-덱--슬라이딩-윈도우-최댓값)
5. [그리디 — 점프 게임](#5-그리디--점프-게임)
6. [그리디 — 주유소(가스 스테이션)](#6-그리디--주유소가스-스테이션)
7. [문자열 — 최장 회문 부분 문자열](#7-문자열--최장-회문-부분-문자열)
8. [구간 — 겹치는 구간 병합](#8-구간--겹치는-구간-병합)
9. [유형 식별 치트시트](#9-유형-식별-치트시트)

---

## 1. 기하 — 선분 교차 / 다각형 넓이

**접근:** CCW로 방향 판정([패턴 23](../algorithms/patterns/23-geometry.md)).

```javascript
const ccw = (a,b,c) => (b[0]-a[0])*(c[1]-a[1]) - (b[1]-a[1])*(c[0]-a[0]);
function cross(a, b, c, d) {           // AB와 CD 교차?
  const d1 = Math.sign(ccw(a,b,c)) * Math.sign(ccw(a,b,d));
  const d2 = Math.sign(ccw(c,d,a)) * Math.sign(ccw(c,d,b));
  return d1 <= 0 && d2 <= 0;           // (공선 케이스는 별도 처리)
}
```

---

## 2. 스택 — 일일 온도

**신호:** "각 날의 다음 더 따뜻한 날까지 며칠?" → 다음 큰 원소.

```javascript
function dailyTemperatures(t) {
  const res = new Array(t.length).fill(0), st = []; // 인덱스, 단조 감소
  for (let i = 0; i < t.length; i++) {
    while (st.length && t[st.at(-1)] < t[i]) {
      const j = st.pop();
      res[j] = i - j;                  // 며칠 후
    }
    st.push(i);
  }
  return res;
}
// O(n)
```

---

## 3. 스택 — 히스토그램 최대 직사각형

**접근:** 모노토닉 스택([패턴 25 §3](../algorithms/patterns/25-monotonic-stack-deque.md)).

```javascript
function largestRectangle(h) {
  const a = [...h, 0], st = []; let max = 0;
  for (let i = 0; i < a.length; i++) {
    while (st.length && a[st.at(-1)] >= a[i]) {
      const height = a[st.pop()];
      const width = st.length ? i - st.at(-1) - 1 : i;
      max = Math.max(max, height * width);
    }
    st.push(i);
  }
  return max;
}
```

---

## 4. 덱 — 슬라이딩 윈도우 최댓값

**접근:** 모노토닉 덱([패턴 25 §4](../algorithms/patterns/25-monotonic-stack-deque.md)).

```javascript
function maxSlidingWindow(nums, k) {
  const dq = [], res = [];
  for (let i = 0; i < nums.length; i++) {
    if (dq.length && dq[0] <= i - k) dq.shift();
    while (dq.length && nums[dq.at(-1)] <= nums[i]) dq.pop();
    dq.push(i);
    if (i >= k - 1) res.push(nums[dq[0]]);
  }
  return res;
}
// O(n)
```

---

## 5. 그리디 — 점프 게임

**신호:** "각 칸의 점프 거리로 끝에 도달 가능?" → 현재 도달 가능한 최대 위치를 그리디로 갱신.

```javascript
function canJump(nums) {
  let reach = 0;
  for (let i = 0; i < nums.length; i++) {
    if (i > reach) return false;       // 못 닿는 칸
    reach = Math.max(reach, i + nums[i]);
  }
  return true;
}
// O(n). 최소 점프 횟수는 BFS식 그리디(구간 끝마다 점프)로 O(n)
```

---

## 6. 그리디 — 주유소(가스 스테이션)

**신호:** "원형 경로 한 바퀴 가능한 시작점?" → 총합 ≥ 0이면 가능, 시작점은 누적이 음수가 되는 지점 다음.

```javascript
function canCompleteCircuit(gas, cost) {
  let total = 0, tank = 0, start = 0;
  for (let i = 0; i < gas.length; i++) {
    const diff = gas[i] - cost[i];
    total += diff; tank += diff;
    if (tank < 0) { start = i + 1; tank = 0; } // 여기까진 시작점 불가 → 다음부터
  }
  return total >= 0 ? start : -1;
}
// O(n)
```

> 그리디 정당성: tank가 음수가 되면 그 구간 내 어떤 점도 시작점이 될 수 없다(교환 논증).

---

## 7. 문자열 — 최장 회문 부분 문자열

**접근:** 중심 확장([패턴 24 §5](../algorithms/patterns/24-advanced-string.md)).

```javascript
function longestPalindrome(s) {
  let best = '';
  const expand = (l, r) => { while (l >= 0 && r < s.length && s[l] === s[r]) { l--; r++; } return s.slice(l+1, r); };
  for (let i = 0; i < s.length; i++)
    for (const p of [expand(i, i), expand(i, i+1)])
      if (p.length > best.length) best = p;
  return best;
}
// O(n²) (Manacher면 O(n))
```

---

## 8. 구간 — 겹치는 구간 병합

**신호:** "겹치는 구간들을 합쳐라". → 시작 기준 정렬 후 순회하며 병합.

```javascript
function merge(intervals) {
  intervals.sort((a, b) => a[0] - b[0]);
  const res = [intervals[0]];
  for (let i = 1; i < intervals.length; i++) {
    const last = res[res.length - 1];
    if (intervals[i][0] <= last[1]) last[1] = Math.max(last[1], intervals[i][1]); // 겹침→확장
    else res.push(intervals[i]);
  }
  return res;
}
// O(n log n)
```

---

## 9. 유형 식별 치트시트

| 신호 | 유형 |
|------|------|
| 점/선분/다각형 위치·교차 | 기하(CCW) |
| 각 원소의 다음 더 큰/작은 | 모노토닉 스택 |
| 막대 최대 직사각형 | 모노토닉 스택 |
| 고정 윈도우 최대/최소 | 모노토닉 덱 |
| 끝 도달 가능/최소 점프 | 그리디(도달 범위) |
| 원형 경로 시작점 | 그리디(누적합) |
| 최장 회문 | 중심 확장 / Manacher |
| 구간 병합/겹침 | 정렬 + 스위프 |

> 정렬이 보이면 그리디·투포인터·스위프를, "다음/이전 가까운 큰 값"이 보이면 모노토닉 스택을, "윈도우 최대/최소"가 보이면 덱을 떠올린다.
