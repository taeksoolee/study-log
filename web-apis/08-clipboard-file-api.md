# 8. Clipboard & File API

## 목차
1. Clipboard API 개요
2. 클립보드 쓰기 (복사)
3. 클립보드 읽기 (붙여넣기)
4. File API 개요
5. Drag & Drop 파일 처리
6. FileReader vs File.text()
7. 면접 포인트

---

## 1. Clipboard API 개요

`navigator.clipboard`는 비동기 Clipboard API다. HTTPS 또는 localhost에서만 동작하며, 일부 작업은 사용자 권한이 필요하다.

```js
// 권한 확인
const permission = await navigator.permissions.query({ name: 'clipboard-read' });
console.log(permission.state); // 'granted' | 'denied' | 'prompt'
```

| 메서드 | 설명 | 권한 |
|--------|------|------|
| `writeText()` | 텍스트 복사 | 자동 허용 (포커스 필요) |
| `readText()` | 텍스트 붙여넣기 | 사용자 허용 필요 |
| `write()` | 다양한 타입 복사 | 포커스 필요 |
| `read()` | 다양한 타입 읽기 | 사용자 허용 필요 |

---

## 2. 클립보드 쓰기 (복사)

### 텍스트 복사

```js
async function copyText(text) {
  try {
    await navigator.clipboard.writeText(text);
    console.log('복사 완료!');
  } catch (err) {
    // 폴백: 구형 방식
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    textarea.select();
    document.execCommand('copy');
    document.body.removeChild(textarea);
  }
}
```

### 복사 버튼 컴포넌트

```js
function CopyButton({ text }) {
  const [copied, setCopied] = useState(false);

  async function handleCopy() {
    await navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  return (
    <button onClick={handleCopy}>
      {copied ? '복사됨!' : '복사'}
    </button>
  );
}
```

### 이미지/HTML 복사

```js
async function copyImage(imageUrl) {
  const res = await fetch(imageUrl);
  const blob = await res.blob();

  await navigator.clipboard.write([
    new ClipboardItem({ [blob.type]: blob })
  ]);
}

async function copyRichText(html, plainText) {
  await navigator.clipboard.write([
    new ClipboardItem({
      'text/html': new Blob([html], { type: 'text/html' }),
      'text/plain': new Blob([plainText], { type: 'text/plain' }),
    })
  ]);
}
```

---

## 3. 클립보드 읽기 (붙여넣기)

### 텍스트 읽기

```js
async function pasteText() {
  try {
    const text = await navigator.clipboard.readText();
    document.querySelector('#input').value = text;
  } catch (err) {
    if (err.name === 'NotAllowedError') {
      alert('클립보드 접근 권한이 필요합니다.');
    }
  }
}
```

### 이미지 붙여넣기 (paste 이벤트)

```js
document.addEventListener('paste', async (event) => {
  const items = event.clipboardData.items;

  for (const item of items) {
    if (item.type.startsWith('image/')) {
      const blob = item.getAsFile();
      const url = URL.createObjectURL(blob);

      const img = document.createElement('img');
      img.src = url;
      document.body.appendChild(img);

      // 메모리 해제
      img.onload = () => URL.revokeObjectURL(url);
      break;
    }
  }
});
```

### Clipboard API로 다양한 타입 읽기

```js
async function readClipboard() {
  const items = await navigator.clipboard.read();

  for (const item of items) {
    console.log('지원 타입:', item.types);

    if (item.types.includes('image/png')) {
      const blob = await item.getType('image/png');
      displayImage(blob);
    } else if (item.types.includes('text/plain')) {
      const blob = await item.getType('text/plain');
      const text = await blob.text();
      displayText(text);
    }
  }
}
```

---

## 4. File API 개요

File API는 `<input type="file">`이나 Drag & Drop으로 받은 파일을 처리하는 API다.

```js
const fileInput = document.querySelector('input[type="file"]');

fileInput.addEventListener('change', () => {
  const files = fileInput.files; // FileList (유사 배열)

  for (const file of files) {
    console.log(file.name);          // 파일명
    console.log(file.size);          // 바이트 크기
    console.log(file.type);          // MIME 타입
    console.log(file.lastModified);  // 수정일 (timestamp)
    console.log(file instanceof Blob); // true (File extends Blob)
  }
});
```

---

## 5. Drag & Drop 파일 처리

```html
<div id="drop-zone">파일을 여기에 드래그하세요</div>
```

