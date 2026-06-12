# 6. 분할 정복 (Divide and Conquer)

## 목차
1. 분할 정복 개념
2. 재귀와의 관계
3. 병합 정렬 (Merge Sort)
4. 퀵 정렬 (Quick Sort)
5. 병합 정렬 vs 퀵 정렬 비교
6. 이진 탐색 - 분할 정복 관점
7. 큰 수 곱셈 (Karatsuba)
8. 면접 포인트

---

## 1. 분할 정복 개념

분할 정복(Divide and Conquer)은 문제를 더 작은 부분 문제로 나누어 각각 해결하고, 그 결과를 합쳐 원래 문제를 푸는 알고리즘 설계 패러다임이다.

### 3단계 구조

| 단계 | 이름 | 설명 |
|------|------|------|
| 1 | **Divide** | 문제를 더 작은 부분 문제로 분할 |
| 2 | **Conquer** | 부분 문제를 재귀적으로 해결 (기저 사례에서 직접 해결) |
| 3 | **Combine** | 부분 문제의 해를 합쳐 원래 문제의 해를 구성 |

### 핵심 특징

- 부분 문제들은 **서로 독립적**이다 (동적 프로그래밍과의 차이점)
- **기저 사례(Base Case)**가 반드시 존재해야 한다
- 문제의 크기가 절반씩 줄어드는 경우 O(log n) 이점이 생긴다
- 병렬 처리(Parallel Processing)에 적합한 구조이다

```
문제 P
├── 부분 문제 P1 (독립적으로 해결)
├── 부분 문제 P2 (독립적으로 해결)
└── Combine(P1 해, P2 해) → P의 해
```

---

## 2. 재귀와의 관계

분할 정복은 **재귀(Recursion)**를 핵심 도구로 사용한다. 그러나 모든 재귀가 분할 정복은 아니다.

```
재귀 (넓은 개념)
├── 분할 정복  ← 문제를 독립적 부분으로 분할
├── 동적 프로그래밍 ← 부분 문제가 중복됨 (메모이제이션)
└── 단순 재귀  ← 분할 없이 크기만 줄임 (팩토리얼 등)
```

```javascript
// 단순 재귀 (분할 정복 아님)
function factorial(n) {
  if (n <= 1) return 1;
  return n * factorial(n - 1); // 하나의 부분 문제만 존재
}

// 분할 정복 (두 개의 독립적 부분 문제)
function mergeSort(arr) {
  if (arr.length <= 1) return arr;
  const mid = Math.floor(arr.length / 2);
  const left = mergeSort(arr.slice(0, mid));  // 독립적 부분 문제 1
  const right = mergeSort(arr.slice(mid));     // 독립적 부분 문제 2
  return merge(left, right);                   // Combine 단계
}
```

### 재귀 트리와 시간복잡도

분할 정복의 시간복잡도는 **마스터 정리(Master Theorem)**로 분석한다.

```
T(n) = aT(n/b) + f(n)

a = 부분 문제 수
b = 문제 크기 축소 비율
f(n) = Combine 단계 비용
```

병합 정렬의 경우: T(n) = 2T(n/2) + O(n) → **O(n log n)**

---

## 3. 병합 정렬 (Merge Sort)

병합 정렬은 배열을 절반으로 나누고, 각각을 정렬한 뒤 합치는 분할 정복 정렬이다.

### JavaScript 구현

```javascript
/**
 * 병합 정렬
 * @param {number[]} arr
 * @returns {number[]}
 */
function mergeSort(arr) {
  // 기저 사례: 원소가 1개 이하이면 이미 정렬됨
  if (arr.length <= 1) return arr;

  // Divide: 배열을 절반으로 분할
  const mid = Math.floor(arr.length / 2);
  const left = arr.slice(0, mid);
  const right = arr.slice(mid);

  // Conquer: 각 부분을 재귀적으로 정렬
  const sortedLeft = mergeSort(left);
  const sortedRight = mergeSort(right);

  // Combine: 두 정렬된 배열을 합병
  return merge(sortedLeft, sortedRight);
}

/**
 * 두 정렬된 배열을 합병
 * @param {number[]} left
 * @param {number[]} right
 * @returns {number[]}
 */
function merge(left, right) {
  const result = [];
  let i = 0;
  let j = 0;

  // 두 포인터를 사용해 작은 원소부터 결과 배열에 추가
  while (i < left.length && j < right.length) {
    if (left[i] <= right[j]) {
      result.push(left[i]);
      i++;
    } else {
      result.push(right[j]);
      j++;
    }
  }

  // 남은 원소 추가
  while (i < left.length) result.push(left[i++]);
  while (j < right.length) result.push(right[j++]);

  return result;
}

// 실행 예시
console.log(mergeSort([38, 27, 43, 3, 9, 82, 10]));
// [3, 9, 10, 27, 38, 43, 82]
```

