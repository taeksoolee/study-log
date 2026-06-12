# 1. Rust 기초 — 소유권, 차용, 메모리 안전성

## 목차
1. Rust 언어 특징
2. Rust vs JavaScript 비교
3. 소유권(Ownership)
4. 이동(Move) vs 복사(Copy)
5. 차용(Borrowing)
6. 수명(Lifetime) 기초
7. 기본 문법: 변수, 함수, struct, enum
8. Option과 Result — 에러 처리
9. 패턴 매칭(match)
10. JavaScript 개발자 주의사항
11. 면접 포인트

---

## 1. Rust 언어 특징

Rust는 Mozilla Research에서 시작된 시스템 프로그래밍 언어다. 세 가지 핵심 목표를 동시에 달성하려 설계되었다.

| 목표 | 설명 |
|------|------|
| 메모리 안전 | GC 없이 컴파일 타임에 메모리 오류를 방지한다 |
| 성능 | C/C++ 수준의 실행 속도를 낸다 |
| 병렬 안전 | 데이터 경쟁(data race)을 컴파일 타임에 차단한다 |

Rust가 이 세 목표를 동시에 달성하는 핵심 메커니즘이 **소유권 시스템**이다. 런타임 비용 없이 컴파일러가 메모리 해제 시점을 결정한다.

---

## 2. Rust vs JavaScript 비교

```
특성              JavaScript                  Rust
--------------------------------------------------------------
패러다임          인터프리터 / JIT 컴파일       AOT 컴파일 (네이티브 코드)
메모리 관리       가비지 컬렉터(GC)             소유권 + 컴파일 타임 검사
타입 시스템       동적 타입 (런타임 검사)        정적 타입 (컴파일 타임 검사)
null 안전         null / undefined 존재          Option<T>로 명시적 표현
에러 처리         try/catch + Promise            Result<T, E> 타입
병렬성            단일 스레드 이벤트 루프        멀티스레드, 소유권이 안전 보장
실행 환경         브라우저 / Node.js             OS 네이티브, WebAssembly 등
```

JavaScript 개발자에게 가장 낯선 개념은 **값이 복사되지 않고 "이동"된다**는 점이다.

---

## 3. 소유권(Ownership)

Rust의 모든 값은 정확히 하나의 변수(소유자)에 속한다. 소유자가 스코프를 벗어나면 값은 즉시 해제된다.

### 3-1. 세 가지 규칙

1. 모든 값에는 소유자가 있다.
2. 소유자는 한 번에 하나만 존재한다.
3. 소유자가 스코프를 벗어나면 값은 해제(drop)된다.

```rust
fn main() {
    {
        let s = String::from("hello"); // s가 소유자
        println!("{}", s);
    } // 이 지점에서 s의 스코프 종료 → String 메모리 자동 해제
    // println!("{}", s); // 컴파일 에러: s는 이미 해제됨
}
```

### 3-2. drop의 의미

C++의 RAII(Resource Acquisition Is Initialization) 패턴과 동일하다. Rust는 `drop` 함수를 스코프 끝에 자동으로 삽입한다. GC 없이 결정론적(deterministic) 해제가 가능한 이유다.

---

## 4. 이동(Move) vs 복사(Copy)

### 4-1. 이동(Move)

힙에 데이터를 저장하는 타입(`String`, `Vec`, 사용자 정의 struct 등)은 대입 시 소유권이 이동한다.

```rust
fn main() {
    let s1 = String::from("hello");
    let s2 = s1; // 소유권이 s1 → s2로 이동

    // println!("{}", s1); // 컴파일 에러: s1은 더 이상 유효하지 않음
    println!("{}", s2); // 정상
}
```

함수에 값을 전달해도 소유권이 이동한다.

```rust
fn take_ownership(s: String) {
    println!("{}", s);
} // s가 해제됨

fn main() {
    let s = String::from("world");
    take_ownership(s);
    // println!("{}", s); // 에러: 소유권이 함수로 이동했음
}
```

### 4-2. 복사(Copy)

스택에 고정 크기로 저장되는 기본 타입(`i32`, `f64`, `bool`, `char`, 고정 크기 배열 등)은 `Copy` 트레이트를 구현한다. 대입 시 값이 복사되어 원본도 유효하다.

