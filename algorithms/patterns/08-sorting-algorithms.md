# 8. 정렬 알고리즘 완전 정복

## 목차

1. 정렬 알고리즘 분류
2. 비교 기반 정렬
   - Bubble Sort
   - Selection Sort
   - Insertion Sort
   - Merge Sort
   - Quick Sort
   - Heap Sort
3. 비비교 기반 정렬
   - Counting Sort
   - Radix Sort
4. Tim Sort (JavaScript 내장)
5. 알고리즘 비교 표
6. JS `Array.sort()` 동작 방식과 주의사항
7. 실무 판단 기준
8. 면접 포인트

---

## 1. 정렬 알고리즘 분류

```
정렬 알고리즘
├── 비교 기반 (Comparison-based)  → 하한: O(n log n)
│   ├── 단순 정렬: Bubble, Selection, Insertion
│   └── 효율 정렬: Merge, Quick, Heap, Tim
└── 비비교 기반 (Non-comparison-based)  → O(n+k) 가능
    ├── Counting Sort
    ├── Radix Sort
    └── Bucket Sort
```

**안정 정렬(Stable Sort)**: 동일한 키 값의 원소들이 정렬 후에도 원래 순서를 유지.
→ Bubble, Insertion, Merge, Tim Sort가 안정 정렬.

---

## 2. 비교 기반 정렬

### 2-1. Bubble Sort

인접한 두 원소를 비교하며 큰 값을 뒤로 밀어내는 방식.

```js
// 기본 버전
function bubbleSort(arr) {
  const n = arr.length;
  for (let i = 0; i < n - 1; i++) {
    for (let j = 0; j < n - 1 - i; j++) {
      if (arr[j] > arr[j + 1]) {
        [arr[j], arr[j + 1]] = [arr[j + 1], arr[j]];
      }
    }
  }
  return arr;
}

// 최적화 버전 — 이미 정렬된 경우 조기 종료
function bubbleSortOptimized(arr) {
  const n = arr.length;
  for (let i = 0; i < n - 1; i++) {
    let swapped = false;
    for (let j = 0; j < n - 1 - i; j++) {
      if (arr[j] > arr[j + 1]) {
        [arr[j], arr[j + 1]] = [arr[j + 1], arr[j]];
        swapped = true;
      }
    }
    if (!swapped) break; // 교환이 없으면 이미 정렬됨
  }
  return arr;
}
```

| 복잡도 | 값 |
|---|---|
| 시간 (최선) | O(n) — 최적화 버전, 이미 정렬된 경우 |
| 시간 (평균/최악) | O(n²) |
| 공간 | O(1) |

**언제 쓰는가**: 거의 쓰지 않음. 교육 목적. 데이터가 이미 거의 정렬된 소규모 배열에서는 최적화 버전이 빠를 수 있음.

---

### 2-2. Selection Sort

매 순회마다 최솟값을 찾아 앞으로 이동.

```js
function selectionSort(arr) {
  const n = arr.length;
  for (let i = 0; i < n - 1; i++) {
    let minIdx = i;
    for (let j = i + 1; j < n; j++) {
      if (arr[j] < arr[minIdx]) {
        minIdx = j;
      }
    }
    if (minIdx !== i) {
      [arr[i], arr[minIdx]] = [arr[minIdx], arr[i]];
    }
  }
  return arr;
}
```

| 복잡도 | 값 |
|---|---|
| 시간 (최선/평균/최악) | O(n²) |
| 공간 | O(1) |

**언제 쓰는가**: 교환 횟수를 최소화해야 할 때 (쓰기 비용이 큰 저장매체). 안정 정렬이 아님에 주의.

---

### 2-3. Insertion Sort

카드 게임처럼 정렬된 부분에 새 원소를 적절한 위치에 삽입.

```js
function insertionSort(arr) {
  for (let i = 1; i < arr.length; i++) {
    const key = arr[i];
    let j = i - 1;
    while (j >= 0 && arr[j] > key) {
      arr[j + 1] = arr[j];
      j--;
    }
    arr[j + 1] = key;
  }
  return arr;
}
```

| 복잡도 | 값 |
|---|---|
| 시간 (최선) | O(n) — 이미 정렬된 경우 |
| 시간 (평균/최악) | O(n²) |
| 공간 | O(1) |