### 시각화

```
[38, 27, 43, 3, 9, 82, 10]
         ↓ Divide
[38, 27, 43]      [3, 9, 82, 10]
     ↓                  ↓
[38] [27,43]      [3,9]  [82,10]
      ↓ ↓           ↓     ↓
     [27][43]      [3][9] [82][10]
      ↓ Merge         ↓ Merge
     [27,43]         [3,9] [10,82]
      ↓ Merge              ↓ Merge
    [27,38,43]           [3,9,10,82]
               ↓ Merge
        [3,9,10,27,38,43,82]
```

### 시간/공간복잡도 분석

| 케이스 | 시간복잡도 | 이유 |
|--------|-----------|------|
| 최선 | O(n log n) | 항상 절반으로 분할 |
| 평균 | O(n log n) | 동일 |
| 최악 | O(n log n) | 입력에 무관하게 동일 |

- **공간복잡도**: O(n) - 합병 시 임시 배열 필요
- **안정 정렬(Stable Sort)**: 동일한 값의 상대적 순서 유지
- 외부 정렬(External Sort)에 적합 (디스크 기반 정렬)

---

## 4. 퀵 정렬 (Quick Sort)

퀵 정렬은 피벗(pivot)을 선택해 피벗보다 작은 원소는 왼쪽, 큰 원소는 오른쪽으로 분할하며 정렬한다.

### JavaScript 구현

```javascript
/**
 * 퀵 정렬 (제자리 정렬 버전)
 * @param {number[]} arr
 * @param {number} low
 * @param {number} high
 */
function quickSort(arr, low = 0, high = arr.length - 1) {
  if (low < high) {
    // Divide: 피벗 기준으로 분할하고 피벗의 최종 위치 반환
    const pivotIndex = partition(arr, low, high);

    // Conquer: 피벗 기준 좌우를 재귀적으로 정렬
    quickSort(arr, low, pivotIndex - 1);
    quickSort(arr, pivotIndex + 1, high);
  }
  return arr;
}

/**
 * Lomuto 파티션 방식
 * 마지막 원소를 피벗으로 선택
 */
function partition(arr, low, high) {
  const pivot = arr[high]; // 피벗: 마지막 원소
  let i = low - 1;         // 작은 원소들의 경계 포인터

  for (let j = low; j < high; j++) {
    if (arr[j] <= pivot) {
      i++;
      [arr[i], arr[j]] = [arr[j], arr[i]]; // swap
    }
  }

  // 피벗을 올바른 위치에 배치
  [arr[i + 1], arr[high]] = [arr[high], arr[i + 1]];
  return i + 1; // 피벗의 최종 인덱스
}

// 실행 예시
const arr = [10, 80, 30, 90, 40, 50, 70];
console.log(quickSort(arr));
// [10, 30, 40, 50, 70, 80, 90]
```

### 피벗 선택 전략

```javascript
// 전략 1: 항상 마지막 원소 (Lomuto) - 이미 정렬된 배열에서 O(n²)
const pivot = arr[high];

// 전략 2: 항상 첫 번째 원소 (Hoare) - 동일한 문제
const pivot = arr[low];

// 전략 3: 랜덤 피벗 - 최악 케이스 확률을 낮춤
function randomPartition(arr, low, high) {
  const randomIndex = low + Math.floor(Math.random() * (high - low + 1));
  [arr[randomIndex], arr[high]] = [arr[high], arr[randomIndex]];
  return partition(arr, low, high);
}

// 전략 4: 세 수의 중앙값 (Median of Three) - 실용적으로 많이 사용
function medianOfThree(arr, low, high) {
  const mid = Math.floor((low + high) / 2);
  // low, mid, high 중 중앙값을 피벗으로
  if (arr[low] > arr[mid]) [arr[low], arr[mid]] = [arr[mid], arr[low]];
  if (arr[low] > arr[high]) [arr[low], arr[high]] = [arr[high], arr[low]];
  if (arr[mid] > arr[high]) [arr[mid], arr[high]] = [arr[high], arr[mid]];
  // mid가 중앙값 → high-1 위치로 이동
  [arr[mid], arr[high - 1]] = [arr[high - 1], arr[mid]];
  return arr[high - 1];
}
```

### 최악 케이스 분석

