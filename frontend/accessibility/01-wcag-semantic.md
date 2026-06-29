# 1. WCAG · 시맨틱 HTML · 키보드 네비게이션

## 목차
1. [WCAG와 4대 원칙 (POUR)](#1-wcag와-4대-원칙-pour)
2. [적합성 수준 (A / AA / AAA)](#2-적합성-수준-a--aa--aaa)
3. [시맨틱 HTML이 접근성의 90%다](#3-시맨틱-html이-접근성의-90다)
4. [접근성 트리와 이름 계산](#4-접근성-트리와-이름-계산)
5. [키보드 네비게이션](#5-키보드-네비게이션)
6. [색 대비와 시각 요구사항](#6-색-대비와-시각-요구사항)
7. [이미지·폼·대체 텍스트](#7-이미지폼대체-텍스트)
8. [면접 포인트](#8-면접-포인트)

---

## 1. WCAG와 4대 원칙 (POUR)

**WCAG**(Web Content Accessibility Guidelines)는 W3C가 만든 웹 접근성 국제 표준이다. 현재 안정 버전은 **2.2**(2023). 모든 지침은 4대 원칙 **POUR**로 묶인다.

| 원칙 | 의미 | 대표 요구사항 |
|------|------|--------------|
| **P**erceivable (인지 가능) | 콘텐츠를 감각으로 인지할 수 있어야 | 대체 텍스트, 자막, 색 대비 |
| **O**perable (운용 가능) | 모든 입력 수단으로 조작 가능해야 | 키보드 접근, 충분한 시간, 발작 유발 금지 |
| **U**nderstandable (이해 가능) | 콘텐츠와 UI가 이해 가능해야 | 명확한 라벨, 일관된 네비게이션, 에러 안내 |
| **R**obust (견고함) | 보조기술이 안정적으로 해석 가능해야 | 유효한 마크업, 올바른 ARIA |

> 암기 팁: **POUR** = "콘텐츠를 사용자에게 **부어준다**". 인지 → 조작 → 이해 → (기술적으로) 견고하게.

---

## 2. 적합성 수준 (A / AA / AAA)

각 성공 기준(Success Criterion)은 세 단계 중 하나에 속한다.

- **A** — 최소한. 미준수 시 일부 사용자가 아예 사용 불가.
- **AA** — 실무·법적 기준선. 대부분의 정부/기업이 목표로 함 (예: 색 대비 4.5:1).
- **AAA** — 최고 수준. 전체 사이트에 일괄 적용은 비현실적이라 권장되지 않음 (예: 색 대비 7:1).

> **실무 타깃은 AA.** 한국의 「장애인차별금지법」, 미국 ADA/Section 508, 유럽 EN 301 549 모두 사실상 WCAG AA를 기준으로 삼는다.

---

## 3. 시맨틱 HTML이 접근성의 90%다

가장 중요한 원칙: **올바른 HTML 요소를 쓰면 접근성은 대부분 공짜로 따라온다.** 보조기술은 요소의 *역할(role)*·*상태(state)*·*이름(name)*을 마크업에서 자동으로 읽는다.

```html
<!-- ❌ div 남용: 역할도, 키보드 포커스도, 엔터 동작도 없음 -->
<div class="btn" onclick="submit()">전송</div>

<!-- ✅ button: role=button, Tab 포커스, Enter/Space 활성화, 비활성화 지원 모두 기본 제공 -->
<button type="button" onclick="submit()">전송</button>
```

### 랜드마크로 페이지 구조 표현

스크린리더 사용자는 랜드마크 단위로 페이지를 빠르게 건너뛴다.

```html
<header>      <!-- role=banner -->
  <nav aria-label="주요 메뉴">…</nav>   <!-- role=navigation -->
</header>
<main>        <!-- role=main : 페이지당 하나 -->
  <article>…</article>
  <aside>…</aside>   <!-- role=complementary -->
</main>
<footer>      <!-- role=contentinfo -->
```

### 제목(heading) 계층은 건너뛰지 않는다

```html
<!-- ❌ h1 → h3 점프: 스크린리더 목차가 깨짐 -->
<h1>제목</h1>
<h3>소제목</h3>

<!-- ✅ 순차적으로 -->
<h1>제목</h1>
<h2>소제목</h2>
```

`<h1>`은 페이지당 한 개, 시각적 크기는 CSS로 조정한다(레벨을 디자인 때문에 바꾸지 말 것).

---

## 4. 접근성 트리와 이름 계산

브라우저는 DOM과 별개로 **접근성 트리(Accessibility Tree)**를 만든다. 각 노드는 보조기술에 `역할 + 이름 + 상태/속성` 형태로 노출된다.

```
button  "장바구니에 담기"  [enabled]
checkbox "마케팅 수신 동의"  [checked]
```

요소의 **접근 가능한 이름(accessible name)**은 우선순위에 따라 계산된다(상위가 하위를 덮어씀):

1. `aria-labelledby` (다른 요소의 텍스트 참조)
2. `aria-label` (직접 지정한 문자열)
3. 요소 내부 콘텐츠 / `<label>` 연결 / `alt` / `title`

```html
<!-- 내부 텍스트가 이름이 됨 → "저장" -->
<button>저장</button>

<!-- 아이콘만 있는 버튼: 보이는 텍스트가 없으므로 aria-label 필수 -->
<button aria-label="닫기"><svg>…</svg></button>
```

> 디버깅: 크롬 DevTools → Elements → **Accessibility** 패널에서 계산된 이름·역할을 직접 확인할 수 있다.

---

## 5. 키보드 네비게이션

마우스를 못 쓰는 사용자(지체장애, 스크린리더, 파워유저)는 **키보드만으로 모든 기능에 접근**할 수 있어야 한다 (WCAG 2.1.1).

### 기본 키 동작

| 키 | 동작 |
|----|------|
| `Tab` / `Shift+Tab` | 다음/이전 포커스 가능 요소로 이동 |
| `Enter` | 링크·버튼 활성화 |
| `Space` | 버튼·체크박스 토글 |
| `Esc` | 모달·메뉴 닫기 |
| 방향키 | 라디오 그룹·탭·메뉴 내부 이동 |

### tabindex 사용 규칙

```html
<!-- 0: 자연스러운 DOM 순서로 포커스 가능하게 (커스텀 위젯에) -->
<div role="button" tabindex="0">커스텀 버튼</div>

<!-- -1: 프로그래밍으로만 포커스 (focus() 호출용). 모달 열 때 제목으로 포커스 이동 등 -->
<h2 tabindex="-1">대화상자 제목</h2>

<!-- ❌ 양수 tabindex: 탭 순서를 강제로 뒤섞어 예측 불가 → 절대 금지 -->
<input tabindex="3">
```

### 포커스 표시(focus indicator)를 지우지 말 것

```css
/* ❌ 키보드 사용자가 현재 위치를 알 수 없게 됨 (WCAG 2.4.7 위반) */
:focus { outline: none; }

/* ✅ 마우스 클릭엔 숨기고 키보드 탐색 시에만 표시 */
:focus-visible {
  outline: 2px solid #1a73e8;
  outline-offset: 2px;
}
```

### 스킵 링크 (Skip to content)

반복되는 네비게이션을 건너뛰고 본문으로 바로 가는 링크. 평소엔 숨겼다가 포커스 시 나타난다.

```html
<a href="#main" class="skip-link">본문 바로가기</a>
…
<main id="main" tabindex="-1">…</main>
```

```css
.skip-link {
  position: absolute;
  left: -9999px;       /* display:none 은 포커스 불가라 화면 밖으로 이동 */
}
.skip-link:focus {
  left: 1rem;
  top: 1rem;
}
```

---

## 6. 색 대비와 시각 요구사항

- **본문 텍스트**: 배경 대비 **4.5:1** 이상 (AA). 큰 텍스트(18.66px 굵게 또는 24px)는 **3:1**.
- **UI 컴포넌트·그래픽**: 인접 색과 **3:1** (WCAG 1.4.11).
- **색만으로 정보 전달 금지** (1.4.1): "빨간 글씨 = 오류"는 색맹 사용자에게 무의미 → 아이콘·텍스트를 함께.

```html
<!-- ❌ 색만으로 구분 -->
<span style="color:red">필수 항목</span>

<!-- ✅ 색 + 기호/텍스트 -->
<span style="color:#c00">⚠ 필수 항목</span>
```

- 확대 200%에서도 콘텐츠 손실 없어야 함 (1.4.4) → 고정 px 폰트보다 `rem`.
- 움직임/애니메이션은 `prefers-reduced-motion`을 존중한다(전정기관 장애).

```css
@media (prefers-reduced-motion: reduce) {
  * { animation: none !important; transition: none !important; }
}
```

---

## 7. 이미지·폼·대체 텍스트

### 이미지 alt

```html
<!-- 정보 전달 이미지: 내용을 서술 -->
<img src="chart.png" alt="2024년 매출 전년 대비 20% 증가">

<!-- 장식용 이미지: 빈 alt로 스크린리더가 건너뛰게 (alt 자체를 빼면 파일명을 읽음) -->
<img src="divider.png" alt="">
```

### 폼은 label과 input을 연결

```html
<!-- ✅ for/id 연결: 라벨 클릭 시 입력 포커스 + 스크린리더가 이름 인식 -->
<label for="email">이메일</label>
<input id="email" type="email" autocomplete="email" required>

<!-- placeholder는 label을 대체하지 못한다 (입력 시 사라지고 대비도 낮음) -->
```

### 에러 메시지 연결

```html
<input id="pw" type="password" aria-describedby="pw-err" aria-invalid="true">
<p id="pw-err" role="alert">비밀번호는 8자 이상이어야 합니다.</p>
```

`aria-describedby`로 입력과 설명을 묶고, `role="alert"`로 동적으로 나타난 에러를 스크린리더가 즉시 읽게 한다.

---

## 8. 면접 포인트

**Q. `<div onclick>` 대신 `<button>`을 써야 하는 이유는?**
> `<button>`은 `role=button`, `Tab` 포커스 가능, `Enter`/`Space` 활성화, `disabled` 지원을 기본 제공한다. `div`로 같은 동작을 내려면 `tabindex`, `role`, 키 이벤트 핸들러를 일일이 추가해야 하고 빠뜨리기 쉽다. 시맨틱 요소를 쓰면 접근성이 공짜로 따라온다.

**Q. WCAG의 4대 원칙(POUR)은?**
> Perceivable(인지)·Operable(운용)·Understandable(이해)·Robust(견고). 실무 목표 수준은 법적 기준선인 **AA**다.

**Q. 접근 가능한 이름(accessible name)은 어떻게 결정되나요?**
> 우선순위: `aria-labelledby` > `aria-label` > 내부 텍스트/`<label>`/`alt`/`title`. 아이콘만 있는 버튼처럼 보이는 텍스트가 없으면 `aria-label`이 필수다.

**Q. `:focus { outline: none }`이 왜 문제인가요?**
> 키보드 사용자가 현재 포커스 위치를 알 수 없게 되어 WCAG 2.4.7(Focus Visible) 위반이다. 굳이 디자인을 바꾸려면 `:focus-visible`로 키보드 탐색 시에만 커스텀 아웃라인을 보여주면 된다.

**Q. `tabindex` 양수 값을 쓰면 안 되는 이유는?**
> 탭 순서를 DOM 순서와 무관하게 강제로 재배치해 예측 불가능해지고 유지보수가 어렵다. 포커스 순서는 DOM 순서로 맞추고, 필요한 곳에만 `tabindex="0"`(포커스 추가)·`"-1"`(프로그래밍 포커스)을 쓴다.

**Q. 색 대비 AA 기준과 "색만으로 전달 금지" 원칙은?**
> 본문 텍스트 4.5:1, 큰 텍스트·UI 요소 3:1. 그리고 색은 보조 수단일 뿐이라 오류·상태를 색만으로 표시하면 색맹 사용자가 인지하지 못하므로 아이콘·텍스트를 병행해야 한다.
