# WebAssembly (Wasm) 프론트엔드 활용

> 브라우저에서 네이티브에 가까운 성능을 끌어내는 WebAssembly의 원리와 프론트엔드 활용법을 다룹니다.

---

## 개요

### WebAssembly란 무엇인가

WebAssembly(Wasm)는 **W3C 공식 표준**으로, 브라우저에서 네이티브에 가까운 속도로 실행되는 저수준 바이너리 포맷이다. JavaScript의 대체가 아니라 **보완** 기술로 설계되었다.

- 2017년 주요 브라우저(Chrome, Firefox, Safari, Edge) 동시 지원 시작
- 2019년 W3C 공식 웹 표준으로 채택
- 현재 전 세계 브라우저의 95% 이상이 지원

### JS의 성능 한계를 넘는 시나리오

| 작업 유형 | JS 한계 원인 | Wasm 이점 |
|-----------|-------------|-----------|
| 수치 연산 (행렬, 벡터) | 타입 추론 오버헤드 | 정적 타입, SIMD 지원 |
| 이미지/비디오 처리 | GC 일시정지 | 선형 메모리 직접 제어 |
| 암호화 | 최적화 불안정 | 예측 가능한 실행 성능 |
| 물리 시뮬레이션 | Hidden class 변경 비용 | AOT 컴파일 최적화 |

### Figma, Google Earth, Photoshop Web, AutoCAD가 Wasm을 쓰는 이유

- **Figma**: C++ 렌더링 엔진을 Wasm으로 컴파일 → 60fps 캔버스 렌더링
- **Google Earth**: 3D 지구본을 브라우저에서 네이티브 앱 수준으로 렌더링
- **Photoshop Web**: 이미지 필터·레이어 합성을 Wasm으로 처리
- **AutoCAD Web**: CAD 엔진(C++) 30년 코드베이스를 웹으로 이식

---

## 핵심 개념

### 1. Wasm 동작 원리

#### 스택 기반 가상 머신

```wat
;; .wat (WebAssembly Text Format) — 두 수의 합
(module
  (func $add (param $a i32) (param $b i32) (result i32)
    local.get $a    ;; 스택에 $a push
    local.get $b    ;; 스택에 $b push
    i32.add         ;; pop 2개 → 합산 → push
  )
  (export "add" (func $add))
)
```

#### .wasm 바이너리 vs .wat 텍스트 포맷

| 구분 | .wasm | .wat |
|------|-------|------|
| 형식 | 바이너리 | 텍스트 (S-expression) |
| 용도 | 브라우저 실행 | 디버깅, 학습 |
| 변환 | wat2wasm | wasm2wat |

#### JS와의 상호운용 (Import/Export)

```typescript
const importObject = {
  env: {
    log: (value: number) => console.log('Wasm says:', value),
    memory: new WebAssembly.Memory({ initial: 1 }),
  },
};

const { instance } = await WebAssembly.instantiateStreaming(
  fetch('/compute.wasm'),
  importObject
);
const result = instance.exports.heavyComputation(42);
```

#### Linear Memory 모델

Wasm은 하나의 연속된 바이트 배열(Linear Memory)을 사용한다.

```typescript
const memory = instance.exports.memory as WebAssembly.Memory;
const buffer = new Uint8Array(memory.buffer);
buffer.set(imageData, 0);                           // 데이터 복사
instance.exports.processImage(0, imageData.length); // Wasm이 메모리 내 직접 처리
const result = buffer.slice(0, imageData.length);   // 결과 읽기
```

---

### 2. JS vs Wasm 성능 비교

#### 언제 Wasm이 빠른가

| 시나리오 | 성능 향상 (대략) | 이유 |
|----------|-----------------|------|
| 행렬 곱셈 (1000×1000) | 5~20× | SIMD + 연속 메모리 접근 |
| SHA-256 해싱 | 3~10× | 비트 연산 최적화 |
| 이미지 블러 (4K) | 10~30× | 픽셀 단위 연속 처리 |
| 비디오 디코딩 | 10~50× | 네이티브 코덱 포팅 |

