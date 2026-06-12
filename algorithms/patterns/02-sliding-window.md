# 2. 슬라이딩 윈도우 (Sliding Window)

## 목차
1. [개념과 브루트 포스 비교](#1-개념과-브루트-포스-비교)
2. [패턴 유형](#2-패턴-유형)
3. [예제 1: 길이 k인 서브배열의 최대 합](#3-예제-1-길이-k인-서브배열의-최대-합)
4. [예제 2: 중복 없는 가장 긴 부분 문자열](#4-예제-2-중복-없는-가장-긴-부분-문자열)
5. [예제 3: 합이 S 이상인 최소 길이 부분 배열](#5-예제-3-합이-s-이상인-최소-길이-부분-배열)
6. [시간복잡도 분석](#6-시간복잡도-분석)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 개념과 브루트 포스 비교

슬라이딩 윈도우는 배열이나 문자열에서 **연속된 부분(구간)** 을 탐색할 때 사용하는 패턴입니다.
윈도우(구간)를 오른쪽으로 밀면서 새로 들어오는 원소와 나가는 원소만 갱신해
불필요한 재계산을 제거합니다.

### 브루트 포스의 문제점

길이 k인 모든 서브배열의 합을 구한다고 가정합니다.

```javascript
// 브루트 포스: O(n * k)
function maxSumBrute(arr, k) {
  let maxSum = -Infinity;
  for (let i = 0; i <= arr.length - k; i++) {
    let sum = 0;
    for (let j = i; j < i + k; j++) { // 매번 k개를 다시 합산
      sum += arr[j];
    }
    maxSum = Math.max(maxSum, sum);
  }
  return maxSum;
}
```

윈도우가 한 칸 이동할 때마다 k개 원소를 **다시 합산**합니다.
윈도우 내 원소는 대부분 이전과 동일한데도 불구하고 반복 계산이 발생합니다.

### 슬라이딩 윈도우의 핵심 아이디어

```
초기:  [ 2,  1,  5,  1,  3,  2 ]   k=3
        [-------]
        sum = 8

이동:  [ 2,  1,  5,  1,  3,  2 ]
           [-------]
           sum = 8 - 2 + 1 = 7   ← 나간 원소 빼고, 들어온 원소 더함
```

이전 합에서 **나간 원소를 빼고 들어온 원소를 더하면** O(1)로 갱신됩니다.

---

## 2. 패턴 유형

### 2-1. 고정 크기 윈도우 (Fixed Size)

윈도우 크기 `k`가 문제에서 주어집니다.

```
조건: 항상 정확히 k개의 원소를 포함
이동: right를 1씩 증가, left = right - k + 1
종료: right가 배열 끝에 도달
```

사용 예: "길이 k인 서브배열의 최대/최소/평균"

### 2-2. 가변 크기 윈도우 (Variable Size)

조건을 만족하는 최소/최대 크기의 구간을 찾습니다.

```
조건: 특정 조건(합 >= S, 중복 없음 등)을 만족하는 구간
확장: right를 오른쪽으로 이동 (원소 추가)
축소: left를 오른쪽으로 이동 (원소 제거)
종료: right가 배열 끝에 도달
```

사용 예: "조건을 만족하는 가장 짧은/긴 부분 배열"

### 패턴 선택 기준

| 문제 유형 | 윈도우 종류 | 포인터 이동 |
|---------|-----------|-----------|
| 길이 k 고정, 최적값 | 고정 | right++, left = right - k |
| 조건 만족하는 최단 구간 | 가변 | right 확장 → left 축소 |
| 조건 만족하는 최장 구간 | 가변 | right 확장 → 위반 시 left 축소 |

---

## 3. 예제 1: 길이 k인 서브배열의 최대 합

### 문제

정수 배열 `arr`와 정수 `k`가 주어질 때,
길이가 정확히 `k`인 연속 부분 배열의 **최대 합**을 반환하세요.

```
입력: arr = [2, 1, 5, 1, 3, 2], k = 3
출력: 9
설명: [5, 1, 3]의 합이 9로 최대

입력: arr = [2, 3, 4, 1, 5], k = 2
출력: 7
설명: [3, 4]의 합이 7로 최대
```

### 접근법

고정 크기 윈도우를 사용합니다.

1. 첫 번째 윈도우(`arr[0..k-1]`)의 합을 미리 계산
2. 윈도우를 오른쪽으로 한 칸씩 이동하면서 합 갱신
3. `currentSum = currentSum - arr[left] + arr[right]`

### JavaScript 풀이

```javascript
/**
 * @param {number[]} arr
 * @param {number} k
 * @return {number}
 */
function maxSumSubarray(arr, k) {
  if (arr.length < k) return -1; // 엣지 케이스

  // 첫 번째 윈도우 합산
  let windowSum = 0;
  for (let i = 0; i < k; i++) {
    windowSum += arr[i];
  }

  let maxSum = windowSum;

  // 윈도우를 오른쪽으로 슬라이드
  for (let right = k; right < arr.length; right++) {
    // 새 원소 추가, 나간 원소 제거
    windowSum += arr[right] - arr[right - k];
    maxSum = Math.max(maxSum, windowSum);
  }

  return maxSum;
}

// 테스트
console.log(maxSumSubarray([2, 1, 5, 1, 3, 2], 3)); // 9
console.log(maxSumSubarray([2, 3, 4, 1, 5], 2));     // 7
console.log(maxSumSubarray([1, 4, 2, 10, 23, 3, 1, 0, 20], 4)); // 39
```

### 단계별 시각화

```
arr = [2, 1, 5, 1, 3, 2], k = 3

초기 윈도우: [2, 1, 5]    → sum = 8,  maxSum = 8
이동 1:      [1, 5, 1]    → sum = 8 - 2 + 1 = 7,  maxSum = 8
이동 2:      [5, 1, 3]    → sum = 7 - 1 + 3 = 9,  maxSum = 9
이동 3:      [1, 3, 2]    → sum = 9 - 5 + 2 = 6,  maxSum = 9

결과: 9
```

### 복잡도

- 시간: O(n) — 각 원소를 정확히 한 번씩 처리
- 공간: O(1) — 추가 자료구조 없음

---

## 4. 예제 2: 중복 없는 가장 긴 부분 문자열

### 문제

문자열 `s`에서 **중복 문자가 없는** 가장 긴 부분 문자열의 길이를 반환하세요.

```
입력: s = "abcabcbb"
출력: 3
설명: "abc"

입력: s = "bbbbb"
출력: 1
설명: "b"

입력: s = "pwwkew"
출력: 3
설명: "wke"
```

### 접근법

가변 크기 윈도우 + Map(문자 → 마지막 인덱스)을 사용합니다.

1. Map으로 현재 윈도우 내 문자의 마지막 위치를 추적
2. 새 문자가 윈도우 내에 이미 있으면, `left`를 중복 문자 다음 위치로 이동
3. 매 단계에서 윈도우 크기(`right - left + 1`)의 최대값을 갱신

### JavaScript 풀이

```javascript
/**
 * @param {string} s
 * @return {number}
 */
function lengthOfLongestSubstring(s) {
  // 문자 → 마지막으로 등장한 인덱스
  const lastSeen = new Map();
  let maxLength = 0;
  let left = 0;

  for (let right = 0; right < s.length; right++) {
    const char = s[right];

    // 현재 윈도우 내에 중복 문자가 있으면 left를 이동
    if (lastSeen.has(char) && lastSeen.get(char) >= left) {
      left = lastSeen.get(char) + 1;
    }

    // 현재 문자의 인덱스 갱신
    lastSeen.set(char, right);

    // 최대 윈도우 크기 갱신
    maxLength = Math.max(maxLength, right - left + 1);
  }

  return maxLength;
}

// 테스트
console.log(lengthOfLongestSubstring("abcabcbb")); // 3
console.log(lengthOfLongestSubstring("bbbbb"));    // 1
console.log(lengthOfLongestSubstring("pwwkew"));   // 3
console.log(lengthOfLongestSubstring(""));         // 0
```

### 단계별 시각화

```
s = "abcabcbb"

right=0: char='a' | window="a"     | left=0, max=1
right=1: char='b' | window="ab"    | left=0, max=2
right=2: char='c' | window="abc"   | left=0, max=3
right=3: char='a' | 'a' at 0 >= left(0) → left=1
                    window="bca"   | left=1, max=3
right=4: char='b' | 'b' at 1 >= left(1) → left=2
                    window="cab"   | left=2, max=3
right=5: char='c' | 'c' at 2 >= left(2) → left=3
                    window="abc"   | left=3, max=3
right=6: char='b' | 'b' at 4 >= left(3) → left=5
                    window="cb"    | left=5, max=3
right=7: char='b' | 'b' at 6 >= left(5) → left=7
                    window="b"     | left=7, max=3

결과: 3
```

### 복잡도

- 시간: O(n) — 각 문자를 최대 두 번(추가/제거) 처리
- 공간: O(min(n, m)) — m은 문자 집합의 크기 (ASCII: 128)

---

## 5. 예제 3: 합이 S 이상인 최소 길이 부분 배열

### 문제

**양의 정수**로 이루어진 배열 `nums`와 양의 정수 `target`이 주어질 때,
합이 `target` **이상**인 **가장 짧은** 연속 부분 배열의 길이를 반환하세요.
만족하는 부분 배열이 없으면 `0`을 반환합니다.

```
입력: target = 7, nums = [2, 3, 1, 2, 4, 3]
출력: 2
설명: [4, 3]의 합이 7로, 길이 2가 최소

입력: target = 4, nums = [1, 4, 4]
출력: 1
설명: [4]

입력: target = 11, nums = [1, 1, 1, 1, 1, 1, 1, 1]
출력: 0
```

### 접근법

가변 크기 윈도우 확장·축소 패턴을 사용합니다.

1. `right`를 오른쪽으로 이동하며 `windowSum`에 원소 추가
2. `windowSum >= target`을 만족하면:
   - 현재 윈도우 길이로 최솟값 갱신
   - `left`를 오른쪽으로 이동하며 윈도우 축소 (더 짧은 정답 탐색)
3. `windowSum < target`이 될 때까지 축소 반복

### JavaScript 풀이

```javascript
/**
 * @param {number} target
 * @param {number[]} nums
 * @return {number}
 */
function minSubArrayLen(target, nums) {
  let left = 0;
  let windowSum = 0;
  let minLength = Infinity;

  for (let right = 0; right < nums.length; right++) {
    windowSum += nums[right]; // 윈도우 확장

    // 조건 만족 시 축소 시도
    while (windowSum >= target) {
      minLength = Math.min(minLength, right - left + 1);
      windowSum -= nums[left]; // 왼쪽 원소 제거
      left++;                  // 윈도우 축소
    }
  }

  return minLength === Infinity ? 0 : minLength;
}

// 테스트
console.log(minSubArrayLen(7, [2, 3, 1, 2, 4, 3])); // 2
console.log(minSubArrayLen(4, [1, 4, 4]));           // 1
console.log(minSubArrayLen(11, [1, 1, 1, 1, 1, 1, 1, 1])); // 0
console.log(minSubArrayLen(15, [1, 2, 3, 4, 5]));   // 5
```

### 단계별 시각화

```
target=7, nums=[2, 3, 1, 2, 4, 3]

right=0: sum=2  < 7 → 확장
right=1: sum=5  < 7 → 확장
right=2: sum=6  < 7 → 확장
right=3: sum=8  >= 7 → min=4, left++ → sum=6, left=1
         sum=6  < 7 → 확장
right=4: sum=10 >= 7 → min=4, left++ → sum=7, left=2
         sum=7  >= 7 → min=3, left++ → sum=6, left=3
         sum=6  < 7 → 확장
right=5: sum=9  >= 7 → min=2, left++ → sum=7, left=4  ← [4,3] 발견
         sum=7  >= 7 → min=2, left++ → sum=3, left=5
         sum=3  < 7 → 종료

결과: 2
```

### 복잡도

- 시간: O(n) — `left`와 `right` 각각 최대 n번 이동
- 공간: O(1)

---

## 6. 시간복잡도 분석

| 문제 | 브루트 포스 | 슬라이딩 윈도우 | 개선 |
|------|------------|--------------|------|
| 고정 크기 최대 합 | O(n·k) | O(n) | k배 감소 |
| 최장 중복 없는 문자열 | O(n²) | O(n) | n배 감소 |
| 최소 길이 부분 배열 | O(n²) | O(n) | n배 감소 |

### 슬라이딩 윈도우가 O(n)인 이유

```
right:  0 → 1 → 2 → ... → n-1   (n번 이동)
left:   0 → ... → n-1             (최대 n번 이동, right를 절대 추월하지 않음)

총 이동 횟수 = O(n) + O(n) = O(2n) = O(n)
```

각 원소는 윈도우에 **한 번 들어오고 한 번 나가므로** 전체 O(n)이 보장됩니다.

### 공간복잡도 비교

| 방법 | 공간복잡도 |
|------|----------|
| 고정 윈도우 (합산) | O(1) |
| 가변 윈도우 (Map 사용) | O(min(n, m)) |
| 가변 윈도우 (합산) | O(1) |

---

## 7. 면접 포인트

### Q1. 슬라이딩 윈도우를 어떤 문제에 적용하나요?

**모범 답변:**
"연속된 부분 배열/문자열"에서 특정 조건(합, 중복 없음, 포함 관계 등)을 만족하는
최적 구간을 찾을 때 사용합니다. 브루트 포스 O(n²)을 O(n)으로 최적화하며,
고정 크기 윈도우와 가변 크기 윈도우 두 가지 방식이 있습니다.

---

### Q2. 고정 윈도우와 가변 윈도우의 차이점은?

**모범 답변:**

| | 고정 윈도우 | 가변 윈도우 |
|-|-----------|-----------|
| 크기 | 문제에서 k로 고정 | 조건에 따라 동적 변화 |
| left 이동 | `right - k`로 자동 결정 | 조건 위반 시 수동 이동 |
| 예시 | 길이 k 최대 합 | 최단/최장 조건 만족 구간 |

가변 윈도우에서는 `right`로 확장하고 조건에 따라 `left`로 축소하는
**확장-축소(expand-contract)** 패턴을 사용합니다.

---

### Q3. 중복 없는 최장 부분 문자열에서 Map 대신 Set을 쓰면 안 되나요?

**모범 답변:**
Set을 사용하면 중복 감지는 가능하지만, **중복 문자의 정확한 위치**를 알 수 없어
`left` 포인터를 O(1)로 이동시킬 수 없습니다. Set을 사용하면 `left`를 한 칸씩
이동하며 Set에서 원소를 제거해야 하므로 코드가 복잡해집니다.

Map은 `char → lastIndex`를 O(1)로 조회해 `left = lastIndex + 1`로 바로 이동할 수 있어 더 효율적입니다.

```javascript
// Set 사용 방식 (left를 한 칸씩 이동)
function withSet(s) {
  const set = new Set();
  let left = 0, maxLen = 0;

  for (let right = 0; right < s.length; right++) {
    while (set.has(s[right])) {
      set.delete(s[left]);
      left++;
    }
    set.add(s[right]);
    maxLen = Math.max(maxLen, right - left + 1);
  }

  return maxLen;
}
// 시간복잡도는 동일하게 O(n)이지만, 내부 while로 인해 상수 계수가 큼
```

---

### Q4. 최소 길이 부분 배열에서 음수가 포함되면 슬라이딩 윈도우를 쓸 수 없는 이유는?

**모범 답변:**
슬라이딩 윈도우의 축소 단계는 "왼쪽 원소를 제거하면 합이 줄어든다"는 전제에 의존합니다.
음수가 있으면 원소를 제거할 때 **합이 오히려 커질 수 있어** 단조성(monotonicity)이 깨집니다.
이 경우 **프리픽스 합 + 이진 탐색** (O(n log n)) 또는 **덱(Deque)** 기반 방법을 사용해야 합니다.

---

### Q5. 슬라이딩 윈도우와 투 포인터의 관계는?

**모범 답변:**
슬라이딩 윈도우는 투 포인터의 특수한 형태입니다.
두 포인터(`left`, `right`)를 사용한다는 점은 동일하지만,
슬라이딩 윈도우는 두 포인터 사이의 **구간(윈도우) 전체의 집계값(합, 빈도 등)을 유지**하는 데 초점을 맞춥니다.

| | 투 포인터 | 슬라이딩 윈도우 |
|-|---------|--------------|
| 초점 | 두 원소의 관계 | 구간 전체의 집계값 |
| 방향 | 반대 방향 가능 | 주로 같은 방향 |
| 자료구조 | 추가 불필요 | Map/Set 필요할 수 있음 |
