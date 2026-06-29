# 20. 고급 DP (LIS · LCS · 편집거리 · 구간 DP)

> [기본 DP](./04-dynamic-programming.md)의 상태/점화식 위에서, 코테 빈출 고급 유형을 정리한다.

> 🎨 **인터랙티브 시각화: [LIS](./visualizer/15-lis.html) · [LCS DP 테이블](./visualizer/21-lcs-dp.html)** — tails 교체와 DP 표 채우기를 확인하세요.

## 목차
1. [DP 설계 체크리스트](#1-dp-설계-체크리스트)
2. [LIS — 최장 증가 부분 수열](#2-lis--최장-증가-부분-수열)
3. [LCS — 최장 공통 부분 수열](#3-lcs--최장-공통-부분-수열)
4. [편집 거리 (Edit Distance)](#4-편집-거리-edit-distance)
5. [구간 DP (Interval DP)](#5-구간-dp-interval-dp)
6. [DP 최적화 개요](#6-dp-최적화-개요)
7. [면접 포인트](#7-면접-포인트)

---

## 1. DP 설계 체크리스트

1. **상태 정의**: `dp[i]` / `dp[i][j]`가 "무엇의 최적값"인지 한 문장으로.
2. **점화식**: 현재 상태를 이전 상태로 표현(최적 부분 구조).
3. **베이스 케이스 / 순서**: 작은 상태부터 채울 순서.
4. **답의 위치**: `dp[n]`? `max(dp)`?
5. **차원 줄이기**: 직전 행만 쓰면 2D→1D로 공간 절감.

> "겹치는 부분 문제 + 최적 부분 구조"가 보이면 DP. 완전탐색의 중복 계산을 메모이제이션으로 제거하는 것이 본질.

---

## 2. LIS — 최장 증가 부분 수열

**O(n²) DP:** `dp[i]` = i로 끝나는 LIS 길이.

```javascript
function lisN2(a) {
  const dp = new Array(a.length).fill(1);
  for (let i = 0; i < a.length; i++)
    for (let j = 0; j < i; j++)
      if (a[j] < a[i]) dp[i] = Math.max(dp[i], dp[j] + 1);
  return Math.max(...dp);
}
```

**O(n log n):** "각 길이의 LIS 마지막 원소 최소값" 배열 `tails`를 이진 탐색으로 유지.

```javascript
function lisNlogN(a) {
  const tails = [];
  for (const x of a) {
    let lo = 0, hi = tails.length;
    while (lo < hi) { const m = (lo+hi)>>1; if (tails[m] < x) lo = m+1; else hi = m; }
    tails[lo] = x;                 // lower bound 위치에 교체/추가
  }
  return tails.length;             // tails는 실제 수열이 아니라 길이만 정확
}
```

> `tails`는 LIS 자체가 아니라 **길이**만 정확하다(역추적하려면 인덱스를 따로 기록).

---

## 3. LCS — 최장 공통 부분 수열

두 문자열의 공통 부분 수열(연속일 필요 X) 최대 길이. `dp[i][j]` = `A[0..i)`와 `B[0..j)`의 LCS.

```javascript
function lcs(A, B) {
  const m = A.length, n = B.length;
  const dp = Array.from({length: m+1}, () => new Array(n+1).fill(0));
  for (let i = 1; i <= m; i++)
    for (let j = 1; j <= n; j++)
      dp[i][j] = A[i-1] === B[j-1]
        ? dp[i-1][j-1] + 1                       // 글자 일치 → 대각 +1
        : Math.max(dp[i-1][j], dp[i][j-1]);      // 불일치 → 한쪽 버림
  return dp[m][n];
}
// 시간·공간 O(m·n) (한 행만 쓰면 공간 O(n))
```

---

## 4. 편집 거리 (Edit Distance)

A를 B로 바꾸는 최소 연산(삽입·삭제·교체). 맞춤법·DNA 정렬·diff의 기반.

```javascript
function editDistance(A, B) {
  const m = A.length, n = B.length;
  const dp = Array.from({length: m+1}, (_, i) => [i, ...new Array(n).fill(0)]);
  for (let j = 0; j <= n; j++) dp[0][j] = j;     // 베이스: 빈 문자열 → j개 삽입
  for (let i = 1; i <= m; i++)
    for (let j = 1; j <= n; j++)
      dp[i][j] = A[i-1] === B[j-1]
        ? dp[i-1][j-1]
        : 1 + Math.min(dp[i-1][j],   // 삭제
                       dp[i][j-1],   // 삽입
                       dp[i-1][j-1]);// 교체
  return dp[m][n];
}
// 시간·공간 O(m·n)
```

---

## 5. 구간 DP (Interval DP)

`dp[i][j]` = 구간 `[i, j]`의 최적값. 작은 구간부터 큰 구간으로 채운다. 행렬 곱 순서, 돌 합치기, 회문 분할 등.

```javascript
// 예: 돌 합치기 — 인접 두 더미를 합칠 때 비용=두 더미 합, 전체 최소 비용
function mergeStones(stones) {
  const n = stones.length;
  const prefix = [0];
  for (const s of stones) prefix.push(prefix.at(-1) + s);
  const dp = Array.from({length: n}, () => new Array(n).fill(0));
  for (let len = 2; len <= n; len++)              // 구간 길이를 늘려가며
    for (let i = 0; i + len - 1 < n; i++) {
      const j = i + len - 1;
      dp[i][j] = Infinity;
      const cost = prefix[j+1] - prefix[i];        // 구간 합
      for (let k = i; k < j; k++)                   // 분할 지점
        dp[i][j] = Math.min(dp[i][j], dp[i][k] + dp[k+1][j] + cost);
    }
  return dp[0][n-1];
}
// 시간 O(n³)
```

> 구간 DP의 시그니처: **바깥 루프가 "구간 길이"**, 안에서 분할점 k를 순회. `dp[i][j] = min/max over k (dp[i][k] + dp[k+1][j] + 합치는 비용)`.

---

## 6. DP 최적화 개요

코테 고난도에서 등장(개념만):
- **비트마스크 DP**: 집합 상태 압축([패턴 16](./16-bitmask.md)).
- **트리 DP**: 서브트리 합성([패턴 18](./18-tree-algorithms.md)).
- **경사 트릭/CHT(Convex Hull Trick)**, **분할 정복 최적화**, **Knuth 최적화**: 특정 점화식의 O(n²)→O(n log n) 단축. 빈도 낮음.
- **공간 최적화**: 직전 상태만 필요하면 롤링 배열로 O(n²)→O(n).

---

## 7. 면접 포인트

**Q. DP를 적용할 수 있는 조건은?**
> 겹치는 부분 문제(같은 계산 반복)와 최적 부분 구조(부분 최적이 전체 최적을 구성)다. 완전탐색의 중복을 메모이제이션/타뷸레이션으로 제거하는 게 본질이다.

**Q. LIS를 O(n log n)으로 푸는 원리는?**
> "각 길이의 증가 부분 수열이 가질 수 있는 마지막 원소의 최솟값"을 모은 tails 배열을 유지하며, 새 원소를 이진 탐색(lower bound) 위치에 교체/추가한다. tails 길이가 LIS 길이다. 단 tails 자체는 실제 수열이 아니다.

**Q. LCS의 점화식은?**
> `dp[i][j]`를 두 접두사의 LCS로 정의하고, 마지막 글자가 같으면 `dp[i-1][j-1]+1`, 다르면 `max(dp[i-1][j], dp[i][j-1])`. 시간·공간 O(mn)이며 한 행만 써서 공간을 O(n)으로 줄일 수 있다.

**Q. 편집 거리의 세 연산은 점화식에서 어떻게 나타나나요?**
> 글자가 다르면 `1 + min(삭제=dp[i-1][j], 삽입=dp[i][j-1], 교체=dp[i-1][j-1])`. 같으면 비용 없이 `dp[i-1][j-1]`.

**Q. 구간 DP의 전형적 형태는?**
> `dp[i][j]`를 구간 [i,j]의 최적값으로 두고, 바깥 루프로 구간 길이를 늘리며 안에서 분할점 k를 순회해 `dp[i][k]+dp[k+1][j]+합치는 비용`의 최소/최대를 취한다. 행렬 곱 순서·돌 합치기·회문 분할이 대표 예이고 보통 O(n³)이다.
