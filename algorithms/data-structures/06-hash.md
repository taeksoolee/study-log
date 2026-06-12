# 6. 해시 테이블 (Hash Table)

## 목차
1. 해시 테이블 개념과 해시 함수
2. 충돌 해결 방법
3. 시간복잡도 분석
4. JavaScript Map 활용 패턴
5. JavaScript Set 활용 패턴
6. 면접 포인트

---

## 1. 해시 테이블 개념과 해시 함수

해시 테이블은 키(Key)를 해시 함수로 변환한 인덱스를 이용해 값을 저장하는 자료구조다. 평균 O(1)의 삽입, 삭제, 탐색을 제공한다.

### 해시 함수 (Hash Function)

좋은 해시 함수의 조건:
1. 동일한 입력에 대해 항상 동일한 출력 (결정론적)
2. 해시 값이 고르게 분포 (균일성)
3. 빠른 계산
4. 충돌 최소화

```javascript
// 단순한 문자열 해시 함수 (djb2 변형)
function hashString(key, tableSize) {
  let hash = 5381;
  for (let i = 0; i < key.length; i++) {
    hash = ((hash << 5) + hash) + key.charCodeAt(i);
    hash = hash & hash; // 32비트 정수로 유지
  }
  return Math.abs(hash) % tableSize;
}

// 다항식 롤링 해시
function polynomialHash(key, tableSize, prime = 31) {
  let hash = 0;
  let power = 1;
  for (let i = 0; i < key.length; i++) {
    hash = (hash + (key.charCodeAt(i) - 96) * power) % tableSize;
    power = (power * prime) % tableSize;
  }
  return hash;
}

console.log(hashString('hello', 100));      // 항상 동일한 값
console.log(polynomialHash('world', 100));  // 항상 동일한 값
```

---

## 2. 충돌 해결 방법

서로 다른 키가 같은 해시 인덱스를 가질 때 충돌(Collision)이 발생한다.

### 방법 1: 체이닝 (Chaining) - 분리 연결법

각 버킷을 연결 리스트(또는 배열)로 만들어 충돌된 항목들을 연결한다.

```javascript
class HashTableChaining {
  constructor(size = 53) {
    this.table = new Array(size);
    this.size = size;
  }

  _hash(key) {
    let hash = 0;
    for (let i = 0; i < Math.min(key.length, 100); i++) {
      hash = (hash * 31 + key.charCodeAt(i)) % this.size;
    }
    return hash;
  }

  set(key, value) {
    const idx = this._hash(key);
    if (!this.table[idx]) {
      this.table[idx] = [];
    }
    // 기존 키가 있으면 값 업데이트
    const existing = this.table[idx].find(item => item[0] === key);
    if (existing) {
      existing[1] = value;
    } else {
      this.table[idx].push([key, value]);
    }
  }

  get(key) {
    const idx = this._hash(key);
    if (!this.table[idx]) return undefined;
    const pair = this.table[idx].find(item => item[0] === key);
    return pair ? pair[1] : undefined;
  }

  delete(key) {
    const idx = this._hash(key);
    if (!this.table[idx]) return false;
    const pos = this.table[idx].findIndex(item => item[0] === key);
    if (pos === -1) return false;
    this.table[idx].splice(pos, 1);
    return true;
  }

  keys() {
    return this.table
      .filter(Boolean)
      .flatMap(bucket => bucket.map(item => item[0]));
  }
}
```

### 방법 2: 개방 주소법 (Open Addressing)

충돌 시 다른 빈 버킷을 찾아 저장한다. 모든 데이터가 테이블 안에 저장된다.

