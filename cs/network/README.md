# 네트워크 학습 로그

네트워크 프로토콜과 통신 원리에 대한 학습 문서입니다.

---

## 목차

| # | 주제 | 파일 | 상태 |
|---|------|------|------|
| 1 | OSI 7계층 & TCP/IP 4계층 비교 | [01-osi-layers.md](./01-osi-layers.md) | ⬜ |
| 2 | TCP vs UDP, 3-way/4-way Handshake, 흐름/혼잡 제어, IP | [02-tcp-ip.md](./02-tcp-ip.md) | ⬜ |
| 3 | HTTP/1.0→3 진화, 헤더, 상태코드, 캐싱, 쿠키, HTTPS | [03-http.md](./03-http.md) | ⬜ |

---

## 학습 순서 가이드

```
01 OSI 7계층 (전체 네트워크 모델 이해)
       ↓
02 TCP/IP (3, 4계층 심화)
       ↓
03 HTTP (응용 계층 심화)
```

---

## 핵심 포인트 요약

- OSI 7계층은 개념 모델, TCP/IP 4계층은 실제 인터넷 구현 모델
- TCP는 신뢰성, UDP는 속도 우선
- HTTP/2는 멀티플렉싱, HTTP/3는 QUIC(UDP 기반)으로 성능 개선
- HTTPS = HTTP + TLS (암호화, 무결성, 인증)

---

## 참고 자료

- [RFC 793 - TCP](https://tools.ietf.org/html/rfc793)
- [RFC 2616 - HTTP/1.1](https://tools.ietf.org/html/rfc2616)
- [RFC 7540 - HTTP/2](https://tools.ietf.org/html/rfc7540)
- [RFC 9114 - HTTP/3](https://tools.ietf.org/html/rfc9114)
- [MDN - HTTP](https://developer.mozilla.org/ko/docs/Web/HTTP)

---

## 참고 자료

### 공식 문서 & 학습 사이트
- **MDN HTTP 가이드**: https://developer.mozilla.org/ko/docs/Web/HTTP
- **Cloudflare Learning Center**: https://www.cloudflare.com/learning/
- **RFC Editor (HTTP/3 - RFC 9114)**: https://www.rfc-editor.org/rfc/rfc9114

### 추천 도서
| 책 제목 | 교보문고 |
|---------|---------|
| 컴퓨터 네트워크 하향식 접근 | [검색](https://search.kyobobook.co.kr/search?keyword=컴퓨터+네트워크+하향식+접근) |
| 그림으로 배우는 HTTP & Network Basic | [검색](https://search.kyobobook.co.kr/search?keyword=그림으로+배우는+HTTP) |
| HTTP 완벽 가이드 | [검색](https://search.kyobobook.co.kr/search?keyword=HTTP+완벽+가이드) |
