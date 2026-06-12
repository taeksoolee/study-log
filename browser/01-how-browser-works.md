# 1. 브라우저 동작 원리

## 목차
1. 브라우저의 주요 구성 요소
2. URL 입력부터 화면 출력까지 전체 흐름
3. DNS 조회
4. TCP/TLS 연결
5. HTTP 요청과 응답
6. 파싱과 리소스 로딩
7. 렌더링
8. 면접 포인트

---

## 1. 브라우저의 주요 구성 요소

```
┌─────────────────────────────────────────┐
│              브라우저                    │
│  ┌──────────┐  ┌────────────────────┐  │
│  │  UI 레이어│  │  브라우저 엔진      │  │
│  │(주소창 등)│  │(UI ↔ 렌더링 엔진   │  │
│  └──────────┘  │  중간 레이어)       │  │
│                └────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │         렌더링 엔진               │  │
│  │  (HTML/CSS 파싱, 화면 그리기)     │  │
│  │  Chrome: Blink / Firefox: Gecko  │  │
│  └──────────────────────────────────┘  │
│  ┌──────────┐  ┌────────────────────┐  │
│  │  JS 엔진 │  │  네트워킹           │  │
│  │  (V8 등) │  │  (HTTP, WebSocket) │  │
│  └──────────┘  └────────────────────┘  │
│  ┌──────────┐  ┌────────────────────┐  │
│  │  UI 백엔드│  │  데이터 저장        │  │
│  │ (OS 위젯)│  │  (Cookie, Storage) │  │
│  └──────────┘  └────────────────────┘  │
└─────────────────────────────────────────┘
```

---

## 2. URL 입력부터 화면 출력까지 전체 흐름

```
사용자가 https://www.example.com 입력
         │
         ▼
[1] URL 파싱 & 캐시 확인
  - 브라우저 캐시 확인 (이미 응답이 있으면 바로 사용)
  - HSTS 목록 확인 (HTTP → HTTPS 자동 업그레이드)
         │
         ▼
[2] DNS 조회
  - 브라우저 DNS 캐시 → OS DNS 캐시 → 라우터 → ISP DNS → 재귀 조회
         │
         ▼
[3] TCP 3-way Handshake
  - SYN → SYN-ACK → ACK
         │
         ▼
[4] TLS Handshake (HTTPS인 경우)
  - 인증서 교환, 대칭키 합의
         │
         ▼
[5] HTTP 요청 전송
  - GET / HTTP/1.1, 헤더 포함
         │
         ▼
[6] 서버 응답 수신
  - 상태 코드, 헤더, HTML 바디
         │
         ▼
[7] HTML 파싱 → DOM 생성
  - CSS 파싱 → CSSOM 생성 (병렬)
  - JS 실행 (파서 블로킹 주의)
         │
         ▼
[8] Render Tree 생성
  - DOM + CSSOM 결합
         │
         ▼
[9] Layout (Reflow)
  - 각 요소의 위치, 크기 계산
         │
         ▼
[10] Paint
  - 픽셀 그리기
         │
         ▼
[11] Composite
  - 레이어 합성 → 화면 출력
```

---

## 3. DNS 조회

```
브라우저 DNS 캐시
      │ 없으면
      ▼
OS DNS 캐시 (/etc/hosts 포함)
      │ 없으면
      ▼
로컬 DNS 리졸버 (보통 ISP 제공, 또는 8.8.8.8)
      │ 없으면
      ▼
루트 DNS 서버 (. 으로 끝나는 최상위, 13개 클러스터)
      │
      ▼
TLD DNS 서버 (.com, .net 등 관리)
      │
      ▼
권한 있는(Authoritative) DNS 서버
      │
      ▼
IP 주소 반환 → 캐시 저장 (TTL 동안 유효)
```

- **TTL (Time To Live)**: 캐시 유효 시간. 짧으면 DNS 변경 빠르게 반영, 길면 성능 좋음
- **DNS over HTTPS (DoH)**: DNS 쿼리를 HTTPS로 암호화해 프라이버시 보호

---

## 4. TCP/TLS 연결

### TCP 3-way Handshake

```
클라이언트                         서버
    │──── SYN (seq=x) ────────────▶│  연결 요청
    │◀─── SYN-ACK (seq=y, ack=x+1)─│  수락
    │──── ACK (ack=y+1) ──────────▶│  확인
    │                              │
    │══════ 데이터 전송 ════════════│
```

### TLS 1.3 Handshake (단순화)

```
클라이언트                         서버
    │──── ClientHello ────────────▶│  지원 암호화 방식 목록, 난수
    │◀─── ServerHello + 인증서 ────│  선택된 방식, 서버 공개키
    │──── (인증서 검증 후)         │
    │──── Finished ───────────────▶│  대칭키로 암호화 시작
```

- **TLS 1.3**: 1-RTT Handshake (이전 세션은 0-RTT 재개 가능)
- **인증서 체인**: 서버 인증서 → 중간 CA → 루트 CA (브라우저에 내장)

---

## 5. HTTP 요청과 응답

