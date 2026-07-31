# 10. 디자인 시스템 테마: 토큰 상속 vs CSS 오버라이드

> 실전 배경: 다크모드에서 드로어 안의 카드(설비정보·ESS 정보) 배경만 **하얗게** 남았다.
> 처음엔 해당 컴포넌트에 비-스코프 CSS로 배경을 억지로 덮었지만, 근본 원인은
> **중첩된 테마 provider가 다크 알고리즘을 상속하지 않은 것**이었다.

## 목차
1. [증상: 특정 컴포넌트만 테마가 안 먹는다](#1-증상-특정-컴포넌트만-테마가-안-먹는다)
2. [원인: 중첩 provider는 algorithm을 자동 상속하지 않는다](#2-원인-중첩-provider는-algorithm을-자동-상속하지-않는다)
3. [CSS 오버라이드 vs 토큰(algorithm) 상속](#3-css-오버라이드-vs-토큰algorithm-상속)
4. [근본 해결: provider에 algorithm 명시](#4-근본-해결-provider에-algorithm-명시)
5. [면접 포인트](#5-면접-포인트)

---

## 1. 증상: 특정 컴포넌트만 테마가 안 먹는다

전역은 다크모드인데 **특정 영역의 컴포넌트만** 라이트로 렌더링됐다. 여기서는 드로어(모달) 안에서 쓰는 카드(`<a-card>`)의 배경이었다.

디자인 시스템(여기선 Ant Design Vue)은 색을 **테마 토큰**으로 관리한다. 컴포넌트는 `#fff`를 하드코딩하지 않고 `colorBgContainer` 같은 토큰을 참조하며, 그 토큰 값은 **algorithm**(light/dark)에 따라 계산된다.

```
theme.defaultAlgorithm → colorBgContainer = #ffffff
theme.darkAlgorithm   → colorBgContainer = #141414
```

즉 "특정 컴포넌트만 흰색"은 **그 컴포넌트가 속한 테마 컨텍스트가 여전히 light algorithm을 쓰고 있다**는 신호다.

---

## 2. 원인: 중첩 provider는 algorithm을 자동 상속하지 않는다

이 앱은 드로어 전용으로 컴포넌트 토큰(z-index, padding 등)을 조정하는 중첩 `ConfigProvider`를 두고 있었다.

```vue
<!-- DrawerCustomThemeProvider.vue (문제 버전) -->
<ConfigProvider :theme="{ components: { Drawer: { zIndexPopup: 2000 } } }">
  <slot />  <!-- 이 안의 a-card는 무슨 algorithm을 쓸까? -->
</ConfigProvider>
```

여기엔 함정이 있다. 중첩 `ConfigProvider`에 `algorithm`을 지정하지 않으면, **부모의 algorithm이 자동으로 상속되지 않고 기본값(light)으로 리셋**되는 경우가 있다. 그래서 이 provider 하위의 모든 컴포넌트가 다크모드에서도 light 토큰으로 렌더링됐다.

> 일반화하면: **테마 컨텍스트를 중첩하면, 자식 컨텍스트가 부모의 테마 설정을 온전히 이어받는지 확인해야 한다.** 컴포넌트 토큰만 덮으려다 알고리즘(색 계산 규칙) 전체를 실수로 초기화하는 게 전형적 실수다.

---

## 3. CSS 오버라이드 vs 토큰(algorithm) 상속

첫 시도는 문제 컴포넌트에 비-스코프 CSS로 배경을 덮는 것이었다.

```css
/* 대증요법: 이 카드만 강제로 어둡게 */
.resource-modal :deep(.ant-card) {
  background-color: #141414 !important;
}
```

이게 나쁜 이유:
- **`!important`와 `:deep()`으로 디자인 시스템 내부 클래스를 침범** → 라이브러리 업데이트에 취약.
- **한 컴포넌트만** 고치므로, 같은 provider를 쓰는 다른 드로어는 여전히 깨진다.
- 색을 하드코딩(`#141414`)해 테마가 늘면 또 깨진다.
- **증상만** 덮고 원인(algorithm 미상속)은 그대로.

근본 해결은 색이 아니라 **algorithm 자체를 올바르게 전달**하는 것. 그러면 토큰이 알아서 다크값으로 계산된다.

---

## 4. 근본 해결: provider에 algorithm 명시

provider가 이미 `isDark`를 주입받고 있었으므로, 같은 값으로 `algorithm`만 명시해주면 됐다.

```vue
<script setup>
import { theme } from 'ant-design-vue';

const customTheme = computed(() => ({
  algorithm: isDark.value ? theme.darkAlgorithm : theme.defaultAlgorithm, // ← 핵심
  components: { Drawer: { zIndexPopup: 2000 } }, // 기존 컴포넌트 토큰 유지
}));
</script>

<template>
  <ConfigProvider :theme="customTheme">
    <slot />
  </ConfigProvider>
</template>
```

효과:
- 이 provider 하위의 **모든** 디자인 시스템 컴포넌트가 올바른 테마로 렌더링된다(카드뿐 아니라 전부).
- CSS 오버라이드·하드코딩 색이 사라진다.
- 이 provider를 공유하는 다른 드로어들도 **한 번에** 고쳐진다.

관련: 컴포넌트 자체 CSS는 [문서 05의 CSS 변수 테마](./05-sticky-transparent-background.md)로, 디자인 시스템 컴포넌트는 이 문서의 algorithm 토큰으로 — **"내 CSS는 변수로, 라이브러리 컴포넌트는 토큰으로"** 두 축을 구분하는 게 핵심이다.

---

## 5. 면접 포인트

**Q. 디자인 시스템에서 다크모드는 보통 어떻게 구현되나요?**
> 컴포넌트가 색을 하드코딩하지 않고 테마 토큰(colorBgContainer 등)을 참조하고, 그 토큰 값을 light/dark algorithm이 계산한다. 그래서 테마 전환은 algorithm만 바꾸면 되고, 개별 컴포넌트 CSS는 손대지 않는다.

**Q. 전역은 다크인데 특정 영역만 라이트로 남는다면?**
> 그 영역의 테마 컨텍스트가 light algorithm을 쓰고 있을 가능성이 크다. 중첩된 테마 provider(ConfigProvider 등)가 부모의 algorithm을 상속하지 않고 기본값으로 리셋된 경우가 흔하다. 중첩 provider에 algorithm을 명시하면 해결된다.

**Q. CSS `!important` 오버라이드로 색을 덮는 것과 토큰으로 고치는 것의 차이는?**
> CSS 오버라이드는 증상만 덮고, 라이브러리 내부 클래스를 침범해 업데이트에 취약하며, 그 컴포넌트 하나만 고쳐 같은 provider의 다른 컴포넌트는 여전히 깨진다. algorithm/토큰을 바로잡으면 하위 전체가 일관되게 해결되고 색 하드코딩도 사라진다. 원인을 고치는 쪽이다.

**Q. 컴포넌트 토큰만 커스텀하려다 생기는 실수는?**
> 중첩 provider에 컴포넌트 토큰(padding, z-index 등)만 지정하고 algorithm을 생략하면, 색 계산 규칙 전체가 기본(light)으로 초기화될 수 있다. 커스텀 토큰을 넣을 때 algorithm도 함께 전달해야 한다.
