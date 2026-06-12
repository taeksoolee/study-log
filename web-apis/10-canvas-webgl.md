# 10. Canvas & WebGL

## 목차
1. Canvas 2D API 기초
2. 도형 그리기
3. 텍스트 및 이미지 처리
4. requestAnimationFrame 애니메이션 루프
5. WebGL 개념 및 Three.js 입문
6. 면접 포인트

---

## 1. Canvas 2D API 기초

```html
<canvas id="canvas" width="800" height="600"></canvas>
```

```js
const canvas = document.getElementById('canvas');
const ctx = canvas.getContext('2d');

// DPR(Device Pixel Ratio) 대응 — 레티나 디스플레이 선명하게
function setupHDCanvas(canvas) {
  const dpr = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();

  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  canvas.style.width = rect.width + 'px';
  canvas.style.height = rect.height + 'px';

  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr); // 논리 픽셀 기준으로 그리기
  return ctx;
}
```

### Context 상태 저장/복원

```js
ctx.save();    // 현재 상태(변환, 스타일 등) 스택에 푸시
ctx.restore(); // 마지막 저장 상태로 복원

// 패턴
ctx.save();
ctx.translate(100, 100);
ctx.rotate(Math.PI / 4);
drawSomething(ctx);
ctx.restore(); // 변환 취소
```

---

## 2. 도형 그리기

```js
// 사각형
ctx.fillStyle = '#6366f1';
ctx.fillRect(x, y, width, height);
ctx.strokeStyle = '#000';
ctx.lineWidth = 2;
ctx.strokeRect(x, y, width, height);
ctx.clearRect(x, y, width, height); // 영역 지우기

// 패스 기반 도형
ctx.beginPath();
ctx.moveTo(50, 50);
ctx.lineTo(200, 50);
ctx.lineTo(200, 200);
ctx.closePath();
ctx.fill();
ctx.stroke();

// 원/호
ctx.beginPath();
ctx.arc(cx, cy, radius, startAngle, endAngle, counterclockwise);
ctx.arc(100, 100, 50, 0, Math.PI * 2); // 원
ctx.arc(100, 100, 50, 0, Math.PI);     // 반원 (위쪽)
ctx.fill();

// 둥근 사각형 (최신 API)
ctx.beginPath();
ctx.roundRect(x, y, width, height, borderRadius);
ctx.fill();

// 베지어 곡선
ctx.beginPath();
ctx.moveTo(50, 200);
ctx.bezierCurveTo(150, 50, 250, 350, 350, 200); // 3차 베지어
ctx.stroke();

// 그라디언트
const gradient = ctx.createLinearGradient(0, 0, canvas.width, 0);
gradient.addColorStop(0, '#6366f1');
gradient.addColorStop(1, '#ec4899');
ctx.fillStyle = gradient;
ctx.fillRect(0, 0, canvas.width, 50);

// 방사형 그라디언트
const radial = ctx.createRadialGradient(cx, cy, 0, cx, cy, radius);
radial.addColorStop(0, 'white');
radial.addColorStop(1, 'transparent');
```

---

## 3. 텍스트 및 이미지 처리

```js
// 텍스트
ctx.font = 'bold 24px sans-serif';
ctx.textAlign = 'center';    // left | right | center | start | end
ctx.textBaseline = 'middle'; // top | hanging | middle | alphabetic | ideographic | bottom
ctx.fillStyle = '#111';
ctx.fillText('Hello Canvas', x, y);
ctx.strokeText('Outlined', x, y);

// 텍스트 측정
const metrics = ctx.measureText('Hello');
console.log(metrics.width);
console.log(metrics.actualBoundingBoxAscent + metrics.actualBoundingBoxDescent); // 높이

// 이미지 그리기
const img = new Image();
img.onload = () => {
  ctx.drawImage(img, dx, dy);                    // 위치만
  ctx.drawImage(img, dx, dy, dw, dh);            // 리사이즈
  ctx.drawImage(img, sx, sy, sw, sh, dx, dy, dw, dh); // 크롭 + 리사이즈
};
img.src = '/photo.jpg';

// 픽셀 조작
const imageData = ctx.getImageData(x, y, width, height);
const { data, width: w, height: h } = imageData;
// data: Uint8ClampedArray [R, G, B, A, R, G, B, A, ...]

// 그레이스케일 필터
for (let i = 0; i < data.length; i += 4) {
  const avg = (data[i] + data[i+1] + data[i+2]) / 3;
  data[i] = data[i+1] = data[i+2] = avg;
}
ctx.putImageData(imageData, x, y);

// Canvas를 이미지/Blob으로 내보내기
const dataURL = canvas.toDataURL('image/png');
const dataURLJpeg = canvas.toDataURL('image/jpeg', 0.8); // 품질 0.8

canvas.toBlob(blob => {
  const url = URL.createObjectURL(blob);
  // 다운로드 링크 생성
}, 'image/webp', 0.9);
```

---

## 4. requestAnimationFrame 애니메이션 루프

