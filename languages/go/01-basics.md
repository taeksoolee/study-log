# 1. Go 기초

## 목차
1. Go 언어 특징과 사용 분야
2. Go vs JavaScript 비교
3. 기본 문법: 변수 선언, 타입 시스템
4. 함수 (다중 반환값, defer, panic/recover)
5. 구조체(struct)와 메서드
6. 인터페이스(interface)
7. 고루틴(Goroutine)
8. 채널(Channel)
9. sync 패키지
10. Go vs Node.js 동시성 모델 비교
11. 면접 포인트

---

## 1. Go 언어 특징과 사용 분야

Go(Golang)는 2009년 Google이 공개한 정적 타입 컴파일 언어입니다.

### 핵심 특징
- **컴파일 언어**: 빠른 컴파일 속도, 단일 바이너리 생성
- **정적 타입**: 컴파일 타임 타입 체크
- **가비지 컬렉션**: C처럼 수동 메모리 관리 불필요
- **고루틴(Goroutine)**: 경량 동시성 내장
- **채널(Channel)**: CSP(Communicating Sequential Processes) 기반 동기화
- **인터페이스**: 암묵적 구현 (duck typing)
- **에러 처리**: 명시적 에러 반환 (예외 없음)
- **빠른 컴파일**: 대규모 코드베이스에서도 빠름

### 주요 사용 분야
| 분야 | 예시 |
|------|------|
| 백엔드 API 서버 | Docker, Kubernetes, Caddy |
| 시스템 도구 | CLI 도구, 파일 처리 |
| 네트워크 서비스 | 프록시, 로드밸런서 |
| 마이크로서비스 | gRPC 기반 서비스 |
| 클라우드 인프라 | Terraform, Prometheus |

---

## 2. Go vs JavaScript 비교

| 항목 | Go | JavaScript |
|------|-----|------------|
| 타입 시스템 | 정적 타입 | 동적 타입 |
| 컴파일 | 컴파일 언어 | 인터프리터/JIT |
| 동시성 | 고루틴 + 채널 | 단일 스레드 + 이벤트 루프 |
| 에러 처리 | 반환값으로 처리 | try/catch + Promise |
| 클래스 | 없음 (struct + method) | class (ES6+) |
| 상속 | 없음 (컴포지션) | 프로토타입 체인 |
| null 안전 | 포인터 + nil | null/undefined |
| 제너릭 | Go 1.18+ 지원 | 없음 (TypeScript 있음) |
| 패키지 관리 | go mod | npm/yarn |
| 실행 환경 | OS 네이티브 바이너리 | Node.js / 브라우저 |

```go
// Go의 Hello World
package main

import "fmt"

func main() {
    fmt.Println("Hello, World!")
}
```

```javascript
// JavaScript의 Hello World
console.log("Hello, World!");
```

---

## 3. 기본 문법: 변수 선언, 타입 시스템

### 변수 선언

```go
package main

import "fmt"

func main() {
    // var 키워드 (명시적 선언)
    var name string = "Alice"
    var age int = 30
    var isActive bool = true

    // 타입 추론 (var + 초기값)
    var pi = 3.14  // float64로 추론

    // 단축 선언 (:= ) - 함수 내부에서만 사용 가능
    city := "Seoul"
    count := 0

    // 다중 변수 선언
    var x, y int = 1, 2
    a, b := "hello", 42

    // 상수
    const MaxSize = 100
    const (
        StatusOK  = 200
        StatusNotFound = 404
    )

    fmt.Println(name, age, isActive, pi, city, count, x, y, a, b)
}
```

### 기본 타입

```go
// 정수형
var i8 int8   = 127
var i16 int16 = 32767
var i32 int32 = 2147483647
var i64 int64 = 9223372036854775807
var i int     = 42       // 플랫폼에 따라 32 또는 64비트

// 부호 없는 정수
var u uint = 42
var u8 uint8 = 255  // byte와 동일

// 실수형
var f32 float32 = 3.14
var f64 float64 = 3.14159265358979  // 기본 실수 타입

// 문자열 (불변, UTF-8)
var s string = "Hello, 세계"

// 불리언
var b bool = true

// 바이트와 룬
var bt byte = 'A'      // uint8 별칭
var r rune = '한'      // int32 별칭, Unicode 코드 포인트

// 타입 변환 (암묵적 변환 없음, 반드시 명시)
var a int = 42
var f float64 = float64(a)  // 명시적 변환 필수
```