#### 언제 JS가 충분한가

- **DOM 조작**: Wasm은 DOM에 직접 접근 불가
- **일반 UI 로직**: 이벤트 핸들링, 폼 유효성 등
- **네트워크 IO**: 비동기 대기 시간이 지배적

#### JS → Wasm 호출 오버헤드 (FFI 비용)

```typescript
// ❌ 나쁜 패턴: 픽셀마다 호출 (호출 1회 ~100ns 오버헤드)
for (let i = 0; i < pixels.length; i++) {
  pixels[i] = instance.exports.processPixel(pixels[i]);
}

// ✅ 좋은 패턴: 벌크 전달 후 일괄 처리
const ptr = instance.exports.allocate(pixels.length);
new Uint8Array(memory.buffer).set(pixels, ptr);
instance.exports.processAllPixels(ptr, pixels.length);
```

> 💡 핵심: **JS↔Wasm 경계를 최소화**, 데이터는 Linear Memory를 통해 벌크 전달.

---

### 3. Wasm 생성 언어

#### Rust (wasm-pack, wasm-bindgen)

```toml
# Cargo.toml
[lib]
crate-type = ["cdylib"]

[dependencies]
wasm-bindgen = "0.2"
```

```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn grayscale(pixels: &mut [u8]) {
    for chunk in pixels.chunks_exact_mut(4) {
        let avg = ((chunk[0] as u16 + chunk[1] as u16 + chunk[2] as u16) / 3) as u8;
        chunk[0] = avg;
        chunk[1] = avg;
        chunk[2] = avg;
    }
}
```

```bash
wasm-pack build --target web --release
```

#### C/C++ (Emscripten)

```bash
emcc compute.c -O3 -s WASM=1 -o compute.js
```

#### AssemblyScript (TypeScript 서브셋 → Wasm)

```typescript
// assembly/index.ts
export function fibonacci(n: i32): i32 {
  if (n <= 1) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}
```

#### 언어별 비교

| 언어 | 출력 크기 | 생태계 | 학습 곡선 | 성능 |
|------|----------|--------|----------|------|
| Rust | ~50KB | 최고 | 높음 | 최고 |
| C/C++ | 중간 | 성숙 | 중간 | 최고 |
| TinyGo | ~100KB | 제한적 | 낮음 | 좋음 |
| AssemblyScript | ~10KB | 작음 | 매우 낮음 | 좋음 |

---

### 4. 브라우저 통합

#### instantiateStreaming (권장)

```typescript
// ✅ 다운로드와 컴파일 동시 진행 (스트리밍)
const { instance } = await WebAssembly.instantiateStreaming(
  fetch('/heavy.wasm'), // Content-Type: application/wasm 필요
  importObject
);
```

#### SharedArrayBuffer + Web Workers (멀티스레드)

```typescript
// 메인 스레드
const memory = new WebAssembly.Memory({ initial: 256, shared: true });
worker.postMessage({ memory });

// Worker 내부
self.onmessage = async (e) => {
  const { instance } = await WebAssembly.instantiateStreaming(
    fetch('/parallel.wasm'),
    { env: { memory: e.data.memory } }
  );
  instance.exports.processChunk(startOffset, chunkSize);
};
```

> ⚠️ `SharedArrayBuffer` 사용 시 필요한 헤더:
> `Cross-Origin-Opener-Policy: same-origin`
> `Cross-Origin-Embedder-Policy: require-corp`

#### WASI (WebAssembly System Interface)

Wasm 모듈이 파일 시스템·네트워크 등에 접근하는 표준 인터페이스. 브라우저 밖(서버, 엣지, IoT)에서도 Wasm 실행 가능.

---

## 실전 예제

