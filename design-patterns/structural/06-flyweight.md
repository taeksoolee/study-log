# Flyweight (플라이웨이트 패턴)

## 목차
1. [개념](#1-개념)
2. [내재적 상태 vs 외재적 상태](#2-내재적-상태-vs-외재적-상태)
3. [아이콘/이미지 공유 예제](#3-아이콘이미지-공유-예제)
4. [Canvas 파티클 시스템 예제](#4-canvas-파티클-시스템-예제)
5. [React key와 플라이웨이트](#5-react-key와-플라이웨이트)
6. [면접 포인트](#6-면접-포인트)

---

## 1. 개념

> 많은 수의 유사한 객체를 효율적으로 지원하기 위해 **공유를 통해 메모리 사용량을 최소화**한다.

"플라이웨이트"는 권투에서 가장 가벼운 체급을 뜻한다. 객체를 최대한 가볍게 만든다.

**핵심 아이디어**: 공유 가능한 상태(내재적)를 별도로 분리하여 공유하고,
객체별로 달라지는 상태(외재적)는 외부에서 전달받는다.

**언제 쓰는가?**
- 동일한 유형의 객체가 수천~수백만 개 필요할 때
- 메모리 부족이 문제가 될 때
- 대부분의 객체가 공유 가능한 상태를 갖고 있을 때

---

## 2. 내재적 상태 vs 외재적 상태

```typescript
// 나쁜 예 — 모든 상태를 객체 내부에 저장
class Particle {
  constructor(
    // 내재적 상태 (모든 파티클이 공유 가능) — 중복 저장됨!
    public color: string,
    public sprite: HTMLImageElement,  // 큰 데이터!
    // 외재적 상태 (각 파티클마다 다름)
    public x: number,
    public y: number,
    public velocity: { dx: number; dy: number },
  ) {}
}

// 파티클 1000개 = HTMLImageElement 1000개 복사 (메모리 낭비)
const particles = Array.from({ length: 1000 }, () =>
  new Particle('red', loadImage('/particle.png'), 0, 0, { dx: 1, dy: 1 })
);
```

---

## 3. 아이콘/이미지 공유 예제

```typescript
// ─── 플라이웨이트 (공유 가능한 내재적 상태) ─────────────
class IconFlyweight {
  private image: HTMLImageElement;

  constructor(
    readonly name: string,
    readonly src: string,
    readonly color: string,
  ) {
    this.image = new Image();
    this.image.src = src;
  }

  draw(ctx: CanvasRenderingContext2D, x: number, y: number, size: number): void {
    ctx.drawImage(this.image, x, y, size, size);
  }
}

// ─── 플라이웨이트 팩토리 (공유 풀 관리) ─────────────────
class IconFactory {
  private pool = new Map<string, IconFlyweight>();

  getIcon(name: string, src: string, color: string): IconFlyweight {
    const key = `${name}-${color}`;
    if (!this.pool.has(key)) {
      console.log(`[Factory] 새 아이콘 생성: ${key}`);
      this.pool.set(key, new IconFlyweight(name, src, color));
    }
    return this.pool.get(key)!;
  }

  getPoolSize(): number {
    return this.pool.size;
  }
}

// ─── 컨텍스트 (외재적 상태 보유) ────────────────────────
class MapMarker {
  constructor(
    private flyweight: IconFlyweight, // 공유 객체 참조
    public x: number,                 // 외재적 상태
    public y: number,
    public size: number,
  ) {}

  draw(ctx: CanvasRenderingContext2D): void {
    this.flyweight.draw(ctx, this.x, this.y, this.size);
  }
}

// ─── 사용 ────────────────────────────────────────────────
const factory = new IconFactory();

// 지도에 같은 종류의 마커 1000개 표시
const markers: MapMarker[] = [];
for (let i = 0; i < 1000; i++) {
  const icon = factory.getIcon('restaurant', '/icons/restaurant.png', 'red');
  markers.push(new MapMarker(icon, Math.random() * 1000, Math.random() * 1000, 24));
}

console.log(`마커 수: ${markers.length}`);        // 1000
console.log(`실제 이미지 객체: ${factory.getPoolSize()}`); // 1 (공유!)
```

---

## 4. Canvas 파티클 시스템 예제

```typescript
// 플라이웨이트: 파티클 타입 (공유 상태)
class ParticleType {
  constructor(
    readonly color: string,
    readonly shape: 'circle' | 'square' | 'star',
    readonly maxLifetime: number,
  ) {}

  draw(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    size: number,
    opacity: number,
  ): void {
    ctx.save();
    ctx.globalAlpha = opacity;
    ctx.fillStyle = this.color;

    if (this.shape === 'circle') {
      ctx.beginPath();
      ctx.arc(x, y, size / 2, 0, Math.PI * 2);
      ctx.fill();
    } else if (this.shape === 'square') {
      ctx.fillRect(x - size / 2, y - size / 2, size, size);
    }
    ctx.restore();
  }
}

// 플라이웨이트 팩토리
class ParticleTypePool {
  private types = new Map<string, ParticleType>();

  get(color: string, shape: ParticleType['shape'], lifetime: number): ParticleType {
    const key = `${color}-${shape}-${lifetime}`;
    if (!this.types.has(key)) {
      this.types.set(key, new ParticleType(color, shape, lifetime));
    }
    return this.types.get(key)!;
  }
}

// 파티클 컨텍스트 (외재적 상태)
class Particle {
  public age = 0;

  constructor(
    private type: ParticleType, // 공유 플라이웨이트
    public x: number,
    public y: number,
    public vx: number,
    public vy: number,
    public size: number,
  ) {}

  update(): void {
    this.x += this.vx;
    this.y += this.vy;
    this.vy += 0.1; // 중력
    this.age++;
  }

  draw(ctx: CanvasRenderingContext2D): void {
    const opacity = 1 - this.age / this.type.maxLifetime;
    this.type.draw(ctx, this.x, this.y, this.size, opacity);
  }

  isDead(): boolean {
    return this.age >= this.type.maxLifetime;
  }
}

// 파티클 시스템 — 수천 개의 파티클, 소수의 타입 공유
class ParticleSystem {
  private pool = new ParticleTypePool();
  private particles: Particle[] = [];

  emit(x: number, y: number, count: number): void {
    const type = this.pool.get('orange', 'circle', 60); // 타입 공유!
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = Math.random() * 3 + 1;
      this.particles.push(new Particle(
        type, x, y,
        Math.cos(angle) * speed,
        Math.sin(angle) * speed,
        Math.random() * 8 + 2,
      ));
    }
  }

  update(ctx: CanvasRenderingContext2D): void {
    this.particles = this.particles.filter(p => !p.isDead());
    this.particles.forEach(p => { p.update(); p.draw(ctx); });
  }
}
```

---

## 5. React key와 플라이웨이트

React의 `key` prop은 플라이웨이트와 유사한 재사용 개념이다.

```tsx
// React의 재조정 알고리즘 — 플라이웨이트 아이디어 적용
const UserList = ({ users }: { users: User[] }) => (
  <ul>
    {users.map(user => (
      // key를 통해 React가 기존 DOM 노드를 재사용(공유)할지 결정
      // key가 같으면 → 기존 컴포넌트 인스턴스 재사용 (플라이웨이트!)
      // key가 다르면 → 새 인스턴스 생성
      <li key={user.id}>{user.name}</li>
    ))}
  </ul>
);

// 가상화 리스트 (react-window) — 실제 플라이웨이트 패턴
// 수천 개의 아이템 중 화면에 보이는 것만 DOM 노드 생성
// 스크롤 시 기존 DOM 노드를 재사용(공유)하여 메모리 절약
import { FixedSizeList } from 'react-window';

const VirtualList = ({ items }: { items: any[] }) => (
  <FixedSizeList height={600} itemCount={items.length} itemSize={50}>
    {({ index, style }) => (
      <div style={style}>{items[index].name}</div>
    )}
  </FixedSizeList>
);
```

---

## 6. 면접 포인트

**Q1. 플라이웨이트 패턴이란 무엇인가요?**
> 많은 수의 유사 객체를 생성할 때 공유 가능한 상태를 외부에 분리하여 공유함으로써 메모리를 절약하는 패턴입니다.

**Q2. 내재적 상태와 외재적 상태의 차이는?**
> 내재적 상태는 객체 간 공유 가능한 변하지 않는 상태입니다. 외재적 상태는 각 객체마다 다른 상태로, 클라이언트가 제공합니다.

**Q3. 실무에서 플라이웨이트 패턴이 적용된 사례는?**
> 가상화 리스트(react-window), 아이콘 스프라이트 시트, Canvas 게임의 오브젝트 풀링, 폰트 렌더링(같은 글자 모양 공유)이 대표적입니다.

**Q4. 플라이웨이트의 단점은?**
> 외재적 상태를 항상 외부에서 전달해야 하므로 코드가 복잡해집니다. 런타임에 상태를 계산해야 하는 CPU 비용이 메모리 절약과 트레이드오프가 됩니다.

---

[← Facade](./05-facade.md) | [← 구조 패턴 목차](./README.md) | [다음: Proxy →](./07-proxy.md)
