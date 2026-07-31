# React Native & 크로스플랫폼 전략

> 웹 개발자가 모바일 앱까지 영역을 확장하기 위한 전략과 React Native 최신 아키텍처를 다룹니다.

---

## 개요

### "웹 개발자인데 앱도 할 수 있나?"

**가능하다.** React Native는 React 지식으로 iOS/Android 앱을 만드는 프레임워크다.

핵심 철학: **"Learn once, write anywhere"** — "Write once, run anywhere"와 다르다. 동일한 사고방식(React 컴포넌트 모델)으로 각 플랫폼에 맞는 코드를 작성한다.

```
크로스플랫폼 스펙트럼:
WebView 래퍼 ←── React Native / Flutter ──→ 네이티브(Swift/Kotlin)
(개발 속도)                                    (성능/UX)
```

이 프로젝트에 Flutter 섹션이 이미 있지만 React Native를 다루는 이유:
- React 웹 개발자의 **가장 낮은 러닝커브**
- 웹과 **코드 공유**가 실질적으로 가능 (같은 React 생태계)
- 2024년 New Architecture 안정화로 성능 한계 돌파

---

## 핵심 개념

### 1. React Native New Architecture (2024~)

#### 기존 Bridge 문제점

```
JS 스레드 ◄──JSON 직렬화 / 비동기 메시지──► 네이티브 스레드
```

- JSON 직렬화/역직렬화 오버헤드
- 비동기 통신만 가능 → 동기적 레이아웃 불가
- 대량 데이터 전송 시 프레임 드롭

#### JSI (JavaScript Interface)

C++로 작성된 인터페이스. JS에서 네이티브 객체를 **직접 참조**:

```javascript
// Bridge 시대: 비동기 + JSON
const value = await NativeModules.Storage.getItem('token');

// JSI 시대: 동기 + 직접 참조
const value = global.nativeStorage.getItem('token'); // 즉시 반환!
```

- Bridge 제거 → JSON 직렬화 없음
- **동기적** 네이티브 호출 가능
- 메모리 공유 가능 (ArrayBuffer)

#### Fabric: 새 렌더링 시스템

- C++ 기반 레이아웃 계산 (Yoga 엔진)
- 동기적 UI 업데이트 → 제스처 응답 즉각적
- Concurrent Features (React 18) 지원
- 이전 아키텍처와 호환 (점진적 마이그레이션)

#### TurboModules

```typescript
// TypeScript 스펙 → codegen이 네이티브 코드 자동 생성
export interface Spec extends TurboModule {
  multiply(a: number, b: number): Promise<number>;
  getDeviceName(): string; // 동기 메서드도 가능!
}
```

- **Lazy Loading**: 필요할 때만 모듈 로드 (앱 시작 시간 단축)
- **Codegen**: TS 스펙 → ObjC++/Java 자동 생성
- **타입 안전**: JS ↔ 네이티브 간 타입 불일치 컴파일 시점 검출

#### Hermes 엔진

```
기존: 소스코드 → [앱 시작 시 파싱+컴파일] → 실행 (느림)
Hermes: 소스코드 → [빌드 시 컴파일] → 바이트코드(.hbc) → 즉시 실행
```

- TTI 50%+ 단축, 메모리 사용량 감소

---

### 2. Expo Router

#### 파일 기반 라우팅 (Next.js App Router와 유사)

```
app/
├── _layout.tsx          # Root Layout
├── index.tsx            # / (홈)
├── (tabs)/
│   ├── _layout.tsx      # Tab Navigator
│   ├── home.tsx         # /home 탭
│   └── profile.tsx      # /profile 탭
├── post/
│   └── [id].tsx         # /post/123 (동적 라우트)
└── +not-found.tsx       # 404
```

```tsx
// app/(tabs)/_layout.tsx
import { Tabs } from 'expo-router';

export default function TabLayout() {
  return (
    <Tabs>
      <Tabs.Screen name="home" options={{ title: '홈' }} />
      <Tabs.Screen name="profile" options={{ title: '프로필' }} />
    </Tabs>
  );
}
```

#### 딥링크 자동화

```tsx
// app/post/[id].tsx → 자동으로 myapp://post/123 매핑
import { useLocalSearchParams } from 'expo-router';

export default function PostDetail() {
  const { id } = useLocalSearchParams<{ id: string }>();
  return <Text>Post #{id}</Text>;
}
```

