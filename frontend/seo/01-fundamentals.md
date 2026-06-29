# 1. SEO 기초 — 크롤링 · 렌더링 · 인덱싱 · 메타

## 목차
1. [검색 엔진의 4단계: 크롤 → 렌더 → 인덱스 → 랭크](#1-검색-엔진의-4단계-크롤--렌더--인덱스--랭크)
2. [크롤링 제어: robots.txt · 크롤 버짓](#2-크롤링-제어-robotstxt--크롤-버짓)
3. [JS 렌더링과 SEO의 충돌](#3-js-렌더링과-seo의-충돌)
4. [필수 메타 태그](#4-필수-메타-태그)
5. [인덱싱 제어: noindex · canonical](#5-인덱싱-제어-noindex--canonical)
6. [시맨틱 마크업과 콘텐츠 신호](#6-시맨틱-마크업과-콘텐츠-신호)
7. [Core Web Vitals와 랭킹](#7-core-web-vitals와-랭킹)
8. [면접 포인트](#8-면접-포인트)

---

## 1. 검색 엔진의 4단계: 크롤 → 렌더 → 인덱스 → 랭크

1. **크롤링(Crawling)**: 봇(Googlebot)이 링크를 따라 페이지를 발견·다운로드.
2. **렌더링(Rendering)**: HTML을 파싱하고, 필요하면 JS를 실행해 최종 DOM 생성.
3. **인덱싱(Indexing)**: 콘텐츠를 분석해 검색 색인에 저장.
4. **랭킹(Ranking)**: 질의에 대해 관련도·품질·성능 등으로 순위 결정.

> 각 단계에서 막히면 노출이 안 된다: 크롤 차단 → 발견 X, JS 렌더 실패 → 빈 페이지 인덱싱, `noindex` → 색인 제외.

---

## 2. 크롤링 제어: robots.txt · 크롤 버짓

`robots.txt`는 크롤러의 **접근(크롤)**을 제어한다(색인 제어가 아님에 주의).

```
# /robots.txt
User-agent: *
Disallow: /admin/
Allow: /
Sitemap: https://example.com/sitemap.xml
```

- `Disallow`는 "크롤하지 마"일 뿐, **색인 제외가 아니다**. 외부 링크로 발견되면 URL만 색인될 수 있다 → 색인 제외는 `noindex`로.
- **크롤 버짓(crawl budget)**: 사이트당 크롤 자원은 유한. 중복·저품질 URL이 많으면 중요한 페이지가 덜 크롤된다(대형 사이트 이슈).

---

## 3. JS 렌더링과 SEO의 충돌

크롤러는 HTML을 먼저 보고, JS 실행은 **나중에·자원이 될 때** 한다(2차 렌더 큐). CSR SPA는 초기 HTML이 비어 있어 문제가 생긴다.

| 렌더링 | 크롤러가 보는 초기 HTML | SEO |
|--------|----------------------|-----|
| CSR (순수 SPA) | 빈 `<div id="root">` | 취약(렌더 지연·실패 위험) |
| SSR | 완성된 HTML | 좋음 |
| SSG | 빌드된 정적 HTML | 가장 좋음(빠름) |
| 동적 렌더링/프리렌더 | 봇에 렌더된 HTML 제공 | 임시방편 |

> 핵심: **콘텐츠가 첫 HTML에 들어 있어야 안전**하다. 중요한 텍스트·링크를 JS로만 그리면 인덱싱이 불안정하다. 그래서 콘텐츠 사이트는 SSR/SSG를 쓴다.

---

## 4. 필수 메타 태그

```html
<head>
  <title>페이지 제목 — 사이트명</title>          <!-- 50~60자, 페이지마다 고유 -->
  <meta name="description" content="페이지 요약(검색 결과 스니펫에 사용, 120~160자)">
  <meta name="viewport" content="width=device-width, initial-scale=1"> <!-- 모바일 -->
  <link rel="canonical" href="https://example.com/page">  <!-- 정규 URL -->
  <meta charset="utf-8">
</head>
```

- `<title>`과 `description`은 **페이지마다 고유**해야 한다(중복은 품질 저하).
- description은 직접적 랭킹 요소는 아니지만 **클릭률(CTR)**에 영향.
- 제목 계층(`h1` 하나 + 순차적 `h2/h3`)이 콘텐츠 구조 신호가 된다.

---

## 5. 인덱싱 제어: noindex · canonical

```html
<!-- 색인에서 제외 (검색 결과에 안 나오게) -->
<meta name="robots" content="noindex, follow">
```

- `noindex`로 색인 제외(로그인·검색결과·중복 페이지). **단 크롤이 돼야 이 태그를 읽으므로 robots.txt로 막으면 안 됨**(모순).
- **canonical**: 같은/유사 콘텐츠가 여러 URL(파라미터, www 유무, 페이지네이션)일 때 대표 URL을 지정해 **중복 콘텐츠 분산**을 막는다.

```html
<link rel="canonical" href="https://example.com/product">
```

---

## 6. 시맨틱 마크업과 콘텐츠 신호

- 시맨틱 태그(`article`, `nav`, `main`)로 구조를 명확히 → 크롤러가 본문/내비를 구분.
- 이미지 `alt`(이미지 검색 + 접근성), 링크는 의미 있는 앵커 텍스트("여기 클릭" ❌).
- 내부 링크로 페이지 간 관계·중요도 전달(링크 그래프). 고아 페이지(아무도 링크 안 하는)는 발견이 어렵다.

---

## 7. Core Web Vitals와 랭킹

성능은 **페이지 경험(Page Experience)** 신호로 랭킹에 반영된다.

- LCP ≤2.5s, INP ≤200ms, CLS ≤0.1 (→ [성능 면접](../../interview/performance-questions.md), [관측성](../observability/01-error-tracking-rum.md)).
- 모바일 우선 색인(Mobile-first Indexing): Google은 **모바일 버전을 기준으로** 색인한다 → 모바일에서 콘텐츠·구조가 완전해야 한다.
- HTTPS, 침입적 광고(인터스티셜) 없음도 페이지 경험 요소.

> 성능은 동점 상황의 타이브레이커에 가깝다 — 콘텐츠 관련성이 우선이지만, CWV가 나쁘면 손해를 본다.

---

## 8. 면접 포인트

**Q. 검색 엔진이 페이지를 노출하는 단계는?**
> 크롤링(발견·다운로드) → 렌더링(필요시 JS 실행) → 인덱싱(색인 저장) → 랭킹(순위 결정). 각 단계에서 막히면 노출이 안 된다.

**Q. CSR SPA가 SEO에 불리한 이유는?**
> 크롤러가 보는 초기 HTML이 비어 있고 JS 실행은 나중에·불확실하게 일어나기 때문이다. 중요한 콘텐츠가 첫 HTML에 없으면 인덱싱이 불안정하다. 그래서 콘텐츠 중심 사이트는 SSR/SSG로 완성된 HTML을 제공한다.

**Q. robots.txt의 Disallow와 noindex의 차이는?**
> robots.txt의 Disallow는 "크롤하지 마"로 접근을 막을 뿐 색인 제외를 보장하지 않는다(외부 링크로 URL만 색인될 수 있음). 색인에서 빼려면 `<meta name="robots" content="noindex">`를 쓰되, 이 태그를 읽으려면 크롤은 허용해야 한다.

**Q. canonical 태그는 언제 쓰나요?**
> 같은 콘텐츠가 여러 URL(쿼리 파라미터, www 유무, 페이지네이션)로 존재할 때 대표 URL을 지정해 중복 콘텐츠로 인한 평가 분산을 막는다.

**Q. 성능(Core Web Vitals)이 SEO에 영향을 주나요?**
> 페이지 경험 신호로 랭킹에 반영된다. LCP/INP/CLS와 HTTPS·모바일 친화성이 포함된다. 다만 콘텐츠 관련성이 우선이고 CWV는 동점 시 타이브레이커에 가깝다. Google은 모바일 버전 기준으로 색인(mobile-first)한다.
