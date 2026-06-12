# 1. C 기초 — 포인터, 메모리 직접 제어, JS 메모리 모델 이해

## 목차
1. C vs JavaScript 비교
2. 포인터(Pointer) 개념
3. 포인터 연산
4. 동적 메모리 할당
5. 스택 vs 힙 메모리
6. 메모리 누수와 댕글링 포인터
7. 배열과 포인터의 관계
8. 구조체(struct)와 포인터
9. JavaScript 가비지 컬렉션을 C 관점에서 이해
10. 면접 포인트

---

## 1. C vs JavaScript 비교

```
특성              C                              JavaScript
------------------------------------------------------------------------
실행 방식         컴파일 → 네이티브 바이너리       인터프리터 / JIT 컴파일
타입 시스템       정적 타입, 명시 필요             동적 타입, 런타임 결정
메모리 관리       개발자가 직접 할당/해제           가비지 컬렉터 자동 처리
포인터            직접 메모리 주소 조작 가능        참조 개념 있으나 주소 비공개
null              NULL 포인터, 역참조 시 크래시     null/undefined, TypeError
문자열            char 배열 + null 종단 문자        String 객체, 불변
배열              고정 크기, 경계 검사 없음         동적 크기, 경계 검사 있음
에러 처리         반환값(-1, NULL) 또는 errno       예외(throw/catch), Promise
표준 라이브러리   최소한 (stdio, stdlib 등)         방대한 내장 API
```

C는 "하드웨어에 가장 가까운 고수준 언어"다. 실행 모델이 투명하기 때문에 JavaScript의 메모리 동작 원리를 이해하는 데 탁월한 기준점이 된다.

---

## 2. 포인터(Pointer) 개념

포인터는 **다른 변수의 메모리 주소를 저장하는 변수**다.

### 2-1. 기본 연산자

| 연산자 | 이름 | 의미 |
|--------|------|------|
| `&` | 주소 연산자(address-of) | 변수의 메모리 주소를 반환 |
| `*` | 역참조 연산자(dereference) | 포인터가 가리키는 값에 접근 |

```c
#include <stdio.h>

int main(void) {
    int x = 42;
    int *p = &x;    // p는 x의 주소를 저장

    printf("x의 값:      %d\n",  x);       // 42
    printf("x의 주소:    %p\n",  &x);      // 예: 0x7ffd1234
    printf("p의 값(주소): %p\n", p);        // x의 주소와 동일
    printf("p가 가리키는 값: %d\n", *p);   // 42 (역참조)

    *p = 100;   // 역참조로 값 변경
    printf("변경 후 x: %d\n", x);          // 100
    return 0;
}
```

### 2-2. 포인터 타입

포인터 타입에는 가리키는 값의 타입 정보가 포함된다. 역참조 시 몇 바이트를 읽을지 결정하기 때문이다.

```c
int    *ip;    // int를 가리키는 포인터 (4바이트 읽기)
double *dp;    // double을 가리키는 포인터 (8바이트 읽기)
char   *cp;    // char를 가리키는 포인터 (1바이트 읽기)
void   *vp;    // 타입 없는 포인터 (역참조 전 형변환 필요)
```

### 2-3. 포인터를 통한 함수 인자 전달 (pass by reference)

```c
#include <stdio.h>

// 값 전달: 원본 변경 불가
void swap_fail(int a, int b) {
    int tmp = a;
    a = b;
    b = tmp;
    // 함수 내부의 a, b는 복사본이므로 원본 불변
}

// 포인터 전달: 원본 변경 가능
void swap(int *a, int *b) {
    int tmp = *a;
    *a = *b;
    *b = tmp;
}

int main(void) {
    int x = 1, y = 2;

    swap_fail(x, y);
    printf("swap_fail 후: x=%d, y=%d\n", x, y); // x=1, y=2 (변화 없음)

    swap(&x, &y);
    printf("swap 후:      x=%d, y=%d\n", x, y); // x=2, y=1
    return 0;
}
```