### 배열과 슬라이스

```go
// 배열: 고정 크기
arr := [3]int{1, 2, 3}
arr2 := [...]int{1, 2, 3, 4}  // 크기 자동 결정

// 슬라이스: 동적 크기 (JS 배열과 유사)
s := []int{1, 2, 3}
s = append(s, 4, 5)

// make로 생성: make(type, len, cap)
s2 := make([]int, 5)      // 길이 5, 용량 5
s3 := make([]int, 3, 10)  // 길이 3, 용량 10

// 슬라이싱
sub := s[1:3]  // 인덱스 1~2

// 2D 슬라이스
matrix := [][]int{
    {1, 2, 3},
    {4, 5, 6},
}

// 맵 (해시맵)
m := map[string]int{
    "alice": 95,
    "bob":   87,
}
m["charlie"] = 92
delete(m, "bob")

// 값 존재 여부 확인
val, ok := m["alice"]  // ok: bool
if ok {
    fmt.Println(val)
}
```

---

## 4. 함수

### 기본 함수와 다중 반환값

```go
package main

import (
    "errors"
    "fmt"
)

// 기본 함수
func add(a, b int) int {
    return a + b
}

// 다중 반환값 (Go의 특징)
func divide(a, b float64) (float64, error) {
    if b == 0 {
        return 0, errors.New("division by zero")
    }
    return a / b, nil
}

// 명명된 반환값
func minMax(nums []int) (min, max int) {
    min, max = nums[0], nums[0]
    for _, n := range nums {
        if n < min {
            min = n
        }
        if n > max {
            max = n
        }
    }
    return  // naked return
}

func main() {
    result, err := divide(10, 3)
    if err != nil {
        fmt.Println("에러:", err)
        return
    }
    fmt.Printf("결과: %.2f\n", result)

    lo, hi := minMax([]int{3, 1, 4, 1, 5, 9})
    fmt.Println(lo, hi)  // 1 9
}
```

### 가변 인수, 함수값, 클로저

```go
// 가변 인수 (variadic)
func sum(nums ...int) int {
    total := 0
    for _, n := range nums {
        total += n
    }
    return total
}

// 슬라이스 전개
nums := []int{1, 2, 3, 4, 5}
fmt.Println(sum(nums...))

// 함수를 값으로 (일급 함수)
apply := func(f func(int) int, n int) int {
    return f(n)
}
double := func(n int) int { return n * 2 }
fmt.Println(apply(double, 5))  // 10

// 클로저
func makeCounter() func() int {
    count := 0
    return func() int {
        count++
        return count
    }
}

counter := makeCounter()
fmt.Println(counter())  // 1
fmt.Println(counter())  // 2
fmt.Println(counter())  // 3
```

### defer, panic, recover

```go
import "fmt"

// defer: 함수 종료 시 실행 (LIFO 순서)
func readFile(path string) {
    fmt.Println("파일 열기")
    defer fmt.Println("파일 닫기")  // 함수 끝에 실행
    fmt.Println("파일 읽기")
    // 출력: 파일 열기 -> 파일 읽기 -> 파일 닫기
}

// panic과 recover (JS의 throw/catch와 유사)
func safeDiv(a, b int) (result int, err error) {
    defer func() {
        if r := recover(); r != nil {
            err = fmt.Errorf("패닉 복구: %v", r)
        }
    }()
    if b == 0 {
        panic("0으로 나누기 시도")
    }
    return a / b, nil
}

func main() {
    result, err := safeDiv(10, 0)
    if err != nil {
        fmt.Println(err)  // 패닉 복구: 0으로 나누기 시도
    } else {
        fmt.Println(result)
    }
}
```

---

## 5. 구조체(struct)와 메서드

