# 1. 투 포인터 (Two Pointers)

## 목차
1. [개념과 사용 조건](#1-개념과-사용-조건)
2. [패턴 유형](#2-패턴-유형)
3. [예제 1: Two Sum II](#3-예제-1-two-sum-ii)
4. [예제 2: 유효한 팰린드롬](#4-예제-2-유효한-팰린드롬)
5. [예제 3: 세 수의 합 (3Sum)](#5-예제-3-세-수의-합-3sum)
6. [시간복잡도 분석](#6-시간복잡도-분석)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 개념과 사용 조건

투 포인터 패턴은 배열이나 문자열에서 **두 개의 인덱스(포인터)를 동시에 사용**해 문제를 푸는 기법입니다.
중첩 반복문(O(n²))을 단일 순회(O(n))로 줄이는 것이 핵심 목표입니다.

### 사용 조건

- **정렬된 배열** 또는 정렬 가능한 배열
- **연속적인 구간** 또는 **양 끝에서 좁혀오는** 탐색 구조
- 쌍(pair), 세 쌍(triplet), 부분 배열의 합/차이를 구하는 문제

### 언제 투 포인터를 떠올릴까?

> "정렬된 배열에서 특정 합/조건을 만족하는 쌍을 찾아야 한다."
> "문자열의 양 끝을 비교해야 한다."
> "O(n²) 브루트 포스를 O(n log n) 이하로 줄여야 한다."

---

## 2. 패턴 유형

### 2-1. 반대 방향 포인터 (Opposite Direction)

왼쪽(left)과 오른쪽(right) 포인터가 서로 가까워지는 방향으로 이동합니다.

```
[ 1,  2,  4,  7,  11 ]
  ^                ^
 left             right
```

- 합이 목표보다 작으면 `left++`
- 합이 목표보다 크면 `right--`
- 합이 목표와 같으면 정답

### 2-2. 같은 방향 포인터 (Same Direction / Fast-Slow)

두 포인터가 같은 방향으로 이동하되, 속도나 이동 조건이 다릅니다.

```
[ a, b, c, d, e, f ]
  ^     ^
slow   fast
```

- 연결 리스트의 사이클 감지 (플로이드 알고리즘)
- 중복 제거, 특정 조건 원소 필터링

---

## 3. 예제 1: Two Sum II

### 문제

오름차순으로 정렬된 배열 `numbers`와 정수 `target`이 주어질 때,
합이 `target`이 되는 두 수의 **1-indexed 위치**를 반환하세요.

```
입력: numbers = [2, 7, 11, 15], target = 9
출력: [1, 2]
설명: numbers[0] + numbers[1] = 2 + 7 = 9
```

### 접근법

배열이 **이미 정렬**되어 있으므로 반대 방향 포인터를 사용합니다.

1. `left = 0`, `right = numbers.length - 1`로 초기화
2. `numbers[left] + numbers[right]`를 `target`과 비교
3. 합이 작으면 `left++`, 크면 `right--`, 같으면 반환

### JavaScript 풀이

```javascript
/**
 * @param {number[]} numbers - 오름차순 정렬된 배열
 * @param {number} target
 * @return {number[]} 1-indexed 위치 배열
 */
function twoSum(numbers, target) {
  let left = 0;
  let right = numbers.length - 1;

  while (left < right) {
    const sum = numbers[left] + numbers[right];

    if (sum === target) {
      return [left + 1, right + 1]; // 1-indexed
    } else if (sum < target) {
      left++;  // 합을 키우려면 왼쪽 포인터를 오른쪽으로
    } else {
      right--; // 합을 줄이려면 오른쪽 포인터를 왼쪽으로
    }
  }

  return []; // 항상 정답이 존재한다고 가정
}

// 테스트
console.log(twoSum([2, 7, 11, 15], 9));   // [1, 2]
console.log(twoSum([2, 3, 4], 6));         // [1, 3]
console.log(twoSum([-1, 0], -1));          // [1, 2]
```

### 복잡도

- 시간: O(n) — 두 포인터가 각각 최대 n번 이동
- 공간: O(1) — 추가 자료구조 없음

---

## 4. 예제 2: 유효한 팰린드롬

### 문제

문자열 `s`에서 **영문자와 숫자만** 남기고 **소문자로 변환**한 후,
그 문자열이 팰린드롬인지 판별하세요.

```
입력: s = "A man, a plan, a canal: Panama"
출력: true
설명: "amanaplanacanalpanama" 는 팰린드롬

입력: s = "race a car"
출력: false
설명: "raceacar" 는 팰린드롬이 아님
```

### 접근법

전처리 없이 투 포인터로 직접 검사합니다.

1. `left = 0`, `right = s.length - 1` 초기화
2. 각 포인터에서 알파벳/숫자가 아닌 문자를 건너뜀
3. 두 문자가 다르면 `false`, 같으면 포인터 이동 반복

### JavaScript 풀이

```javascript
/**
 * @param {string} s
 * @return {boolean}
 */
function isPalindrome(s) {
  // 영문자·숫자 여부 확인 헬퍼
  const isAlphanumeric = (char) => /[a-zA-Z0-9]/.test(char);

  let left = 0;
  let right = s.length - 1;

  while (left < right) {
    // 유효하지 않은 문자 건너뜀
    while (left < right && !isAlphanumeric(s[left])) left++;
    while (left < right && !isAlphanumeric(s[right])) right--;

    // 소문자로 변환 후 비교
    if (s[left].toLowerCase() !== s[right].toLowerCase()) {
      return false;
    }

    left++;
    right--;
  }

  return true;
}

// 테스트
console.log(isPalindrome("A man, a plan, a canal: Panama")); // true
console.log(isPalindrome("race a car"));                      // false
console.log(isPalindrome(" "));                               // true
```

### 복잡도

- 시간: O(n) — 각 문자를 최대 한 번씩 방문
- 공간: O(1) — 추가 문자열 생성 없음

---

## 5. 예제 3: 세 수의 합 (3Sum)

### 문제

정수 배열 `nums`에서 합이 0이 되는 **세 수의 모든 조합**을 반환하세요.
중복 조합은 포함하지 않습니다.

```
입력: nums = [-1, 0, 1, 2, -1, -4]
출력: [[-1, -1, 2], [-1, 0, 1]]

입력: nums = [0, 1, 1]
출력: []

입력: nums = [0, 0, 0]
출력: [[0, 0, 0]]
```

### 접근법

3중 루프(O(n³)) 대신 **정렬 + 투 포인터**로 O(n²)에 해결합니다.

1. 배열을 정렬
2. 각 원소 `nums[i]`를 고정하고, 나머지 구간 `[i+1, n-1]`에 투 포인터 적용
3. `nums[i] + nums[left] + nums[right] === 0` 인 경우 결과 추가
4. 중복 건너뛰기 처리가 핵심

### JavaScript 풀이

```javascript
/**
 * @param {number[]} nums
 * @return {number[][]}
 */
function threeSum(nums) {
  nums.sort((a, b) => a - b); // 오름차순 정렬
  const result = [];

  for (let i = 0; i < nums.length - 2; i++) {
    // i 위치 중복 건너뜀
    if (i > 0 && nums[i] === nums[i - 1]) continue;

    // 가장 작은 세 수의 합이 이미 양수 → 이후 탐색 불필요
    if (nums[i] > 0) break;

    let left = i + 1;
    let right = nums.length - 1;

    while (left < right) {
      const sum = nums[i] + nums[left] + nums[right];

      if (sum === 0) {
        result.push([nums[i], nums[left], nums[right]]);

        // 중복 값 건너뜀
        while (left < right && nums[left] === nums[left + 1]) left++;
        while (left < right && nums[right] === nums[right - 1]) right--;

        left++;
        right--;
      } else if (sum < 0) {
        left++;
      } else {
        right--;
      }
    }
  }

  return result;
}

// 테스트
console.log(threeSum([-1, 0, 1, 2, -1, -4]));
// [[-1, -1, 2], [-1, 0, 1]]

console.log(threeSum([0, 0, 0]));
// [[0, 0, 0]]

console.log(threeSum([1, 2, -2, -1]));
// []
```

### 복잡도

- 시간: O(n²) — 외부 루프 O(n) × 내부 투 포인터 O(n)
- 공간: O(1) ~ O(n) — 정렬에 O(log n), 결과 배열 제외 시 O(1)

---

## 6. 시간복잡도 분석

| 문제 | 브루트 포스 | 투 포인터 | 개선 |
|------|------------|----------|------|
| Two Sum II | O(n²) | O(n) | n배 감소 |
| 팰린드롬 | O(n) — 동일 | O(n) | 공간 O(n) → O(1) |
| 3Sum | O(n³) | O(n²) | n배 감소 |

### 투 포인터가 O(n)인 이유

두 포인터 `left`와 `right`는 각각 한 방향으로만 이동하며, 서로 교차하면 종료됩니다.
전체 이동 횟수의 합은 최대 `n`번이므로 시간복잡도는 O(n)입니다.

```
초기:  left=0, right=n-1  →  최대 n번의 이동으로 left >= right
```

---

## 7. 면접 포인트

### Q1. 투 포인터를 언제 사용하나요?

**모범 답변:**
정렬된 배열에서 두 원소의 합/차이 조건을 찾거나, 문자열의 양 끝에서 비교가 필요할 때 사용합니다.
중첩 루프를 단일 순회로 줄여 O(n²) → O(n) 최적화가 핵심입니다.

---

### Q2. 3Sum에서 중복 처리는 왜 필요하고 어떻게 하나요?

**모범 답변:**
정렬 후 같은 값이 연속될 때, 동일한 조합이 여러 번 추가되는 것을 방지해야 합니다.
- 외부 루프(`i`)에서: `i > 0 && nums[i] === nums[i-1]` 이면 `continue`
- 내부 투 포인터에서: 정답을 찾은 직후 `left`, `right`에서 연속된 중복값을 건너뜀

---

### Q3. 투 포인터와 이진 탐색의 차이는 무엇인가요?

**모범 답변:**

| | 투 포인터 | 이진 탐색 |
|-|---------|---------|
| 목적 | 두 원소의 관계(합/차) 탐색 | 단일 값 위치 탐색 |
| 이동 방식 | 조건에 따라 한 쪽씩 이동 | 중간점 기준 절반씩 제거 |
| 시간복잡도 | O(n) | O(log n) |
| 사용 예 | 쌍 찾기, 팰린드롬 | 정렬된 배열에서 값 찾기 |

---

### Q4. 정렬되지 않은 배열에서 Two Sum은 어떻게 푸나요?

**모범 답변:**
정렬되지 않은 경우 투 포인터는 사용할 수 없습니다.
대신 **해시맵(Map)** 을 사용해 O(n) 시간, O(n) 공간으로 해결합니다.

```javascript
function twoSumUnsorted(nums, target) {
  const map = new Map(); // value → index

  for (let i = 0; i < nums.length; i++) {
    const complement = target - nums[i];
    if (map.has(complement)) {
      return [map.get(complement), i];
    }
    map.set(nums[i], i);
  }

  return [];
}
```

투 포인터(O(1) 공간) vs 해시맵(O(n) 공간) 트레이드오프를 설명할 수 있어야 합니다.

---

### Q5. Fast-Slow 포인터는 어디에 쓰이나요?

**모범 답변:**
주로 **연결 리스트**에서 사용됩니다.

- **사이클 감지**: 빠른 포인터(2칸)와 느린 포인터(1칸)가 만나면 사이클 존재
- **중간 노드 찾기**: 빠른 포인터가 끝에 도달하면 느린 포인터가 중간 위치
- **k번째 노드**: 빠른 포인터를 k칸 앞서 출발시켜 동시에 이동

```javascript
// 연결 리스트 사이클 감지 (플로이드 알고리즘)
function hasCycle(head) {
  let slow = head;
  let fast = head;

  while (fast !== null && fast.next !== null) {
    slow = slow.next;
    fast = fast.next.next;

    if (slow === fast) return true;
  }

  return false;
}
```
