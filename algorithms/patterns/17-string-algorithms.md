# 17. 문자열 알고리즘 (KMP · 라빈-카프)

> 🎨 **[인터랙티브 시각화 (KMP)](./visualizer/17-kmp.html)** — 실패 함수와 패턴 점프 매칭을 확인하세요.

## 목차
1. [문자열 매칭 문제와 브루트 포스](#1-문자열-매칭-문제와-브루트-포스)
2. [KMP — 실패 함수](#2-kmp--실패-함수)
3. [KMP — 매칭](#3-kmp--매칭)
4. [라빈-카프 — 롤링 해시](#4-라빈-카프--롤링-해시)
5. [기타 유용 기법](#5-기타-유용-기법)
6. [비교](#6-비교)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 문자열 매칭 문제와 브루트 포스

텍스트 T(길이 n)에서 패턴 P(길이 m)의 등장 위치를 찾는 문제.

```javascript
// 브루트 포스: O(n·m) — 불일치마다 한 칸만 밀고 처음부터 다시 비교
function naive(T, P) {
  const res = [];
  for (let i = 0; i + P.length <= T.length; i++) {
    let j = 0;
    while (j < P.length && T[i+j] === P[j]) j++;
    if (j === P.length) res.push(i);
  }
  return res;
}
```

문제: 불일치 시 이미 비교한 정보를 버리고 한 칸만 민다. KMP는 이 정보를 재활용해 O(n+m).

---

## 2. KMP — 실패 함수

핵심은 패턴의 **실패 함수(failure / LPS: Longest Proper Prefix which is also Suffix)**. `pi[i]` = `P[0..i]`에서 "접두사이자 접미사인 가장 긴 길이". 불일치 시 패턴을 얼마나 점프할지 알려준다.

```javascript
function buildLPS(P) {
  const pi = new Array(P.length).fill(0);
  let len = 0;                       // 직전까지의 LPS 길이
  for (let i = 1; i < P.length; i++) {
    while (len > 0 && P[i] !== P[len]) len = pi[len - 1]; // 점프
    if (P[i] === P[len]) len++;
    pi[i] = len;
  }
  return pi;
}
// "ABABC" → pi = [0,0,1,2,0]
```

> 직관: `ABAB`까지 맞다가 다음에서 불일치하면, 이미 일치한 접미사 `AB`가 패턴 접두사 `AB`와 같으므로 거기서부터 이어 비교한다(처음으로 안 돌아감).

---

## 3. KMP — 매칭

```javascript
function kmp(T, P) {
  const pi = buildLPS(P), res = [];
  let j = 0;                         // 현재 매칭된 패턴 길이
  for (let i = 0; i < T.length; i++) {
    while (j > 0 && T[i] !== P[j]) j = pi[j - 1]; // 불일치 → 실패 함수로 점프
    if (T[i] === P[j]) j++;
    if (j === P.length) {            // 전체 매칭 성공
      res.push(i - P.length + 1);
      j = pi[j - 1];                 // 다음 매칭 위해 점프
    }
  }
  return res;
}
```

텍스트 인덱스 `i`는 **절대 뒤로 가지 않는다** → O(n+m).

---

## 4. 라빈-카프 — 롤링 해시

패턴과 텍스트 구간의 **해시를 비교**한다. 윈도우를 한 칸 밀 때 해시를 O(1)에 갱신(롤링)해 평균 O(n+m).

```javascript
function rabinKarp(T, P) {
  const n = T.length, m = P.length, res = [];
  if (m > n) return res;
  const B = 256, MOD = 1_000_000_007n;
  let pHash = 0n, tHash = 0n, pow = 1n;     // pow = B^(m-1)
  for (let i = 0; i < m; i++) {
    pHash = (pHash * BigInt(B) + BigInt(P.charCodeAt(i))) % MOD;
    tHash = (tHash * BigInt(B) + BigInt(T.charCodeAt(i))) % MOD;
    if (i < m - 1) pow = (pow * BigInt(B)) % MOD;
  }
  for (let i = 0; i + m <= n; i++) {
    if (pHash === tHash) {                   // 해시 일치 → 실제 비교(충돌 방지)
      if (T.slice(i, i + m) === P) res.push(i);
    }
    if (i + m < n) {                         // 롤링: 앞 글자 빼고 뒤 글자 추가
      tHash = (tHash - BigInt(T.charCodeAt(i)) * pow % MOD + MOD) % MOD;
      tHash = (tHash * BigInt(B) + BigInt(T.charCodeAt(i + m))) % MOD;
    }
  }
  return res;
}
```

> 해시가 같아도 **충돌 가능성** 때문에 실제 문자열을 한 번 비교해야 정확하다. 최악 O(n·m)이지만 평균은 O(n+m). 여러 패턴 동시 검색·2D 매칭에 강점.

---

## 5. 기타 유용 기법

- **문자 빈도 배열**: 애너그램·순열 판정은 길이 26 카운트 배열 비교로 O(n).
- **투 포인터 + 해시**: 부분 문자열(슬라이딩 윈도우)과 결합.
- **트라이**: 여러 패턴 prefix 검색(→ [코테 가이드](../../interview/coding-test-guide.md) 참고).
- **회문(palindrome)**: 중심 확장 O(n²) 또는 Manacher O(n).

---

## 6. 비교

| | 브루트 포스 | KMP | 라빈-카프 |
|--|-----------|-----|----------|
| 시간 | O(n·m) | O(n+m) | 평균 O(n+m), 최악 O(n·m) |
| 전처리 | 없음 | LPS O(m) | 해시 O(m) |
| 강점 | 단순 | 단일 패턴 보장 | 다중 패턴·2D, 부분 일치 |

---

## 7. 면접 포인트

**Q. KMP가 O(n+m)인 이유는?**
> 실패 함수(LPS)로 불일치 시 이미 일치한 접두사=접미사 정보를 재활용해 패턴만 점프시키고, 텍스트 인덱스는 절대 되돌아가지 않기 때문이다. 전처리 O(m) + 매칭 O(n).

**Q. 실패 함수(LPS)란 무엇인가요?**
> `pi[i]`는 `P[0..i]`에서 "자기 자신이 아닌 접두사이면서 접미사인 가장 긴 부분 문자열의 길이"다. 불일치가 났을 때 패턴의 어디서부터 다시 비교하면 되는지를 알려준다.

**Q. 라빈-카프에서 해시가 같으면 바로 매칭으로 확정하나요?**
> 아니다. 서로 다른 문자열이 같은 해시를 가질 수 있으므로(충돌), 해시가 일치하면 실제 문자열을 한 번 비교해 확정한다. 그래서 최악은 O(n·m)이지만 좋은 해시면 평균 O(n+m)이다.

**Q. 롤링 해시의 핵심 아이디어는?**
> 윈도우를 한 칸 밀 때 빠지는 앞 글자의 기여를 빼고 새 뒤 글자를 더해 해시를 O(1)에 갱신하는 것. 매번 전체를 다시 해싱하지 않아 전체 O(n)이 된다.

**Q. 애너그램/순열 판정은 어떻게 효율화하나요?**
> 정렬(O(n log n)) 대신 길이 26(또는 유니코드 범위) 빈도 배열을 만들어 비교하면 O(n)이다. 슬라이딩 윈도우와 결합하면 "문자열 안의 모든 애너그램 위치 찾기"도 O(n)에 풀린다.
