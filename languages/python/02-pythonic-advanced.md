# 2. Python 심화 — 파이써닉 패턴

> [01 기초](./01-basics.md)에서 문법·자료구조·컴프리헨션을 다뤘다. 여기서는 JS 개발자가 자주 헷갈리는 **제너레이터·데코레이터·컨텍스트 매니저·async·타입 힌트**를 JS와 대비해 정리한다.

## 목차
1. [이터레이터와 제너레이터](#1-이터레이터와-제너레이터)
2. [데코레이터](#2-데코레이터)
3. [컨텍스트 매니저 (with)](#3-컨텍스트-매니저-with)
4. [던더 메서드 (dunder)](#4-던더-메서드-dunder)
5. [async / await](#5-async--await)
6. [타입 힌트](#6-타입-힌트)
7. [JS와 자주 헷갈리는 함정](#7-js와-자주-헷갈리는-함정)
8. [면접 포인트](#8-면접-포인트)

---

## 1. 이터레이터와 제너레이터

JS의 `function*`/`yield`와 거의 동일하다. `yield`가 있는 함수는 호출 시 즉시 실행되지 않고 **제너레이터 객체**를 반환한다(지연 평가).

```python
def countdown(n):
    while n > 0:
        yield n          # 값을 내보내고 여기서 일시정지
        n -= 1

for x in countdown(3):   # 3, 2, 1
    print(x)
```

```python
# 제너레이터 표현식: 리스트 컴프리헨션의 [] 대신 () → 메모리에 전부 안 올림
total = sum(x * x for x in range(1_000_000))  # 100만 개를 메모리에 안 담고 합산
```

| | JavaScript | Python |
|--|-----------|--------|
| 제너레이터 정의 | `function* () { yield }` | `def f(): yield` |
| 다음 값 | `it.next().value` | `next(it)` |
| 끝 신호 | `{done:true}` | `StopIteration` 예외 |

> 제너레이터의 가치: 무한 수열·대용량 스트림을 **메모리 상수**로 처리. 파일을 한 줄씩 읽는 `for line in file:`이 대표 예다.

---

## 2. 데코레이터

함수/클래스를 **감싸서 동작을 추가**하는 고차 함수. `@` 문법은 "함수를 데코레이터에 넣고 결과로 재바인딩"하는 설탕이다.

```python
import functools, time

def timer(fn):
    @functools.wraps(fn)              # 원함수의 이름/docstring 보존
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = fn(*args, **kwargs)
        print(f"{fn.__name__}: {time.perf_counter()-start:.4f}s")
        return result
    return wrapper

@timer                                # slow = timer(slow) 와 동일
def slow():
    time.sleep(0.1)
```

표준 라이브러리 데코레이터:
- `@functools.cache` / `@lru_cache` — 메모이제이션.
- `@property` — 메서드를 속성처럼 접근(getter).
- `@staticmethod` / `@classmethod` — 바인딩 제어.
- `@dataclass` — 보일러플레이트 자동 생성.

```python
from dataclasses import dataclass

@dataclass
class Point:
    x: int
    y: int        # __init__, __repr__, __eq__ 자동 생성
```

> JS엔 1급 데코레이터가 최근에야 표준화됐다(TC39 Stage 3). Python은 HOF로 같은 일을 오래전부터 해왔다.

---

## 3. 컨텍스트 매니저 (with)

자원의 **획득과 해제를 자동화**한다. 예외가 나도 `__exit__`이 보장 호출된다(JS의 `try/finally`를 선언적으로).

```python
with open('data.txt') as f:   # 블록 종료 시 자동 close (예외 발생해도)
    data = f.read()
# 여기서 f는 이미 닫힘
```

직접 만들 때:

```python
from contextlib import contextmanager

@contextmanager
def transaction(conn):
    tx = conn.begin()
    try:
        yield tx          # yield 앞 = __enter__, 뒤 = __exit__
        tx.commit()
    except Exception:
        tx.rollback()
        raise
```

> JS엔 동등한 `with`가 없어 `try/finally`로 직접 닫아야 한다(곧 `using` 선언이 표준화 중). Python의 `with`는 자원 누수를 구조적으로 막는다.

---

## 4. 던더 메서드 (dunder)

`__메서드__`로 연산자·내장 함수의 동작을 커스터마이즈한다(연산자 오버로딩). JS의 `Symbol.iterator`, `valueOf`, `toString`을 일반화한 것.

```python
class Vec:
    def __init__(self, x, y): self.x, self.y = x, y
    def __add__(self, o):  return Vec(self.x+o.x, self.y+o.y)  # v1 + v2
    def __repr__(self):    return f"Vec({self.x}, {self.y})"   # 디버그 출력
    def __eq__(self, o):   return (self.x, self.y) == (o.x, o.y)
    def __len__(self):     return 2                            # len(v)
    def __iter__(self):    yield self.x; yield self.y          # for 가능

print(Vec(1,2) + Vec(3,4))   # Vec(4, 6)
```

자주 쓰는 것: `__init__`, `__repr__`/`__str__`, `__eq__`/`__hash__`, `__len__`, `__getitem__`(인덱싱), `__call__`(인스턴스를 함수처럼), `__enter__`/`__exit__`(컨텍스트 매니저).

---

## 5. async / await

문법은 JS와 거의 같다. 단 **이벤트 루프를 명시적으로 실행**해야 한다(`asyncio.run`). JS는 런타임이 루프를 항상 돌리지만 Python은 직접 띄운다.

```python
import asyncio

async def fetch(name, delay):
    await asyncio.sleep(delay)     # JS의 await fetch(...)와 동일 개념
    return name

async def main():
    # Promise.all 에 해당
    results = await asyncio.gather(
        fetch("a", 1), fetch("b", 2)
    )
    print(results)  # ['a', 'b']

asyncio.run(main())                # 이벤트 루프 시작 (JS엔 불필요)
```

| | JavaScript | Python |
|--|-----------|--------|
| 비동기 함수 | `async function` | `async def` |
| 대기 | `await p` | `await coro` |
| 병렬 대기 | `Promise.all([...])` | `asyncio.gather(...)` |
| 지연 | `setTimeout`/`await sleep` | `await asyncio.sleep()` |
| 루프 실행 | 자동 | `asyncio.run()` 필요 |

> 주의: `requests` 같은 동기 라이브러리를 `async` 안에서 호출하면 이벤트 루프가 블록된다. 비동기엔 `aiohttp`/`httpx` 등 async 지원 라이브러리를 써야 한다(JS에서 동기 XHR로 루프 막는 것과 같은 실수).

---

## 6. 타입 힌트

런타임엔 강제되지 않지만(주석 수준), `mypy`/`pyright` 같은 정적 검사기와 IDE가 활용한다. TS의 타입과 목적이 같다.

```python
from typing import Optional

def greet(name: str, times: int = 1) -> str:
    return f"Hi {name}! " * times

scores: dict[str, int] = {}
maybe: Optional[int] = None   # int | None (Python 3.10+: int | None 직접 표기)
```

> 차이: TS 타입은 컴파일(트랜스파일) 시 제거되고 런타임 검사가 없다 — Python 타입 힌트도 동일하게 런타임 무효(주석일 뿐)다. 둘 다 "개발 시점 도구"라는 점이 핵심.

---

## 7. JS와 자주 헷갈리는 함정

```python
# 1) 가변 기본 인자 — 함수 정의 시 한 번만 평가되어 공유됨!
def f(items=[]):      # ❌ 호출마다 같은 리스트 재사용
    items.append(1); return items
def f(items=None):    # ✅
    items = items or []

# 2) 얕은 복사 / is vs ==
a = [1, 2]; b = a          # 같은 객체 참조 (JS와 동일)
print(a is b, a == b)      # True True  (is=동일성, ==는 값 동등)

# 3) 정수 캐싱 — 작은 정수(-5~256)는 같은 객체로 캐싱되는 함정
a, b = 257, 257
print(a is b)   # 모듈/함수 스코프에선 True(상수 폴딩), REPL 줄별 입력에선 False — 구현 의존적
# (리터럴에 직접 is를 쓰면 SyntaxWarning. 값 비교엔 항상 == 사용)

# 4) truthiness: 빈 컬렉션/0/""/None 이 거짓
if not items:  # 빈 리스트면 True
    ...
```

> 가변 기본 인자는 Python 최다 함정. JS엔 없는 문제(JS는 매 호출 기본값 재평가). 항상 `None` 센티넬을 써라.

---

## 8. 면접 포인트

**Q. 제너레이터의 장점은?**
> 모든 값을 메모리에 올리지 않고 필요할 때 하나씩 생성(lazy)한다. 무한 수열·대용량 파일/스트림을 메모리 상수로 처리할 수 있다. `yield`가 있으면 함수가 제너레이터가 되며, JS의 `function*`/`yield`와 동일한 개념이다.

**Q. 데코레이터란?**
> 함수/클래스를 인자로 받아 감싼 새 함수를 돌려주는 고차 함수이며, `@`는 `f = deco(f)`의 설탕이다. 로깅·캐싱·인증·타이밍 같은 횡단 관심사를 분리한다. `functools.wraps`로 원함수 메타데이터를 보존하는 게 관례.

**Q. `with`(컨텍스트 매니저)가 해결하는 문제는?**
> 자원의 획득/해제를 쌍으로 보장한다. 블록을 벗어나면 예외가 나도 `__exit__`이 호출돼 파일·락·DB 트랜잭션을 확실히 정리한다. `try/finally`의 선언적 버전이다.

**Q. Python async와 JS async의 차이는?**
> 문법(`async def`/`await`)과 모델은 거의 같지만, Python은 `asyncio.run()`으로 이벤트 루프를 명시적으로 띄워야 하고, 동기 라이브러리를 async 안에서 부르면 루프가 블록되므로 async 전용 라이브러리를 써야 한다.

**Q. 가변 기본 인자 함정이란?**
> `def f(x=[])`의 기본값은 함수 정의 시 **한 번만** 생성돼 모든 호출이 같은 리스트를 공유한다. 누적 버그의 원인. 기본값을 `None`으로 두고 함수 안에서 `x = x or []`로 새로 만든다.

**Q. 타입 힌트는 런타임에 강제되나요?**
> 아니다. 주석 수준이며 `mypy`/`pyright` 같은 정적 검사기와 IDE가 사용할 뿐 런타임 동작을 바꾸지 않는다. 이 점은 트랜스파일 시 제거되는 TypeScript 타입과 동일한 철학이다.