JavaScript에서 객체를 함수에 전달할 때 "참조의 복사본"이 전달되는 것과 개념적으로 유사하다. 단, C는 주소를 직접 볼 수 있다.

---

## 3. 포인터 연산

포인터에 정수를 더하면 포인터가 가리키는 타입의 크기만큼 주소가 이동한다.

```c
#include <stdio.h>

int main(void) {
    int arr[] = {10, 20, 30, 40, 50};
    int *p = arr;  // 배열의 첫 번째 원소를 가리킴

    printf("p    = %d\n", *p);       // 10
    printf("p+1  = %d\n", *(p+1));   // 20 (주소 +4바이트)
    printf("p+2  = %d\n", *(p+2));   // 30 (주소 +8바이트)

    // 포인터 증가
    p++;
    printf("p++ 후: %d\n", *p);      // 20

    // 두 포인터의 차이 = 원소 개수
    int *start = arr;
    int *end   = arr + 4;
    printf("거리: %td\n", end - start); // 4
    return 0;
}
```

포인터 연산은 타입 안전하지 않다. 배열 경계를 넘어도 컴파일러는 경고하지 않는다. 이 점이 C의 주요 보안 취약점(버퍼 오버플로우)의 원인이다.

---

## 4. 동적 메모리 할당

스택은 컴파일 타임에 크기가 결정된 변수만 저장할 수 있다. 런타임에 크기를 결정하거나 함수 반환 후에도 데이터를 유지하려면 **힙(heap)** 에 할당한다.

### 4-1. malloc — 초기화 없이 할당

```c
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    int n = 5;
    int *arr = (int *)malloc(n * sizeof(int)); // n개의 int 크기만큼 할당

    if (arr == NULL) {
        perror("malloc 실패");
        return 1;
    }

    for (int i = 0; i < n; i++) {
        arr[i] = i * i;
    }

    for (int i = 0; i < n; i++) {
        printf("arr[%d] = %d\n", i, arr[i]); // 0, 1, 4, 9, 16
    }

    free(arr);      // 반드시 해제
    arr = NULL;     // 댕글링 포인터 방지
    return 0;
}
```

### 4-2. calloc — 0으로 초기화하며 할당

```c
// malloc과 달리 모든 바이트를 0으로 초기화
int *arr = (int *)calloc(n, sizeof(int));
```

### 4-3. realloc — 기존 블록 크기 변경

```c
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    int *arr = (int *)malloc(3 * sizeof(int));
    arr[0] = 1; arr[1] = 2; arr[2] = 3;

    // 5개 크기로 확장
    int *tmp = (int *)realloc(arr, 5 * sizeof(int));
    if (tmp == NULL) {
        free(arr); // realloc 실패 시 원본 해제
        return 1;
    }
    arr = tmp;
    arr[3] = 4; arr[4] = 5;

    for (int i = 0; i < 5; i++) {
        printf("%d ", arr[i]); // 1 2 3 4 5
    }
    printf("\n");

    free(arr);
    return 0;
}
```

### 4-4. free — 명시적 해제

`malloc`/`calloc`/`realloc`으로 할당한 메모리는 반드시 `free`로 해제해야 한다. 해제하지 않으면 메모리 누수(memory leak)가 발생한다.

---

## 5. 스택 vs 힙 메모리

```
스택(Stack)                        힙(Heap)
------------------------------------------------------------------
함수 호출 시 자동 할당              malloc/calloc으로 명시적 할당
함수 반환 시 자동 해제              free로 명시적 해제 필요
크기가 컴파일 타임에 결정됨         크기가 런타임에 결정됨
접근 속도 빠름 (포인터 이동만)      접근 속도 상대적으로 느림 (단편화)
크기 제한 있음 (보통 수 MB)        크기 제한 큼 (가용 물리 메모리)
지역 변수, 함수 인자, 반환 주소     동적 할당 데이터, 큰 구조체 등
```

