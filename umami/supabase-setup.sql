-- =============================================================================
-- Umami × Supabase 격리 셋업 SQL
--
-- 검증일: 2026-07-13 (Umami v2 / umami-software/umami master 기준)
-- 실행 위치: Supabase Dashboard → SQL Editor  (기본 postgres 역할로 실행)
--
-- 목적:
--   1) Umami 전용 스키마 `umami` 생성 (public 스키마 오염 방지)
--   2) 전용 최소권한 로그인 역할 `umami_app` 생성 (스키마에 CREATE 권한만 부여)
--   3) anon / authenticated / public 로부터 접근 차단 (PostgREST 노출 방지)
--
-- 배경:
--   Umami 는 Prisma 로 Postgres 에 "직접" 접속한다. Supabase 의 anon key /
--   PostgREST(REST API) 경로는 전혀 사용하지 않는다. 따라서 실질적인 격리
--   포인트는 RLS/anon 설정이 아니라 아래 두 가지다.
--     (a) 전용 스키마를 PostgREST 에 "노출하지 않기" (아래 마지막 주석 참고)
--     (b) 전용 최소권한 역할로만 접속하기 (이 스크립트)
--
-- 설계 메모 — 왜 스키마 소유자를 umami_app 이 아니라 postgres 로 두는가:
--   Supabase SQL Editor 는 postgres 역할 + 커넥션 풀러(Supavisor)로 실행된다.
--   `create schema ... authorization umami_app` 나 `grant umami_app to postgres`
--   처럼 "다른 역할로 SET ROLE" 또는 "postgres 의 멤버십 변경" 을 요구하는 구문은
--     - ERROR: 42501: must be able to SET ROLE "umami_app", 또는
--     - Connection terminated unexpectedly (풀러가 인증 역할 변경에 커넥션 리셋)
--   를 유발할 수 있다.
--   그래서 스키마는 postgres 소유로 두고 umami_app 에는 USAGE + CREATE 만 부여한다.
--   격리 효과는 동일하다: umami_app 이 만드는 테이블은 umami_app 소유가 되고,
--   anon/authenticated 는 스키마 USAGE 자체가 없어 접근 불가.
-- =============================================================================


-- 0) 전용 로그인 역할 생성 ----------------------------------------------------
--    - 비밀번호는 반드시 강력한 무작위 값으로 교체할 것.
--        예) openssl rand -base64 24
--    - NOSUPERUSER / NOCREATEDB / NOCREATEROLE / NOINHERIT 로 권한 최소화.
--    - 이 역할은 authenticator/anon/authenticated 와 무관한 독립 역할이다.
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'umami_app') then
    create role umami_app with login password 'CHANGE_ME_STRONG_PASSWORD'
      nosuperuser nocreatedb nocreaterole noinherit;
  end if;
end $$;


-- 1) 전용 스키마 생성 (소유자 = 실행 역할 postgres) --------------------------
--    umami_app 에는 USAGE(진입) + CREATE(테이블/인덱스 생성) 만 부여한다.
--    → Umami(Prisma migrate)가 이 스키마 안에서 객체를 만들 수 있고,
--      만들어진 객체의 소유자는 umami_app 이 된다.
create schema if not exists umami;
grant usage, create on schema umami to umami_app;


-- 2) 커넥션 기본 search_path 고정 --------------------------------------------
--    풀러(transaction/session) 모드나 Prisma 의 ?schema 파라미터 전달 여부와
--    무관하게, umami_app 로 접속한 세션은 항상 umami 스키마를 먼저 보게 한다.
--    (transaction pooling + pgbouncer=true 환경에서도 스키마가 어긋나지 않도록
--     하는 안전장치.)
alter role umami_app in database postgres set search_path = umami;


-- 3) anon / authenticated / public 접근 차단 ---------------------------------
--    Umami 는 PostgREST 를 쓰지 않지만, 방어적으로 REST/역할 기반 접근을
--    원천 차단한다. 스키마 USAGE 를 제거하면 그 안의 어떤 객체에도 접근할 수 없다.
--    (신규 스키마라 이들 역할은 원래 USAGE 가 없지만, 명시적으로 못박음)
revoke all on schema umami from anon, authenticated, public;


-- =============================================================================
-- ⚠️ 대시보드에서 반드시 확인 (SQL 로는 설정 불가):
--
--   Settings → API → "Exposed schemas" 에 `umami` 를 추가하지 말 것.
--   기본값(public, graphql_public)만 유지하면 umami 스키마는 REST API 로
--   노출되지 않는다. → anon key 로도 외부에서 접근 불가.
--
-- ✅ 격리 검증 (선택):
--   -- 스키마/역할이 만들어졌는지
--   select nspname as schema, pg_get_userbyid(nspowner) as owner
--   from pg_namespace where nspname = 'umami';
--   -- umami_app 에 부여된 스키마 권한 확인 (USAGE/CREATE 만 있어야 정상)
--   select grantee, privilege_type
--   from information_schema.role_usage_grants
--   where object_schema = 'umami';
-- =============================================================================
