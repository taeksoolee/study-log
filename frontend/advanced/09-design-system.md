# 디자인 시스템 구축

## 개요

[case-studies/10](../../case-studies/10-design-system-theme.md)에서 테마 토큰 상속과 CSS 오버라이드를 다뤘다면, 이 문서에서는 **디자인 시스템 전체를 설계·구축·운영하는 과정**을 다룬다.

디자인 시스템이란 단순한 컴포넌트 라이브러리가 아니다. **일관된 사용자 경험을 만들기 위한 표준, 도구, 프로세스의 집합**이다.

구성 요소:
- **디자인 토큰**: 색상, 타이포그래피, 스페이싱 등의 원자적 값
- **컴포넌트 라이브러리**: 재사용 가능한 UI 빌딩 블록
- **패턴 & 가이드라인**: 컴포넌트를 조합하는 방법론
- **문서화**: 사용법, 디자인 의도, 접근성 가이드
- **거버넌스**: 기여 프로세스, 버저닝, 의사결정 구조

---

## 디자인 토큰 (Design Tokens)

디자인 토큰은 **디자인 결정을 플랫폼에 독립적인 방식으로 저장하는 최소 단위**다. 하드코딩된 값(`#3b82f6`) 대신 의미를 가진 이름(`color-interactive-primary`)으로 표현한다.

### 토큰 계층 구조

```
Primitive (Global) → Semantic → Component
```

이 계층 구조가 필요한 이유:
1. **Primitive만 사용** → 테마 전환 불가, 의미 파악 어려움
2. **Semantic까지** → 테마 전환 가능, 컴포넌트별 세밀한 제어 어려움
3. **Component까지** → 완전한 제어, 하지만 토큰 수 폭증 주의

#### Primitive Tokens (Global)

가장 낮은 수준의 원시 값. 맥락(context)이 없다.

```css
/* 색상 */
--color-blue-50: #eff6ff;
--color-blue-100: #dbeafe;
--color-blue-500: #3b82f6;
--color-blue-900: #1e3a8a;
--color-gray-100: #f3f4f6;
--color-gray-900: #111827;

/* 타이포그래피 */
--font-size-xs: 0.75rem;
--font-size-sm: 0.875rem;
--font-size-base: 1rem;
--font-size-lg: 1.125rem;
--font-weight-normal: 400;
--font-weight-medium: 500;
--font-weight-bold: 700;

/* 스페이싱 (4px 기반) */
--space-1: 0.25rem;   /* 4px */
--space-2: 0.5rem;    /* 8px */
--space-3: 0.75rem;   /* 12px */
--space-4: 1rem;      /* 16px */
--space-6: 1.5rem;    /* 24px */
--space-8: 2rem;      /* 32px */

/* 그림자 */
--shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
--shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);

/* 반경 */
--radius-sm: 0.25rem;
--radius-md: 0.375rem;
--radius-lg: 0.5rem;
--radius-full: 9999px;

/* 애니메이션 */
--duration-fast: 150ms;
--duration-normal: 250ms;
--duration-slow: 400ms;
```

#### Semantic Tokens

의미(맥락)를 부여한 토큰. **테마에 따라 매핑이 바뀐다.**

```css
/* Light 테마 */
:root, [data-theme="light"] {
  --color-text-primary: var(--color-gray-900);
  --color-text-secondary: var(--color-gray-600);
  --color-text-disabled: var(--color-gray-400);

  --color-bg-page: var(--color-white);
  --color-bg-surface: var(--color-gray-50);
  --color-bg-elevated: var(--color-white);

  --color-border-default: var(--color-gray-200);
  --color-border-strong: var(--color-gray-400);

  --color-interactive-primary: var(--color-blue-500);
  --color-interactive-hover: var(--color-blue-600);

  --color-status-success: var(--color-green-500);
  --color-status-error: var(--color-red-500);
  --color-status-warning: var(--color-yellow-500);
}

/* Dark 테마 */
[data-theme="dark"] {
  --color-text-primary: var(--color-gray-100);
  --color-text-secondary: var(--color-gray-400);
  --color-text-disabled: var(--color-gray-600);

  --color-bg-page: var(--color-gray-900);
  --color-bg-surface: var(--color-gray-800);
  --color-bg-elevated: var(--color-gray-750);

  --color-border-default: var(--color-gray-700);
  --color-border-strong: var(--color-gray-500);

  --color-interactive-primary: var(--color-blue-400);
  --color-interactive-hover: var(--color-blue-300);
}
```