```c
#include <stdio.h>
#include <stdlib.h>

void stack_example(void) {
    int local = 42;          // 스택 할당
    printf("스택 주소: %p, 값: %d\n", (void *)&local, local);
    // 함수 반환 시 local은 자동 해제
}

void heap_example(void) {
    int *ptr = (int *)malloc(sizeof(int)); // 힙 할당
    *ptr = 42;
    printf("힙 주소: %p, 값: %d\n", (void *)ptr, *ptr);
    free(ptr); // 명시적 해제 필요
    // 함수가 반환되어도 free 하지 않으면 메모리는 남아있음
}

int main(void) {
    stack_example();
    heap_example();
    return 0;
}
```

---

## 6. 메모리 누수와 댕글링 포인터

### 6-1. 메모리 누수(Memory Leak)

`free`를 호출하지 않거나 포인터를 잃어버려 해제할 수 없게 된 경우다.

```c
void leak_example(void) {
    int *p = (int *)malloc(sizeof(int));
    *p = 10;
    // free(p); 를 빠뜨림
    // 함수 반환 후 p는 사라지지만 힙의 4바이트는 해제되지 않음
    // 이 함수를 반복 호출하면 메모리가 계속 줄어듦
}

void no_leak(void) {
    int *p = (int *)malloc(sizeof(int));
    if (p == NULL) return;
    *p = 10;
    // 모든 경로에서 free 호출
    free(p);
}
```

### 6-2. 댕글링 포인터(Dangling Pointer)

이미 해제된 메모리를 가리키는 포인터다. 역참조 시 미정의 동작(undefined behavior)이 발생한다.

```c
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    int *p = (int *)malloc(sizeof(int));
    *p = 42;
    free(p);

    // p는 여전히 같은 주소를 가리키지만, 그 메모리는 해제됨
    // *p = 100;    // 미정의 동작: 크래시 또는 조용한 데이터 오염
    // printf("%d", *p); // 미정의 동작

    p = NULL;    // 해제 후 NULL 대입이 관례
    if (p != NULL) {
        printf("%d\n", *p); // NULL 체크로 안전하게 차단
    }
    return 0;
}
```

### 6-3. 이중 해제(Double Free)

같은 포인터를 두 번 `free`하면 힙 관리 구조가 손상되어 보안 취약점이 된다.

```c
int *p = (int *)malloc(sizeof(int));
free(p);
// free(p); // 이중 해제: 미정의 동작, 보안 취약점

p = NULL;   // NULL 대입으로 이중 해제 방지
free(p);    // NULL에 free 호출은 안전 (no-op)
```

---

## 7. 배열과 포인터의 관계

C에서 배열 이름은 첫 번째 원소의 주소다. 배열과 포인터는 거의 상호 교환 가능하다.

```c
#include <stdio.h>

int main(void) {
    int arr[5] = {10, 20, 30, 40, 50};
    int *p = arr;  // &arr[0]와 동일

    // 배열 표기법과 포인터 표기법은 동일
    printf("%d\n", arr[2]);   // 30
    printf("%d\n", *(arr+2)); // 30
    printf("%d\n", p[2]);     // 30
    printf("%d\n", *(p+2));   // 30

    // sizeof의 차이 (중요!)
    printf("sizeof(arr): %zu\n", sizeof(arr)); // 20 (5 * 4바이트)
    printf("sizeof(p):   %zu\n", sizeof(p));   // 8 (포인터 크기, 64비트)
    return 0;
}
```

함수에 배열을 전달하면 포인터로 **퇴화(decay)** 된다. 크기 정보가 사라지므로 별도로 전달해야 한다.

```c
void print_array(int *arr, int size) {
    // sizeof(arr)는 포인터 크기(8)를 반환함 — 배열 크기 아님
    for (int i = 0; i < size; i++) {
        printf("%d ", arr[i]);
    }
    printf("\n");
}

int main(void) {
    int arr[5] = {1, 2, 3, 4, 5};
    print_array(arr, 5); // 크기를 명시적으로 전달
    return 0;
}
```

