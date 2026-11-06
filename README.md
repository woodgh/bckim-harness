# bckim-harness

bckim의 개발 방식을 AI 코딩 에이전트(Claude Code·Codex·Gemini CLI)에 넣는 개인 하네스입니다.
말투와 작업 원칙, 언어별 코딩 규칙, 자주 쓰는 작업(프로젝트 생성·빌드·리뷰)을 한 저장소에서 관리하고,
각 도구의 설정 폴더에 연결해 씁니다. 저장소를 고치면 모든 도구에 바로 반영됩니다.

## 설치

**macOS·Linux**

```sh
git clone https://github.com/woodgh/bckim-harness ~/orca/bckim-harness
~/orca/bckim-harness/install.sh
```

**Windows** (PowerShell)

```powershell
git clone https://github.com/woodgh/bckim-harness $HOME\orca\bckim-harness
powershell -ExecutionPolicy Bypass -File $HOME\orca\bckim-harness\install.ps1
```

- 기본 지침·규칙·스킬을 Claude Code, Codex(Orca가 관리하는 계정 포함), Gemini CLI에 연결합니다.
- 여러 번 실행해도 안전하고, 같은 이름의 다른 파일은 덮어쓰지 않고 알려 줍니다.
- **업데이트:** `git pull`. 새 스킬이 생겼거나 Windows라면 설치 스크립트를 한 번 더 실행합니다.
- **제거:** `install.sh --uninstall` / `install.ps1 -Uninstall`
- 실행 중인 Claude Code 세션은 `/reload-plugins`, Codex·Gemini는 새 세션부터 적용됩니다.
- Windows는 권한 없이 쓰려고 정션과 복사를 섞어 씁니다. 아직 Windows에서 실제로 실행해 보지는 않았습니다.

## 스킬

Claude Code에서는 `/bckim:<스킬>`로 부르고, `/bckim`을 입력하면 목록이 보입니다. "빌드해줘", "리뷰해줘"처럼 말해도 맞는 스킬이 쓰입니다.

| 스킬 | 하는 일 |
|---|---|
| [`review`](skills/review/SKILL.md) | 모든 언어의 변경을 리뷰합니다. 정확성부터 스타일까지 순서대로 보고 `파일:줄`과 심각도를 붙입니다 |
| [`cmake`](skills/cmake/SKILL.md) | C++ 새 프로젝트를 git 저장소로 만듭니다 |
| [`cmake-preset`](skills/cmake-preset/SKILL.md) | 플랫폼 프리셋으로 `Build/<플랫폼>/`에 빌드 파일을 만듭니다 |
| [`cmake-build`](skills/cmake-build/SKILL.md) | 빌드하고 오류·경고를 칸 맞춘 목록으로 보여 줍니다 |
| [`cmake-rebuild`](skills/cmake-rebuild/SKILL.md) | 처음부터 다시 빌드해 남아 있는 경고를 모두 보여 줍니다 |
| [`vcpkg`](skills/vcpkg/SKILL.md) | C++ 의존성을 추가·제거합니다. 기본 STATIC, iOS·Android는 항상 STATIC |

플랫폼은 `Windows`, `macOS`, `Linux`, `iOS`, `Android`이며, 생략하면 현재 운영체제로 진행합니다.

```
/bckim:cmake Hello          # C++ 프로젝트 만들기
cd Hello
/bckim:cmake-preset         # 빌드 파일 → Build/macOS/
/bckim:cmake-build          # 빌드 → Binaries/macOS/Hello
/bckim:vcpkg install fmt    # 라이브러리 추가
```

## MCP

아직 하네스에 포함된 MCP 서버는 없습니다. 추가하면 플러그인 매니페스트(`.claude-plugin/plugin.json`, `gemini-extension.json`)의 `mcpServers`에 넣습니다.

## 규칙

| 규칙 | 파일 | 적용 |
|---|---|---|
| 기본 지침 | [`AGENTS.md`](AGENTS.md) | 모든 에이전트, 모든 작업 |
| C++ 규칙 | [`rules/cpp.md`](rules/cpp.md), [`rules/cpp.clang-format`](rules/cpp.clang-format) | C/C++ 파일을 다룰 때 |
| Swift·.NET·JS/TS | (예정) `rules/swift.md`, `rules/dotnet.md`, `rules/js.md` | |

- **기본 지침:** 집사처럼 존댓말로 답하고, 문제를 고치면 프로젝트의 `.history/년_월_일_파일이름.md`에 무엇을 어디서 고쳤는지 기록합니다.
- **C++ 규칙:** 크로스 플랫폼(Windows·macOS·Linux·iOS·Android) 표준 C++20 기준의 폴더 구성, 이름, 형식, 오류 처리, 플랫폼 분리, vcpkg 사용법입니다. Forward·WndUI 코드에서 뽑았습니다.
- Claude Code는 C/C++ 파일을 다룰 때 C++ 규칙이 자동으로 붙고, Codex·Gemini는 기본 지침의 안내에 따라 읽습니다.

## 구조

```
AGENTS.md                # 기본 지침
rules/                   # 언어 규칙
skills/                  # 스킬 (플러그인 bckim)
install.sh, install.ps1  # 설치·제거
.claude-plugin/          # Claude Code·Codex 매니페스트
gemini-extension.json    # Gemini CLI 매니페스트
```

- **스킬 추가:** `skills/<이름>/SKILL.md`(폴더 이름 = `name`)를 만들고 설치 스크립트를 다시 실행합니다.
- **규칙 추가:** `rules/<언어>.md`를 만들고 `AGENTS.md`의 언어별 규칙 절에 안내를 넣은 뒤 설치 스크립트를 다시 실행합니다.
- 스킬 설명(`description`, `argument-hint`)은 명령 목록에 그대로 보이므로 반드시 한글로 씁니다.
- 검증: `claude plugin validate .`
