# bckim-harness

bckim의 개발 방식을 AI 코딩 에이전트(Claude Code·Codex·Gemini CLI)에 넣는 개인 하네스입니다. 저장소 하나를 각 도구의 설정 폴더에 링크로 연결해 쓰며, 저장소를 고치면 모든 도구에 바로 반영됩니다.

## 구성

| 구성 | 파일 | 언제 적용되나 |
|---|---|---|
| 기본 지침 | `AGENTS.md` | 모든 에이전트, 모든 작업 |
| 언어 규칙 | `rules/<언어>.md` | 그 언어의 파일을 읽거나 쓸 때 |
| 스킬 (플러그인 `bckim`) | `skills/<스킬>/SKILL.md` | 명령으로 부르거나, 관련 요청을 했을 때 |

| 영역 | 언어 규칙 | 스킬 |
|---|---|---|
| 공통 | | `review` |
| C++ | `rules/cpp.md`, `rules/cpp.clang-format` | `cmake`, `cmake-preset`, `cmake-build`, `cmake-rebuild`, `vcpkg` |
| Swift | (예정) `rules/swift.md` | |
| .NET | (예정) `rules/dotnet.md` | |
| JS/TS | (예정) `rules/js.md` | |

### 기본 지침 (`AGENTS.md`)

- **말투:** 사용자를 모시는 집사처럼 정중한 존댓말로 답합니다. 코드 주석·커밋 메시지·문서 본문은 각 프로젝트 규칙을 따릅니다.
- **언어별 규칙 안내:** C/C++ 파일을 다루기 전에 `rules/cpp.md`를 읽게 합니다. Codex·Gemini는 이 안내로 규칙을 읽고, Claude Code는 규칙이 자동으로 붙습니다.
- **수정 기록:** 문제(버그, 리뷰 지적, 빌드 실패 등)를 고칠 때마다 프로젝트 루트의 `.history/년_월_일_파일이름.md`에 기록합니다.
  - 이름은 수정한 파일 이름입니다(`Source/Sum.cpp` → `2026_11_05_Sum.md`). 여러 파일이면 경로 알파벳순 첫 파일, 같은 날 같은 이름이면 `_2`.
  - 내용은 문제, 원인, 수정(파일·줄·내용), 확인입니다.

### C++ 규칙 (`rules/cpp.md`)

크로스 플랫폼(Windows·macOS·Linux·iOS·Android) 표준 C++20 규칙입니다. 사용자의 Forward·WndUI 코드에서 뽑았습니다.

- **폴더 구성:** 루트 `CMakeLists.txt`·`CMakePresets.json`, 소스는 `Source/`, 빌드 파일은 `Build/<플랫폼>/`, 결과물은 `Binaries/<플랫폼>/`
- **이름:** 타입·공개 함수·매개변수·지역 변수는 PascalCase, private 함수는 camelCase, 멤버는 `camelCase_`, 상수는 `k`, 전역은 `g`, enum은 `E` 접두사
- **형식:** Allman, 4칸, 한 문장 한 줄, 왼쪽 맞춤, `(void)`, `== false`. `rules/cpp.clang-format`이 형식을 정합니다.
- **파일:** 배너, `#ifndef _NAME_H_` / `#endif//_NAME_H_` 헤더 가드, `Pch.h` 먼저 include, 한글 주석
- **설계:** 예외 대신 `bool` + `int32_t& Reason`, `new`/`delete` 대신 스마트 포인터, 플랫폼 분기는 `#if defined(...)` + `#else #error`
- **의존성:** vcpkg(`ThirdParty/vcpkg` 서브모듈), 기본 STATIC

## 스킬

Claude Code에서는 `/bckim:<스킬>`로 부릅니다. `/bckim`을 입력하면 목록과 한글 설명이 보입니다. 직접 부르지 않아도 "빌드해줘", "리뷰해줘"처럼 말하면 맞는 스킬이 쓰입니다. 플랫폼은 `Windows`, `macOS`, `Linux`, `iOS`, `Android`이고, 생략할 수 있는 곳에서 생략하면 현재 운영체제로 진행합니다.

| 명령 | 하는 일 |
|---|---|
| `/bckim:cmake <프로젝트명>` | C++ 새 프로젝트를 git 저장소로 만듭니다(파일만, 빌드는 안 함) |
| `/bckim:cmake-preset [플랫폼]` | `cmake --preset`으로 `Build/<플랫폼>/`에 빌드 파일을 만듭니다 |
| `/bckim:cmake-build [플랫폼] [Debug\|Release]` | 빌드하고 오류·경고를 칸 맞춘 목록으로 보여 줍니다 |
| `/bckim:cmake-rebuild [플랫폼] [Debug\|Release]` | 처음부터 다시 빌드합니다. 가려졌던 경고까지 모두 보여 줍니다 |
| `/bckim:vcpkg install <패키지> [STATIC\|DYNAMIC]` | 의존성을 추가합니다. `remove <패키지>`, `list`도 있습니다 |
| `/bckim:review [PR번호\|경로]` | 모든 언어의 변경을 리뷰합니다 |

