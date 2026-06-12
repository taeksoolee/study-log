# 4. 동적 프로그래밍 (Dynamic Programming)

## 목차
1. DP 개념 및 조건
2. Memoization vs Tabulation 비교
3. 1D DP 패턴
   - 피보나치 수열
   - 계단 오르기 (Climbing Stairs)
   - 동전 거슬러 주기 (Coin Change)
4. 2D DP 패턴
   - 최장 공통 부분 수열 (LCS)
   - 0/1 배낭 문제 (Knapsack)
5. 공간 압축 최적화
6. 면접 포인트

---

## 1. DP 개념 및 조건

동적 프로그래밍은 복잡한 문제를 작은 하위 문제로 분할하고, 각 하위 문제의 결과를 저장하여 중복 계산을 제거하는 최적화 기법입니다.

### DP 적용 조건

**1. 최적 부분 구조 (Optimal Substructure)**
> 문제의 최적 해가 하위 문제의 최적 해로 구성될 수 있어야 한다.

```
f(n) = f(n-1) + f(n-2)  // 피보나치
minCost(n) = min(minCost(n-1), minCost(n-2)) + cost[n]  // 계단 문제
```

**2. 중복 부분 문제 (Overlapping Subproblems)**
> 동일한 하위 문제가 반복적으로 계산되어야 한다.

단순 분할정복(Merge Sort 등)은 하위 문제가 중복되지 않으므로 DP가 아님.

### DP vs 다른 알고리즘 선택 기준

```
모든 경우를 탐색? → 완전 탐색(백트래킹)
최적해 + 중복 부분 문제? → DP
최적해 + 탐욕적 선택 속성? → 그리디
```

---

## 2. Memoization vs Tabulation 비교

| 구분 | Memoization (Top-down) | Tabulation (Bottom-up) |
|------|------------------------|------------------------|
| 방향 | 큰 문제 → 작은 문제 | 작은 문제 → 큰 문제 |
| 구현 | 재귀 + 캐시(Map/배열) | 반복문 + DP 테이블 |
| 계산 | 필요한 하위 문제만 계산 | 모든 하위 문제 계산 |
| 공간 | 재귀 스택 + 캐시 | DP 테이블만 |
| 성능 | 캐시 미스 가능 | 순차 접근으로 캐시 효율 높음 |
| 직관성 | 점화식 그대로 작성 | 순서 설계 필요 |

```javascript
// Memoization 예시 구조
const memo = new Map();
function dp(n) {
  if (memo.has(n)) return memo.get(n); // 캐시 히트
  const result = /* 점화식 */;
  memo.set(n, result);
  return result;
}

// Tabulation 예시 구조
const table = new Array(n + 1).fill(0);
table[0] = /* 기저 사례 */;
for (let i = 1; i <= n; i++) {
  table[i] = /* 점화식 */;
}
```

---

## 3. 1D DP 패턴

### 3-1. 피보나치 수열

**점화식:** `F(n) = F(n-1) + F(n-2)`, `F(0) = 0`, `F(1) = 1`

```javascript
// 1. 순수 재귀 - O(2^n) 시간, 비효율
function fibNaive(n) {
  if (n <= 1) return n;
  return fibNaive(n - 1) + fibNaive(n - 2);
}

// 2. Memoization (Top-down) - O(n) 시간, O(n) 공간
function fibMemo(n, memo = new Map()) {
  if (n <= 1) return n;
  if (memo.has(n)) return memo.get(n);

  const result = fibMemo(n - 1, memo) + fibMemo(n - 2, memo);
  memo.set(n, result);
  return result;
}

// 3. Tabulation (Bottom-up) - O(n) 시간, O(n) 공간
function fibTab(n) {
  if (n <= 1) return n;
  const dp = new Array(n + 1);
  dp[0] = 0;
  dp[1] = 1;

  for (let i = 2; i <= n; i++) {
    dp[i] = dp[i - 1] + dp[i - 2];
  }
  return dp[n];
}

// 4. 공간 최적화 - O(n) 시간, O(1) 공간
function fibOptimal(n) {
  if (n <= 1) return n;
  let prev2 = 0, prev1 = 1;

  for (let i = 2; i <= n; i++) {
    const curr = prev1 + prev2;
    prev2 = prev1;
    prev1 = curr;
  }
  return prev1;
}

console.log(fibOptimal(10)); // 55
```

