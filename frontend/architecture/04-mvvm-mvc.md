# 4. MVC / MVP / MVVM in Frontend

## 목차

1. [MVC — Model-View-Controller](#1-mvc--model-view-controller)
2. [MVP — Model-View-Presenter](#2-mvp--model-view-presenter)
3. [MVVM — Model-View-ViewModel](#3-mvvm--model-view-viewmodel)
4. [패턴 비교 표](#4-패턴-비교-표)
5. [현대 프론트엔드에서의 변형](#5-현대-프론트엔드에서의-변형)
6. [면접 포인트](#6-면접-포인트)

---

## 1. MVC — Model-View-Controller

### 개념

MVC는 애플리케이션을 세 가지 역할로 분리하는 가장 오래된 UI 아키텍처 패턴이다.

| 구성요소 | 역할 |
|---------|------|
| **Model** | 데이터와 비즈니스 로직 (상태, API 호출, 유효성 검사) |
| **View** | UI 렌더링 (사용자에게 보이는 화면) |
| **Controller** | 사용자 입력을 받아 Model을 업데이트하고 View를 선택 |

### 전통적인 MVC 흐름

```
User Input → Controller → Model (업데이트) → View (렌더링)
                ↑_____________________________________↓
                         (다음 입력 대기)
```

### React에서의 MVC 매핑

React는 순수 MVC는 아니지만 개념적으로 매핑할 수 있다.

```typescript
// Model — 상태 및 비즈니스 로직
// userModel.ts
export interface UserState {
  users: User[]
  isLoading: boolean
  error: string | null
}

export const fetchUsers = async (): Promise<User[]> => {
  const response = await fetch('/api/users')
  if (!response.ok) throw new Error('사용자 목록을 불러오지 못했습니다')
  return response.json()
}

// Controller — Redux 액션/리듀서 또는 컨텍스트 핸들러
// userSlice.ts (Redux Toolkit)
const userSlice = createSlice({
  name: 'users',
  initialState: { users: [], isLoading: false, error: null } as UserState,
  reducers: {
    setUsers: (state, action: PayloadAction<User[]>) => {
      state.users = action.payload
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(loadUsers.pending, (state) => { state.isLoading = true })
      .addCase(loadUsers.fulfilled, (state, action) => {
        state.isLoading = false
        state.users = action.payload
      })
      .addCase(loadUsers.rejected, (state, action) => {
        state.isLoading = false
        state.error = action.error.message ?? '오류 발생'
      })
  },
})

// View — React 컴포넌트 (렌더링만 담당)
const UserListView = ({ users, isLoading, onDeleteClick }: UserListViewProps) => {
  if (isLoading) return <Spinner />

  return (
    <ul>
      {users.map((user) => (
        <li key={user.id}>
          {user.name}
          <button onClick={() => onDeleteClick(user.id)}>삭제</button>
        </li>
      ))}
    </ul>
  )
}

// Controller 역할의 컨테이너 컴포넌트
const UserListContainer = () => {
  const dispatch = useAppDispatch()
  const { users, isLoading } = useAppSelector((state) => state.users)

  useEffect(() => { dispatch(loadUsers()) }, [dispatch])

  const handleDeleteClick = (id: string) => {
    dispatch(deleteUser(id))
  }

  return (
    <UserListView
      users={users}
      isLoading={isLoading}
      onDeleteClick={handleDeleteClick}
    />
  )
}
```

### MVC의 문제점

- Controller가 Model과 View를 모두 알고 있어 **God Object**가 되기 쉬움
- View와 Model 사이에 **양방향 데이터 흐름**이 발생할 수 있어 추적이 어려움

---

## 2. MVP — Model-View-Presenter

### 개념

MVP는 MVC의 Controller를 **Presenter**로 대체한 패턴이다.
View는 매우 수동적(Passive)이며, Presenter가 모든 로직을 담당한다.

```
User Input → View → Presenter → Model
                ↑         ↓
                └─ View 업데이트 (Presenter가 View를 직접 호출)
```

### MVC vs MVP 핵심 차이

- MVC: View가 Model을 직접 관찰(Observer 패턴)
- MVP: View는 인터페이스만 노출, Presenter가 View를 제어

```typescript
// View 인터페이스 (Passive View)
interface IUserListView {
  showUsers(users: User[]): void
  showLoading(isLoading: boolean): void
  showError(message: string): void
}

// Presenter
class UserListPresenter {
  constructor(
    private view: IUserListView,
    private userRepository: IUserRepository
  ) {}

  async loadUsers() {
    this.view.showLoading(true)
    try {
      const users = await this.userRepository.getAll()
      this.view.showUsers(users)
    } catch (err) {
      this.view.showError('사용자 목록을 불러오지 못했습니다')
    } finally {
      this.view.showLoading(false)
    }
  }
}

// React에서의 MVP 적용
const useUserListPresenter = (): IUserListView & { loadUsers: () => void } => {
  const [users, setUsers] = useState<User[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const view: IUserListView = {
    showUsers: setUsers,
    showLoading: setIsLoading,
    showError: setError,
  }

  const presenter = new UserListPresenter(view, new AxiosUserRepository())

  return { ...view, loadUsers: presenter.loadUsers.bind(presenter) }
}
```

### MVP의 특징

- **Presenter는 View를 인터페이스로 참조** → 단위 테스트 용이
- View가 매우 단순(Passive)해져 **UI 로직이 없음**
- Android 개발에서 널리 사용되었으나 React 생태계에서는 드물게 사용

---

## 3. MVVM — Model-View-ViewModel

### 개념

MVVM은 View와 ViewModel 사이에 **데이터 바인딩**을 사용하는 패턴이다.
ViewModel은 View를 직접 참조하지 않고, View가 ViewModel을 관찰(observe)한다.

```
Model ←→ ViewModel ←(Data Binding)→ View
                                        ↓
                                  User Input
                                        ↓
                               ViewModel 업데이트
```

### Vue에서의 MVVM (가장 전형적인 예)

```vue
<!-- View -->
<template>
  <div>
    <!-- Data Binding: ViewModel의 상태를 View가 자동으로 반영 -->
    <input v-model="searchQuery" placeholder="검색어 입력" />
    <div v-if="isLoading">로딩 중...</div>
    <ul v-else>
      <li v-for="product in filteredProducts" :key="product.id">
        {{ product.name }} - {{ product.price }}원
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
// ViewModel — 반응형 상태와 로직
import { ref, computed, onMounted } from 'vue'

const searchQuery = ref('')        // View와 양방향 바인딩
const products = ref<Product[]>([])
const isLoading = ref(false)

// Computed: View가 사용하는 파생 상태
const filteredProducts = computed(() =>
  products.value.filter((p) =>
    p.name.toLowerCase().includes(searchQuery.value.toLowerCase())
  )
)

// Model 호출
onMounted(async () => {
  isLoading.value = true
  products.value = await productApi.getAll()  // Model
  isLoading.value = false
})
</script>
```

### Angular에서의 MVVM

```typescript
// ViewModel (Component)
@Component({
  selector: 'app-product-list',
  template: `
    <input [(ngModel)]="searchQuery" />
    <app-product-card
      *ngFor="let product of filteredProducts"
      [product]="product"
    ></app-product-card>
  `
})
export class ProductListComponent implements OnInit {
  searchQuery = ''                 // View와 양방향 바인딩 [(ngModel)]
  products: Product[] = []

  get filteredProducts() {         // Computed 상태
    return this.products.filter((p) =>
      p.name.includes(this.searchQuery)
    )
  }

  constructor(private productService: ProductService) {}  // Model 주입

  ngOnInit() {
    this.productService.getAll().subscribe((data) => {
      this.products = data
    })
  }
}
```

### React에서의 MVVM (Custom Hook 방식)

React는 공식적으로 MVVM을 지향하지 않지만 Custom Hook이 ViewModel 역할을 한다.

```typescript
// ViewModel — Custom Hook
const useProductList = () => {
  const [searchQuery, setSearchQuery] = useState('')
  const [products, setProducts] = useState<Product[]>([])
  const [isLoading, setIsLoading] = useState(false)

  // Computed 상태 (derived state)
  const filteredProducts = useMemo(
    () => products.filter((p) => p.name.includes(searchQuery)),
    [products, searchQuery]
  )

  useEffect(() => {
    setIsLoading(true)
    productApi.getAll().then((data) => {
      setProducts(data)
      setIsLoading(false)
    })
  }, [])

  return { searchQuery, setSearchQuery, filteredProducts, isLoading }
}

// View — 렌더링만 담당
const ProductListView = () => {
  const { searchQuery, setSearchQuery, filteredProducts, isLoading } = useProductList()

  return (
    <div>
      <input
        value={searchQuery}
        onChange={(e) => setSearchQuery(e.target.value)}
        placeholder="검색어 입력"
      />
      {isLoading ? (
        <Spinner />
      ) : (
        <ul>
          {filteredProducts.map((p) => (
            <li key={p.id}>{p.name} - {p.price}원</li>
          ))}
        </ul>
      )}
    </div>
  )
}
```

---

## 4. 패턴 비교 표

| 항목 | MVC | MVP | MVVM |
|------|-----|-----|------|
| **View-Logic 분리** | 부분적 | 완전 분리 | 완전 분리 |
| **데이터 흐름** | 단방향/양방향 | 단방향 | 양방향 바인딩 |
| **View 의존성** | Controller가 View 참조 | Presenter가 View 인터페이스 참조 | ViewModel은 View 모름 |
| **테스트 용이성** | 보통 | 매우 좋음 | 좋음 |
| **주요 프레임워크** | Ruby on Rails, Django | Android (Java) | Vue, Angular, React(Hook) |
| **학습 난이도** | 낮음 | 중간 | 중간 |

---

## 5. 현대 프론트엔드에서의 변형

### Flux 아키텍처 — MVC의 문제 해결

Facebook은 복잡한 MVC의 양방향 데이터 흐름 문제를 해결하기 위해 **Flux**를 도입했다.

```
Action → Dispatcher → Store → View
   ↑___________________________|
           (단방향 흐름)
```

Flux가 MVC의 변형인 이유:
- **Store** = Model (데이터와 비즈니스 로직)
- **View** = View (React 컴포넌트)
- **Dispatcher** = Controller의 역할 (액션을 스토어로 전달)
- **단방향 데이터 흐름**으로 MVC의 양방향 의존 문제 해결

### Redux — Flux의 구현체

```typescript
// Redux = MVC의 변형
// Action (사용자 의도)
const incrementAction = { type: 'counter/increment' }

// Reducer (Model + Controller 역할)
const counterReducer = (state = 0, action: AnyAction) => {
  switch (action.type) {
    case 'counter/increment': return state + 1
    default: return state
  }
}

// Store (단일 상태 트리 = Model)
const store = createStore(counterReducer)

// View (React 컴포넌트)
const Counter = () => {
  const count = useSelector((state) => state.counter)
  const dispatch = useDispatch()

  return (
    <button onClick={() => dispatch(incrementAction)}>
      Count: {count}
    </button>
  )
}
```

### React Hooks = MVVM의 현대적 구현

```typescript
// Custom Hook = ViewModel
// useState/useEffect/useMemo로 반응형 상태 관리 → MVVM의 데이터 바인딩과 유사
const useCounter = (initialValue = 0) => {
  const [count, setCount] = useState(initialValue)

  const doubleCount = useMemo(() => count * 2, [count])  // Computed

  const increment = useCallback(() => setCount((c) => c + 1), [])
  const decrement = useCallback(() => setCount((c) => c - 1), [])

  return { count, doubleCount, increment, decrement }
}
```

---

## 6. 면접 포인트

**Q. MVC, MVP, MVVM의 핵심 차이는?**

> MVC는 Controller가 Model과 View를 모두 알고 조율합니다.
> MVP는 View가 수동적(Passive)이고 Presenter가 View 인터페이스를 통해 직접 View를 업데이트합니다.
> MVVM은 ViewModel이 View를 전혀 모르고, View가 ViewModel의 상태를 관찰(데이터 바인딩)합니다.
> 테스트 관점에서는 MVP(Presenter는 View 인터페이스만 의존)와 MVVM(ViewModel은 View 독립)이 유리합니다.

**Q. Redux는 MVC의 어떤 점을 개선했나요?**

> 전통적 MVC에서는 View와 Model 사이에 양방향 데이터 흐름이 발생하여 규모가 커질수록 상태 변화를 추적하기 어렵습니다.
> Redux(Flux 기반)는 Action → Reducer → Store → View의 단방향 흐름을 강제하여
> 언제, 어떤 이유로 상태가 바뀌었는지 명확하게 추적할 수 있게 합니다.

**Q. React Custom Hook과 MVVM의 관계는?**

> MVVM의 ViewModel은 View의 상태와 로직을 담당하며 View를 직접 참조하지 않습니다.
> React Custom Hook도 상태와 파생 상태(useMemo), 액션 핸들러를 묶어 반환하며
> 컴포넌트(View)에서는 훅을 호출해 상태를 구독합니다.
> 이 패턴은 MVVM에서 View가 ViewModel을 관찰하는 것과 구조적으로 동일합니다.
