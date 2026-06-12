# 11. Device APIs

## 목차
1. Geolocation API
2. DeviceOrientation / DeviceMotion
3. Vibration API
4. Battery API
5. 기타 디바이스 API
6. 면접 포인트

---

## 1. Geolocation API

HTTPS 또는 localhost에서만 동작하며, 사용자 허용이 필요하다.

### 현재 위치 조회

```js
if (!navigator.geolocation) {
  console.warn('Geolocation 미지원 브라우저');
  return;
}

// 한 번 조회
navigator.geolocation.getCurrentPosition(
  (position) => {
    const { latitude, longitude, accuracy } = position.coords;
    console.log(`위도: ${latitude}, 경도: ${longitude}`);
    console.log(`정확도: ${accuracy}m`);
    console.log(`고도: ${position.coords.altitude}m`); // GPS 있을 때
    console.log(`속도: ${position.coords.speed}m/s`);  // 이동 중일 때
  },
  (error) => {
    switch (error.code) {
      case error.PERMISSION_DENIED:
        console.error('위치 권한 거부');
        break;
      case error.POSITION_UNAVAILABLE:
        console.error('위치 정보 불가');
        break;
      case error.TIMEOUT:
        console.error('타임아웃');
        break;
    }
  },
  {
    enableHighAccuracy: true,  // GPS 우선 사용 (배터리 많이 사용)
    timeout: 10000,            // 최대 10초 대기 (ms)
    maximumAge: 5000,          // 5초 내 캐시 허용 (ms)
  }
);
```

### 위치 추적 (실시간)

```js
const watchId = navigator.geolocation.watchPosition(
  (position) => updateMap(position.coords),
  handleError,
  { enableHighAccuracy: true, timeout: 5000, maximumAge: 0 }
);

// 추적 중지
navigator.geolocation.clearWatch(watchId);
```

### Promise 래퍼

```js
function getCurrentPosition(options = {}) {
  return new Promise((resolve, reject) => {
    navigator.geolocation.getCurrentPosition(resolve, reject, options);
  });
}

// 사용
try {
  const { coords } = await getCurrentPosition({ enableHighAccuracy: true });
  const mapUrl = `https://maps.google.com/?q=${coords.latitude},${coords.longitude}`;
} catch (err) {
  if (err.code === 1) alert('위치 권한을 허용해주세요.');
}
```

### 두 지점 거리 계산 (Haversine)

```js
function getDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // 지구 반지름 (km)
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}
```

---

## 2. DeviceOrientation / DeviceMotion

모바일 기기의 자이로스코프, 가속도계 데이터를 제공한다.

### DeviceOrientationEvent

```js
// iOS 13+에서 권한 요청 필요
async function requestMotionPermission() {
  if (typeof DeviceOrientationEvent.requestPermission === 'function') {
    const permission = await DeviceOrientationEvent.requestPermission();
    if (permission !== 'granted') throw new Error('권한 거부');
  }
}

window.addEventListener('deviceorientation', (event) => {
  // alpha: 나침반 방향 (0~360, Z축 회전)
  // beta: 앞뒤 기울기 (-180~180, X축 회전)
  // gamma: 좌우 기울기 (-90~90, Y축 회전)
  const { alpha, beta, gamma } = event;

  // 화면 기울기에 따라 요소 이동 (틸트 효과)
  const tiltX = Math.max(-20, Math.min(20, gamma));
  const tiltY = Math.max(-20, Math.min(20, beta));
  card.style.transform = `rotateX(${-tiltY}deg) rotateY(${tiltX}deg)`;
});
```

### DeviceMotionEvent

```js
window.addEventListener('devicemotion', (event) => {
  // 가속도 (중력 제외)
  const { x, y, z } = event.acceleration;

  // 가속도 (중력 포함)
  const { x: gx, y: gy, z: gz } = event.accelerationIncludingGravity;

  // 회전 속도 (deg/s)
  const { alpha, beta, gamma } = event.rotationRate;

  // 흔들기 감지
  const magnitude = Math.sqrt(x**2 + y**2 + z**2);
  if (magnitude > 15) {
    triggerShakeAction();
  }
});
```

---

## 3. Vibration API

```js
// 200ms 진동
navigator.vibrate(200);

// 패턴: [진동, 대기, 진동] (ms)
navigator.vibrate([200, 100, 200]);

// 알림 패턴
navigator.vibrate([100, 50, 100, 50, 300]);

// 진동 중지
navigator.vibrate(0);
navigator.vibrate([]);

