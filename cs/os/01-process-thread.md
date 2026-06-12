# 1. 프로세스와 스레드

## 목차
1. [프로세스(Process) 개념](#1-프로세스process-개념)
2. [스레드(Thread) 개념](#2-스레드thread-개념)
3. [PCB(Process Control Block)](#3-pcbprocess-control-block)
4. [컨텍스트 스위칭](#4-컨텍스트-스위칭)
5. [멀티프로세싱 vs 멀티스레딩](#5-멀티프로세싱-vs-멀티스레딩)
6. [프로세스 간 통신(IPC)](#6-프로세스-간-통신ipc)
7. [JavaScript 관점: 싱글 스레드](#7-javascript-관점-싱글-스레드)
8. [면접 포인트](#8-면접-포인트)

---

## 1. 프로세스(Process) 개념

**프로세스**란 운영체제로부터 자원을 할당받아 실행 중인 프로그램의 인스턴스다.
프로그램(Program)은 디스크에 저장된 정적인 코드 파일이고, 프로세스는 그것이 메모리에 적재되어 실행되는 동적인 상태를 말한다.

### 프로세스의 메모리 구성 요소

```
+------------------+  높은 주소
|      Stack       |  ← 함수 호출 정보, 지역 변수 (위→아래로 증가)
+------------------+
|        ↓         |
|        ↑         |
+------------------+
|       Heap       |  ← 동적 할당 메모리 (아래→위로 증가)
+------------------+
|  Data Segment    |  ← 전역 변수, 정적 변수
|  (BSS + Data)    |
+------------------+
|  Code Segment    |  ← 실행 코드 (읽기 전용)
+------------------+  낮은 주소
```

| 영역 | 설명 | 예시 |
|------|------|------|
| Code (Text) | 실행할 명령어 집합, 읽기 전용 | 함수 본문 |
| Data | 초기값이 있는 전역/정적 변수 | `int g = 10;` |
| BSS | 초기값 없는 전역/정적 변수 | `int g;` |
| Heap | 런타임 동적 할당 | `malloc()`, `new` |
| Stack | 함수 호출 스택, 지역 변수 | 함수 파라미터, 리턴 주소 |

### 프로세스 상태 전이

```
         fork()              dispatch
  New ---------> Ready -----------------> Running
                  ↑                          |
                  |    I/O 완료 / 인터럽트    |  I/O 요청 / 대기
                  |                          ↓
                  +------- Waiting <---------+
                                             |
                                             | exit()
                                             ↓
                                          Terminated
```

- **New**: 프로세스가 생성된 직후
- **Ready**: CPU 할당을 기다리는 상태
- **Running**: CPU에서 실행 중
- **Waiting (Blocked)**: I/O나 이벤트 완료를 기다리는 상태
- **Terminated**: 실행 완료 또는 강제 종료

---

## 2. 스레드(Thread) 개념

**스레드**는 프로세스 내에서 실행되는 실행 흐름의 단위다.
하나의 프로세스는 최소 1개의 스레드(메인 스레드)를 가지며, 여러 스레드를 동시에 실행할 수 있다.

### 스레드 간 공유 자원과 독립 자원

```
Process
+------------------------------------------+
|  공유 자원 (Shared)                        |
|  +--------------------------------------+  |
|  | Code Segment                        |  |
|  | Data Segment (전역 변수)              |  |
|  | Heap                                |  |
|  | 파일 디스크립터, 시그널 핸들러         |  |
|  +--------------------------------------+  |
|                                           |
|  Thread 1          Thread 2              |
|  +-------------+   +-------------+       |
|  | Stack       |   | Stack       |       |
|  | Registers   |   | Registers   |       |
|  | PC (프로그램 카운터)  PC          |       |
|  +-------------+   +-------------+       |
+------------------------------------------+
```

### 프로세스 vs 스레드 비교

| 구분 | 프로세스 | 스레드 |
|------|---------|--------|
| 메모리 공간 | 독립적 (별도 주소 공간) | 공유 (같은 프로세스 내) |
| 생성 비용 | 높음 | 낮음 |
| 통신 방법 | IPC 필요 | 공유 메모리 직접 접근 |
| 안정성 | 높음 (격리됨) | 낮음 (하나가 죽으면 전체 영향) |
| 컨텍스트 스위칭 비용 | 높음 | 낮음 |

### 코드 예시: Java 멀티스레드

```java
// Thread를 상속하는 방법
class MyThread extends Thread {
    private String name;

    public MyThread(String name) {
        this.name = name;
    }

    @Override
    public void run() {
        for (int i = 0; i < 5; i++) {
            System.out.println(name + ": " + i);
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }
}

// Runnable을 구현하는 방법 (권장)
class MyRunnable implements Runnable {
    private String name;

    public MyRunnable(String name) {
        this.name = name;
    }

    @Override
    public void run() {
        for (int i = 0; i < 5; i++) {
            System.out.println(name + ": " + i);
        }
    }
}

public class Main {
    public static void main(String[] args) {
        Thread t1 = new MyThread("Thread-1");
        Thread t2 = new Thread(new MyRunnable("Thread-2"));

        t1.start();  // run()이 아닌 start() 호출 → 별도 스레드로 실행
        t2.start();
    }
}
```

---

## 3. PCB(Process Control Block)

**PCB**는 운영체제가 각 프로세스를 관리하기 위해 유지하는 자료구조다.
프로세스가 생성될 때 만들어지고, 종료될 때 삭제된다.

### PCB에 저장되는 정보

```
+--------------------------------+
|        Process Control Block   |
+--------------------------------+
| Process ID (PID)               |  ← 프로세스 식별자
| Process State                  |  ← Ready, Running, Waiting 등
| Program Counter (PC)           |  ← 다음 실행할 명령어 주소
| CPU Registers                  |  ← 범용 레지스터 값들
| CPU Scheduling Information     |  ← 우선순위, 스케줄 큐 포인터
| Memory Management Information  |  ← 페이지 테이블, 세그먼트 테이블
| Accounting Information         |  ← CPU 사용 시간, 실행 시간
| I/O Status Information         |  ← 열린 파일 목록, I/O 장치
+--------------------------------+
```

### PCB의 역할

- 컨텍스트 스위칭 시 현재 프로세스 상태를 저장하고 복원
- 운영체제 커널이 프로세스 큐를 구성할 때 PCB 포인터 사용
- 부모-자식 프로세스 관계 추적 (PPID 필드)

---

## 4. 컨텍스트 스위칭

**컨텍스트 스위칭(Context Switching)**이란 현재 실행 중인 프로세스(또는 스레드)의 상태를 PCB에 저장하고, 다음에 실행할 프로세스의 상태를 PCB에서 복원하여 CPU 제어권을 넘기는 과정이다.

### 컨텍스트 스위칭 과정

```
프로세스 A 실행 중
       |
       | 인터럽트 / 시스템 콜 발생
       ↓
  커널 모드 진입
       |
       | 1. 프로세스 A의 상태를 PCB-A에 저장
       |    - PC, 레지스터, 스택 포인터 등
       ↓
  스케줄러 실행
       |
       | 2. 다음 실행할 프로세스 B 선택
       ↓
  PCB-B에서 상태 복원
       |
       | 3. 프로세스 B의 PC, 레지스터 복원
       ↓
프로세스 B 실행
```

### 컨텍스트 스위칭 오버헤드

컨텍스트 스위칭은 **순수 오버헤드**다. 스위칭이 일어나는 동안 CPU는 유용한 작업을 수행하지 않는다.

오버헤드 발생 원인:
1. **레지스터 저장/복원**: 수십~수백 개의 레지스터 값을 메모리에 쓰고 읽음
2. **캐시 무효화**: 새 프로세스는 캐시가 비어있어 캐시 미스 증가 (Cold Cache)
3. **TLB 플러시**: 주소 공간이 바뀌면 TLB를 비워야 함 (프로세스 스위칭 시)
4. **커널 코드 실행 시간**: 스케줄러 실행 및 메모리 맵 변경

스레드 스위칭은 같은 주소 공간을 공유하므로 TLB 플러시가 필요 없어 프로세스 스위칭보다 비용이 낮다.

---

## 5. 멀티프로세싱 vs 멀티스레딩

### 멀티프로세싱 (Multi-Processing)

- 여러 CPU(코어)가 여러 프로세스를 동시에 실행
- 각 프로세스는 독립된 메모리 공간을 가짐
- 한 프로세스의 오류가 다른 프로세스에 영향을 주지 않음
- 프로세스 간 통신(IPC)이 필요하므로 오버헤드 있음

### 멀티스레딩 (Multi-Threading)

- 하나의 프로세스 내에서 여러 스레드가 병렬 실행
- 메모리 공유로 통신 비용 낮음
- 하나의 스레드 오류가 전체 프로세스에 영향
- 동기화 문제(Race Condition, Deadlock) 발생 가능

### 코드 예시: Python 멀티프로세싱

```python
from multiprocessing import Process
import os

def worker(name):
    print(f"Worker {name}: PID={os.getpid()}")

if __name__ == "__main__":
    processes = []
    for i in range(4):
        p = Process(target=worker, args=(i,))
        processes.append(p)
        p.start()

    for p in processes:
        p.join()  # 모든 프로세스가 끝날 때까지 대기
```

### 코드 예시: Python 멀티스레딩

```python
from threading import Thread
import os

def worker(name):
    # 같은 PID 출력 → 같은 프로세스 내 스레드임을 확인
    print(f"Worker {name}: PID={os.getpid()}")

threads = []
for i in range(4):
    t = Thread(target=worker, args=(i,))
    threads.append(t)
    t.start()

for t in threads:
    t.join()
```

> 참고: Python의 GIL(Global Interpreter Lock)로 인해 CPU 바운드 작업에서는 멀티스레딩이 진정한 병렬 실행이 되지 않는다. CPU 바운드 작업에는 멀티프로세싱을 사용하는 것이 적합하다.

---

## 6. 프로세스 간 통신(IPC)

서로 다른 프로세스는 메모리 공간이 격리되어 있으므로 데이터를 교환하려면 IPC(Inter-Process Communication) 메커니즘이 필요하다.

### IPC 방식 비교

| 방식 | 속도 | 방향 | 특징 |
|------|------|------|------|
| 파이프(Pipe) | 보통 | 단방향 | 부모-자식 프로세스 간, FIFO |
| 네임드 파이프(FIFO) | 보통 | 단방향 | 무관한 프로세스 간 가능 |
| 소켓(Socket) | 보통 | 양방향 | 네트워크를 통한 원격 통신도 가능 |
| 공유 메모리(Shared Memory) | 빠름 | 양방향 | 가장 빠르나 동기화 필요 |
| 메시지 큐(Message Queue) | 보통 | 양방향 | 커널이 관리하는 메시지 버퍼 |
| 시그널(Signal) | 빠름 | 단방향 | 비동기 이벤트 알림 |

### 코드 예시: 파이프(Pipe)

```python
import os

# 파이프 생성: read_fd(읽기), write_fd(쓰기)
read_fd, write_fd = os.pipe()

pid = os.fork()

if pid == 0:
    # 자식 프로세스: 읽기
    os.close(write_fd)
    data = os.read(read_fd, 1024)
    print(f"자식이 수신: {data.decode()}")
    os.close(read_fd)
else:
    # 부모 프로세스: 쓰기
    os.close(read_fd)
    os.write(write_fd, b"Hello from parent!")
    os.close(write_fd)
    os.wait()
```

### 코드 예시: 공유 메모리(Python multiprocessing)

```python
from multiprocessing import Process, Value, Array

def increment(counter):
    for _ in range(1000):
        counter.value += 1  # 동기화 없이 사용하면 Race Condition 발생!

if __name__ == "__main__":
    # 공유 메모리로 정수 값 생성
    counter = Value('i', 0)

    p1 = Process(target=increment, args=(counter,))
    p2 = Process(target=increment, args=(counter,))

    p1.start()
    p2.start()
    p1.join()
    p2.join()

    print(f"최종값: {counter.value}")  # 2000이 되지 않을 수 있음 (Race Condition)
```

---

## 7. JavaScript 관점: 싱글 스레드

JavaScript는 기본적으로 **싱글 스레드** 언어다. 즉, 한 번에 하나의 작업만 실행할 수 있다.
브라우저와 Node.js 환경에서 비동기 처리는 **이벤트 루프(Event Loop)**를 통해 구현된다.

### 이벤트 루프 동작 원리

```
     Call Stack
  +-------------+
  | console.log | ← 현재 실행 중인 함수
  |  setTimeout |
  +-------------+
         |
         | 비어있으면 Task Queue에서 꺼냄
         |
  +-------------+         +------------------+
  |  Event Loop | ←------→|   Task Queue     |
  +-------------+         | [callback1, ...]  |
                          +------------------+
                                 ↑
                          Web APIs (I/O, Timer)
                          +------------------+
                          | setTimeout       |
                          | fetch / xhr      |
                          | DOM Events       |
                          +------------------+
```

### 코드 예시: 싱글 스레드 비동기 처리

```javascript
console.log("1: 시작");

setTimeout(() => {
  console.log("3: setTimeout 콜백 (2초 후)");
}, 2000);

// Promise는 Microtask Queue에 들어감 (Task Queue보다 우선순위 높음)
Promise.resolve().then(() => {
  console.log("2.5: Promise 마이크로태스크");
});

console.log("2: 끝");

// 출력 순서:
// 1: 시작
// 2: 끝
// 2.5: Promise 마이크로태스크
// 3: setTimeout 콜백 (2초 후)
```

### Worker Thread (Node.js)

Node.js 10.5.0 이후 `worker_threads` 모듈을 통해 실제 멀티스레딩이 가능하다.
단, 스레드 간 메모리는 기본적으로 공유되지 않고 `SharedArrayBuffer`를 통해 공유한다.

```javascript
const { Worker, isMainThread, parentPort, workerData } = require('worker_threads');

if (isMainThread) {
  // 메인 스레드
  const worker = new Worker(__filename, {
    workerData: { start: 1, end: 1_000_000 }
  });

  worker.on('message', (result) => {
    console.log(`합산 결과: ${result}`);
  });
} else {
  // 워커 스레드 (CPU 집약적 작업)
  const { start, end } = workerData;
  let sum = 0;
  for (let i = start; i <= end; i++) {
    sum += i;
  }
  parentPort.postMessage(sum);
}
```

---

## 8. 면접 포인트

### Q1. 프로세스와 스레드의 차이를 설명하세요.

> 프로세스는 독립적인 메모리 공간(코드, 데이터, 힙, 스택)을 가진 실행 단위이고, 스레드는 프로세스 내에서 코드/데이터/힙을 공유하면서 각자의 스택과 레지스터를 가지는 실행 흐름입니다. 스레드는 생성/전환 비용이 낮고 통신이 쉽지만, 공유 자원에 대한 동기화 문제가 발생할 수 있습니다.

### Q2. 컨텍스트 스위칭이란 무엇이며, 왜 오버헤드가 발생하나요?

> 컨텍스트 스위칭은 CPU가 현재 프로세스의 상태(레지스터, PC 등)를 PCB에 저장하고, 다음 프로세스의 상태를 복원하는 과정입니다. 오버헤드는 레지스터 저장/복원, 캐시 무효화(Cold Cache), TLB 플러시, 스케줄러 실행 등에 의해 발생하며, 이 시간 동안 CPU는 실제 작업을 수행하지 못합니다.

### Q3. 멀티스레딩의 장단점은 무엇인가요?

> **장점**: 스레드 간 메모리 공유로 통신 비용이 낮고, 생성/전환 비용이 프로세스보다 작으며, 자원을 효율적으로 사용합니다.
> **단점**: 하나의 스레드에 문제가 생기면 같은 프로세스의 다른 스레드에도 영향을 줄 수 있고, 공유 자원에 대한 Race Condition, Deadlock 등 동기화 문제가 발생합니다.

### Q4. IPC 방식 중 가장 빠른 것은 무엇인가요?

> 공유 메모리(Shared Memory)가 가장 빠릅니다. 커널을 거치지 않고 직접 메모리에 접근하기 때문입니다. 단, 여러 프로세스가 동시에 접근할 수 있으므로 세마포어나 뮤텍스를 이용한 동기화가 필요합니다.

### Q5. JavaScript는 싱글 스레드인데 어떻게 비동기 처리가 가능한가요?

> JavaScript 엔진(V8) 자체는 싱글 스레드이지만, 브라우저나 Node.js 런타임이 제공하는 Web API / libuv가 I/O 작업을 별도 스레드에서 처리합니다. 작업이 완료되면 콜백을 Task Queue에 넣고, 이벤트 루프가 Call Stack이 비었을 때 콜백을 꺼내 실행합니다. 따라서 논블로킹 비동기 처리가 가능합니다.

### Q6. PCB에는 어떤 정보가 저장되나요?

> PCB에는 프로세스 ID(PID), 프로세스 상태, 다음 실행할 명령어 주소(PC), CPU 레지스터 값, 스케줄링 우선순위, 메모리 관리 정보(페이지 테이블 포인터), 열린 파일 목록, 계정 정보 등이 저장됩니다.