```javascript
class HashTableOpenAddressing {
  constructor(size = 53) {
    this.table = new Array(size).fill(null);
    this.deleted = new Array(size).fill(false); // tombstone
    this.size = size;
    this.count = 0;
  }

  _hash(key) {
    let hash = 0;
    for (let i = 0; i < key.length; i++) {
      hash = (hash * 31 + key.charCodeAt(i)) % this.size;
    }
    return hash;
  }

  // 선형 탐사 (Linear Probing)
  _probe(key) {
    let idx = this._hash(key);
    let firstDeleted = -1;

    while (this.table[idx] !== null || this.deleted[idx]) {
      if (this.deleted[idx]) {
        if (firstDeleted === -1) firstDeleted = idx;
      } else if (this.table[idx][0] === key) {
        return idx; // 키 발견
      }
      idx = (idx + 1) % this.size;
    }
    return firstDeleted !== -1 ? firstDeleted : idx;
  }

  set(key, value) {
    if (this.count / this.size > 0.7) {
      // 로드 팩터 초과 시 리사이징 필요 (구현 생략)
      console.warn('로드 팩터가 0.7을 초과했습니다. 리사이징을 권장합니다.');
    }
    const idx = this._probe(key);
    if (!this.table[idx] || this.deleted[idx]) this.count++;
    this.table[idx] = [key, value];
    this.deleted[idx] = false;
  }

  get(key) {
    const idx = this._probe(key);
    if (this.table[idx] && this.table[idx][0] === key) {
      return this.table[idx][1];
    }
    return undefined;
  }

  delete(key) {
    const idx = this._probe(key);
    if (this.table[idx] && this.table[idx][0] === key) {
      this.deleted[idx] = true;
      this.count--;
      return true;
    }
    return false;
  }
}
```

### 충돌 해결 방법 비교

| 항목 | 체이닝 | 개방 주소법 |
|------|--------|-------------|
| 공간 효율 | 낮음 (포인터 오버헤드) | 높음 (테이블 내부 저장) |
| 로드 팩터 | 1 이상도 동작 | 1 미만 유지 필요 |
| 캐시 효율 | 낮음 (포인터 추적) | 높음 (연속 메모리) |
| 삭제 구현 | 단순 | 복잡 (tombstone 필요) |
| 실무 사용 | Java HashMap | Python dict |

---

## 3. 시간복잡도 분석

| 연산 | 평균 | 최악 |
|------|------|------|
| 삽입 | O(1) | O(n) |
| 삭제 | O(1) | O(n) |
| 탐색 | O(1) | O(n) |

**로드 팩터(Load Factor)**: `n / m` (n = 저장된 항목 수, m = 버킷 수)

최악의 경우 O(n)이 발생하는 상황:
1. 해시 함수가 모든 키를 동일한 버킷에 매핑하는 경우
2. 로드 팩터가 너무 높아 충돌이 빈번하게 발생하는 경우

실무에서 평균 O(1)을 유지하려면:
- 좋은 해시 함수 사용
- 로드 팩터를 0.7 이하로 유지
- 임계값 초과 시 테이블 크기를 2배로 늘리고 리해싱(rehashing)

---

## 4. JavaScript Map 활용 패턴

### 패턴 1: 빈도 카운팅 (Frequency Counter)

```javascript
// 배열에서 각 원소의 등장 횟수 계산
function frequencyCounter(arr) {
  const freq = new Map();
  for (const item of arr) {
    freq.set(item, (freq.get(item) ?? 0) + 1);
  }
  return freq;
}

// 두 배열의 원소 제곱 일치 여부 확인 - O(n)
function areSameSquares(arr1, arr2) {
  if (arr1.length !== arr2.length) return false;
  const freq1 = frequencyCounter(arr1);
  const freq2 = frequencyCounter(arr2);

  for (const [val, count] of freq1) {
    const square = val ** 2;
    if (!freq2.has(square) || freq2.get(square) !== count) return false;
  }
  return true;
}

console.log(areSameSquares([1, 2, 3], [4, 1, 9])); // true
console.log(areSameSquares([1, 2, 1], [4, 4, 1])); // false
```

### 패턴 2: Two Sum 문제

```javascript
// O(n) 해결책
function twoSum(nums, target) {
  const seen = new Map(); // 값 -> 인덱스

  for (let i = 0; i < nums.length; i++) {
    const complement = target - nums[i];
    if (seen.has(complement)) {
      return [seen.get(complement), i];
    }
    seen.set(nums[i], i);
  }
  return null;
}

console.log(twoSum([2, 7, 11, 15], 9)); // [0, 1]
console.log(twoSum([3, 2, 4], 6));      // [1, 2]

// 변형: 모든 쌍 반환
function twoSumAllPairs(nums, target) {
  const seen = new Map();
  const result = [];

  for (let i = 0; i < nums.length; i++) {
    const complement = target - nums[i];
    if (seen.has(complement)) {
      for (const idx of seen.get(complement)) {
        result.push([idx, i]);
      }
    }
    if (!seen.has(nums[i])) seen.set(nums[i], []);
    seen.get(nums[i]).push(i);
  }
  return result;
}
```

### 패턴 3: 그룹 애너그램 (Group Anagrams)

