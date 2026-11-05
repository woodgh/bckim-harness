# bckim-harness

내 개발 방식을 AI 코딩 에이전트(Claude Code·Codex·Gemini CLI)에 넣는 개인 하네스입니다.

- **기본 지침** (`AGENTS.md`): 모든 에이전트, 모든 작업에 적용 (집사처럼 존댓말, 문제 수정 시 `.history/년_월_일_이름.md` 기록 등)
- **언어 규칙** (`rules/`): 그 언어 파일을 다룰 때 자동으로 적용
- **스킬** (`skills/`, 플러그인 `bckim`): 명령으로 실행하는 일. Claude Code에서는 `/bckim:<스킬>`

| 영역 | 언어 규칙 | 스킬 |
|---|---|---|
| 공통 | | `review` |
| C++ | `rules/cpp.md`, `rules/cpp.clang-format` | `cmake`, `cmake-preset`, `cmake-build`, `vcpkg` |
| Swift | `rules/swift.md` (예정) | |
| .NET | `rules/dotnet.md` (예정) | |
| JS/TS | `rules/js.md` (예정) | |

## 스킬

| 스킬 | 하는 일 |
|---|---|
| `review [PR#\|경로]` | 모든 언어. 정확성 → 플랫폼·환경 차이 → 자원 → 오류 처리 → 동시성 → 보안 → 언어 규칙·스타일 순서로 리뷰. 기준은 프로젝트 설정과 `rules/<언어>.md` |
| `cmake <이름>` | C++ 새 프로젝트(git 저장소). 루트 `CMakeLists.txt`·`CMakePresets.json`·`.gitignore`, `Source/`에 `CMakeLists.txt`·`Pch.h`·`Pch.cpp`·`<이름>.cpp` |
| `cmake-preset <플랫폼>` | `cmake --preset <플랫폼>`으로 `Build/<플랫폼>/`에 빌드 파일 생성 |
| `cmake-build <플랫폼> [Debug\|Release]` | `Build/<플랫폼>/`을 빌드해 `Binaries/<플랫폼>/`에 결과물 생성 |
| `vcpkg install <패키지> [STATIC\|DYNAMIC]` | 의존성 추가 (기본 STATIC). 처음이면 `ThirdParty/vcpkg` 서브모듈, `ThirdParty/vcpkg.json`, `ThirdParty/vcpkg-triplets/`, 프리셋 연결까지. `remove`, `list`도 있음 |

플랫폼은 `Windows`, `macOS`, `Linux`, `iOS`, `Android`. C++ 사용 순서:

```
/bckim:cmake Hello          # 상위 폴더에서
cd Hello
/bckim:cmake-preset macOS
/bckim:cmake-build macOS
/bckim:vcpkg install fmt      # 필요할 때
```

## 설치

모두 저장소 파일을 링크로 연결합니다. 저장소를 고치면 그대로 반영됩니다.

```sh
H=~/orca/bckim-harness

# 기본 지침
ln -s $H/AGENTS.md ~/.claude/CLAUDE.md
ln -s $H/AGENTS.md ~/.codex/AGENTS.md
ln -s $H/AGENTS.md ~/.gemini/GEMINI.md
ln -s $H/AGENTS.md "$CODEX_HOME/AGENTS.md"     # Orca에서 띄운 Codex (CODEX_HOME이 Orca 계정 폴더)

# 언어 규칙: Claude Code는 해당 파일을 다룰 때 자동 적용. Codex·Gemini는 AGENTS.md 안내로 읽음
mkdir -p ~/.claude/rules && ln -s $H/rules/cpp.md ~/.claude/rules/cpp.md

# 스킬 (플러그인 bckim)
ln -s $H ~/.claude/skills/bckim                # Claude Code. 실행 중인 세션은 /reload-plugins
for s in review cmake cmake-preset cmake-build vcpkg; do ln -s $H/skills/$s ~/.agents/skills/$s; done   # Codex (bckim:<스킬>로 보임)
gemini extensions link $H                       # Gemini CLI
```

새 스킬을 추가하면 Codex용 `~/.agents/skills/` 링크도 하나 더 만듭니다.

## 구조

```
AGENTS.md              # 기본 지침
rules/                 # 언어 규칙 (cpp.md, cpp.clang-format)
skills/                # review, cmake, cmake-preset, cmake-build, vcpkg
.claude-plugin/        # Claude Code·Codex 매니페스트
gemini-extension.json  # Gemini CLI 매니페스트
```

스킬은 `skills/<이름>/SKILL.md`(폴더 이름 = `name`)로, 언어 규칙은 `rules/<언어>.md`로 추가합니다. 스킬의 `description`·`argument-hint`와 플러그인 설명은 반드시 한글로 씁니다(명령 목록에 그대로 보입니다). 새 언어 규칙을 넣으면 `AGENTS.md`의 언어별 규칙 절과 `~/.claude/rules/` 링크도 함께 추가합니다.
