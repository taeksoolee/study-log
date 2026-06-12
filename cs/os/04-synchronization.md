# 4. 동기화와 교착상태

## 목차
1. 임계 구역 (Critical Section) 문제
2. Race Condition
3. Mutex (상호 배제)
4. Semaphore
5. Monitor
6. JavaScript와 동기화
7. 교착상태 (Deadlock)
8. 교착상태 처리 방법
9. 면접 포인트

---

## 1. 임계 구역 (Critical Section) 문제

### 1.1 임계 구역이란?

**여러 프로세스(또는 스레드)가 공유 자원에 동시에 접근할 때 문제가 발생하는 코드 영역**이다.

```
프로세스 구조:
do {
    // 진입 구역 (entry section)   ← 임계 구역 진입 허가 요청
    
        // 임계 구역 (critical section)
        // 공유 변수 접근, 공유 파일 수정 등
    
    // 퇴출 구역 (exit section)    ← 임계 구역 사용 완료 알림
    
    // 나머지 구역 (remainder section)
} while (true);
```

### 1.2 임계 구역 문제 해결 3가지 조건

| 조건 | 설명 |
|------|------|
| 상호 배제 (Mutual Exclusion) | 한 프로세스가 임계 구역에 있으면 다른 프로세스는 진입 불가 |
| 진행 (Progress) | 임계 구역을 사용 중인 프로세스가 없을 때, 진입을 원하는 프로세스가 있다면 진입이 허용되어야 함 |
| 유한 대기 (Bounded Waiting) | 프로세스가 임계 구역 진입을 요청한 후 허가될 때까지 다른 프로세스의 진입 횟수에 상한이 있어야 함 |

---

## 2. Race Condition

### 2.1 개념

**여러 프로세스(또는 스레드)가 공유 데이터에 동시에 접근하고, 실행 순서에 따라 결과가 달라지는 상황**이다.

### 2.2 발생 원인

```
예시: 두 스레드가 전역 변수 count를 각각 1씩 증가

Thread A                Thread B
read count (= 5)
                        read count (= 5)
count = count + 1
write count (= 6)
                        count = count + 1
                        write count (= 6)  ← 기대값 7이지만 6이 됨!
```

`count++` 연산은 실제로 3단계(읽기 → 계산 → 쓰기)로 이루어지며,
이 중간에 다른 스레드가 끼어들 경우 결과가 오염된다.

### 2.3 발생 원인 정리

- **컨텍스트 스위칭**: 연산 도중 다른 프로세스로 전환
- **멀티코어 병렬 실행**: 여러 코어에서 동시에 같은 변수 접근
- **인터럽트**: 연산 중간에 인터럽트 발생

---

## 3. Mutex (Mutual Exclusion Lock)

### 3.1 개념

**임계 구역을 보호하기 위한 잠금 장치**이다.
한 번에 하나의 스레드만 잠금을 획득할 수 있고, 잠금을 보유한 스레드만 임계 구역에 진입할 수 있다.

### 3.2 의사코드 (Pseudocode)

```
// Mutex 구조
Mutex {
    bool locked = false
}

// 잠금 획득 (atomic operation)
acquire(mutex):
    while (mutex.locked == true):
        wait()          // busy-waiting (스핀락)
    mutex.locked = true

// 잠금 해제
release(mutex):
    mutex.locked = false


// 사용 예
do {
    acquire(mutex)
        // 임계 구역
        count++
    release(mutex)
    
    // 나머지 구역
} while (true)
```

### 3.3 스핀락 (Spinlock) vs 블로킹 뮤텍스

```
스핀락 (Busy-waiting):
  - CPU를 계속 점유하면서 조건을 반복 확인
  - 대기 시간이 짧을 때 효율적 (컨텍스트 스위칭 비용보다 대기 비용이 낮을 때)
  - 멀티코어 환경에서 유용

블로킹 뮤텍스:
  - 잠금 획득 실패 시 스레드를 sleep 상태로 전환
  - CPU를 낭비하지 않음
  - 대기 시간이 길 때 효율적
```

### 3.4 C 스타일 의사코드 예시

```c
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
int shared_count = 0;

void* increment(void* arg) {
    for (int i = 0; i < 1000000; i++) {
        pthread_mutex_lock(&mutex);    // 잠금 획득
        shared_count++;                // 임계 구역
        pthread_mutex_unlock(&mutex);  // 잠금 해제
    }
    return NULL;
}
```

---

## 4. Semaphore

### 4.1 개념

**정수 값을 가진 동기화 도구**로, Dijkstra가 제안했다.
Mutex보다 일반화된 형태로, 여러 개의 공유 자원을 관리할 수 있다.