```
이미 정렬된 배열 [1, 2, 3, 4, 5]에서 마지막 원소를 피벗으로 선택 시:

피벗=5: [1,2,3,4] | [5]   → n-1 비교
피벗=4: [1,2,3]   | [4]   → n-2 비교
피벗=3: [1,2]     | [3]   → n-3 비교
...
총 비교 횟수: (n-1) + (n-2) + ... + 1 = n(n-1)/2 = O(n²)

재귀 깊이도 O(n)이 되어 스택 오버플로우 위험!
```

### 시간/공간복잡도 분석

| 케이스 | 시간복잡도 | 발생 조건 |
|--------|-----------|---------|
| 최선 | O(n log n) | 피벗이 항상 중앙값 |
| 평균 | O(n log n) | 랜덤 입력 |
| 최악 | O(n²) | 이미 정렬된 배열 + 끝 원소 피벗 |

- **공간복잡도**: O(log n) 평균 (재귀 스택), O(n) 최악
- **불안정 정렬(Unstable Sort)**: 동일한 값의 상대적 순서 보장 안됨
- 캐시 지역성(Cache Locality)이 좋아 실제로 매우 빠름

---

## 5. 병합 정렬 vs 퀵 정렬 비교

| 항목 | 병합 정렬 | 퀵 정렬 |
|------|----------|---------|
| 시간복잡도 (최선) | O(n log n) | O(n log n) |
| 시간복잡도 (평균) | O(n log n) | O(n log n) |
| 시간복잡도 (최악) | O(n log n) | O(n²) |
| 공간복잡도 | O(n) | O(log n) 평균 |
| 안정성 | 안정(Stable) | 불안정(Unstable) |
| 제자리 정렬 | 아님 | 맞음 |
| 캐시 효율 | 낮음 | 높음 |
| 실제 성능 | 느린 편 | 빠른 편 |
| 적합한 상황 | 외부 정렬, 안정 정렬 필요 | 일반 내부 정렬 |

> **실무 포인트**: JavaScript의 `Array.prototype.sort()`는 V8 엔진에서 TimSort(병합 정렬 + 삽입 정렬)를 사용한다.

---

## 6. 이진 탐색 - 분할 정복 관점

이진 탐색도 분할 정복의 일종이다. 다만 Combine 단계가 없고 한쪽 부분만 탐색한다.

```javascript
/**
 * 이진 탐색 (재귀 버전) - 분할 정복 구조 명확히 드러남
 * @param {number[]} arr - 정렬된 배열
 * @param {number} target
 * @param {number} low
 * @param {number} high
 * @returns {number} 인덱스 또는 -1
 */
function binarySearch(arr, target, low = 0, high = arr.length - 1) {
  // 기저 사례: 탐색 범위 없음
  if (low > high) return -1;

  // Divide: 중간 지점으로 분할
  const mid = Math.floor((low + high) / 2);

  if (arr[mid] === target) return mid;

  // Conquer: 한쪽 부분만 재귀 탐색 (Combine 단계 없음)
  if (arr[mid] < target) {
    return binarySearch(arr, target, mid + 1, high); // 오른쪽 탐색
  } else {
    return binarySearch(arr, target, low, mid - 1);  // 왼쪽 탐색
  }
}

// T(n) = T(n/2) + O(1) → O(log n)
console.log(binarySearch([1, 3, 5, 7, 9, 11], 7)); // 3
console.log(binarySearch([1, 3, 5, 7, 9, 11], 4)); // -1
```

---

## 7. 큰 수 곱셈 (Karatsuba 알고리즘)

일반적인 n자리 수 곱셈은 O(n²)이지만, Karatsuba 알고리즘은 분할 정복으로 O(n^1.585)를 달성한다.

### 핵심 아이디어

```
x = a * 10^(n/2) + b   (x를 두 부분으로 나눔)
y = c * 10^(n/2) + d

x * y = ac * 10^n + (ad + bc) * 10^(n/2) + bd

일반적: 4번의 곱셈 필요
Karatsuba: 3번의 곱셈으로 가능!

ad + bc = (a+b)(c+d) - ac - bd
→ ac, bd, (a+b)(c+d) 3번만 재귀 계산
```