### 예제 1: Rust → Wasm 이미지 처리 (React 통합)

**Rust (src/lib.rs):**
```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn sepia(pixels: &mut [u8]) {
    for chunk in pixels.chunks_exact_mut(4) {
        let (r, g, b) = (chunk[0] as f32, chunk[1] as f32, chunk[2] as f32);
        chunk[0] = ((r * 0.393) + (g * 0.769) + (b * 0.189)).min(255.0) as u8;
        chunk[1] = ((r * 0.349) + (g * 0.686) + (b * 0.168)).min(255.0) as u8;
        chunk[2] = ((r * 0.272) + (g * 0.534) + (b * 0.131)).min(255.0) as u8;
    }
}
```

**React 컴포넌트:**
```tsx
import { useRef, useState, useCallback } from 'react';
import init, { sepia } from 'wasm-image';

export function ImageProcessor() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [timing, setTiming] = useState({ wasm: 0, js: 0 });

  const applyWasm = useCallback(async () => {
    await init();
    const ctx = canvasRef.current!.getContext('2d')!;
    const imageData = ctx.getImageData(0, 0, 1920, 1080);

    const start = performance.now();
    sepia(imageData.data);
    setTiming(t => ({ ...t, wasm: performance.now() - start }));

    ctx.putImageData(imageData, 0, 0);
  }, []);

  return (
    <div>
      <canvas ref={canvasRef} width={1920} height={1080} />
      <button onClick={applyWasm}>Sepia (Wasm)</button>
      <p>Wasm: {timing.wasm.toFixed(2)}ms | JS: {timing.js.toFixed(2)}ms</p>
    </div>
  );
}
```

> 📊 1920×1080 벤치마크: JS ~12ms vs Wasm ~3ms (약 4배)

### 예제 2: 웹 기반 PDF 렌더러

```typescript
import * as pdfjsLib from 'pdfjs-dist';

pdfjsLib.GlobalWorkerOptions.workerSrc = '/pdf.worker.min.mjs';

async function renderPDF(url: string, canvas: HTMLCanvasElement) {
  const pdf = await pdfjsLib.getDocument(url).promise;
  const page = await pdf.getPage(1);
  const viewport = page.getViewport({ scale: 2.0 });
  canvas.width = viewport.width;
  canvas.height = viewport.height;
  await page.render({ canvasContext: canvas.getContext('2d')!, viewport }).promise;
}
```

### 예제 3: ffmpeg.wasm (비디오 트랜스코딩)

```typescript
import { FFmpeg } from '@ffmpeg/ffmpeg';
import { fetchFile, toBlobURL } from '@ffmpeg/util';

async function convertVideo(input: File): Promise<string> {
  const ffmpeg = new FFmpeg();
  await ffmpeg.load({
    coreURL: await toBlobURL('/ffmpeg-core.wasm', 'application/wasm'),
  });

  await ffmpeg.writeFile('input.mp4', await fetchFile(input));
  await ffmpeg.exec(['-i', 'input.mp4', '-c:v', 'libvpx-vp9', 'output.webm']);

  const data = await ffmpeg.readFile('output.webm');
  return URL.createObjectURL(new Blob([data], { type: 'video/webm' }));
}
```

---

## 실전 도입 고려사항

### 번들 사이즈

| 라이브러리 | .wasm 크기 | gzip 후 |
|-----------|-----------|---------|
| 단순 연산 (Rust) | ~50KB | ~20KB |
| 이미지 처리 | ~200KB | ~80KB |
| ffmpeg.wasm | ~25MB | ~8MB |
| SQLite.wasm | ~1MB | ~400KB |

### 초기 로딩 전략

```typescript
// 1. Lazy Load — 사용자 액션 시 로드
const loadWasm = () => import('./pkg/image_processor');

// 2. Preload 힌트
// <link rel="preload" href="/critical.wasm" as="fetch" crossorigin>

// 3. Cache API로 컴파일 결과 저장
const cache = await caches.open('wasm-v1');
```