---

## 8. 구조체(struct)와 포인터

### 8-1. 구조체 기본

```c
#include <stdio.h>
#include <string.h>

typedef struct {
    char name[50];
    int  age;
    double score;
} Student;

int main(void) {
    Student s;
    strncpy(s.name, "Alice", sizeof(s.name) - 1);
    s.age   = 20;
    s.score = 95.5;

    printf("이름: %s, 나이: %d, 점수: %.1f\n",
           s.name, s.age, s.score);
    return 0;
}
```

### 8-2. 구조체 포인터와 -> 연산자

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct Node {
    int          value;
    struct Node *next;  // 자기 참조 구조체 (연결 리스트)
} Node;

Node *create_node(int value) {
    Node *node = (Node *)malloc(sizeof(Node));
    if (node == NULL) return NULL;
    node->value = value;  // (*node).value = value 와 동일
    node->next  = NULL;
    return node;
}

void print_list(Node *head) {
    while (head != NULL) {
        printf("%d -> ", head->value);
        head = head->next;
    }
    printf("NULL\n");
}

void free_list(Node *head) {
    while (head != NULL) {
        Node *tmp = head->next;
        free(head);
        head = tmp;
    }
}

int main(void) {
    Node *head = create_node(1);
    head->next = create_node(2);
    head->next->next = create_node(3);

    print_list(head); // 1 -> 2 -> 3 -> NULL
    free_list(head);
    return 0;
}
```

`->` 연산자는 `(*ptr).field`의 단축 표기다. 구조체 포인터에서 필드에 접근할 때 사용한다.

---

## 9. JavaScript 가비지 컬렉션을 C 관점에서 이해

### 9-1. JavaScript 객체의 힙 할당

JavaScript의 모든 객체는 힙에 할당된다. 내부적으로 C의 `malloc`과 유사한 연산이 일어난다.

```javascript
// JavaScript
const obj = { x: 1, y: 2 }; // 힙에 할당
// C 내부 동작 (의사 코드)
// JSObject *obj = (JSObject *)malloc(sizeof(JSObject));
// obj->x = 1; obj->y = 2;
```

### 9-2. 참조 카운팅과 가비지 컬렉션

C에서 프로그래머가 `free`를 호출해야 하는 것을, JavaScript 엔진이 자동으로 처리한다.

```
C 수동 관리                     JavaScript GC 자동 관리
----------------------------------------------------------
malloc → 메모리 확보            객체 생성 → 힙 할당
사용 후 free 호출               참조가 없어지면 GC 대상
free 잊으면 → 메모리 누수        GC가 주기적으로 해제
free 후 사용 → 크래시            해제 후 접근 불가능 (참조 없음)
```

```javascript
// JavaScript에서 메모리 누수 패턴 (C 관점에서 이해)
function createLeak() {
    const large = new Array(1000000).fill(0); // 힙 할당
    globalCache.push(large);  // 전역 참조로 GC 불가 → 누수
}

// C 관점: globalCache가 포인터를 보유하므로 free 불가
// C:  malloc 후 포인터를 잃어버린 것과 동일한 효과
```

### 9-3. 순환 참조

```javascript
// JavaScript
function createCycle() {
    const a = {};
    const b = {};
    a.ref = b;  // a → b 참조
    b.ref = a;  // b → a 참조 (순환)
    // 함수 반환 후 a, b는 지역 스코프에서 사라지지만
    // 서로를 참조하므로 단순 참조 카운팅으로는 해제 불가
    // → 현대 GC는 도달 가능성(reachability) 분석으로 해결
}
```

C에서 순환 참조를 가진 연결 구조는 모든 포인터를 직접 추적하여 해제해야 하며, 이를 잘못하면 메모리 누수나 이중 해제가 발생한다.

### 9-4. JavaScript 엔진 내부 메모리 영역

```
JavaScript 엔진 메모리 레이아웃 (V8 예시)
------------------------------------------
스택(Stack)       : 원시값, 참조(포인터), 함수 호출 프레임
힙(Heap)
  Young Space     : 새로 생성된 객체 (Minor GC 대상)
  Old Space       : 오래 살아남은 객체 (Major GC 대상)
  Code Space      : JIT 컴파일된 코드
  Large Object    : 큰 배열, ArrayBuffer 등