```go
package main

import (
    "fmt"
    "math"
)

// 구조체 정의
type Point struct {
    X, Y float64
}

type Circle struct {
    Center Point
    Radius float64
}

// 메서드: 값 리시버 (복사본)
func (c Circle) Area() float64 {
    return math.Pi * c.Radius * c.Radius
}

// 메서드: 포인터 리시버 (원본 수정 가능)
func (c *Circle) Scale(factor float64) {
    c.Radius *= factor
}

// 생성자 패턴 (Go에는 생성자 없음, 관례적으로 NewXxx 함수 사용)
func NewCircle(x, y, r float64) *Circle {
    return &Circle{
        Center: Point{X: x, Y: y},
        Radius: r,
    }
}

// 구조체 임베딩 (컴포지션, 상속 대체)
type Animal struct {
    Name string
}

func (a Animal) Speak() string {
    return a.Name + "이(가) 소리를 냄"
}

type Dog struct {
    Animal          // 임베딩
    Breed string
}

func main() {
    c := NewCircle(0, 0, 5)
    fmt.Printf("넓이: %.2f\n", c.Area())
    c.Scale(2)
    fmt.Printf("확대 후 반지름: %.2f\n", c.Radius)

    dog := Dog{
        Animal: Animal{Name: "바둑이"},
        Breed:  "진돗개",
    }
    fmt.Println(dog.Speak())  // 임베딩된 메서드 접근
    fmt.Println(dog.Name)     // 임베딩된 필드 접근
}
```

---

## 6. 인터페이스(interface)

```go
package main

import (
    "fmt"
    "math"
)

// 인터페이스 정의
type Shape interface {
    Area() float64
    Perimeter() float64
}

type Rectangle struct {
    Width, Height float64
}

// 암묵적 구현 (implements 키워드 없음)
func (r Rectangle) Area() float64 {
    return r.Width * r.Height
}

func (r Rectangle) Perimeter() float64 {
    return 2 * (r.Width + r.Height)
}

type Circle struct {
    Radius float64
}

func (c Circle) Area() float64 {
    return math.Pi * c.Radius * c.Radius
}

func (c Circle) Perimeter() float64 {
    return 2 * math.Pi * c.Radius
}

// 인터페이스를 매개변수로
func printShape(s Shape) {
    fmt.Printf("넓이: %.2f, 둘레: %.2f\n", s.Area(), s.Perimeter())
}

// 빈 인터페이스 (any, 모든 타입 허용)
func printAny(v interface{}) {
    fmt.Printf("타입: %T, 값: %v\n", v, v)
}

// 타입 단언 (type assertion)
func checkType(v interface{}) {
    // 단일 타입 단언
    if s, ok := v.(string); ok {
        fmt.Println("문자열:", s)
    }

    // 타입 스위치
    switch val := v.(type) {
    case int:
        fmt.Println("정수:", val)
    case string:
        fmt.Println("문자열:", val)
    case bool:
        fmt.Println("불리언:", val)
    default:
        fmt.Printf("알 수 없는 타입: %T\n", val)
    }
}

func main() {
    shapes := []Shape{
        Rectangle{Width: 3, Height: 4},
        Circle{Radius: 5},
    }
    for _, s := range shapes {
        printShape(s)
    }
}
```

---

## 7. 고루틴(Goroutine)

```go
package main

import (
    "fmt"
    "time"
)

func worker(id int) {
    fmt.Printf("워커 %d 시작\n", id)
    time.Sleep(time.Second)
    fmt.Printf("워커 %d 완료\n", id)
}

func main() {
    // go 키워드로 고루틴 생성
    // OS 스레드보다 훨씬 가벼운 경량 스레드 (초기 ~2KB 스택)
    go worker(1)
    go worker(2)
    go worker(3)

    // main 함수가 끝나면 모든 고루틴도 종료됨
    // 실제 코드에서는 WaitGroup이나 채널로 동기화 필요
    time.Sleep(2 * time.Second)
}

// 고루틴의 특징
// - Go 런타임이 관리하는 경량 스레드 (수천~수만 개 동시 실행 가능)
// - M:N 스레드 모델: 많은 고루틴을 적은 OS 스레드에 매핑
// - 스케줄러: GOMAXPROCS 설정으로 병렬 실행 제어
// - 스택: 동적으로 확장/축소 (초기 2KB, 최대 1GB)
```

---

## 8. 채널(Channel)

