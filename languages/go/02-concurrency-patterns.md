# 2. Go 동시성 패턴 심화

> [01 기초](./01-basics.md)에서 고루틴·채널·sync를 다뤘다. 여기서는 **실전 동시성 패턴**과 자원 누수·데드락·레이스를 다룬다. JS 개발자 관점에서 비교한다: JS는 단일 스레드 + 이벤트 루프라 "병렬"이 없지만, Go는 진짜 OS 스레드 위에서 고루틴을 멀티플렉싱한다.

## 목차
1. [select — 다중 채널 다중화](#1-select--다중-채널-다중화)
2. [context — 취소와 타임아웃 전파](#2-context--취소와-타임아웃-전파)
3. [Fan-out / Fan-in](#3-fan-out--fan-in)
4. [Worker Pool](#4-worker-pool)
5. [errgroup — 에러와 함께 기다리기](#5-errgroup--에러와-함께-기다리기)
6. [데드락 · 고루틴 누수 · 레이스](#6-데드락--고루틴-누수--레이스)
7. [JS 비동기와의 비교](#7-js-비동기와의-비교)
8. [면접 포인트](#8-면접-포인트)

---

## 1. select — 다중 채널 다중화

`select`는 여러 채널 중 **준비된 것 하나**를 고른다. 둘 이상 준비되면 무작위 선택(기아 방지).

```go
select {
case msg := <-ch1:
    fmt.Println("ch1:", msg)
case ch2 <- 42:
    fmt.Println("sent to ch2")
case <-time.After(1 * time.Second):
    fmt.Println("timeout")     // 타임아웃 패턴
default:
    fmt.Println("no channel ready") // 논블로킹 (있으면 블록 안 함)
}
```

- `time.After`와 조합 → **타임아웃**.
- `default` → **논블로킹** 송수신.
- `for { select {...} }` → 이벤트 루프. (JS 이벤트 루프와 발상이 비슷하지만 여러 고루틴이 진짜 병렬로 돈다.)

---

## 2. context — 취소와 타임아웃 전파

고루틴은 외부에서 강제 종료할 수 없다(`thread.kill` 같은 게 없음). 대신 **`context.Context`로 취소 신호를 전파**하고, 각 고루틴이 자발적으로 멈춘다. 서버 핸들러·DB 호출·HTTP 요청에 표준으로 쓰인다.

```go
ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
defer cancel() // 누수 방지: 끝나면 반드시 호출

func worker(ctx context.Context) {
    for {
        select {
        case <-ctx.Done():            // 취소/타임아웃 시 신호
            fmt.Println("중단:", ctx.Err()) // context deadline exceeded
            return
        default:
            // 작업 한 단위 수행
        }
    }
}
```

- `WithCancel` / `WithTimeout` / `WithDeadline`로 파생 컨텍스트 생성.
- 부모를 취소하면 **모든 자식 컨텍스트가 연쇄 취소**된다(트리 전파).
- `ctx`는 함수의 **첫 번째 인자**로 넘기는 게 관례: `func F(ctx context.Context, ...)`.

> JS의 `AbortController`/`AbortSignal`이 정확히 같은 역할이다. `signal.aborted` ↔ `ctx.Done()`, `controller.abort()` ↔ `cancel()`.

---

## 3. Fan-out / Fan-in

- **Fan-out**: 한 작업 스트림을 여러 고루틴에 분산해 병렬 처리.
- **Fan-in**: 여러 채널의 결과를 하나의 채널로 합침.

```go
func fanIn(chs ...<-chan int) <-chan int {
    out := make(chan int)
    var wg sync.WaitGroup
    for _, ch := range chs {
        wg.Add(1)
        go func(c <-chan int) {       // 각 입력 채널을 out으로 전달
            defer wg.Done()
            for v := range c {
                out <- v
            }
        }(ch)
    }
    go func() { wg.Wait(); close(out) }() // 전부 끝나면 out 닫기
    return out
}
```

> 핵심: 채널을 닫는 책임은 **송신자**에게 있다. 모든 송신 고루틴이 끝난 뒤(`wg.Wait()`) 한 번만 닫아야 "closed channel에 send" 패닉을 피한다.

---

## 4. Worker Pool

고루틴이 싸다고 무한정 만들면 메모리·스케줄링 부담이 커진다. 작업 수를 **고정된 워커 N개**로 제한한다.

```go
func main() {
    jobs := make(chan int, 100)
    results := make(chan int, 100)

    for w := 1; w <= 3; w++ {        // 워커 3개만 생성
        go worker(w, jobs, results)
    }
    for j := 1; j <= 9; j++ { jobs <- j }
    close(jobs)                       // 더 보낼 게 없음을 알림

    for a := 1; a <= 9; a++ { <-results }
}

func worker(id int, jobs <-chan int, results chan<- int) {
    for j := range jobs {             // 채널 닫히면 루프 종료
        results <- j * 2
    }
}
```

> `chan<- int`(송신 전용), `<-chan int`(수신 전용)로 방향을 타입에 박아 실수를 컴파일 타임에 잡는다.

---

## 5. errgroup — 에러와 함께 기다리기

`sync.WaitGroup`은 에러를 모으지 못한다. `golang.org/x/sync/errgroup`은 **여러 고루틴 중 하나라도 실패하면 context를 취소**하고 첫 에러를 반환한다. JS의 `Promise.all`과 의미가 같다.

```go
g, ctx := errgroup.WithContext(ctx)
for _, url := range urls {
    url := url
    g.Go(func() error {
        return fetch(ctx, url)   // 하나라도 에러면 ctx 취소 → 나머지도 중단
    })
}
if err := g.Wait(); err != nil { // 첫 에러 반환 (Promise.all과 동일 의미)
    log.Fatal(err)
}
```

---

## 6. 데드락 · 고루틴 누수 · 레이스

### 데드락
모든 고루틴이 서로를 기다리면 런타임이 감지하고 패닉시킨다.

```go
ch := make(chan int) // 버퍼 없음
ch <- 1              // 받는 고루틴이 없음 → fatal error: all goroutines are asleep - deadlock!
```

### 고루틴 누수
수신자가 사라졌는데 고루틴이 채널 송신에서 영원히 블록되면 회수되지 않는다(GC 안 됨). → `context`나 `done` 채널로 종료 경로를 항상 보장한다.

### 레이스 컨디션
공유 메모리 동시 접근. **`-race` 플래그**로 탐지한다.

```bash
go run -race main.go
go test -race ./...
```

해결: 채널로 소유권 이전("Don't communicate by sharing memory; share memory by communicating") 또는 `sync.Mutex`/`atomic`.

```go
var mu sync.Mutex
mu.Lock(); count++; mu.Unlock()
```

---

## 7. JS 비동기와의 비교

| 개념 | Go | JavaScript |
|------|-----|-----------|
| 동시성 단위 | 고루틴(수천~수만, OS 스레드에 다중화) | 콜백/Promise(단일 스레드) |
| 병렬성 | 진짜 멀티코어 병렬 | 없음(Web Worker는 별도 메모리) |
| 취소 | `context.Context` | `AbortController` |
| 여러 작업 대기 | `errgroup` / `WaitGroup` | `Promise.all` / `allSettled` |
| 통신 | 채널(타입 안전) | 공유 클로저/이벤트 |
| 경쟁 상태 | 존재(공유 메모리) → mutex/채널 | 단일 스레드라 원자성 보장(주로 없음) |

> 가장 큰 사고방식 차이: JS는 "단일 스레드라 레이스가 (대부분) 없다"가 기본 전제지만, Go는 "병렬이 기본이므로 공유 상태는 항상 보호해야 한다"가 전제다.

---

## 8. 면접 포인트

**Q. 고루틴을 외부에서 강제 종료할 수 있나요?**
> 없다. `context.Context`로 취소 신호를 전파하고 각 고루틴이 `ctx.Done()`을 보고 스스로 빠져나가야 한다. JS의 `AbortController`와 같은 협력적 취소 모델이다.

**Q. 채널을 닫는 책임은 누구에게 있나요?**
> 송신자(producer). 수신자가 닫거나, 닫힌 채널에 또 보내면 패닉이다. fan-in처럼 송신자가 여럿이면 `WaitGroup`으로 전부 끝난 뒤 한 번만 닫는다.

**Q. Worker Pool을 왜 쓰나요?**
> 고루틴이 싸도 무제한 생성하면 메모리·스케줄링 비용과 다운스트림(DB 커넥션 등) 과부하가 생긴다. 고정 워커 수로 동시성을 제한해 자원을 통제한다.

**Q. `errgroup`과 `Promise.all`의 공통점은?**
> 여러 동시 작업을 기다리다 하나라도 실패하면 즉시 에러를 전파하고(errgroup은 context를 취소해 나머지를 중단) 첫 에러를 반환한다. "전부 성공 or 첫 실패" 시맨틱이 같다.

**Q. Go의 레이스 컨디션을 어떻게 탐지·예방하나요?**
> `go test -race` / `go run -race`로 런타임 탐지. 예방은 "공유 메모리로 통신하지 말고, 통신으로 메모리를 공유하라" — 채널로 소유권을 넘기거나, 불가피하면 `sync.Mutex`/`atomic`으로 보호한다.

**Q. JS와 Go의 동시성 모델의 근본 차이는?**
> JS는 단일 스레드 + 이벤트 루프라 진짜 병렬이 없고 공유 상태 레이스가 (대체로) 없다. Go는 고루틴을 다수의 OS 스레드에 다중화해 멀티코어 병렬을 실현하므로, 공유 상태 보호가 필수다.
