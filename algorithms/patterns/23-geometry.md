# 23. 기하 기초 (Computational Geometry)

> 🎨 **[인터랙티브 시각화 (볼록 껍질)](./visualizer/16-convex-hull.html)** — CCW 기반 모노톤 체인을 확인하세요.

## 목차
1. [CCW — 세 점의 방향](#1-ccw--세-점의-방향)
2. [선분 교차 판정](#2-선분-교차-판정)
3. [볼록 껍질 (Convex Hull)](#3-볼록-껍질-convex-hull)
4. [점의 다각형 내부 판정](#4-점의-다각형-내부-판정)
5. [다각형 넓이 (신발끈 공식)](#5-다각형-넓이-신발끈-공식)
6. [부동소수점 주의](#6-부동소수점-주의)
7. [면접 포인트](#7-면접-포인트)

---

## 1. CCW — 세 점의 방향

기하 문제의 **만능 도구**. 세 점 A→B→C가 반시계(좌회전)·시계(우회전)·일직선 중 무엇인지 **외적(cross product)** 부호로 판정.

```javascript
// > 0: 반시계(좌), < 0: 시계(우), = 0: 일직선
function ccw(a, b, c) {
  return (b[0]-a[0]) * (c[1]-a[1]) - (b[1]-a[1]) * (c[0]-a[0]);
}
```

> 외적 `(B-A) × (C-A)`의 z성분이다. 부호만 보면 되므로 나눗셈·삼각함수 없이 정수 연산으로 정확하다(오버플로만 주의 → BigInt).

---

## 2. 선분 교차 판정

선분 AB와 CD가 교차하는가? CCW를 4번 쓴다.

```javascript
function segIntersect(a, b, c, d) {
  const ab = Math.sign(ccw(a, b, c)) * Math.sign(ccw(a, b, d));
  const cd = Math.sign(ccw(c, d, a)) * Math.sign(ccw(c, d, b));
  if (ab === 0 && cd === 0) {            // 한 직선 위(공선) → 1D 바운딩박스 겹침 검사
    const ovl = (p, q, r, s, i) =>      // i축(0=x,1=y) 구간 겹침
      Math.min(p[i], q[i]) <= Math.max(r[i], s[i]) &&
      Math.min(r[i], s[i]) <= Math.max(p[i], q[i]);
    return ovl(a, b, c, d, 0) && ovl(a, b, c, d, 1);
  }
  return ab <= 0 && cd <= 0;            // 서로를 가로지름
}
```

- 일반 교차: AB 기준 C,D가 반대편이고(`ccw 부호 다름`) CD 기준 A,B도 반대편.
- 공선(일직선) 특수 케이스: 좌표 구간이 겹치는지 별도 확인(끝점 접촉 포함).

---

## 3. 볼록 껍질 (Convex Hull)

점들을 모두 감싸는 최소 볼록 다각형. **모노톤 체인(Andrew)**: 정렬 후 아래·위 껍질을 CCW로 만든다. O(n log n).

```javascript
function convexHull(points) {
  points.sort((p, q) => p[0]-q[0] || p[1]-q[1]);     // x, y 순 정렬
  const n = points.length;
  if (n < 3) return points;
  const hull = [];
  for (let i = 0; i < n; i++) {                       // 아래 껍질
    while (hull.length >= 2 &&
           ccw(hull[hull.length-2], hull[hull.length-1], points[i]) <= 0)
      hull.pop();                                      // 우회전/일직선이면 제거
    hull.push(points[i]);
  }
  const lower = hull.length + 1;
  for (let i = n - 2; i >= 0; i--) {                   // 위 껍질
    while (hull.length >= lower &&
           ccw(hull[hull.length-2], hull[hull.length-1], points[i]) <= 0)
      hull.pop();
    hull.push(points[i]);
  }
  hull.pop();                                          // 시작점 중복 제거
  return hull;
}
```

> 응용: 최소 외접 도형, 가장 먼 두 점(회전 캘리퍼스), 충돌 영역.

---

## 4. 점의 다각형 내부 판정

**광선 투사(ray casting)**: 점에서 한 방향으로 반직선을 쏴 다각형 변과의 교차 횟수가 **홀수면 내부**, 짝수면 외부.

```javascript
function pointInPolygon(pt, poly) {
  let inside = false;
  for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    const [xi, yi] = poly[i], [xj, yj] = poly[j];
    const intersect = (yi > pt[1]) !== (yj > pt[1]) &&
      pt[0] < ((xj - xi) * (pt[1] - yi)) / (yj - yi) + xi;
    if (intersect) inside = !inside;
  }
  return inside;
}
// O(n)
```

---

## 5. 다각형 넓이 (신발끈 공식)

정점을 순서대로 돌며 외적을 누적. 볼록·오목 모두 동작.

```javascript
function polygonArea(poly) {
  let area = 0;
  for (let i = 0, n = poly.length; i < n; i++) {
    const [x1, y1] = poly[i], [x2, y2] = poly[(i+1) % n];
    area += x1 * y2 - x2 * y1;            // 신발끈(shoelace)
  }
  return Math.abs(area) / 2;
}
```

---

## 6. 부동소수점 주의

기하의 최대 함정은 **부동소수점 오차**.

- 가능하면 정수 좌표 + 정수 연산(CCW의 외적)으로 비교 → 정확.
- 부득이 실수 비교는 `Math.abs(a - b) < EPS`(엡실론, 예: 1e-9)로.
- 큰 좌표의 외적은 오버플로 → JS는 2^53 초과 시 BigInt.

---

## 7. 면접 포인트

**Q. CCW(외적)로 무엇을 판정하나요?**
> 세 점의 방향(반시계/시계/일직선)을 외적 부호로 판정한다. 나눗셈·삼각함수 없이 정수 연산으로 정확해, 선분 교차·볼록 껍질·다각형 넓이 등 기하 문제의 기본 도구다.

**Q. 두 선분의 교차를 어떻게 판정하나요?**
> CCW를 네 번 쓴다. 선분 AB 기준으로 C·D가 서로 반대편이고, CD 기준으로 A·B도 반대편이면 교차한다. 한 직선 위(공선)인 특수 케이스는 좌표 구간 겹침을 따로 확인한다.

**Q. 볼록 껍질을 구하는 방법과 복잡도는?**
> 점을 정렬한 뒤 아래·위 껍질을 CCW로 만드는 모노톤 체인(또는 그레이엄 스캔)으로 O(n log n)이다. 우회전이 생기면 스택에서 점을 제거해 볼록성을 유지한다.

**Q. 점이 다각형 내부인지 어떻게 판정하나요?**
> 광선 투사: 점에서 한 방향으로 반직선을 쏴 다각형 변과의 교차 횟수가 홀수면 내부, 짝수면 외부다. O(n).

**Q. 기하 알고리즘에서 부동소수점 함정을 어떻게 피하나요?**
> 가능하면 정수 좌표와 정수 외적으로 비교해 오차를 원천 차단하고, 실수 비교가 불가피하면 엡실론(예: 1e-9) 허용 오차로 비교한다. 큰 좌표는 오버플로를 주의한다.
