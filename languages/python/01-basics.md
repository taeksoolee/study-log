# 1. Python 기초 (JS 개발자를 위한 Python)

## 목차
1. Python vs JavaScript 주요 차이점
2. 기본 문법: 변수, 타입, 조건문, 반복문
3. 함수 정의
4. 자료구조: list, tuple, dict, set
5. 리스트 컴프리헨션
6. 알고리즘 유용 내장 함수
7. collections 모듈
8. heapq 모듈
9. 문자열 메서드
10. 면접 포인트

---

## 1. Python vs JavaScript 주요 차이점

| 항목 | Python | JavaScript |
|------|--------|------------|
| 타입 시스템 | 동적 타입, 강타입 | 동적 타입, 약타입 |
| 들여쓰기 | 문법적 의미 (블록 구분) | 선택 사항 |
| 세미콜론 | 불필요 | 선택 사항 (ASI) |
| null 표현 | `None` | `null`, `undefined` |
| 논리 연산자 | `and`, `or`, `not` | `&&`, `||`, `!` |
| 삼항 연산자 | `a if cond else b` | `cond ? a : b` |
| 클래스 상속 | `class B(A):` | `class B extends A` |
| 모듈 시스템 | `import`, `from ... import` | `import`, `require` |
| 비동기 | `async/await`, `asyncio` | `async/await`, Promise |
| 배열/리스트 | `list` | `Array` |
| 해시맵 | `dict` | `Object`, `Map` |
| 정수 나눗셈 | `//` | `Math.floor(a/b)` |
| 거듭제곱 | `**` | `**` 또는 `Math.pow` |

```python
# Python에서 타입 강제 변환 실패 예시 (JS와 다른 점)
# JS: "5" + 3 => "53"  (암묵적 변환)
# Python: "5" + 3 => TypeError 발생
result = "5" + str(3)  # 명시적 변환 필요 => "53"

# None 체크
x = None
if x is None:       # JS의 x === null 과 유사
    print("없음")

# 불리언
print(True, False)  # JS는 true, false (소문자)
```

---

## 2. 기본 문법: 변수, 타입, 조건문, 반복문

### 변수와 타입

```python
# 변수 선언 (var/let/const 없이 그냥 할당)
name = "Alice"
age = 30
pi = 3.14
is_active = True

# 타입 확인
print(type(name))       # <class 'str'>
print(type(age))        # <class 'int'>
print(isinstance(age, int))  # True

# 다중 할당
a, b, c = 1, 2, 3
x = y = z = 0

# 스왑 (JS와 달리 임시 변수 불필요)
a, b = b, a
```

### 조건문

```python
score = 85

# 기본 if/elif/else
if score >= 90:
    grade = "A"
elif score >= 80:
    grade = "B"
elif score >= 70:
    grade = "C"
else:
    grade = "F"

# 인라인 조건 (삼항 연산자)
result = "합격" if score >= 60 else "불합격"

# 값 범위 체크 (Python 특유 문법)
if 80 <= score < 90:
    print("B등급")
```

### 반복문

```python
# for-in (JS의 for...of와 유사)
fruits = ["apple", "banana", "cherry"]
for fruit in fruits:
    print(fruit)

# range: range(start, stop, step)
for i in range(5):         # 0, 1, 2, 3, 4
    print(i)

for i in range(1, 10, 2):  # 1, 3, 5, 7, 9
    print(i)

# while
count = 0
while count < 5:
    count += 1

# break, continue (JS와 동일)
for i in range(10):
    if i == 3:
        continue
    if i == 7:
        break
    print(i)

# for-else (Python 특유: break 없이 끝나면 else 실행)
for i in range(5):
    if i == 10:
        break
else:
    print("break 없이 완료됨")
```

---

## 3. 함수 정의

```python
# 기본 함수
def greet(name):
    return f"Hello, {name}!"

# 기본값 인수 (default arguments)
def power(base, exp=2):
    return base ** exp

print(power(3))     # 9
print(power(3, 3))  # 27

# 키워드 인수 (keyword arguments)
def describe(name, age, city="Seoul"):
    return f"{name}, {age}세, {city} 거주"

print(describe(age=25, name="Bob"))  # 순서 무관

# 가변 위치 인수 (*args)
def sum_all(*args):
    return sum(args)

print(sum_all(1, 2, 3, 4))  # 10

# 가변 키워드 인수 (**kwargs)
def print_info(**kwargs):
    for key, value in kwargs.items():
        print(f"{key}: {value}")

print_info(name="Alice", age=30, city="Busan")

# 람다 (lambda)
square = lambda x: x ** 2
add = lambda x, y: x + y

# JS의 화살표 함수와 유사하지만 단일 표현식만 가능
numbers = [3, 1, 4, 1, 5]
numbers.sort(key=lambda x: -x)  # 내림차순

# 타입 힌트 (Type Hints, Python 3.5+)
def add_numbers(a: int, b: int) -> int:
    return a + b
```

