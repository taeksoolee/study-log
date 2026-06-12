# 1. 배열과 문자열 (Array & String)

## 목차
1. 배열 기본 연산 시간복잡도
2. JavaScript 배열 메서드 정리
3. 문자열 조작
4. 자주 나오는 패턴
   - 빈도 카운팅
   - 투 포인터 기초
   - 슬라이딩 윈도우 기초
   - 아나그램 체크
5. 면접 포인트

---

## 1. 배열 기본 연산 시간복잡도

배열(Array)은 연속된 메모리 공간에 데이터를 저장하는 자료구조입니다.
인덱스를 통해 O(1)로 임의 접근이 가능하지만, 삽입/삭제는 요소를 이동시켜야 하므로 비용이 발생합니다.

| 연산           | 시간복잡도 | 설명                                    |
|---------------|------------|----------------------------------------|
| 접근 (Access)  | O(1)       | 인덱스로 직접 접근                      |
| 검색 (Search)  | O(n)       | 순차 탐색 (정렬 시 이진 탐색 O(log n))  |
| 끝에 삽입       | O(1)*      | push — amortized O(1)                  |
| 앞에 삽입       | O(n)       | unshift — 모든 요소를 한 칸씩 뒤로 이동 |
| 중간 삽입       | O(n)       | splice — 삽입 이후 요소를 이동          |
| 끝에서 삭제     | O(1)       | pop                                    |
| 앞에서 삭제     | O(n)       | shift — 모든 요소를 한 칸씩 앞으로 이동 |
| 중간 삭제       | O(n)       | splice — 삭제 이후 요소를 이동          |

> *동적 배열(JavaScript Array)은 용량 초과 시 내부적으로 재할당(resize)이 발생하지만, 평균적으로 O(1)로 취급합니다.

---

## 2. JavaScript 배열 메서드 정리

### 2-1. 기본 변형 메서드

```js
const arr = [1, 2, 3, 4, 5];

// push / pop — 배열 끝 조작 O(1)
arr.push(6);         // [1, 2, 3, 4, 5, 6]
arr.pop();           // [1, 2, 3, 4, 5]  반환값: 6

// unshift / shift — 배열 앞 조작 O(n)
arr.unshift(0);      // [0, 1, 2, 3, 4, 5]
arr.shift();         // [1, 2, 3, 4, 5]  반환값: 0

// splice(start, deleteCount, ...items) — 중간 삽입/삭제 O(n)
arr.splice(2, 1);         // 인덱스 2에서 1개 삭제 → [1, 2, 4, 5]
arr.splice(2, 0, 3);      // 인덱스 2에 3 삽입    → [1, 2, 3, 4, 5]

// slice(start, end) — 부분 복사 (원본 불변) O(k), k=복사 개수
const sliced = arr.slice(1, 4); // [2, 3, 4]
```

### 2-2. 탐색 메서드

```js
const arr = [10, 20, 30, 20, 40];

// indexOf — 값으로 첫 번째 인덱스 탐색 O(n)
arr.indexOf(20);          // 1
arr.indexOf(99);          // -1 (없으면 -1)
arr.lastIndexOf(20);      // 3

// findIndex — 조건 함수로 첫 번째 인덱스 탐색 O(n)
arr.findIndex(x => x > 25);   // 2

// find — 조건에 맞는 첫 번째 값 반환 O(n)
arr.find(x => x > 25);        // 30

// includes — 포함 여부 boolean O(n)
arr.includes(20);         // true
arr.includes(99);         // false
```

### 2-3. 고차 함수 메서드

```js
const nums = [1, 2, 3, 4, 5];

// filter — 조건에 맞는 요소만 새 배열로 반환 O(n)
const evens = nums.filter(x => x % 2 === 0); // [2, 4]

// map — 각 요소를 변환한 새 배열 반환 O(n)
const doubled = nums.map(x => x * 2); // [2, 4, 6, 8, 10]

// reduce — 배열을 단일 값으로 누적 O(n)
const sum = nums.reduce((acc, cur) => acc + cur, 0); // 15

// forEach — 반환값 없이 순회 O(n)
nums.forEach((val, idx) => console.log(idx, val));

// some / every — 조건 검사 O(n)
nums.some(x => x > 4);   // true
nums.every(x => x > 0);  // true

// flat / flatMap — 중첩 배열 펼치기 O(n)
[[1, 2], [3, 4]].flat();              // [1, 2, 3, 4]
[[1], [2]].flatMap(x => x.map(v => v * 2)); // [2, 4]
```

