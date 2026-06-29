# 2. Rust 심화 — 스마트 포인터 · 트레이트 · 동시성 안전성

> [01 기초](./01-basics.md)에서 소유권·차용·수명·Option/Result를 다뤘다. 여기서는 소유권만으로 표현이 안 되는 구조(공유 소유, 순환, 내부 가변성)를 푸는 **스마트 포인터**, 다형성을 담당하는 **트레이트**, 그리고 Rust가 컴파일 타임에 데이터 레이스를 막는 **Send/Sync**를 다룬다.

## 목차
1. [왜 스마트 포인터가 필요한가](#1-왜-스마트-포인터가-필요한가)
2. [Box<T> — 힙 할당과 재귀 타입](#2-boxt--힙-할당과-재귀-타입)
3. [Rc<T> — 공유 소유권](#3-rct--공유-소유권)
4. [RefCell<T> — 내부 가변성](#4-refcellt--내부-가변성)
5. [트레이트 — 다형성과 추상화](#5-트레이트--다형성과-추상화)
6. [반복자와 클로저](#6-반복자와-클로저)
7. [Send / Sync — 컴파일 타임 동시성 안전](#7-send--sync--컴파일-타임-동시성-안전)
8. [면접 포인트](#8-면접-포인트)

---

## 1. 왜 스마트 포인터가 필요한가

기본 소유권 규칙은 "값마다 소유자 단 하나"다. 하지만 현실엔 **여러 곳이 같은 데이터를 공유**(그래프, 트리의 부모 참조)하거나, **불변 참조 뒤에서 내부를 바꿔야** 하는 경우가 있다. 스마트 포인터는 이런 패턴을 안전하게 허용하는 래퍼 타입이다.

| 타입 | 역할 | 비유(JS) |
|------|------|---------|
| `Box<T>` | 힙에 하나 할당, 단일 소유 | 일반 객체 참조 |
| `Rc<T>` | 참조 카운트 공유 소유(단일 스레드) | GC가 관리하는 공유 참조 |
| `Arc<T>` | 원자적 RC(멀티 스레드) | — |
| `RefCell<T>` | 런타임 검사 내부 가변성 | 항상 mutable한 JS 객체 |

---

## 2. Box<T> — 힙 할당과 재귀 타입

가장 단순한 스마트 포인터. 값을 힙에 두고 포인터만 스택에 둔다. 컴파일 타임 크기를 알 수 없는 **재귀 타입**에 필수다.

```rust
// 재귀 타입: Box 없으면 크기가 무한대라 컴파일 불가
enum List {
    Cons(i32, Box<List>),
    Nil,
}
use List::*;
let list = Cons(1, Box::new(Cons(2, Box::new(Nil))));
```

`Box`는 스코프를 벗어나면 힙 메모리를 자동 해제한다(`Drop`). GC 없이도 메모리 누수가 없는 이유.

---

## 3. Rc<T> — 공유 소유권

하나의 데이터를 여러 소유자가 공유해야 할 때. **참조 카운트**를 세고 0이 되면 해제한다 (단일 스레드 전용).

```rust
use std::rc::Rc;

let a = Rc::new(vec![1, 2, 3]);
let b = Rc::clone(&a);   // 깊은 복사 아님! 카운트만 +1 (저렴)
println!("count = {}", Rc::strong_count(&a)); // 2
```

- `Rc::clone`은 데이터를 복제하지 않고 카운트만 올린다(O(1)).
- 불변 공유만 가능. 가변이 필요하면 `RefCell`과 조합.
- **순환 참조**(A→B→A)는 카운트가 0이 안 돼 누수된다 → 한쪽을 `Weak<T>`(카운트 안 올림)로 끊는다.

> JS의 GC는 순환 참조를 mark-and-sweep으로 자동 회수하지만, Rust의 RC는 못 한다. 이게 RC 방식의 근본적 트레이드오프다.

---

## 4. RefCell<T> — 내부 가변성

소유권 규칙(가변 참조는 동시에 하나)은 **컴파일 타임**에 강제된다. `RefCell`은 이 검사를 **런타임**으로 미뤄, 불변 참조를 통해서도 내부를 바꿀 수 있게 한다(내부 가변성). 규칙 위반 시 컴파일이 아니라 **런타임 패닉**.

```rust
use std::cell::RefCell;

let c = RefCell::new(5);
*c.borrow_mut() += 10;          // 가변 차용
println!("{}", c.borrow());     // 15

// 빌림 규칙 위반: 동시에 가변+불변 → 런타임 패닉
let _a = c.borrow_mut();
let _b = c.borrow();            // panic: already mutably borrowed
```

`Rc<RefCell<T>>` 조합은 "공유되면서 가변인 데이터"의 표준 패턴이다(예: 그래프 노드).

---

## 5. 트레이트 — 다형성과 추상화

트레이트는 "이 타입이 할 수 있는 동작"을 정의한다. Java의 인터페이스, TS의 인터페이스/타입클래스에 해당하되 **기존 타입에도 나중에 구현을 붙일 수 있다**.

```rust
trait Summary {
    fn summarize(&self) -> String;
    fn preview(&self) -> String {            // 기본 구현 제공 가능
        format!("{}...", &self.summarize()[..5])
    }
}

struct Article { title: String }
impl Summary for Article {
    fn summarize(&self) -> String { self.title.clone() }
}
```

### 정적 vs 동적 디스패치

```rust
fn notify(item: &impl Summary) {}    // 정적: 컴파일 타임 단형화(monomorphization), 빠름
fn notify_dyn(item: &dyn Summary) {} // 동적: 런타임 vtable 조회, 유연
```

- `impl Trait`/제네릭 `<T: Summary>` → 타입마다 특화 코드 생성(제로 비용 추상화).
- `dyn Trait` → 런타임 다형성(JS 객체 메서드 호출과 유사), 약간의 비용.

---

## 6. 반복자와 클로저

Rust의 반복자는 **지연 평가(lazy)**되고, 체이닝해도 추가 할당이 거의 없다(제로 비용).

```rust
let sum: i32 = (1..=10)
    .filter(|n| n % 2 == 0)   // 클로저
    .map(|n| n * n)
    .sum();                    // 여기서야 실제 순회 (lazy)
```

- `iter()`(불변 참조) / `iter_mut()`(가변) / `into_iter()`(소유권 이동) 구분.
- 클로저는 환경을 캡처: `Fn`(불변)·`FnMut`(가변)·`FnOnce`(소유권 소비) 트레이트로 분류.

> JS의 `arr.filter().map()`은 매 단계 새 배열을 만들지만, Rust 반복자는 어댑터를 합성해 단일 패스로 컴파일된다.

---

## 7. Send / Sync — 컴파일 타임 동시성 안전

Rust의 가장 강력한 보증: **데이터 레이스가 컴파일되지 않는다.** 두 마커 트레이트가 핵심이다.

- **`Send`**: 소유권을 다른 스레드로 *이동*해도 안전한 타입.
- **`Sync`**: 여러 스레드가 *참조(&T)를 공유*해도 안전한 타입.

```rust
use std::sync::{Arc, Mutex};
use std::thread;

let counter = Arc::new(Mutex::new(0)); // Arc=스레드 안전 RC, Mutex=동기화
let mut handles = vec![];
for _ in 0..10 {
    let c = Arc::clone(&counter);
    handles.push(thread::spawn(move || {
        *c.lock().unwrap() += 1;       // 락 없이 접근하면 컴파일 에러
    }));
}
for h in handles { h.join().unwrap(); }
println!("{}", *counter.lock().unwrap()); // 10
```

- `Rc`는 `Send`가 아니라 스레드 경계를 넘기면 **컴파일 에러** → 단일 스레드에서만 안전하게 강제.
- 멀티 스레드 공유는 `Arc`(원자적 카운트) + `Mutex`/`RwLock`.

> "Fearless Concurrency": 타입 시스템이 락 없는 공유 가변 접근을 컴파일 단계에서 거부한다. Go가 런타임 `-race`로 *탐지*한다면, Rust는 아예 *컴파일을 막는다*.

---

## 8. 면접 포인트

**Q. `Box`, `Rc`, `Arc`, `RefCell`의 차이는?**
> `Box`는 힙 단일 소유, `Rc`는 단일 스레드 참조 카운트 공유 소유, `Arc`는 원자적 카운트라 멀티 스레드용, `RefCell`은 빌림 검사를 런타임으로 미뤄 불변 참조로도 내부를 바꾸는 내부 가변성을 준다. 공유+가변은 보통 `Rc<RefCell<T>>`(단일) / `Arc<Mutex<T>>`(멀티).

**Q. `Rc::clone`은 깊은 복사인가요?**
> 아니다. 데이터를 복제하지 않고 참조 카운트만 1 올리는 O(1) 연산이다. 그래서 `data.clone()`이 아니라 의도를 드러내는 `Rc::clone(&data)`를 관례로 쓴다.

**Q. Rust에서 순환 참조는 어떻게 되나요?**
> `Rc`는 참조 카운트가 0이 안 되는 순환에서 메모리 누수가 생긴다. GC가 없으므로 자동 회수되지 않는다. 한쪽을 `Weak<T>`(카운트를 올리지 않는 약한 참조)로 만들어 순환을 끊어야 한다.

**Q. 정적 디스패치와 동적 디스패치(`impl Trait` vs `dyn Trait`)?**
> `impl Trait`/제네릭은 컴파일 타임 단형화로 타입별 특화 코드를 생성해 런타임 비용이 없다. `dyn Trait`은 vtable을 통한 런타임 다형성으로 유연하지만 간접 호출 비용이 있다.

**Q. Rust가 데이터 레이스를 어떻게 막나요?**
> `Send`(스레드 간 이동 가능)·`Sync`(스레드 간 참조 공유 가능) 마커 트레이트로 타입 안전성을 표현한다. `Rc`처럼 스레드 안전하지 않은 타입을 스레드로 넘기면 컴파일 에러가 난다. 공유 가변은 `Arc<Mutex<T>>`로만 가능해, 락 없는 동시 접근이 애초에 컴파일되지 않는다("Fearless Concurrency").

**Q. Rust RC와 JS GC의 차이는?**
> JS GC는 mark-and-sweep으로 순환 참조까지 자동 회수하지만 GC 일시정지가 있다. Rust RC는 결정적(스코프 종료 시 즉시 해제)이고 GC 정지가 없지만, 순환은 개발자가 `Weak`로 직접 끊어야 한다.