**언제 쓰는가**:
- 거의 정렬된(nearly sorted) 배열 → 실질적으로 O(n)에 가까움.
- 소규모 배열(n < 20) → 오버헤드가 적어 Merge/Quick보다 빠를 수 있음.
- Tim Sort 내부에서 소규모 청크 정렬에 활용됨.

---

### 2-4. Merge Sort

분할 정복(Divide & Conquer). 배열을 반으로 나눠 재귀 정렬 후 병합.

```js
function mergeSort(arr) {
  if (arr.length <= 1) return arr;

  const mid = Math.floor(arr.length / 2);
  const left = mergeSort(arr.slice(0, mid));
  const right = mergeSort(arr.slice(mid));

  return merge(left, right);
}

function merge(left, right) {
  const result = [];
  let i = 0, j = 0;

  while (i < left.length && j < right.length) {
    if (left[i] <= right[j]) {
      result.push(left[i++]);
    } else {
      result.push(right[j++]);
    }
  }

  return result.concat(left.slice(i)).concat(right.slice(j));
}

// 예시
console.log(mergeSort([5, 3, 8, 4, 2])); // [2, 3, 4, 5, 8]
```

| 복잡도 | 값 |
|---|---|
| 시간 (최선/평균/최악) | O(n log n) — 항상 일정 |
| 공간 | O(n) |

**언제 쓰는가**:
- 안정 정렬이 필요할 때.
- 연결 리스트(LinkedList) 정렬 — 인덱스 접근 없이 포인터 조작만으로 O(1) 공간 병합 가능.
- 외부 정렬(External Sort) — 디스크 기반 대용량 데이터.
- 최악 성능도 O(n log n)을 보장해야 할 때.

---

### 2-5. Quick Sort

피벗을 기준으로 작은 값은 왼쪽, 큰 값은 오른쪽으로 분할하며 재귀 정렬.

```js
// 피벗 전략 1: 마지막 원소를 피벗으로
function quickSortLast(arr, low = 0, high = arr.length - 1) {
  if (low < high) {
    const pivotIdx = partition(arr, low, high);
    quickSortLast(arr, low, pivotIdx - 1);
    quickSortLast(arr, pivotIdx + 1, high);
  }
  return arr;
}

function partition(arr, low, high) {
  const pivot = arr[high];
  let i = low - 1;

  for (let j = low; j < high; j++) {
    if (arr[j] <= pivot) {
      i++;
      [arr[i], arr[j]] = [arr[j], arr[i]];
    }
  }
  [arr[i + 1], arr[high]] = [arr[high], arr[i + 1]];
  return i + 1;
}

// 피벗 전략 2: 랜덤 피벗 — 최악 케이스 방지
function quickSortRandom(arr, low = 0, high = arr.length - 1) {
  if (low < high) {
    const randIdx = Math.floor(Math.random() * (high - low + 1)) + low;
    [arr[randIdx], arr[high]] = [arr[high], arr[randIdx]];
    const pivotIdx = partition(arr, low, high);
    quickSortRandom(arr, low, pivotIdx - 1);
    quickSortRandom(arr, pivotIdx + 1, high);
  }
  return arr;
}

// 피벗 전략 3: Median-of-Three — 첫/중간/마지막 중 중앙값
function medianOfThree(arr, low, high) {
  const mid = Math.floor((low + high) / 2);
  if (arr[low] > arr[mid]) [arr[low], arr[mid]] = [arr[mid], arr[low]];
  if (arr[low] > arr[high]) [arr[low], arr[high]] = [arr[high], arr[low]];
  if (arr[mid] > arr[high]) [arr[mid], arr[high]] = [arr[high], arr[mid]];
  // mid가 중앙값이 됨 → high 위치로 이동해서 피벗으로 사용
  [arr[mid], arr[high]] = [arr[high], arr[mid]];
  return arr[high];
}
```

| 복잡도 | 값 |
|---|---|
| 시간 (최선/평균) | O(n log n) |
| 시간 (최악) | O(n²) — 이미 정렬된 배열에 항상 첫/마지막 피벗 선택 시 |
| 공간 | O(log n) — 재귀 스택 |

