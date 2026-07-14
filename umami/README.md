# Umami 셀프호스팅 (Vercel + Supabase)

웹 분석(Umami) 서버를 **Vercel + Supabase** 로 셀프호스팅하기 위한 셋업 가이드다.
이 디렉터리는 **Umami 서버를 실행 가능한 상태로 만드는 것**까지만 다룬다.
프런트엔드(SPA) 클라이언트 트래킹 연동은 별도 작업이며, 방향은
[frontend-integration.md](./frontend-integration.md) 에 정리해 둔다.

> **검증일: 2026-07-13.** 이 문서의 env·빌드·풀러 관련 내용은 이 날짜에
> Umami v2(`umami-software/umami` master)와 Supabase 공식 문서로 확인했다.
> Umami/Supabase 사양은 바뀔 수 있으니, 시간이 지났으면 [출처](#출처)를 재확인할 것.

---

## 이 디렉터리 구성

| 파일 | 용도 |
| --- | --- |
| `README.md` | 배포 가이드 (이 문서) |
| `supabase-setup.sql` | 전용 스키마 + 최소권한 역할 + 접근 차단 SQL |
| `umami.env.example` | Vercel 에 넣을 환경변수 템플릿 |
| `frontend-integration.md` | (다음 작업) 프런트엔드(SPA) 트래킹 & 로그인 연동 설계 |

> 💡 이 작업을 AI 에이전트로 진행한다면 [../ai/mcp-setup.md](../ai/mcp-setup.md) 로 Supabase ·
> Vercel MCP 를 붙이면 배포·DB 상태를 직접 조회하며 검증할 수 있다.

---

## 아키텍처 & 보안 개념

- Umami 는 **Next.js + Prisma** 앱이다. DB 에는 **Prisma 로 Postgres 에 직접 접속**한다.
- 즉 Supabase 의 **anon key / PostgREST(REST API) 를 전혀 쓰지 않는다.** Umami 는
  DB 접속 문자열(사용자명+비밀번호)로 로그인하는 "전용 계정" 방식이다.
- 따라서 "anon 에서 직접 접근 차단"의 실제 수단은 RLS/anon 설정이 아니라 다음 둘이다.
  1. **전용 스키마(`umami`)를 PostgREST 에 노출하지 않기** — Supabase 는 *Exposed schemas*
     에 등록된 스키마(기본 `public`)만 REST API 로 뚫어준다. `umami` 를 등록하지 않으면
     anon/authenticated 로 외부에서 접근할 수 없다.
  2. **전용 최소권한 역할(`umami_app`)로만 접속** — `postgres` 슈퍼유저나 `service_role`
     이 아니라, `umami` 스키마에만 권한이 있는 독립 역할을 만들어 그 계정으로 접속한다.

`supabase-setup.sql` 이 위 1·2를 세팅한다.

---

## 실행 주체: 수동 vs 자동

셋업은 **사람이 직접 하는 부분**과 **Umami 빌드가 자동으로 하는 부분**으로 나뉜다.
이 구분과 순서를 헷갈리지 말 것 (SQL 먼저, 배포 나중).

| 대상 | 무엇으로 | 언제 / 누가 |
| --- | --- | --- |
| 스키마 `umami` + 역할 `umami_app` + 권한 격리 | `supabase-setup.sql` | **수동 1회** — Supabase SQL Editor 에서 사람이 실행 |
| 스키마 안 테이블 (`website`, `session` 등) | `scripts/check-db.js` → `prisma migrate deploy` | **자동** — Vercel 배포 빌드 때마다 Umami 가 실행 |

> `check-db.js` 는 Umami 의 `build` 스크립트 체인(`... → check-db → ...`)에 포함돼 있어,
> **fork 에 push → Vercel 자동 빌드** 흐름에서 자동 실행된다. 수동으로 돌릴 필요 없다.
> (버전 업 시에도 다음 배포 때 마이그레이션이 자동 반영)
>
> 그래서 순서가 중요하다 — **빈 스키마·역할을 SQL 로 먼저 깔고(2단계)**, 그 다음
> **Vercel 배포(4단계)** 때 테이블이 채워진다.

---

## 사전 준비

- GitHub 계정 (Umami fork 용)
- Vercel 계정
- Supabase 프로젝트 1개
- 로컬에 `openssl` (시크릿 생성용)

---

## 1단계 — Umami fork & Vercel Import

1. `https://github.com/umami-software/umami` 를 본인/조직 계정으로 **fork** 한다.
   (Umami 앱 코드는 서비스 애플리케이션 레포에 넣지 말고 별도 저장소로 운영한다.)
2. Vercel → **Add New… → Project → Import** 에서 fork 한 저장소를 선택한다.
3. Framework 는 자동으로 **Next.js** 로 잡힌다. 빌드 설정은 기본값 그대로 둔다.
4. **아직 Deploy 하지 말고** 환경변수부터 채운다(3단계). DB 없이 배포하면 빌드가 실패한다.

---

## 2단계 — Supabase 셋업

1. Supabase 프로젝트를 만든다. (DB 비밀번호는 안전하게 보관)
2. **SQL Editor** 에서 `supabase-setup.sql` 을 연다.
   - 파일 안 `CHANGE_ME_STRONG_PASSWORD` 를 강력한 무작위 값으로 교체한다.
     (예: `openssl rand -base64 24` — 이 값이 `umami_app` 역할의 비밀번호)
   - 실행한다. → 전용 스키마 `umami`, 역할 `umami_app`, 접근 차단이 적용된다.
3. **Settings → API → Exposed schemas** 를 연다.
   - **`umami` 를 추가하지 않는다.** 기본값(`public`, `graphql_public`)만 유지.
     → `umami` 스키마는 REST API 로 노출되지 않는다.
4. **Connect** 버튼(상단)에서 커넥션 문자열 2종을 확보한다.
   - **Transaction pooler** (포트 `6543`) → 런타임용 `DATABASE_URL`
   - **Session pooler** (포트 `5432`) → 마이그레이션용 `DIRECT_DATABASE_URL`
   - 두 문자열 모두 사용자명이 `postgres.<PROJECT_REF>` 로 되어 있는데, 이를
     **`umami_app.<PROJECT_REF>`** 로 바꾸고 비밀번호도 2단계에서 정한
     `umami_app` 비밀번호로 교체한다.
   - ⚠️ **호스트명은 반드시 대시보드 값을 그대로 쓴다.** `aws-0` / `aws-1` 등
     클러스터 번호는 프로젝트마다 다르며, 넘겨짚어 틀리면 접속은 되지만 쿼리에서
     `Tenant or user not found` 에러가 난다. (자세한 진단은
     [트러블슈팅](#트러블슈팅) 참고)

> **왜 커넥션이 2개인가?**
> Umami 빌드 단계(`scripts/check-db.js`)가 `prisma migrate deploy` 로 테이블을
> 생성/갱신하는데, 마이그레이션(DDL·`CREATE INDEX` 등)은 트랜잭션 풀러(6543)에서
> 실패할 수 있다. Umami 는 이를 위해 **`DIRECT_DATABASE_URL`** 을 지원하며, 이 값이
> 있으면 마이그레이션만 그 커넥션으로 실행한다. 런타임 쿼리는 `DATABASE_URL`(6543)을 쓴다.

---

## 3단계 — Vercel 환경변수 등록

`umami.env.example` 을 참고해 Vercel → Project → **Settings → Environment Variables** 에
아래를 등록한다. (Production/Preview 모두 필요하면 각각 등록)

| 변수 | 값 |
| --- | --- |
| `DATABASE_URL` | Transaction pooler(6543), `?pgbouncer=true&schema=umami&connection_limit=1` |
| `DIRECT_DATABASE_URL` | Session pooler(5432), `?schema=umami` |
| `APP_SECRET` | `openssl rand -hex 32` 결과 |

선택 변수(`TRACKER_SCRIPT_NAME`, `DISABLE_TELEMETRY` 등)는 `umami.env.example` 참고.

---

## 4단계 — 배포 & 첫 로그인

1. Vercel 에서 **Deploy** 한다. 빌드 로그에 `prisma migrate deploy` 가 성공하고
   `umami` 스키마에 테이블이 생성되는지 확인한다.
2. 배포된 URL 로 접속 → 기본 계정으로 로그인한다.
   - 사용자명 `admin` / 비밀번호 `umami`
3. **⚠️ 로그인 직후 비밀번호를 즉시 변경한다.** (Settings → Profile)
4. Settings → Websites 에서 추적할 사이트를 등록하면 `data-website-id` 와
   트래커 스크립트 스니펫을 얻는다. (클라이언트 연동은 다음 작업에서 사용)

---

## 배포 검증 체크리스트

- [ ] Vercel 빌드 로그에서 `prisma migrate deploy` 성공
- [ ] Supabase → Table Editor 에서 테이블이 **`umami` 스키마**에 생성됨 (public 아님)
- [ ] Settings → API → Exposed schemas 에 `umami` **없음**
- [ ] `umami_app` 로 `public` 등 다른 스키마 접근 시 permission denied
      (검증 쿼리는 `supabase-setup.sql` 하단 주석 참고)
- [ ] Umami 로그인 성공 & 기본 비밀번호 변경 완료

---

## 트러블슈팅

- **빌드에서 마이그레이션 실패 / prepared statement 관련 에러**
  → `DIRECT_DATABASE_URL` 이 **Session pooler(5432)** 인지 확인. Transaction
  pooler(6543)를 넣으면 마이그레이션이 깨질 수 있다.
- **런타임에서 커넥션 고갈 / too many connections**
  → `DATABASE_URL` 에 `pgbouncer=true` 와 `connection_limit=1` 이 있는지 확인.
- **테이블이 `public` 에 생김**
  → 두 커넥션 문자열 모두 `?schema=umami` 가 붙었는지, `supabase-setup.sql` 의
  `alter role umami_app ... set search_path = umami` 가 적용됐는지 확인.
- **풀러가 `umami_app` 계정을 거부**
  → 역할에 `LOGIN` 이 있는지, 사용자명 형식이 `umami_app.<PROJECT_REF>` 인지
  (Dashboard → Connect 의 형식과 대조) 확인.
- **`Tenant or user not found` (연결은 되는데 쿼리에서 실패)**
  → 풀러 **호스트명**이 틀린 경우가 대부분. `aws-0` 로 넘겨짚었지만 실제로는
  `aws-1-<region>...` 인 식. Dashboard → Connect 의 Host 를 그대로 복사해
  `DATABASE_URL`·`DIRECT_DATABASE_URL` **둘 다** 교체한다. "Database connection
  successful" 이 뜬 뒤 version 체크(`$queryRaw`)에서 이 에러가 나는 게 전형적 증상.
- **대안: 트랜잭션 풀러 단일 커넥션만 쓰고 싶을 때**
  → `DATABASE_URL` 만 6543 으로 두고 `SKIP_DB_MIGRATION=1` 을 설정한 뒤,
  마이그레이션은 세션/direct 커넥션으로 수동 1회 실행(`prisma migrate deploy`).
  단, 이후 Umami 버전 업 때마다 수동 마이그레이션이 필요해 운영 부담이 늘어난다.

---

## 향후: 프런트엔드 연동

Umami 서버가 뜬 뒤의 클라이언트 트래킹(SPA 라우트 추적)과 로그인 연동 설계는
별도 문서로 분리했다 — **[frontend-integration.md](./frontend-integration.md)**.
(서버 셋업과는 다른 단계의 작업)

---

## 출처

- [Umami – Environment variables](https://docs.umami.is/docs/environment-variables)
- [Umami – Install / requirements](https://docs.umami.is/docs/install)
- [umami-software/umami – `scripts/check-db.js`](https://github.com/umami-software/umami/blob/master/scripts/check-db.js) (`DIRECT_DATABASE_URL` / `SKIP_DB_MIGRATION` 처리)
- [umami-software/umami – `prisma/schema.prisma`](https://github.com/umami-software/umami/blob/master/prisma/schema.prisma) (`provider = postgresql`, `directUrl` 없음)
- [Supabase – Prisma 연동](https://supabase.com/docs/guides/database/prisma)
- [Supabase – Connect to your database (pooler modes)](https://supabase.com/docs/guides/database/connecting-to-postgres)
- [Prisma – Migrations with Supabase Supavisor(transaction mode) 이슈](https://github.com/prisma/prisma/issues/22779)
