# 10. Node.js 면접 질문 20개

> 브라우저 JS와 다른 **런타임 관점**(libuv 이벤트 루프, 스트림, 단일 스레드 + 스레드풀)을 묻는다.

## 목차
1. [Node.js의 단일 스레드 모델이란?](#1-nodejs의-단일-스레드-모델이란)
2. [libuv와 이벤트 루프의 단계는?](#2-libuv와-이벤트-루프의-단계는)
3. [`process.nextTick`과 마이크로태스크 순서는?](#3-processnexttick과-마이크로태스크-순서는)
4. [`setTimeout`과 `setImmediate`의 차이는?](#4-settimeout과-setimmediate의-차이는)
5. [스레드풀은 무엇을 처리하나요?](#5-스레드풀은-무엇을-처리하나요)
6. [CPU 집약 작업은 왜 문제이고 어떻게 푸나요?](#6-cpu-집약-작업은-왜-문제이고-어떻게-푸나요)
7. [스트림(Stream)이란 무엇이고 왜 쓰나요?](#7-스트림stream이란-무엇이고-왜-쓰나요)
8. [백프레셔(backpressure)란?](#8-백프레셔backpressure란)
9. [Buffer란 무엇인가요?](#9-buffer란-무엇인가요)
10. [EventEmitter 패턴은?](#10-eventemitter-패턴은)
11. [CommonJS와 ESM의 차이는?](#11-commonjs와-esm의-차이는)
12. [클러스터와 worker_threads의 차이는?](#12-클러스터와-worker_threads의-차이는)
13. [에러 처리: 동기/비동기/Promise는?](#13-에러-처리-동기비동기promise는)
14. [메모리 누수의 흔한 원인은?](#14-메모리-누수의-흔한-원인은)
15. [`global`, `process`, 환경변수는?](#15-global-process-환경변수는)
16. [미들웨어 패턴(Express)이란?](#16-미들웨어-패턴express이란)
17. [graceful shutdown은 어떻게 하나요?](#17-graceful-shutdown은-어떻게-하나요)
18. [Node에서 보안 기본기는?](#18-node에서-보안-기본기는)
19. [성능 측정/프로파일링 도구는?](#19-성능-측정프로파일링-도구는)
20. [REST API 확장 시 고려사항은?](#20-rest-api-확장-시-고려사항은)

---

## 1. Node.js의 단일 스레드 모델이란?

**답변:**
JS 실행은 단일 스레드(이벤트 루프)에서 일어나지만, I/O는 libuv가 백그라운드(스레드풀/OS 비동기)로 처리하고 완료 콜백만 루프에 넣는다. 그래서 적은 스레드로 많은 동시 연결을 처리(논블로킹 I/O)한다. 단, JS 콜백 하나가 오래 돌면 전체가 멈춘다.

## 2. libuv와 이벤트 루프의 단계는?

**답변:**
libuv는 Node의 비동기 I/O를 담당하는 C 라이브러리다. 이벤트 루프는 단계(phase)를 순환한다: **timers**(setTimeout/Interval) → **pending callbacks** → **poll**(I/O 콜백 대기/실행) → **check**(setImmediate) → **close callbacks**. 각 단계 사이에 마이크로태스크(`process.nextTick`, Promise)가 비워진다.

## 3. `process.nextTick`과 마이크로태스크 순서는?

**답변:**
각 단계 전환 시 **`process.nextTick` 큐가 먼저**, 그 다음 **Promise 마이크로태스크 큐**가 비워진다. `nextTick`을 재귀적으로 쓰면 이벤트 루프가 다음 단계로 못 넘어가 I/O를 굶길 수 있어 주의.

## 4. `setTimeout`과 `setImmediate`의 차이는?

**답변:**
`setImmediate`는 check 단계, `setTimeout(…,0)`은 timers 단계에서 실행된다. I/O 콜백 **안**에서는 `setImmediate`가 항상 먼저 실행되지만, 메인 모듈에서 둘의 순서는 비결정적이다(타이머 준비 타이밍에 의존).

## 5. 스레드풀은 무엇을 처리하나요?

**답변:**
libuv 스레드풀(기본 4개, `UV_THREADPOOL_SIZE`로 조정)은 OS가 비동기 API를 제공하지 않는 작업을 처리한다: 파일 시스템(`fs`), `crypto`(pbkdf2 등), `zlib`, DNS(`lookup`). 네트워크 I/O는 대부분 OS 비동기라 스레드풀을 쓰지 않는다.

## 6. CPU 집약 작업은 왜 문제이고 어떻게 푸나요?

**답변:**
무거운 동기 계산(이미지 처리, 암호화 루프)은 이벤트 루프를 점유해 **모든 요청을 블록**한다. 해법: `worker_threads`로 별도 스레드에서 처리, 작업을 청크로 쪼개기, 외부 워커/큐로 오프로드, 네이티브 애드온 사용.

## 7. 스트림(Stream)이란 무엇이고 왜 쓰나요?

**답변:**
데이터를 **조각(chunk) 단위로** 읽고 쓰는 추상화(Readable/Writable/Duplex/Transform). 전체를 메모리에 올리지 않아 대용량 파일·네트워크를 일정 메모리로 처리한다. `pipe`/`pipeline`으로 연결한다.

```js
const { pipeline } = require('stream/promises');
await pipeline(fs.createReadStream('in'), zlib.createGzip(), fs.createWriteStream('out.gz'));
```

## 8. 백프레셔(backpressure)란?

**답변:**
쓰기 측이 읽기 측보다 느릴 때 데이터가 메모리에 쌓이는 문제. `write()`가 `false`를 반환하면 `drain` 이벤트까지 멈춰야 한다. `pipe`/`pipeline`은 이를 자동 처리하므로 수동 스트림 연결보다 권장된다.

## 9. Buffer란 무엇인가요?

**답변:**
V8 힙 밖에 할당되는 **고정 길이 이진 데이터** 컨테이너. 파일·소켓·암호화 등 바이트를 다룰 때 쓴다. 문자열과 달리 인코딩(utf8, base64, hex)을 명시해 변환한다.

## 10. EventEmitter 패턴은?

**답변:**
`on(event, listener)`로 구독하고 `emit(event, …)`로 발행하는 Node의 핵심 비동기 패턴. 스트림·서버·프로세스가 모두 이를 상속한다. 리스너 누수(`MaxListenersExceededWarning`)와 `error` 이벤트 미처리(프로세스 크래시)에 주의.

## 11. CommonJS와 ESM의 차이는?

**답변:**
CJS(`require`/`module.exports`)는 동기 로드·런타임 평가, ESM(`import`/`export`)은 정적 분석·비동기 로드·트리셰이킹 가능. ESM은 top-level await 지원, `__dirname` 없음(`import.meta.url` 사용). `package.json`의 `"type"`으로 결정.

## 12. 클러스터와 worker_threads의 차이는?

**답변:**
`cluster`는 **프로세스**를 여러 개 포크해 멀티코어로 요청을 분산(메모리 공유 안 함, IPC로 통신) — I/O 바운드 확장에 적합. `worker_threads`는 **스레드**로 메모리(SharedArrayBuffer) 공유 가능 — CPU 바운드 작업에 적합.

## 13. 에러 처리: 동기/비동기/Promise는?

**답변:**
동기는 `try/catch`, 콜백은 에러 우선(`(err, data)=>`) 규약, Promise는 `.catch`/`try-catch+await`. 처리 안 된 거부는 `process.on('unhandledRejection')`, 동기 예외는 `uncaughtException`(복구 불가로 보고 로깅 후 종료 권장)으로 잡는다.

## 14. 메모리 누수의 흔한 원인은?

**답변:**
전역/모듈 스코프에 쌓이는 캐시(맵), 제거 안 한 이벤트 리스너·타이머, 클로저가 잡은 큰 객체, 무한 증가 배열. `--inspect` + 힙 스냅샷 비교, `process.memoryUsage()`로 추적한다.

## 15. `global`, `process`, 환경변수는?

**답변:**
`global`은 브라우저 `window` 대응 전역. `process`는 실행 정보(`argv`, `env`, `pid`, `cwd()`)와 이벤트(`exit`, `SIGINT`)를 제공. 설정은 `process.env`로 주입하되 비밀값은 `.env`/시크릿 매니저로 관리하고 커밋 금지.

## 16. 미들웨어 패턴(Express)이란?

**답변:**
`(req, res, next)` 시그니처 함수를 체인으로 연결해 요청을 단계별로 가공한다(로깅→인증→파싱→핸들러). `next()` 호출로 다음으로, `next(err)`로 에러 핸들러로 보낸다. 관심사 분리와 재사용의 핵심.

## 17. graceful shutdown은 어떻게 하나요?

**답변:**
`SIGTERM`/`SIGINT`를 받으면 새 연결을 끊고(`server.close()`), 진행 중 요청을 마치고, DB·큐 연결을 정리한 뒤 종료한다. 타임아웃을 두어 무한 대기를 막는다. 컨테이너 환경(K8s)에서 필수.

## 18. Node에서 보안 기본기는?

**답변:**
입력 검증(스키마), SQL/명령 주입 방지(파라미터화), 의존성 취약점 점검(`npm audit`), 헤더 보안(helmet), 비밀값 분리, 레이트 리미팅, HTTPS, 최소 권한 실행. 신뢰 못 할 입력으로 `eval`/`child_process` 금지.

## 19. 성능 측정/프로파일링 도구는?

**답변:**
`--inspect`(Chrome DevTools), `--prof`(V8 프로파일러), `clinic.js`, `perf_hooks`(고해상도 타이밍), `0x`(플레임그래프). 이벤트 루프 지연은 `perf_hooks.monitorEventLoopDelay`로 관측한다.

## 20. REST API 확장 시 고려사항은?

**답변:**
무상태(stateless) 설계로 수평 확장, 클러스터/로드밸런서, 캐싱(Redis), DB 커넥션 풀, 페이지네이션·레이트리밋, 비동기 작업은 큐로 분리, 관측성(로그·메트릭·트레이싱), graceful shutdown. 병목은 대개 DB와 이벤트 루프 블로킹이다.
