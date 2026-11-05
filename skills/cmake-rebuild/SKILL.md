---
name: cmake-rebuild
description: |
  C++ CMake 프로젝트를 처음부터 다시 빌드한다(`cmake --build ... --clean-first`). 바뀐 소스가 없어
  가려졌던 경고까지 모두 보여 준다. 플랫폼은 Windows, macOS, Linux, iOS, Android이고 생략하면 현재
  운영체제, 구성은 Debug(기본) 또는 Release. 결과는 `/bckim:cmake-build`와 같은 칸 맞춘 오류·경고
  목록으로 보고한다. "다시 빌드해줘", "클린 빌드", "리빌드", "경고 전부 보여줘"에 쓴다.
argument-hint: '[플랫폼] [Debug|Release]'
---

# CMake 다시 빌드

`~/orca/bckim-harness/skills/cmake-build/SKILL.md`를 읽고 그 절차(프로젝트·플랫폼 정하기, 빌드 파일 확인,
다시 구성, 오류·경고 목록, 보고 형식)를 그대로 따른다. 다른 점은 하나뿐이다.

- 빌드 명령에 `--clean-first`를 붙인다. 이전 빌드 결과를 지우고 모든 소스를 다시 컴파일·링크한다.

  | 플랫폼 | 명령 |
  |---|---|
  | Windows, macOS | `cmake --build Build/<Platform> --config <Config> --clean-first` |
  | Linux, Android | `cmake --build Build/<Platform> --clean-first` |
  | iOS | `cmake --build Build/iOS --config <Config> --clean-first -- -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO` |

- vcpkg 패키지(`Build/<Platform>/vcpkg_installed/`)는 지우지 않는다. 프로젝트 소스만 다시 빌드한다.
- 보고 첫 줄은 `**<Platform> <Config> 다시 빌드 <성공|실패>** · 오류 <N> · 경고 <N> · 컴파일 <N>개 파일`로 쓴다.
