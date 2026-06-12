# 1. 날짜/시간 유틸리티

## 목차

1. [네이티브 Date 객체의 문제점](#1-네이티브-date-객체의-문제점)
2. [dayjs](#2-dayjs)
3. [date-fns](#3-date-fns)
4. [Temporal API](#4-temporal-api)
5. [dayjs vs date-fns 비교](#5-dayjs-vs-date-fns-비교)
6. [타임존 처리](#6-타임존-처리)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 네이티브 Date 객체의 문제점

```js
// 문제 1: Mutable — 원본이 변한다
const date = new Date('2024-01-01');
date.setMonth(5); // 원본 date가 변경됨
console.log(date); // 2024-06-01

// 문제 2: 월이 0-indexed
new Date(2024, 0, 1); // 1월
new Date(2024, 11, 31); // 12월

// 문제 3: 파싱 결과가 브라우저마다 다름
new Date('2024-01-01') // UTC 기준
new Date('01/01/2024') // Local 기준 (브라우저 차이 있음)

// 문제 4: 타임존 처리 불편
// UTC와 로컬 시간 변환, 특정 타임존으로 표시하기 어려움

// 문제 5: 포맷 API 없음
// date.toLocaleDateString() 의 포맷이 환경마다 다름
```

---

## 2. dayjs

경량(~2KB gzip)의 Moment.js 대안. 불변(immutable) API 제공.

### 설치

```bash
npm install dayjs
```

### 기본 사용법

```js
import dayjs from 'dayjs';

// 생성
const now = dayjs();                        // 현재 시각
const d = dayjs('2024-06-12');              // 문자열 파싱
const fromDate = dayjs(new Date());         // Date 객체에서

// 포맷
dayjs().format('YYYY-MM-DD');               // '2024-06-12'
dayjs().format('YYYY년 MM월 DD일 HH:mm');   // '2024년 06월 12일 14:30'

// 파싱
dayjs('2024-06-12', 'YYYY-MM-DD');

// 조작 (불변 — 항상 새 객체 반환)
const tomorrow = dayjs().add(1, 'day');
const lastMonth = dayjs().subtract(1, 'month');
const startOfMonth = dayjs().startOf('month');

// 비교
dayjs('2024-01-01').isBefore(dayjs('2024-06-01')); // true
dayjs('2024-06-01').isAfter(dayjs('2024-01-01'));  // true
dayjs('2024-01-01').isSame('2024-01-01');           // true

// 차이
dayjs('2024-12-31').diff(dayjs('2024-01-01'), 'day'); // 365
```

### 플러그인 시스템

```js
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
import utc from 'dayjs/plugin/utc';
import timezone from 'dayjs/plugin/timezone';
import 'dayjs/locale/ko';

dayjs.extend(relativeTime);
dayjs.extend(utc);
dayjs.extend(timezone);
dayjs.locale('ko');

// relativeTime: 상대 시간 표현
dayjs('2024-01-01').fromNow(); // '5개월 전'
dayjs().add(2, 'hour').toNow(); // '2시간 후'

// 타임존
dayjs().tz('Asia/Seoul').format(); // 서울 시간
```

---

## 3. date-fns

함수형 접근 방식. 개별 함수를 import해서 사용 — Tree-shakable.

### 설치

```bash
npm install date-fns
```

### 기본 사용법

```js
import {
  format, parse, parseISO,
  addDays, subMonths, startOfMonth, endOfWeek,
  isBefore, isAfter, isEqual, differenceInDays,
  formatDistance, formatRelative
} from 'date-fns';
import { ko } from 'date-fns/locale';

// 포맷
format(new Date(), 'yyyy-MM-dd');                  // '2024-06-12'
format(new Date(), 'yyyy년 MM월 dd일', { locale: ko }); // '2024년 06월 12일'

// 파싱
const d = parseISO('2024-06-12');
const d2 = parse('12/06/2024', 'dd/MM/yyyy', new Date());

// 조작 (입력 Date 객체를 직접 수정하지 않음)
const tomorrow = addDays(new Date(), 1);
const lastMonth = subMonths(new Date(), 1);
const start = startOfMonth(new Date());

// 비교
isBefore(new Date('2024-01-01'), new Date('2024-06-01')); // true
differenceInDays(new Date('2024-12-31'), new Date('2024-01-01')); // 365

// 상대 시간
formatDistance(new Date('2024-01-01'), new Date(), { locale: ko, addSuffix: true });
// '6개월 전'
```

### TypeScript 타입 지원

```ts
import { format } from 'date-fns';
// 타입 자동 추론 — Date 또는 number(timestamp) 허용
const result: string = format(new Date(), 'yyyy-MM-dd');
```

---

## 4. Temporal API

JavaScript의 새로운 날짜/시간 표준 (TC39 Stage 3). 불변(immutable), 타임존 내장.

> **주의**: 2024년 기준 브라우저 지원이 아직 완전하지 않아 폴리필 필요.

```js
import { Temporal } from '@js-temporal/polyfill';

// PlainDate — 시간 없는 날짜
const date = Temporal.PlainDate.from('2024-06-12');
const tomorrow = date.add({ days: 1 });  // 불변

// PlainDateTime — 타임존 없는 날짜+시간
const dt = Temporal.PlainDateTime.from('2024-06-12T14:30:00');

// ZonedDateTime — 타임존 포함
const seoul = Temporal.ZonedDateTime.from({
  year: 2024, month: 6, day: 12,
  hour: 14, minute: 30,
  timeZone: 'Asia/Seoul'
});

// Instant — UTC 절대 시간
const now = Temporal.Now.instant();

// 비교
Temporal.PlainDate.compare(date, tomorrow); // -1 (date < tomorrow)

// 차이
const duration = date.until(tomorrow); // Temporal.Duration
duration.days; // 1
```

---

## 5. dayjs vs date-fns 비교

| 항목 | dayjs | date-fns |
|------|-------|----------|
| 번들 크기 (gzip) | ~2KB (코어) | 개별 함수 import 시 더 작음 |
| API 스타일 | 체이닝 (`dayjs().add().format()`) | 함수형 (`format(addDays(d, 1))`) |
| 불변성 | 메서드가 새 인스턴스 반환 | 입력 수정 없음 (Date 객체는 mutable) |
| 타입스크립트 | `@types/dayjs` 포함 | 기본 포함 (v2+) |
| 플러그인 시스템 | 있음 | 없음 (함수 자체가 트리쉐이커블) |
| Tree-shaking | 플러그인 단위 | 함수 단위 (더 세밀) |
| 한국어 로케일 | `dayjs/locale/ko` | `date-fns/locale/ko` |
| 커뮤니티 | 활발 | 활발 |

**선택 기준:**
- 체이닝 스타일이 익숙하거나 Moment.js 마이그레이션 → **dayjs**
- 함수형 프로그래밍, 번들 최적화 중요 → **date-fns**

---

## 6. 타임존 처리

### UTC vs Local

```js
// UTC 기준으로 저장, 표시할 때 변환이 원칙
const utcDate = new Date().toISOString(); // '2024-06-12T05:30:00.000Z'

// dayjs + timezone 플러그인
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import timezone from 'dayjs/plugin/timezone';

dayjs.extend(utc);
dayjs.extend(timezone);

// UTC → 서울 시간
dayjs.utc('2024-06-12T05:30:00Z').tz('Asia/Seoul').format('YYYY-MM-DD HH:mm');
// '2024-06-12 14:30'

// 서울 시간으로 입력 → UTC로 변환
dayjs.tz('2024-06-12 14:30', 'Asia/Seoul').utc().format();
// '2024-06-12T05:30:00Z'
```

### 서버-클라이언트 타임존 전략

```js
// 1. 서버는 항상 UTC ISO 8601로 응답
// API 응답: { "createdAt": "2024-06-12T05:30:00.000Z" }

// 2. 클라이언트에서 사용자 타임존으로 변환
const userTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
// 'Asia/Seoul'

dayjs.utc(apiResponse.createdAt).tz(userTimezone).format('YYYY-MM-DD HH:mm');
```

---

## 7. 면접 포인트

**Q. Moment.js 대신 dayjs를 사용하는 이유는?**
> Moment.js는 번들 크기가 크고(~70KB minified) mutable API를 갖습니다. dayjs는 ~2KB로 경량이고, Moment.js와 호환되는 API를 제공하면서 불변성을 유지합니다. 또한 Moment.js는 현재 유지보수 모드(신규 기능 없음)로 전환되었습니다.

**Q. dayjs와 date-fns의 차이는?**
> dayjs는 체이닝 기반의 OOP 스타일이고, date-fns는 함수형 스타일입니다. date-fns는 함수 단위 tree-shaking이 가능해 번들 최적화에 유리하지만, 함수를 중첩해서 사용하면 가독성이 떨어질 수 있습니다.

**Q. 날짜를 DB/API에서 어떻게 주고받는가?**
> DB와 API 통신 시에는 항상 UTC ISO 8601 형식(`2024-06-12T05:30:00.000Z`)을 사용합니다. 표시 단계에서 사용자의 타임존으로 변환하며, `Intl.DateTimeFormat().resolvedOptions().timeZone`으로 브라우저의 타임존을 감지할 수 있습니다.

**Q. Temporal API가 기존 Date를 대체하는 이유는?**
> Date는 mutable, 월이 0-indexed, 파싱 동작이 환경마다 다르고, 타임존 처리가 어렵습니다. Temporal은 PlainDate/ZonedDateTime 등 목적별 타입을 명확히 분리하고, 불변 API와 타임존 내장 지원을 제공합니다.
