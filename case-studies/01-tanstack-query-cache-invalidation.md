# 01. TanStack Query 캐시 무효화 & 로그아웃 세션 정리

> 실전 배경: 로그아웃 후 **새로고침 없이 다른 계정으로 로그인**했더니, 첫 렌더에
> 이전 사용자의 자원 목록이 잠깐 그대로 노출됐다. 로그아웃 코드는 분명히
> `queryClient.invalidateQueries()`를 호출하고 있었는데도.

## 목차
1. [stale ≠ removed: invalidate가 하는 일](#1-stale--removed-invalidate가-하는-일)
2. [staleTime vs gcTime, 그리고 데이터가 남아 있는 이유](#2-staletime-vs-gctime-그리고-데이터가-남아-있는-이유)
3. [invalidate / removeQueries / clear 선택 기준](#3-invalidate--removequeries--clear-선택-기준)
4. [영속 캐시(IndexedDB) 복원 레이스 컨디션](#4-영속-캐시indexeddb-복원-레이스-컨디션)
5. [폴링 목록 동기화: invalidate 대신 setQueriesData](#5-폴링-목록-동기화-invalidate-대신-setqueriesdata)
6. [면접 포인트](#6-면접-포인트)

---

## 1. stale ≠ removed: invalidate가 하는 일

`invalidateQueries()`의 이름은 "무효화"지만, 실제 동작은 **"이 쿼리를 stale로 표시하고, 활성(active) 관찰자가 있으면 refetch를 걸어라"**다. 캐시에 들어 있는 `data` 자체를 지우지 않는다.

```ts
// 로그아웃 시 (버그 버전)
await queryClient.invalidateQueries();
router.replace('/login');
```

여기서 두 가지 일이 벌어진다.

1. 모든 쿼리가 stale로 표시된다. 하지만 `data`는 `queryCache`에 그대로 남는다.
2. 마운트되어 있는 활성 쿼리는 **즉시 refetch**된다. 그런데 이 시점엔 토큰이 이미 없어서, 요청 인터셉터가 요청을 취소(`CancelToken`)하고 rejected promise가 쏟아진다.

결과적으로 캐시의 `data`는 살아 있으므로, 계정을 바꿔 다시 목록 화면에 들어가면 **새 데이터를 받기 전 첫 렌더에서 이전 사용자 데이터가 보인다.**

---

## 2. staleTime vs gcTime, 그리고 데이터가 남아 있는 이유

| 옵션 | 의미 | 기본값(v5) |
|------|------|-----------|
| `staleTime` | 이 시간 동안은 데이터를 "신선"하다고 보고 refetch하지 않음 | `0` (즉시 stale) |
| `gcTime` (구 `cacheTime`) | **관찰자가 0이 된 뒤** 이 시간이 지나야 캐시에서 데이터를 제거(GC) | `5분` |

핵심은 gcTime의 트리거가 "시간"이 아니라 **"관찰자가 0이 된 시점부터의 시간"**이라는 점이다. 화면을 떠나도 gcTime이 지나기 전엔 `data`가 메모리에 남는다.

문제의 쿼리는 `gcTime: 24시간`으로 잡혀 있었다.

```ts
useQuery({
  queryKey: ['resourceList', filters],
  queryFn: fetchResourceList,
  gcTime: 1000 * 60 * 60 * 24, // 24시간 — 화면을 떠나도 하루 동안 캐시 유지
});
```

즉 "로그아웃 → 재로그인"이 24시간 안에 일어나면, invalidate로는 절대 이전 데이터가 사라지지 않는다. **의도적으로 긴 gcTime을 준 쿼리일수록 세션 경계에서 명시적 제거가 필수**가 된다.

---

## 3. invalidate / removeQueries / clear 선택 기준

세 API는 파괴력이 다르다.

| API | 캐시 data 제거 | refetch 유발 | 뮤테이션 캐시 |
|-----|:---:|:---:|:---:|
| `invalidateQueries()` | ❌ (stale 표시만) | ✅ 활성 쿼리 | 영향 없음 |
| `removeQueries()` | ✅ 쿼리만 | ❌ | 영향 없음 |
| `clear()` | ✅ 전부 | ❌ | ✅ **함께 제거** |

이 사례의 해법은 **경로마다 다른 API**를 쓰는 것이었다.

```ts
// 로그아웃: 남김없이 비운다. refetch도 유발하지 않아 취소 요청 다발도 사라진다.
function onLogout() {
  queryClient.clear();
  clearPersistedQueryCache(); // IndexedDB (아래 4절)
  // + 사용자 스코프 스토어/모바일 네비 메모리 reset
}

// 로그인: clear()를 쓰면 안 된다.
function onLoginStart() {
  queryClient.removeQueries(); // 쿼리만 제거
}
```

**로그인에서 `clear()`를 피한 이유**가 이 문서의 핵심 판단이다. 로그인 처리는 대개 `mutationFn` 안에서 이뤄지는데, `clear()`는 **뮤테이션 캐시까지 비운다.** 그러면 지금 실행 중인 로그인 뮤테이션 자체를 캐시에서 제거하게 되고, 뮤테이션 캐시를 구독해 전역 에러 토스트를 띄우는 provider가 있다면 라이브러리 내부 동작에 의존하는 불안정한 상태가 된다. 그래서 로그인은 쿼리만 지우는 `removeQueries()`를 쓴다.

> 정리: **로그아웃은 `clear()`, 로그인은 `removeQueries()`.** "지금 실행 중인 뮤테이션을 죽이면 안 되는가?"가 갈림길이다.

---

## 4. 영속 캐시(IndexedDB) 복원 레이스 컨디션

`persistQueryClient`로 Query 캐시를 IndexedDB에 영속화하면, 새로고침 후에도 즉시 복원(hydrate)된다. 그런데 이게 세션 정리와 **경합**한다.

부팅 시퀀스는 대략 이렇다.

```ts
// persistQueryClient 내부 개념
const restored = await persister.restoreClient(); // ① IndexedDB 조회 (비동기)
hydrate(queryClient, restored);                   // ② 메모리로 복원
```

①과 ② 사이에 세션 정리(`clearPersistedQueryCache()`)가 끼어들면, **방금 지운 캐시가 ②에서 되살아난다.** refreshToken이 없어 로그아웃 이벤트조차 없이 로그인 화면으로 진입하는 부팅 경로에서 특히 재현됐다.

해법은 **단방향 플래그**로 "복원 결과 폐기"를 표시하는 것.

```ts
let isSessionCleared = false;

export function clearPersistedQueryCache() {
  isSessionCleared = true;               // 이후 복원 결과는 버린다
  return idbPersister.removeClient();    // IndexedDB의 캐시 제거
}

export async function restoreClient() {
  const restored = await idb.get('vue-query-cache');
  if (isSessionCleared) return undefined; // 복원 도중 정리됐으면 폐기
  return restored;
}
```

복원은 부팅 시 1회만 일어나므로 플래그를 되돌릴 필요가 없다. (재복원 시나리오가 생기면 이 가정을 재검토해야 한다.)

> 이건 [비동기 순서 보장](../javascript/08-async.md)과 [웹 스토리지(IndexedDB)](../browser/07-storage.md)가 만나는 지점이다. `await` 사이의 틈에 다른 코드가 끼어들 수 있다는 걸 잊으면 이런 버그가 난다.

---

## 5. 폴링 목록 동기화: invalidate 대신 setQueriesData

또 다른 실전 사례. 목록 API는 행 상태를 `RUNNING`으로 주지만, 별도 status API로 조회하면 이미 `ERROR` 같은 **최종 상태**인 경우가 있었다. RUNNING 행만 5초 폴링해 최종 상태로 갱신해야 했다.

여기서 "완료되면 목록을 invalidate하자"는 자연스러운 발상이 **오히려 틀렸다.** invalidate하면 목록 API를 다시 부르고, 그 API는 여전히 stale한 RUNNING을 돌려주므로 방금 반영한 최종 상태가 되돌아간다.

```ts
// ❌ 최종 상태가 다시 RUNNING으로 롤백됨
queryClient.invalidateQueries({ queryKey: ['kpxList'] });

// ✅ status 결과로 목록 캐시를 직접 패치 (서버 재조회 없이)
queryClient.setQueriesData({ queryKey: ['kpxList'] }, (old) =>
  patchListStatus(old, key, finalStatus),
);
```

**"서버가 아직 최종값을 모른다"**면, 서버를 다시 부르는 invalidate가 아니라 클라이언트가 아는 최종값으로 캐시를 패치(`setQueriesData`)하는 게 맞다.

---

## 6. 면접 포인트

**Q. `invalidateQueries`와 `removeQueries`, `clear`의 차이는?**
> invalidate는 쿼리를 stale로 표시하고 활성 쿼리를 refetch할 뿐 캐시의 data는 남긴다. removeQueries는 쿼리 데이터를 제거하되 refetch하지 않는다. clear는 쿼리·뮤테이션 캐시를 모두 비운다. 그래서 "데이터를 실제로 없애야" 하는 로그아웃엔 clear/removeQueries가 맞고, "다시 받아와야" 하는 데이터 갱신엔 invalidate가 맞다.

**Q. staleTime과 gcTime(cacheTime)의 차이는?**
> staleTime은 데이터를 신선하다고 보는 기간(그동안 refetch 안 함), gcTime은 관찰자가 0이 된 뒤 캐시에서 제거되기까지의 기간이다. gcTime의 기준은 절대 시간이 아니라 "관찰자가 사라진 시점부터"라, 화면을 떠나도 gcTime 전엔 데이터가 메모리에 남는다.

**Q. 로그아웃 후 이전 사용자 데이터가 노출되는 버그, 원인과 해법은?**
> invalidate만 하면 data가 gcTime까지 캐시에 남아, 재로그인 첫 렌더에 노출된다. gcTime이 길수록 심하다. 로그아웃 시 queryClient.clear()로 실제 제거하고, IndexedDB 영속 캐시도 함께 지운다. 로그인 시엔 실행 중인 로그인 뮤테이션을 죽이지 않으려고 clear 대신 removeQueries를 쓴다.

**Q. 영속 캐시를 쓸 때 세션 정리에서 조심할 점은?**
> 부팅 시 복원(restore→hydrate)이 비동기라, 그 사이에 캐시를 지우면 hydrate가 지운 데이터를 되살린다. 복원 결과를 폐기하는 플래그로 이 창을 닫는다.

**Q. 폴링으로 최종 상태를 반영할 때 invalidate가 왜 문제인가?**
> 원본 목록 API가 아직 최종값을 모르면, invalidate로 재조회해봐야 stale한 중간 상태로 롤백된다. 클라이언트가 아는 최종값을 setQueriesData로 캐시에 직접 패치하는 게 맞다.