### 2-4. 정렬 및 기타

```js
const arr = [3, 1, 4, 1, 5, 9];

// sort — 기본은 문자열 정렬이므로 비교 함수 필수 O(n log n)
arr.sort((a, b) => a - b);    // 오름차순: [1, 1, 3, 4, 5, 9]
arr.sort((a, b) => b - a);    // 내림차순: [9, 5, 4, 3, 1, 1]

// reverse — 배열 역순 (in-place) O(n)
arr.reverse();

// concat — 배열 합치기 (새 배열 반환) O(n)
[1, 2].concat([3, 4]); // [1, 2, 3, 4]

// Array.from — 유사 배열/이터러블을 배열로 변환
Array.from({ length: 5 }, (_, i) => i); // [0, 1, 2, 3, 4]
Array.from('hello');                      // ['h', 'e', 'l', 'l', 'o']

// spread 연산자로 복사
const copy = [...arr];
```

---

## 3. 문자열 조작

JavaScript에서 문자열은 불변(immutable)입니다. 모든 조작은 새로운 문자열을 반환합니다.

```js
const str = 'Hello, World!';

// split — 문자열을 배열로 분리 O(n)
str.split(', ');        // ['Hello', 'World!']
str.split('');          // 각 문자 배열로 분리
'a b c'.split(' ');     // ['a', 'b', 'c']

// join — 배열을 문자열로 합치기 O(n)
['a', 'b', 'c'].join('-');  // 'a-b-c'
['a', 'b', 'c'].join('');   // 'abc'

// 문자열 뒤집기 — split + reverse + join 패턴
const reversed = str.split('').reverse().join('');

// substring(start, end) — 부분 문자열 추출
str.substring(0, 5);    // 'Hello'
str.substring(7);       // 'World!'

// slice(start, end) — 음수 인덱스 지원
str.slice(0, 5);        // 'Hello'
str.slice(-6);          // 'World!'
str.slice(-6, -1);      // 'World'

// includes / startsWith / endsWith O(n)
str.includes('World');       // true
str.startsWith('Hello');     // true
str.endsWith('!');           // true

// indexOf / lastIndexOf — 부분 문자열 위치
str.indexOf('l');            // 2
str.lastIndexOf('l');        // 10

// replace / replaceAll
'aabbcc'.replace('b', 'X');     // 'aXbbcc' — 첫 번째만
'aabbcc'.replaceAll('b', 'X');  // 'aaXXcc' — 전체

// toLowerCase / toUpperCase
str.toLowerCase();   // 'hello, world!'
str.toUpperCase();   // 'HELLO, WORLD!'

// trim — 앞뒤 공백 제거
'  hello  '.trim();        // 'hello'
'  hello  '.trimStart();   // 'hello  '
'  hello  '.trimEnd();     // '  hello'

// padStart / padEnd — 패딩 추가
'5'.padStart(3, '0');   // '005'
'5'.padEnd(3, '0');     // '500'

// repeat
'ab'.repeat(3);   // 'ababab'

// charAt / charCodeAt / String.fromCharCode
str.charAt(0);                  // 'H'
str.charCodeAt(0);              // 72
String.fromCharCode(72);        // 'H'
```

---

## 4. 자주 나오는 패턴

### 4-1. 빈도 카운팅 (Frequency Counter)

배열이나 문자열에서 각 요소의 등장 횟수를 객체(Map)로 집계하는 패턴입니다.
두 배열/문자열을 비교할 때 중첩 루프 O(n²)를 O(n)으로 줄일 수 있습니다.

**예제: 두 배열의 제곱 관계 확인**

```js
// arr1의 각 요소의 제곱이 arr2에 동일 빈도로 있는지 확인
function sameSquared(arr1, arr2) {
  if (arr1.length !== arr2.length) return false;

  const freq1 = {};
  const freq2 = {};

  for (const val of arr1) {
    freq1[val] = (freq1[val] || 0) + 1;
  }
  for (const val of arr2) {
    freq2[val] = (freq2[val] || 0) + 1;
  }

  for (const key in freq1) {
    const squared = key ** 2;
    if (!freq2[squared]) return false;
    if (freq2[squared] !== freq1[key]) return false;
  }

  return true;
}

console.log(sameSquared([1, 2, 3], [4, 1, 9]));  // true
console.log(sameSquared([1, 2, 3], [1, 9]));      // false
```

