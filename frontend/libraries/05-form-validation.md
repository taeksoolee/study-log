# 5. 폼 & 유효성 검사

## 목차

1. [React Hook Form](#1-react-hook-form)
2. [Zod: 스키마 기반 유효성 검사](#2-zod-스키마-기반-유효성-검사)
3. [React Hook Form + Zod 조합](#3-react-hook-form--zod-조합)
4. [Yup: 전통적 접근](#4-yup-전통적-접근)
5. [Zod vs Yup 비교](#5-zod-vs-yup-비교)
6. [복잡한 폼 패턴](#6-복잡한-폼-패턴)
7. [면접 포인트](#7-면접-포인트)

---

## 1. React Hook Form

비제어 컴포넌트(uncontrolled) 기반으로 성능 최적화. 리렌더링 최소화.

```bash
npm install react-hook-form
```

### 기본 사용법

```tsx
import { useForm } from 'react-hook-form';

type LoginForm = {
  email: string;
  password: string;
  rememberMe: boolean;
};

function LoginForm() {
  const {
    register,       // 입력 필드 등록
    handleSubmit,   // 폼 제출 처리
    formState: { errors, isSubmitting, isDirty, isValid },
    watch,          // 필드 값 구독
    reset,          // 폼 초기화
  } = useForm<LoginForm>({
    defaultValues: { email: '', password: '', rememberMe: false },
    mode: 'onBlur', // 'onChange' | 'onBlur' | 'onSubmit' | 'all'
  });

  const onSubmit = async (data: LoginForm) => {
    await loginApi(data);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <div>
        <input
          {...register('email', {
            required: '이메일을 입력하세요',
            pattern: {
              value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
              message: '올바른 이메일 형식이 아닙니다',
            },
          })}
          placeholder="이메일"
        />
        {errors.email && <span>{errors.email.message}</span>}
      </div>

      <div>
        <input
          type="password"
          {...register('password', {
            required: '비밀번호를 입력하세요',
            minLength: { value: 8, message: '8자 이상 입력하세요' },
          })}
        />
        {errors.password && <span>{errors.password.message}</span>}
      </div>

      <input type="checkbox" {...register('rememberMe')} />

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? '로그인 중...' : '로그인'}
      </button>
    </form>
  );
}
```

### Controller: 외부 컴포넌트 연동

```tsx
import { Controller, useForm } from 'react-hook-form';
import Select from 'react-select'; // 커스텀 컴포넌트

function ProfileForm() {
  const { control, handleSubmit } = useForm();

  return (
    <form onSubmit={handleSubmit(console.log)}>
      {/* ref를 직접 받지 않는 컴포넌트에 Controller 사용 */}
      <Controller
        name="country"
        control={control}
        rules={{ required: '국가를 선택하세요' }}
        render={({ field, fieldState: { error } }) => (
          <>
            <Select
              {...field}
              options={[
                { value: 'kr', label: '한국' },
                { value: 'us', label: '미국' },
              ]}
            />
            {error && <span>{error.message}</span>}
          </>
        )}
      />
    </form>
  );
}
```

---

## 2. Zod: 스키마 기반 유효성 검사

런타임 유효성 검사 + TypeScript 타입 추론을 동시에.

```bash
npm install zod
```

### 기본 스키마

```ts
import { z } from 'zod';

// 기본 타입
const StringSchema = z.string();
const NumberSchema = z.number();

// 문자열 유효성 검사
const EmailSchema = z.string()
  .email('올바른 이메일 형식이 아닙니다')
  .min(1, '이메일을 입력하세요');

// 객체 스키마
const UserSchema = z.object({
  name: z.string().min(2, '이름은 2자 이상').max(50),
  email: z.string().email(),
  age: z.number().int().min(0).max(120).optional(),
  role: z.enum(['admin', 'user', 'guest']),
  createdAt: z.date(),
});

// 타입 추론
type User = z.infer<typeof UserSchema>;
// { name: string; email: string; age?: number; role: 'admin'|'user'|'guest'; createdAt: Date }
```

### 고급 스키마

```ts
// 조건부 유효성 검사 (refine)
const PasswordSchema = z.object({
  password: z.string().min(8),
  confirmPassword: z.string(),
}).refine(
  (data) => data.password === data.confirmPassword,
  {
    message: '비밀번호가 일치하지 않습니다',
    path: ['confirmPassword'], // 에러가 표시될 필드
  }
);

// 유니온
const IdSchema = z.union([z.string(), z.number()]);
const IdSchema2 = z.string().or(z.number()); // 동일

// 배열
const TagsSchema = z.array(z.string()).min(1, '태그를 1개 이상 추가하세요');

// 변환 (parse 시 값 변환)
const TrimmedString = z.string().transform(s => s.trim());

// API 응답 파싱
const ApiResponseSchema = z.object({
  data: z.array(UserSchema),
  total: z.number(),
  page: z.number(),
});

// 안전한 파싱 (예외 없이 결과 반환)
const result = ApiResponseSchema.safeParse(apiResponse);
if (result.success) {
  console.log(result.data);
} else {
  console.error(result.error.issues); // 에러 목록
}
```

---

## 3. React Hook Form + Zod 조합

```bash
npm install @hookform/resolvers
```

```tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

// 스키마 정의
const RegisterSchema = z.object({
  name: z.string().min(2, '이름은 2자 이상 입력하세요'),
  email: z.string().email('올바른 이메일 형식이 아닙니다'),
  password: z.string()
    .min(8, '비밀번호는 8자 이상입니다')
    .regex(/[A-Z]/, '대문자를 포함해야 합니다')
    .regex(/[0-9]/, '숫자를 포함해야 합니다'),
  confirmPassword: z.string(),
}).refine(
  (data) => data.password === data.confirmPassword,
  { message: '비밀번호가 일치하지 않습니다', path: ['confirmPassword'] }
);

type RegisterForm = z.infer<typeof RegisterSchema>;

function RegisterForm() {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<RegisterForm>({
    resolver: zodResolver(RegisterSchema), // Zod 연결
  });

  return (
    <form onSubmit={handleSubmit((data) => console.log(data))}>
      <input {...register('name')} placeholder="이름" />
      {errors.name && <p>{errors.name.message}</p>}

      <input {...register('email')} placeholder="이메일" />
      {errors.email && <p>{errors.email.message}</p>}

      <input type="password" {...register('password')} placeholder="비밀번호" />
      {errors.password && <p>{errors.password.message}</p>}

      <input type="password" {...register('confirmPassword')} placeholder="비밀번호 확인" />
      {errors.confirmPassword && <p>{errors.confirmPassword.message}</p>}

      <button type="submit">가입하기</button>
    </form>
  );
}
```

---

## 4. Yup: 전통적 접근

체이닝 API로 유효성 규칙 선언. Formik과 함께 많이 사용.

```bash
npm install yup
```

```ts
import * as yup from 'yup';

const RegisterSchema = yup.object({
  name: yup.string().required('이름을 입력하세요').min(2, '2자 이상'),
  email: yup.string().required().email('올바른 이메일 형식'),
  password: yup.string().required().min(8),
  confirmPassword: yup
    .string()
    .oneOf([yup.ref('password')], '비밀번호가 일치하지 않습니다'),
  age: yup.number().min(0).max(120).optional(),
});

// React Hook Form + Yup
import { yupResolver } from '@hookform/resolvers/yup';
const { register } = useForm({ resolver: yupResolver(RegisterSchema) });
```

---

## 5. Zod vs Yup 비교

| 항목 | Zod | Yup |
|------|-----|-----|
| TypeScript 타입 추론 | 완벽 (`z.infer<>`) | 제한적 |
| 번들 크기 | ~14KB | ~40KB |
| API 스타일 | 체이닝 + `refine` | 체이닝 |
| 에러 메시지 | 커스터마이징 쉬움 | 커스터마이징 가능 |
| 비동기 유효성 | `.refine(async fn)` | `.test(async fn)` |
| 변환(transform) | 내장 | 내장 |
| 커뮤니티 | 빠르게 성장 | 안정적, 오래됨 |
| Formik 연동 | `@hookform/resolvers` | `@hookform/resolvers` |

**선택 기준:**
- TypeScript 프로젝트, 타입 안전성 중요 → **Zod**
- 레거시 프로젝트, 기존 Yup 사용 중 → **Yup 유지**

---

## 6. 복잡한 폼 패턴

### 동적 필드 (useFieldArray)

```tsx
import { useForm, useFieldArray } from 'react-hook-form';

type FormValues = {
  users: { name: string; email: string }[];
};

function DynamicForm() {
  const { register, control, handleSubmit } = useForm<FormValues>({
    defaultValues: { users: [{ name: '', email: '' }] },
  });

  const { fields, append, remove } = useFieldArray({
    control,
    name: 'users',
  });

  return (
    <form onSubmit={handleSubmit(console.log)}>
      {fields.map((field, index) => (
        <div key={field.id}>
          <input {...register(`users.${index}.name`)} placeholder="이름" />
          <input {...register(`users.${index}.email`)} placeholder="이메일" />
          <button type="button" onClick={() => remove(index)}>삭제</button>
        </div>
      ))}
      <button type="button" onClick={() => append({ name: '', email: '' })}>
        추가
      </button>
      <button type="submit">제출</button>
    </form>
  );
}
```

### 다단계 폼 (Multi-step)

```tsx
function MultiStepForm() {
  const [step, setStep] = useState(1);
  const methods = useForm({ mode: 'onChange' });

  const { handleSubmit, trigger } = methods;

  const nextStep = async () => {
    // 현재 단계의 필드만 유효성 검사
    const fields = step === 1 ? ['name', 'email'] : ['address', 'phone'];
    const isValid = await trigger(fields as any);
    if (isValid) setStep(s => s + 1);
  };

  return (
    <FormProvider {...methods}>
      <form onSubmit={handleSubmit(console.log)}>
        {step === 1 && <StepOne />}
        {step === 2 && <StepTwo />}
        {step === 3 && <StepThree />}

        <button type="button" onClick={nextStep}>다음</button>
      </form>
    </FormProvider>
  );
}
```

---

## 7. 면접 포인트

**Q. React Hook Form이 다른 폼 라이브러리(Formik)보다 빠른 이유는?**
> React Hook Form은 비제어 컴포넌트(uncontrolled)를 기반으로 합니다. 필드 값이 변할 때마다 state를 업데이트하지 않아 리렌더링이 발생하지 않습니다. Formik은 제어 컴포넌트(controlled)로 모든 키 입력마다 리렌더링이 발생합니다.

**Q. Zod의 `z.infer<>`는 어떻게 동작하는가?**
> `z.infer<typeof Schema>`는 TypeScript의 조건부 타입(Conditional Types)을 활용해 Zod 스키마 정의에서 TypeScript 타입을 자동으로 추론합니다. 스키마와 타입을 별도로 관리할 필요 없이 단일 소스(스키마)에서 타입이 생성되므로 둘의 불일치가 없어집니다.

**Q. `register`와 `Controller`의 차이는?**
> `register`는 HTML 네이티브 input/select/textarea에 사용합니다. ref를 통해 DOM에 직접 접근합니다. `Controller`는 react-select, MUI TextField처럼 외부에서 value/onChange를 props로 받는 제어 컴포넌트에 사용합니다.

**Q. 폼 유효성 검사를 클라이언트에서만 해도 되는가?**
> 절대 안 됩니다. 클라이언트 유효성 검사는 UX를 위한 즉각적 피드백용이고, 보안은 서버 유효성 검사로 보장해야 합니다. 브라우저의 개발자 도구로 클라이언트 검사를 우회할 수 있습니다. 서버에서도 동일한 Zod 스키마로 검증하면 코드 재사용과 일관성을 동시에 얻을 수 있습니다.
