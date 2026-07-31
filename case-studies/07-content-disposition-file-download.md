# 07. HTTP 파일 다운로드: `Content-Disposition` 파싱 & Blob 다운로드

> 실전 배경: 정산 엑셀·명세서 다운로드에서 파일명이 이상하게 저장됐다.
> 어떤 건 서버 파일명을 아예 못 읽고, 한글 명세서는 `UTF-8''명세서(최종)_...`처럼
> **`UTF-8''` 접두가 파일명에 그대로** 남았다. 원인은 프론트의 `Content-Disposition` 파서.

## 목차
1. [Content-Disposition: filename vs filename*](#1-content-disposition-filename-vs-filename)
2. [실서버 응답으로 확인한 실제 포맷](#2-실서버-응답으로-확인한-실제-포맷)
3. [올바른 파서 구현](#3-올바른-파서-구현)
4. [CORS: 헤더를 노출해야 JS가 읽는다](#4-cors-헤더를-노출해야-js가-읽는다)
5. [Blob 다운로드 패턴과 파일명 fallback](#5-blob-다운로드-패턴과-파일명-fallback)
6. [면접 포인트](#6-면접-포인트)

---

## 1. Content-Disposition: filename vs filename*

서버가 다운로드 파일명을 알려주는 헤더가 `Content-Disposition`이다. 여기엔 **두 가지 파일명 파라미터**가 있고, 이 둘을 모두 처리해야 한다.

```http
Content-Disposition: attachment; filename="report.xlsx"
Content-Disposition: attachment; filename*=UTF-8''%EB%AA%85%EC%84%B8%EC%84%9C.xlsx
```

| 파라미터 | 정의 | 용도 |
|----------|------|------|
| `filename` | 원래 RFC 2616. **ASCII만** 안전 | 영문 파일명 |
| `filename*` | RFC 5987 확장. `charset''퍼센트인코딩` 형식 | 한글 등 **비ASCII** 파일명 |

`filename*`의 값 구조는 `charset '' percent-encoded-value`다.

```
filename*=UTF-8''%EB%AA%85%EC%84%B8%EC%84%9C.xlsx
          └──┬──┘└┘└──────────┬───────────────┘
          charset  언어(생략)   퍼센트 인코딩된 실제 값
```

즉 `filename*`을 읽을 땐 **`UTF-8''` 접두를 떼고, 나머지를 `decodeURIComponent`로 디코딩**해야 한다. 이 처리를 안 하면 접두가 파일명에 남거나 한글이 `%EB%AA%...`로 저장된다. RFC상 둘 다 있으면 **`filename*`가 우선**이다.

---

## 2. 실서버 응답으로 확인한 실제 포맷

추측하지 않고 실제 dev API를 `curl`로 호출해 응답 헤더를 확인했다. 파서를 고칠 땐 "스펙"보다 "실서버가 실제로 뭘 주는지"가 먼저다.

```
# 엑셀 (filename= only, 따옴표 있음)
filename="kpx_settlement_monthly_2026-01_2026-07.xlsx"

# 명세서 (ASCII fallback + UTF-8 확장 동시 제공)
filename="kpx_statement_fin_15min_20260701.xlsx";
filename*=UTF-8''%EB%AA%85%EC%84%B8%EC%84%9C(%EC%B5%9C%EC%A2%85)_15%EB%B6%84_20260701.xlsx
```

기존 파서의 두 가지 버그가 여기서 드러났다.

1. **`filename=`(따옴표 유무)를 못 읽음** — `filename*=`만 보는 정규식이었다.
2. **charset 대소문자** — `utf-8`(소문자)만 허용해서 실서버의 `UTF-8`을 놓쳤다.

---

## 3. 올바른 파서 구현

```ts
export function parseContentDispositionFilename(header?: string): string | null {
  if (!header) return null;

  // 1) filename*=charset''value (RFC 5987) — 우선
  const extended = /filename\*\s*=\s*([^']*)''([^;]+)/i.exec(header);
  if (extended) {
    const value = extended[2].trim();
    try {
      return decodeURIComponent(value); // 퍼센트 디코딩 (charset은 UTF-8 가정)
    } catch {
      return value; // 잘못된 인코딩이면 원문이라도 반환
    }
  }

  // 2) filename="value" 또는 filename=value
  const basic = /filename\s*=\s*"?([^"';]+)"?/i.exec(header);
  if (basic) return basic[1].trim();

  return null;
}
```

포인트:
- `filename*`를 **먼저** 검사(우선순위).
- 정규식 플래그 `i`로 **charset·키 대소문자 무시**.
- `decodeURIComponent`를 `try/catch`로 감싸 잘못된 인코딩에도 죽지 않게.
- 이 함수는 부수효과 없는 순수 함수라 **단위 테스트로 케이스별 검증**이 쉽다(엑셀/명세서/따옴표 유무/대소문자).

---

## 4. CORS: 헤더를 노출해야 JS가 읽는다

교차 출처 요청에서는 **기본적으로 안전한 응답 헤더 몇 개만** JS(`response.headers.get(...)`)로 접근할 수 있다. `Content-Disposition`은 거기 포함되지 않으므로, 서버가 명시적으로 노출해야 한다.

```http
Access-Control-Expose-Headers: Content-Disposition
```

이게 없으면 `fetch`/`axios`가 응답을 정상 수신해도 **`Content-Disposition` 헤더만 `null`**로 읽혀, 프론트는 원인을 못 찾고 헤맨다. "다운로드는 되는데 파일명만 안 잡힌다"면 CORS expose 설정부터 의심한다.

---

## 5. Blob 다운로드 패턴과 파일명 fallback

응답 본문을 Blob으로 받아 임시 `<a download>`로 저장하는 표준 패턴이다.

```ts
async function downloadApiFile(url: string, fallbackName: string) {
  const res = await http.get(url, { responseType: 'blob' });

  const serverName = parseContentDispositionFilename(
    res.headers['content-disposition'],
  );
  const filename = serverName ?? fallbackName; // 서버 파일명 우선, 없으면 fallback

  const blobUrl = URL.createObjectURL(res.data);
  const a = document.createElement('a');
  a.href = blobUrl;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(blobUrl); // ← 메모리 누수 방지: 반드시 해제
}
```

- **서버 파일명 우선, 없을 때만 하드코딩 fallback**. fallback은 CD 부재 시의 안전망이지 기본값이 아니다.
- `URL.createObjectURL`로 만든 blob URL은 GC되지 않으므로 `revokeObjectURL`로 **명시적 해제**해야 한다(안 하면 누수).
- mock(MSW)의 파일명 포맷이 실서버와 다를 수 있음을 인지하고, 필요 시 동기화한다.

---

## 6. 면접 포인트

**Q. `Content-Disposition`의 `filename`과 `filename*`은 뭐가 다른가요?**
> filename은 RFC 2616 기반이라 ASCII만 안전하고, filename*은 RFC 5987 확장으로 `charset''퍼센트인코딩` 형식이라 한글 같은 비ASCII를 담는다. 둘 다 있으면 filename*이 우선이고, 읽을 때 `UTF-8''` 접두를 떼고 decodeURIComponent로 디코딩해야 한다.

**Q. 한글 파일명이 `%EB%AA%...`나 `UTF-8''...`로 저장되는 이유는?**
> filename* 값을 그대로 파일명에 쓴 것이다. charset''접두를 제거하지 않았거나 퍼센트 디코딩을 안 한 경우다. 파서에서 접두 분리 + decodeURIComponent를 해야 한다.

**Q. 다운로드는 되는데 JS에서 파일명 헤더가 null로 읽힌다면?**
> 교차 출처에서 Content-Disposition은 기본 노출 헤더가 아니라서, 서버가 Access-Control-Expose-Headers에 넣지 않으면 JS가 못 읽는다. CORS expose 설정을 확인한다.

**Q. Blob 다운로드 시 주의할 점은?**
> createObjectURL로 만든 URL은 자동 회수되지 않으므로 클릭 후 revokeObjectURL로 해제해야 메모리 누수가 없다. 그리고 서버 파일명을 우선 쓰되 헤더가 없을 때의 fallback 이름을 둔다.
