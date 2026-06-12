# BFF (Backend for Frontend)

프론트엔드 개발자가 알아야 할 BFF 패턴과 관련 기술 스택 학습 자료입니다.

## 학습 목차

1. [BFF 개념](./01-bff-concept.md) — BFF 패턴이란 무엇인가, 왜 필요한가
2. [Express.js](./02-express.md) — BFF 관점의 Express 서버 구성
3. [NestJS](./03-nestjs.md) — 구조화된 Node.js 프레임워크로 BFF 구현
4. [Hono](./04-hono.md) — 경량 엣지 프레임워크로 BFF 구현
5. [tRPC](./05-trpc.md) — 타입 안전 API 레이어
6. [GraphQL](./06-graphql.md) — BFF 계층에서의 GraphQL

## 왜 프론트엔드 개발자가 BFF를 배워야 하는가

현대 웹 개발에서 **풀스택 트렌드**가 강해지면서, 프론트엔드 개발자도 서버 사이드 코드를 작성하는 일이 많아졌습니다.

- Next.js의 **Route Handlers** / **Server Actions** — 사실상 BFF 역할
- Vercel, Cloudflare Workers 등 **엣지 런타임** 보편화
- 마이크로서비스 환경에서 **데이터 집계 책임**을 프론트팀이 맡는 경우 증가
- 타입 안전성(tRPC, Hono RPC)으로 **프론트-백 계약** 명확화

## 추천 학습 순서

```
BFF 개념 이해
    ↓
Express (기본기)
    ↓
NestJS (엔터프라이즈) 또는 Hono (경량/엣지) — 팀 상황에 맞게 선택
    ↓
tRPC 또는 GraphQL — 타입 공유 전략 선택
```

## 관련 링크

- [Express 공식 문서](https://expressjs.com/)
- [NestJS 공식 문서](https://nestjs.com/)
- [Hono 공식 문서](https://hono.dev/)
- [tRPC 공식 문서](https://trpc.io/)
- [Apollo GraphQL](https://www.apollographql.com/)

---

## 참고 자료

### 공식 문서
- **NestJS**: https://docs.nestjs.com/
- **Hono**: https://hono.dev/docs/
- **Express**: https://expressjs.com/ko/
- **tRPC**: https://trpc.io/docs/
- **Apollo GraphQL**: https://www.apollographql.com/docs/
- **Prisma ORM**: https://www.prisma.io/docs/