### C++ 프로젝트 흐름

```
/bckim:cmake Hello              # 프로젝트를 둘 상위 폴더에서
cd Hello
/bckim:cmake-preset             # 현재 운영체제 (예: Build/macOS/)
/bckim:cmake-build              # 결과물: Binaries/macOS/Hello
/bckim:vcpkg install fmt        # 라이브러리가 필요할 때
```

`/bckim:cmake`가 만드는 구조입니다. 배너의 작성자와 연도는 `git config user.name`과 오늘 날짜로 채우며, 묻지 않습니다.

```
Hello/
├── CMakeLists.txt          # 공통 설정. 플랫폼은 프리셋이 정함
├── CMakePresets.json       # Windows / macOS / Linux / iOS / Android
├── .gitignore              # Build/, Binaries/
├── .history/               # 수정 기록
└── Source/
    ├── CMakeLists.txt
    ├── Pch.h
    ├── Pch.cpp
    └── Hello.cpp
```

- macOS·iOS 프리셋은 Xcode 생성기를 씁니다. Android는 `ANDROID_NDK_HOME`이 필요하며, 없으면 스킬이 NDK를 찾아 씁니다.
- iOS는 서명 없이 시뮬레이터용으로 빌드합니다.

### 빌드 결과 보고

`cmake-build`와 `cmake-rebuild`는 매번 같은 형식으로 보고합니다. 이번 빌드의 오류·경고만 보여 주고, 전체 로그는 `Build/<플랫폼>/build.log`에 남깁니다.

```
macOS Debug 빌드 실패 · 오류 1 · 경고 3 · 컴파일 4개 파일

오류  Source/Sum.cpp              11:5                       use of undeclared identifier 'x'
경고  Source/Warn.cpp              3:22  -Wunused-parameter  unused parameter 'Argc' (×2)
경고  Source/Network/Socket.cpp  105:9   -Wshadow            declaration shadows a local variable
경고  libfmtd.a(format.cc.o)                                 built for newer 'macOS' version ...
```

- 칸 순서는 종류, 파일, 줄:열, 코드, 내용입니다. 줄 번호는 오른쪽 정렬이라 `:`가 세로로 맞습니다.
- 오류를 먼저, 그다음 파일·줄 순서로 정렬합니다. 같은 경고가 반복되면 `(×2)`처럼 합칩니다.
- 오류·경고가 없으면 "경고가 없습니다."라고만 씁니다.
- 바뀐 소스가 없어 컴파일하지 않은 빌드는 경고가 가려질 수 있으므로 `cmake-rebuild`를 안내합니다.

### vcpkg 의존성

```
ThirdParty/
├── vcpkg/                  # git 서브모듈
├── vcpkg.json              # 매니페스트: 설치할 패키지 목록
└── vcpkg-triplets/
    ├── Linkage.cmake       # DYNAMIC으로 지정한 패키지 목록
    └── <triplet>.cmake     # 플랫폼별 triplet 5개
```

- 처음 `install`하면 서브모듈 추가, `vcpkg.json`, triplet, 프리셋 연결까지 준비합니다. 부트스트랩은 configure할 때 자동으로 됩니다.
- 연결 방식은 기본 STATIC입니다. DYNAMIC은 Windows·macOS·Linux에만 적용되고, iOS·Android는 항상 STATIC입니다.
- 패키지는 선택 기능을 끈 채(`"default-features": false`) 넣고, 빌드 뒤 소스·중간 파일은 지웁니다(`--clean-after-build`).
- macOS·iOS triplet은 프리셋과 같은 배포 대상 버전(12.0, 15.0)으로 빌드해 링커 버전 경고가 나지 않게 합니다.

### 리뷰

`/bckim:review`는 언어와 상관없이 정확성 → 플랫폼·환경 차이 → 자원 → 오류 처리 → 동시성 → 보안 → 언어 규칙·스타일 순서로 봅니다. 기준은 프로젝트 설정(ESLint, SwiftLint, `.editorconfig` 등), `rules/<언어>.md`, 공식 관례 순입니다. 지적마다 `파일:줄`과 심각도(치명·높음·보통·스타일)를 붙이며, 요청하기 전에는 고치지 않습니다.

## 설치

### 준비물

| | 필수 | 선택 |
|---|---|---|
| 공통 | git, CMake 3.22 이상 | clang-format |
| Windows | Visual Studio 2022 이상(MSVC) | |
| macOS | Xcode | Android NDK |
| Linux | GCC 13 이상 또는 Clang 17 이상, make | Android NDK |

LLVM은 필요 없습니다. 빌드는 각 운영체제의 기본 컴파일러로 합니다.