---

### 3-2. 계단 오르기 (Climbing Stairs)

**문제:** n개의 계단을 오를 때 한 번에 1칸 또는 2칸 오를 수 있다. 총 방법의 수를 반환하라.

**점화식:** `dp[i] = dp[i-1] + dp[i-2]` (피보나치와 동일한 구조)

```javascript
/**
 * @param {number} n
 * @return {number}
 * 시간복잡도: O(n)
 * 공간복잡도: O(1)
 */
function climbStairs(n) {
  if (n <= 2) return n;

  let one = 2; // dp[i-1]: 한 칸 전
  let two = 1; // dp[i-2]: 두 칸 전

  for (let i = 3; i <= n; i++) {
    const curr = one + two;
    two = one;
    one = curr;
  }
  return one;
}

// DP 테이블로 이해하기
function climbStairsTable(n) {
  const dp = new Array(n + 1);
  dp[1] = 1; // 1칸: 1가지
  dp[2] = 2; // 2칸: 2가지 (1+1, 2)

  for (let i = 3; i <= n; i++) {
    // i번째 계단에 도달하는 방법
    // = (i-1)에서 1칸 + (i-2)에서 2칸
    dp[i] = dp[i - 1] + dp[i - 2];
  }
  return dp[n];
}

console.log(climbStairs(5)); // 8
```

---

### 3-3. 동전 거슬러 주기 (Coin Change)

**문제:** 동전 종류 배열 `coins`와 목표 금액 `amount`가 주어질 때, 목표 금액을 만들기 위한 최소 동전 수를 반환하라. 불가능하면 -1 반환.

**점화식:** `dp[i] = min(dp[i], dp[i - coin] + 1)` for each coin

```javascript
/**
 * @param {number[]} coins
 * @param {number} amount
 * @return {number}
 * 시간복잡도: O(amount * coins.length)
 * 공간복잡도: O(amount)
 */
function coinChange(coins, amount) {
  // dp[i] = 금액 i를 만들기 위한 최소 동전 수
  const dp = new Array(amount + 1).fill(Infinity);
  dp[0] = 0; // 기저 사례: 금액 0은 동전 0개

  for (let i = 1; i <= amount; i++) {
    for (const coin of coins) {
      if (coin <= i && dp[i - coin] !== Infinity) {
        dp[i] = Math.min(dp[i], dp[i - coin] + 1);
      }
    }
  }

  return dp[amount] === Infinity ? -1 : dp[amount];
}

// 예시: coins = [1, 5, 6, 9], amount = 11
// dp[0]=0, dp[1]=1(1), dp[5]=1(5), dp[6]=1(6),
// dp[9]=1(9), dp[10]=2(5+5), dp[11]=2(5+6)
console.log(coinChange([1, 5, 6, 9], 11)); // 2
console.log(coinChange([2], 3));           // -1
```

---

## 4. 2D DP 패턴

### 4-1. 최장 공통 부분 수열 (LCS, Longest Common Subsequence)

**문제:** 두 문자열 `text1`, `text2`의 최장 공통 부분 수열의 길이를 반환하라.
(부분 수열은 순서를 유지하지만 연속일 필요 없음)

**점화식:**
```
dp[i][j] = dp[i-1][j-1] + 1           (text1[i-1] === text2[j-1])
dp[i][j] = max(dp[i-1][j], dp[i][j-1]) (text1[i-1] !== text2[j-1])
```

