# 9. Web Components

## 목차
1. 개요
2. Custom Elements
3. Shadow DOM
4. HTML Templates
5. 프레임워크와 함께 사용하기
6. 면접 포인트

---

## 1. 개요

Web Components는 재사용 가능한 캡슐화된 HTML 엘리먼트를 만드는 세 가지 표준 기술의 집합이다.

| 기술 | 역할 |
|------|------|
| Custom Elements | 새로운 HTML 태그 정의 |
| Shadow DOM | 캡슐화된 DOM/스타일 트리 |
| HTML Templates | 재사용 가능한 HTML 마크업 |

---

## 2. Custom Elements

### Autonomous Custom Element (완전 새 태그)

```js
class UserAvatar extends HTMLElement {
  // 관찰할 속성 목록 (변경 시 attributeChangedCallback 호출)
  static observedAttributes = ['name', 'size', 'src'];

  // #로 private 필드
  #root;

  constructor() {
    super(); // 반드시 먼저 호출
    this.#root = this.attachShadow({ mode: 'open' });
  }

  // DOM에 연결될 때
  connectedCallback() {
    this.render();
    console.log('connected:', this.isConnected);
  }

  // DOM에서 제거될 때
  disconnectedCallback() {
    this.#cleanup();
  }

  // 다른 document로 이동될 때
  adoptedCallback() {
    console.log('다른 document로 이동됨');
  }

  // 관찰 속성 변경 시
  attributeChangedCallback(name, oldValue, newValue) {
    if (oldValue === newValue) return;
    this.render();
  }

  render() {
    const name = this.getAttribute('name') ?? 'Unknown';
    const size = this.getAttribute('size') ?? '40';
    const src = this.getAttribute('src');

    this.#root.innerHTML = `
      <style>
        .avatar {
          width: ${size}px;
          height: ${size}px;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          background: #6366f1;
          color: white;
          font-weight: bold;
          font-size: ${size * 0.4}px;
          overflow: hidden;
        }
        img { width: 100%; height: 100%; object-fit: cover; }
      </style>
      <div class="avatar">
        ${src ? `<img src="${src}" alt="${name}" />` : name.charAt(0).toUpperCase()}
      </div>
    `;
  }

  #cleanup() {
    // 이벤트 리스너, 타이머 등 정리
  }
}

customElements.define('user-avatar', UserAvatar);
```

```html
<user-avatar name="홍길동" size="60" src="/profile.jpg"></user-avatar>
```

### Customized Built-in Element (기존 태그 확장)

```js
class FancyButton extends HTMLButtonElement {
  connectedCallback() {
    this.classList.add('fancy');
    this.addEventListener('click', this.#ripple.bind(this));
  }

  #ripple(e) {
    const ripple = document.createElement('span');
    ripple.className = 'ripple';
    this.appendChild(ripple);
    setTimeout(() => ripple.remove(), 600);
  }
}

customElements.define('fancy-button', FancyButton, { extends: 'button' });
```

```html
<button is="fancy-button">클릭</button>
```

### whenDefined — 등록 시점 대기

```js
// 커스텀 엘리먼트가 등록될 때까지 대기
await customElements.whenDefined('user-avatar');
const el = document.querySelector('user-avatar');
el.render();
```

---

## 3. Shadow DOM

Shadow DOM은 컴포넌트의 DOM과 CSS를 외부로부터 캡슐화한다.

```js
const shadow = element.attachShadow({
  mode: 'open',   // element.shadowRoot로 외부 접근 가능
  // mode: 'closed' // element.shadowRoot === null (완전 차단)
  delegatesFocus: true, // 내부 포커스 자동 위임
});
```

### 스타일 캡슐화