#### Component Tokens

특정 컴포넌트에 바인딩되는 가장 구체적인 토큰.

```css
/* Button */
--button-color-bg: var(--color-interactive-primary);
--button-color-bg-hover: var(--color-interactive-hover);
--button-color-text: var(--color-white);
--button-padding-x: var(--space-4);
--button-padding-y: var(--space-2);
--button-radius: var(--radius-md);

/* Input */
--input-border-color: var(--color-border-default);
--input-border-color-focus: var(--color-interactive-primary);
--input-bg: var(--color-bg-surface);
--input-padding: var(--space-3);
```

> **주의**: 모든 컴포넌트에 Component Token을 만들면 토큰이 폭증한다. 자주 커스텀되는 핵심 컴포넌트에만 적용하고, 나머지는 Semantic Token을 직접 참조하는 것이 실용적이다.

### 구현 방법

| 방법 | 장점 | 단점 |
|------|------|------|
| CSS Custom Properties | 런타임 테마 전환, 브라우저 네이티브 | 타입 안전성 없음 |
| Style Dictionary | 멀티 플랫폼, 자동화 | 빌드 스텝 필요 |
| Figma Tokens (Tokens Studio) | 디자인 ↔ 코드 동기화 | Figma 의존 |

---

## Headless UI 패턴

### 개념

Headless UI는 **기능(로직 + 접근성)은 제공하되, 스타일은 소비자가 결정**하는 패턴이다.

```
┌─────────────────────────────┐
│  Headless 컴포넌트 (라이브러리) │
│  • 키보드 내비게이션           │
│  • WAI-ARIA 속성 관리         │
│  • 포커스 트랩                │
│  • 상태 관리 (open/close 등)  │
└──────────────┬──────────────┘
               │ render props / hooks / slots
┌──────────────▼──────────────┐
│  소비자 (당신의 디자인 시스템)   │
│  • 자체 디자인 토큰 적용       │
│  • Tailwind / CSS Modules    │
│  • 커스텀 애니메이션           │
└─────────────────────────────┘
```

### 주요 라이브러리

| 라이브러리 | 특징 | 프레임워크 |
|-----------|------|-----------|
| **Radix UI** | 가장 성숙, 비제어/제어 모두 지원, 포털·애니메이션 내장 | React |
| **Ark UI** | Chakra 팀 제작, 상태 머신 기반(Zag.js) | React/Vue/Solid |
| **React Aria** (Adobe) | Hook 기반, 최고 수준 접근성, 국제화 내장 | React |
| **Headless UI** (Tailwind Labs) | 간결한 API, Tailwind 최적화 | React/Vue |
| **Melt UI** | Svelte 전용 Headless | Svelte |

### 언제 Headless를 쓰는가

✅ 사용해야 할 때:
- 독자적 디자인 언어(브랜드 가이드)가 있을 때
- 높은 커스텀 자유도가 필요할 때
- 접근성을 직접 구현하기 어렵거나 시간이 부족할 때
- 여러 테마/브랜드를 하나의 컴포넌트로 커버해야 할 때

❌ 굳이 필요 없을 때:
- 이미 완성된 UI 라이브러리(MUI, Ant Design)의 스타일이 요구사항과 맞을 때
- 프로토타이핑 단계에서 빠른 결과물이 필요할 때

---

## 컴포넌트 설계 원칙

### Compound Component 패턴

관련된 컴포넌트들을 하나의 네임스페이스 아래에 묶어, **암묵적 상태 공유**를 가능하게 한다.

```tsx
// 사용 예
<Select>
  <Select.Trigger>과일 선택</Select.Trigger>
  <Select.Content>
    <Select.Item value="apple">사과</Select.Item>
    <Select.Item value="banana">바나나</Select.Item>
    <Select.Item value="cherry">체리</Select.Item>
  </Select.Content>
</Select>
```

