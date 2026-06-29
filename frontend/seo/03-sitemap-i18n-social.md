# 3. 사이트맵 · 국제화 · 소셜 · 정규화

## 목차
1. [XML 사이트맵](#1-xml-사이트맵)
2. [국제화 SEO — hreflang](#2-국제화-seo--hreflang)
3. [중복 콘텐츠와 정규화(canonical) 심화](#3-중복-콘텐츠와-정규화canonical-심화)
4. [URL 설계](#4-url-설계)
5. [소셜 공유 — Open Graph · Twitter Card](#5-소셜-공유--open-graph--twitter-card)
6. [페이지네이션·무한스크롤의 SEO](#6-페이지네이션무한스크롤의-seo)
7. [면접 포인트](#7-면접-포인트)

---

## 1. XML 사이트맵

사이트의 중요한 URL 목록을 크롤러에 알려주는 파일. 발견을 돕는다(특히 내부 링크가 약하거나 큰 사이트).

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://example.com/products/1</loc>
    <lastmod>2024-06-01</lastmod>
  </url>
</urlset>
```

- URL이 5만 개/50MB를 넘으면 **사이트맵 인덱스**로 분할.
- `robots.txt`에 `Sitemap:` 경로 명시 + Search Console 제출.
- 사이트맵에는 **인덱싱 가능한(200, noindex 아님, canonical 자기 자신) URL만** 넣는다.

---

## 2. 국제화 SEO — hreflang

언어/지역별 페이지가 있을 때, 검색 엔진에 **각 버전의 대상 언어·지역**을 알려 올바른 버전을 노출시킨다.

```html
<link rel="alternate" hreflang="ko-KR" href="https://example.com/ko/page">
<link rel="alternate" hreflang="en-US" href="https://example.com/en/page">
<link rel="alternate" hreflang="x-default" href="https://example.com/page"> <!-- 기본/매칭 없음 -->
```

규칙:
- **상호 참조(reciprocal)**: A가 B를 가리키면 B도 A를 가리켜야 유효.
- 각 페이지는 자기 자신 포함 모든 대안을 나열.
- `x-default`로 매칭 안 되는 사용자의 기본 버전 지정.
- 언어 자동 리디렉트는 크롤러를 가둘 수 있어 주의(봇은 보통 미국 IP).

---

## 3. 중복 콘텐츠와 정규화(canonical) 심화

중복 콘텐츠는 평가가 여러 URL로 분산돼 손해다. 흔한 원인과 정규화:

| 원인 | 해결 |
|------|------|
| `http`/`https`, `www` 유무 | 301 리디렉트로 한 버전 통일 |
| 추적 파라미터(`?utm=...`) | canonical을 파라미터 없는 URL로 |
| 정렬·필터 파라미터 | 대표 URL canonical |
| 모바일/AMP 별도 URL | canonical로 연결 |

> canonical은 **힌트**지 명령이 아니다(Google이 무시할 수도). 강제 통일은 301 리디렉트가 확실하다.

---

## 4. URL 설계

- 짧고 의미 있는 경로: `/blog/seo-guide` > `/p?id=8472`.
- 소문자·하이픈(언더스코어 X), 안정적(바뀌면 301).
- 카테고리 구조를 반영하되 너무 깊지 않게.
- 키워드를 자연스럽게 포함하되 스터핑 금지.

---

## 5. 소셜 공유 — Open Graph · Twitter Card

링크를 SNS/메신저에 붙였을 때 보이는 미리보기 카드. 직접 랭킹 요소는 아니지만 **공유 CTR**에 큰 영향.

```html
<!-- Open Graph (Facebook, 카카오톡, 슬랙 등 대부분) -->
<meta property="og:title" content="페이지 제목">
<meta property="og:description" content="요약">
<meta property="og:image" content="https://example.com/og.png"> <!-- 1200×630 권장 -->
<meta property="og:url" content="https://example.com/page">
<meta property="og:type" content="article">

<!-- Twitter Card -->
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="페이지 제목">
<meta name="twitter:image" content="https://example.com/og.png">
```

- OG 이미지는 절대 URL, 1200×630(1.91:1) 권장.
- **CSR로 메타를 클라이언트에서 주입하면 크롤러가 못 본다** → 소셜 봇은 JS 실행 안 함. SSR/SSG로 첫 HTML에 OG 태그를 넣어야 한다.
- 캐싱돼 안 바뀌면 각 플랫폼 디버거로 캐시 갱신.

---

## 6. 페이지네이션·무한스크롤의 SEO

- 무한 스크롤은 크롤러가 스크롤하지 않아 **2페이지 이후 콘텐츠를 못 본다** → 페이지네이션 URL(`?page=2`)을 함께 제공해 크롤 가능하게.
- 각 페이지는 고유 URL + 자기 canonical. 과거 권장되던 `rel=next/prev`는 Google이 색인 신호로 더는 쓰지 않는다(여전히 접근성/UX엔 유효).
- "모두 보기" 페이지가 있으면 그쪽을 canonical로 둘 수도.

---

## 7. 면접 포인트

**Q. XML 사이트맵에는 어떤 URL을 넣나요?**
> 인덱싱 가능한 URL만 — 200 응답, noindex가 아니고, canonical이 자기 자신인 정규 URL. noindex·리디렉트·중복 URL을 넣으면 신호가 혼란스러워진다. 5만 개를 넘으면 사이트맵 인덱스로 분할한다.

**Q. hreflang은 무엇이고 유효 조건은?**
> 언어/지역별 페이지의 대상을 검색 엔진에 알려 올바른 버전을 노출시킨다. 상호 참조(서로를 가리킴)가 필수이고, 각 페이지가 자기 포함 모든 대안을 나열하며, `x-default`로 기본 버전을 둔다.

**Q. 중복 콘텐츠를 canonical과 301 중 무엇으로 해결하나요?**
> canonical은 힌트라 Google이 무시할 수 있어, http/https·www 통일처럼 확실히 한 버전만 남겨야 하면 301 리디렉트가 낫다. 추적 파라미터·정렬 변형처럼 페이지는 살려야 하면 canonical로 대표 URL을 가리킨다.

**Q. CSR 앱에서 OG 태그가 미리보기에 안 나오는 이유는?**
> 소셜 크롤러(카카오·페이스북 봇)는 JS를 실행하지 않아 클라이언트에서 주입한 메타를 못 본다. OG 태그는 SSR/SSG로 서버가 첫 HTML에 넣어야 미리보기 카드가 뜬다.

**Q. 무한 스크롤 페이지의 SEO 문제와 해결은?**
> 크롤러는 스크롤하지 않아 첫 화면 이후 콘텐츠를 못 본다. 각 묶음에 크롤 가능한 페이지네이션 URL(`?page=2`)을 제공하고 고유 URL+자기 canonical을 둬서 봇이 전체를 발견하게 한다.
