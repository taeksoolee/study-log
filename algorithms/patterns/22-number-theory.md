# 22. 정수론 & 수학 (GCD · 소수 · 모듈러)

> 🎨 **[인터랙티브 시각화 (에라토스테네스의 체)](./visualizer/19-sieve.html)** — 배수 제거 과정을 확인하세요.

## 목차
1. [유클리드 호제법 — GCD/LCM](#1-유클리드-호제법--gcdlcm)
2. [소수 판정 & 에라토스테네스의 체](#2-소수-판정--에라토스테네스의-체)
3. [소인수분해](#3-소인수분해)
4. [모듈러 연산](#4-모듈러-연산)
5. [빠른 거듭제곱 (Fast Power)](#5-빠른-거듭제곱-fast-power)
6. [조합론 기초](#6-조합론-기초)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 유클리드 호제법 — GCD/LCM

최대공약수(GCD)를 `gcd(a, b) = gcd(b, a % b)`로 O(log min(a,b))에 구한다.

```javascript
function gcd(a, b) { return b === 0 ? a : gcd(b, a % b); }
function lcm(a, b) { return a / gcd(a, b) * b; }   // 먼저 나눠 오버플로 완화
```

> `lcm = a*b/gcd`인데 `a*b`가 먼저 커지면 오버플로 위험 → `a/gcd*b` 순서로. JS는 2^53 초과 시 BigInt.

---

## 2. 소수 판정 & 에라토스테네스의 체

**단일 수 판정**: √n까지만 나눠보면 된다(약수는 √n 기준 대칭).

```javascript
function isPrime(n) {
  if (n < 2) return false;
  for (let i = 2; i * i <= n; i++) if (n % i === 0) return false; // √n까지
  return true;
}
// O(√n)
```

**범위 내 모든 소수**: 에라토스테네스의 체. 배수를 지워나간다.

```javascript
function sieve(n) {
  const isP = new Array(n + 1).fill(true);
  isP[0] = isP[1] = false;
  for (let i = 2; i * i <= n; i++)
    if (isP[i]) for (let j = i * i; j <= n; j += i) isP[j] = false; // i² 부터
  return isP;
}
// O(n log log n)
```

> 체에서 `j = i*i`부터 시작하는 이유: `i*2, i*3, … i*(i-1)`은 더 작은 소수의 배수로 이미 지워졌다.

---

## 3. 소인수분해

```javascript
function factorize(n) {
  const factors = [];
  for (let p = 2; p * p <= n; p++)        // √n까지 시도
    while (n % p === 0) { factors.push(p); n /= p; }
  if (n > 1) factors.push(n);             // 남은 건 큰 소수 하나
  return factors;
}
// O(√n). 여러 수를 분해하면 "최소 소인수(SPF)" 체로 전처리해 O(log n)/쿼리
```

---

## 4. 모듈러 연산

큰 수 답을 `MOD`(보통 1e9+7)로 나눈 나머지로 요구하는 문제가 많다. 오버플로 방지 + 분배 법칙.

```
(a + b) % m = ((a%m) + (b%m)) % m
(a * b) % m = ((a%m) * (b%m)) % m
(a - b) % m = ((a%m) - (b%m) + m) % m     // 음수 방지로 +m
```

> 나눗셈은 그대로 안 됨 → **모듈러 곱셈 역원**(페르마 소정리: `a^(m-2) mod m`, m이 소수)으로 처리. JS는 곱이 2^53을 넘으면 BigInt 필요.

---

## 5. 빠른 거듭제곱 (Fast Power)

`a^b`를 O(log b)에. 지수를 이진수로 보고 제곱을 누적(분할 정복). 모듈러 거듭제곱·행렬 거듭제곱(피보나치 O(log n))에 필수.

```javascript
function power(a, b, mod = 1_000_000_007n) {
  a = BigInt(a) % mod; b = BigInt(b);
  let result = 1n;
  while (b > 0n) {
    if (b & 1n) result = result * a % mod;  // 현재 비트가 1이면 곱
    a = a * a % mod;                         // 밑 제곱
    b >>= 1n;
  }
  return result;
}
// O(log b)
```

---

## 6. 조합론 기초

- 순열 `nPr = n!/(n-r)!`, 조합 `nCr = n!/(r!(n-r)!)`.
- 큰 `nCr mod p`: 팩토리얼 전처리 + 모듈러 역원, 또는 파스칼 삼각형 DP `C[n][r] = C[n-1][r-1] + C[n-1][r]`.
- 비둘기집 원리·포함배제는 카운팅 문제의 단골 논리.

```javascript
// 파스칼 삼각형으로 작은 nCr
function pascal(N) {
  const C = Array.from({length: N+1}, (_, i) => new Array(i+1).fill(1));
  for (let n = 2; n <= N; n++)
    for (let r = 1; r < n; r++) C[n][r] = C[n-1][r-1] + C[n-1][r];
  return C;
}
```

---

## 7. 면접 포인트

**Q. 유클리드 호제법의 원리는?**
> `gcd(a,b) = gcd(b, a mod b)`를 b가 0이 될 때까지 반복한다. 큰 수를 나머지로 빠르게 줄여 O(log min(a,b))에 GCD를 구한다. LCM은 `a/gcd*b`로 구하되 오버플로를 피하려 먼저 나눈다.

**Q. 소수 판정을 √n까지만 하는 이유는?**
> 약수는 √n을 기준으로 쌍을 이룬다(`d`가 약수면 `n/d`도 약수). 따라서 √n 이하에 약수가 없으면 그 위에도 없다. 단일 판정은 O(√n), 범위 내 전체는 에라토스테네스 체로 O(n log log n).

**Q. 에라토스테네스 체에서 `i*i`부터 지우는 이유는?**
> `i*2 … i*(i-1)`은 i보다 작은 소수들의 배수로 이미 지워졌기 때문이다. 중복 작업을 줄여 효율을 높인다.

**Q. 모듈러 연산에서 나눗셈은 어떻게 하나요?**
> 그냥 나누면 안 되고 모듈러 곱셈 역원을 곱한다. modulo가 소수면 페르마 소정리로 `a^(m-2) mod m`이 역원이며, 이를 빠른 거듭제곱으로 O(log m)에 구한다.

**Q. 빠른 거듭제곱의 아이디어는?**
> 지수를 이진 표현으로 보고 밑을 제곱해가며, 지수 비트가 1인 자리에서만 결과에 곱한다. `a^b`를 O(log b)에 계산하며, 모듈러 거듭제곱과 행렬 거듭제곱(피보나치 O(log n))에 쓰인다.
