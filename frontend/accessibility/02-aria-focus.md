# 2. ARIA · 스크린리더 · 포커스 관리

## 목차
1. [ARIA란 무엇이고 언제 쓰는가](#1-aria란-무엇이고-언제-쓰는가)
2. [ARIA의 5가지 규칙](#2-aria의-5가지-규칙)
3. [role · property · state](#3-role--property--state)
4. [Live Region — 동적 콘텐츠 알림](#4-live-region--동적-콘텐츠-알림)
5. [포커스 관리 (모달·라우팅)](#5-포커스-관리-모달라우팅)
6. [실전: 접근 가능한 모달 다이얼로그](#6-실전-접근-가능한-모달-다이얼로그)
7. [실전: 탭·드롭다운 키보드 패턴](#7-실전-탭드롭다운-키보드-패턴)
8. [면접 포인트](#8-면접-포인트)

---

## 1. ARIA란 무엇이고 언제 쓰는가

**ARIA**(Accessible Rich Internet Applications)는 HTML만으로 표현 안 되는 *역할·상태·속성*을 보조기술에 전달하는 속성 집합이다. 주로 커스텀 위젯(탭, 콤보박스, 트리, 모달)처럼 네이티브 요소가 없는 UI에 쓴다.

**핵심 전제: ARIA는 시맨틱 HTML의 보완재이지 대체재가 아니다.** ARIA는 *접근성 트리의 표현만* 바꿀 뿐, **동작(키보드, 포커스)은 전혀 추가하지 않는다.** `role="button"`을 붙여도 Enter/Space로 눌리지 않으며, 그 동작은 직접 JS로 구현해야 한다.

```html
<!-- 네이티브 button 하나면 끝나는 걸 ARIA로 재현하면 손해 -->
<div role="button" tabindex="0"
     onkeydown="if(event.key==='Enter'||event.key===' ')activate()"
     onclick="activate()">확인</div>

<!-- 그냥 이렇게 -->
<button onclick="activate()">확인</button>
```

---

## 2. ARIA의 5가지 규칙

W3C가 정리한 **ARIA 사용 5원칙**:

1. **네이티브 HTML로 가능하면 ARIA를 쓰지 마라.** (`<nav>` > `role="navigation"`)
2. **네이티브 시맨틱을 바꾸지 마라.** (`<h2 role="button">` ❌ — 제목이 사라짐)
3. **모든 인터랙티브 ARIA 위젯은 키보드로 조작 가능해야 한다.**
4. **포커스 가능한 요소를 `role="presentation"`/`aria-hidden="true"`로 숨기지 마라.** (포커스는 되는데 스크린리더엔 안 보이는 유령 요소 발생)
5. **모든 인터랙티브 요소엔 접근 가능한 이름이 있어야 한다.**

> 1번을 기억하면 ARIA의 절반은 안 쓰게 된다. **"No ARIA is better than bad ARIA."** — 잘못 쓴 ARIA는 안 쓴 것보다 나쁘다.

---

## 3. role · property · state

ARIA 속성은 세 부류로 나뉜다.

| 종류 | 설명 | 예 |
|------|------|-----|
| **role** | 요소가 무엇인지 | `role="tablist"`, `role="dialog"`, `role="alert"` |
| **property** | 잘 변하지 않는 특성 | `aria-label`, `aria-labelledby`, `aria-describedby`, `aria-haspopup` |
| **state** | 동적으로 변하는 상태 | `aria-expanded`, `aria-checked`, `aria-selected`, `aria-disabled`, `aria-hidden` |

```html
<!-- 아코디언 토글: 상태를 aria-expanded로 동기화 -->
<button aria-expanded="false" aria-controls="panel1">상세 보기</button>
<div id="panel1" hidden>…</div>
```

```js
btn.addEventListener('click', () => {
  const open = btn.getAttribute('aria-expanded') === 'true';
  btn.setAttribute('aria-expanded', String(!open)); // 상태를 반드시 갱신
  panel.hidden = open;
});
```

> 상태 속성은 **시각 상태와 항상 동기화**해야 한다. 패널을 열면서 `aria-expanded`를 안 바꾸면 스크린리더 사용자는 여전히 "접힘"으로 듣는다.

### `aria-hidden`의 함정

```html
<!-- 장식 아이콘은 스크린리더에서 숨김 -->
<button>저장 <svg aria-hidden="true">…</svg></button>

<!-- ❌ 포커스 가능한 요소를 숨기면 안 됨: 탭은 되는데 안 읽힘 -->
<a href="/x" aria-hidden="true">링크</a>
```

---

## 4. Live Region — 동적 콘텐츠 알림

페이지 일부가 비동기로 바뀔 때(검색 결과, 토스트, 폼 에러), 포커스를 옮기지 않고도 스크린리더가 변경을 읽게 하는 영역.

```html
<!-- polite: 사용자가 하던 말이 끝난 뒤 읽음 (일반 알림) -->
<div aria-live="polite" id="status"></div>

<!-- assertive: 즉시 끊고 읽음 (긴급 에러). 남용 금지 -->
<div aria-live="assertive" role="alert" id="error"></div>
```

```js
// 영역은 미리 DOM에 존재해야 하고, 텍스트만 나중에 주입한다
document.getElementById('status').textContent = '검색 결과 12건';
```

| 속성/role | 동작 |
|-----------|------|
| `aria-live="polite"` | 끼어들지 않고 차례에 읽음 |
| `aria-live="assertive"` / `role="alert"` | 즉시 읽음 |
| `role="status"` | polite + role 의미 부여 (로딩·저장 완료 등) |
| `aria-atomic="true"` | 바뀐 부분만이 아니라 영역 전체를 다시 읽음 |

> 흔한 실수: 알림이 생길 때 `aria-live` 컨테이너를 **새로 만들면** 보조기술이 변화를 감지 못 한다. 컨테이너는 항상 존재시키고 내용만 바꾼다.

---

## 5. 포커스 관리 (모달·라우팅)

키보드/스크린리더 사용자 경험의 핵심은 **포커스가 지금 어디 있는가**다.

### SPA 라우팅 시 포커스 이동

전통 페이지 이동은 새 페이지 최상단으로 포커스가 가지만, SPA는 DOM만 바뀌어 포커스가 사라진 버튼에 남는다. 라우팅 후 새 페이지의 `<h1>`이나 메인 영역으로 포커스를 옮겨준다.

```js
function onRouteChange() {
  const heading = document.querySelector('main h1');
  heading.setAttribute('tabindex', '-1');
  heading.focus();      // 스크린리더가 새 페이지 제목을 읽음
}
```

### 포커스 트랩(focus trap)

모달이 열리면 포커스가 모달 *밖으로* 새어 나가면 안 된다. `Tab`이 마지막 요소에서 첫 요소로 순환하도록 가둔다. (`<dialog>` 요소는 이걸 기본 제공한다.)

---

## 6. 실전: 접근 가능한 모달 다이얼로그

네이티브 `<dialog>`는 포커스 트랩·`Esc` 닫기·백드롭·inert(배경 비활성)를 모두 기본 제공한다. 가능하면 직접 구현 대신 이걸 쓴다.

```html
<dialog id="confirm" aria-labelledby="dlg-title">
  <h2 id="dlg-title">삭제 확인</h2>
  <p>정말 삭제하시겠습니까?</p>
  <button id="ok">삭제</button>
  <button id="cancel">취소</button>
</dialog>
```

```js
const dlg = document.getElementById('confirm');
let opener;

function open() {
  opener = document.activeElement; // 1) 연 요소 기억
  dlg.showModal();                 // 2) 포커스 트랩 + 배경 inert 자동
}                                  //    (showModal은 첫 포커스도 자동 이동)

dlg.addEventListener('close', () => {
  opener?.focus();                 // 3) 닫으면 원래 위치로 포커스 복원
});
```

**접근 가능한 모달의 4대 체크리스트:**
1. 열 때 포커스가 모달 안으로 이동
2. `Tab`이 모달 내부에서 순환 (포커스 트랩)
3. `Esc`로 닫힘
4. 닫을 때 포커스가 **연 요소로 복원**

직접 구현한다면 모달에 `role="dialog"` + `aria-modal="true"` + `aria-labelledby`를 붙이고 배경에 `inert`를 적용한다.

---

## 7. 실전: 탭·드롭다운 키보드 패턴

WAI-ARIA Authoring Practices(APG)는 위젯별 표준 키보드 동작을 정의한다. 탭(Tabs) 예:

```html
<div role="tablist" aria-label="설정">
  <button role="tab" id="t1" aria-selected="true"  aria-controls="p1">계정</button>
  <button role="tab" id="t2" aria-selected="false" aria-controls="p2" tabindex="-1">알림</button>
</div>
<div role="tabpanel" id="p1" aria-labelledby="t1">…</div>
<div role="tabpanel" id="p2" aria-labelledby="t2" hidden>…</div>
```

탭 위젯 키보드 규약:
- `Tab` 키는 탭 목록 전체를 **하나의 정류장**으로 취급 → 선택된 탭만 `tabindex="0"`, 나머지는 `-1` (로빙 tabindex).
- 탭 사이 이동은 **방향키**(←/→)로.
- 방향키로 이동 시 `aria-selected`와 `tabindex`를 갱신하고 패널을 토글.

> 이 "roving tabindex" 패턴은 라디오 그룹·메뉴·트리에도 동일하게 적용된다. 그룹 전체에 Tab을 한 번만 멈추게 하고 내부는 방향키로 도는 것이 표준이다.

---

## 8. 면접 포인트

**Q. ARIA를 쓰면 키보드 동작도 같이 생기나요?**
> 아니다. ARIA는 *접근성 트리의 표현(역할·상태·이름)*만 바꾼다. `role="button"`을 붙여도 Enter/Space로 눌리지 않으며, 포커스(`tabindex`)와 키 핸들러를 직접 구현해야 한다. 그래서 네이티브 요소가 거의 항상 낫다.

**Q. "No ARIA is better than bad ARIA"의 의미는?**
> 잘못된 ARIA(상태 미동기화, 포커스 가능한 요소를 `aria-hidden` 처리 등)는 보조기술 사용자에게 틀린 정보를 줘서 아예 안 쓴 것보다 나쁘다. 1순위는 항상 네이티브 시맨틱 HTML이다.

**Q. `aria-live`의 polite와 assertive 차이는?**
> polite는 사용자가 하던 읽기가 끝난 뒤 알림을 읽고, assertive(=`role="alert"`)는 즉시 끊고 읽는다. 일반 상태 변화는 polite, 긴급 에러만 assertive. 또한 live region 컨테이너는 미리 DOM에 존재해야 하고 내용만 바꿔야 감지된다.

**Q. 모달을 접근성 있게 만들려면?**
> ① 열 때 포커스를 모달 안으로 이동, ② Tab을 모달 내부에 가두는 포커스 트랩, ③ Esc로 닫기, ④ 닫을 때 연 요소로 포커스 복원. 네이티브 `<dialog>`의 `showModal()`은 ①②③과 배경 inert를 기본 제공한다.

**Q. SPA에서 라우팅 후 접근성상 무엇을 해줘야 하나요?**
> DOM만 바뀌고 포커스는 사라진 요소에 남아 스크린리더가 새 화면을 인지 못 한다. 라우팅 후 새 페이지의 `<h1>`(또는 main)에 `tabindex="-1"` + `focus()`로 포커스를 옮겨 제목을 읽게 한다.

**Q. roving tabindex가 무엇인가요?**
> 탭·라디오·메뉴처럼 묶인 위젯에서 그룹 전체가 Tab 정류장 하나가 되도록, 활성 항목만 `tabindex="0"`·나머지는 `-1`로 두고 내부 이동은 방향키로 처리하는 패턴. WAI-ARIA APG의 표준 키보드 모델이다.