**피벗 전략 비교**:
- 첫/마지막 원소: 구현 단순, 정렬된 배열에서 O(n²)
- 랜덤 피벗: 평균적으로 O(n log n) 기대값 유지
- Median-of-Three: 실무에서 가장 많이 쓰이는 균형 잡힌 전략

**언제 쓰는가**:
- 캐시 효율이 좋아 실제로는 Merge Sort보다 빠른 경우 많음.
- 추가 메모리가 제한될 때 (in-place).
- 안정 정렬이 필요 없을 때.

---

### 2-6. Heap Sort

최대 힙(Max Heap)을 구성한 뒤 루트(최댓값)를 꺼내며 정렬.

```js
function heapSort(arr) {
  const n = arr.length;

  // 1단계: 최대 힙 구성 (heapify)
  for (let i = Math.floor(n / 2) - 1; i >= 0; i--) {
    heapify(arr, n, i);
  }

  // 2단계: 루트를 마지막과 교환하며 힙 크기 줄이기
  for (let i = n - 1; i > 0; i--) {
    [arr[0], arr[i]] = [arr[i], arr[0]];
    heapify(arr, i, 0);
  }

  return arr;
}

function heapify(arr, n, i) {
  let largest = i;
  const left = 2 * i + 1;
  const right = 2 * i + 2;

  if (left < n && arr[left] > arr[largest]) largest = left;
  if (right < n && arr[right] > arr[largest]) largest = right;

  if (largest !== i) {
    [arr[i], arr[largest]] = [arr[largest], arr[i]];
    heapify(arr, n, largest);
  }
}
```

| 복잡도 | 값 |
|---|---|
| 시간 (최선/평균/최악) | O(n log n) — 항상 일정 |
| 공간 | O(1) — in-place |

**언제 쓰는가**:
- O(n log n) 보장 + O(1) 공간이 동시에 필요할 때.
- 단, 캐시 지역성이 나빠 Quick Sort보다 실제 속도는 느린 경우가 많음.
- Top-K 문제 해결 시 우선순위 큐(힙) 자료구조와 함께 활용.

---

## 3. 비비교 기반 정렬

### 3-1. Counting Sort

값의 등장 횟수를 세어 정렬. 값의 범위(k)가 작을 때 O(n+k).

```js
function countingSort(arr) {
  if (arr.length === 0) return arr;

  const max = Math.max(...arr);
  const min = Math.min(...arr);
  const range = max - min + 1;
  const count = new Array(range).fill(0);
  const output = new Array(arr.length);

  // 빈도 계산
  for (const num of arr) {
    count[num - min]++;
  }

  // 누적 합
  for (let i = 1; i < range; i++) {
    count[i] += count[i - 1];
  }

  // 역순으로 배치 (안정 정렬 보장)
  for (let i = arr.length - 1; i >= 0; i--) {
    output[count[arr[i] - min] - 1] = arr[i];
    count[arr[i] - min]--;
  }

  return output;
}

// 예시: 점수 정렬 (0~100)
console.log(countingSort([4, 2, 2, 8, 3, 3, 1])); // [1, 2, 2, 3, 3, 4, 8]
```

| 복잡도 | 값 |
|---|---|
| 시간 | O(n + k) — k: 값의 범위 |
| 공간 | O(k) |

**언제 쓰는가**: 정수이고 값의 범위(k)가 n에 비해 크지 않을 때. 예) 성적 분포, 나이 분포.

---

### 3-2. Radix Sort

자릿수(digit)별로 Counting Sort를 반복 적용.

```js
function radixSort(arr) {
  const max = Math.max(...arr);
  let exp = 1;

  while (Math.floor(max / exp) > 0) {
    countingSortByDigit(arr, exp);
    exp *= 10;
  }

  return arr;
}

function countingSortByDigit(arr, exp) {
  const n = arr.length;
  const output = new Array(n);
  const count = new Array(10).fill(0);

  for (let i = 0; i < n; i++) {
    const digit = Math.floor(arr[i] / exp) % 10;
    count[digit]++;
  }

  for (let i = 1; i < 10; i++) {
    count[i] += count[i - 1];
  }

  for (let i = n - 1; i >= 0; i--) {
    const digit = Math.floor(arr[i] / exp) % 10;
    output[count[digit] - 1] = arr[i];
    count[digit]--;
  }

  for (let i = 0; i < n; i++) {
    arr[i] = output[i];
  }
}

// 예시
console.log(radixSort([170, 45, 75, 90, 802, 24, 2, 66]));
// [2, 24, 45, 66, 75, 90, 170, 802]
```

