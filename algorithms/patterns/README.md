# 알고리즘 패턴 (Algorithm Patterns)

## 학습 목차

1. [투 포인터](./01-two-pointers.md)
2. [슬라이딩 윈도우](./02-sliding-window.md)
3. [BFS/DFS](./03-bfs-dfs.md)
4. [동적 프로그래밍](./04-dynamic-programming.md)
5. [그리디](./05-greedy.md)
6. [분할 정복](./06-divide-conquer.md)
7. [백트래킹](./07-backtracking.md)
8. [정렬 알고리즘](./08-sorting-algorithms.md)
9. [암호학 기초](./09-cryptography-basics.md)
10. [이진 탐색](./10-binary-search.md)
11. [누적합 & 구간합](./11-prefix-sum.md)
12. [유니온 파인드](./12-union-find.md)
13. [위상 정렬](./13-topological-sort.md)
14. [최단 경로 (다익스트라·벨만포드·플로이드)](./14-shortest-path.md)
15. [세그먼트 트리 & 펜윅](./15-segment-tree-fenwick.md)
16. [비트마스크 & 비트마스크 DP](./16-bitmask.md)
17. [문자열 알고리즘 (KMP·라빈카프)](./17-string-algorithms.md)
18. [트리 알고리즘 (트리 DP·LCA)](./18-tree-algorithms.md)
19. [최소 신장 트리 (MST)](./19-mst.md)
20. [고급 DP (LIS·LCS·편집거리·구간 DP)](./20-advanced-dp.md)
21. [그래프 심화 (SCC·이분그래프·단절점)](./21-advanced-graph.md)
22. [정수론 & 수학 (GCD·소수·모듈러)](./22-number-theory.md)
23. [기하 기초 (CCW·볼록껍질)](./23-geometry.md)
24. [고급 문자열 (Z·아호코라식·접미사배열)](./24-advanced-string.md)
25. [모노토닉 스택/덱](./25-monotonic-stack-deque.md)
26. [고급 그리디 & 스케줄링](./26-advanced-greedy.md)

## 패턴 선택 가이드

| 상황 | 추천 패턴 |
|------|----------|
| 정렬된 배열에서 쌍 찾기 | 투 포인터 |
| 연속된 부분 배열 문제 | 슬라이딩 윈도우 |
| 정렬된 배열에서 값/경계 찾기 | 이진 탐색 |
| "최댓값을 최소화" 류 최적화 | 매개변수 탐색(이진 탐색) |
| 임의 구간 합 반복 질의 | 누적합 |
| 구간 갱신이 잦을 때 | 차분 배열 |
| 최단 경로, 레벨 순회 | BFS |
| 가능한 모든 경우 탐색 | DFS/백트래킹 |
| 최적 부분 구조 | 동적 프로그래밍 |
| 지역 최적 → 전역 최적 | 그리디 |
| 정렬, 분할 문제 | 분할 정복 |
| 그룹 연결성 / 사이클(무방향) / MST | 유니온 파인드 |
| 의존성 순서 / 사이클(방향) | 위상 정렬 |
| 가중 그래프 최소 비용 경로 | 최단 경로(다익스트라/벨만포드/플로이드) |
| 구간 질의+갱신 둘 다 잦음 | 세그먼트 트리 / 펜윅 |
| 부분집합 상태 압축 (N≤20) | 비트마스크 DP |
| 문자열 패턴 매칭 | KMP / 라빈카프 |
| 서브트리 정보 / 최소 공통 조상 | 트리 DP / LCA |
| 모든 노드 최소 비용 연결 | MST(크루스칼/프림) |
| 부분 수열·문자열 변환·구간 분할 | 고급 DP(LIS/LCS/구간) |
| 방향 그래프 강결합 / 이분 판정 | 그래프 심화(SCC/이분) |
| GCD·소수·거듭제곱·mod | 정수론 |
| 점·선분·다각형·교차 | 기하(CCW) |
| 다중 패턴 매칭·접두접미사 | 고급 문자열(아호코라식/Z) |
| 다음 큰 원소·윈도우 최대/최소 | 모노토닉 스택/덱 |
| 활동 선택·스케줄링·압축 | 고급 그리디 |

---

## 참고 자료

### 학습 사이트
- **LeetCode 패턴별 문제**: https://leetcode.com/
- **Neetcode 150**: https://neetcode.io/roadmap

### 추천 도서
| 책 제목 | 교보문고 |
|---------|---------|
| 이것이 코딩 테스트다 | [검색](https://search.kyobobook.co.kr/search?keyword=이것이+코딩+테스트다) |
| 알고리즘 문제 해결 전략 | [검색](https://search.kyobobook.co.kr/search?keyword=알고리즘+문제+해결+전략) |