```js
class AnimationLoop {
  #rafId = null;
  #lastTime = 0;
  #running = false;

  start() {
    if (this.#running) return;
    this.#running = true;
    this.#lastTime = performance.now();
    this.#rafId = requestAnimationFrame(this.#loop.bind(this));
  }

  stop() {
    this.#running = false;
    if (this.#rafId) {
      cancelAnimationFrame(this.#rafId);
      this.#rafId = null;
    }
  }

  #loop(timestamp) {
    if (!this.#running) return;

    const deltaTime = timestamp - this.#lastTime; // ms
    this.#lastTime = timestamp;

    this.update(deltaTime / 1000); // 초 단위로 변환
    this.render();

    this.#rafId = requestAnimationFrame(this.#loop.bind(this));
  }

  update(dt) { /* 상태 업데이트 */ }
  render() { /* 그리기 */ }
}
```

### 실제 파티클 예제

```js
const canvas = document.getElementById('canvas');
const ctx = canvas.getContext('2d');

const particles = Array.from({ length: 100 }, () => ({
  x: Math.random() * canvas.width,
  y: Math.random() * canvas.height,
  vx: (Math.random() - 0.5) * 2,
  vy: (Math.random() - 0.5) * 2,
  r: Math.random() * 4 + 1,
  color: `hsl(${Math.random() * 360}, 70%, 60%)`,
}));

function update(dt) {
  for (const p of particles) {
    p.x += p.vx * dt * 60;
    p.y += p.vy * dt * 60;
    if (p.x < 0 || p.x > canvas.width) p.vx *= -1;
    if (p.y < 0 || p.y > canvas.height) p.vy *= -1;
  }
}

function render() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  for (const p of particles) {
    ctx.beginPath();
    ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
    ctx.fillStyle = p.color;
    ctx.fill();
  }
}

let last = 0;
function loop(ts) {
  const dt = Math.min((ts - last) / 1000, 0.05); // 최대 50ms 제한
  last = ts;
  update(dt);
  render();
  requestAnimationFrame(loop);
}
requestAnimationFrame(loop);
```

---

## 5. WebGL 개념 및 Three.js 입문

### WebGL 개념

WebGL은 OpenGL ES 기반의 저수준 3D 그래픽 API다.

```
CPU(JS)  →  Vertex Buffer  →  Vertex Shader  →  Rasterization  →  Fragment Shader  →  화면
```

- **Vertex Shader**: 각 꼭짓점의 위치 계산 (GLSL)
- **Fragment Shader**: 각 픽셀의 색상 계산 (GLSL)
- **Buffer**: GPU에 올린 데이터 배열
- **Uniform**: JS에서 Shader로 전달하는 변수

### Three.js 기본 장면

```bash
npm install three
```

```js
import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

// 1. 장면(Scene) 설정
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x111111);

// 2. 카메라
const camera = new THREE.PerspectiveCamera(
  75,                                    // FOV (도)
  window.innerWidth / window.innerHeight, // 종횡비
  0.1,                                   // near
  1000                                   // far
);
camera.position.set(0, 1, 5);

// 3. 렌더러
const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(window.devicePixelRatio);
document.body.appendChild(renderer.domElement);

// 4. 오브젝트 생성
const geometry = new THREE.BoxGeometry(1, 1, 1);
const material = new THREE.MeshStandardMaterial({ color: 0x6366f1, roughness: 0.4 });
const cube = new THREE.Mesh(geometry, material);
scene.add(cube);

// 5. 조명
const light = new THREE.DirectionalLight(0xffffff, 1);
light.position.set(5, 10, 5);
scene.add(light);
scene.add(new THREE.AmbientLight(0xffffff, 0.3));

// 6. 컨트롤
const controls = new OrbitControls(camera, renderer.domElement);

// 7. 애니메이션 루프
function animate() {
  requestAnimationFrame(animate);
  cube.rotation.x += 0.01;
  cube.rotation.y += 0.01;
  controls.update();
  renderer.render(scene, camera);
}
animate();

// 8. 리사이즈 대응
window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});
```

---

## 6. 면접 포인트

**Q. requestAnimationFrame이 setTimeout보다 나은 이유는?**

rAF는 브라우저 렌더링 사이클에 맞게 호출되어(보통 60fps = 16.7ms) 불필요한 중간 프레임을 건너뛴다. 탭이 비활성화되면 자동으로 실행이 중지되어 CPU/배터리를 절약한다. setTimeout(1000/60)은 정밀하지 않고 탭 비활성 시에도 실행된다.

**Q. Canvas와 SVG의 성능 특성 차이는?**

Canvas는 픽셀 기반 즉각 모드(immediate mode)로, 요소가 많아도 성능이 일정하다. 변경 시 전체를 다시 그려야 한다. SVG는 유지 모드(retained mode)로, DOM 트리를 유지해 이벤트 처리와 접근성이 좋지만 요소가 수천 개 이상이면 성능이 저하된다. 복잡한 애니메이션/게임 → Canvas, 인터랙티브 데이터 시각화 → SVG.

**Q. OffscreenCanvas는 무엇인가?**

Web Worker에서 Canvas를 그릴 수 있는 API다. 무거운 렌더링 로직을 메인 스레드에서 분리해 UI가 끊기지 않도록 한다.

```js
const offscreen = canvas.transferControlToOffscreen();
worker.postMessage({ canvas: offscreen }, [offscreen]);
```

**Q. WebGL2와 WebGPU의 차이는?**

WebGL2는 OpenGL ES 3.0 기반으로 현재 광범위하게 지원된다. WebGPU는 Vulkan/Metal/D3D12 기반의 차세대 GPU API로 컴퓨트 셰이더, 멀티스레드 GPU 명령, 더 낮은 드라이버 오버헤드를 제공한다. 2024년 주요 브라우저에서 지원 중이다.