```go
package main

import "fmt"

func main() {
    // 채널 생성: make(chan 타입, 버퍼크기)
    ch := make(chan int)       // 비버퍼 채널 (동기)
    bch := make(chan int, 5)   // 버퍼 채널 (비동기, 최대 5개)

    // 기본 송수신
    go func() {
        ch <- 42  // 송신 (수신자가 받을 때까지 블록)
    }()
    val := <-ch  // 수신 (송신자가 보낼 때까지 블록)
    fmt.Println(val)

    // 버퍼 채널: 버퍼 차기 전까지 블록 안 됨
    bch <- 1
    bch <- 2
    fmt.Println(<-bch)  // 1

    _ = bch
}

// 방향성 채널: 읽기/쓰기 전용
func producer(ch chan<- int) {  // 쓰기 전용
    for i := 0; i < 5; i++ {
        ch <- i
    }
    close(ch)  // 채널 닫기
}

func consumer(ch <-chan int) {  // 읽기 전용
    for val := range ch {  // 채널이 닫힐 때까지 수신
        fmt.Println(val)
    }
}

// select문: 여러 채널 동시 대기
func selectExample() {
    ch1 := make(chan string)
    ch2 := make(chan string)

    go func() { ch1 <- "one" }()
    go func() { ch2 <- "two" }()

    for i := 0; i < 2; i++ {
        select {
        case msg1 := <-ch1:
            fmt.Println("ch1로부터:", msg1)
        case msg2 := <-ch2:
            fmt.Println("ch2로부터:", msg2)
        case <-time.After(time.Second):  // 타임아웃
            fmt.Println("타임아웃")
        default:  // 즉시 처리 (논블로킹)
            fmt.Println("채널 준비 안 됨")
        }
    }
}

// 완전한 생산자-소비자 패턴
func pipeline() {
    naturals := make(chan int)
    squares := make(chan int)

    // 생산자
    go func() {
        for i := 0; i < 5; i++ {
            naturals <- i
        }
        close(naturals)
    }()

    // 변환기
    go func() {
        for n := range naturals {
            squares <- n * n
        }
        close(squares)
    }()

    // 소비자
    for sq := range squares {
        fmt.Println(sq)
    }
}
```

---

## 9. sync 패키지

```go
package main

import (
    "fmt"
    "sync"
    "sync/atomic"
)

// WaitGroup: 고루틴 완료 대기
func waitGroupExample() {
    var wg sync.WaitGroup

    for i := 0; i < 5; i++ {
        wg.Add(1)  // 카운터 증가
        go func(id int) {
            defer wg.Done()  // 완료 시 카운터 감소
            fmt.Printf("워커 %d 실행 중\n", id)
        }(i)
    }

    wg.Wait()  // 모든 고루틴 완료 대기
    fmt.Println("모든 워커 완료")
}

// Mutex: 공유 자원 보호
type SafeCounter struct {
    mu    sync.Mutex
    count int
}

func (c *SafeCounter) Increment() {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.count++
}

func (c *SafeCounter) Value() int {
    c.mu.Lock()
    defer c.mu.Unlock()
    return c.count
}

// RWMutex: 읽기/쓰기 분리 락
type Cache struct {
    mu   sync.RWMutex
    data map[string]string
}

func (c *Cache) Get(key string) (string, bool) {
    c.mu.RLock()  // 여러 고루틴이 동시에 읽기 가능
    defer c.mu.RUnlock()
    val, ok := c.data[key]
    return val, ok
}

func (c *Cache) Set(key, value string) {
    c.mu.Lock()  // 쓰기는 단독 락
    defer c.mu.Unlock()
    c.data[key] = value
}

// Once: 한 번만 실행
var (
    instance *Cache
    once     sync.Once
)

func getInstance() *Cache {
    once.Do(func() {
        instance = &Cache{data: make(map[string]string)}
    })
    return instance
}

// atomic: 원자적 연산 (Mutex보다 가벼움)
func atomicExample() {
    var counter int64
    var wg sync.WaitGroup

    for i := 0; i < 1000; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            atomic.AddInt64(&counter, 1)
        }()
    }

    wg.Wait()
    fmt.Println(atomic.LoadInt64(&counter))  // 1000
}
```

---

## 10. Go vs Node.js 동시성 모델 비교

| 항목 | Go (고루틴) | Node.js (이벤트 루프) |
|------|------------|----------------------|
| 동시성 모델 | M:N 스레드, CSP | 단일 스레드, 이벤트 루프 |
| CPU 바운드 | 병렬 처리 가능 (멀티코어) | 단일 스레드라 제한적 |
| I/O 바운드 | 비동기 I/O + 고루틴 블로킹 OK | 비동기 콜백/Promise |
| 코드 스타일 | 동기 코드처럼 작성 | async/await 필요 |
| 메모리 | 고루틴당 ~2KB 시작 | 스레드 하나 (공유) |
| 확장성 | 수십만 고루틴 가능 | 리소스 효율적이나 CPU 한계 |
| 에러 처리 | 반환값으로 명시적 처리 | try/catch + .catch() |