```

이 구조는 C에서 `malloc`이 내부적으로 관리하는 힙 세그먼트와 개념적으로 동일하다.

---

## 10. 면접 포인트

**Q1. 포인터와 참조의 차이는?**

C의 포인터는 메모리 주소를 저장하는 변수로, 주소 연산과 NULL 할당이 가능하다. 포인터 자체의 주소도 얻을 수 있다(`&&p`). C++의 참조는 선언 시 초기화 필수이며 NULL이 될 수 없고 가리키는 대상을 바꿀 수 없다. JavaScript의 "참조"는 객체 핸들로, 주소 자체를 직접 볼 수 없다.

**Q2. 메모리 누수가 발생하는 원인과 방지 방법은?**

원인: malloc/calloc으로 할당 후 free를 호출하지 않거나, 포인터를 잃어버려 해제 불가 상태가 되는 경우. 방지: 모든 코드 경로에서 free 호출 보장, 포인터 변수를 NULL로 초기화, Valgrind 같은 도구로 검사, RAII 패턴(C++), 스마트 포인터(C++) 활용.

**Q3. 댕글링 포인터란 무엇이고 어떻게 방지하는가?**

해제된 메모리를 여전히 가리키는 포인터다. 역참조 시 미정의 동작(크래시, 데이터 오염, 보안 취약점)이 발생한다. 방지: free 직후 포인터를 NULL로 설정, 포인터 사용 전 NULL 체크, 함수에서 지역 변수의 주소를 반환하지 않기.

**Q4. 스택 오버플로우(Stack Overflow)는 왜 발생하는가?**

스택의 크기는 제한되어 있다(보통 1~8MB). 재귀 함수가 너무 깊이 호출되거나 스택에 매우 큰 배열을 선언하면 스택 영역을 초과한다. JavaScript에서도 "Maximum call stack size exceeded" 에러가 동일한 원인이다. 해결: 재귀를 반복문으로 변환, 큰 데이터는 힙(malloc)에 할당.

**Q5. malloc이 NULL을 반환하는 경우는?**

할당 가능한 메모리가 부족할 때 NULL을 반환한다. NULL 체크 없이 역참조하면 세그멘테이션 폴트(segfault)가 발생한다. 프로덕션 코드에서 모든 동적 할당 결과는 NULL 여부를 반드시 확인해야 한다.

**Q6. JavaScript의 GC와 C의 수동 메모리 관리 중 어느 쪽이 더 좋은가?**

트레이드오프가 있다. GC는 개발 편의성과 안전성이 높지만 GC 실행 시 Stop-the-World 지연, 메모리 사용량 증가, 해제 시점 비결정론의 단점이 있다. 수동 관리는 결정론적 해제와 낮은 메모리 풋프린트가 장점이지만 개발자 실수로 인한 버그 위험이 높다. 실시간 시스템이나 임베디드에서는 수동 관리, 일반 애플리케이션은 GC가 적합하다.

**Q7. 배열 이름이 포인터와 다른 점은?**

배열 이름은 첫 번째 원소의 주소로 포인터처럼 사용할 수 있지만, 포인터 변수가 아니다. `sizeof(배열명)`은 전체 배열 크기를 반환하지만, 포인터 변수의 sizeof는 포인터 자체 크기(8바이트)를 반환한다. 배열 이름에는 `++`, `--` 연산을 할 수 없고 다른 주소를 대입할 수 없다.
