# 04. `env node` shebang · PATH · MCP가 안 붙던 이유

> 실전 배경: 에디터(Cursor/VSCode 계열)에 Figma MCP 서버를 붙였는데
> "failed during live tool discovery"로 계속 실패했다. `command: "npx"`를
> 셸 래퍼로 감쌌더니 **부분적으로만** 해결됐고, 진짜 원인은 그 아래
> `#!/usr/bin/env node` shebang이 **엉뚱한 node 바이너리**를 집는 것이었다.

## 목차
1. [1차 진단: PATH에 npx가 없다 (부분적으로 맞음)](#1-1차-진단-path에-npx가-없다-부분적으로-맞음)
2. [2차 진단: npx는 찾았는데 그 안의 node가 문제였다](#2-2차-진단-npx는-찾았는데-그-안의-node가-문제였다)
3. [env node shebang과 process.execPath](#3-env-node-shebang과-processexecpath)
4. [해법: node를 절대경로로 못 박기](#4-해법-node를-절대경로로-못-박기)
5. [곁다리 함정: envsubst가 셸 변수를 치환한다](#5-곁다리-함정-envsubst가-셸-변수를-치환한다)
6. [면접 포인트](#6-면접-포인트)

---

## 1. 1차 진단: PATH에 npx가 없다 (부분적으로 맞음)

MCP 서버 설정은 대개 이렇게 생겼다.

```jsonc
{ "command": "npx", "args": ["-y", "figma-developer-mcp", "--stdio"] }
```

`command: "npx"`는 **PATH에서 npx를 찾는다.** 그런데 nvm은 초기화 스크립트를 `~/.zshrc`(인터랙티브 셸 전용)에 넣기 때문에, 에디터가 비인터랙티브로 스폰한 프로세스의 PATH엔 nvm 경로가 없어 `npx`를 못 찾을 수 있다.

그래서 1차로 인터랙티브 셸을 강제하는 래퍼로 바꿨다.

```jsonc
{ "command": "zsh", "args": ["-ic", "npx -y figma-developer-mcp --stdio"] }
```

`-i`(interactive)로 `~/.zshrc`를 로드해 nvm PATH를 살린다. 그런데 사용자가 "여전히 안 된다"고 했다. **npx를 찾는 문제만 풀렸을 뿐, 더 깊은 원인이 남아 있었다.**

---

## 2. 2차 진단: npx는 찾았는데 그 안의 node가 문제였다

추측을 멈추고 에디터의 실제 MCP 로그를 봤다.

```
npm ERR! code ENOENT
npm ERR! syscall lstat
npm ERR! path /Applications/Cursor.app/Contents/Resources/app/resources/lib
npm ERR! enoent ENOENT: no such file or directory, lstat '.../resources/lib'
```

npm 디버그 로그가 결정적 단서였다.

```
0 verbose cli /Applications/Cursor.app/.../resources/helpers/node \
              /Users/me/.nvm/versions/node/v20.11.1/lib/node_modules/npm/bin/npm-cli.js
2 info using node@v22.22.0   ← ???
```

읽어보면: **`npx` 스크립트 파일 자체는 nvm 경로(v20.11.1)에서 정상적으로 찾았다.** 그런데 그 스크립트를 실행할 node로, **에디터 앱 번들에 내장된 node(v22.22.0)**가 선택됐다. npm이 `process.execPath`(자신을 실행한 node의 경로) 기준으로 라이브러리 위치를 추정하다가, 앱 번들 안에는 없는 `.../resources/lib`를 `lstat`하려다 죽은 것이다.

즉 문제는 "npx를 못 찾음"이 아니라 **"npx는 찾았는데 그걸 실행하는 node가 엉뚱함"**이었다.

---

## 3. env node shebang과 process.execPath

`npx`는 바이너리가 아니라 **shebang이 달린 스크립트**다.

```bash
#!/usr/bin/env node
# ↑ "PATH를 뒤져서 처음 나오는 node로 이 스크립트를 실행하라"
```

`#!/usr/bin/env node`의 핵심은 **node 경로를 하드코딩하지 않고 PATH 조회에 위임**한다는 점이다. 이식성엔 좋지만, PATH에 여러 node가 있으면 **PATH 순서상 먼저 나오는 것**이 이긴다.

에디터가 MCP 서버를 스폰할 때 자신의 내장 node 헬퍼(`resources/helpers/node`)를 PATH 앞쪽에 노출하면:

1. `env`가 그 내장 node(v22)를 먼저 찾는다.
2. 그 node로 nvm의 `npm-cli.js`를 실행한다.
3. npm이 `process.execPath`(= 내장 node 경로) 기준으로 자기 lib를 찾다가 앱 번들엔 없는 경로라 `ENOENT`.

> `process.execPath`는 "지금 실행 중인 node 실행 파일의 절대경로"다. npm처럼 자기 설치 위치를 execPath 상대로 추정하는 도구는, **어떤 node로 실행됐는지**에 극도로 민감하다.

이 문제는 Cursor뿐 아니라 **`env node` shebang을 쓰는 모든 CLI를 MCP `command`로 쓸 때** 재현될 수 있다.

---

## 4. 해법: node를 절대경로로 못 박기

암묵적 PATH 조회(shebang)에 맡기지 말고, **원하는 node의 절대경로를 명시**해 그 node로 npx 스크립트를 직접 실행한다.

```jsonc
{
  "command": "zsh",
  "args": [
    "-ic",
    "exec \"$(nvm which default)\" \"$(command -v npx)\" -y figma-developer-mcp --stdio"
  ]
}
```

- `$(nvm which default)` → nvm 기본 node의 **절대경로**(예: `~/.nvm/versions/node/v20.11.1/bin/node`).
- `$(command -v npx)` → npx **스크립트 파일 경로**.
- 즉 `node npx-script ...` 형태로 직접 실행해, shebang의 PATH 조회를 완전히 우회한다. PATH 순서와 무관하게 항상 nvm node로 실행된다.

**검증법**: 에디터 내장 헬퍼 경로를 PATH 최우선에 두어 충돌을 재현한 뒤, 새 래퍼로 MCP `initialize` 요청이 정상 응답하는지 확인했다. "문제를 일부러 재현 → 수정으로 해소 확인"은 04번이 아니라 [02번 문서의 검출력 검증](./02-tests-that-catch-regressions.md#2-검출력-검증-코드를-되돌리면-테스트가-깨지는가)과 같은 사고방식이다.

---

## 5. 곁다리 함정: envsubst가 셸 변수를 치환한다

설정 파일(`.mcp.base.json`)을 템플릿으로 두고 `envsubst`로 실제 파일을 생성하는 경우, 처음엔 이렇게 썼다가 깨졌다.

```bash
# ❌ envsubst가 $NODE_BIN도 치환 대상으로 보고 빈 문자열로 날림
NODE_BIN=$(nvm which default); exec "$NODE_BIN" ...
```

`envsubst`는 `$VAR`/`${VAR}` 형태를 모두 환경변수로 치환한다. 정의하지 않은 `$NODE_BIN`은 **빈 문자열**로 바뀌어 커맨드가 깨진다.

```bash
# ✅ 커맨드 치환 $(...)은 envsubst가 건드리지 않으므로 인라인으로
exec "$(nvm which default)" "$(command -v npx)" ...
```

이름 붙인 셸 변수를 피하고 `$(...)`를 바로 인라인하면 회피된다. (또는 `envsubst '$KNOWN_VAR'`로 치환 대상을 화이트리스트한다.)

> 이 설정 파일은 팀 전체에 영향을 주는 단일 진실 공급원이라, 변경은 브랜치를 분리해 리뷰를 거쳤다. 토큰이 들어가는 로컬 설정(예: `.cursor/mcp.json`)은 gitignore 대상이라 각자 재생성해야 반영된다. → [AI/MCP 설정 가이드](../ai/mcp-setup.md)

---

## 6. 면접 포인트

**Q. `#!/usr/bin/env node`는 왜 쓰고, 어떤 위험이 있나요?**
> node 경로를 하드코딩하지 않고 PATH에서 찾게 해 이식성을 높인다. 대신 PATH에 여러 node가 있으면 순서상 먼저 나오는 게 선택되므로, 의도한 버전과 다른 node로 실행될 수 있다. 버전 매니저(nvm)와 에디터 내장 node가 공존하는 환경에서 특히 문제가 된다.

**Q. `process.execPath`가 무엇이고 왜 중요한가요?**
> 현재 실행 중인 node 실행 파일의 절대경로다. npm처럼 자기 설치 위치를 execPath 기준으로 추정하는 도구는, 어떤 node로 실행됐는지에 따라 엉뚱한 lib 경로를 찾아 ENOENT로 죽을 수 있다. 그래서 "npx는 찾았는데 그걸 실행한 node가 잘못된" 상황이 생긴다.

**Q. CLI가 로컬 셸에선 되는데 에디터/CI에서 안 될 때 원인은?**
> 대개 환경 차이, 특히 PATH다. nvm 초기화가 인터랙티브 셸(~/.zshrc)에만 있으면 비인터랙티브 스폰 프로세스엔 PATH가 안 잡힌다. 또 앱이 자체 node를 PATH 앞에 노출하면 shebang이 그걸 집는다. 해법은 인터랙티브 셸 강제(zsh -ic)와, 더 확실하게는 node 절대경로를 명시해 실행하는 것이다.

**Q. 추측으로 두 번 고쳤는데 안 됐다면 다음 수는?**
> 추측을 멈추고 실제 로그를 본다. 이 사례에선 에디터의 MCP 서버 로그와 npm 디버그 로그에서 "내장 node v22로 실행 중"이라는 결정적 단서를 얻어 진짜 원인을 특정했다. 그리고 문제를 일부러 재현(내장 node를 PATH 최우선)해 수정이 실제로 해소하는지 검증했다.