---

## 4. 자료구조: list, tuple, dict, set

### list (배열)

```python
arr = [1, 2, 3, 4, 5]

# 인덱싱 & 슬라이싱
print(arr[0])      # 1
print(arr[-1])     # 5 (마지막)
print(arr[1:3])    # [2, 3]
print(arr[::-1])   # [5, 4, 3, 2, 1] (역순)

# 주요 메서드
arr.append(6)           # 끝에 추가
arr.insert(0, 0)        # 인덱스에 삽입
arr.pop()               # 마지막 제거
arr.pop(0)              # 인덱스 제거
arr.remove(3)           # 값으로 제거 (첫 번째 발견)
arr.extend([7, 8])      # 다른 리스트 합치기
arr.sort()              # 제자리 정렬
arr.reverse()           # 제자리 역순
print(len(arr))         # 길이
print(3 in arr)         # 포함 여부
```

### tuple (불변 리스트)

```python
point = (3, 4)
x, y = point  # 언패킹

# 단일 요소 튜플은 콤마 필수
single = (42,)

# 함수 다중 반환값에 자주 사용
def min_max(lst):
    return min(lst), max(lst)

lo, hi = min_max([3, 1, 4, 1, 5])
```

### dict (해시맵)

```python
person = {"name": "Alice", "age": 30}

# 접근
print(person["name"])
print(person.get("email", "없음"))  # KeyError 방지

# 추가/수정/삭제
person["city"] = "Seoul"
del person["age"]

# 순회
for key in person:
    print(key, person[key])

for key, value in person.items():
    print(f"{key}: {value}")

print(list(person.keys()))
print(list(person.values()))

# dict 병합 (Python 3.9+)
merged = {**person, "extra": True}
```

### set (집합)

```python
s = {1, 2, 3, 4}
s.add(5)
s.remove(3)
s.discard(99)  # 없어도 에러 없음

a = {1, 2, 3}
b = {2, 3, 4}
print(a | b)   # 합집합: {1, 2, 3, 4}
print(a & b)   # 교집합: {2, 3}
print(a - b)   # 차집합: {1}
print(a ^ b)   # 대칭 차집합: {1, 4}
```

---

## 5. 리스트 컴프리헨션

```python
# 기본 형식: [표현식 for 변수 in 이터러블 if 조건]

# JS의 map과 유사
squares = [x**2 for x in range(10)]
# => [0, 1, 4, 9, 16, 25, 36, 49, 64, 81]

# JS의 filter와 유사
evens = [x for x in range(20) if x % 2 == 0]
# => [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]

# map + filter 조합
result = [x**2 for x in range(20) if x % 2 == 0]

# 중첩 반복문 (2D 배열 flatten)
matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
flat = [x for row in matrix for x in row]
# => [1, 2, 3, 4, 5, 6, 7, 8, 9]

# dict 컴프리헨션
word_len = {word: len(word) for word in ["apple", "banana", "cherry"]}
# => {'apple': 5, 'banana': 6, 'cherry': 6}

# set 컴프리헨션
unique_squares = {x**2 for x in [-2, -1, 0, 1, 2]}
# => {0, 1, 4}

# 제너레이터 표현식 (메모리 효율적)
gen = (x**2 for x in range(1000000))  # 즉시 계산 안 함
```

---

## 6. 알고리즘 유용 내장 함수