```tsx
// 구현 핵심: Context로 상태 공유
const SelectContext = createContext<SelectState | null>(null);

function Select({ children }: { children: ReactNode }) {
  const [open, setOpen] = useState(false);
  const [value, setValue] = useState<string>('');

  return (
    <SelectContext.Provider value={{ open, setOpen, value, setValue }}>
      <div className="select-root">{children}</div>
    </SelectContext.Provider>
  );
}

Select.Trigger = function Trigger({ children }: { children: ReactNode }) {
  const { setOpen } = useContext(SelectContext)!;
  return <button onClick={() => setOpen(prev => !prev)}>{children}</button>;
};

Select.Content = function Content({ children }: { children: ReactNode }) {
  const { open } = useContext(SelectContext)!;
  if (!open) return null;
  return <ul role="listbox">{children}</ul>;
};

Select.Item = function Item({ value, children }: { value: string; children: ReactNode }) {
  const { setValue, setOpen } = useContext(SelectContext)!;
  return (
    <li role="option" onClick={() => { setValue(value); setOpen(false); }}>
      {children}
    </li>
  );
};
```

**장점**: API가 선언적이고, 내부 상태를 캡슐화하면서도 구조를 유연하게 변경 가능.

### Polymorphic Component (as prop)

하나의 컴포넌트가 **렌더링할 HTML 요소를 동적으로 결정**한다.

```tsx
type ButtonProps<T extends ElementType = 'button'> = {
  as?: T;
  children: ReactNode;
} & ComponentPropsWithoutRef<T>;

function Button<T extends ElementType = 'button'>({
  as,
  children,
  ...props
}: ButtonProps<T>) {
  const Component = as || 'button';
  return <Component {...props}>{children}</Component>;
}

// 사용
<Button>일반 버튼</Button>
<Button as="a" href="/home">링크 버튼</Button>
<Button as={Link} to="/dashboard">Router 링크</Button>
```

### Variant 관리

#### CVA (Class Variance Authority)

Tailwind CSS와 함께 **타입 안전한 variant**를 정의하는 도구.

```tsx
import { cva, type VariantProps } from 'class-variance-authority';

const buttonVariants = cva(
  // base
  'inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-2',
  {
    variants: {
      variant: {
        primary: 'bg-blue-500 text-white hover:bg-blue-600',
        secondary: 'bg-gray-100 text-gray-900 hover:bg-gray-200',
        ghost: 'hover:bg-gray-100 text-gray-700',
        destructive: 'bg-red-500 text-white hover:bg-red-600',
      },
      size: {
        sm: 'h-8 px-3 text-sm',
        md: 'h-10 px-4 text-base',
        lg: 'h-12 px-6 text-lg',
      },
    },
    compoundVariants: [
      {
        variant: 'ghost',
        size: 'sm',
        className: 'px-2', // ghost + sm일 때 특별 처리
      },
    ],
    defaultVariants: {
      variant: 'primary',
      size: 'md',
    },
  }
);

type ButtonProps = VariantProps<typeof buttonVariants> & {
  children: ReactNode;
};

function Button({ variant, size, children, ...props }: ButtonProps) {
  return (
    <button className={buttonVariants({ variant, size })} {...props}>
      {children}
    </button>
  );
}
```

#### 비교

| 도구 | 스타일 방식 | 타입 안전 | 런타임 비용 |
|------|-----------|----------|------------|
| CVA | Tailwind (유틸리티) | ✅ | Zero (빌드 타임) |
| Stitches | CSS-in-JS | ✅ | Near-zero |
| Vanilla Extract | CSS-in-TS (빌드 타임) | ✅ | Zero |

### Slot 패턴 (Radix `asChild`)

`as` prop의 한계(prop 충돌, 타입 복잡성)를 해결하는 대안.

```tsx
import { Slot } from '@radix-ui/react-slot';

type ButtonProps = {
  asChild?: boolean;
  children: ReactNode;
} & ButtonHTMLAttributes<HTMLButtonElement>;

function Button({ asChild, children, ...props }: ButtonProps) {
  const Comp = asChild ? Slot : 'button';
  return <Comp {...props}>{children}</Comp>;
}

// 사용: 자식 요소가 Button의 props를 상속받음
<Button asChild>
  <a href="/">링크처럼 동작하는 버튼</a>
</Button>
```

**`asChild` vs `as`**:
- `as`: 타입 추론이 복잡, prop 네이밍 충돌 가능
- `asChild`: 자식을 그대로 렌더, props가 merge됨, 더 명시적

---

## 문서화 & 시각 회귀 테스트

### Storybook

디자인 시스템의 **살아 있는 문서**. 컴포넌트를 독립적으로 개발·테스트·공유한다.