```js
const dropZone = document.querySelector('#drop-zone');

// 기본 동작 방지 (브라우저가 파일을 열지 않도록)
['dragenter', 'dragover', 'dragleave', 'drop'].forEach(event => {
  dropZone.addEventListener(event, e => e.preventDefault());
  document.body.addEventListener(event, e => e.preventDefault());
});

// 시각적 피드백
dropZone.addEventListener('dragenter', () => dropZone.classList.add('active'));
dropZone.addEventListener('dragleave', () => dropZone.classList.remove('active'));

// 파일 드롭 처리
dropZone.addEventListener('drop', async (event) => {
  dropZone.classList.remove('active');
  const files = [...event.dataTransfer.files];

  for (const file of files) {
    await processFile(file);
  }
});

// DataTransferItem API (디렉토리 지원)
dropZone.addEventListener('drop', async (event) => {
  const items = [...event.dataTransfer.items];

  for (const item of items) {
    if (item.kind !== 'file') continue;

    // webkitGetAsEntry로 폴더 재귀 처리
    const entry = item.webkitGetAsEntry();
    if (entry.isDirectory) {
      await readDirectory(entry);
    } else {
      const file = item.getAsFile();
      await processFile(file);
    }
  }
});

async function readDirectory(dirEntry) {
  const reader = dirEntry.createReader();
  return new Promise((resolve, reject) => {
    const entries = [];
    function readBatch() {
      reader.readEntries(batch => {
        if (!batch.length) return resolve(entries);
        entries.push(...batch);
        readBatch();
      }, reject);
    }
    readBatch();
  });
}
```

---

## 6. FileReader vs File.text()

```js
const file = input.files[0];

// --- 구버전: FileReader (이벤트 기반) ---
function readWithFileReader(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = () => reject(reader.error);
    reader.readAsText(file, 'UTF-8');    // 텍스트
    // reader.readAsArrayBuffer(file);  // ArrayBuffer
    // reader.readAsDataURL(file);      // base64 data URL
    // reader.readAsBinaryString(file); // deprecated
  });
}

// --- 최신: File/Blob 메서드 (Promise 기반) ---
const text = await file.text();                    // 텍스트
const arrayBuffer = await file.arrayBuffer();      // ArrayBuffer
const stream = file.stream();                      // ReadableStream
```

| 항목 | FileReader | File.text() / arrayBuffer() |
|------|-----------|------------------------------|
| API 스타일 | 이벤트 기반 | Promise 기반 |
| 진행률 | onprogress 지원 | 미지원 |
| 인코딩 지정 | readAsText(file, encoding) | 항상 UTF-8 |
| 취소 | abort() 가능 | 불가 |
| 권장 | 진행률 필요 시 | 일반적인 경우 |

```js
// 대용량 파일 업로드 진행률 표시 (FileReader 사용)
function uploadWithProgress(file) {
  const reader = new FileReader();

  reader.onprogress = (event) => {
    if (event.lengthComputable) {
      const progress = (event.loaded / event.total * 100).toFixed(1);
      updateUI(progress);
    }
  };

  reader.readAsArrayBuffer(file);
}
```

---

## 7. 면접 포인트

**Q. `URL.createObjectURL(blob)` vs `FileReader.readAsDataURL()`의 차이는?**

`createObjectURL`은 Blob에 대한 메모리 참조 URL(blob:...)을 즉시 반환하며, `URL.revokeObjectURL()`로 명시적으로 해제해야 한다. `readAsDataURL`은 파일 전체를 base64 인코딩해 data URL로 변환하므로 33% 크기 증가가 발생한다. 이미지 미리보기 등에는 `createObjectURL`이 더 효율적이다.

**Q. Clipboard API가 HTTPS에서만 동작하는 이유는?**

클립보드에는 민감한 정보(비밀번호, 개인정보)가 있을 수 있어 보안 컨텍스트(Secure Context)에서만 사용 가능하도록 제한한다. `localhost`는 개발 편의를 위해 예외적으로 허용된다.

**Q. File은 Blob을 상속받는다. Blob과의 차이점은?**

`Blob`은 불변의 원시 데이터 덩어리다. `File`은 Blob에 `name`, `lastModified`, `webkitRelativePath` 속성이 추가된 서브클래스다. Blob 메서드(`.text()`, `.arrayBuffer()`, `.stream()`, `.slice()`)를 모두 사용할 수 있다.

**Q. DataTransfer.items와 DataTransfer.files의 차이는?**

`files`는 `FileList`로 파일만 담긴다. `items`는 `DataTransferItemList`로 파일 외에 텍스트, URL 등 다양한 타입을 포함하며, `webkitGetAsEntry()`로 디렉토리도 처리할 수 있다.
