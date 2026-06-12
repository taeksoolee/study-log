# Adapter (어댑터 패턴)

## 목차
1. [개념](#1-개념)
2. [구버전 API를 새 인터페이스로 래핑](#2-구버전-api를-새-인터페이스로-래핑)
3. [클래스 어댑터 vs 객체 어댑터](#3-클래스-어댑터-vs-객체-어댑터)
4. [실용 예시 — 서드파티 라이브러리 통합](#4-실용-예시--서드파티-라이브러리-통합)
5. [프론트엔드 실무 사례](#5-프론트엔드-실무-사례)
6. [면접 포인트](#6-면접-포인트)

---

## 1. 개념

> 호환되지 않는 인터페이스를 가진 객체들이 **협력할 수 있도록 변환 레이어**를 제공한다.

현실의 전원 어댑터처럼: 220V 콘센트에 110V 기기를 연결하는 어댑터.
코드에서는: 기존 코드를 수정하지 않고 새 코드와 구 코드를 연결한다.

**언제 쓰는가?**
- 기존 코드를 변경할 수 없는 서드파티 라이브러리를 사용할 때
- 구버전 API를 새 인터페이스로 점진적으로 마이그레이션할 때
- 서로 다른 인터페이스를 가진 여러 클래스를 통합할 때

**구조**
```
Client → Target (interface) → Adapter → Adaptee (기존 코드)
```

---

## 2. 구버전 API를 새 인터페이스로 래핑

```typescript
// ─── 구버전 코드 (변경 불가) ─────────────────────────────
class OldUserService {
  fetchUserData(userId: number): {
    user_name: string;
    user_email: string;
    user_age: number;
  } {
    // 레거시 DB에서 스네이크_케이스로 반환
    return {
      user_name: 'Alice',
      user_email: 'alice@example.com',
      user_age: 30,
    };
  }

  saveUserData(data: { user_name: string; user_email: string }): void {
    console.log('구버전 저장:', data);
  }
}

// ─── 새 인터페이스 (앱 전체에서 사용하는 표준) ──────────
interface UserService {
  getUser(id: number): { name: string; email: string; age: number };
  saveUser(data: { name: string; email: string }): void;
}

// ─── 어댑터 ─────────────────────────────────────────────
class UserServiceAdapter implements UserService {
  private oldService: OldUserService;

  constructor(oldService: OldUserService) {
    this.oldService = oldService;
  }

  getUser(id: number): { name: string; email: string; age: number } {
    const raw = this.oldService.fetchUserData(id);
    // 스네이크_케이스 → 카멜케이스 변환
    return {
      name: raw.user_name,
      email: raw.user_email,
      age: raw.user_age,
    };
  }

  saveUser(data: { name: string; email: string }): void {
    this.oldService.saveUserData({
      user_name: data.name,
      user_email: data.email,
    });
  }
}

// ─── 클라이언트 코드 ─────────────────────────────────────
const userService: UserService = new UserServiceAdapter(new OldUserService());

const user = userService.getUser(1);
console.log(user); // { name: 'Alice', email: 'alice@example.com', age: 30 }
userService.saveUser({ name: 'Bob', email: 'bob@example.com' });
```

---

## 3. 클래스 어댑터 vs 객체 어댑터

```typescript
// 객체 어댑터 — 합성 사용 (권장)
class ObjectAdapter implements Target {
  constructor(private adaptee: Adaptee) {}
  request() {
    return this.adaptee.specificRequest();
  }
}

// 클래스 어댑터 — 다중 상속 사용 (TypeScript에서는 제한적)
// TypeScript는 다중 상속을 지원하지 않으므로 믹스인이나 인터페이스로 처리
class ClassAdapter extends Adaptee implements Target {
  request() {
    return this.specificRequest();
  }
}
```

**비교**

| 구분 | 객체 어댑터 | 클래스 어댑터 |
|------|------------|--------------|
| 방법 | 합성 | 상속 |
| 유연성 | 높음 (런타임 교체 가능) | 낮음 |
| 접근 | Adaptee의 public만 접근 | protected도 접근 가능 |
| 권장도 | 권장 | 제한적으로 사용 |

---

## 4. 실용 예시 — 서드파티 라이브러리 통합

로컬 스토리지 어댑터: 스토리지 구현체를 교체 가능하게 만든다.

```typescript
// 앱에서 사용하는 표준 스토리지 인터페이스
interface StorageAdapter {
  get<T>(key: string): T | null;
  set<T>(key: string, value: T): void;
  remove(key: string): void;
  clear(): void;
}

// LocalStorage 어댑터
class LocalStorageAdapter implements StorageAdapter {
  get<T>(key: string): T | null {
    const item = localStorage.getItem(key);
    if (!item) return null;
    try {
      return JSON.parse(item) as T;
    } catch {
      return item as unknown as T;
    }
  }

  set<T>(key: string, value: T): void {
    localStorage.setItem(key, JSON.stringify(value));
  }

  remove(key: string): void {
    localStorage.removeItem(key);
  }

  clear(): void {
    localStorage.clear();
  }
}

// SessionStorage 어댑터
class SessionStorageAdapter implements StorageAdapter {
  get<T>(key: string): T | null {
    const item = sessionStorage.getItem(key);
    return item ? JSON.parse(item) : null;
  }
  set<T>(key: string, value: T): void {
    sessionStorage.setItem(key, JSON.stringify(value));
  }
  remove(key: string): void { sessionStorage.removeItem(key); }
  clear(): void { sessionStorage.clear(); }
}

// 인메모리 어댑터 (테스트용)
class MemoryStorageAdapter implements StorageAdapter {
  private store = new Map<string, string>();
  get<T>(key: string): T | null {
    const item = this.store.get(key);
    return item ? JSON.parse(item) : null;
  }
  set<T>(key: string, value: T): void {
    this.store.set(key, JSON.stringify(value));
  }
  remove(key: string): void { this.store.delete(key); }
  clear(): void { this.store.clear(); }
}

// 사용 — 환경에 따라 어댑터만 교체
const storage: StorageAdapter =
  typeof window !== 'undefined'
    ? new LocalStorageAdapter()
    : new MemoryStorageAdapter(); // SSR/테스트 환경

storage.set('user', { name: 'Alice' });
console.log(storage.get('user')); // { name: 'Alice' }
```

---

## 5. 프론트엔드 실무 사례

### Axios 인터셉터 — 어댑터 패턴

```typescript
// axios 응답을 앱 표준 형식으로 변환하는 어댑터
const apiClient = axios.create({ baseURL: 'https://api.example.com' });

apiClient.interceptors.response.use(
  (response) => {
    // 서버 응답 형식 → 앱 표준 형식으로 변환 (어댑터 역할)
    return {
      data: response.data.result,
      meta: response.data.pagination,
      status: response.status,
    };
  },
  (error) => {
    // 에러 형식도 표준화
    throw new AppError(error.response?.data?.message || '알 수 없는 오류');
  }
);
```

### 외부 지도 SDK 어댑터

```typescript
interface MapService {
  showMap(container: HTMLElement): void;
  addMarker(lat: number, lng: number, label: string): void;
  setCenter(lat: number, lng: number): void;
}

// Google Maps 어댑터
class GoogleMapsAdapter implements MapService {
  private map: google.maps.Map | null = null;
  showMap(container: HTMLElement) {
    this.map = new google.maps.Map(container, { zoom: 14 });
  }
  addMarker(lat: number, lng: number, label: string) {
    new google.maps.Marker({ position: { lat, lng }, map: this.map, title: label });
  }
  setCenter(lat: number, lng: number) {
    this.map?.setCenter({ lat, lng });
  }
}
```

---

## 6. 면접 포인트

**Q1. 어댑터 패턴이란 무엇인가요?**
> 호환되지 않는 인터페이스를 가진 두 객체를 연결하는 변환 레이어입니다. 기존 코드를 수정하지 않고 새 인터페이스로 사용할 수 있게 해줍니다.

**Q2. 어댑터와 데코레이터 패턴의 차이는?**
> 어댑터는 인터페이스를 변환합니다. 데코레이터는 인터페이스를 유지하면서 기능을 추가합니다.

**Q3. 어댑터와 파사드 패턴의 차이는?**
> 어댑터는 두 인터페이스를 연결합니다. 파사드는 복잡한 서브시스템을 단순한 인터페이스로 감춥니다. 파사드는 새 인터페이스를 정의하고, 어댑터는 기존 인터페이스를 다른 인터페이스로 변환합니다.

**Q4. 실무에서 어댑터를 사용한 경험이 있나요?**
> Axios 인터셉터, 스토리지 추상화, 외부 지도/결제 SDK 통합이 대표적인 예시입니다. 서드파티 라이브러리 교체 시 내부 코드를 보호하기 위해 어댑터 레이어를 둡니다.

---

[← 구조 패턴 목차](./README.md) | [다음: Bridge →](./02-bridge.md)