#### EAS (Expo Application Services)

```bash
eas build --platform ios --profile production    # 클라우드 빌드
eas update --branch production --message "버그 수정"  # OTA 업데이트
eas submit --platform ios                        # 앱스토어 제출
```

---

### 3. React Native vs Flutter

| 구분 | React Native | Flutter |
|------|-------------|--------|
| 언어 | JavaScript/TypeScript | Dart |
| 렌더링 | 네이티브 컴포넌트 사용 | 자체 렌더링 (Skia/Impeller) |
| 웹 코드 공유 | 높음 (React 생태계) | 낮음 |
| 성능 | New Arch로 네이티브 근접 | 처음부터 네이티브 수준 |
| 학습 곡선 | React 개발자: 매우 낮음 | 새 언어 학습 필요 |
| UI 느낌 | 플랫폼 네이티브 | 모든 플랫폼 동일 |
| 적합 | React 팀 확장, 웹+앱 공유 | 커스텀 UI, 성능 중시 |

**선택 기준:**
- React 팀 + 웹 코드 공유 중요 → React Native
- 새 팀 + 커스텀 UI/애니메이션 핵심 → Flutter
- 기존 네이티브 앱에 부분 도입 → React Native (Brownfield 우수)

---

### 4. 코드 공유 전략

#### 모노레포 구조

```
my-app/
├── apps/
│   ├── web/         # Next.js
│   └── mobile/      # Expo
├── packages/
│   ├── shared/      # 비즈니스 로직, 타입, API, 훅
│   ├── ui/          # 공유 UI (NativeWind/Tamagui)
│   └── config/      # ESLint, TS 설정
├── turbo.json
└── pnpm-workspace.yaml
```

#### 공유 훅 예시

```typescript
// packages/shared/src/hooks/useUser.ts
import { useQuery } from '@tanstack/react-query';

export function useUser(userId: string) {
  return useQuery({
    queryKey: ['user', userId],
    queryFn: () => apiClient.get(`/users/${userId}`),
  });
}
```

웹과 모바일에서 **동일한 훅**을 import:

```tsx
// apps/web (Next.js)              // apps/mobile (Expo)
import { useUser } from            import { useUser } from
  '@myapp/shared';                   '@myapp/shared';
// UI만 다름                        // UI만 다름
<div>{user.name}</div>             <Text>{user.name}</Text>
```

#### NativeWind로 스타일 공유

```tsx
// packages/ui/src/Button.tsx — 웹+네이티브 동일 코드
import { Pressable, Text } from 'react-native';

export function Button({ title, onPress, variant = 'primary' }) {
  return (
    <Pressable
      onPress={onPress}
      className={`px-4 py-2 rounded-lg ${
        variant === 'primary' ? 'bg-blue-500' : 'bg-gray-200'
      }`}
    >
      <Text className={variant === 'primary' ? 'text-white' : 'text-gray-800'}>
        {title}
      </Text>
    </Pressable>
  );
}
```

현실적 공유율: 비즈니스 로직 70~80%, UI 컴포넌트 30~50%

---

### 5. 네이티브 기능 접근

#### Expo SDK

```tsx
import * as Location from 'expo-location';
import * as LocalAuthentication from 'expo-local-authentication';

// GPS
const { status } = await Location.requestForegroundPermissionsAsync();
const location = await Location.getCurrentPositionAsync({});

// 생체 인증
const result = await LocalAuthentication.authenticateAsync({
  promptMessage: '본인 확인',
});
```

#### Expo Modules (커스텀 네이티브)

```swift
// iOS — Swift
public class MyModule: Module {
  public func definition() -> ModuleDefinition {
    Name("MyModule")
    Function("getDeviceId") { () -> String in
      UIDevice.current.identifierForVendor?.uuidString ?? ""
    }
  }
}
```

```tsx
// JS에서 사용
import MyModule from './modules/my-module';
const id = MyModule.getDeviceId();
```

---

## 실전 코드 예제

### 플랫폼 분기 컴포넌트

