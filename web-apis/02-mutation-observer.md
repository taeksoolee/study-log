# 2. MutationObserver

## 목차
1. 개요
2. 옵션 (childList, attributes, subtree 등)
3. 서드파티 DOM 변경 감지
4. 무한 루프 방지
5. 면접 포인트

---

## 1. 개요

`MutationObserver`는 DOM 트리의 변경(자식 노드 추가/삭제, 속성 변경, 텍스트 변경)을 비동기로 감지하는 API다.
구버전 API인 `MutationEvent`(동기, deprecated)의 대체재다.

```js
const observer = new MutationObserver(callback);
observer.observe(targetNode, config);

const records = observer.takeRecords(); // 대기 중인 레코드 즉시 반환 + 비움
observer.disconnect();
```

콜백은 `MutationRecord` 배열을 받는다.

```js
const callback = (mutationsList, observer) => {
  for (const mutation of mutationsList) {
    console.log(mutation.type);           // 'childList' | 'attributes' | 'characterData'
    console.log(mutation.target);         // 변경된 노드
    console.log(mutation.addedNodes);     // 추가된 노드 목록 (NodeList)
    console.log(mutation.removedNodes);   // 제거된 노드 목록 (NodeList)
    console.log(mutation.attributeName);  // 변경된 속성명 (attributes 타입일 때)
    console.log(mutation.oldValue);       // 변경 전 값 (옵션 설정 시)
  }
};
```

---

## 2. 옵션 (childList, attributes, subtree 등)

```js
const config = {
  // 자식 노드 추가/삭제 감지
  childList: true,

  // 속성 변경 감지
  attributes: true,

  // 텍스트 노드 내용 변경 감지
  characterData: true,

  // 자손 노드 전체로 감지 범위 확장 (기본: 직접 자식만)
  subtree: true,

  // 변경 전 속성값 기록 (attributes: true 필요)
  attributeOldValue: true,

  // 변경 전 텍스트값 기록 (characterData: true 필요)
  characterDataOldValue: true,

  // 특정 속성만 감지 (null이면 모든 속성)
  attributeFilter: ['class', 'data-state', 'aria-expanded'],
};
```

### 옵션 조합 예시

| 목적 | 옵션 |
|------|------|
| 자식 노드 추가/삭제만 | `{ childList: true }` |
| 전체 서브트리 변경 | `{ childList: true, subtree: true }` |
| class 속성 변경 감지 | `{ attributes: true, attributeFilter: ['class'] }` |
| 입력 텍스트 변경 감지 | `{ characterData: true, subtree: true }` |

---

## 3. 서드파티 DOM 변경 감지

서드파티 라이브러리(광고, 채팅 위젯 등)가 DOM을 변경할 때 후처리 로직이 필요한 경우.

```js
// 서드파티가 추가하는 요소에 자동으로 스타일 적용
const applyCustomStyle = (node) => {
  if (node.nodeType !== Node.ELEMENT_NODE) return;
  if (node.matches('.third-party-widget')) {
    node.style.zIndex = '100';
    node.style.maxWidth = '360px';
  }
  // 하위 노드도 검사
  node.querySelectorAll('.third-party-widget').forEach(applyCustomStyle);
};

const observer = new MutationObserver((mutations) => {
  for (const mutation of mutations) {
    mutation.addedNodes.forEach(applyCustomStyle);
  }
});

observer.observe(document.body, { childList: true, subtree: true });
```

### 동적으로 삽입된 스크립트 감지

```js
const scriptObserver = new MutationObserver((mutations) => {
  for (const mutation of mutations) {
    for (const node of mutation.addedNodes) {
      if (node.tagName === 'SCRIPT') {
        console.warn('스크립트 삽입 감지:', node.src || node.textContent.slice(0, 50));
      }
    }
  }
});

scriptObserver.observe(document.documentElement, {
  childList: true,
  subtree: true,
});
```

---

## 4. 무한 루프 방지

MutationObserver 콜백 내에서 DOM을 변경하면 다시 콜백이 트리거되어 무한 루프가 발생할 수 있다.

### 방법 1: disconnect → 변경 → re-observe

```js
let isProcessing = false;

const observer = new MutationObserver((mutations) => {
  if (isProcessing) return;
  isProcessing = true;
  observer.disconnect(); // 일시 중지

  try {
    mutations.forEach(mutation => {
      // DOM 변경 작업
      mutation.target.dataset.processed = 'true';
    });
  } finally {
    // 재관찰 (마이크로태스크로 지연하여 현재 변경이 완전히 완료된 후)
    Promise.resolve().then(() => {
      observer.observe(targetNode, config);
      isProcessing = false;
    });
  }
});
```

### 방법 2: 플래그로 자체 유발 변경 무시

```js
let ignoreNext = false;

const observer = new MutationObserver((mutations) => {
  if (ignoreNext) {
    ignoreNext = false;
    return;
  }

  for (const mutation of mutations) {
    if (mutation.attributeName === 'data-highlight') continue; // 자체 속성 무시

    ignoreNext = true;
    mutation.target.setAttribute('data-highlight', Date.now());
  }
});

observer.observe(document.querySelector('#editor'), {
  attributes: true,
  attributeFilter: ['contenteditable', 'spellcheck'],
});
```

### 방법 3: 변경 원인 추적

```js
const SELF_MUTATIONS = new WeakSet();

const observer = new MutationObserver((mutations) => {
  const external = mutations.filter(m => !SELF_MUTATIONS.has(m.target));
  if (!external.length) return;

  external.forEach(mutation => {
    const el = mutation.addedNodes[0];
    if (el) {
      SELF_MUTATIONS.add(el);
      el.classList.add('auto-styled');
    }
  });
});
```

---

## 5. 면접 포인트

**Q. MutationObserver와 MutationEvent의 차이는?**

`MutationEvent`는 동기 실행이라 DOM 변경 중 콜백이 즉시 실행되어 레이아웃 재계산을 강제하고 성능 문제를 유발한다. `MutationObserver`는 비동기(마이크로태스크 큐)로 실행되어 여러 변경을 배치 처리한다. `MutationEvent`는 현재 deprecated 상태다.

**Q. takeRecords()는 언제 쓰나?**

observer를 disconnect하기 직전에 호출하면, 아직 콜백에 전달되지 않은 대기 레코드를 즉시 처리할 수 있다. 컴포넌트 언마운트 시 pending 변경 사항을 마지막으로 처리할 때 유용하다.

```js
const records = observer.takeRecords();
observer.disconnect();
if (records.length) processRecords(records);
```

**Q. subtree: true 사용 시 주의할 점은?**

`document.body` 전체에 `subtree: true`를 걸면 모든 DOM 변경이 감지되어 콜백 호출 빈도가 매우 높아진다. 가능한 좁은 범위의 타겟 노드를 지정하고, 필요한 옵션만 활성화하는 것이 좋다.

**Q. React/Vue 같은 프레임워크에서 MutationObserver가 유용한 경우는?**

직접 제어할 수 없는 서드파티 위젯이나 브라우저 확장 프로그램의 DOM 조작을 감지할 때, contenteditable 편집기의 변경 이벤트를 처리할 때, 또는 포털(Portal)로 렌더링된 컴포넌트의 생성/소멸을 감지할 때 유용하다.