// 지원 여부 확인
if ('vibrate' in navigator) {
  navigator.vibrate(50); // 햅틱 피드백
}
```

### 사용 사례

```js
// 버튼 탭 햅틱 피드백 (모바일 앱 느낌)
button.addEventListener('click', () => {
  navigator.vibrate?.(10); // optional chaining으로 미지원 시 무시
});

// 게임 충돌 피드백
function onCollision() {
  navigator.vibrate?.([100, 50, 100]);
}

// 폼 유효성 실패
function onValidationError() {
  navigator.vibrate?.([50, 30, 50, 30, 50]);
}
```

---

## 4. Battery API

```js
const battery = await navigator.getBattery();

console.log(`충전 중: ${battery.charging}`);
console.log(`배터리 잔량: ${(battery.level * 100).toFixed(0)}%`);
console.log(`완충까지: ${battery.chargingTime}초`);
console.log(`방전까지: ${battery.dischargingTime}초`);

// 이벤트 리스너
battery.addEventListener('chargingchange', () => {
  console.log(battery.charging ? '충전 시작' : '충전 중지');
});

battery.addEventListener('levelchange', () => {
  if (battery.level < 0.1) {
    showLowBatteryWarning();
  }
});

// 배터리 절약 모드에서 기능 제한
function adjustForBattery(battery) {
  if (battery.level < 0.2 && !battery.charging) {
    disableAnimations();
    reducePollingFrequency();
  }
}
```

> Battery Status API는 개인정보 침해 우려로 Firefox에서 제거됨. Chrome에서는 여전히 지원.

---

## 5. 기타 디바이스 API

### Ambient Light Sensor

```js
if ('AmbientLightSensor' in window) {
  const sensor = new AmbientLightSensor();
  sensor.addEventListener('reading', () => {
    console.log(`주변 밝기: ${sensor.illuminance} lux`);
    // 어두우면 다크 모드 전환
    if (sensor.illuminance < 50) applyDarkMode();
  });
  sensor.start();
}
```

### Screen Orientation API

```js
const orientation = screen.orientation;
console.log(orientation.type);  // 'portrait-primary' | 'landscape-primary' | ...
console.log(orientation.angle); // 0 | 90 | 180 | 270

orientation.addEventListener('change', () => {
  console.log('화면 방향 변경:', orientation.type);
});

// 화면 방향 잠금 (모바일 앱에서)
await screen.orientation.lock('landscape');
screen.orientation.unlock();
```

### Wake Lock API (화면 자동 꺼짐 방지)

```js
let wakeLock = null;

async function requestWakeLock() {
  try {
    wakeLock = await navigator.wakeLock.request('screen');
    console.log('화면 유지 활성');

    wakeLock.addEventListener('release', () => {
      console.log('Wake Lock 해제');
    });
  } catch (err) {
    console.error('Wake Lock 실패:', err);
  }
}

// 해제
async function releaseWakeLock() {
  await wakeLock?.release();
  wakeLock = null;
}

// 탭 비활성화 시 자동 해제 → 재활성화 시 재요청
document.addEventListener('visibilitychange', async () => {
  if (document.visibilityState === 'visible' && wakeLock !== null) {
    await requestWakeLock();
  }
});
```

---

## 6. 면접 포인트

**Q. Geolocation의 `enableHighAccuracy: true`가 항상 GPS를 사용하나?**

GPS를 우선적으로 요청하지만, 실내나 GPS 미지원 기기에서는 Wi-Fi/셀룰러 기반 위치를 반환한다. 배터리 소모가 크고 응답이 느릴 수 있으므로, 배달 앱 같은 고정밀 위치가 필요한 경우에만 사용한다.

**Q. DeviceOrientation 이벤트가 iOS에서 동작하지 않는 이유는?**

iOS 13부터 DeviceMotionEvent/DeviceOrientationEvent 사용 시 명시적 사용자 허가가 필요하다. `DeviceOrientationEvent.requestPermission()`을 사용자 제스처(click 등) 핸들러에서 호출해야 한다.

**Q. Vibration API가 모든 환경에서 동작하나?**

Android Chrome에서는 잘 동작하지만, iOS Safari는 미지원이다. 또한 일부 기기에서는 저전력 모드나 시스템 설정에 따라 무시될 수 있다. `navigator.vibrate?.()` 형태로 존재 여부를 확인하고 호출하는 것이 안전하다.

**Q. Wake Lock이 자동으로 해제되는 경우는?**

탭이 백그라운드로 이동하거나(visibilitychange), 시스템 레벨에서 잠금(배터리 부족, 긴급 전화 등)이 발생할 때 자동 해제된다. `release` 이벤트를 듣고 필요하면 재요청해야 한다.