```tsx
// VideoPlayer.web.tsx — 웹 전용
export function VideoPlayer({ url }) {
  return <video src={url} controls style={{ width: '100%' }} />;
}

// VideoPlayer.native.tsx — 네이티브 전용
import { Video } from 'expo-av';
export function VideoPlayer({ url }) {
  return <Video source={{ uri: url }} useNativeControls style={{ height: 300 }} />;
}
// → import { VideoPlayer } from './VideoPlayer' 하면 자동 분기
```

### OTA 업데이트

```tsx
import * as Updates from 'expo-updates';

async function checkForUpdates() {
  if (__DEV__) return;
  const update = await Updates.checkForUpdateAsync();
  if (update.isAvailable) {
    await Updates.fetchUpdateAsync();
    await Updates.reloadAsync(); // 즉시 적용
  }
}
```

**제한:** JS 번들 + 에셋만 업데이트 가능. 네이티브 코드 변경 시 새 빌드 + 스토어 심사 필요.

---

## 도입 판단 기준

```
앱이 필요한가?
├── 내부 도구/관리자 → PWA or WebView로 충분
└── 사용자 대면 앱
      ├── 복잡한 네이티브(AR, 비디오 편집) → Native or Flutter
      ├── React 팀 + 웹 공유 → React Native (Expo)
      └── 새 팀 + 커스텀 UI → Flutter
```

| 기준 | WebView | React Native |
|------|---------|-------------|
| 성능 | 웹 수준 | 네이티브 근접 |
| UX | 이질감 | 네이티브 느낌 |
| 개발 속도 | 매우 빠름 | 빠름 |
| 적합 | PoC, 내부 도구 | 사용자 대면 앱 |

**Expo vs Bare:**
- 대부분의 앱 → Expo (Managed)로 충분
- 2024년 기준 "eject"는 거의 불필요 (Expo Modules + Config Plugins)

**앱스토어 심사:**
- React Native/Expo 앱은 일반적으로 심사 통과에 문제없음
- OTA는 허용하지만 앱의 핵심 목적 변경은 금지

---

## 면접 포인트

### Q1. React Native의 New Architecture를 설명하시오

> 기존 Bridge(JSON 직렬화, 비동기)의 병목을 해결하는 아키텍처.
> **JSI**(동기적 네이티브 호출), **Fabric**(C++ 렌더러, Concurrent 지원),
> **TurboModules**(lazy loading + codegen), **Hermes**(바이트코드 사전 컴파일).
> 결과: 프레임 드롭 감소, 앱 시작 시간 단축, 타입 안전성 향상.

### Q2. Bridge와 JSI의 차이는?

| Bridge | JSI |
|--------|-----|
| 비동기 메시지 큐 | 동기 함수 호출 |
| JSON 직렬화 | 직접 참조 (zero-copy) |
| Java/ObjC 구현 | C++ 구현 |

### Q3. 웹과 모바일에서 코드를 어떻게 공유하는가?

> 모노레포에서 `packages/shared`에 로직·훅·타입을 두고 양쪽에서 import.
> UI는 NativeWind/Tamagui 또는 `.web.tsx`/`.native.tsx` 확장자로 분기.
> 비즈니스 로직 70~80%, UI 30~50% 공유가 현실적.

### Q4. React Native vs Flutter 선택 기준은?

> React 팀 + 웹 공유 → RN. 새 팀 + 커스텀 UI → Flutter.
> RN은 네이티브 컴포넌트 활용(플랫폼 느낌), Flutter는 자체 렌더링(일관된 UI).

### Q5. Expo의 장단점은?

> **장점:** Zero-config 시작, EAS 자동화, OTA 업데이트, SDK 풍부
> **단점:** EAS 무료 티어 제한(월 30회), 일부 네이티브 호환 이슈, 클라우드 빌드 시간

---

## 참고 자료

- [React Native 공식 — New Architecture](https://reactnative.dev/docs/the-new-architecture/landing-page)
- [Expo Router 공식 문서](https://docs.expo.dev/router/introduction/)
- [Expo Modules API](https://docs.expo.dev/modules/overview/)
- [NativeWind](https://www.nativewind.dev/)
- [Tamagui](https://tamagui.dev/)
- [EAS 서비스](https://docs.expo.dev/eas/)
- [Hermes 엔진](https://hermesengine.dev/)
- [Turborepo](https://turbo.build/repo)