두 가지 원자적(atomic) 연산으로 조작한다:
- `wait()` (P 연산, down): 세마포어 값을 1 감소. 값이 0 이하면 대기
- `signal()` (V 연산, up): 세마포어 값을 1 증가. 대기 중인 프로세스 깨움

### 4.2 Binary Semaphore vs Counting Semaphore

```
Binary Semaphore (이진 세마포어):
  - 값: 0 또는 1
  - Mutex와 동일한 역할
  - 상호 배제 구현에 사용

Counting Semaphore (계수 세마포어):
  - 값: 0 이상의 정수
  - 여러 개의 동일한 자원을 관리
  - 예: DB 커넥션 풀 (10개의 연결 허용)
```

### 4.3 의사코드

```
// 세마포어 구조
Semaphore {
    int value
    Queue waiting_queue
}

// wait() - P 연산
wait(S):
    S.value--
    if (S.value < 0):
        // 현재 프로세스를 S.waiting_queue에 추가
        block()   // 프로세스를 대기 상태로

// signal() - V 연산
signal(S):
    S.value++
    if (S.value <= 0):
        // waiting_queue에서 프로세스 하나를 꺼냄
        wakeup(process)  // 프로세스를 준비 상태로


// 상호 배제 예시 (Binary Semaphore)
Semaphore mutex = 1

Process P1:
    wait(mutex)
        // 임계 구역
    signal(mutex)

Process P2:
    wait(mutex)
        // 임계 구역
    signal(mutex)
```

### 4.4 세마포어로 실행 순서 제어

```
// P2가 P1의 작업 이후에 실행되도록 순서 제어
Semaphore sync = 0

Process P1:
    // 작업 S1 수행
    signal(sync)   // P2에게 알림

Process P2:
    wait(sync)     // P1이 완료될 때까지 대기
    // 작업 S2 수행 (S1 이후에 실행 보장)
```

### 4.5 Mutex vs Semaphore 차이

| 구분 | Mutex | Semaphore |
|------|-------|-----------|
| 소유권 | 잠금을 획득한 스레드만 해제 가능 | 어느 스레드도 signal 가능 |
| 값 범위 | 0 또는 1 | 0 이상의 정수 |
| 용도 | 상호 배제 | 상호 배제 + 실행 순서 제어 + 자원 개수 관리 |
| 적용 범위 | 단일 프로세스 내 | 프로세스 간도 가능 |

---

## 5. Monitor

### 5.1 개념

**세마포어보다 고수준의 동기화 추상화 도구**이다.
공유 데이터와 그 데이터에 접근하는 프로시저를 하나의 모듈로 캡슐화하며, 한 번에 하나의 프로세스만 모니터 내의 프로시저를 실행할 수 있다.

```
Monitor {
    // 공유 변수
    shared_data

    // 초기화 코드
    initialization_code()

    // 프로시저 (내부에서 상호 배제 자동 보장)
    procedure_1()
    procedure_2()
    ...
}
```

### 5.2 조건 변수 (Condition Variable)

모니터 내에서 특정 조건을 기다리기 위한 메커니즘이다.

```
Condition variable x

x.wait()    // 현재 프로세스를 일시 중단하고 대기
x.signal()  // 대기 중인 프로세스 하나를 깨움
```

### 5.3 Java에서의 Monitor

```java
class BankAccount {
    private int balance = 0;

    // synchronized 키워드로 모니터 구현
    public synchronized void deposit(int amount) {
        balance += amount;
        notifyAll();  // 대기 중인 스레드 깨움
    }

    public synchronized void withdraw(int amount) throws InterruptedException {
        while (balance < amount) {
            wait();   // 잔액 부족 시 대기
        }
        balance -= amount;
    }
}
```

---

## 6. JavaScript와 동기화

### 6.1 JavaScript가 동기화 문제에서 자유로운 이유

JavaScript는 **싱글 스레드(Single-threaded)** 언어이기 때문에, 기본적으로 Race Condition이 발생하지 않는다.

```
JavaScript 실행 모델:
  - 하나의 콜 스택(Call Stack)
  - 한 번에 하나의 작업만 실행
  - Race Condition 발생 불가

멀티스레드 환경:
  Thread1 ──→ 읽기 ──→ 계산 ──→ 쓰기
  Thread2          ──→ 읽기 ──→ 계산 ──→ 쓰기  ← 충돌 가능

JavaScript (싱글스레드):
  Task1: 읽기 → 계산 → 쓰기 (완료 후)
  Task2: 읽기 → 계산 → 쓰기 (순차 실행)
```

### 6.2 JavaScript의 비동기 처리

싱글 스레드지만 **이벤트 루프(Event Loop)**를 통해 비동기 작업을 처리한다.

