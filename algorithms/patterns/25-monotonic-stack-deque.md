# 25. 모노토닉 스택 / 덱 (Monotonic Stack/Deque)

> 🎨 **인터랙티브 시각화: [히스토그램 최대 직사각형](./visualizer/14-histogram-stack.html) · [슬라이딩 윈도우 최댓값](./visualizer/18-deque-window-max.html)** — 스택/덱 동작을 확인하세요.

## 목차
1. [모노토닉 스택이란](#1-모노토닉-스택이란)
2. [다음 큰 원소 (Next Greater Element)](#2-다음-큰-원소-next-greater-element)
3. [히스토그램에서 최대 직사각형](#3-히스토그램에서-최대-직사각형)
4. [모노토닉 덱 — 슬라이딩 윈도우 최댓값](#4-모노토닉-덱--슬라이딩-윈도우-최댓값)
5. [빗물 가두기](#5-빗물-가두기)
6. [패턴 식별](#6-패턴-식별)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 모노토닉 스택이란

원소가 **단조(증가 또는 감소) 순서를 유지하도록** 관리하는 스택. 새 원소가 단조성을 깨면 어긋나는 원소들을 pop한다. "각 원소의 다음/이전 더 큰(작은) 원소"를 **전체 O(n)**에 찾는 것이 핵심 효과(각 원소가 한 번 push·pop).

```javascript
// 단조 감소 스택 골격 (다음 큰 원소용)
for (let i = 0; i < n; i++) {
  while (st.length && a[st.at(-1)] < a[i]) {
    const idx = st.pop();   // a[idx]의 "다음 큰 원소"가 a[i]
  }
  st.push(i);
}
```

---

## 2. 다음 큰 원소 (Next Greater Element)

각 원소의 오른쪽에서 처음으로 더 큰 값. 인덱스를 단조 감소 스택으로 관리.

```javascript
function nextGreater(a) {
  const res = new Array(a.length).fill(-1), st = [];
  for (let i = 0; i < a.length; i++) {
    while (st.length && a[st.at(-1)] < a[i]) res[st.pop()] = a[i];
    st.push(i);
  }
  return res;            // 남은 인덱스는 -1 (오른쪽에 더 큰 값 없음)
}
// O(n)
```

> 변형: 이전 큰 원소(왼→오 방향 바꾸기), 다음 작은 원소(부등호 반전), 원형 배열(인덱스를 2n까지 `i % n`).

---

## 3. 히스토그램에서 최대 직사각형

막대 높이 배열에서 만들 수 있는 최대 직사각형 넓이. 각 막대를 높이로 하는 직사각형의 좌우 경계를 모노토닉 스택으로 찾는다.

```javascript
function largestRectangle(heights) {
  const st = [], h = [...heights, 0];   // 끝에 0 추가로 스택 비우기
  let max = 0;
  for (let i = 0; i < h.length; i++) {
    while (st.length && h[st.at(-1)] >= h[i]) {
      const height = h[st.pop()];
      const width = st.length ? i - st.at(-1) - 1 : i; // 좌우 경계 폭
      max = Math.max(max, height * width);
    }
    st.push(i);
  }
  return max;
}
// O(n) — "최대 직사각형(2D 0/1 행렬)"도 행마다 이 함수로 O(R·C)
```

> 핵심: pop되는 막대는 "현재 막대가 그보다 낮아 더 못 뻗는다"는 신호 → 그 막대 기준 직사각형을 확정.

---

## 4. 모노토닉 덱 — 슬라이딩 윈도우 최댓값

크기 k 윈도우의 최댓값을 매번 O(1)에. 덱에 **인덱스를 값 내림차순으로** 유지(앞이 최댓값).

```javascript
function maxSlidingWindow(nums, k) {
  const dq = [], res = [];               // dq: 인덱스, nums 내림차순
  for (let i = 0; i < nums.length; i++) {
    if (dq.length && dq[0] <= i - k) dq.shift();        // 윈도우 벗어난 앞 제거
    while (dq.length && nums[dq.at(-1)] <= nums[i]) dq.pop(); // 작은 뒤 제거
    dq.push(i);
    if (i >= k - 1) res.push(nums[dq[0]]);              // 앞 = 현재 최댓값
  }
  return res;
}
// O(n) — 각 인덱스 한 번 push/pop
```

> 슬라이딩 윈도우([패턴 02](./02-sliding-window.md))가 합/개수라면, 최댓값/최솟값은 모노토닉 덱이 필요하다(힙은 O(n log k), 덱은 O(n)).

---

## 5. 빗물 가두기

높이 막대 사이에 고이는 물의 양. 모노토닉 스택(또는 양끝 투포인터)으로 O(n).

```javascript
function trap(height) {
  const st = []; let water = 0;
  for (let i = 0; i < height.length; i++) {
    while (st.length && height[st.at(-1)] < height[i]) {
      const bottom = st.pop();
      if (!st.length) break;
      const left = st.at(-1);
      const w = i - left - 1;
      const h = Math.min(height[left], height[i]) - height[bottom];
      water += w * h;                    // 가로 구간 × 고임 높이
    }
    st.push(i);
  }
  return water;
}
// O(n)
```

---

## 6. 패턴 식별

| 신호 | 도구 |
|------|------|
| 다음/이전 더 큰(작은) 원소 | 모노토닉 스택 |
| 히스토그램 최대 직사각형 | 모노토닉 스택 |
| 빗물 가두기 | 모노토닉 스택 / 투포인터 |
| 고정 크기 윈도우 최대/최소 | 모노토닉 덱 |
| "주식 스팬", 온도 대기 일수 | 모노토닉 스택 |

> 공통 신호: "각 원소에 대해 한쪽 방향으로 조건을 만족하는 가장 가까운 원소"를 묻는다.

---

## 7. 면접 포인트

**Q. 모노토닉 스택이 O(n)인 이유는?**
> 각 원소가 스택에 정확히 한 번 push되고 최대 한 번 pop되기 때문이다. 이중 루프처럼 보여도 전체 pop 횟수가 n을 넘지 않아 amortized O(n)이다.

**Q. 다음 큰 원소를 어떻게 구하나요?**
> 인덱스를 단조 감소 스택으로 관리하다가, 현재 원소가 스택 top보다 크면 그 top의 "다음 큰 원소"가 현재 원소다(pop하며 기록). 남은 인덱스는 오른쪽에 더 큰 값이 없는 것이다.

**Q. 슬라이딩 윈도우 최댓값에 힙 대신 덱을 쓰는 이유는?**
> 덱에 인덱스를 값 내림차순으로 유지하면 앞이 항상 윈도우 최댓값이라 O(1) 조회, 전체 O(n)이다. 힙은 O(n log k)이고 윈도우를 벗어난 원소 제거가 번거롭다.

**Q. 히스토그램 최대 직사각형의 아이디어는?**
> 막대 높이가 증가하는 동안 스택에 쌓고, 더 낮은 막대를 만나면 스택에서 막대를 pop하며 "그 막대를 높이로 하는 직사각형"의 넓이를 확정한다(폭은 좌우 경계). 끝에 0을 붙여 스택을 모두 비운다. O(n).

**Q. 모노토닉 스택 문제의 공통 신호는?**
> "각 원소에 대해 한 방향에서 조건(더 큼/작음)을 만족하는 가장 가까운 원소"를 묻는 문제다. 다음 큰 원소, 주식 스팬, 일일 온도, 히스토그램, 빗물 가두기가 대표 예다.