```python
nums = [3, 1, 4, 1, 5, 9, 2, 6]

# sorted: 새 리스트 반환 (원본 불변)
print(sorted(nums))             # 오름차순
print(sorted(nums, reverse=True))  # 내림차순
print(sorted(nums, key=lambda x: -x))  # key 함수 활용

# min / max
print(min(nums))               # 1
print(max(nums))               # 9
print(min(nums, key=abs))      # key 함수 활용

# enumerate: 인덱스와 값을 함께 순회
for i, val in enumerate(nums):
    print(i, val)

for i, val in enumerate(nums, start=1):  # 1부터 시작
    print(i, val)

# zip: 여러 이터러블을 병렬로 순회
names = ["Alice", "Bob", "Charlie"]
scores = [95, 87, 92]
for name, score in zip(names, scores):
    print(f"{name}: {score}")

# zip으로 dict 생성
d = dict(zip(names, scores))
# => {'Alice': 95, 'Bob': 87, 'Charlie': 92}

# map: 함수를 각 요소에 적용
doubled = list(map(lambda x: x * 2, nums))
str_nums = list(map(str, nums))

# filter: 조건에 맞는 요소만 추출
positives = list(filter(lambda x: x > 0, [-1, 2, -3, 4]))

# sum, any, all
print(sum(nums))
print(sum(x**2 for x in nums))  # 제너레이터 활용
print(any(x > 8 for x in nums))   # 하나라도 True
print(all(x > 0 for x in nums))   # 모두 True

# abs, divmod, pow
print(abs(-5))          # 5
print(divmod(17, 5))    # (3, 2) => (몫, 나머지)
print(pow(2, 10))       # 1024
print(pow(2, 10, 1000)) # 1024 % 1000 = 24 (모듈러 거듭제곱)
```

---

## 7. collections 모듈

```python
from collections import defaultdict, Counter, deque

# defaultdict: 키 없을 때 기본값 자동 생성
graph = defaultdict(list)
graph[1].append(2)  # KeyError 없이 동작
graph[1].append(3)

word_count = defaultdict(int)
for word in "hello world hello".split():
    word_count[word] += 1  # 초기화 불필요
# => defaultdict(<class 'int'>, {'hello': 2, 'world': 1})

# Counter: 빈도 계산
text = "abracadabra"
counter = Counter(text)
print(counter)              # Counter({'a': 5, 'b': 2, 'r': 2, 'c': 1, 'd': 1})
print(counter.most_common(3))   # [('a', 5), ('b', 2), ('r', 2)]
print(counter['a'])         # 5

nums_count = Counter([1, 2, 2, 3, 3, 3])
print(nums_count[3])  # 3

# Counter 연산
c1 = Counter({'a': 3, 'b': 2})
c2 = Counter({'a': 1, 'b': 4})
print(c1 + c2)  # Counter({'b': 6, 'a': 4})
print(c1 - c2)  # Counter({'a': 2})

# deque: 양방향 큐 (앞뒤 O(1) 삽입/삭제)
dq = deque([1, 2, 3])
dq.append(4)        # 오른쪽에 추가
dq.appendleft(0)    # 왼쪽에 추가
dq.pop()            # 오른쪽 제거
dq.popleft()        # 왼쪽 제거
dq.rotate(1)        # 오른쪽으로 회전

# BFS에서 자주 사용
from collections import deque
def bfs(graph, start):
    visited = set()
    queue = deque([start])
    visited.add(start)
    while queue:
        node = queue.popleft()
        for neighbor in graph[node]:
            if neighbor not in visited:
                visited.add(neighbor)
                queue.append(neighbor)
```

---

## 8. heapq 모듈 (힙 큐)

```python
import heapq

# 최소 힙 (min-heap) - Python 기본
heap = []
heapq.heappush(heap, 3)
heapq.heappush(heap, 1)
heapq.heappush(heap, 4)
heapq.heappush(heap, 1)

print(heapq.heappop(heap))  # 1 (최솟값)
print(heap[0])              # 현재 최솟값 조회 (제거 없이)

# 리스트를 힙으로 변환 (O(n))
nums = [3, 1, 4, 1, 5, 9, 2, 6]
heapq.heapify(nums)

# nlargest / nsmallest
print(heapq.nlargest(3, nums))   # [9, 6, 5]
print(heapq.nsmallest(3, nums))  # [1, 1, 2]

# 최대 힙 구현: 값을 음수로 저장
max_heap = []
for num in [3, 1, 4, 1, 5]:
    heapq.heappush(max_heap, -num)

print(-heapq.heappop(max_heap))  # 5 (최댓값)

# 튜플로 우선순위 지정 (첫 번째 요소 기준)
tasks = []
heapq.heappush(tasks, (3, "low priority task"))
heapq.heappush(tasks, (1, "high priority task"))
heapq.heappush(tasks, (2, "medium priority task"))

priority, task = heapq.heappop(tasks)
print(task)  # "high priority task"
```

---

## 9. 문자열 메서드