```javascript
// Mutex 없이도 안전한 JavaScript 코드
let count = 0;

async function increment() {
    // 비동기 대기가 없다면 원자적으로 실행됨
    count++;
}

// 단, 비동기 구간이 있으면 주의 필요
async function unsafeIncrement() {
    const current = count;    // 읽기
    await someAsyncTask();    // 여기서 다른 태스크 실행 가능
    count = current + 1;      // 이 시점에 count가 변경되어 있을 수 있음!
}
```

### 6.3 Web Worker와 동기화

JavaScript에서 멀티스레딩을 지원하는 Web Worker를 사용하면 동기화가 필요하다.

```javascript
// SharedArrayBuffer + Atomics로 동기화
const sab = new SharedArrayBuffer(4);
const view = new Int32Array(sab);

// Worker에서 원자적 연산
Atomics.add(view, 0, 1);   // 원자적 증가 (Race Condition 방지)
Atomics.load(view, 0);     // 원자적 읽기
```

---

## 7. 교착상태 (Deadlock)

### 7.1 개념

**두 개 이상의 프로세스가 서로 상대방이 보유한 자원을 기다리며 무한정 대기하는 상태**이다.

```
교착상태 예시:

Process P1          Process P2
보유: Resource A    보유: Resource B
요청: Resource B    요청: Resource A

P1 ──요청──→ Resource B ──보유──→ P2
P2 ──요청──→ Resource A ──보유──→ P1

서로 기다리며 영원히 진행되지 않음!
```

### 7.2 교착상태 발생의 4가지 필요 조건 (Coffman 조건)

모든 조건이 **동시에 성립**할 때 교착상태가 발생할 수 있다. 하나라도 성립하지 않으면 교착상태는 발생하지 않는다.

**① 상호 배제 (Mutual Exclusion)**
- 자원은 한 번에 하나의 프로세스만 사용할 수 있다
- 공유 불가능한 자원(Mutex, 프린터 등)에서 발생

**② 점유 대기 (Hold and Wait)**
- 자원을 보유하면서 다른 자원을 기다리는 상태
- 적어도 하나의 자원을 보유하고, 추가 자원을 요청하며 대기

**③ 비선점 (No Preemption)**
- 자원을 강제로 빼앗을 수 없다
- 프로세스가 자발적으로 자원을 반환할 때까지 대기

**④ 순환 대기 (Circular Wait)**
- 프로세스들이 원형으로 서로의 자원을 기다리는 상태
- P1→P2→P3→...→Pn→P1 형태의 순환

### 7.3 자원 할당 그래프 (Resource Allocation Graph)

```
교착상태 없음:           교착상태 있음:

P1 →→ R1              P1 →→ R1 ←← P2
       ↓↓                    ↓↓      ↑↑
       P2              R2 →→ P1  P2 ←← R2
                              ↑↑      ↓↓
                        P2 ←← R1  R1 →→ P1

(사이클 없음)           (사이클 존재 → 교착상태)
```

---

## 8. 교착상태 처리 방법

### 8.1 예방 (Prevention)

4가지 조건 중 **하나를 원천적으로 부정**하여 교착상태 발생 자체를 막는다.

```
① 상호 배제 부정:
   - 모든 자원을 공유 가능하게 만듦
   - 현실적으로 불가능 (프린터 등 본질적으로 공유 불가한 자원 존재)

② 점유 대기 부정:
   - 프로세스 시작 전 필요한 모든 자원을 한 번에 요청
   - 또는 자원 요청 전에 보유 자원 전부 반환
   - 문제: 자원 이용률 낮음, 기아 현상 발생 가능

③ 비선점 부정:
   - 자원을 강제로 빼앗을 수 있게 허용
   - CPU 레지스터, 메모리는 가능하지만 프린터 등은 어려움

④ 순환 대기 부정:
   - 모든 자원 유형에 순서를 부여하고, 순서대로만 요청 허용
   - 예: R1 < R2 < R3 순서라면 R3를 가진 상태에서 R1 요청 불가
   - 현실적으로 가장 많이 사용되는 예방 기법
```

### 8.2 회피 (Avoidance)

**교착상태가 발생하지 않을 것이 보장될 때만 자원을 할당**한다.
프로세스가 요청할 최대 자원 수를 미리 알아야 한다.

