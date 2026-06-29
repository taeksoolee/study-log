# 10. 이진 탐색 (Binary Search)

> 🎨 **[인터랙티브 시각화](./visualizer/08-binary-search.html)** — lo·mid·hi 포인터 이동을 단계별로 확인하세요.

## 목차
1. [개념과 전제 조건](#1-개념과-전제-조건)
2. [기본 구현과 경계 함정](#2-기본-구현과-경계-함정)
3. [lower bound / upper bound](#3-lower-bound--upper-bound)
4. [매개변수 탐색 (Parametric Search)](#4-매개변수-탐색-parametric-search)
5. [예제: 회전 정렬 배열 탐색](#5-예제-회전-정렬-배열-탐색)
6. [시간복잡도와 실수 체크리스트](#6-시간복잡도와-실수-체크리스트)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 개념과 전제 조건

이진 탐색은 **정렬된(혹은 단조성을 가진) 탐색 공간**을 절반씩 줄여 O(log n)에 답을 찾는 기법이다. 핵심 전제는 "어떤 기준에 대해 배열이 `F F F T T T`처럼 한 번만 바뀌는 단조성"을 가진다는 것.

```
선형 탐색 O(n)  vs  이진 탐색 O(log n)
n = 1,000,000 → 최악 100만 번  vs  약 20번
```

탐색 대상은 배열의 *값*일 수도 있고(고전적), "답이 될 수 있는 후보 범위"일 수도 있다(매개변수 탐색).

---

## 2. 기본 구현과 경계 함정

```javascript
// 값 target의 인덱스 반환, 없으면 -1
function binarySearch(arr, target) {
  let lo = 0, hi = arr.length - 1;     // 닫힌 구간 [lo, hi]
  while (lo <= hi) {                    // 등호 주의: 원소 1개도 검사해야 함
    const mid = lo + ((hi - lo) >> 1);  // (lo+hi)/2 오버플로 회피 관습
    if (arr[mid] === target) return mid;
    if (arr[mid] < target) lo = mid + 1;
    else hi = mid - 1;
  }
  return -1;
}
```

**3대 함정:**
1. `lo <= hi` vs `lo < hi` — 구간 정의(닫힘/반열림)와 짝을 맞춰야 무한 루프를 피한다.
2. `mid = (lo + hi) / 2`는 큰 수에서 오버플로 위험 → `lo + (hi - lo)/2`. (JS는 Number라 덜 치명적이지만 습관화.)
3. 경계 갱신 `mid + 1` / `mid - 1`을 빼먹으면 무한 루프.

> JS엔 내장 이진 탐색이 없다. `Array.prototype.indexOf`는 O(n) 선형이므로 정렬 배열이라도 직접 구현해야 log 시간을 얻는다.

---

## 3. lower bound / upper bound

중복이 있는 배열에서 "target이 들어갈 위치"를 찾는 변형. 코테에서 기본 탐색보다 훨씬 자주 쓰인다.

```javascript
// lower bound: target 이상(>=)이 처음 나오는 인덱스
function lowerBound(arr, target) {
  let lo = 0, hi = arr.length;   // 반열림 [lo, hi)
  while (lo < hi) {
    const mid = lo + ((hi - lo) >> 1);
    if (arr[mid] < target) lo = mid + 1;
    else hi = mid;               // arr[mid] >= target → 후보 유지
  }
  return lo;                      // 0 ~ arr.length
}

// upper bound: target 초과(>)가 처음 나오는 인덱스
function upperBound(arr, target) {
  let lo = 0, hi = arr.length;
  while (lo < hi) {
    const mid = lo + ((hi - lo) >> 1);
    if (arr[mid] <= target) lo = mid + 1;
    else hi = mid;
  }
  return lo;
}

// target의 개수 = upperBound - lowerBound
```

> `lowerBound`와 `upperBound`만 정확히 외워두면 "이상/초과/이하/미만/개수/삽입위치" 질문을 전부 커버한다.

---

## 4. 매개변수 탐색 (Parametric Search)

"최대/최소 X를 구하라" 문제를 **"X가 가능한가?"라는 결정 문제(boolean)로 바꿔** 답의 범위를 이진 탐색한다. 결정 함수가 단조(`가능 가능 … 불가능` 또는 그 반대)일 때 적용한다. 코테 고난도 단골.

```javascript
// 예: 나무를 H로 잘라 M미터 이상 얻는 최대 절단 높이 (백준 '나무 자르기' 류)
function maxCutHeight(trees, need) {
  let lo = 0, hi = Math.max(...trees);
  let answer = 0;
  while (lo <= hi) {
    const h = lo + ((hi - lo) >> 1);
    const got = trees.reduce((s, t) => s + Math.max(0, t - h), 0); // 결정: 충분?
    if (got >= need) {      // 가능 → 더 높게(욕심) 시도
      answer = h;
      lo = h + 1;
    } else {                // 불가능 → 낮춰야
      hi = h - 1;
    }
  }
  return answer;
}
```

> 신호: "최댓값을 최소화", "최솟값을 최대화", "K개로 나눌 때…" 같은 문구가 보이면 매개변수 탐색을 의심하라. 답 후보 범위에 대해 단조 결정 함수를 세우는 게 핵심.

---

## 5. 예제: 회전 정렬 배열 탐색

정렬 후 회전된 배열(`[4,5,6,7,0,1,2]`)에서 target 찾기. 한쪽 절반은 항상 정렬돼 있다는 성질을 이용.

```javascript
function searchRotated(nums, target) {
  let lo = 0, hi = nums.length - 1;
  while (lo <= hi) {
    const mid = lo + ((hi - lo) >> 1);
    if (nums[mid] === target) return mid;
    if (nums[lo] <= nums[mid]) {            // 왼쪽 절반이 정렬됨
      if (nums[lo] <= target && target < nums[mid]) hi = mid - 1;
      else lo = mid + 1;
    } else {                                 // 오른쪽 절반이 정렬됨
      if (nums[mid] < target && target <= nums[hi]) lo = mid + 1;
      else hi = mid - 1;
    }
  }
  return -1;
}
```

---

## 6. 시간복잡도와 실수 체크리스트

| 연산 | 복잡도 |
|------|--------|
| 탐색 | O(log n) |
| 정렬 후 탐색(1회) | O(n log n) + O(log n) |
| 매개변수 탐색 | O(log(범위) × 결정함수비용) |

체크리스트:
- 배열이 **정렬돼 있는가?**(아니면 먼저 정렬하거나 단조 결정함수를 세운다)
- 구간 정의(`[lo,hi]` vs `[lo,hi)`)와 루프 조건/갱신이 일관적인가?
- 답이 인덱스인지 값인지, "이상/초과" 중 무엇인지 명확한가?

---

## 7. 면접 포인트

**Q. 이진 탐색의 전제 조건은?**
> 탐색 공간이 정렬돼 있거나, 어떤 기준에 대해 단조성(`F…F T…T`)을 가져야 한다. 그래야 절반을 안전하게 버릴 수 있다.

**Q. `lo <= hi`와 `lo < hi`는 언제 쓰나요?**
> 닫힌 구간 `[lo, hi]`로 특정 값을 찾을 땐 원소 1개도 검사하려고 `lo <= hi`를 쓰고, 반열림 `[lo, hi)`로 경계(lower/upper bound)를 찾을 땐 `lo < hi`를 쓴다. 구간 정의와 조건·갱신을 일관되게 맞추는 게 무한 루프를 피하는 핵심이다.

**Q. lower bound와 upper bound의 차이는?**
> lower bound는 target *이상*이 처음 나오는 위치, upper bound는 target *초과*가 처음 나오는 위치다. 두 값의 차이가 target의 개수이며, 중복 원소·삽입 위치 문제를 모두 이걸로 푼다.

**Q. 매개변수 탐색(parametric search)이란?**
> "최대/최소 X" 최적화 문제를 "X가 가능한가?"라는 단조 결정 문제로 변환해 답의 범위를 이진 탐색하는 기법. "최댓값을 최소화", "K개로 나눌 때 최소…" 같은 문구가 신호다. 복잡도는 O(log(범위) × 결정함수 비용).

**Q. JS로 정렬된 배열을 빠르게 탐색하려면?**
> `indexOf`/`includes`는 O(n) 선형이라 정렬 배열의 이점을 못 살린다. 내장 이진 탐색이 없으므로 직접 구현해 O(log n)을 얻어야 한다.