```rust
fn main() {
    let x = 5;
    let y = x; // Copy: x의 값이 복사됨
    println!("x={}, y={}", x, y); // 둘 다 유효
}
```

### 4-3. 명시적 복제(Clone)

힙 타입을 복사하려면 `clone()`을 명시적으로 호출한다.

```rust
fn main() {
    let s1 = String::from("hello");
    let s2 = s1.clone(); // 힙 데이터까지 깊은 복사
    println!("s1={}, s2={}", s1, s2); // 둘 다 유효
}
```

---

## 5. 차용(Borrowing)

소유권을 넘기지 않고 값을 빌려 쓰는 메커니즘이다.

### 5-1. 불변 참조(&T)

```rust
fn print_length(s: &String) {
    println!("길이: {}", s.len());
} // 참조가 반납됨. 소유권 이동 없음

fn main() {
    let s = String::from("hello");
    print_length(&s); // 참조를 빌려줌
    println!("{}", s); // s는 여전히 유효
}
```

불변 참조는 동시에 여러 개 존재할 수 있다.

```rust
let s = String::from("hello");
let r1 = &s;
let r2 = &s;
println!("{} {}", r1, r2); // 정상
```

### 5-2. 가변 참조(&mut T)

```rust
fn add_world(s: &mut String) {
    s.push_str(", world");
}

fn main() {
    let mut s = String::from("hello");
    add_world(&mut s);
    println!("{}", s); // "hello, world"
}
```

핵심 제약: **가변 참조는 동시에 하나만 존재할 수 있다.**

```rust
let mut s = String::from("hello");
let r1 = &mut s;
// let r2 = &mut s; // 컴파일 에러: 가변 참조는 동시에 하나만 허용
println!("{}", r1);
```

또한 불변 참조와 가변 참조는 같은 스코프에서 공존할 수 없다.

```rust
let mut s = String::from("hello");
let r1 = &s;     // 불변 참조
let r2 = &s;     // 불변 참조 (여러 개 허용)
// let r3 = &mut s; // 에러: r1, r2가 살아있는 동안 가변 참조 불가
println!("{} {}", r1, r2);
// r1, r2는 여기서 마지막 사용 → 이후에는 가변 참조 가능
let r3 = &mut s;
println!("{}", r3);
```

### 5-3. 댕글링 참조 방지

Rust 컴파일러는 댕글링 참조(해제된 메모리를 가리키는 참조)를 컴파일 타임에 차단한다.

```rust
// fn dangle() -> &String {
//     let s = String::from("hello");
//     &s  // 에러: s는 함수 종료 시 해제되므로 참조를 반환할 수 없음
// }

fn no_dangle() -> String {
    let s = String::from("hello");
    s // 소유권을 반환하면 해제되지 않음
}
```

---

## 6. 수명(Lifetime) 기초

수명은 참조가 유효한 범위를 명시하는 어노테이션이다. 대부분의 경우 컴파일러가 자동으로 추론하지만(수명 생략 규칙), 여러 참조가 얽히면 명시해야 한다.

```rust
// 두 문자열 슬라이스 중 더 긴 것을 반환
// 반환된 참조의 수명은 입력 중 더 짧은 쪽을 따른다
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}

fn main() {
    let s1 = String::from("long string");
    let result;
    {
        let s2 = String::from("xy");
        result = longest(s1.as_str(), s2.as_str());
        println!("longest: {}", result); // 정상: result가 s2 스코프 안에서 사용됨
    }
}
```

수명 어노테이션은 수명을 변경하지 않는다. 컴파일러에게 "이 참조들의 수명이 연관되어 있다"고 알려주는 힌트다.

---

## 7. 기본 문법: 변수, 함수, struct, enum

### 7-1. 변수

```rust
fn main() {
    let x = 5;          // 불변 변수 (기본)
    let mut y = 10;     // 가변 변수
    y += 1;

    let z: f64 = 3.14;  // 타입 명시

    // 섀도잉(shadowing): 같은 이름으로 재선언 가능
    let x = x * 2;      // 새로운 불변 변수 x (이전 x를 가림)
    println!("x={}, y={}, z={}", x, y, z);
}
```

### 7-2. 함수