**은행가 알고리즘 (Banker's Algorithm)**

```
시스템 상태:
  Available: 각 자원의 남은 개수
  Max:       각 프로세스가 요청할 최대 자원 수
  Allocation: 현재 할당된 자원 수
  Need:      아직 요청하지 않은 최대 자원 수 (= Max - Allocation)

안전 상태 (Safe State):
  - 모든 프로세스가 순서대로 완료될 수 있는 상태
  - Safe Sequence가 존재하면 안전 상태

자원 요청 시:
  1. 요청량 ≤ Need 확인
  2. 요청량 ≤ Available 확인
  3. 가정적으로 자원 할당 후 안전 상태인지 검사
  4. 안전하면 실제 할당, 아니면 대기
```

### 8.3 탐지 (Detection)

교착상태 발생을 허용하되, **주기적으로 교착상태 발생 여부를 탐지**한다.

```
탐지 방법:
  - 자원 할당 그래프에서 사이클 탐지
  - 사이클이 존재하면 교착상태 의심
  - 단일 인스턴스 자원: 사이클 = 교착상태
  - 복수 인스턴스 자원: 사이클 ≠ 반드시 교착상태 (은행가 알고리즘 변형 사용)

탐지 주기 결정:
  - 너무 자주: 오버헤드 증가
  - 너무 드물게: 교착상태가 오래 지속되어 자원 낭비
```

### 8.4 복구 (Recovery)

교착상태 탐지 후 **상태를 정상으로 되돌리는** 작업이다.

```
① 프로세스 종료:
   방법 1: 교착상태 프로세스 모두 종료 (빠르지만 손실 큼)
   방법 2: 교착상태가 해소될 때까지 하나씩 종료 (오버헤드 높음)
   
   종료 우선순위 기준:
   - 프로세스 우선순위
   - 실행 시간 및 남은 작업량
   - 사용한 자원의 종류와 양
   - 대화형 vs 배치 프로세스

② 자원 선점:
   - 일부 프로세스에서 자원을 강제로 빼앗아 다른 프로세스에 할당
   - 선점된 프로세스는 안전한 상태(Checkpoint)로 롤백
   - 동일한 프로세스가 계속 선점 피해를 입지 않도록 주의 (기아 현상)
```

---

## 9. 면접 포인트

### Q1. Race Condition이란 무엇이고, 어떻게 해결하나요?

두 개 이상의 스레드가 공유 자원에 동시에 접근할 때 실행 순서에 따라 결과가 달라지는 현상입니다. `count++` 같은 연산도 내부적으로 읽기-계산-쓰기의 3단계로 나뉘어, 그 사이에 다른 스레드가 개입하면 값이 오염됩니다. Mutex, Semaphore, Monitor 등의 동기화 도구로 임계 구역을 보호하여 해결합니다.

### Q2. Mutex와 Semaphore의 차이점은?

Mutex는 잠금을 획득한 스레드만 해제할 수 있는 소유권 개념이 있으며 0/1 값만 가집니다. Semaphore는 값 범위가 정수 전체이고, 어떤 스레드도 signal을 호출할 수 있습니다. Semaphore는 자원 개수 관리나 실행 순서 제어에도 활용 가능하여 Mutex보다 더 일반화된 도구입니다.

### Q3. 교착상태의 4가지 조건을 설명하고, 이를 어떻게 예방하나요?

상호 배제(자원 독점), 점유 대기(자원 보유 중 추가 요청), 비선점(강제 회수 불가), 순환 대기(원형 대기) 4가지가 동시에 성립할 때 교착상태가 발생합니다. 실무에서 가장 현실적인 예방 방법은 순환 대기를 부정하는 것으로, 모든 자원에 전역 순서를 부여하고 오름차순으로만 자원을 요청하도록 강제합니다.

### Q4. JavaScript는 왜 Mutex 없이도 안전한가요?

JavaScript는 싱글 스레드로 동작하는 이벤트 루프 모델을 사용하기 때문에, 한 번에 하나의 태스크만 실행됩니다. 따라서 공유 변수에 대한 동시 접근 자체가 발생하지 않아 Race Condition이 없습니다. 단, 비동기 함수 내부에서 await 이후 구간은 주의가 필요하며, Web Worker를 사용하는 경우 SharedArrayBuffer와 Atomics API로 동기화해야 합니다.

### Q5. 교착상태 예방, 회피, 탐지, 복구의 차이점은?

- 예방: 4가지 조건 중 하나를 제거하여 교착상태 발생 자체를 차단. 자원 이용률이 낮아지는 단점.
- 회피: 자원 할당 전에 안전 상태 유지 여부를 검사(은행가 알고리즘). 최대 요청량 사전 파악 필요.
- 탐지: 교착상태 발생을 허용하고 주기적으로 탐지. 탐지 비용과 해소 비용 발생.
- 복구: 교착상태 탐지 후 프로세스 종료 또는 자원 선점으로 복구.

### Q6. Monitor가 Semaphore보다 나은 점은?

Semaphore는 wait()와 signal()을 프로그래머가 직접 올바른 순서로 호출해야 하며, 실수(예: signal을 빠뜨리거나 순서를 바꾸는 것)가 버그로 이어집니다. Monitor는 공유 데이터와 접근 프로시저를 캡슐화하여 상호 배제를 언어 수준에서 자동으로 보장합니다. Java의 `synchronized` 키워드가 Monitor를 구현한 대표적인 예입니다.
