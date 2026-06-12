# 3. V8 엔진

## 목차
1. V8 엔진 개요
2. 파싱과 AST 생성
3. Ignition (인터프리터)
4. TurboFan (최적화 컴파일러)
5. JIT 컴파일
6. 히든 클래스 (Hidden Class)
7. 인라인 캐싱 (Inline Caching)
8. 가비지 컬렉션
9. 면접 포인트

---

## 1. V8 엔진 개요

V8은 Google이 개발한 오픈소스 JavaScript/WebAssembly 엔진입니다. Chrome, Node.js, Deno에서 사용됩니다.

```
JS 소스코드
     │
     ▼
[파서(Parser)]
  → 소스를 AST(추상 구문 트리)로 변환
     │
     ▼
[Ignition] ← 인터프리터
  → AST를 바이트코드로 컴파일 후 실행
  → 실행 중 프로파일링 데이터 수집
     │ 핫 코드(자주 실행되는 코드) 발견
     ▼
[TurboFan] ← 최적화 JIT 컴파일러
  → 바이트코드 + 프로파일링 데이터 → 기계어(native code)
  → 가정이 틀리면 Deoptimization → Ignition으로 복귀
```

### V8의 진화

| 버전 | 주요 아키텍처 |
|------|---------------|
| 이전 (2017 이전) | Full-codegen + Crankshaft (JIT만 사용) |
| 현재 | Ignition(인터프리터) + TurboFan(최적화 JIT) |

---

## 2. 파싱과 AST 생성

### 파싱 단계

```
소스 문자열
     │
     ▼ 어휘 분석 (Lexer/Tokenizer)
토큰 스트림: [function] [add] [(] [a] [,] [b] [)] [{] [return] [a] [+] [b] [}]
     │
     ▼ 구문 분석 (Parser)
AST (Abstract Syntax Tree)
```

### AST 예시

```javascript
function add(a, b) {
  return a + b;
}
```

```
FunctionDeclaration
  ├── id: Identifier (name: "add")
  ├── params:
  │     ├── Identifier (name: "a")
  │     └── Identifier (name: "b")
  └── body: BlockStatement
              └── ReturnStatement
                    └── BinaryExpression (operator: "+")
                          ├── Identifier (name: "a")
                          └── Identifier (name: "b")
```

### Eager vs Lazy Parsing

```javascript
// 즉시 파싱(Eager): 최상위 레벨에서 즉시 실행되거나 바로 참조되는 함수
function topLevel() { /* 즉시 파싱 */ }

// 지연 파싱(Lazy): 나중에 호출될 가능성이 높은 내부 함수는 일단 스킵
// 실제로 호출될 때 파싱 (Pre-parser로 기본 구조만 체크)
function outer() {
  function inner() { /* 처음엔 지연 파싱 */ }
  return inner;
}
```

---

## 3. Ignition (인터프리터)

Ignition은 AST를 받아 **바이트코드(bytecode)**로 컴파일하고 실행합니다.

### 바이트코드 예시

```javascript
function add(a, b) { return a + b; }
add(1, 2);
```

```
// Ignition이 생성하는 바이트코드 (단순화)
LdaNamedProperty r0, [0]   // r0(a) 로드
Add r1, [1]                 // r1(b)와 더하기
Return                      // 결과 반환
```

### Ignition의 역할

1. AST → 바이트코드 변환 (빠름, 메모리 효율적)
2. 바이트코드 즉시 실행
3. 실행 횟수, 타입 정보 등 **프로파일링 데이터** 수집
4. 자주 실행되는 "핫(hot)" 함수 식별 → TurboFan에 전달

---

## 4. TurboFan (최적화 컴파일러)

TurboFan은 Ignition이 수집한 프로파일링 데이터를 바탕으로 **고도로 최적화된 기계어**를 생성합니다.

### 최적화 과정

```
바이트코드 + 프로파일링 데이터
         │
         ▼
Sea of Nodes (중간 표현, IR)
         │
         ▼
여러 최적화 패스:
  - Inlining: 짧은 함수 호출을 호출 지점에 펼침
  - Dead code elimination: 실행 불가 코드 제거
  - Constant folding: 2+3 → 5로 컴파일 타임 계산
  - Type specialization: 타입이 항상 number면 정수 연산으로 특화
         │
         ▼
기계어 (Native Code) → 실행
```

