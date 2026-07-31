# 03. moment → dayjs 마이그레이션 (불변성 · 호환성 스펙)

> 실전 배경: 번들 크기와 유지보수를 위해 레거시 `moment`를 `dayjs`로 교체했다.
> "API가 거의 똑같아서 쉽다"는 통념이 함정이었다 — **가변성(mutability) 차이** 하나 때문에
> 조용한 버그가 숨어들 수 있고, 반대로 옛 습관인 `.clone()`은 전부 죽은 코드가 된다.

## 목차
1. [핵심 차이: moment는 가변, dayjs는 불변](#1-핵심-차이-moment는-가변-dayjs는-불변)
2. [그래서 dayjs에서 .clone()은 no-op이다](#2-그래서-dayjs에서-clone은-no-op이다)
3. [포맷 토큰 함정: HH:MM vs HH:mm](#3-포맷-토큰-함정-hhmm-vs-hhmm)
4. [플러그인·로케일은 명시 등록이 계약이다](#4-플러그인로케일은-명시-등록이-계약이다)
5. [마이그레이션을 지키는 호환성 스펙 테스트](#5-마이그레이션을-지키는-호환성-스펙-테스트)
6. [면접 포인트](#6-면접-포인트)

---

## 1. 핵심 차이: moment는 가변, dayjs는 불변

`moment`의 `add`/`set`/`startOf` 등은 **원본 인스턴스를 그 자리에서 변경(mutate)하고 자신을 반환**한다. `dayjs`는 **항상 새 인스턴스를 반환하고 원본은 건드리지 않는다.**

```js
// moment — 원본이 바뀐다
const m = moment('2026-01-01');
m.add(1, 'day');      // m 자체가 2026-01-02로 변함
console.log(m.format('YYYY-MM-DD')); // 2026-01-02

// dayjs — 원본 불변
const d = dayjs('2026-01-01');
d.add(1, 'day');      // 반환값을 안 받으면 아무 효과 없음
console.log(d.format('YYYY-MM-DD')); // 2026-01-01  ← 그대로
const d2 = d.add(1, 'day'); // 새 인스턴스를 받아야 한다
```

**마이그레이션의 진짜 위험**은 여기서 나온다. moment 시절 이렇게 쓰던 코드가 있다면:

```js
// moment: base를 계속 누적 변경해서 쓰던 패턴
const base = moment();
base.add(-15, 'minutes'); // base가 바뀜 (의도적)
// ... base를 여러 곳에서 재사용
```

이걸 API만 `dayjs`로 바꾸면 `base.add(...)`가 아무것도 안 하는 죽은 문장이 되어 **조용히 로직이 틀어진다.** 그래서 모든 변환 지점을 `체이닝` 또는 `let + 재할당` 패턴으로 바꿔야 한다.

```js
// dayjs로 안전하게 옮긴 형태
let now = dayjs();
now = now.add(-15, 'minutes');           // 재할당
// 또는
const start = dayjs().set('hour', 9).set('minute', 0); // 체이닝
```

---

## 2. 그래서 dayjs에서 .clone()은 no-op이다

moment는 가변이라, 원본을 지키려면 `.clone()` 후 조작하는 방어 습관이 있었다.

```js
// moment 시절의 안전 관행
const end = start.clone().add(1, 'month');
```

dayjs는 `add`/`set`/`startOf`/`endOf`가 이미 새 인스턴스를 반환하므로, **`.clone()`은 반환값을 또 복제할 뿐 의미가 없다(no-op에 가깝다).**

```js
// dayjs — clone은 불필요
const end = start.add(1, 'month'); // start는 어차피 안 변함
```

마이그레이션 후 코드베이스에 남은 `.clone()` 호출들은 **동작엔 영향 없지만 옛 사고방식의 잔재**다. 기능 회귀 위험이 없으니 별도 정리 커밋으로 빼는 게 맞다 — 이런 cosmetic 정리를 마이그레이션 본 커밋에 섞으면 리뷰 diff가 오염된다.

---

## 3. 포맷 토큰 함정: HH:MM vs HH:mm

마이그레이션 중 발견된 **선재(pre-existing) 버그.** moment도 dayjs도 포맷 토큰이 같아서 그대로 옮겨졌다.

```js
dayjs().format('HH:MM'); // ❌ 의도: 시:분 / 실제: 시:월(月)
dayjs().format('HH:mm'); // ✅ 시:분
```

| 토큰 | 의미 |
|------|------|
| `MM` | **월** (01–12) |
| `mm` | 분 (00–59) |
| `HH` | 24시간 시 (00–23) |
| `DD` | 일 |
| `dd` | 요일 약어 |

대문자/소문자가 완전히 다른 필드다. 이 값이 문자열 비교(`expectedTime > curTime`)에 쓰이고 있어서, 분 대신 월이 들어가면 비교 결과가 의도와 어긋난다. **마이그레이션은 이런 잠자던 버그를 드러내는 좋은 기회**지만, 본 스코프 밖이면 즉시 고치지 말고 `TODO`/별도 티켓으로 분리하는 판단도 함께 배울 지점이다.

---

## 4. 플러그인·로케일은 명시 등록이 계약이다

dayjs는 코어가 작고, `utc`/`timezone`/`duration`/`customParseFormat`/`isSameOrBefore`/`isBetween`/`relativeTime`/`weekday` 등은 **플러그인으로 분리**되어 있다. 등록하지 않은 기능을 호출하면 런타임에서 조용히 실패하거나 함수가 없다.

```ts
// shared/libs/dayjs.ts — 단일 진입점에서 한 번만 등록
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import timezone from 'dayjs/plugin/timezone';
import customParseFormat from 'dayjs/plugin/customParseFormat';
import 'dayjs/locale/ko';

dayjs.extend(utc);
dayjs.extend(timezone);
dayjs.extend(customParseFormat);
dayjs.locale('ko');

export default dayjs;
```

모든 파일이 `dayjs`를 직접 import하지 않고 **이 진입점에서만** 가져오게 하면, 플러그인 누락으로 인한 "여기선 되는데 저기선 안 되는" 문제를 막는다. UI 라이브러리(ant-design-vue 등)의 date/time picker도 dayjs 기반 빌드로 등록해야 v-model 값 타입이 맞는다.

---

## 5. 마이그레이션을 지키는 호환성 스펙 테스트

"기능적으로 완전히 동일한가"를 보장하는 가장 강력한 장치는 **moment와 dayjs 결과를 나란히 비교하는 호환성 스펙**이다.

```ts
// moment-dayjs-compatibility.spec.ts
it('participatingDateStr: 두 라이브러리 결과가 동일', () => {
  const ts = Date.now();                     // ← 시점을 먼저 캡처 (아래 함정)
  expect(dayjs(ts).format('YYYY-MM-DD'))
    .toBe(moment(ts).format('YYYY-MM-DD'));
});
```

- 잘못 옮겼던 케이스(예: `set('year', 2024).set('month', 5)`의 오변환)를 **명시적 회귀 케이스로 박제**해두면 같은 실수가 재발하지 않는다.
- **자정 경계 flaky 함정**: `dayjs()`와 `moment()`를 각각 호출해 비교하면, 두 호출 사이 ms 차이로 자정을 넘겨 날짜가 달라질 수 있다. 반드시 `const ts = Date.now()`로 **시점을 캡처해 양쪽에 같은 값**을 넘긴다.
- 이 호환성 스펙은 마이그레이션이 끝난 뒤에도 남겨, 이후 날짜 로직 변경의 안전망으로 재사용한다.

> 마이그레이션 검증은 정적 검사(타입·린트) + 호환성 유닛 테스트 수준까지가 자동화 범위다. 실제 datepicker 인터랙션은 E2E/수동으로 별도 검증해야 한다.

---

## 6. 면접 포인트

**Q. moment에서 dayjs로 옮길 때 가장 조심할 점은?**
> 가변성 차이다. moment의 add/set은 원본을 그 자리에서 바꾸지만 dayjs는 새 인스턴스를 반환한다. moment 시절 "원본을 누적 변경"하던 코드를 API만 바꾸면 dayjs에선 반환값을 안 받아 아무 효과가 없어 조용히 로직이 깨진다. 체이닝이나 재할당으로 바꿔야 한다.

**Q. dayjs 코드에서 .clone()을 봤다면?**
> 대부분 moment 시절의 방어 습관이 남은 것이다. dayjs는 불변이라 add/set/startOf가 이미 새 인스턴스를 주므로 clone은 사실상 no-op이다. 동작엔 영향 없으니 별도 정리 커밋으로 제거한다.

**Q. `HH:MM`과 `HH:mm`의 차이는?**
> MM은 월, mm은 분이다. HH:MM은 "시:월"이 되어버린다. moment·dayjs 모두 같은 토큰 규칙이라 잘못된 포맷이 그대로 이식되기 쉽다.

**Q. dayjs에서 utc나 timezone이 동작하지 않는다면?**
> 해당 플러그인을 extend로 등록하지 않았을 가능성이 크다. dayjs는 코어가 작고 기능이 플러그인으로 분리돼 있어, 단일 진입점 모듈에서 필요한 플러그인과 로케일을 한 번 등록하고 모든 파일이 그 모듈만 import하게 하는 게 안전하다.

**Q. "기능적으로 완전히 동일하다"를 어떻게 보장했나요?**
> moment와 dayjs의 출력을 나란히 비교하는 호환성 스펙 테스트를 두고, 잘못 옮겼던 케이스를 회귀 케이스로 박제했다. 시점 캡처(Date.now 공유)로 자정 경계 flaky를 막고, 정적 검사와 함께 CI에 태웠다. picker 인터랙션 같은 UI는 E2E/수동으로 보완한다.
