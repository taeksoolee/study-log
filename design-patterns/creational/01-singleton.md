# Singleton (싱글톤 패턴)

## 목차
1. [개념](#1-개념)
2. [전통적 Class 구현](#2-전통적-class-구현)
3. [JS 모듈 패턴으로 자연스럽게](#3-js-모듈-패턴으로-자연스럽게)
4. [실용 예시 — 설정 관리 & 로거](#4-실용-예시--설정-관리--로거)
5. [문제점 — 테스트의 어려움](#5-문제점--테스트의-어려움)
6. [면접 포인트](#6-면접-포인트)

---

## 1. 개념

> 클래스의 인스턴스가 **단 하나만** 존재하도록 보장하고, 그 인스턴스에 전역 접근점을 제공한다.

**언제 쓰는가?**
- 애플리케이션 전체에서 공유해야 하는 자원 (설정, 로거, DB 연결, 캐시)
- 동일 인스턴스가 여러 곳에서 사용되어야 할 때
- 전역 상태를 하나의 진입점으로 관리하고 싶을 때

**구조 다이어그램**
```
Client ──→ Singleton
              │
              ├─ instance: Singleton (static, private)
              ├─ getInstance(): Singleton (static, public)
              └─ businessLogic()
```

---

## 2. 전통적 Class 구현

```typescript
class Singleton {
  private static instance: Singleton | null = null;
  private value: number = 0;

  // 외부에서 new 호출 금지
  private constructor() {
    console.log('Singleton 인스턴스 생성');
  }

  public static getInstance(): Singleton {
    if (!Singleton.instance) {
      Singleton.instance = new Singleton();
    }
    return Singleton.instance;
  }

  public increment(): void {
    this.value++;
  }

  public getValue(): number {
    return this.value;
  }
}

// 사용
const a = Singleton.getInstance();
const b = Singleton.getInstance();

a.increment();
console.log(b.getValue()); // 1 — a와 b는 동일 인스턴스

console.log(a === b); // true
```

### Thread-Safe (Node.js 환경에서의 주의)

Node.js는 단일 스레드이므로 기본적으로 안전하다.
하지만 Worker Threads를 사용한다면 각 Worker가 별도의 V8 인스턴스를 갖기 때문에
싱글톤이 각각 별도로 만들어진다는 점을 주의해야 한다.

---

## 3. JS 모듈 패턴으로 자연스럽게

JavaScript ES 모듈(ESM)은 **자체적으로 싱글톤**처럼 동작한다.
같은 모듈을 여러 번 `import`해도 모듈 코드는 한 번만 실행되며, 동일한 객체를 반환한다.

```javascript
// config.js — 이 파일 자체가 싱글톤
let settings = {
  apiUrl: 'https://api.example.com',
  timeout: 5000,
  debug: false,
};

export function getConfig() {
  return settings;
}

export function updateConfig(newSettings) {
  settings = { ...settings, ...newSettings };
}
```

```javascript
// moduleA.js
import { getConfig, updateConfig } from './config.js';
updateConfig({ debug: true });

// moduleB.js
import { getConfig } from './config.js';
console.log(getConfig().debug); // true — 동일한 settings 참조
```

이 방식이 Class 기반 싱글톤보다 JavaScript 다운 접근법이다.

---

## 4. 실용 예시 — 설정 관리 & 로거

### 4-1. 앱 설정 관리자

```typescript
interface AppConfig {
  apiUrl: string;
  locale: string;
  theme: 'light' | 'dark';
}

class ConfigManager {
  private static instance: ConfigManager;
  private config: AppConfig = {
    apiUrl: 'https://api.example.com',
    locale: 'ko-KR',
    theme: 'light',
  };

  private constructor() {}

  static getInstance(): ConfigManager {
    if (!ConfigManager.instance) {
      ConfigManager.instance = new ConfigManager();
    }
    return ConfigManager.instance;
  }

  get<K extends keyof AppConfig>(key: K): AppConfig[K] {
    return this.config[key];
  }

  set<K extends keyof AppConfig>(key: K, value: AppConfig[K]): void {
    this.config[key] = value;
  }
}

// 사용
const config = ConfigManager.getInstance();
config.set('theme', 'dark');
console.log(ConfigManager.getInstance().get('theme')); // 'dark'
```

### 4-2. 로거 (Logger)

```typescript
type LogLevel = 'info' | 'warn' | 'error';

class Logger {
  private static instance: Logger;
  private logs: Array<{ level: LogLevel; message: string; time: Date }> = [];

  private constructor() {}

  static getInstance(): Logger {
    if (!Logger.instance) {
      Logger.instance = new Logger();
    }
    return Logger.instance;
  }

  log(level: LogLevel, message: string): void {
    const entry = { level, message, time: new Date() };
    this.logs.push(entry);
    console[level](`[${entry.time.toISOString()}] ${message}`);
  }

  getLogs() {
    return [...this.logs];
  }
}

const logger = Logger.getInstance();
logger.log('info', '앱 시작');
logger.log('warn', '메모리 부족 경고');
```

---

## 5. 문제점 — 테스트의 어려움

싱글톤의 가장 큰 단점은 **테스트 격리가 어렵다**는 것이다.

```typescript
// 문제: 이전 테스트의 상태가 다음 테스트에 영향을 줌
describe('ConfigManager', () => {
  it('테스트 A', () => {
    ConfigManager.getInstance().set('theme', 'dark');
    // ...
  });

  it('테스트 B', () => {
    // theme이 여전히 'dark'! 상태가 공유됨
    const theme = ConfigManager.getInstance().get('theme');
  });
});
```

**해결책**
1. 테스트용 `reset()` 메서드 추가
2. DI(Dependency Injection) 컨테이너 활용
3. 모듈 모킹 (`jest.mock()`)

```typescript
// 테스트를 위한 리셋 메서드 추가
class ConfigManager {
  // ...
  static resetForTest(): void {
    ConfigManager.instance = null as any;
  }
}

afterEach(() => {
  ConfigManager.resetForTest();
});
```

---

## 6. 면접 포인트

**Q1. 싱글톤 패턴이란 무엇이고, 언제 사용하나요?**
> 클래스의 인스턴스를 하나로 제한하는 패턴입니다. 전역 설정, 로거, DB 연결풀처럼 앱 전체에서 공유해야 하는 자원에 사용합니다.

**Q2. JavaScript에서 싱글톤을 구현하는 가장 자연스러운 방법은?**
> ES 모듈이 기본적으로 싱글톤처럼 동작합니다. 동일 모듈을 여러 번 import해도 코드는 한 번만 실행되고 동일 객체가 반환됩니다.

**Q3. 싱글톤 패턴의 단점은?**
> - 전역 상태 의존성 → 코드 결합도 증가
> - 테스트 격리 어려움 → 상태가 테스트 간 공유됨
> - 단일 책임 원칙 위반 가능성 (인스턴스 관리 + 비즈니스 로직 혼재)
> - 멀티스레드 환경에서 동기화 필요

**Q4. Redux store와 싱글톤의 관계는?**
> Redux store는 앱에서 하나만 생성되고 전역에서 접근하는 싱글톤 패턴의 실제 사례입니다.

---

[← 생성 패턴 목차](./README.md) | [다음: Factory Method →](./02-factory-method.md)