```rust
fn add(a: i32, b: i32) -> i32 {
    a + b // 마지막 표현식이 반환값 (세미콜론 없음)
}

fn greet(name: &str) -> String {
    format!("Hello, {}!", name)
}

fn main() {
    println!("{}", add(3, 4));
    println!("{}", greet("Rust"));
}
```

### 7-3. struct

```rust
#[derive(Debug)]
struct User {
    username: String,
    email: String,
    age: u32,
}

impl User {
    // 연관 함수 (생성자 역할)
    fn new(username: &str, email: &str, age: u32) -> User {
        User {
            username: String::from(username),
            email: String::from(email),
            age,
        }
    }

    // 메서드 (&self로 불변 참조)
    fn introduce(&self) -> String {
        format!("{}({}세)", self.username, self.age)
    }
}

fn main() {
    let user = User::new("alice", "alice@example.com", 30);
    println!("{}", user.introduce());
    println!("{:?}", user); // Debug 출력
}
```

### 7-4. enum

```rust
#[derive(Debug)]
enum Direction {
    North,
    South,
    East,
    West,
}

#[derive(Debug)]
enum Shape {
    Circle(f64),           // 데이터를 포함하는 variant
    Rectangle(f64, f64),
    Triangle { base: f64, height: f64 }, // 이름 있는 필드
}

fn area(shape: &Shape) -> f64 {
    match shape {
        Shape::Circle(r)               => std::f64::consts::PI * r * r,
        Shape::Rectangle(w, h)         => w * h,
        Shape::Triangle { base, height } => 0.5 * base * height,
    }
}

fn main() {
    let s = Shape::Circle(5.0);
    println!("넓이: {:.2}", area(&s));
}
```

---

## 8. Option과 Result — 에러 처리

### 8-1. Option\<T\>

null 대신 `Option<T>`를 사용한다. 값이 있을 수도, 없을 수도 있음을 타입으로 표현한다.

```rust
fn find_first_even(numbers: &[i32]) -> Option<i32> {
    for &n in numbers {
        if n % 2 == 0 {
            return Some(n);
        }
    }
    None
}

fn main() {
    let nums = vec![1, 3, 4, 7];

    match find_first_even(&nums) {
        Some(n) => println!("첫 번째 짝수: {}", n),
        None    => println!("짝수 없음"),
    }

    // if let으로 간결하게 처리
    if let Some(n) = find_first_even(&nums) {
        println!("발견: {}", n);
    }

    // unwrap_or로 기본값 제공
    let result = find_first_even(&nums).unwrap_or(0);
    println!("결과: {}", result);
}
```

### 8-2. Result\<T, E\>

성공(`Ok`) 또는 실패(`Err`)를 나타낸다. 예외 대신 반환값으로 에러를 처리한다.

```rust
use std::num::ParseIntError;

fn parse_and_double(s: &str) -> Result<i32, ParseIntError> {
    let n = s.trim().parse::<i32>()?; // ? 연산자: 에러면 조기 반환
    Ok(n * 2)
}

fn main() {
    match parse_and_double("21") {
        Ok(n)  => println!("결과: {}", n),  // 42
        Err(e) => println!("에러: {}", e),
    }

    match parse_and_double("abc") {
        Ok(n)  => println!("결과: {}", n),
        Err(e) => println!("에러: {}", e),  // 파싱 실패
    }
}
```

`?` 연산자는 JavaScript의 `await`처럼 에러 시 조기 반환을 간결하게 표현한다.

---

## 9. 패턴 매칭(match)

```rust
fn classify_number(n: i32) -> &'static str {
    match n {
        i32::MIN..=-1 => "음수",
        0             => "영",
        1..=9         => "한 자리 양수",
        _             => "두 자리 이상 양수",
    }
}

fn describe_tuple(pair: (i32, bool)) -> String {
    match pair {
        (0, _)     => String::from("첫 번째가 0"),
        (x, true)  => format!("{} 그리고 참", x),
        (x, false) => format!("{} 그리고 거짓", x),
    }
}

// 구조 분해(destructuring)
struct Point { x: i32, y: i32 }

fn describe_point(p: Point) -> String {
    match p {
        Point { x: 0, y: 0 } => String::from("원점"),
        Point { x, y: 0 }    => format!("x축 위 ({})", x),
        Point { x: 0, y }    => format!("y축 위 ({})", y),
        Point { x, y }       => format!("({}, {})", x, y),
    }
}

fn main() {
    println!("{}", classify_number(-5));
    println!("{}", describe_tuple((3, true)));
    println!("{}", describe_point(Point { x: 0, y: 5 }));
}
```