```javascript
function groupAnagrams(strs) {
  const map = new Map();

  for (const str of strs) {
    // 정렬된 문자열을 키로 사용
    const key = str.split('').sort().join('');
    if (!map.has(key)) map.set(key, []);
    map.get(key).push(str);
  }

  return [...map.values()];
}

console.log(groupAnagrams(['eat', 'tea', 'tan', 'ate', 'nat', 'bat']));
// [['eat','tea','ate'], ['tan','nat'], ['bat']]

// 최적화: 정렬 대신 문자 빈도 배열을 키로 사용 - O(n*m)
function groupAnagramsOptimal(strs) {
  const map = new Map();

  for (const str of strs) {
    const count = Array(26).fill(0);
    for (const char of str) {
      count[char.charCodeAt(0) - 97]++;
    }
    const key = count.join(',');
    if (!map.has(key)) map.set(key, []);
    map.get(key).push(str);
  }

  return [...map.values()];
}
```

### 패턴 4: LRU 캐시 (Least Recently Used Cache)

Map은 삽입 순서를 보장하므로, 연결 리스트 없이도 LRU 구현이 가능하다.

```javascript
class LRUCache {
  constructor(capacity) {
    this.capacity = capacity;
    this.cache = new Map(); // 키 -> 값 (삽입 순서 유지)
  }

  get(key) {
    if (!this.cache.has(key)) return -1;

    // 가장 최근 사용으로 갱신: 삭제 후 재삽입
    const value = this.cache.get(key);
    this.cache.delete(key);
    this.cache.set(key, value);
    return value;
  }

  put(key, value) {
    if (this.cache.has(key)) {
      this.cache.delete(key);
    } else if (this.cache.size >= this.capacity) {
      // Map의 첫 번째 키가 가장 오래된 항목
      const oldestKey = this.cache.keys().next().value;
      this.cache.delete(oldestKey);
    }
    this.cache.set(key, value);
  }
}

// 사용 예시
const lru = new LRUCache(3);
lru.put(1, 'a');
lru.put(2, 'b');
lru.put(3, 'c');
lru.get(1);      // 'a' — 1이 최근 사용됨
lru.put(4, 'd'); // 2가 가장 오래됨 → 2 제거
console.log(lru.get(2)); // -1 (제거됨)
console.log(lru.get(3)); // 'c'
```

---

## 5. JavaScript Set 활용 패턴

### 패턴 1: 중복 제거

```javascript
// 배열 중복 제거 - O(n)
const arr = [1, 2, 3, 2, 1, 4, 3, 5];
const unique = [...new Set(arr)];
console.log(unique); // [1, 2, 3, 4, 5]

// 문자열 중복 문자 제거
const str = 'aabbbcddde';
const uniqueChars = [...new Set(str)].join('');
console.log(uniqueChars); // 'abcde'

// 객체 배열 중복 제거 (특정 키 기준)
function uniqueBy(arr, keyFn) {
  const seen = new Set();
  return arr.filter(item => {
    const key = keyFn(item);
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

const users = [
  { id: 1, name: 'Alice' },
  { id: 2, name: 'Bob' },
  { id: 1, name: 'Alice Duplicate' },
];
console.log(uniqueBy(users, u => u.id));
// [{ id: 1, name: 'Alice' }, { id: 2, name: 'Bob' }]
```

### 패턴 2: 집합 연산 (Set Operations)

```javascript
function setOperations(a, b) {
  const setA = new Set(a);
  const setB = new Set(b);

  // 교집합 (Intersection)
  const intersection = new Set([...setA].filter(x => setB.has(x)));

  // 합집합 (Union)
  const union = new Set([...setA, ...setB]);

  // 차집합 (Difference) A - B
  const differenceAB = new Set([...setA].filter(x => !setB.has(x)));

  // 대칭 차집합 (Symmetric Difference)
  const symmetricDiff = new Set([
    ...[...setA].filter(x => !setB.has(x)),
    ...[...setB].filter(x => !setA.has(x)),
  ]);

  // 부분집합 여부
  const isSubset = (sub, sup) => [...sub].every(x => sup.has(x));

  return {
    intersection: [...intersection],
    union: [...union],
    differenceAB: [...differenceAB],
    symmetricDiff: [...symmetricDiff],
    isASubsetOfB: isSubset(setA, setB),
  };
}

const result = setOperations([1, 2, 3, 4], [3, 4, 5, 6]);
console.log(result.intersection);   // [3, 4]
console.log(result.union);          // [1, 2, 3, 4, 5, 6]
console.log(result.differenceAB);   // [1, 2]
console.log(result.symmetricDiff);  // [1, 2, 5, 6]
```

