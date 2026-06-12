# 13. JavaScript Intl API 완전 가이드

## 목차

1. Intl이란?
2. Intl.DateTimeFormat
3. Intl.NumberFormat
4. Intl.RelativeTimeFormat
5. Intl.Collator
6. Intl.ListFormat
7. Intl.PluralRules
8. Intl.Segmenter
9. Intl.Locale
10. 성능 팁
11. dayjs / date-fns와 비교
12. 브라우저 호환성
13. 면접 포인트

---

## 1. Intl이란?

`Intl`은 ECMAScript Internationalization API의 네임스페이스 객체다. 언어·지역(locale)에 맞는 날짜, 숫자, 문자열 비교 등을 **브라우저/Node.js 내장** 기능으로 처리할 수 있게 해준다.

- 표준: ECMA-402 (ECMAScript Internationalization API Specification)
- 별도 라이브러리 없이 사용 가능
- locale 문자열은 BCP 47 태그 형식 사용 (`"ko-KR"`, `"en-US"`, `"ja-JP"` 등)

```js
// locale 지원 여부 확인
console.log(Intl.DateTimeFormat.supportedLocalesOf(["ko-KR", "xx-XX"]));
// ["ko-KR"]
```

---

## 2. Intl.DateTimeFormat

날짜와 시간을 locale에 맞게 포맷한다.

### 기본 사용

```js
const date = new Date("2024-03-15T09:30:00");

// 한국어
new Intl.DateTimeFormat("ko-KR").format(date);
// "2024. 3. 15."

// 미국 영어
new Intl.DateTimeFormat("en-US").format(date);
// "3/15/2024"

// 일본어
new Intl.DateTimeFormat("ja-JP").format(date);
// "2024/3/15"
```

### 주요 옵션

```js
const formatter = new Intl.DateTimeFormat("ko-KR", {
  year: "numeric",    // "2024"
  month: "long",      // "3월"
  day: "numeric",     // "15일"
  weekday: "long",    // "금요일"
  hour: "2-digit",
  minute: "2-digit",
  second: "2-digit",
  hour12: false,      // 24시간제
});

formatter.format(date);
// "2024년 3월 15일 금요일 09:30:00"
```

### timeZone 옵션

```js
const formatter = new Intl.DateTimeFormat("en-US", {
  timeZone: "America/New_York",
  dateStyle: "full",
  timeStyle: "long",
});

formatter.format(new Date());
// "Friday, March 15, 2024 at 7:30:00 PM EST"
```

### dateStyle / timeStyle 단축 옵션

```js
// dateStyle: "full" | "long" | "medium" | "short"
new Intl.DateTimeFormat("ko-KR", { dateStyle: "full" }).format(date);
// "2024년 3월 15일 금요일"

new Intl.DateTimeFormat("ko-KR", { dateStyle: "short", timeStyle: "short" }).format(date);
// "24. 3. 15. 오전 9:30"
```

### formatToParts — 부분별 분리

```js
const parts = new Intl.DateTimeFormat("ko-KR", {
  year: "numeric",
  month: "long",
  day: "numeric",
}).formatToParts(date);

// [
//   { type: "year",    value: "2024" },
//   { type: "literal", value: "년 " },
//   { type: "month",   value: "3" },
//   { type: "literal", value: "월 " },
//   { type: "day",     value: "15" },
//   { type: "literal", value: "일" },
// ]
```

---

## 3. Intl.NumberFormat

숫자를 locale에 맞게 포맷한다.

### 기본 숫자 포맷

```js
const num = 1234567.89;

new Intl.NumberFormat("ko-KR").format(num); // "1,234,567.89"
new Intl.NumberFormat("de-DE").format(num); // "1.234.567,89"  (독일식)
new Intl.NumberFormat("hi-IN").format(num); // "12,34,567.89"  (인도식)
```

### 통화 (currency)