---

## 10. JavaScript 개발자 주의사항

### 10-1. 변수는 기본적으로 불변

JavaScript의 `let`과 달리 Rust의 `let`은 불변이다. 변경하려면 `let mut`을 명시해야 한다.

### 10-2. 문자열이 두 종류다

- `&str`: 문자열 슬라이스 (불변 참조, 스택/정적 메모리)
- `String`: 힙에 저장된 가변 문자열

함수 인자로는 대개 `&str`을 받고, 소유권이 필요하면 `String`을 사용한다.

### 10-3. 세미콜론 유무가 의미를 바꾼다

```rust
fn five() -> i32 {
    5       // 표현식: 반환값
    // 5;   // 문장: () 반환 → 컴파일 에러
}
```

### 10-4. 클로저와 소유권

```rust
let s = String::from("hello");
let print_s = move || println!("{}", s); // move: 소유권을 클로저로 이동
print_s();
// println!("{}", s); // 에러: s는 클로저로 이동됨
```

### 10-5. 반복자(Iterator)가 지연 평가된다

```rust
let v = vec![1, 2, 3, 4, 5];
let sum: i32 = v.iter()
    .filter(|&&x| x % 2 == 0)
    .map(|&x| x * x)
    .sum();
println!("{}", sum); // 4 + 16 = 20
```

JavaScript의 배열 메서드와 유사하지만, `.collect()` 또는 소비자 메서드(`sum`, `count` 등)가 호출될 때까지 실제로 실행되지 않는다.

---

## 11. 면접 포인트

**Q1. Rust의 소유권 시스템이 해결하는 문제는 무엇인가?**

GC 없이 메모리 안전성을 보장한다. 컴파일 타임에 댕글링 포인터, 이중 해제(double free), use-after-free, 데이터 경쟁을 차단한다. 런타임 오버헤드가 없어 C/C++ 수준 성능을 낸다.

**Q2. 이동(Move)과 복사(Copy)의 차이는?**

Copy 트레이트를 구현한 타입(정수, 부울 등 스택 고정 크기 타입)은 대입 시 값이 복사되어 원본도 유효하다. 그 외 타입은 소유권이 이동하여 원본을 사용할 수 없다. 힙 할당 타입을 복사하려면 `clone()`을 명시해야 한다.

**Q3. 불변 참조와 가변 참조의 동시성 규칙은?**

불변 참조(`&T`)는 동시에 여러 개 가능하다. 가변 참조(`&mut T`)는 동시에 하나만 가능하다. 불변 참조가 살아있는 동안 가변 참조를 만들 수 없다. 이 규칙이 데이터 경쟁을 컴파일 타임에 방지한다.

**Q4. Option과 null의 차이는?**

null은 어떤 타입의 변수에도 들어갈 수 있어 런타임 NullPointerException을 유발한다. `Option<T>`는 타입 시스템에 통합되어 `None` 가능성을 컴파일 타임에 강제 처리하게 만든다. 값을 사용하려면 반드시 `Some`/`None`을 분기해야 한다.

**Q5. 수명(lifetime) 어노테이션이 필요한 경우는?**

함수가 참조를 반환하는데 여러 입력 참조 중 어느 것의 수명을 따르는지 컴파일러가 추론할 수 없을 때 명시한다. 수명 어노테이션은 수명을 연장하거나 변경하지 않으며, 참조 간 수명 관계를 컴파일러에게 알려주는 역할이다.

**Q6. ? 연산자의 동작 원리는?**

`Result` 또는 `Option`을 반환하는 표현식 뒤에 붙인다. 값이 `Ok(v)`/`Some(v)`이면 `v`를 언래핑한다. `Err(e)`/`None`이면 현재 함수에서 즉시 해당 에러/None을 반환한다. `try/catch`와 달리 에러 경로가 타입 시스템에 명시된다.