```javascript
/**
 * @param {string} text1
 * @param {string} text2
 * @return {number}
 * 시간복잡도: O(M * N)
 * 공간복잡도: O(M * N) → 최적화 시 O(N)
 */
function longestCommonSubsequence(text1, text2) {
  const m = text1.length;
  const n = text2.length;

  // dp[i][j]: text1[0..i-1]과 text2[0..j-1]의 LCS 길이
  const dp = Array.from({ length: m + 1 }, () => new Array(n + 1).fill(0));

  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      if (text1[i - 1] === text2[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1] + 1; // 문자 매칭
      } else {
        dp[i][j] = Math.max(dp[i - 1][j], dp[i][j - 1]); // 최대값 선택
      }
    }
  }

  return dp[m][n];
}

// DP 테이블 시각화 (text1="abcde", text2="ace")
//     ""  a  c  e
//  ""  0  0  0  0
//  a   0  1  1  1
//  b   0  1  1  1
//  c   0  1  2  2
//  d   0  1  2  2
//  e   0  1  2  3

console.log(longestCommonSubsequence("abcde", "ace")); // 3
console.log(longestCommonSubsequence("abc", "abc"));   // 3
console.log(longestCommonSubsequence("abc", "def"));   // 0
```

---

### 4-2. 0/1 배낭 문제 (0/1 Knapsack)

**문제:** `n`개의 아이템이 있고 각각 무게 `weights[i]`와 가치 `values[i]`를 가진다.
최대 무게 `W`를 담을 수 있는 배낭에 넣을 수 있는 최대 가치를 구하라.
(각 아이템은 한 번만 선택 가능)

**점화식:**
```
dp[i][w] = dp[i-1][w]                                    (아이템 i 미선택)
dp[i][w] = max(dp[i-1][w], dp[i-1][w-weights[i]] + values[i]) (아이템 i 선택 가능 시)
```

```javascript
/**
 * @param {number[]} weights - 아이템 무게 배열
 * @param {number[]} values  - 아이템 가치 배열
 * @param {number} W         - 배낭 최대 무게
 * @return {number}
 * 시간복잡도: O(n * W)
 * 공간복잡도: O(n * W) → 최적화 시 O(W)
 */
function knapsack(weights, values, W) {
  const n = weights.length;

  // dp[i][w]: 아이템 0~i-1 중에서 무게 w 이하로 담을 수 있는 최대 가치
  const dp = Array.from({ length: n + 1 }, () => new Array(W + 1).fill(0));

  for (let i = 1; i <= n; i++) {
    const w = weights[i - 1];
    const v = values[i - 1];

    for (let j = 0; j <= W; j++) {
      dp[i][j] = dp[i - 1][j]; // 아이템 i 미선택

      if (j >= w) {
        // 아이템 i 선택 시 vs 미선택 시 비교
        dp[i][j] = Math.max(dp[i][j], dp[i - 1][j - w] + v);
      }
    }
  }

  return dp[n][W];
}

// 공간 최적화 버전 - O(W) 공간
function knapsackOptimized(weights, values, W) {
  const n = weights.length;
  const dp = new Array(W + 1).fill(0);

  for (let i = 0; i < n; i++) {
    // 역방향 순회: 같은 아이템을 중복 선택하지 않기 위함
    for (let j = W; j >= weights[i]; j--) {
      dp[j] = Math.max(dp[j], dp[j - weights[i]] + values[i]);
    }
  }

  return dp[W];
}

const weights = [2, 3, 4, 5];
const values  = [3, 4, 5, 6];
const W = 8;
console.log(knapsack(weights, values, W));          // 10
console.log(knapsackOptimized(weights, values, W)); // 10
```

---

## 5. 공간 압축 최적화

### 1D DP 공간 압축

현재 상태가 직전 k개의 상태에만 의존하는 경우, 전체 배열 대신 슬라이딩 윈도우 변수 사용.