```tsx
// Button.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { Button } from './Button';

const meta: Meta<typeof Button> = {
  title: 'Components/Button',
  component: Button,
  tags: ['autodocs'], // 자동 문서 생성
  argTypes: {
    variant: {
      control: 'select',
      options: ['primary', 'secondary', 'ghost', 'destructive'],
    },
    size: {
      control: 'radio',
      options: ['sm', 'md', 'lg'],
    },
  },
};
export default meta;

type Story = StoryObj<typeof Button>;

export const Primary: Story = {
  args: { variant: 'primary', children: '확인' },
};

export const AllVariants: Story = {
  render: () => (
    <div style={{ display: 'flex', gap: 8 }}>
      <Button variant="primary">Primary</Button>
      <Button variant="secondary">Secondary</Button>
      <Button variant="ghost">Ghost</Button>
      <Button variant="destructive">Delete</Button>
    </div>
  ),
};

// Interaction Testing (play 함수)
export const ClickTest: Story = {
  args: { variant: 'primary', children: '클릭' },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const button = canvas.getByRole('button');
    await userEvent.click(button);
    await expect(button).toHaveFocus();
  },
};
```

핵심 Addon:
- **Controls**: props를 실시간 조작
- **Docs**: MDX와 결합해 자동 문서화
- **A11y**: 접근성 자동 검사 (axe-core)
- **Interactions**: play 함수로 시나리오 테스트

### 시각 회귀 (Visual Regression)

코드 변경이 **의도치 않게 UI를 깨뜨리는 것을 감지**하는 테스트.

| 도구 | 특징 | 가격 |
|------|------|------|
| **Chromatic** | Storybook 전용, TurboSnap(변경된 Story만), UI Review 워크플로 | 무료 5000 snap/월 |
| **Percy** (BrowserStack) | 범용, 크로스 브라우저, responsive 스냅샷 | 유료 |
| **Playwright Screenshots** | 자체 구축, 무료, 커스텀 가능 | 무료 |
| **Lost Pixel** | 오픈소스, Storybook/Ladle/페이지 지원 | 무료 (셀프호스트) |

CI 워크플로:

```yaml
# .github/workflows/visual-test.yml
name: Visual Regression
on: pull_request

jobs:
  chromatic:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v4
      - run: npm ci
      - uses: chromaui/action@latest
        with:
          projectToken: ${{ secrets.CHROMATIC_TOKEN }}
          onlyChanged: true  # TurboSnap
```

---

## 멀티 플랫폼 지원

### Style Dictionary

Amazon에서 만든 **토큰 변환 도구**. 하나의 JSON 소스에서 모든 플랫폼 코드를 생성한다.

```
tokens.json → Style Dictionary → CSS Variables
                                → TypeScript constants
                                → iOS Swift enum
                                → Android XML resources
                                → SCSS variables
```

설정 예제:

```json
// tokens/color/base.json
{
  "color": {
    "blue": {
      "500": { "value": "#3b82f6", "type": "color" }
    },
    "text": {
      "primary": {
        "value": "{color.gray.900}",
        "type": "color",
        "description": "주요 텍스트 색상"
      }
    }
  }
}
```

```js
// style-dictionary.config.js
import StyleDictionary from 'style-dictionary';

export default {
  source: ['tokens/**/*.json'],
  platforms: {
    css: {
      transformGroup: 'css',
      buildPath: 'dist/css/',
      files: [{
        destination: 'variables.css',
        format: 'css/variables',
        options: { outputReferences: true }, // var(--color-gray-900) 유지
      }],
    },
    ts: {
      transformGroup: 'js',
      buildPath: 'dist/ts/',
      files: [{
        destination: 'tokens.ts',
        format: 'javascript/es6',
      }],
    },
    ios: {
      transformGroup: 'ios-swift',
      buildPath: 'dist/ios/',
      files: [{
        destination: 'DesignTokens.swift',
        format: 'ios-swift/enum.swift',
      }],
    },
  },
};
```

### 디자인 ↔ 코드 동기화

```
Designer (Figma)                    Developer (Code)
    │                                     │
    │  Tokens Studio plugin               │
    │  ────────────────────►              │
    │        Push to GitHub               │
    │                                     │
    │                          Style Dictionary 빌드
    │                          자동 PR 생성
    │                                     │
    │  ◄────────────────────              │
    │    변경 사항 리뷰 & 머지             │
```

