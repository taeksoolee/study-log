# 08. 로딩 UX: `keepPreviousData` · `isLoading` vs `isFetching`

> 실전 배경: 목록에서 필터·정렬·페이지를 바꿀 때마다 스켈레톤/스피너가 **번쩍**였다.
> 데이터가 이미 있는데도 매번 빈 화면으로 돌아갔다가 다시 채워지니 눈이 피로하고
> 레이아웃이 튀었다. 원인은 "queryKey가 바뀌면 새 쿼리"라는 TanStack Query의 동작.

## 목차
1. [왜 재조회 때마다 로딩이 번쩍이나](#1-왜-재조회-때마다-로딩이-번쩍이나)
2. [isLoading vs isFetching vs isPending](#2-isloading-vs-isfetching-vs-ispending)
3. [placeholderData: keepPreviousData](#3-placeholderdata-keeppreviousdata)
4. [번쩍임 없는 로딩 UX 설계](#4-번쩍임-없는-로딩-ux-설계)
5. [면접 포인트](#5-면접-포인트)

---

## 1. 왜 재조회 때마다 로딩이 번쩍이나

TanStack Query에서 `queryKey`는 캐시의 정체성(identity)이다. 필터·정렬·페이지가 바뀌면 `queryKey`가 바뀌고, 그건 **완전히 다른 쿼리**로 취급된다.

```ts
useQuery({
  queryKey: ['kpxList', { page, sort, filters }], // ← 이 값이 바뀌면 '새 쿼리'
  queryFn: fetchList,
});
```

새 `queryKey`엔 아직 캐시된 `data`가 없으므로 `data`는 `undefined`가 되고, 그래서 `isLoading`(또는 v5의 `isPending`)이 `true`가 된다. 화면은 `isLoading` 분기를 타 스켈레톤을 그린다 → **매 조작마다 빈 화면 → 데이터**의 번쩍임.

이건 버그가 아니라 기본 동작이다. "이전 페이지 데이터를 유지하면서 다음을 불러오는" 것은 **명시적으로 요청**해야 한다.

---

## 2. isLoading vs isFetching vs isPending

이 셋을 구분하지 못하면 로딩 UX를 못 잡는다.

| 상태 | 의미 | 언제 true |
|------|------|-----------|
| `isPending` (v5, 구 `isLoading`) | **캐시된 데이터가 없음** | 첫 요청 중, 또는 새 queryKey 첫 요청 중 |
| `isFetching` | **요청이 진행 중** (백그라운드 포함) | 첫 요청·refetch·재조회 등 네트워크가 도는 모든 순간 |
| `isRefetching` | `isFetching && !isPending` | 데이터는 있는데 백그라운드 갱신 중 |

핵심 규칙:
- **`isPending`(데이터 없음)** → 보여줄 게 없으니 **스켈레톤/스피너**.
- **`isFetching`(데이터는 있고 갱신 중)** → 기존 데이터를 두고 **상단 프로그레스바·미세한 인디케이터** 정도.

즉 "데이터가 있는가"와 "네트워크가 도는가"는 다른 축이다. 이 둘을 하나(`isLoading`)로 묶어 분기하면 번쩍임이 생긴다.

---

## 3. placeholderData: keepPreviousData

해법은 **queryKey가 바뀌어도 새 데이터가 올 때까지 이전 데이터를 placeholder로 유지**하는 것이다.

```ts
import { keepPreviousData } from '@tanstack/vue-query'; // (react-query도 동일 API)

useQuery({
  queryKey: ['kpxList', { page, sort, filters }],
  queryFn: fetchList,
  placeholderData: keepPreviousData, // ← 이전 queryKey의 data를 유지
});
```

이렇게 하면:
- 새 `queryKey`로 바뀌어도 `data`가 이전 값으로 채워져 **`isPending`이 `false`로 유지**된다(빈 화면이 안 생김).
- 대신 `isFetching`은 `true`, `isPlaceholderData`도 `true`가 되어 "지금 보이는 건 이전 데이터"임을 알 수 있다.
- 새 데이터가 도착하면 매끄럽게 교체된다.

> v4의 `keepPreviousData: true` 옵션이 v5에서 `placeholderData: keepPreviousData` 함수로 바뀌었다. `placeholderData`는 캐시에 저장되지 않는 임시 표시용 데이터라는 점에서 `initialData`(실제 캐시로 취급)와 다르다.

---

## 4. 번쩍임 없는 로딩 UX 설계

실제 뷰에서의 분기 전략.

```ts
const { data, isPending, isFetching, isPlaceholderData } = useQuery({ /* ... */ });
```

```html
<!-- 최초 진입: 보여줄 데이터가 없을 때만 스켈레톤 -->
<Skeleton v-if="isPending" />

<template v-else>
  <!-- 재조회 중엔 데이터를 두고 상단 얇은 로딩바 + 살짝 흐리게 -->
  <TopProgressBar v-if="isFetching" />
  <DataTable :rows="data" :class="{ 'opacity-70': isPlaceholderData }" />
</template>
```

- **최초만 스켈레톤**, 재조회는 데이터 유지 + 미세 인디케이터.
- 페이지네이션 버튼은 `isFetching` 동안 비활성화해 연타로 인한 경쟁을 막는다.
- 이전 데이터를 흐리게(`opacity`) 처리하면 "갱신 중"이 직관적으로 보인다.

이 접근은 [문서 01의 캐시 개념](./01-tanstack-query-cache-invalidation.md)과 짝을 이룬다 — 01은 "데이터를 언제 지우나", 08은 "데이터를 언제까지 보여주나".

---

## 5. 면접 포인트

**Q. `isLoading`(isPending)과 `isFetching`의 차이는?**
> isPending은 캐시된 데이터가 없는 상태(보여줄 게 없음), isFetching은 네트워크 요청이 도는 상태(백그라운드 갱신 포함)다. "데이터가 있는가"와 "요청 중인가"는 다른 축이라, 데이터가 있으면서 갱신 중일 수 있다(isRefetching). 스켈레톤은 isPending, 미세 인디케이터는 isFetching에 매핑한다.

**Q. 필터/페이지를 바꿀 때 화면이 번쩍이는 이유와 해결은?**
> queryKey가 바뀌면 다른 쿼리로 취급돼 data가 undefined가 되고 isPending이 true가 되기 때문이다. placeholderData: keepPreviousData로 이전 데이터를 유지하면 isPending이 false로 유지돼 번쩍임이 사라지고, isPlaceholderData로 "이전 데이터 표시 중"을 구분할 수 있다.

**Q. `placeholderData`와 `initialData`의 차이는?**
> initialData는 실제 캐시로 저장되어 staleTime 등의 계산에 쓰이는 "진짜 초기 데이터"고, placeholderData는 캐시에 저장되지 않는 임시 표시용이다. keepPreviousData는 placeholderData의 특수형으로 이전 queryKey의 데이터를 잠시 보여준다.

**Q. Suspense로도 로딩을 처리할 수 있는데 차이는?**
> useSuspenseQuery는 로딩을 상위 Suspense 경계로 던져 선언적으로 fallback을 그린다. 다만 이 경우 재조회마다 fallback으로 떨어지지 않도록 전환(transition) 처리가 필요하다. keepPreviousData 방식은 컴포넌트 내부에서 상태 플래그로 세밀하게 제어할 수 있어 목록 UX엔 더 직접적이다.