```javascript
// 전: O(n) 공간
const dp = new Array(n + 1);
dp[0] = 0; dp[1] = 1;
for (let i = 2; i <= n; i++) dp[i] = dp[i-1] + dp[i-2];

// 후: O(1) 공간
let a = 0, b = 1;
for (let i = 2; i <= n; i++) {
  [a, b] = [b, a + b];
}
```

### 2D DP 공간 압축

현재 행이 직전 행에만 의존하는 경우, 2D 배열 대신 1D 배열 2개(또는 역방향 순회)로 압축.

```javascript
// LCS 공간 압축: O(M*N) → O(N)
function lcsCOmpressed(text1, text2) {
  const m = text1.length, n = text2.length;
  let prev = new Array(n + 1).fill(0);
  let curr = new Array(n + 1).fill(0);

  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      if (text1[i - 1] === text2[j - 1]) {
        curr[j] = prev[j - 1] + 1;
      } else {
        curr[j] = Math.max(prev[j], curr[j - 1]);
      }
    }
    [prev, curr] = [curr, prev]; // 행 교환
    curr.fill(0);
  }

  return prev[n];
}
```

---

## 6. 면접 포인트

### Q1. DP와 재귀의 차이는 무엇인가요?

재귀는 단순히 문제를 분할하여 해결하는 방식이고, DP는 재귀(또는 반복)에 **메모이제이션**을 추가하여 중복 계산을 제거합니다. 모든 DP는 재귀로 표현할 수 있지만, 모든 재귀가 DP는 아닙니다.

### Q2. Memoization과 Tabulation 중 어느 것이 더 빠른가요?

이론적 시간복잡도는 동일하지만, Tabulation이 순차 메모리 접근으로 CPU 캐시 효율이 좋아 실제로 빠른 경우가 많습니다. 단, Memoization은 필요한 상태만 계산하므로 특정 경우엔 더 효율적일 수 있습니다.

### Q3. 점화식을 어떻게 도출하나요?

1. **상태 정의:** `dp[i]`가 무엇을 의미하는지 명확히 정의
2. **기저 사례:** 가장 작은 입력의 답을 정의
3. **전이 관계:** `dp[i]`를 이전 상태(`dp[i-1]`, `dp[i-2]` 등)로 표현
4. **최종 답의 위치:** `dp[n]`인지 `max(dp)`인지 결정

### Q4. 0/1 배낭에서 역방향 순회가 필요한 이유는?

공간 최적화된 1D 배열에서 순방향 순회 시 같은 아이템을 여러 번 사용하게 됩니다 (무한 배낭 문제가 됨). 역방향으로 순회하면 아이템 i를 처리할 때 아직 아이템 i가 포함되지 않은 이전 상태를 참조하게 됩니다.

### Q5. 어떤 문제에서 DP 대신 그리디를 써야 하나요?

그리디는 **탐욕적 선택 속성(Greedy Choice Property)** 이 성립할 때 사용합니다. 즉, 매 단계에서 지역 최적해를 선택해도 전역 최적해가 보장되는 경우입니다. DP는 과거 모든 선택을 고려해야 하는 경우에 사용합니다.

예: 동전 거스름돈 문제는 동전 단위가 배수 관계일 때 그리디가 성립하지만, 임의의 단위([1,3,4], amount=6)에서는 DP가 필요합니다.

### 복잡도 정리

| 문제 | 시간복잡도 | 공간복잡도 | 공간 압축 후 |
|------|-----------|-----------|-------------|
| 피보나치 | O(n) | O(n) | O(1) |
| 계단 오르기 | O(n) | O(n) | O(1) |
| Coin Change | O(n * W) | O(W) | - |
| LCS | O(M * N) | O(M * N) | O(N) |
| 0/1 Knapsack | O(n * W) | O(n * W) | O(W) |