```go
// Go: 동기 스타일 코드 (내부적으로 비동기)
func fetchAll(urls []string) []string {
    results := make([]string, len(urls))
    var wg sync.WaitGroup

    for i, url := range urls {
        wg.Add(1)
        go func(i int, url string) {
            defer wg.Done()
            results[i] = fetch(url)  // 블로킹처럼 보이지만 고루틴 전환
        }(i, url)
    }

    wg.Wait()
    return results
}
```

```javascript
// Node.js: async/await로 비동기 처리
async function fetchAll(urls) {
    const results = await Promise.all(
        urls.map(url => fetch(url).then(r => r.text()))
    );
    return results;
}
```

### Go의 동시성 철학
- **"메모리를 공유하여 통신하지 말고, 통신하여 메모리를 공유하라"**
- 채널을 통한 데이터 전달로 경쟁 조건(race condition) 방지
- `go run -race` 명령으로 레이스 컨디션 탐지 가능

---

## 11. 면접 포인트

### Q1. 고루틴과 OS 스레드의 차이는?

**A:**
- **OS 스레드**: 커널이 관리, 생성 비용 큼 (~1MB 스택), 컨텍스트 스위치 비용 큼
- **고루틴**: Go 런타임이 관리, 경량 (~2KB 시작 스택, 동적 확장), 수십만 개 생성 가능
- Go 런타임은 M:N 스케줄링으로 N개 고루틴을 M개 OS 스레드에 매핑

### Q2. 채널과 뮤텍스 중 언제 무엇을 쓰나요?

**A:**
- **채널**: 데이터 전달, 고루틴 간 통신, 파이프라인 패턴
- **뮤텍스**: 공유 상태 보호, 카운터/캐시 등 내부 상태 관리
- 채널은 고루틴 간 소유권 이전, 뮤텍스는 공유 자원 잠금

```go
// 채널이 적합: 결과 전달
func calculate(n int, ch chan<- int) {
    ch <- n * n
}

// 뮤텍스가 적합: 공유 카운터
type Counter struct {
    mu    sync.Mutex
    value int
}
```

### Q3. defer의 실행 순서는?

**A:** LIFO(Last In, First Out) 순서. 스택처럼 나중에 등록된 defer가 먼저 실행됩니다.

```go
func example() {
    defer fmt.Println("첫 번째")   // 3번째 출력
    defer fmt.Println("두 번째")   // 2번째 출력
    defer fmt.Println("세 번째")   // 1번째 출력
}
// 출력: 세 번째 -> 두 번째 -> 첫 번째
```

### Q4. Go에서 인터페이스를 암묵적으로 구현하는 이유는?

**A:** Go는 `implements` 키워드 없이 메서드 시그니처만 일치하면 인터페이스를 구현한 것으로 간주합니다.
- 장점: 느슨한 결합, 기존 타입에 사후에 인터페이스 적용 가능
- 예: `io.Reader` 인터페이스는 `Read(p []byte) (n int, err error)` 메서드만 있으면 충족

### Q5. nil 채널의 동작은?

```go
var ch chan int  // nil 채널
// ch <- 1     // 영원히 블록됨
// <-ch        // 영원히 블록됨

// select에서 nil 채널은 해당 case를 비활성화
select {
case v := <-ch:  // ch가 nil이면 이 case는 절대 선택 안 됨
    fmt.Println(v)
default:
    fmt.Println("기본 처리")
}
```

### Q6. Go의 에러 처리 패턴

```go
// 관용적인 Go 에러 처리
func processFile(path string) error {
    f, err := os.Open(path)
    if err != nil {
        return fmt.Errorf("파일 열기 실패 %s: %w", path, err)
    }
    defer f.Close()

    // ... 처리 로직

    return nil
}

// 커스텀 에러 타입
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("검증 실패 [%s]: %s", e.Field, e.Message)
}

// errors.Is와 errors.As로 에러 타입 확인
var ve *ValidationError
if errors.As(err, &ve) {
    fmt.Println("필드:", ve.Field)
}
```
