# Facade (파사드 패턴)

## 목차
1. [개념](#1-개념)
2. [복잡한 서브시스템 단순화 예제](#2-복잡한-서브시스템-단순화-예제)
3. [API 래퍼 예시](#3-api-래퍼-예시)
4. [SDK 초기화 파사드](#4-sdk-초기화-파사드)
5. [프론트엔드 실무 사례](#5-프론트엔드-실무-사례)
6. [면접 포인트](#6-면접-포인트)

---

## 1. 개념

> 복잡한 서브시스템에 대한 **단순화된 인터페이스**를 제공한다.

파사드(Facade)는 건물의 정면(외관)을 뜻하는 프랑스어다.
건물 내부 구조를 감추고 외부에 깔끔한 인터페이스만 노출하는 것과 같다.

**언제 쓰는가?**
- 복잡한 서브시스템을 간단하게 사용하고 싶을 때
- 서브시스템 의존성를 최소화하고 싶을 때
- 레거시 코드를 점진적으로 교체할 때 (스트랭글러 패턴)

**구조**
```
Client → Facade → SubsystemA
                → SubsystemB
                → SubsystemC
```

**어댑터 vs 파사드**
- 어댑터: 기존 인터페이스 → 다른 인터페이스 (1:1 변환)
- 파사드: 복잡한 여러 인터페이스 → 단순 인터페이스 (N:1 단순화)

---

## 2. 복잡한 서브시스템 단순화 예제

주문 처리 시스템: 재고확인 → 결제 → 배송 → 알림의 복잡한 흐름을 파사드로 단순화한다.

```typescript
// ─── 서브시스템들 (각각 복잡한 내부 로직 보유) ──────────

class InventoryService {
  checkStock(productId: string, quantity: number): boolean {
    console.log(`[재고] ${productId} × ${quantity} 확인 중...`);
    return true; // 재고 있다고 가정
  }

  reserve(productId: string, quantity: number): string {
    console.log(`[재고] ${productId} × ${quantity} 예약`);
    return `RESERVE-${Date.now()}`;
  }

  release(reservationId: string): void {
    console.log(`[재고] 예약 ${reservationId} 해제`);
  }
}

class PaymentService {
  validateCard(cardToken: string): boolean {
    console.log(`[결제] 카드 유효성 검사: ${cardToken}`);
    return true;
  }

  charge(cardToken: string, amount: number): string {
    console.log(`[결제] ${amount}원 청구`);
    return `TXN-${Date.now()}`;
  }

  refund(transactionId: string): void {
    console.log(`[결제] 거래 ${transactionId} 환불`);
  }
}

class ShippingService {
  calculateCost(address: string): number {
    return address.startsWith('서울') ? 2500 : 4000;
  }

  createShipment(orderId: string, address: string): string {
    console.log(`[배송] 주문 ${orderId} → ${address}`);
    return `SHIP-${Date.now()}`;
  }
}

class NotificationService {
  sendEmail(to: string, subject: string, body: string): void {
    console.log(`[이메일] to: ${to}, subject: ${subject}`);
  }

  sendSMS(to: string, message: string): void {
    console.log(`[SMS] to: ${to}: ${message}`);
  }
}

// ─── 파사드 ──────────────────────────────────────────────
interface OrderDetails {
  productId: string;
  quantity: number;
  cardToken: string;
  address: string;
  userEmail: string;
  userPhone: string;
}

class OrderFacade {
  private inventory = new InventoryService();
  private payment = new PaymentService();
  private shipping = new ShippingService();
  private notification = new NotificationService();

  // 클라이언트는 이 하나의 메서드만 알면 된다
  async placeOrder(details: OrderDetails): Promise<{ orderId: string; success: boolean }> {
    const orderId = `ORDER-${Date.now()}`;

    // 1. 재고 확인
    if (!this.inventory.checkStock(details.productId, details.quantity)) {
      throw new Error('재고 부족');
    }
    const reservationId = this.inventory.reserve(details.productId, details.quantity);

    // 2. 결제
    const shippingCost = this.shipping.calculateCost(details.address);
    let transactionId: string;
    try {
      this.payment.validateCard(details.cardToken);
      transactionId = this.payment.charge(details.cardToken, shippingCost);
    } catch (err) {
      this.inventory.release(reservationId);
      throw new Error('결제 실패');
    }

    // 3. 배송 등록
    const shipmentId = this.shipping.createShipment(orderId, details.address);

    // 4. 알림
    this.notification.sendEmail(
      details.userEmail,
      '주문 확인',
      `주문 ${orderId}이 접수되었습니다.`
    );
    this.notification.sendSMS(
      details.userPhone,
      `[주문완료] ${orderId} 배송번호: ${shipmentId}`
    );

    return { orderId, success: true };
  }
}

// ─── 클라이언트 코드 — 파사드 덕분에 단순 ─────────────────
const orderFacade = new OrderFacade();
const result = await orderFacade.placeOrder({
  productId: 'PROD-001',
  quantity: 2,
  cardToken: 'tok_visa_xxxx',
  address: '서울 강남구 테헤란로 1',
  userEmail: 'user@example.com',
  userPhone: '010-1234-5678',
});
console.log(result); // { orderId: 'ORDER-...', success: true }
```

---

## 3. API 래퍼 예시

```typescript
// axios + 인증 + 에러 핸들링 + 재시도를 파사드로 통합
class ApiClient {
  private client: AxiosInstance;

  constructor(baseURL: string) {
    this.client = axios.create({
      baseURL,
      timeout: 10000,
      headers: { 'Content-Type': 'application/json' },
    });

    // 요청 인터셉터 — 토큰 자동 첨부
    this.client.interceptors.request.use(config => {
      const token = localStorage.getItem('accessToken');
      if (token) config.headers.Authorization = `Bearer ${token}`;
      return config;
    });

    // 응답 인터셉터 — 에러 처리, 토큰 갱신
    this.client.interceptors.response.use(
      res => res.data,
      async err => {
        if (err.response?.status === 401) {
          await this.refreshToken();
          return this.client.request(err.config);
        }
        throw new AppError(err.response?.data?.message);
      }
    );
  }

  // 파사드 메서드 — 클라이언트는 이것만 사용
  get<T>(url: string, params?: object): Promise<T> {
    return this.client.get(url, { params });
  }

  post<T>(url: string, data: object): Promise<T> {
    return this.client.post(url, data);
  }

  private async refreshToken(): Promise<void> {
    const refreshToken = localStorage.getItem('refreshToken');
    const { accessToken } = await this.client.post('/auth/refresh', { refreshToken });
    localStorage.setItem('accessToken', accessToken);
  }
}

const api = new ApiClient('https://api.example.com');
const users = await api.get<User[]>('/users', { page: 1 });
```

---

## 4. SDK 초기화 파사드

```typescript
// Firebase 초기화 파사드 — 실제 Firebase SDK와 유사한 패턴
class FirebaseApp {
  private auth: Auth;
  private firestore: Firestore;
  private storage: Storage;
  private analytics: Analytics;

  constructor(config: FirebaseConfig) {
    const app = initializeApp(config);
    this.auth = getAuth(app);
    this.firestore = getFirestore(app);
    this.storage = getStorage(app);
    this.analytics = getAnalytics(app);
  }

  // 파사드 — 복잡한 SDK API를 단순화
  async signIn(email: string, password: string) {
    return signInWithEmailAndPassword(this.auth, email, password);
  }

  async getDocument<T>(collection: string, id: string): Promise<T> {
    const ref = doc(this.firestore, collection, id);
    const snap = await getDoc(ref);
    return snap.data() as T;
  }
}
```

---

## 5. 프론트엔드 실무 사례

| 라이브러리/패턴 | 파사드 역할 |
|----------------|-----------|
| **jQuery** | 복잡한 DOM API를 `$()` 하나로 단순화 |
| **Axios** | XMLHttpRequest API를 단순화 |
| **React Query** | 데이터 페칭, 캐싱, 동기화 복잡성을 `useQuery` 하나로 |
| **Firebase SDK** | 복잡한 GCP 서비스를 간단한 JS API로 |
| **Zustand** | Redux의 복잡한 설정을 단순화 |

---

## 6. 면접 포인트

**Q1. 파사드 패턴이란 무엇인가요?**
> 복잡한 서브시스템에 단순화된 인터페이스를 제공하는 패턴입니다. 클라이언트가 서브시스템의 내부 구조를 몰라도 사용할 수 있게 합니다.

**Q2. 어댑터와 파사드의 차이는?**
> 어댑터는 두 기존 인터페이스를 1:1로 변환합니다. 파사드는 여러 복잡한 서브시스템을 하나의 단순 인터페이스로 통합합니다.

**Q3. 파사드의 단점은?**
> 파사드 자체가 "God Object"가 되어 너무 많은 책임을 가질 수 있습니다. 또한 파사드가 제공하지 않는 서브시스템 기능을 사용하려면 우회해야 합니다.

**Q4. React Query와 파사드 패턴의 관계를 설명해주세요.**
> React Query의 `useQuery`는 데이터 페칭, 캐싱, 재검증, 로딩/에러 상태 관리 등 복잡한 로직을 하나의 훅으로 단순화하는 파사드입니다.

---

[← Decorator](./04-decorator.md) | [← 구조 패턴 목차](./README.md) | [다음: Flyweight →](./06-flyweight.md)
