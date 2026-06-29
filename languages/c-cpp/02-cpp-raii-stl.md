# 2. C++ 심화 — RAII · 스마트 포인터 · 이동 시맨틱 · STL

> [01 기초](./01-basics.md)에서 C의 포인터·수동 메모리 관리(`malloc`/`free`)·누수를 다뤘다. 여기서는 C++가 그 수동 관리를 **타입 시스템으로 자동화**하는 방법(RAII, 스마트 포인터, 이동 시맨틱)과 STL을 다룬다. JS 개발자 관점에서 "GC 없이 어떻게 누수를 막는가"가 핵심 질문이다.

## 목차
1. [RAII — 자원 관리의 핵심 원리](#1-raii--자원-관리의-핵심-원리)
2. [unique_ptr — 단일 소유](#2-unique_ptr--단일-소유)
3. [shared_ptr / weak_ptr — 공유 소유](#3-shared_ptr--weak_ptr--공유-소유)
4. [복사 vs 이동 시맨틱](#4-복사-vs-이동-시맨틱)
5. [참조와 const](#5-참조와-const)
6. [STL — 컨테이너 · 반복자 · 알고리즘](#6-stl--컨테이너--반복자--알고리즘)
7. [면접 포인트](#7-면접-포인트)

---

## 1. RAII — 자원 관리의 핵심 원리

**RAII**(Resource Acquisition Is Initialization): 자원의 수명을 **객체의 수명에 묶는다**. 생성자에서 자원을 획득하고 소멸자에서 해제하면, 객체가 스코프를 벗어날 때 자동으로 정리된다 — 예외가 나도, 어디로 return해도.

```cpp
class File {
    FILE* fp;
public:
    File(const char* path)  { fp = fopen(path, "r"); }  // 획득
    ~File()                 { if (fp) fclose(fp); }      // 해제 (자동 호출)
};

void read() {
    File f("data.txt");   // 생성
    // ... 예외가 나도, return해도 ...
}                         // 스코프 종료 → ~File() 자동 호출 → fclose 보장
```

> C의 `malloc`/`free`나 `fopen`/`fclose`는 짝을 수동으로 맞춰야 해 누수·이중 해제가 생긴다. RAII는 그 짝을 컴파일러가 보장한다. Python의 `with`, Rust의 `Drop`이 같은 아이디어다.

---

## 2. unique_ptr — 단일 소유

힙 객체의 **소유자가 하나뿐**임을 타입으로 표현. 스코프를 벗어나면 자동 `delete`. 복사 불가, 이동만 가능.

```cpp
#include <memory>

auto p = std::make_unique<int>(42);   // new int(42)
// auto q = p;          // ❌ 컴파일 에러: 복사 불가 (소유자는 하나)
auto q = std::move(p);  // ✅ 소유권 이동 — 이제 p는 nullptr
// q가 스코프를 벗어나면 자동 delete (수동 free 불필요)
```

- 런타임 오버헤드 0 (raw 포인터와 동일 크기·속도). **기본 선택지.**
- 소유권을 함수에 넘길 땐 `std::move`로 명시적 이전.

---

## 3. shared_ptr / weak_ptr — 공유 소유

여러 소유자가 같은 객체를 공유할 때. **참조 카운트**로 마지막 소유자가 사라지면 해제 (원자적 카운트라 Rust의 `Arc`에 대응 — 비원자적 `Rc`가 아님).

```cpp
auto a = std::make_shared<int>(10);
auto b = a;                          // 카운트 2 (복사 허용)
std::cout << a.use_count();          // 2
// a, b 모두 소멸 → 카운트 0 → 자동 해제
```

- 카운트 조작이 **원자적**이라 멀티 스레드 안전(약간의 비용 있음).
- **순환 참조 누수**: A→B→A가 서로 `shared_ptr`면 카운트가 0이 안 됨 → 한쪽을 `weak_ptr`(카운트 안 올림)로.

```cpp
struct Node {
    std::shared_ptr<Node> next;
    std::weak_ptr<Node> prev;   // 순환을 끊기 위해 weak
};
```

> GC 없는 언어(C++/Rust)의 RC 방식은 모두 순환 참조를 자동 회수하지 못한다. JS GC는 mark-and-sweep으로 순환까지 회수하지만 정지(pause)가 있다 — 이게 결정적 소멸 vs GC의 트레이드오프다.

---

## 4. 복사 vs 이동 시맨틱

C++11의 핵심. 큰 객체를 복사하지 않고 **자원을 훔쳐(이동)** 성능을 높인다.

```cpp
std::vector<int> make() {
    std::vector<int> v(1000000);
    return v;                    // 복사 아닌 이동 (또는 RVO로 복사 자체 제거)
}
std::vector<int> data = make();  // 100만 개를 복사하지 않음

std::string a = "hello";
std::string b = std::move(a);    // a의 내부 버퍼를 b로 이동, a는 유효하지만 미지정 상태(보통 빈 문자열)
```

- **lvalue**(이름 있는 값) vs **rvalue**(임시값). `&&`는 rvalue 참조 = "이동해도 되는 임시".
- 이동 생성자/이동 대입(`T(T&&)`, `operator=(T&&)`)이 자원 포인터만 옮기고 원본을 비운다.
- `std::move`는 사실 이동을 *하지 않고*, 값을 rvalue로 **캐스팅**해 이동 오버로드를 부를 뿐이다.

> JS엔 이 개념이 없다 — 객체는 항상 참조로 전달되고 GC가 정리한다. C++는 값 시맨틱이 기본이라 "복사를 피하는 이동"이 성능의 핵심이 된다.

---

## 5. 참조와 const

```cpp
void f(const std::string& s);  // const 참조: 복사 없이 읽기 전용 전달 (가장 흔함)
void g(std::string& s);        // 비const 참조: 호출자 변수를 직접 수정
void h(std::string s);         // 값 복사 (작은 타입이나 소유권 가질 때)
```

- 큰 객체를 읽기만 할 땐 `const T&`로 복사를 피한다(JS는 항상 참조라 고민할 필요 없는 부분).
- 참조는 "널이 될 수 없는 별칭"이라 포인터보다 안전. 재바인딩 불가.

---

## 6. STL — 컨테이너 · 반복자 · 알고리즘

STL은 **컨테이너 + 반복자 + 알고리즘**의 직교 설계다. 알고리즘은 컨테이너를 모른 채 반복자만으로 동작한다.

```cpp
#include <vector>
#include <algorithm>

std::vector<int> v = {5, 2, 8, 1, 9};
std::sort(v.begin(), v.end());                 // 정렬
auto it = std::find(v.begin(), v.end(), 8);    // 탐색

int cnt = std::count_if(v.begin(), v.end(),
                        [](int x){ return x > 3; });  // 람다 (JS 화살표함수)
```

| 컨테이너 | 특성 | JS 대응 |
|---------|------|---------|
| `vector` | 동적 배열, 연속 메모리 | `Array` |
| `map` / `set` | 정렬된 트리(O(log n)) | `Map`/`Set`(삽입 순서, 정렬 아님) |
| `unordered_map` | 해시(O(1) 평균) | `Map`/`Object` |
| `deque` | 양끝 삽입 빠름 | — |

- 람다: `[캡처](인자){ 본문 }`. `[=]` 값 캡처, `[&]` 참조 캡처.
- 범위 기반 for: `for (auto& x : v)` — JS의 `for...of`.

---

## 7. 면접 포인트

**Q. RAII란 무엇이고 왜 중요한가요?**
> 자원의 수명을 객체 수명에 묶어, 생성자에서 획득·소멸자에서 해제하는 패턴. 스코프를 벗어나면(예외가 나도) 소멸자가 자동 호출돼 메모리·파일·락 누수를 막는다. C++ 자원 관리의 근간이며 Python `with`, Rust `Drop`과 같은 아이디어다.

**Q. `unique_ptr`와 `shared_ptr`의 차이는?**
> `unique_ptr`는 단일 소유로 복사 불가·이동만 가능하며 런타임 비용이 0이라 기본 선택지다. `shared_ptr`는 참조 카운트로 여러 소유자가 공유하며 카운트 조작 비용이 있고, 순환 참조 누수를 막으려 `weak_ptr`를 함께 쓴다.

**Q. 이동 시맨틱(move semantics)이 왜 필요한가요?**
> 큰 객체를 반환·전달할 때 깊은 복사 대신 내부 자원(포인터)만 옮겨 성능을 높인다. `&&`(rvalue 참조)로 "이동해도 되는 임시값"을 받고, 이동 생성자가 원본을 비운다. `std::move`는 실제로 이동하는 게 아니라 값을 rvalue로 캐스팅해 이동 오버로드를 부른다.

**Q. GC 없는 C++가 어떻게 메모리 누수를 막나요?**
> RAII + 스마트 포인터. 소유권을 타입으로 표현하고 소멸자가 결정적으로 해제하므로 GC가 필요 없다. 다만 `shared_ptr` 순환 참조는 자동 회수되지 않아 `weak_ptr`로 끊어야 한다 — JS GC가 mark-and-sweep으로 순환까지 처리하는 것과 대비된다.

**Q. STL의 설계 철학은?**
> 컨테이너·반복자·알고리즘의 분리. 알고리즘(`sort`, `find`)은 컨테이너 종류를 모른 채 반복자 인터페이스만으로 동작해, N개 알고리즘 × M개 컨테이너 조합을 N+M 구현으로 커버한다.

**Q. `const T&`로 인자를 받는 이유는?**
> 큰 객체를 복사 없이(참조) 읽기 전용으로 전달하기 위해서다. 값 복사 비용을 없애면서 함수가 원본을 수정하지 못하게 보장한다. JS는 객체가 항상 참조 전달이라 고민이 없지만 C++는 값 시맨틱이 기본이라 명시해야 한다.