### 디버깅

| 방법 | 상태 | 비고 |
|------|------|------|
| Chrome DevTools | ✅ | .wasm 소스 패널 스텝 실행 |
| DWARF 디버그 | ⚠️ 실험적 | Rust/C++ 소스 레벨 |
| console.log 브릿지 | ✅ | 가장 현실적 |

### SEO/SSR

- Wasm은 클라이언트 실행 → SEO 직접 영향 없음
- 서버에서 Wasm 실행 가능 (Wasmer, Wasmtime)
- 크롤러는 Wasm 실행 불가 → 중요 콘텐츠는 HTML로 제공

---

## 미래 전망

### Wasm GC (Garbage Collection)

고수준 언어(Kotlin, Dart, C#)가 브라우저 내장 GC를 공유하여 바이너리 크기 대폭 감소. Chrome 119+, Firefox 120+ 지원. Flutter Web이 Wasm GC 기반 전환 중.

### Component Model

서로 다른 언어로 작성된 Wasm 모듈들이 표준 인터페이스로 직접 통신하는 모델. 언어 간 상호운용성의 미래.

### Wasm + AI (On-Device Inference)

```typescript
import * as ort from 'onnxruntime-web';
ort.env.wasm.wasmPaths = '/ort-wasm/';

const session = await ort.InferenceSession.create('/model.onnx', {
  executionProviders: ['wasm'],
});
const results = await session.run({ input: tensor });
```

- 프라이버시: 데이터가 서버로 전송되지 않음
- 레이턴시: 네트워크 왕복 없이 즉시 추론

---

## 면접 포인트

### Q1. WebAssembly란 무엇이고 언제 사용하는가?

> Wasm은 W3C 표준 바이너리 포맷으로 네이티브에 가까운 속도로 실행된다. JS 성능이 병목인 수치 연산, 이미지/비디오 처리, 암호화, 게임 엔진 등에 사용한다. JS를 대체하는 게 아니라, 성능 크리티컬 부분만 오프로드하는 보완 관계다.

### Q2. JS와 Wasm의 성능 차이는 어디에서 오는가?

> ① 정적 타입 → 컴파일 시점 최적화 (JS는 런타임 타입 추론)
> ② 선형 메모리 직접 접근 → GC 없음
> ③ SIMD 명령어 활용
> ④ AOT 컴파일 → 예측 가능한 성능 (JS JIT는 워밍업 필요)

### Q3. Wasm이 DOM을 직접 조작할 수 없는 이유는?

> Wasm은 샌드박스 환경에서 실행되며, 보안·이식성을 위해 브라우저 API 직접 접근을 설계에서 배제했다. DOM 조작은 JS import 함수를 통해서만 가능하다.

### Q4. Wasm 도입의 트레이드오프는?

> **장점**: 연산 성능 향상, C++/Rust 코드 재활용, 예측 가능한 성능
> **단점**: 번들 크기 증가, 디버깅 어려움, FFI 오버헤드, 팀 내 Rust/C++ 역량 필요

### Q5. AssemblyScript vs Rust Wasm?

> **AssemblyScript**: TS 유사 문법, 학습 곡선 낮음, 출력 ~10KB, 생태계 작음
> **Rust**: 학습 곡선 높지만 도구 성숙(wasm-pack), 최고 성능, 메모리 안전. 프로덕션 표준.

---

## 참고 자료

- [WebAssembly 공식](https://webassembly.org/)
- [wasm-pack](https://rustwasm.github.io/wasm-pack/)
- [Emscripten](https://emscripten.org/)
- [ffmpeg.wasm](https://ffmpegwasm.netlify.app/)
- [AssemblyScript](https://www.assemblyscript.org/)
- [Wasm by Example](https://wasmbyexample.dev/)