| 복잡도 | 값 |
|---|---|
| 시간 | O(d × (n + k)) — d: 자릿수, k: 기수(10) |
| 공간 | O(n + k) |

**언제 쓰는가**: 큰 정수 배열, 고정 길이 문자열 정렬. 값의 범위가 커도 자릿수(d)가 작으면 효율적.

---

## 4. Tim Sort (JavaScript 내장)

Tim Sort는 Merge Sort + Insertion Sort의 하이브리드로, Python과 JavaScript(V8 엔진)에서 `Array.prototype.sort`의 내부 구현으로 사용됨.

**핵심 아이디어**:
1. 배열을 작은 청크(run, 보통 32~64개 원소)로 나눔.
2. 각 청크는 Insertion Sort로 정렬 (소규모에서 빠름).
3. 청크들을 Merge Sort 방식으로 병합.
4. 이미 정렬된 구간(natural run)을 감지해 활용.

| 복잡도 | 값 |
|---|---|
| 시간 (최선) | O(n) — 이미 정렬된 경우 |
| 시간 (평균/최악) | O(n log n) |
| 공간 | O(n) |
| 안정 정렬 | O |

**실제 데이터에서 매우 빠른 이유**: 실세계 데이터는 완전 랜덤이 아니라 부분적으로 정렬된 구간이 많음 → natural run 활용으로 병합 횟수 최소화.

---

## 5. 알고리즘 비교 표

| 알고리즘 | 최선 | 평균 | 최악 | 공간 | 안정 | 비고 |
|---|---|---|---|---|---|---|
| Bubble Sort | O(n) | O(n²) | O(n²) | O(1) | O | 거의 미사용 |
| Selection Sort | O(n²) | O(n²) | O(n²) | O(1) | X | 교환 횟수 최소 |
| Insertion Sort | O(n) | O(n²) | O(n²) | O(1) | O | 소규모/거의 정렬됨 |
| Merge Sort | O(n log n) | O(n log n) | O(n log n) | O(n) | O | 연결 리스트, 외부 정렬 |
| Quick Sort | O(n log n) | O(n log n) | O(n²) | O(log n) | X | 실무 고성능 |
| Heap Sort | O(n log n) | O(n log n) | O(n log n) | O(1) | X | 메모리 제한 |
| Counting Sort | O(n+k) | O(n+k) | O(n+k) | O(k) | O | 정수, 범위 작을 때 |
| Radix Sort | O(dn) | O(dn) | O(dn) | O(n+k) | O | 큰 정수, 문자열 |
| Tim Sort | O(n) | O(n log n) | O(n log n) | O(n) | O | JS/Python 내장 |

---

## 6. JS `Array.sort()` 동작 방식과 주의사항

### 기본 동작

```js
// 주의: 기본 sort는 요소를 문자열로 변환하여 비교
[10, 9, 2, 1, 100].sort();
// → [1, 10, 100, 2, 9]  ← 사전순(lexicographic) 정렬!

// 숫자 정렬 시 반드시 compareFn 사용
[10, 9, 2, 1, 100].sort((a, b) => a - b);
// → [1, 2, 9, 10, 100]  ← 올바른 오름차순

[10, 9, 2, 1, 100].sort((a, b) => b - a);
// → [100, 10, 9, 2, 1]  ← 내림차순
```

### compareFn 반환값 규칙

```js
// compareFn(a, b)의 반환값:
// < 0 → a가 b보다 앞
// = 0 → 순서 유지
// > 0 → b가 a보다 앞

// 객체 배열 정렬
const users = [
  { name: 'Charlie', age: 25 },
  { name: 'Alice', age: 30 },
  { name: 'Bob', age: 20 },
];

users.sort((a, b) => a.age - b.age);
// → [Bob(20), Charlie(25), Alice(30)]

// 문자열 정렬 (다국어 포함)
const names = ['banana', 'Apple', 'cherry'];
names.sort((a, b) => a.localeCompare(b));
// → ['Apple', 'banana', 'cherry']
```