```js
// Shadow DOM 내부 스타일은 외부에 영향 없고, 외부 스타일도 내부에 영향 없음
shadow.innerHTML = `
  <style>
    /* 이 스타일은 Shadow DOM 내부에만 적용 */
    :host {                     /* 호스트 엘리먼트 자체 */
      display: block;
      font-family: sans-serif;
    }
    :host([disabled]) {         /* 속성 기반 호스트 스타일링 */
      opacity: 0.5;
      pointer-events: none;
    }
    :host-context(.dark-theme) { /* 조상에 클래스 있을 때 */
      color: white;
    }

    /* CSS 변수는 Shadow DOM 경계를 통과 */
    .button {
      background: var(--btn-color, #6366f1);
      color: var(--btn-text-color, white);
    }

    /* 슬롯 콘텐츠 스타일링 */
    ::slotted(span) { font-weight: bold; }
    ::slotted(*) { margin: 0; }
  </style>
  <button class="button">
    <slot></slot>
  </button>
`;
```

### Slot (외부 콘텐츠 삽입)

```js
// 컴포넌트 정의
class InfoCard extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' }).innerHTML = `
      <style>
        .card { border: 1px solid #ccc; padding: 16px; border-radius: 8px; }
        header { font-size: 1.2em; font-weight: bold; margin-bottom: 8px; }
      </style>
      <div class="card">
        <header><slot name="title">제목 없음</slot></header>
        <div class="content"><slot></slot></div>
        <footer><slot name="actions"></slot></footer>
      </div>
    `;
  }
}
customElements.define('info-card', InfoCard);
```

```html
<info-card>
  <span slot="title">알림</span>
  <p>본문 내용이 여기 들어갑니다.</p>
  <button slot="actions">확인</button>
</info-card>
```

---

## 4. HTML Templates

`<template>` 태그의 내용은 파싱되지만 렌더링되지 않는다. JS로 복제해서 사용한다.

```html
<template id="card-template">
  <article class="card">
    <img class="card-img" alt="" />
    <h2 class="card-title"></h2>
    <p class="card-desc"></p>
    <a class="card-link" href="#">자세히 보기</a>
  </article>
</template>
```

```js
const template = document.getElementById('card-template');

function createCard({ title, description, image, href }) {
  // content: DocumentFragment
  const fragment = template.content.cloneNode(true);

  fragment.querySelector('.card-title').textContent = title;
  fragment.querySelector('.card-desc').textContent = description;
  fragment.querySelector('.card-img').src = image;
  fragment.querySelector('.card-link').href = href;

  return fragment;
}

const container = document.querySelector('#cards');
data.forEach(item => container.appendChild(createCard(item)));
```

---

## 5. 프레임워크와 함께 사용하기

### React에서 Web Components 사용

```jsx
// React 19+는 Custom Elements를 props로 자동 처리
// React 18 이하는 ref를 통해 속성/이벤트를 직접 설정

function App() {
  const ref = useRef(null);

  useEffect(() => {
    const el = ref.current;
    el.addEventListener('custom-event', handleEvent);
    return () => el.removeEventListener('custom-event', handleEvent);
  }, []);

  return <user-avatar ref={ref} name="홍길동" size="60" />;
}
```

### Web Components에서 프레임워크 사용 (Lit)

```js
import { LitElement, html, css } from 'lit';

class MyCounter extends LitElement {
  static styles = css`
    button { padding: 8px 16px; }
    span { font-size: 1.5em; margin: 0 12px; }
  `;

  static properties = {
    count: { type: Number },
  };

  count = 0;

  render() {
    return html`
      <button @click=${() => this.count--}>-</button>
      <span>${this.count}</span>
      <button @click=${() => this.count++}>+</button>
    `;
  }
}

customElements.define('my-counter', MyCounter);
```

---

## 6. 면접 포인트

**Q. Shadow DOM의 `mode: 'open'` vs `'closed'`의 차이는?**

`open`이면 `element.shadowRoot`로 외부 JS에서 Shadow DOM에 접근 가능하다. `closed`면 `null`을 반환해 접근이 차단된다. 단, `attachShadow`를 호출하는 시점의 참조를 저장하면 `closed`여도 내부에서 접근 가능하다. 완전한 보안 수단은 아니며, 주로 접근을 discourage하는 용도다.

**Q. Web Components의 스타일 캡슐화 한계는?**

CSS 커스텀 속성(변수)은 Shadow DOM 경계를 통과한다. `::part()` 의사 요소로 외부에서 특정 내부 요소를 스타일링할 수 있다(컴포넌트가 `part` 속성 노출 시). 전역 스타일(`body { font-family }` 등 상속 속성)은 Shadow DOM 내부에도 상속된다.

**Q. `disconnectedCallback`에서 반드시 정리해야 할 것은?**

이벤트 리스너(document/window에 등록한 것), `setInterval`/`setTimeout`, ResizeObserver/IntersectionObserver, AbortController. Shadow DOM 내부의 이벤트 리스너는 DOM과 함께 GC되므로 별도 정리 불필요.

**Q. Web Components와 React 컴포넌트의 차이는?**

Web Components는 브라우저 네이티브 표준으로 프레임워크 없이 사용 가능하고 어떤 프레임워크와도 호환된다. React 컴포넌트는 React 생태계에 종속된다. Web Components는 스타일 캡슐화가 강하지만 상태 관리나 선언적 렌더링이 번거롭다. 디자인 시스템이나 마이크로 프론트엔드에서 Web Components가 유리하다.