### 1. 저장소 받기

```sh
git clone https://github.com/woodgh/bckim-harness ~/orca/bckim-harness
H=~/orca/bckim-harness
```

다른 위치에 받았다면 `H`만 바꾸면 됩니다. 단, 스킬과 기본 지침이 규칙 파일을 `~/orca/bckim-harness/rules/`로 가리키므로, 위치를 바꾸면 그 경로도 함께 고쳐야 합니다.

### 2. 도구에 연결하기

모두 링크입니다. 같은 이름의 파일이 이미 있으면 `ln`이 실패하므로, 먼저 내용을 확인하고 옮겨 두세요.

**Claude Code**

```sh
mkdir -p ~/.claude/skills ~/.claude/rules
ln -s $H/AGENTS.md    ~/.claude/CLAUDE.md          # 기본 지침
ln -s $H/rules/cpp.md ~/.claude/rules/cpp.md       # C++ 규칙 (C/C++ 파일을 다룰 때 자동 적용)
ln -s $H              ~/.claude/skills/bckim       # 스킬 (bckim@skills-dir 플러그인으로 로드)
```

**Codex**

```sh
mkdir -p ~/.codex ~/.agents/skills
ln -s $H/AGENTS.md ~/.codex/AGENTS.md                 # 기본 지침 (C++ 규칙도 이 안내로 읽음)
for s in review cmake cmake-preset cmake-build cmake-rebuild vcpkg; do
    ln -s $H/skills/$s ~/.agents/skills/$s           # 스킬 (bckim:<스킬>로 보임)
done
```

Orca에서 띄운 Codex는 `CODEX_HOME`이 Orca 계정 폴더(`~/Library/Application Support/orca/codex-accounts/<계정>/home`)입니다. 계정마다 기본 지침도 연결하세요.

```sh
ln -s $H/AGENTS.md "$CODEX_HOME/AGENTS.md"
```

**Gemini CLI**

```sh
mkdir -p ~/.gemini
ln -s $H/AGENTS.md ~/.gemini/GEMINI.md      # 기본 지침
gemini extensions link $H                   # 스킬
```

### 3. 확인하기

- **Claude Code:** `claude plugin list`의 "Skills-directory plugins"에 `bckim@skills-dir`가 보이면 됩니다. 실행 중인 세션은 `/reload-plugins` 후 `/bckim`을 입력해 목록을 확인합니다.
- **Codex:** 새 세션에서 "bckim 스킬 목록 보여줘"라고 물으면 `bckim:cmake` 등이 보입니다.
- **말투:** 새 세션에서 아무 질문이나 하면 존댓말로 답합니다.

### 업데이트와 제거

- **업데이트:** `git -C $H pull`. 링크라서 다시 설치할 필요가 없습니다. 실행 중인 Claude Code 세션은 `/reload-plugins`, Codex·Gemini는 새 세션부터 반영됩니다.
- **제거:** 위에서 만든 링크만 지우면 됩니다(`rm ~/.claude/skills/bckim` 등). 저장소 파일은 그대로 남습니다.

### 지원 범위

| | Claude Code | Codex | Gemini CLI |
|---|---|---|---|
| 기본 지침 | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` | `~/.gemini/GEMINI.md` |
| C++ 규칙 | C/C++ 파일을 다룰 때 자동 | 기본 지침 안내로 읽음 | 기본 지침 안내로 읽음 |
| 스킬 | `/bckim:<스킬>` | `bckim:<스킬>` | `<스킬>` (이름 앞에 `bckim:` 없음) |
| 시험 여부 | 시험함 | 시험함 | 확장 인식만 시험함 |

## 구조와 확장

```
AGENTS.md                # 기본 지침
rules/                   # 언어 규칙 (cpp.md, cpp.clang-format)
skills/                  # review, cmake, cmake-preset, cmake-build, cmake-rebuild, vcpkg
.claude-plugin/          # Claude Code·Codex 매니페스트 (플러그인 이름 bckim)
gemini-extension.json    # Gemini CLI 매니페스트
```

- **새 스킬:** `skills/<이름>/SKILL.md`를 만듭니다. 폴더 이름과 `name`을 같게 하고, Codex용 `~/.agents/skills/<이름>` 링크를 하나 더 만듭니다.
- **새 언어 규칙:** `rules/<언어>.md`를 만들고, `AGENTS.md`의 언어별 규칙 절과 `~/.claude/rules/` 링크를 함께 추가합니다. 맨 위에 `paths:`(파일 패턴)를 넣으면 Claude Code는 그 파일을 다룰 때만 규칙을 붙입니다.
- **설명은 반드시 한글로:** 스킬의 `description`·`argument-hint`와 플러그인 설명은 `/bckim` 명령 목록에 그대로 보이므로 한글로 씁니다.
- **검증:** `claude plugin validate .`