### V8 엔진에서 Tim Sort 적용 (Node.js 11+, Chrome 70+)

```js
// 안정 정렬이 보장됨 (이전 버전은 보장 안 됨)
const items = [
  { id: 1, priority: 1 },
  { id: 2, priority: 1 },
  { id: 3, priority: 2 },
];
items.sort((a, b) => a.priority - b.priority);
// id:1, id:2 순서 유지됨 (stable sort)
```

---

## 7. 실무 판단 기준

### 내장 `Array.sort()` 사용하는 경우 (대부분의 경우)

- 일반적인 배열 정렬 → 항상 내장 sort 사용.
- Tim Sort 기반으로 실용적으로 가장 빠름.
- 코드 가독성, 유지보수성 우선.

### 직접 구현을 고려하는 경우

```
1. 정렬 알고리즘 제어가 필요할 때
   - Quick Sort의 피벗 전략을 데이터 특성에 맞게 튜닝.
   - 외부 정렬(파일/DB 기반 대용량 데이터).

2. 특수한 성능 요구사항
   - 값 범위가 좁은 정수 → Counting Sort로 O(n) 달성.
   - 고정 자릿수 데이터 → Radix Sort.

3. 알고리즘 면접 / 코딩 테스트
   - 정렬 알고리즘 자체가 문제의 핵심인 경우.

4. 거의 정렬된 데이터 스트리밍
   - Insertion Sort가 Tim Sort보다 간단하고 동일한 성능.
```

---

## 8. 면접 포인트

**Q. Tim Sort가 무엇인지 설명해주세요.**

Tim Sort는 Merge Sort와 Insertion Sort를 결합한 하이브리드 알고리즘입니다. 배열을 작은 청크(run)로 나눠 Insertion Sort로 정렬한 뒤, Merge Sort로 병합합니다. 실세계 데이터의 부분적으로 정렬된 특성을 활용해 최선 O(n), 평균/최악 O(n log n)을 달성하며, 안정 정렬입니다. JavaScript의 `Array.prototype.sort`와 Python의 `list.sort()`에서 사용됩니다.

**Q. 안정 정렬(Stable Sort)이란 무엇인가요?**

동일한 키 값을 가진 원소들이 정렬 후에도 원래의 상대적 순서를 유지하는 것입니다. 예를 들어 나이로 정렬할 때 같은 나이인 사람들의 원래 순서가 유지됩니다. Bubble, Insertion, Merge, Tim Sort가 안정 정렬이며, Selection, Quick, Heap Sort는 불안정 정렬입니다.

**Q. Quick Sort의 최악 케이스는 언제이며 어떻게 방지하나요?**

이미 정렬된 배열에서 항상 첫 번째 또는 마지막 원소를 피벗으로 선택하면 분할이 1:n-1로 치우쳐 O(n²)이 됩니다. 방지 방법으로는 랜덤 피벗 선택, Median-of-Three 전략, 또는 Introsort(Quick Sort + Heap Sort 혼합) 사용이 있습니다.

**Q. Merge Sort vs Quick Sort 어떤 것을 선택하나요?**

- 안정 정렬이 필요하거나 연결 리스트를 정렬할 때 → Merge Sort.
- 최악 성능을 O(n log n)으로 보장해야 할 때 → Merge Sort.
- 추가 메모리를 최소화하고 캐시 효율을 높여야 할 때 → Quick Sort.
- 실무 일반 배열 정렬 → 내장 sort (Tim Sort) 사용.

**Q. JS `Array.sort()`에서 숫자 정렬 시 왜 compareFn이 필요한가요?**

`Array.sort()`는 기본적으로 요소를 문자열로 변환해 사전순(lexicographic) 비교를 합니다. 따라서 `[10, 9, 2]`를 정렬하면 `[10, 2, 9]`가 됩니다("1" < "2" < "9"). 숫자 비교를 위해 `(a, b) => a - b`처럼 compareFn을 명시해야 합니다.