```http
GET / HTTP/1.1
Host: www.example.com
User-Agent: Mozilla/5.0 ...
Accept: text/html,application/xhtml+xml
Accept-Language: ko-KR,ko;q=0.9
Accept-Encoding: gzip, deflate, br
Connection: keep-alive
Cookie: session=abc123
```

```http
HTTP/1.1 200 OK
Content-Type: text/html; charset=UTF-8
Content-Length: 1234
Content-Encoding: gzip
Cache-Control: max-age=3600
ETag: "abc123"
Set-Cookie: session=xyz; HttpOnly; Secure
```

### HTTP 버전별 특징

| 버전 | 주요 특징 |
|------|-----------|
| HTTP/1.0 | 요청마다 TCP 연결 새로 수립 |
| HTTP/1.1 | Keep-Alive (연결 재사용), 파이프라이닝(HOL blocking 문제) |
| HTTP/2 | 멀티플렉싱, 헤더 압축(HPACK), 서버 푸시, 바이너리 프레임 |
| HTTP/3 | QUIC(UDP 기반), 0-RTT, 연결 마이그레이션 |

---

## 6. 파싱과 리소스 로딩

### HTML 파싱과 파서 블로킹

```html
<!DOCTYPE html>
<html>
<head>
  <!-- CSS: 렌더링 차단 리소스 (CSSOM 없이 렌더링 불가) -->
  <link rel="stylesheet" href="style.css">

  <!-- JS: 파서 차단 리소스 (기본적으로 HTML 파싱 중단) -->
  <script src="app.js"></script>

  <!-- defer: HTML 파싱 완료 후 실행, DOMContentLoaded 전 -->
  <script defer src="deferred.js"></script>

  <!-- async: 다운로드 완료 즉시 실행 (순서 보장 없음) -->
  <script async src="analytics.js"></script>
</head>
```

```
일반 <script>:
HTML 파싱 ──────┤ JS 다운로드+실행 ├──────── HTML 파싱 계속

defer:
HTML 파싱 ──────────────────────────────── │ JS 실행

async:
HTML 파싱 ──────────│ JS 실행 │──────────── HTML 파싱 계속
```

### Preload Scanner

렌더링 엔진이 HTML을 순차적으로 파싱하는 동안, 별도의 스캐너가 HTML을 미리 훑으며 이미지, CSS, JS 등의 리소스를 미리 발견해 병렬로 다운로드합니다.

---

## 7. 렌더링 (간략 요약)

파싱 이후 단계는 `02-rendering-pipeline.md`에서 상세히 다룹니다.

```
DOM + CSSOM
     │
     ▼
Render Tree (display:none 제외, visibility:hidden 포함)
     │
     ▼
Layout: 기하학적 계산 (위치, 크기)
     │
     ▼
Paint: 각 레이어를 픽셀로 채우기
     │
     ▼
Composite: GPU에서 레이어 합성 → 화면 출력
```

---

## 8. 면접 포인트

### Q1. 브라우저 주소창에 URL을 입력하면 어떤 일이 일어나나요?

DNS 조회로 IP를 얻고 → TCP 3-way handshake로 연결 → TLS handshake로 암호화 채널 수립 → HTTP 요청 전송 → 서버 응답 수신 → HTML 파싱 → DOM/CSSOM 생성 → Render Tree → Layout → Paint → Composite 순서로 진행됩니다.

### Q2. `<script>` 태그의 `defer`와 `async`의 차이점은?

`async`는 스크립트 다운로드가 완료되는 즉시 HTML 파싱을 중단하고 실행합니다. 순서 보장이 없습니다. `defer`는 HTML 파싱과 병렬로 다운로드하지만, 파싱 완료 후 `DOMContentLoaded` 이벤트 전에 **문서 순서대로** 실행됩니다. 분석 스크립트처럼 독립적인 것은 `async`, DOM에 의존하거나 순서가 중요한 것은 `defer`가 적합합니다.

### Q3. DNS 조회 단계가 중요한 이유는?

웹 성능에서 DNS 조회는 수십~수백 ms를 차지할 수 있습니다. `<link rel="dns-prefetch" href="//cdn.example.com">`으로 미리 조회해두면 리소스 로딩 시 대기 시간을 줄일 수 있습니다. 또한 CDN 사용 시 지리적으로 가까운 엣지 서버의 IP를 반환받는 것도 DNS 수준에서 이루어집니다.

### Q4. TLS와 HTTPS의 관계는?

HTTPS는 HTTP + TLS입니다. TLS(Transport Layer Security)는 TCP 위에서 암호화, 무결성 검증, 인증을 제공합니다. TLS 1.3은 1-RTT 핸드쉐이크로 연결 수립 시간을 단축했으며, 이전 연결이 있다면 0-RTT 재개도 가능합니다.

### Q5. Critical Rendering Path(CRP)란?

HTML → DOM, CSS → CSSOM, DOM+CSSOM → Render Tree → Layout → Paint까지의 최초 렌더링에 반드시 거쳐야 하는 경로입니다. CRP를 최적화(렌더링 차단 리소스 최소화, CSS 인라인, JS defer/async)하면 FCP(First Contentful Paint)를 앞당길 수 있습니다.