```javascript
/**
 * Karatsuba 곱셈 (개념 구현, 큰 정수는 BigInt 사용)
 * @param {bigint} x
 * @param {bigint} y
 * @returns {bigint}
 */
function karatsuba(x, y) {
  // 기저 사례: 작은 수는 직접 곱셈
  if (x < 10n || y < 10n) return x * y;

  // 자리수 계산
  const n = BigInt(Math.max(x.toString().length, y.toString().length));
  const half = n / 2n;
  const base = 10n ** half;

  // Divide: 각 수를 두 부분으로 분할
  const a = x / base;
  const b = x % base;
  const c = y / base;
  const d = y % base;

  // Conquer: 3번의 재귀 곱셈
  const ac = karatsuba(a, c);
  const bd = karatsuba(b, d);
  const abcd = karatsuba(a + b, c + d);

  // Combine: Karatsuba 공식 적용
  const adbc = abcd - ac - bd;

  return ac * (base * base) + adbc * base + bd;
}

console.log(karatsuba(1234n, 5678n)); // 7006652n
console.log(1234n * 5678n);           // 7006652n (검증)
```

### 복잡도 비교

| 알고리즘 | 시간복잡도 |
|---------|-----------|
| 초등학교 곱셈 | O(n²) |
| Karatsuba | O(n^1.585) |
| Schönhage–Strassen | O(n log n log log n) |

---

## 8. 면접 포인트

### Q1. 병합 정렬이 항상 O(n log n)인 이유는?

> 분할 단계에서 항상 정확히 절반으로 나누기 때문입니다. 입력 데이터의 상태(정렬 여부)에 관계없이 재귀 트리의 깊이는 항상 log n이고, 각 레벨에서 O(n)의 합병 작업이 일어납니다. 따라서 T(n) = 2T(n/2) + O(n)이고, 마스터 정리에 의해 O(n log n)입니다.

### Q2. 퀵 정렬이 평균적으로 빠른 이유는?

> 1. **제자리 정렬**: 추가 메모리를 거의 사용하지 않아 캐시 효율이 좋습니다.
> 2. **작은 상수 계수**: 실제 비교/이동 횟수가 적습니다.
> 3. **캐시 지역성**: 연속된 메모리 접근 패턴으로 캐시 히트율이 높습니다.

### Q3. 언제 병합 정렬을 선택하고 언제 퀵 정렬을 선택하나요?

> - **병합 정렬 선택**: 안정 정렬이 필요할 때, 외부 정렬(대용량 데이터), 연결 리스트 정렬, 최악 케이스 O(n log n)을 보장해야 할 때
> - **퀵 정렬 선택**: 일반적인 내부 정렬, 메모리가 제한적일 때, 평균 성능이 중요할 때

### Q4. 분할 정복과 동적 프로그래밍의 차이는?

> 분할 정복은 **부분 문제가 독립적**이어서 각 부분 문제를 중복 없이 한 번씩 계산합니다. 동적 프로그래밍은 **부분 문제가 중복**될 때 그 결과를 메모이제이션하여 재사용합니다. 피보나치 계산에서 단순 재귀는 O(2^n)이지만 DP 메모이제이션은 O(n)입니다.

### Q5. 퀵 정렬의 최악 케이스를 방지하는 방법은?

> 1. **랜덤 피벗**: 이미 정렬된 배열에서도 O(n²)이 될 확률이 극히 낮아집니다.
> 2. **Median-of-Three**: 첫, 중간, 마지막 원소의 중앙값을 피벗으로 사용합니다.
> 3. **IntroSort**: 퀵 정렬 시작 후 재귀 깊이가 2*log(n)을 초과하면 힙 정렬로 전환합니다. (C++ STL의 std::sort가 이 방식)

### Q6. 재귀 깊이 문제를 해결하는 방법은?

```javascript
// 꼬리 재귀 최적화를 위해 작은 부분을 재귀, 큰 부분을 반복으로
function quickSortOptimized(arr, low = 0, high = arr.length - 1) {
  while (low < high) {
    const pivotIndex = partition(arr, low, high);

    // 작은 부분을 재귀, 큰 부분을 반복 처리 → 스택 깊이 O(log n) 보장
    if (pivotIndex - low < high - pivotIndex) {
      quickSortOptimized(arr, low, pivotIndex - 1);
      low = pivotIndex + 1;
    } else {
      quickSortOptimized(arr, pivotIndex + 1, high);
      high = pivotIndex - 1;
    }
  }
  return arr;
}
```

---

## 핵심 정리

```
분할 정복 = Divide + Conquer + Combine

병합 정렬:
- 항상 O(n log n), 안정 정렬, O(n) 공간
- 입력 불문 균일한 성능

퀵 정렬:
- 평균 O(n log n), 불안정 정렬, O(log n) 공간
- 피벗 선택이 성능 좌우, 실제로 빠름

이진 탐색:
- T(n) = T(n/2) + O(1) → O(log n)
- Combine 단계 없는 분할 정복
```