```js
new Intl.NumberFormat("ko-KR", {
  style: "currency",
  currency: "KRW",
}).format(50000);
// "₩50,000"

new Intl.NumberFormat("en-US", {
  style: "currency",
  currency: "USD",
}).format(1234.5);
// "$1,234.50"

// currencyDisplay 옵션: "symbol" | "narrowSymbol" | "code" | "name"
new Intl.NumberFormat("ko-KR", {
  style: "currency",
  currency: "USD",
  currencyDisplay: "name",
}).format(100);
// "미국 달러 100.00"
```

### 퍼센트

```js
new Intl.NumberFormat("ko-KR", {
  style: "percent",
  maximumFractionDigits: 1,
}).format(0.856);
// "85.6%"
```

### 단위 (unit)

```js
new Intl.NumberFormat("ko-KR", {
  style: "unit",
  unit: "kilometer-per-hour",
  unitDisplay: "short",
}).format(120);
// "120km/h"

new Intl.NumberFormat("en-US", {
  style: "unit",
  unit: "liter",
  unitDisplay: "long",
}).format(3.5);
// "3.5 liters"
```

### 컴팩트 표기 (compact)

```js
new Intl.NumberFormat("ko-KR", {
  notation: "compact",
}).format(12345678);
// "1234만"

new Intl.NumberFormat("en-US", {
  notation: "compact",
  compactDisplay: "short",
}).format(12345678);
// "12M"
```

---

## 4. Intl.RelativeTimeFormat

현재 시각 기준의 상대적 시간 표현을 제공한다.

```js
const rtf = new Intl.RelativeTimeFormat("ko-KR", { numeric: "auto" });

rtf.format(-3, "day");    // "3일 전"
rtf.format(2, "hour");    // "2시간 후"
rtf.format(-1, "day");    // "어제"    (numeric: "auto"일 때)
rtf.format(1, "day");     // "내일"
rtf.format(-1, "month");  // "지난달"

const rtfEn = new Intl.RelativeTimeFormat("en-US", { numeric: "auto" });
rtfEn.format(-1, "day");  // "yesterday"
rtfEn.format(3, "week");  // "in 3 weeks"
```

### 유틸 함수 예시

```js
function getRelativeTime(date) {
  const rtf = new Intl.RelativeTimeFormat("ko-KR", { numeric: "auto" });
  const diffMs = date - Date.now();
  const diffSec = Math.round(diffMs / 1000);
  const diffMin = Math.round(diffSec / 60);
  const diffHour = Math.round(diffMin / 60);
  const diffDay = Math.round(diffHour / 24);

  if (Math.abs(diffSec) < 60) return rtf.format(diffSec, "second");
  if (Math.abs(diffMin) < 60) return rtf.format(diffMin, "minute");
  if (Math.abs(diffHour) < 24) return rtf.format(diffHour, "hour");
  return rtf.format(diffDay, "day");
}
```

---

## 5. Intl.Collator

언어별 문자열 정렬·비교를 처리한다. 단순 `<`, `>` 비교는 유니코드 코드포인트 기준이라 언어별로 올바르지 않을 수 있다.

```js
const words = ["banana", "äpfel", "cherry", "apricot"];

// 기본 sort (코드포인트 기준 — ä가 z 뒤에 올 수 있음)
words.sort();

// Collator 사용
words.sort(new Intl.Collator("de").compare);
// ["äpfel", "apricot", "banana", "cherry"]  — 독일어 기준 정렬
```

### sensitivity 옵션

```js
const col = new Intl.Collator("en", { sensitivity: "base" });

// "base": 기본 문자만 비교 (대소문자·악센트 무시)
col.compare("a", "A");  // 0 (같음)
col.compare("a", "á");  // 0 (같음)

// "accent": 악센트는 구분, 대소문자 무시
// "case": 대소문자 구분, 악센트 무시
// "variant": 모두 구분 (기본값)
```

### numeric 옵션 — 자연수 정렬

```js
const items = ["item10", "item2", "item1", "item20"];

items.sort(new Intl.Collator("en", { numeric: true }).compare);
// ["item1", "item2", "item10", "item20"]  — 자연스러운 숫자 순서
```

---

## 6. Intl.ListFormat

