---
name: cmake-preset
description: |
  C++ CMake 프로젝트의 플랫폼 프리셋으로 빌드 파일을 만든다. `cmake --preset <플랫폼>`을 실행해
  Build/<플랫폼>/에 생성한다. 플랫폼은 Windows, macOS, Linux, iOS, Android이고, 생략하면 현재
  운영체제(Windows·macOS·Linux)로 한다. `/bckim:cmake`로 만든
  프로젝트(또는 CMakePresets.json이 있는 프로젝트) 안에서 쓴다. "프리셋 생성", "빌드 파일
  만들어줘", "cmake 구성해줘"에 쓴다. 빌드는 `/bckim:cmake-build <플랫폼>`.
argument-hint: '[플랫폼]'
---

# CMake 프리셋으로 빌드 파일 생성

## 1. 프로젝트 찾기

프로젝트 루트는 git 저장소 최상위 폴더다(`git rev-parse --show-toplevel`). 그곳에 `CMakePresets.json`이 있어야 한다.
git 저장소가 아니거나 `CMakePresets.json`이 없으면 멈추고 "`/bckim:cmake <프로젝트명>`으로 먼저 프로젝트를 만들어 주세요"라고 알린다.

## 2. 플랫폼 정하기

- 인자를 프리셋 이름에 맞춘다. 대소문자는 무시한다(`macos` → `macOS`, `ios` → `iOS`).
- 인자가 없으면 묻지 않고 현재 운영체제의 프리셋으로 진행한다: Windows → `Windows`, macOS → `macOS`, Linux → `Linux`.
  어떤 플랫폼으로 정했는지 보고에 적는다.
- `cmake --list-presets`로 쓸 수 있는 프리셋을 확인한다. 데스크톱 프리셋은 그 OS에서만 보인다.
  목록에 없으면 이유(예: macOS 프리셋은 Mac에서만)와 쓸 수 있는 목록을 알리고 멈춘다.

## 3. 플랫폼별 준비 확인

| 플랫폼 | 필요한 것 | 없을 때 |
|---|---|---|
| macOS, iOS | Xcode (`xcodebuild -version`) | Xcode 설치를 안내하고 멈춘다 |
| Android | NDK. `ANDROID_NDK_HOME` 환경 변수 | 아래 순서로 찾는다 |
| Windows | Visual Studio (C++ 데스크톱 개발) | 설치를 안내하고 멈춘다 |
| Linux | C++20 컴파일러, make | 설치를 안내하고 멈춘다 |

Android에서 `ANDROID_NDK_HOME`이 없으면 `$ANDROID_HOME/ndk/`, `$ANDROID_SDK_ROOT/ndk/`,
`~/Library/Android/sdk/ndk/`(macOS), `~/Android/Sdk/ndk/`(Linux), `%LOCALAPPDATA%\Android\Sdk\ndk\`(Windows)에서
가장 높은 버전을 찾아 그 경로로 이번 명령에만 설정한다. 어떤 경로를 썼는지 알린다. 못 찾으면 멈추고 NDK 설치를 안내한다.

## 4. 실행

프로젝트 루트에서 실행한다.

```sh
cmake --preset <Platform>
# Android: ANDROID_NDK_HOME=<NDK 경로> cmake --preset Android
```

- 이미 `Build/<Platform>/`이 있으면 그대로 다시 실행한다(CMake가 갱신한다). 지우지 않는다.
- 실패하면 오류 줄과 원인을 짧게 알리고, 고칠 방법이 분명하면 제안한다. 파일을 임의로 고치지 않는다.

## 5. 보고

- 성공: `Build/<Platform>/`에 빌드 파일이 생겼다고 알리고 다음 단계를 안내한다:
  `/bckim:cmake-build <Platform>`.
- macOS·iOS는 Xcode 프로젝트(`Build/<Platform>/<ProjectName>.xcodeproj`)도 생겼으니 Xcode로 열 수 있다고 덧붙인다.
  Windows는 `Build/Windows/<ProjectName>.sln`.