### 패턴 3: 방문 추적 (Visited Tracking)

```javascript
// 가장 긴 연속 수열 - O(n)
function longestConsecutive(nums) {
  const numSet = new Set(nums);
  let maxLength = 0;

  for (const num of numSet) {
    // 연속 수열의 시작점만 처리 (num-1이 없는 경우)
    if (!numSet.has(num - 1)) {
      let current = num;
      let length = 1;

      while (numSet.has(current + 1)) {
        current++;
        length++;
      }
      maxLength = Math.max(maxLength, length);
    }
  }
  return maxLength;
}

console.log(longestConsecutive([100, 4, 200, 1, 3, 2])); // 4 → [1,2,3,4]
console.log(longestConsecutive([0, 3, 7, 2, 5, 8, 4, 6, 0, 1])); // 9

// 중복 없는 가장 긴 부분 문자열 (슬라이딩 윈도우 + Set)
function lengthOfLongestSubstring(s) {
  const charSet = new Set();
  let left = 0;
  let maxLength = 0;

  for (let right = 0; right < s.length; right++) {
    while (charSet.has(s[right])) {
      charSet.delete(s[left]);
      left++;
    }
    charSet.add(s[right]);
    maxLength = Math.max(maxLength, right - left + 1);
  }
  return maxLength;
}

console.log(lengthOfLongestSubstring('abcabcbb')); // 3 → 'abc'
console.log(lengthOfLongestSubstring('pwwkew'));   // 3 → 'wke'
```

---

## 6. 면접 포인트

### 해시 테이블 기본

**Q. 해시 테이블이 평균 O(1)인 이유는?**

좋은 해시 함수가 키를 균일하게 분포시키면 각 버킷에 저장되는 항목 수가 기대치 n/m에 수렴한다. 로드 팩터를 상수로 유지하면 탐색, 삽입, 삭제가 상수 시간에 이루어진다.

**Q. 로드 팩터(Load Factor)란 무엇이고, 왜 중요한가요?**

로드 팩터는 `저장된 항목 수 / 버킷 수`다. 너무 높으면 충돌이 빈번해져 성능이 저하되고, 너무 낮으면 메모리를 낭비한다. 일반적으로 0.7을 임계값으로 삼아 초과 시 리사이징(보통 2배)과 리해싱을 수행한다.

### 충돌 해결

**Q. 체이닝과 개방 주소법의 차이점과 각각의 장단점은?**

체이닝은 각 버킷이 연결 리스트를 가져 로드 팩터가 1을 넘어도 동작하고 삭제가 간단하지만, 포인터 오버헤드로 캐시 효율이 낮다. 개방 주소법은 테이블 내에 데이터를 저장해 캐시 효율이 높지만, 로드 팩터를 1 미만으로 유지해야 하며 삭제 시 tombstone이 필요하다. Python의 dict는 개방 주소법, Java의 HashMap은 체이닝을 사용한다.

### JavaScript Map vs Object

**Q. JavaScript에서 일반 객체({}) 대신 Map을 사용해야 하는 경우는?**

- 키로 문자열/심볼 외 타입(숫자, 객체, 함수 등)을 사용해야 할 때
- 삽입 순서 보장이 필요할 때
- 크기를 자주 확인해야 할 때 (`map.size` vs `Object.keys(obj).length`)
- 키 개수가 매우 많아 성능이 중요할 때
- 프로토타입 오염(prototype pollution) 위험을 피해야 할 때

**Q. Map과 WeakMap의 차이점은?**

WeakMap은 키가 반드시 객체여야 하고, 키에 대한 참조가 약한 참조(weak reference)다. 다른 곳에서 키 객체를 참조하지 않으면 GC가 수거할 수 있다. 이터러블이 아니므로 keys(), values(), size를 사용할 수 없다. 메모이제이션이나 캐싱에서 메모리 누수를 방지할 때 유용하다.

### 실전 문제 접근

**Q. "배열에서 합이 k인 두 원소를 찾아라" 같은 문제의 접근 방법은?**

해시맵에 이미 본 원소를 저장하고, 현재 원소의 보수(complement = k - current)가 해시맵에 있는지 O(1)로 확인한다. 브루트포스 O(n²)을 O(n)으로 줄일 수 있다. 이처럼 "이미 본 것을 빠르게 조회"하는 패턴은 해시 테이블이 핵심이다.