배열을 자연어 리스트 형태로 변환한다.

```js
const items = ["사과", "바나나", "체리"];

new Intl.ListFormat("ko-KR", { style: "long", type: "conjunction" }).format(items);
// "사과, 바나나 및 체리"

new Intl.ListFormat("en-US", { style: "long", type: "conjunction" }).format(["Apple", "Banana", "Cherry"]);
// "Apple, Banana, and Cherry"

new Intl.ListFormat("en-US", { style: "short", type: "disjunction" }).format(["Apple", "Banana", "Cherry"]);
// "Apple, Banana, or Cherry"

new Intl.ListFormat("en-US", { type: "unit" }).format(["5 pounds", "12 ounces"]);
// "5 pounds, 12 ounces"
```

---

## 7. Intl.PluralRules

언어마다 단수/복수 규칙이 다르다. 영어는 1개(one)/그 외(other)지만, 아랍어는 6가지 규칙을 가진다.

```js
const pr = new Intl.PluralRules("en-US");
pr.select(0);  // "other"
pr.select(1);  // "one"
pr.select(2);  // "other"

const prKo = new Intl.PluralRules("ko-KR");
prKo.select(1);  // "other"  — 한국어는 단수/복수 구분 없음
```

### 서수 (ordinal)

```js
const ordinal = new Intl.PluralRules("en-US", { type: "ordinal" });
const suffixes = { one: "st", two: "nd", few: "rd", other: "th" };

function getOrdinal(n) {
  return n + suffixes[ordinal.select(n)];
}

getOrdinal(1);  // "1st"
getOrdinal(2);  // "2nd"
getOrdinal(3);  // "3rd"
getOrdinal(4);  // "4th"
getOrdinal(11); // "11th"
```

---

## 8. Intl.Segmenter

텍스트를 단어/문장/자소(grapheme) 단위로 분리한다. 공백이 없는 언어(중국어, 일본어 등)에서 특히 유용하다.

```js
// 단어 단위 분리
const wordSegmenter = new Intl.Segmenter("en-US", { granularity: "word" });
const segments = [...wordSegmenter.segment("Hello, world! How are you?")];
const words = segments.filter(s => s.isWordLike).map(s => s.segment);
// ["Hello", "world", "How", "are", "you"]

// 문장 단위 분리
const sentenceSegmenter = new Intl.Segmenter("ko-KR", { granularity: "sentence" });
[...sentenceSegmenter.segment("안녕하세요. 반갑습니다!")].map(s => s.segment);
// ["안녕하세요. ", "반갑습니다!"]

// 자소 단위 분리 — 이모지나 복합 문자 처리에 유용
const graphemeSegmenter = new Intl.Segmenter("en", { granularity: "grapheme" });
[...graphemeSegmenter.segment("👨‍👩‍👧‍👦")].length; // 1 (가족 이모지는 1개)
"👨‍👩‍👧‍👦".length; // 11 (string.length는 코드 유닛 기준)
```

---

## 9. Intl.Locale

Locale 정보를 객체로 다룬다.

```js
const locale = new Intl.Locale("ko-KR-u-ca-gregory-nu-latn");

locale.language;   // "ko"
locale.region;     // "KR"
locale.calendar;   // "gregory"
locale.numberingSystem; // "latn"

// 확장 정보 접근
const locale2 = new Intl.Locale("en-US");
locale2.getCalendars();       // ["gregory"]
locale2.getHourCycles();      // ["h12"]
locale2.getNumberingSystems(); // ["latn"]
```

---

## 10. 성능 팁

**Intl 객체는 생성 비용이 크다. 반드시 재사용하라.**

```js
// 나쁜 예 — 매 렌더마다 새로 생성
function formatPrice(price) {
  return new Intl.NumberFormat("ko-KR", {
    style: "currency",
    currency: "KRW",
  }).format(price);
}

// 좋은 예 — 모듈 스코프에서 한 번만 생성
const priceFormatter = new Intl.NumberFormat("ko-KR", {
  style: "currency",
  currency: "KRW",
});

function formatPrice(price) {
  return priceFormatter.format(price);
}
```

