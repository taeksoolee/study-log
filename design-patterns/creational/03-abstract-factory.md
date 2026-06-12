# Abstract Factory (추상 팩토리 패턴)

## 목차
1. [개념](#1-개념)
2. [UI 테마 팩토리 예제](#2-ui-테마-팩토리-예제)
3. [플랫폼별 컴포넌트 예제](#3-플랫폼별-컴포넌트-예제)
4. [실제 프레임워크에서의 활용](#4-실제-프레임워크에서의-활용)
5. [팩토리 메서드 vs 추상 팩토리](#5-팩토리-메서드-vs-추상-팩토리)
6. [면접 포인트](#6-면접-포인트)

---

## 1. 개념

> **관련된 객체들의 군(family)**을 구체 클래스를 명시하지 않고 생성하는 인터페이스를 제공한다.

추상 팩토리는 "팩토리들의 팩토리"라고도 불린다.
서로 연관된 여러 제품을 **일관된 테마나 플랫폼 하에서** 함께 생성해야 할 때 사용한다.

**핵심 아이디어**: 일관성이 중요한 객체 군을 하나의 팩토리 인터페이스로 묶는다.

**구조**
```
AbstractFactory (interface)
├─ createButton(): Button
├─ createInput(): Input
└─ createModal(): Modal

LightThemeFactory        DarkThemeFactory
├─ createButton()    ←→  ├─ createButton()
├─ createInput()         ├─ createInput()
└─ createModal()         └─ createModal()
```

---

## 2. UI 테마 팩토리 예제

테마(Light/Dark)에 따라 일관된 UI 컴포넌트 세트를 생성하는 예제다.

```typescript
// 제품 인터페이스들
interface Button {
  render(): string;
  getStyle(): Record<string, string>;
}

interface Input {
  render(): string;
  getPlaceholderStyle(): Record<string, string>;
}

interface Card {
  render(content: string): string;
}

// 추상 팩토리 인터페이스
interface ThemeFactory {
  createButton(label: string): Button;
  createInput(placeholder: string): Input;
  createCard(): Card;
}

// ─── Light Theme ─────────────────────────────────────────
class LightButton implements Button {
  constructor(private label: string) {}
  render() {
    return `<button style="background:#fff;color:#333">${this.label}</button>`;
  }
  getStyle() {
    return { background: '#ffffff', color: '#333333', border: '1px solid #ccc' };
  }
}

class LightInput implements Input {
  constructor(private placeholder: string) {}
  render() {
    return `<input placeholder="${this.placeholder}" style="background:#fff;color:#333" />`;
  }
  getPlaceholderStyle() {
    return { color: '#999999' };
  }
}

class LightCard implements Card {
  render(content: string) {
    return `<div style="background:#fff;box-shadow:0 1px 3px rgba(0,0,0,0.1)">${content}</div>`;
  }
}

class LightThemeFactory implements ThemeFactory {
  createButton(label: string): Button {
    return new LightButton(label);
  }
  createInput(placeholder: string): Input {
    return new LightInput(placeholder);
  }
  createCard(): Card {
    return new LightCard();
  }
}

// ─── Dark Theme ──────────────────────────────────────────
class DarkButton implements Button {
  constructor(private label: string) {}
  render() {
    return `<button style="background:#333;color:#fff">${this.label}</button>`;
  }
  getStyle() {
    return { background: '#333333', color: '#ffffff', border: '1px solid #555' };
  }
}

class DarkInput implements Input {
  constructor(private placeholder: string) {}
  render() {
    return `<input placeholder="${this.placeholder}" style="background:#222;color:#fff" />`;
  }
  getPlaceholderStyle() {
    return { color: '#666666' };
  }
}

class DarkCard implements Card {
  render(content: string) {
    return `<div style="background:#1e1e1e;box-shadow:0 1px 3px rgba(0,0,0,0.5)">${content}</div>`;
  }
}

class DarkThemeFactory implements ThemeFactory {
  createButton(label: string): Button {
    return new DarkButton(label);
  }
  createInput(placeholder: string): Input {
    return new DarkInput(placeholder);
  }
  createCard(): Card {
    return new DarkCard();
  }
}

// ─── 클라이언트 코드 ─────────────────────────────────────
function buildLoginForm(factory: ThemeFactory): string {
  const card = factory.createCard();
  const emailInput = factory.createInput('이메일 입력');
  const passwordInput = factory.createInput('비밀번호 입력');
  const submitBtn = factory.createButton('로그인');

  const formContent = `
    ${emailInput.render()}
    ${passwordInput.render()}
    ${submitBtn.render()}
  `;
  return card.render(formContent);
}

// 테마에 따라 팩토리만 교체
const theme = window?.matchMedia('(prefers-color-scheme: dark)').matches
  ? new DarkThemeFactory()
  : new LightThemeFactory();

console.log(buildLoginForm(theme));
```

---

## 3. 플랫폼별 컴포넌트 예제

```typescript
// 모바일 vs 데스크탑에 따라 다른 UI 컴포넌트 생성
interface NavigationBar {
  render(): string;
}

interface MenuItem {
  render(label: string): string;
}

interface UIFactory {
  createNavigationBar(): NavigationBar;
  createMenuItem(): MenuItem;
}

class MobileNavBar implements NavigationBar {
  render() { return '<nav class="mobile-nav">햄버거 메뉴</nav>'; }
}

class DesktopNavBar implements NavigationBar {
  render() { return '<nav class="desktop-nav">상단 네비게이션</nav>'; }
}

class MobileMenuItem implements MenuItem {
  render(label: string) { return `<li class="mobile-item">${label}</li>`; }
}

class DesktopMenuItem implements MenuItem {
  render(label: string) { return `<li class="desktop-item">${label}</li>`; }
}

class MobileUIFactory implements UIFactory {
  createNavigationBar() { return new MobileNavBar(); }
  createMenuItem() { return new MobileMenuItem(); }
}

class DesktopUIFactory implements UIFactory {
  createNavigationBar() { return new DesktopNavBar(); }
  createMenuItem() { return new DesktopMenuItem(); }
}

// 런타임에 플랫폼 감지 후 팩토리 결정
function createUIFactory(): UIFactory {
  const isMobile = /Mobi|Android/i.test(navigator.userAgent);
  return isMobile ? new MobileUIFactory() : new DesktopUIFactory();
}
```

---

## 4. 실제 프레임워크에서의 활용

### Material-UI (MUI) 테마 시스템
MUI의 `ThemeProvider`는 추상 팩토리 개념을 적용한다.
테마 객체가 팩토리 역할을 하며, 버튼/인풋/모달 등의 스타일을 일관성 있게 생성한다.

```typescript
// MUI 테마 — 추상 팩토리 개념 적용
const lightTheme = createTheme({
  palette: { mode: 'light', primary: { main: '#1976d2' } },
});

const darkTheme = createTheme({
  palette: { mode: 'dark', primary: { main: '#90caf9' } },
});

// ThemeProvider가 팩토리 역할 → 하위 모든 컴포넌트가 일관된 스타일 사용
<ThemeProvider theme={darkTheme}>
  <Button>버튼</Button>
  <TextField />
</ThemeProvider>
```

---

## 5. 팩토리 메서드 vs 추상 팩토리

| 구분 | 팩토리 메서드 | 추상 팩토리 |
|------|--------------|------------|
| 범위 | 단일 객체 생성 | 연관된 객체 군(family) 생성 |
| 방법 | 상속 (서브클래스 오버라이드) | 합성 (팩토리 객체 주입) |
| 목적 | 생성할 클래스 결정을 서브클래스에 위임 | 일관된 제품 군 보장 |
| 복잡도 | 상대적으로 단순 | 상대적으로 복잡 |

---

## 6. 면접 포인트

**Q1. 추상 팩토리 패턴이란 무엇인가요?**
> 서로 관련된 객체들(제품 군)을 일관성 있게 생성하는 인터페이스를 제공하는 패턴입니다. 클라이언트는 구체 클래스를 몰라도 일관된 제품 군을 사용할 수 있습니다.

**Q2. 언제 팩토리 메서드 대신 추상 팩토리를 선택하나요?**
> 여러 연관된 객체가 **함께 변경**되어야 할 때(예: 테마, 플랫폼, 환경) 추상 팩토리를 선택합니다. Light 테마로 버튼은 Light이지만 입력창은 Dark인 불일치를 방지하고 싶을 때 유용합니다.

**Q3. MUI ThemeProvider와 추상 팩토리의 관계를 설명해주세요.**
> ThemeProvider는 추상 팩토리 개념을 활용합니다. 테마 객체가 모든 컴포넌트의 스타일 생성 규칙을 담고 있으며, 테마만 교체하면 하위 모든 컴포넌트가 일관성 있게 변경됩니다.

**Q4. 추상 팩토리의 단점은?**
> 새로운 제품 종류(예: Tooltip 추가)를 추가할 때 팩토리 인터페이스와 모든 구체 팩토리 클래스를 수정해야 해서 확장이 어렵습니다.

---

[← Factory Method](./02-factory-method.md) | [← 생성 패턴 목차](./README.md) | [다음: Builder →](./04-builder.md)
