# 3. ResizeObserver

## 목차
1. 개요
2. ResizeObserver vs window resize 이벤트
3. 엘리먼트 크기 변화 감지
4. 반응형 컴포넌트 구현
5. 면접 포인트

---

## 1. 개요

`ResizeObserver`는 특정 엘리먼트의 크기(content box, border box)가 변경될 때 콜백을 호출하는 API다.
뷰포트 크기가 아니라 **개별 엘리먼트** 단위로 크기 변화를 감지한다.

```js
const observer = new ResizeObserver(callback);
observer.observe(element);
observer.observe(element, { box: 'border-box' }); // 옵션 지정
observer.unobserve(element);
observer.disconnect();
```

콜백은 `ResizeObserverEntry` 배열을 받는다.

```js
const callback = (entries) => {
  for (const entry of entries) {
    // contentBoxSize: padding 제외 크기
    const { inlineSize, blockSize } = entry.contentBoxSize[0];

    // borderBoxSize: padding + border 포함 크기
    const { inlineSize: bw, blockSize: bh } = entry.borderBoxSize[0];

    // contentRect: 레거시 방식 (여전히 널리 사용됨)
    const { width, height } = entry.contentRect;

    console.log(`width: ${width}, height: ${height}`);
  }
};
```

> `inlineSize`는 가로(수평 쓰기 모드 기준), `blockSize`는 세로. writing-mode가 vertical이면 반전된다.

---

## 2. ResizeObserver vs window resize 이벤트

| 항목 | window resize | ResizeObserver |
|------|--------------|----------------|
| 감지 범위 | 뷰포트 크기 변경만 | 모든 엘리먼트 크기 변경 |
| 트리거 원인 | 창 크기 조절만 | CSS 변경, flex/grid 재계산, 내용 변경 등 |
| 성능 | 동기 이벤트, throttle 필요 | 비동기 배치 처리 |
| 정밀도 | 뷰포트 기준 | 엘리먼트 기준, box model 선택 가능 |
| 중첩 컴포넌트 | 직접 계산 필요 | 각 엘리먼트 독립 감지 |

```js
// 기존 방식: 비효율적
window.addEventListener('resize', () => {
  const el = document.querySelector('.sidebar');
  adjustLayout(el.offsetWidth);
});

// ResizeObserver: 엘리먼트 직접 감지
const ro = new ResizeObserver(entries => {
  const entry = entries[0];
  adjustLayout(entry.contentRect.width);
});
ro.observe(document.querySelector('.sidebar'));
```

---

## 3. 엘리먼트 크기 변화 감지

### 기본 사용

```js
const sidebar = document.querySelector('.sidebar');

const ro = new ResizeObserver(entries => {
  for (const entry of entries) {
    const width = entry.contentRect.width;
    const height = entry.contentRect.height;
    console.log(`Sidebar: ${width.toFixed(0)}x${height.toFixed(0)}`);
  }
});

ro.observe(sidebar);
```

### box 옵션

```js
// content-box (기본): padding 제외
ro.observe(el, { box: 'content-box' });

// border-box: padding + border 포함
ro.observe(el, { box: 'border-box' });

// device-pixel-content-box: 디바이스 픽셀 단위 (고DPI 캔버스에 유용)
ro.observe(canvas, { box: 'device-pixel-content-box' });
```

### 크기 변화 시 캔버스 해상도 업데이트

```js
const canvas = document.querySelector('canvas');
const ctx = canvas.getContext('2d');

new ResizeObserver(entries => {
  for (const entry of entries) {
    if (entry.devicePixelContentBoxSize) {
      // 정밀한 픽셀 단위
      canvas.width = entry.devicePixelContentBoxSize[0].inlineSize;
      canvas.height = entry.devicePixelContentBoxSize[0].blockSize;
    } else {
      // 폴백
      canvas.width = Math.round(entry.contentRect.width * devicePixelRatio);
      canvas.height = Math.round(entry.contentRect.height * devicePixelRatio);
    }
    draw(ctx);
  }
}).observe(canvas, { box: 'device-pixel-content-box' });
```

---

## 4. 반응형 컴포넌트 구현

### 컴포넌트 자체 breakpoint (Container Queries 대신)

```js
class ResponsiveCard extends HTMLElement {
  connectedCallback() {
    this.ro = new ResizeObserver(entries => {
      const width = entries[0].contentRect.width;
      this.dataset.size = width < 300 ? 'sm' : width < 600 ? 'md' : 'lg';
    });
    this.ro.observe(this);
  }

  disconnectedCallback() {
    this.ro.disconnect();
  }
}

customElements.define('responsive-card', ResponsiveCard);
```

```css
responsive-card[data-size="sm"] .card-description { display: none; }
responsive-card[data-size="md"] .card-image { width: 80px; }
responsive-card[data-size="lg"] .card-image { width: 160px; }
```

### React Hook으로 추상화

```js
import { useState, useEffect, useRef } from 'react';

function useElementSize(ref) {
  const [size, setSize] = useState({ width: 0, height: 0 });

  useEffect(() => {
    if (!ref.current) return;

    const ro = new ResizeObserver(entries => {
      const { width, height } = entries[0].contentRect;
      setSize({ width, height });
    });

    ro.observe(ref.current);
    return () => ro.disconnect();
  }, [ref]);

  return size;
}

// 사용
function Chart() {
  const containerRef = useRef(null);
  const { width, height } = useElementSize(containerRef);

  return (
    <div ref={containerRef} style={{ width: '100%' }}>
      <canvas width={width} height={height} />
    </div>
  );
}
```

### 텍스트 오버플로 감지

```js
const label = document.querySelector('.label');

new ResizeObserver(() => {
  const isOverflowing = label.scrollWidth > label.clientWidth;
  label.title = isOverflowing ? label.textContent : '';
}).observe(label);
```

---

## 5. 면접 포인트

**Q. ResizeObserver로 무한 루프가 발생할 수 있는 경우는?**

콜백 내에서 관찰 중인 엘리먼트의 크기를 변경하면 재귀 호출이 발생한다. 브라우저는 이를 감지해 `ResizeObserver loop limit exceeded` 에러를 발생시키고 해당 프레임 콜백을 건너뛴다. 콜백 내에서는 크기에 영향을 주지 않는 작업(클래스 토글, 데이터 업데이트 등)만 수행하는 것이 안전하다.

**Q. CSS Container Queries와 ResizeObserver의 차이는?**

CSS Container Queries는 순수 CSS로 컨테이너 크기에 따른 스타일을 선언적으로 지정한다. ResizeObserver는 JS 로직(데이터 재계산, 서드파티 라이브러리 업데이트 등)이 필요할 때 적합하다. 단순 스타일 변경이라면 Container Queries가 더 간결하고 성능도 좋다.

**Q. contentRect vs contentBoxSize의 차이는?**

`contentRect`는 레거시 속성으로 `DOMRectReadOnly`를 반환한다. `contentBoxSize`는 배열 형태로 writing-mode를 고려한 `inlineSize`, `blockSize`를 제공한다. 다국어 지원이 필요한 앱에서는 `contentBoxSize`가 더 정확하다.

**Q. 여러 엘리먼트를 하나의 ResizeObserver로 관찰해도 되나?**

성능상 하나의 인스턴스로 여러 엘리먼트를 관찰하는 것이 권장된다. 엘리먼트마다 개별 인스턴스를 만들면 메모리 사용량이 증가한다. `entry.target`으로 어떤 엘리먼트가 변경됐는지 구분할 수 있다.
