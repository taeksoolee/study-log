# Proxy (프록시 패턴)

## 목차
1. [개념](#1-개념)
2. [JS Proxy 객체와의 연결](#2-js-proxy-객체와의-연결)
3. [캐싱 프록시 예제](#3-캐싱-프록시-예제)
4. [접근 제어 프록시 예제](#4-접근-제어-프록시-예제)
5. [지연 로딩(Lazy Loading) 프록시](#5-지연-로딩lazy-loading-프록시)
6. [프론트엔드 실무 사례 — Vue 반응성 시스템](#6-프론트엔드-실무-사례--vue-반응성-시스템)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 개념

> 다른 객체에 대한 **접근을 제어하는 대리자(surrogate)** 또는 자리채우미(placeholder)를 제공한다.

프록시는 실제 객체와 동일한 인터페이스를 구현하여 클라이언트가 구분할 수 없게 한다.

**프록시의 종류**
- **가상 프록시 (Virtual)**: 비용이 큰 객체의 생성을 지연 (Lazy Loading)
- **보호 프록시 (Protection)**: 접근 권한 제어
- **캐싱 프록시 (Caching)**: 결과를 캐시하여 재계산 방지
- **원격 프록시 (Remote)**: 원격 서비스의 로컬 대리자

**구조**
```
Client → Subject (interface) → RealSubject
                         ↖ Proxy (같은 인터페이스 구현)
                              └─ realSubject: RealSubject
```

---

## 2. JS Proxy 객체와의 연결

ES6의 `Proxy` 내장 객체는 프록시 패턴을 언어 수준에서 지원한다.

```typescript
const target = {
  name: 'Alice',
  age: 30,
};

const handler: ProxyHandler<typeof target> = {
  // get 트랩 — 속성 접근 가로채기
  get(obj, prop) {
    console.log(`[Proxy] ${String(prop)} 접근`);
    return Reflect.get(obj, prop);
  },

  // set 트랩 — 속성 설정 가로채기
  set(obj, prop, value) {
    console.log(`[Proxy] ${String(prop)} = ${value} 설정`);
    if (prop === 'age' && typeof value !== 'number') {
      throw new TypeError('age는 숫자여야 합니다');
    }
    return Reflect.set(obj, prop, value);
  },

  // has 트랩 — in 연산자 가로채기
  has(obj, prop) {
    console.log(`[Proxy] ${String(prop)} in 검사`);
    return Reflect.has(obj, prop);
  },
};

const proxy = new Proxy(target, handler);
console.log(proxy.name);   // [Proxy] name 접근 → 'Alice'
proxy.age = 31;            // [Proxy] age = 31 설정
// proxy.age = 'thirty';  // TypeError!
console.log('name' in proxy); // [Proxy] name in 검사 → true
```

---

## 3. 캐싱 프록시 예제

```typescript
interface DataService {
  fetchUser(id: number): Promise<{ id: number; name: string; email: string }>;
  fetchPosts(userId: number): Promise<{ id: number; title: string }[]>;
}

class RealDataService implements DataService {
  async fetchUser(id: number) {
    console.log(`[API] GET /users/${id}`);
    // 실제로는 fetch 호출
    return { id, name: 'Alice', email: 'alice@example.com' };
  }

  async fetchPosts(userId: number) {
    console.log(`[API] GET /users/${userId}/posts`);
    return [{ id: 1, title: '첫 번째 글' }];
  }
}

// 캐싱 프록시
class CachingDataServiceProxy implements DataService {
  private cache = new Map<string, { data: any; expires: number }>();
  private ttl: number;

  constructor(
    private realService: DataService,
    ttlSeconds = 60,
  ) {
    this.ttl = ttlSeconds * 1000;
  }

  private getCached<T>(key: string): T | null {
    const entry = this.cache.get(key);
    if (entry && entry.expires > Date.now()) {
      console.log(`[Cache] Hit: ${key}`);
      return entry.data;
    }
    return null;
  }

  private setCache(key: string, data: any): void {
    this.cache.set(key, { data, expires: Date.now() + this.ttl });
  }

  async fetchUser(id: number) {
    const key = `user:${id}`;
    const cached = this.getCached<Awaited<ReturnType<DataService['fetchUser']>>>(key);
    if (cached) return cached;

    const result = await this.realService.fetchUser(id);
    this.setCache(key, result);
    return result;
  }

  async fetchPosts(userId: number) {
    const key = `posts:${userId}`;
    const cached = this.getCached<Awaited<ReturnType<DataService['fetchPosts']>>>(key);
    if (cached) return cached;

    const result = await this.realService.fetchPosts(userId);
    this.setCache(key, result);
    return result;
  }
}

// 사용 — 인터페이스 동일, 캐싱은 투명
const dataService: DataService = new CachingDataServiceProxy(new RealDataService());

await dataService.fetchUser(1); // [API] GET /users/1
await dataService.fetchUser(1); // [Cache] Hit: user:1 (캐시!)
await dataService.fetchUser(2); // [API] GET /users/2 (다른 사용자)
```

---

## 4. 접근 제어 프록시 예제

```typescript
interface AdminService {
  deleteUser(id: number): void;
  banUser(id: number): void;
  viewLogs(): string[];
}

class RealAdminService implements AdminService {
  deleteUser(id: number): void { console.log(`사용자 ${id} 삭제`); }
  banUser(id: number): void { console.log(`사용자 ${id} 정지`); }
  viewLogs(): string[] { return ['log1', 'log2']; }
}

type Role = 'admin' | 'moderator' | 'viewer';

const PERMISSIONS: Record<Role, (keyof AdminService)[]> = {
  admin: ['deleteUser', 'banUser', 'viewLogs'],
  moderator: ['banUser', 'viewLogs'],
  viewer: ['viewLogs'],
};

class AuthProxy implements AdminService {
  constructor(
    private service: AdminService,
    private role: Role,
  ) {}

  private checkPermission(action: keyof AdminService): void {
    if (!PERMISSIONS[this.role].includes(action)) {
      throw new Error(`권한 없음: ${this.role}는 ${action} 불가`);
    }
  }

  deleteUser(id: number): void {
    this.checkPermission('deleteUser');
    this.service.deleteUser(id);
  }

  banUser(id: number): void {
    this.checkPermission('banUser');
    this.service.banUser(id);
  }

  viewLogs(): string[] {
    this.checkPermission('viewLogs');
    return this.service.viewLogs();
  }
}

const moderatorService = new AuthProxy(new RealAdminService(), 'moderator');
moderatorService.banUser(1);     // 사용자 1 정지
moderatorService.viewLogs();     // ['log1', 'log2']
// moderatorService.deleteUser(1); // Error: 권한 없음
```

---

## 5. 지연 로딩(Lazy Loading) 프록시

```typescript
// 이미지 지연 로딩 가상 프록시
interface Image {
  display(): void;
  getSize(): { width: number; height: number };
}

class RealImage implements Image {
  private imageData: ImageData | null = null;

  constructor(private src: string) {
    // 생성 시 즉시 로드 (비용 큼)
    console.log(`[RealImage] 로딩 시작: ${src}`);
    this.load();
  }

  private load(): void {
    console.log(`[RealImage] 로딩 완료: ${this.src}`);
    // 실제 이미지 로드 처리
  }

  display(): void { console.log(`[RealImage] 표시: ${this.src}`); }
  getSize() { return { width: 1920, height: 1080 }; }
}

// 지연 로딩 프록시 — 실제 사용 시점까지 로딩 지연
class LazyImageProxy implements Image {
  private realImage: RealImage | null = null;

  constructor(private src: string) {
    // 생성 시에는 로드하지 않음!
    console.log(`[LazyProxy] 프록시 생성: ${src}`);
  }

  private getRealImage(): RealImage {
    if (!this.realImage) {
      this.realImage = new RealImage(this.src); // 최초 접근 시 생성
    }
    return this.realImage;
  }

  display(): void {
    this.getRealImage().display(); // 이 시점에 실제 로드
  }

  getSize() {
    return this.getRealImage().getSize();
  }
}

// 100개 이미지 프록시 생성 — 로딩 없음
const images: Image[] = Array.from({ length: 100 }, (_, i) =>
  new LazyImageProxy(`/images/photo-${i}.jpg`)
);

// 첫 번째 이미지만 실제 로드
images[0].display();
```

---

## 6. 프론트엔드 실무 사례 — Vue 반응성 시스템

Vue 3의 반응성 시스템은 ES6 `Proxy`를 기반으로 한다.

```typescript
// Vue 3의 reactive() 내부 원리 (단순화)
function reactive<T extends object>(target: T): T {
  return new Proxy(target, {
    get(obj, key) {
      track(obj, key); // 의존성 추적
      const value = Reflect.get(obj, key);
      return typeof value === 'object' ? reactive(value) : value;
    },
    set(obj, key, value) {
      const result = Reflect.set(obj, key, value);
      trigger(obj, key); // 변경 알림 → 컴포넌트 리렌더
      return result;
    },
  });
}

const state = reactive({ count: 0, user: { name: 'Alice' } });
state.count++; // Proxy set 트랩 → 화면 자동 업데이트
```

---

## 7. 면접 포인트

**Q1. 프록시 패턴이란 무엇인가요?**
> 실제 객체에 대한 접근을 제어하는 대리 객체를 제공하는 패턴입니다. 같은 인터페이스를 구현하여 클라이언트가 프록시인지 실제 객체인지 구분하지 못하게 합니다.

**Q2. ES6 Proxy와 프록시 패턴의 관계는?**
> ES6 `Proxy`는 프록시 패턴을 JavaScript 언어 수준에서 구현한 것입니다. `get`, `set`, `has` 등의 트랩으로 객체 접근을 세밀하게 제어할 수 있습니다.

**Q3. Vue 3의 반응성 시스템과 프록시 패턴의 관계를 설명해주세요.**
> Vue 3는 `reactive()`에서 ES6 `Proxy`를 사용하여 상태 객체를 감쌉니다. `set` 트랩에서 변경을 감지하고 컴포넌트에 알려 리렌더링을 트리거합니다.

**Q4. 데코레이터와 프록시의 차이는?**
> 데코레이터는 기능을 추가하는 것이 목적입니다. 프록시는 접근 제어(캐싱, 지연 로딩, 권한)가 목적입니다. 구조는 유사하지만 의도가 다릅니다.

---

[← Flyweight](./06-flyweight.md) | [← 구조 패턴 목차](./README.md) | [행동 패턴으로 →](../behavioral/README.md)