### Deoptimization (최적화 해제)

```javascript
function add(a, b) { return a + b; }

add(1, 2);      // 10000번 실행 → TurboFan이 "a, b는 항상 number"로 가정하여 최적화
add("1", "2");  // 갑자기 string → 가정이 틀림 → Deopt!
                // Ignition으로 돌아가 재실행
```

Deoptimization은 성능 저하를 유발합니다. 일관된 타입 사용이 중요한 이유입니다.

---

## 5. JIT 컴파일

JIT(Just-In-Time) 컴파일은 실행 중에 코드를 기계어로 컴파일하는 기법입니다.

```
AOT (Ahead-of-Time) 컴파일: 실행 전 기계어 변환 (C, Go 등)
  장점: 최초 실행 빠름
  단점: 플랫폼별 바이너리, 초기 배포 시간

JIT 컴파일: 실행 중에 기계어로 변환
  장점: 런타임 타입 정보 활용해 최적화, 플랫폼 독립적
  단점: 워밍업(warm-up) 시간, 메모리 사용
```

### V8의 Tiered JIT

```
코드 처음 실행
      │
      ▼
Ignition (인터프리터): 느리지만 즉시 시작 가능
      │ 많이 실행됨 (hot)
      ▼
TurboFan (최적화 JIT): 빠른 기계어 실행
      │ 가정이 틀림
      ▼
Deoptimization → Ignition으로 복귀
```

---

## 6. 히든 클래스 (Hidden Class)

JavaScript는 동적 타입이지만, V8은 내부적으로 **히든 클래스**를 사용해 객체의 구조를 추적하고 정적 언어처럼 최적화합니다.

### 히든 클래스 생성 예시

```javascript
function Point(x, y) {
  this.x = x; // 히든 클래스 C0: {} → C1: {x}
  this.y = y; // 히든 클래스 C1: {x} → C2: {x, y}
}

const p1 = new Point(1, 2); // C0 → C1 → C2 전이
const p2 = new Point(3, 4); // C2를 재사용! (같은 히든 클래스)
```

### 히든 클래스 최적화 깨는 패턴

```javascript
// 나쁜 패턴 1: 프로퍼티 추가 순서가 다름
const a = {};
a.x = 1; a.y = 2; // C0 → C1{x} → C2{x,y}

const b = {};
b.y = 1; b.x = 2; // C0 → C1{y} → C3{y,x} ← 다른 히든 클래스!

// 나쁜 패턴 2: 나중에 프로퍼티 추가
function Person(name) {
  this.name = name;
}
const p = new Person("Alice");
p.age = 30; // 새 히든 클래스 생성 → 최적화 깨짐

// 좋은 패턴: 생성자에서 모든 프로퍼티 초기화
function PersonGood(name, age) {
  this.name = name;
  this.age = age;  // 일관된 구조
}

// 나쁜 패턴 3: delete 연산자
delete p.name; // 히든 클래스에서 프로퍼티 제거 → 최적화 깨짐
// 대신: p.name = undefined; 또는 null 할당
```

---

## 7. 인라인 캐싱 (Inline Caching, IC)

V8은 같은 위치에서 반복 실행되는 연산의 결과를 캐싱해 성능을 높입니다.

### 종류

```javascript
// Monomorphic IC: 항상 같은 히든 클래스 → 최상의 성능
function getX(point) {
  return point.x; // 항상 C2 히든 클래스 → 오프셋 캐싱
}
getX(new Point(1, 2));
getX(new Point(3, 4));

// Polymorphic IC: 2~4개의 서로 다른 히든 클래스 → 약간 느림
function getLength(obj) {
  return obj.length; // string, array 등 여러 타입 → 짧은 캐시 목록
}
getLength("hello");
getLength([1, 2, 3]);

// Megamorphic IC: 5개 이상 → 캐시 효과 없음, 매번 조회
function getValue(obj) {
  return obj.value; // 수십 가지 다른 구조 → 전역 캐시 테이블 사용
}
```