```python
s = "  Hello, World!  "

# 기본 조작
print(s.strip())           # "Hello, World!" (앞뒤 공백 제거)
print(s.lstrip())          # 왼쪽만
print(s.rstrip())          # 오른쪽만
print(s.lower())           # "  hello, world!  "
print(s.upper())           # "  HELLO, WORLD!  "
print(s.title())           # 각 단어 첫 글자 대문자

# 검색
s2 = "abcabc"
print(s2.find("b"))        # 1 (없으면 -1)
print(s2.index("b"))       # 1 (없으면 ValueError)
print(s2.count("a"))       # 2
print(s2.startswith("ab")) # True
print(s2.endswith("bc"))   # True

# 변환
print("hello world".replace("world", "Python"))
print("a,b,c".split(","))     # ['a', 'b', 'c']
print(",".join(["a", "b", "c"]))  # "a,b,c"

# 포맷팅
name, age = "Alice", 30
print(f"{name}은 {age}살")                 # f-string (권장)
print("{0}은 {1}살".format(name, age))    # format 메서드
print("%.2f" % 3.14159)                    # % 포맷

# 검사
print("123".isdigit())     # True
print("abc".isalpha())     # True
print("abc123".isalnum())  # True
print("  ".isspace())      # True

# 알고리즘에서 유용한 패턴
# 알파벳 순서 확인
print(ord('a'))   # 97
print(chr(97))    # 'a'
print(ord('z') - ord('a'))  # 25

# 문자열 역순
print("hello"[::-1])   # "olleh"

# 문자 빈도 (Counter 없이)
from collections import Counter
freq = Counter("programming")
```

---

## 10. 면접 포인트

### Q1. Python의 GIL(Global Interpreter Lock)이란?
**A:** CPython에서 한 번에 하나의 스레드만 Python 바이트코드를 실행할 수 있도록 하는 뮤텍스입니다.
- CPU 바운드 작업: 멀티스레딩 효과 없음 → `multiprocessing` 사용 권장
- I/O 바운드 작업: GIL이 I/O 대기 중 해제되어 멀티스레딩 효과 있음
- `asyncio`는 단일 스레드 이벤트 루프로 GIL 문제를 우회

### Q2. 리스트와 튜플의 차이는?
**A:**
- `list`: 가변(mutable), 더 많은 메모리 사용, 해시 불가
- `tuple`: 불변(immutable), 더 적은 메모리, 딕셔너리 키로 사용 가능
- 함수 반환값, 레코드성 데이터에는 튜플이 적합

### Q3. `is`와 `==`의 차이는?
**A:**
- `==`: 값(value) 동등성 비교
- `is`: 객체 동일성(identity) 비교 (`id()` 비교)
- `None` 체크에는 반드시 `is None` 사용

```python
a = [1, 2, 3]
b = [1, 2, 3]
print(a == b)   # True (값이 같음)
print(a is b)   # False (다른 객체)

x = None
print(x is None)   # True (권장)
print(x == None)   # True (비권장)
```

### Q4. 얕은 복사 vs 깊은 복사
```python
import copy

original = [[1, 2], [3, 4]]
shallow = original.copy()      # 또는 original[:]
deep = copy.deepcopy(original)

original[0][0] = 99
print(shallow[0][0])  # 99 (영향 받음 - 내부 객체 공유)
print(deep[0][0])     # 1  (영향 없음 - 완전히 독립)
```

### Q5. 제너레이터(Generator)란?
**A:** `yield`를 사용하는 함수로, 이터레이터를 생성합니다. 값을 한 번에 메모리에 올리지 않고 필요할 때 하나씩 생성하여 메모리 효율적입니다.

```python
def fibonacci():
    a, b = 0, 1
    while True:
        yield a
        a, b = b, a + b

gen = fibonacci()
print([next(gen) for _ in range(8)])
# [0, 1, 1, 2, 3, 5, 8, 13]
```

### Q6. 코딩 테스트 시 자주 쓰는 패턴
```python
# 2D 배열 초기화
grid = [[0] * cols for _ in range(rows)]  # 올바른 방법
# grid = [[0] * cols] * rows  # 위험! 행 공유 문제

# 무한대 표현
INF = float('inf')

# 딕셔너리로 메모이제이션
memo = {}
def fib(n):
    if n in memo:
        return memo[n]
    if n <= 1:
        return n
    memo[n] = fib(n-1) + fib(n-2)
    return memo[n]

# functools.lru_cache 활용
from functools import lru_cache

@lru_cache(maxsize=None)
def fib_cached(n):
    if n <= 1:
        return n
    return fib_cached(n-1) + fib_cached(n-2)
```
