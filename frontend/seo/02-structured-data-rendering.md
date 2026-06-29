# 2. 구조화 데이터 · 렌더링 전략

## 목차
1. [구조화 데이터란 (Schema.org)](#1-구조화-데이터란-schemaorg)
2. [JSON-LD 작성](#2-json-ld-작성)
3. [리치 결과(Rich Results)](#3-리치-결과rich-results)
4. [렌더링 전략별 SEO 비교](#4-렌더링-전략별-seo-비교)
5. [Next.js 메타데이터/렌더링 예](#5-nextjs-메타데이터렌더링-예)
6. [동적 렌더링과 프리렌더링](#6-동적-렌더링과-프리렌더링)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 구조화 데이터란 (Schema.org)

검색 엔진이 콘텐츠의 **의미**를 이해하도록 표준 어휘(**Schema.org**)로 표시하는 메타데이터. "이건 상품이고 가격은 X, 평점은 Y"를 기계가 읽을 수 있게 한다. 그 결과 검색 결과에 별점·가격·FAQ 같은 **리치 결과**가 노출된다.

표기 방식 3가지: **JSON-LD(권장)**, Microdata, RDFa. Google은 JSON-LD를 권장한다(마크업과 분리돼 관리 쉬움).

---

## 2. JSON-LD 작성

`<script type="application/ld+json">`에 별도 블록으로 넣는다(보이는 HTML과 분리).

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Product",
  "name": "무선 이어폰",
  "image": "https://example.com/img.jpg",
  "description": "노이즈 캔슬링 이어폰",
  "brand": { "@type": "Brand", "name": "Acme" },
  "offers": {
    "@type": "Offer",
    "price": "129000",
    "priceCurrency": "KRW",
    "availability": "https://schema.org/InStock"
  },
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.5",
    "reviewCount": "230"
  }
}
</script>
```

- 자주 쓰는 타입: `Article`/`NewsArticle`, `Product`, `BreadcrumbList`, `FAQPage`, `Organization`, `Recipe`, `Event`.
- **표시된 콘텐츠와 일치해야 한다** — 페이지에 없는 평점을 마크업하면 스팸으로 페널티.
- Google **Rich Results Test**로 검증.

---

## 3. 리치 결과(Rich Results)

구조화 데이터가 만드는 향상된 검색 결과:
- 별점·리뷰 수(Product/Review), 빵부스러기 경로(BreadcrumbList), FAQ 아코디언(FAQPage), 사이트링크 검색창, 레시피 카드 등.
- 효과: CTR 상승(눈에 띄어서). 단 **노출은 Google 재량**(마크업이 있다고 항상 나오진 않음).

---

## 4. 렌더링 전략별 SEO 비교

| 전략 | 초기 HTML | SEO | 적합 |
|------|----------|-----|------|
| **CSR** | 빈 셸 | 취약 | 로그인 후 대시보드(SEO 불필요) |
| **SSR** | 요청 시 완성 | 좋음 | 자주 바뀌는 동적 콘텐츠(상품·뉴스) |
| **SSG** | 빌드 시 완성 | 최상(빠름) | 블로그·문서·랜딩(거의 고정) |
| **ISR** | 정적 + 주기적 재생성 | 최상 | 대량 페이지 + 가끔 갱신(이커머스 카탈로그) |
| **스트리밍 SSR** | 점진 전송 | 좋음 | 초기 콘텐츠 빠른 노출 |

> SEO가 중요한 공개 콘텐츠는 **SSR/SSG/ISR**로 첫 HTML에 콘텐츠를 담는다. 비공개·상호작용 위주 화면은 CSR로 충분하다.

---

## 5. Next.js 메타데이터/렌더링 예

App Router는 서버에서 메타데이터를 동적 생성한다(페이지별 고유 title/OG 보장).

```tsx
// app/products/[id]/page.tsx
export async function generateMetadata({ params }) {
  const product = await getProduct(params.id);   // 서버에서 데이터
  return {
    title: `${product.name} — 쇼핑몰`,
    description: product.summary,
    openGraph: { images: [product.image] },
    alternates: { canonical: `/products/${params.id}` },
  };
}

export default async function Page({ params }) {
  const product = await getProduct(params.id);    // 서버 렌더 → 완성 HTML
  return <ProductView product={product} />;
}
```

> 동적 메타데이터를 서버에서 생성하면 각 페이지가 고유한 title·description·OG·canonical을 갖는다(CSR에서 클라이언트로 `document.title`을 바꾸면 크롤러가 못 볼 수 있음).

---

## 6. 동적 렌더링과 프리렌더링

레거시 SPA를 당장 SSR로 못 바꿀 때의 임시방편:
- **프리렌더링(prerender)**: 빌드/요청 시 헤드리스 브라우저로 HTML을 미리 생성해 제공(prerender.io, `react-snap`).
- **동적 렌더링(dynamic rendering)**: 봇에게만 렌더된 HTML을, 사용자에겐 CSR을 제공. Google은 한때 권장했으나 지금은 **차선책**으로 본다(클로킹 오해 위험은 콘텐츠가 동일하면 없음).

> 근본 해결은 SSR/SSG로의 전환이다. 프리렌더는 동적 콘텐츠가 적을 때만 유효하다.

---

## 7. 면접 포인트

**Q. 구조화 데이터(JSON-LD)는 무엇이고 왜 쓰나요?**
> Schema.org 어휘로 콘텐츠의 의미(상품·가격·평점·FAQ)를 기계가 읽게 표시하는 메타데이터다. 검색 결과에 별점·가격 같은 리치 결과를 띄워 CTR을 높인다. Google은 HTML과 분리되는 JSON-LD를 권장한다.

**Q. 구조화 데이터 작성 시 주의점은?**
> 페이지에 실제로 표시된 콘텐츠와 일치해야 한다. 없는 평점·가격을 마크업하면 스팸으로 페널티를 받는다. Rich Results Test로 검증하고, 리치 결과 노출 여부는 Google 재량임을 안다.

**Q. SEO 관점에서 렌더링 전략을 어떻게 고르나요?**
> 공개 콘텐츠는 첫 HTML에 내용이 담기는 SSR/SSG/ISR을 쓴다. 거의 고정이면 SSG, 자주 바뀌면 SSR, 대량 페이지+가끔 갱신은 ISR. 로그인 후 대시보드처럼 SEO가 불필요한 화면은 CSR로 충분하다.

**Q. CSR에서 `document.title`을 바꾸면 SEO가 되나요?**
> 위험하다. 크롤러가 JS 실행 전 초기 HTML을 보거나 렌더를 지연하면 클라이언트로 바꾼 메타데이터를 못 볼 수 있다. 메타데이터는 서버에서(예: Next.js `generateMetadata`) 생성해 첫 HTML에 담는 게 안전하다.

**Q. 동적 렌더링(dynamic rendering)은 무엇인가요?**
> 봇에게는 서버에서 렌더한 HTML을, 사용자에게는 CSR을 제공하는 임시방편이다. 레거시 SPA에 쓰지만 근본 해결은 SSR/SSG 전환이며, 봇과 사용자에게 같은 콘텐츠를 줘야 클로킹 문제가 없다.