### 성능 최적화 팁

```javascript
// 1. 타입 일관성 유지 (Monomorphic 유지)
function processUser(user) {
  return user.name.toUpperCase();
  // user 객체가 항상 같은 구조면 IC가 최적화됨
}

// 2. 같은 위치에서 같은 타입 사용
function sum(a, b) {
  return a + b;
}
// sum(1, 2) 만 호출하면 number IC
// sum("a", "b")를 추가하면 string도 처리 → polymorphic

// 3. 배열 타입 일관성 (SMI, Double, Object 배열 구분)
const intArr = [1, 2, 3];          // SMI (Small Integer) 배열 → 최적화
const mixArr = [1, 2.5, 3];        // Double 배열
const objArr = [1, "two", { n: 3 }]; // Object 배열 → 가장 느림
```

---

## 8. 가비지 컬렉션

V8은 **세대별(Generational) GC**를 사용합니다.

```
힙(Heap) 구조:
┌───────────────────────────────────────────────────┐
│  New Space (Young Generation)                     │
│  ┌─────────────┐  ┌─────────────┐                │
│  │ From Space  │  │  To Space   │  작은 객체 생성  │
│  │(Scavenge 후)│  │(현재 할당)  │  Minor GC로 관리 │
│  └─────────────┘  └─────────────┘                │
├───────────────────────────────────────────────────┤
│  Old Space (Old Generation)                       │
│  오래된 객체 (2번 이상 Minor GC 생존)              │
│  Mark-Sweep-Compact로 관리 (Major GC)             │
└───────────────────────────────────────────────────┘
```

- **Minor GC (Scavenge)**: New Space에서 자주 실행, 짧은 일시정지
- **Major GC (Mark-Sweep-Compact)**: Old Space 전체, 오래 걸림
- **Incremental Marking**: Major GC를 여러 작은 단계로 나눠 main thread 정지 최소화

---

## 9. 면접 포인트

### Q1. V8의 JIT 컴파일 과정을 설명해주세요.

소스코드 파싱으로 AST를 생성하고, Ignition 인터프리터가 AST를 바이트코드로 컴파일해 실행합니다. 실행 중 자주 호출되는 "핫" 함수가 발견되면 수집한 타입 프로파일링 데이터와 함께 TurboFan 최적화 컴파일러로 전달해 고성능 기계어로 변환합니다. 이후 타입 가정이 틀어지면 Deoptimization이 발생해 다시 Ignition으로 복귀합니다.

### Q2. 히든 클래스를 깨지 않으려면 어떻게 코드를 작성해야 하나요?

1. 생성자/클래스에서 모든 프로퍼티를 초기화하고, 나중에 동적으로 추가하지 않기
2. 여러 인스턴스 간 프로퍼티 추가 순서를 동일하게 유지하기
3. `delete` 대신 `null`이나 `undefined` 할당
4. 타입을 변경하지 않기 (처음에 number로 초기화한 프로퍼티에 string 할당 금지)

### Q3. Deoptimization은 왜 성능에 나쁜가요?

TurboFan이 생성한 최적화 기계어를 버리고 바이트코드 실행(Ignition)으로 복귀합니다. 뿐만 아니라 이후 다시 충분히 "핫"해질 때까지 최적화 컴파일이 일어나지 않을 수 있습니다. 실제 성능 문제보다 Deopt 발생 자체가 "코드에 타입 불일치가 있다"는 신호이므로, Chrome DevTools의 "Optimize function" 상태를 확인해 Deopt 여부를 모니터링할 수 있습니다.

### Q4. V8의 가비지 컬렉션이 성능에 미치는 영향은?

Major GC는 Old Space 전체를 스캔하므로 main thread를 수십~수백 ms 정지시킬 수 있습니다. 이를 줄이려면: 단명(short-lived) 객체를 많이 생성하고(New Space에서 처리), 큰 캐시나 전역 상태는 최소화하며, 객체 풀링(pooling)으로 재사용하는 방법이 있습니다. V8은 Incremental Marking과 Concurrent GC로 정지 시간을 최소화하고 있습니다.