**예제: 문자 빈도 카운팅**

```js
function charFrequency(str) {
  const freq = {};
  for (const ch of str) {
    freq[ch] = (freq[ch] || 0) + 1;
  }
  return freq;
}

console.log(charFrequency('hello'));
// { h: 1, e: 1, l: 2, o: 1 }
```

---

### 4-2. 투 포인터 기초 (Two Pointer)

정렬된 배열이나 문자열에서 두 개의 포인터를 양 끝에서 시작하거나
같은 방향으로 이동시켜 조건을 만족하는 쌍을 탐색하는 패턴입니다.
중첩 루프 O(n²)를 O(n)으로 줄일 수 있습니다.

**예제: 정렬된 배열에서 합이 target인 두 수 찾기**

```js
function twoSum(sortedArr, target) {
  let left = 0;
  let right = sortedArr.length - 1;

  while (left < right) {
    const sum = sortedArr[left] + sortedArr[right];

    if (sum === target) {
      return [left, right];
    } else if (sum < target) {
      left++;   // 합이 작으면 왼쪽 포인터를 오른쪽으로
    } else {
      right--;  // 합이 크면 오른쪽 포인터를 왼쪽으로
    }
  }

  return null;
}

console.log(twoSum([1, 2, 3, 5, 8], 10)); // [2, 4] → 3+8=11? 아니면...
console.log(twoSum([1, 3, 5, 7, 9], 12)); // [1, 4] → 3+9=12
```

**예제: 회문(Palindrome) 확인**

```js
function isPalindrome(str) {
  let left = 0;
  let right = str.length - 1;

  while (left < right) {
    if (str[left] !== str[right]) return false;
    left++;
    right--;
  }

  return true;
}

console.log(isPalindrome('racecar')); // true
console.log(isPalindrome('hello'));   // false
```

---

### 4-3. 슬라이딩 윈도우 기초 (Sliding Window)

배열이나 문자열의 연속된 부분 구간(윈도우)을 고정 크기 또는 가변 크기로
유지하면서 이동하는 패턴입니다.
매번 전체를 재계산하지 않고 윈도우 경계만 갱신하여 O(n)으로 처리합니다.

**예제: 고정 크기 윈도우 — 연속 k개 요소의 최대 합**

```js
function maxSumSubarray(arr, k) {
  if (arr.length < k) return null;

  // 첫 윈도우 합 계산
  let windowSum = 0;
  for (let i = 0; i < k; i++) {
    windowSum += arr[i];
  }

  let maxSum = windowSum;

  // 윈도우를 오른쪽으로 이동하면서 갱신
  for (let i = k; i < arr.length; i++) {
    windowSum += arr[i] - arr[i - k]; // 새 요소 추가, 이전 요소 제거
    maxSum = Math.max(maxSum, windowSum);
  }

  return maxSum;
}

console.log(maxSumSubarray([2, 1, 5, 1, 3, 2], 3)); // 9 (5+1+3)
console.log(maxSumSubarray([2, 3, 4, 1, 5], 2));     // 7 (3+4)
```

**예제: 가변 크기 윈도우 — 합이 target 이상인 최소 길이 부분 배열**

```js
function minSubarrayLen(arr, target) {
  let left = 0;
  let sum = 0;
  let minLen = Infinity;

  for (let right = 0; right < arr.length; right++) {
    sum += arr[right];

    // 조건 만족 시 왼쪽 포인터를 줄여 윈도우 축소
    while (sum >= target) {
      minLen = Math.min(minLen, right - left + 1);
      sum -= arr[left];
      left++;
    }
  }

  return minLen === Infinity ? 0 : minLen;
}

console.log(minSubarrayLen([2, 3, 1, 2, 4, 3], 7)); // 2 (4+3)
```

---

### 4-4. 아나그램 체크 (Anagram Check)

두 문자열이 서로 같은 문자를 같은 개수로 가지고 있는지 확인하는 패턴입니다.

**방법 1: 정렬 비교 — O(n log n)**

```js
function isAnagramSort(s, t) {
  if (s.length !== t.length) return false;
  return s.split('').sort().join('') === t.split('').sort().join('');
}
```

**방법 2: 빈도 카운팅 — O(n)**