핵심 도구:
- **Figma Variables API**: Figma 네이티브 변수를 코드로 추출
- **Tokens Studio** (Figma plugin): 토큰을 JSON으로 GitHub에 Push
- **GitHub Actions**: 토큰 변경 감지 → Style Dictionary 빌드 → 자동 PR

---

## 실전 코드 예제

### CSS Custom Properties 기반 테마 시스템

```css
/* theme.css */
:root {
  /* Primitive */
  --color-blue-500: #3b82f6;
  --color-gray-900: #111827;
  --color-gray-100: #f3f4f6;
  --color-white: #ffffff;

  /* Semantic (Light - default) */
  --color-text-primary: var(--color-gray-900);
  --color-bg-page: var(--color-white);
  --color-interactive: var(--color-blue-500);
}

[data-theme="dark"] {
  --color-text-primary: var(--color-gray-100);
  --color-bg-page: var(--color-gray-900);
  --color-interactive: #60a5fa; /* blue-400 */
}

/* 시스템 설정 따르기 */
@media (prefers-color-scheme: dark) {
  :root:not([data-theme]) {
    --color-text-primary: var(--color-gray-100);
    --color-bg-page: var(--color-gray-900);
  }
}
```

```tsx
// ThemeProvider.tsx
function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<'light' | 'dark'>(() => {
    return (localStorage.getItem('theme') as 'light' | 'dark')
      || (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  });

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    localStorage.setItem('theme', theme);
  }, [theme]);

  return (
    <ThemeContext.Provider value={{ theme, setTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}
```

### Radix UI + Tailwind로 Select 구현

```tsx
import * as SelectPrimitive from '@radix-ui/react-select';
import { ChevronDown, Check } from 'lucide-react';
import { cn } from '@/lib/utils';

const Select = SelectPrimitive.Root;
const SelectTrigger = forwardRef<
  ElementRef<typeof SelectPrimitive.Trigger>,
  ComponentPropsWithoutRef<typeof SelectPrimitive.Trigger>
>(({ className, children, ...props }, ref) => (
  <SelectPrimitive.Trigger
    ref={ref}
    className={cn(
      'flex h-10 w-full items-center justify-between rounded-md',
      'border border-[var(--input-border-color)] bg-[var(--input-bg)]',
      'px-3 py-2 text-sm',
      'focus:outline-none focus:ring-2 focus:ring-[var(--color-interactive)]',
      'disabled:cursor-not-allowed disabled:opacity-50',
      className
    )}
    {...props}
  >
    {children}
    <SelectPrimitive.Icon asChild>
      <ChevronDown className="h-4 w-4 opacity-50" />
    </SelectPrimitive.Icon>
  </SelectPrimitive.Trigger>
));

const SelectItem = forwardRef<
  ElementRef<typeof SelectPrimitive.Item>,
  ComponentPropsWithoutRef<typeof SelectPrimitive.Item>
>(({ className, children, ...props }, ref) => (
  <SelectPrimitive.Item
    ref={ref}
    className={cn(
      'relative flex w-full cursor-default select-none items-center',
      'rounded-sm py-1.5 pl-8 pr-2 text-sm outline-none',
      'focus:bg-gray-100 dark:focus:bg-gray-800',
      'data-[disabled]:pointer-events-none data-[disabled]:opacity-50',
      className
    )}
    {...props}
  >
    <span className="absolute left-2 flex h-3.5 w-3.5 items-center justify-center">
      <SelectPrimitive.ItemIndicator>
        <Check className="h-4 w-4" />
      </SelectPrimitive.ItemIndicator>
    </span>
    <SelectPrimitive.ItemText>{children}</SelectPrimitive.ItemText>
  </SelectPrimitive.Item>
));
```

---

## 운영 & 거버넌스

### 버저닝 전략

Semantic Versioning (semver)을 따르되, 디자인 시스템에 맞게 해석:

| 변경 유형 | 버전 | 예시 |
|-----------|------|------|
| 새 컴포넌트, 새 variant 추가 | minor | `1.3.0 → 1.4.0` |
| 버그 수정, 접근성 개선 | patch | `1.4.0 → 1.4.1` |
| API 변경, prop 삭제, 토큰 이름 변경 | **major** | `1.4.1 → 2.0.0` |
| 시각적 변경 (의도된 디자인 변경) | minor or major | 영향도에 따라 판단 |

### Contribution 가이드라인

