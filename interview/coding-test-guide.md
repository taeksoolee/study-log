# 8. 코딩 테스트 가이드 (JS 실전)

> JS는 코테에서 불리한 점이 있다(내장 우선순위 큐·정렬 안정성 외 자료구조 부족). 이 문서는 **전략 + JS에 없는 자료구조 직접 구현 + 함정**을 모은다.

## 목차
1. [문제 풀이 5단계 절차](#1-문제-풀이-5단계-절차)
2. [복잡도로 알고리즘 역추정하기](#2-복잡도로-알고리즘-역추정하기)
3. [JS 코테 함정 모음](#3-js-코테-함정-모음)
4. [직접 구현: 최소 힙 / 우선순위 큐](#4-직접-구현-최소-힙--우선순위-큐)
5. [직접 구현: 트라이(Trie)](#5-직접-구현-트라이trie)
6. [입출력과 자주 쓰는 스니펫](#6-입출력과-자주-쓰는-스니펫)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 문제 풀이 5단계 절차

1. **이해**: 입력 범위·제약·엣지 케이스를 예제로 확인. 모호하면 질문(면접) / 가정 명시.
2. **brute force 먼저**: 무식한 해법의 복잡도를 말하고, 통과 가능 여부를 제약과 비교.
3. **최적화 패턴 매칭**: 정렬→투포인터/이진탐색, 연속구간→슬라이딩윈도우/누적합, 그래프→BFS/DFS/유니온파인드, 최적부분구조→DP.
4. **구현**: 작게 나눠 작성, 변수명 명확히, 엣지(빈 입력·1개·최대) 처리.
5. **검증**: 예제 + 경계값 손으로 추적, 복잡도 재확인.

> 면접에선 **말로 설명하며** 푸는 게 핵심. 침묵하며 코딩하지 말 것.

---

## 2. 복잡도로 알고리즘 역추정하기

제약(N)을 보면 의도된 복잡도가 보인다 (대략 1초 ≈ 1억 연산 기준).

| N 범위 | 허용 복잡도 | 떠올릴 것 |
|--------|-----------|----------|
| N ≤ 10~12 | O(N!), O(2^N) | 순열·완전탐색·백트래킹 |
| N ≤ 20~25 | O(2^N) | 비트마스크 DP |
| N ≤ 500 | O(N³) | 플로이드, 3중 DP |
| N ≤ 5,000 | O(N²) | 2중 루프 DP |
| N ≤ 10^5~10^6 | O(N log N) | 정렬·이진탐색·힙·세그트리 |
| N ≤ 10^7~10^8 | O(N) | 투포인터·누적합·그리디 |

---

## 3. JS 코테 함정 모음

```javascript
// 1) 정렬 기본이 "문자열 사전순" → 숫자 정렬은 비교 함수 필수
[10, 2, 1].sort();              // [1, 10, 2]  ❌
[10, 2, 1].sort((a, b) => a-b); // [1, 2, 10]  ✅

// 2) 큰 수: 2^53 초과는 부정확 → BigInt
9007199254740993 === 9007199254740992; // true ❌  → BigInt('...') 사용

// 3) 정수 나눗셈
Math.floor(7 / 2);  // 3   (7/2 = 3.5)
7 % 2;              // 1   음수 주의: -7 % 2 === -1

// 4) 2차원 배열 초기화 — 행 공유 버그
const bad = Array(3).fill([]);          // 같은 배열 3번 참조 ❌
const ok  = Array.from({length: 3}, () => []); // ✅

// 5) Map/Set이 객체보다 빠르고 안전 (키 순서·프로토타입 오염 없음)
const seen = new Set();   const cnt = new Map();

// 6) 재귀 깊이: 깊은 DFS는 스택 오버플로 → 반복 + 명시적 스택
```

---

## 4. 직접 구현: 최소 힙 / 우선순위 큐

JS엔 우선순위 큐가 **내장돼 있지 않다**. 다익스트라·K번째·스케줄링에 필수라 외워두자. 배열 기반 이진 힙으로 O(log n) 삽입/삭제.

```javascript
class MinHeap {
  constructor() { this.h = []; }
  size() { return this.h.length; }
  peek() { return this.h[0]; }

  push(v) {
    const h = this.h;
    h.push(v);
    let i = h.length - 1;
    while (i > 0) {                       // 위로 올리기(sift-up)
      const p = (i - 1) >> 1;
      if (h[p] <= h[i]) break;
      [h[p], h[i]] = [h[i], h[p]];
      i = p;
    }
  }

  pop() {
    const h = this.h;
    const top = h[0], last = h.pop();
    if (h.length) {
      h[0] = last;
      let i = 0, n = h.length;
      while (true) {                       // 아래로 내리기(sift-down)
        let l = 2*i+1, r = 2*i+2, min = i;
        if (l < n && h[l] < h[min]) min = l;
        if (r < n && h[r] < h[min]) min = r;
        if (min === i) break;
        [h[min], h[i]] = [h[i], h[min]];
        i = min;
      }
    }
    return top;
  }
}

// 우선순위 큐: [우선순위, 값] 튜플로 push, 비교를 priority로
const pq = new MinHeap();
pq.push([dist, node]); // MinHeap 비교를 배열 첫 원소 기준으로 바꾸려면 비교자 주입형으로 일반화
```

> 최대 힙이 필요하면 값에 `-`를 붙여 넣거나 비교자를 반대로. 다익스트라/프림/K개 문제의 단골 도구.

---

## 5. 직접 구현: 트라이(Trie)

문자열 prefix 검색·자동완성·사전 문제의 자료구조. 각 노드가 다음 글자로의 분기를 가진다.

```javascript
class Trie {
  constructor() { this.root = {}; }

  insert(word) {
    let node = this.root;
    for (const ch of word) {
      node[ch] ??= {};       // 없으면 생성
      node = node[ch];
    }
    node.$ = true;           // 단어 끝 표시
  }

  search(word) {             // 완전 일치
    let node = this.root;
    for (const ch of word) {
      if (!node[ch]) return false;
      node = node[ch];
    }
    return node.$ === true;
  }

  startsWith(prefix) {       // 접두사 존재 여부
    let node = this.root;
    for (const ch of prefix) {
      if (!node[ch]) return false;
      node = node[ch];
    }
    return true;
  }
}
```

> 시간복잡도: 삽입·탐색 모두 O(단어 길이). 단어 수와 무관해 대량 사전에서 해시보다 prefix 질의에 유리하다.

---

## 6. 입출력과 자주 쓰는 스니펫

```javascript
// 백준식 빠른 입력 (Node.js)
const input = require('fs').readFileSync('/dev/stdin', 'utf8').trim().split('\n');
const [n, m] = input[0].split(' ').map(Number);

// 자주 쓰는 변환
const grid = input.slice(1).map(line => line.split(' ').map(Number));
const freq = arr.reduce((m, x) => m.set(x, (m.get(x)||0)+1), new Map());

// 방향 벡터 (상하좌우)
const DIR = [[-1,0],[1,0],[0,-1],[0,1]];

// 큐는 배열 shift가 O(n) → 인덱스 포인터로 O(1) 디큐
let q = [start], head = 0;
while (head < q.length) { const cur = q[head++]; /* ... q.push(next) */ }
```

---

## 7. 면접 포인트

**Q. 제약(N)만 보고 알고리즘을 어떻게 추정하나요?**
> 1초에 약 1억 연산을 기준으로 역산한다. N≤20이면 2^N(완전탐색/비트마스크), N≤5000이면 O(N²), N≤10^6이면 O(N log N)(정렬·이진탐색·힙), N≤10^8이면 O(N)(투포인터·누적합)을 떠올린다.

**Q. JS로 코테 볼 때 가장 흔한 함정은?**
> `sort()`가 기본 사전순이라 숫자는 `(a,b)=>a-b` 비교자가 필수, 2^53 초과 정수는 BigInt, `Array(n).fill([])`의 행 참조 공유, 배열 `shift()`의 O(n) 디큐다.

**Q. JS에 없어서 직접 구현해야 하는 자료구조는?**
> 우선순위 큐(이진 힙)가 대표적이다. 다익스트라·K번째 원소·스케줄링에 필요한데 내장이 없어 sift-up/down으로 직접 만든다. prefix 문제엔 트라이도 자주 구현한다.

**Q. 깊은 재귀 DFS가 위험한 이유와 대안은?**
> 호출 스택 한계로 스택 오버플로가 날 수 있다. 명시적 스택을 쓰는 반복 DFS로 바꾸거나, BFS로 풀 수 있으면 BFS를 쓴다.

**Q. 배열을 큐로 쓸 때 주의점은?**
> `Array.shift()`는 앞을 빼면서 전체를 당겨 O(n)이다. 큐가 크면 인덱스 포인터(`head++`)로 디큐를 O(1)로 만들거나 덱 자료구조를 쓴다.
