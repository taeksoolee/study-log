# 1. IntersectionObserver

## 목차
1. 개요
2. 옵션 (root, rootMargin, threshold)
3. 무한 스크롤 구현
4. 이미지 Lazy Loading 구현
5. 애니메이션 트리거 패턴
6. 면접 포인트

---

## 1. 개요

`IntersectionObserver`는 타겟 엘리먼트가 뷰포트(또는 지정된 조상 엘리먼트)와 교차하는 시점을 비동기로 감지하는 API다.
스크롤 이벤트 기반 구현 대비 **메인 스레드 블로킹 없이** 교차 감지가 가능하다.

```js
const observer = new IntersectionObserver(callback, options);
observer.observe(targetElement);
observer.unobserve(targetElement); // 개별 해제
observer.disconnect();             // 전체 해제
```

콜백은 `IntersectionObserverEntry` 배열을 받는다.

```js
const callback = (entries, observer) => {
  entries.forEach(entry => {
    console.log(entry.isIntersecting);      // 교차 여부
    console.log(entry.intersectionRatio);   // 0.0 ~ 1.0
    console.log(entry.boundingClientRect);  // 타겟 위치
    console.log(entry.rootBounds);          // 루트 위치
    console.log(entry.time);               // 교차 발생 시각 (ms)
  });
};
```

---

## 2. 옵션 (root, rootMargin, threshold)

```js
const options = {
  // root: 교차 기준이 되는 컨테이너. null이면 뷰포트
  root: document.querySelector('#scroll-container'),

  // rootMargin: root 경계를 확장/축소 (CSS margin 문법)
  // 양수 → 미리 감지 (ex. 200px 아래에서 미리 로드)
  // 음수 → 더 안쪽에 들어와야 감지
  rootMargin: '0px 0px 200px 0px',

  // threshold: 몇 % 교차했을 때 콜백 실행할지
  // 단일 값 또는 배열 가능
  threshold: [0, 0.25, 0.5, 0.75, 1.0],
};
```

### rootMargin 시각화

```
┌──────────────────────────────┐  ← 뷰포트 상단
│                              │
│         화면에 보이는 영역     │
│                              │
└──────────────────────────────┘  ← 뷰포트 하단
       ↕ rootMargin: '0px 0px 200px 0px'
- - - - - - - - - - - - - - - -   ← 실제 감지 경계 (200px 아래)
```

---

## 3. 무한 스크롤 구현

```js
class InfiniteScroll {
  constructor(containerSelector, loadMore) {
    this.container = document.querySelector(containerSelector);
    this.loadMore = loadMore;
    this.page = 1;
    this.loading = false;

    this.sentinel = document.createElement('div');
    this.sentinel.className = 'sentinel';
    this.container.appendChild(this.sentinel);

    this.observer = new IntersectionObserver(
      this.handleIntersect.bind(this),
      { rootMargin: '0px 0px 300px 0px', threshold: 0 }
    );
    this.observer.observe(this.sentinel);
  }

  async handleIntersect(entries) {
    const [entry] = entries;
    if (!entry.isIntersecting || this.loading) return;

    this.loading = true;
    try {
      const hasMore = await this.loadMore(this.page);
      if (hasMore) {
        this.page++;
      } else {
        this.observer.disconnect(); // 마지막 페이지 → 관찰 중지
      }
    } finally {
      this.loading = false;
    }
  }

  destroy() {
    this.observer.disconnect();
    this.sentinel.remove();
  }
}

// 사용 예
const scroll = new InfiniteScroll('#feed', async (page) => {
  const res = await fetch(`/api/posts?page=${page}`);
  const { items, hasNext } = await res.json();
  renderItems(items);
  return hasNext;
});
```

---

## 4. 이미지 Lazy Loading 구현

```html
<!-- data-src에 실제 URL 보관, src는 placeholder -->
<img class="lazy" data-src="photo.jpg" src="placeholder.svg" alt="사진" />
```

```js
const lazyImages = document.querySelectorAll('img.lazy');

const imageObserver = new IntersectionObserver((entries, observer) => {
  entries.forEach(entry => {
    if (!entry.isIntersecting) return;

    const img = entry.target;
    img.src = img.dataset.src;

    // srcset도 지원
    if (img.dataset.srcset) {
      img.srcset = img.dataset.srcset;
    }

    img.classList.add('loaded');
    observer.unobserve(img); // 로드 후 관찰 해제
  });
}, {
  rootMargin: '0px 0px 500px 0px', // 500px 전에 미리 로드
});

lazyImages.forEach(img => imageObserver.observe(img));

// 폴백: IntersectionObserver 미지원 환경
if (!('IntersectionObserver' in window)) {
  lazyImages.forEach(img => { img.src = img.dataset.src; });
}
```

---

## 5. 애니메이션 트리거 패턴

```css
.fade-in {
  opacity: 0;
  transform: translateY(30px);
  transition: opacity 0.6s ease, transform 0.6s ease;
}
.fade-in.visible {
  opacity: 1;
  transform: translateY(0);
}
```

```js
const animObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
      // 한 번 재생 후 해제 (반복 재생 원하면 else에서 제거)
      animObserver.unobserve(entry.target);
    }
  });
}, { threshold: 0.15 });

document.querySelectorAll('.fade-in').forEach(el => animObserver.observe(el));
```

### 순차 지연 애니메이션

```js
document.querySelectorAll('.fade-in').forEach((el, i) => {
  el.style.transitionDelay = `${i * 0.1}s`;
  animObserver.observe(el);
});
```

---

## 6. 면접 포인트

**Q. IntersectionObserver가 scroll 이벤트보다 나은 이유는?**

scroll 이벤트는 매 프레임 메인 스레드에서 동기 실행되므로 레이아웃 스래싱이 발생하기 쉽다.
IntersectionObserver는 브라우저 내부에서 비동기로 교차 여부를 계산하고, 콜백을 태스크 큐에 넣기 때문에 메인 스레드 영향이 최소화된다.

**Q. threshold: 0과 threshold: 0.0001의 차이는?**

`0`은 픽셀 1개라도 보이면 실행된다. 실질적으로 동일하나, 일부 브라우저에서 0은 "보이기 시작 전 경계"로 처리하는 구현 차이가 있을 수 있다. 정확한 "화면에 진입하는 순간"을 원하면 `0`을 사용하면 된다.

**Q. rootMargin이 CSS margin과 다른 점은?**

CSS margin과 문법이 같지만, `%` 단위를 사용할 경우 root 엘리먼트의 너비를 기준으로 계산된다. viewport가 root일 때도 동일하다.

**Q. SPA에서 페이지 전환 시 주의할 점은?**

컴포넌트 언마운트 시 반드시 `observer.disconnect()`를 호출해야 메모리 누수가 발생하지 않는다. React의 경우 `useEffect` 클린업에서 처리한다.

```js
useEffect(() => {
  const observer = new IntersectionObserver(callback, options);
  observer.observe(ref.current);
  return () => observer.disconnect();
}, []);
```