```
1. Issue 생성 (버그 / 기능 요청 / RFC)
2. RFC 승인 (major 변경 시)
3. Branch 생성 & 구현
4. Storybook Story 작성
5. 시각 회귀 테스트 통과
6. 접근성 검사 통과
7. 코드 리뷰 (최소 2인)
8. Changeset 작성 (changelog 자동 생성)
9. 머지 → 자동 배포
```

### RFC 프로세스

새 컴포넌트나 브레이킹 체인지를 제안할 때:
1. **Problem Statement**: 왜 필요한가
2. **Proposed Solution**: API 설계 초안 (사용 예제 포함)
3. **Alternatives**: 검토한 대안들
4. **Migration Path**: 기존 사용자의 마이그레이션 방법
5. **Open Questions**: 결정되지 않은 사항

### Adoption 지표

- 어떤 팀이 어떤 버전을 쓰는지 추적
- 컴포넌트별 사용 빈도 (import 분석)
- 커스텀 오버라이드 빈도 → 디자인 시스템의 간극 발견
- Deprecated 컴포넌트의 남은 사용처

---

## 면접 포인트

### Q. 디자인 토큰이란 무엇이고 왜 계층화하는가?

디자인 토큰은 색상·크기·간격 등 디자인 결정을 플랫폼 독립적인 key-value로 저장한 것이다. 계층화(Primitive → Semantic → Component)하는 이유는:
- **Primitive**만으로는 테마 전환이 불가능 (`blue-500`이 버튼인지 링크인지 알 수 없음)
- **Semantic** 계층이 있어야 "다크 모드에서 텍스트는 밝아야 한다"를 일관되게 적용 가능
- **Component** 계층은 특정 컴포넌트만 예외적으로 조정할 때 유용

### Q. Headless UI란? 언제 사용하는가?

로직·접근성·상태 관리만 제공하고 스타일은 제공하지 않는 컴포넌트 라이브러리. 자체 디자인 언어가 있고, 높은 커스텀 자유도가 필요하며, WAI-ARIA 패턴을 직접 구현하기 어려울 때 사용한다.

### Q. 디자인 시스템의 버저닝은 어떻게 하는가?

semver를 따른다. prop 삭제, 토큰 이름 변경은 major. 새 컴포넌트/variant 추가는 minor. 버그 수정은 patch. Changeset을 사용해 PR마다 변경 범위를 기록하고, 머지 시 자동으로 버전을 결정한다.

### Q. 시각 회귀 테스트란 무엇이고 왜 필요한가?

UI의 스크린샷을 기준선(baseline)과 비교하여 의도치 않은 시각적 변경을 감지하는 테스트. CSS 한 줄 변경이 수십 개 컴포넌트에 영향을 줄 수 있기 때문에, 사람의 눈이 모든 화면을 확인하기 어려운 부분을 자동화한다.

### Q. Compound Component 패턴을 설명하시오.

관련 컴포넌트를 하나의 부모 아래 묶고, Context를 통해 상태를 암묵적으로 공유하는 패턴. `<Select>`, `<Select.Trigger>`, `<Select.Item>`처럼 선언적 API를 제공하면서 내부 상태를 캡슐화할 수 있다.

### Q. 다크 모드를 CSS 변수로 구현하는 방법은?

1. Primitive 토큰을 `:root`에 정의
2. Semantic 토큰을 라이트/다크 각각 선언 (`[data-theme="dark"]`)
3. `prefers-color-scheme` 미디어 쿼리로 시스템 설정 대응
4. JS에서 `data-theme` 속성을 토글하면 모든 Semantic 토큰이 일괄 전환

---

## 참고 자료

- [Design Tokens W3C Community Group](https://design-tokens.github.io/community-group/format/) — 토큰 표준 스펙
- [Style Dictionary Docs](https://amzn.github.io/style-dictionary/) — 멀티 플랫폼 토큰 빌드
- [Radix UI](https://www.radix-ui.com/) — Headless 컴포넌트 레퍼런스
- [CVA (Class Variance Authority)](https://cva.style/) — Tailwind variant 관리
- [Storybook](https://storybook.js.org/) — 컴포넌트 문서화
- [Chromatic](https://www.chromatic.com/) — 시각 회귀 테스트
- [Tokens Studio](https://tokens.studio/) — Figma ↔ 코드 동기화
- Brad Frost, *Atomic Design* — 디자인 시스템 설계 철학
- Nathan Curtis, *Modular Web Design* — 컴포넌트 기반 디자인 시스템