React에서 재사용:

```js
// useMemo로 locale 변경 시에만 재생성
function useFormatter(locale) {
  return useMemo(() => ({
    date: new Intl.DateTimeFormat(locale, { dateStyle: "medium" }),
    currency: new Intl.NumberFormat(locale, { style: "currency", currency: "KRW" }),
  }), [locale]);
}
```

---

## 11. dayjs / date-fns와 비교

| 기능 | 네이티브 Intl | dayjs | date-fns |
|------|-------------|-------|---------|
| 날짜 포맷 | O | O | O |
| 날짜 계산 (add/subtract) | X | O | O |
| 파싱 (문자열 → Date) | X | O | O |
| 상대 시간 | Intl.RelativeTimeFormat | dayjs/plugin/relativeTime | formatDistanceToNow |
| 번들 크기 | 0 KB | ~2 KB (core) | tree-shakable |
| 타임존 지원 | timeZone 옵션 | plugin 필요 | date-fns-tz |
| locale 지원 | 브라우저 내장 | locale 파일 import | locale 파일 import |

**결론**: 단순 포맷·정렬·상대 시간만 필요하다면 네이티브 Intl로 충분하다. 날짜 계산(add/subtract/diff)이 필요하다면 dayjs 또는 date-fns를 사용한다.

---

## 12. 브라우저 호환성

| API | Chrome | Firefox | Safari | Node.js |
|-----|--------|---------|--------|---------|
| DateTimeFormat | 24+ | 29+ | 10+ | 0.12+ |
| NumberFormat | 24+ | 29+ | 10+ | 0.12+ |
| RelativeTimeFormat | 71+ | 65+ | 14+ | 12+ |
| Collator | 24+ | 29+ | 10+ | 0.12+ |
| ListFormat | 72+ | 78+ | 14.1+ | 12+ |
| PluralRules | 63+ | 58+ | 13+ | 10+ |
| Segmenter | 87+ | 미지원 | 14.1+ | 16+ |
| Locale | 74+ | 75+ | 14+ | 12+ |

> Firefox의 Segmenter 미지원 주의. polyfill: `@formatjs/intl-segmenter`

---

## 13. 면접 포인트

**Q. Intl API를 매번 new로 생성하면 안 되는 이유는?**

Intl 객체는 내부적으로 locale 데이터 파싱, 규칙 컴파일 등 무거운 초기화 작업을 수행한다. 루프나 렌더 함수 안에서 매번 생성하면 성능 저하가 발생하므로 모듈 스코프 또는 useMemo로 캐싱해야 한다.

**Q. `string.localeCompare()`와 `Intl.Collator`의 차이는?**

`localeCompare`는 내부적으로 Collator를 사용하지만, 반복 비교 시 매번 Collator 인스턴스를 생성하는 비용이 있다. 대량 정렬에는 `Intl.Collator` 인스턴스를 미리 만들어 `.compare` 메서드를 전달하는 것이 훨씬 빠르다.

**Q. 이모지나 한글 자모가 포함된 문자열의 길이를 정확히 구하려면?**

`string.length`는 UTF-16 코드 유닛 기준이므로 이모지(서로게이트 쌍)나 결합 문자를 잘못 계산한다. `Intl.Segmenter`로 grapheme 단위로 분리한 후 개수를 세는 것이 정확하다.

**Q. 상대 시간을 "3일 전" 형식으로 보여주려면 어떻게 하나?**

`Intl.RelativeTimeFormat`을 사용한다. 날짜 차이를 직접 계산해 unit(`"day"`, `"hour"` 등)과 값을 넘겨주면 locale에 맞는 표현을 반환한다. `numeric: "auto"` 옵션을 주면 "어제", "내일"처럼 자연스러운 표현도 반환된다.

**Q. 숫자를 "1234만" 형태로 표기하려면?**

`Intl.NumberFormat`의 `notation: "compact"` 옵션을 사용한다. locale을 `"ko-KR"`로 설정하면 한국식 단위(만, 억)로 자동 변환된다.