```js
function isAnagram(s, t) {
  if (s.length !== t.length) return false;

  const freq = {};

  for (const ch of s) {
    freq[ch] = (freq[ch] || 0) + 1;
  }

  for (const ch of t) {
    if (!freq[ch]) return false;
    freq[ch]--;
  }

  return true;
}

console.log(isAnagram('anagram', 'nagaram')); // true
console.log(isAnagram('rat', 'car'));          // false
```

**방법 3: Map 활용**

```js
function isAnagramMap(s, t) {
  if (s.length !== t.length) return false;

  const map = new Map();

  for (const ch of s) {
    map.set(ch, (map.get(ch) || 0) + 1);
  }

  for (const ch of t) {
    if (!map.get(ch)) return false;
    map.set(ch, map.get(ch) - 1);
  }

  return true;
}
```

**응용: 슬라이딩 윈도우 + 아나그램 — 문자열 p의 아나그램 위치 찾기**

```js
function findAnagrams(s, p) {
  const result = [];
  if (s.length < p.length) return result;

  const pFreq = new Array(26).fill(0);
  const wFreq = new Array(26).fill(0);
  const base = 'a'.charCodeAt(0);

  for (let i = 0; i < p.length; i++) {
    pFreq[p.charCodeAt(i) - base]++;
    wFreq[s.charCodeAt(i) - base]++;
  }

  if (pFreq.toString() === wFreq.toString()) result.push(0);

  for (let i = p.length; i < s.length; i++) {
    wFreq[s.charCodeAt(i) - base]++;
    wFreq[s.charCodeAt(i - p.length) - base]--;

    if (pFreq.toString() === wFreq.toString()) {
      result.push(i - p.length + 1);
    }
  }

  return result;
}

console.log(findAnagrams('cbaebabacd', 'abc')); // [0, 6]
```

---

## 5. 면접 포인트

### Q1. JavaScript 배열은 진짜 배열인가요?

JavaScript의 배열은 엄밀히 말하면 객체(Object)입니다. 인덱스를 키로 사용하는
해시맵 형태로 구현되어 있으며, V8 엔진은 내부 최적화를 통해 특정 조건에서는
진짜 연속 메모리 배열처럼 동작합니다. `typeof []`는 `'object'`를 반환합니다.
배열 여부 확인은 `Array.isArray(arr)`를 사용합니다.

### Q2. `slice`와 `splice`의 차이는?

| 특성         | `slice`                     | `splice`                            |
|-------------|----------------------------|-------------------------------------|
| 원본 변경    | 변경하지 않음 (불변)         | 원본을 직접 변경 (가변)              |
| 반환값       | 새로운 배열                 | 제거된 요소 배열                     |
| 목적         | 부분 복사                   | 삽입/삭제                           |
| 음수 인덱스  | 지원                        | 지원                                |

### Q3. 슬라이딩 윈도우는 언제 사용하나요?

- 연속된 부분 배열/문자열에서 최적값(최대, 최소, 평균)을 구할 때
- 특정 조건을 만족하는 가장 짧거나 긴 부분 구간을 구할 때
- 전형적인 문제: "k 크기 부분 배열의 최대 합", "중복 없는 가장 긴 부분 문자열"
- 핵심: 매 이동마다 전체를 재계산하지 않고 윈도우 경계만 조정

### Q4. 빈도 카운팅과 투 포인터 중 어떤 것을 선택하나요?

- **빈도 카운팅**: 두 배열/문자열의 관계 비교, 아나그램, 요소 등장 횟수 기반 조건
- **투 포인터**: 정렬된 배열에서 합/차 조건 만족 쌍 탐색, 회문 검사, 방향성 있는 탐색

### Q5. 문자열 불변성(immutability)이 중요한 이유는?

문자열은 불변이므로 `str[0] = 'A'` 같은 방식으로 수정할 수 없습니다.
문자열을 조작해야 할 때는 배열로 변환(`split('')`)한 뒤 조작하고
다시 합치는(`join('')`) 패턴을 사용합니다. 이는 O(n)의 추가 비용이 발생합니다.

### Q6. 배열에서 중복 제거 방법은?

```js
// Set 활용 — O(n)
const arr = [1, 2, 2, 3, 3, 3];
const unique = [...new Set(arr)];       // [1, 2, 3]
const unique2 = Array.from(new Set(arr)); // [1, 2, 3]

// filter + indexOf — O(n²), 비권장
const unique3 = arr.filter((v, i) => arr.indexOf(v) === i);
```
