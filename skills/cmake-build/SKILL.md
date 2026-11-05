---
name: cmake-build
description: |
  C++ CMake 프로젝트를 플랫폼별로 빌드한다. `cmake --build Build/<플랫폼>`을 실행하고 결과물
  Binaries/<플랫폼>/을 알린다. 플랫폼은 Windows, macOS, Linux, iOS, Android이고 생략하면 현재
  운영체제로 한다. 구성은 Debug(기본) 또는 Release. Build/<플랫폼>/이 없으면 `/bckim:cmake-preset <플랫폼>`부터 한다. C++ CMake 프로젝트에서
  "빌드해줘", "cmake 빌드", "<플랫폼> 빌드"에 쓴다.
argument-hint: '[플랫폼] [Debug|Release]'
---

# CMake 빌드

## 1. 프로젝트와 플랫폼

- 프로젝트 루트는 git 저장소 최상위 폴더다(`git rev-parse --show-toplevel`). 그곳에 `CMakePresets.json`이
  없으면 멈추고 `/bckim:cmake <프로젝트명>`으로 먼저 만들라고 알린다.
- 플랫폼은 `/bckim:cmake-preset`과 같은 규칙으로 정한다(대소문자 무시). 없으면 묻지 않고 현재 운영체제로 한다.
- 빌드 구성은 `Debug`(기본) 또는 `Release`다. 첫 인자가 `Debug`·`Release`면 구성으로 보고 플랫폼은 현재 운영체제로 한다
  (`/bckim:cmake-build Release` → 현재 운영체제 Release 빌드).

## 2. 빌드 파일 확인

`Build/<Platform>/`이 없으면 `/bckim:cmake-preset <Platform>`의 절차를 먼저 진행한다. 실패하면 거기서 멈춘다.

## 3. 빌드

프로젝트 루트에서 실행한다.

먼저 `cmake Build/<Platform>`으로 다시 구성한다. 소스 목록은 `FILE(GLOB ... CONFIGURE_DEPENDS)`라서, 새로 추가한
파일은 Xcode·Visual Studio 생성기에서 다시 구성하기 전까지 첫 빌드에 들어가지 않는다. Android는
`/bckim:cmake-preset`처럼 `ANDROID_NDK_HOME`을 설정하고 실행한다.


| 플랫폼 | 명령 |
|---|---|
| Windows, macOS | `cmake --build Build/<Platform> --config <Config>` |
| Linux, Android | `cmake --build Build/<Platform>` |
| iOS | `cmake --build Build/iOS --config <Config> -- -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO` |

- Linux·Android 프리셋은 빌드 구성이 프리셋에 `Debug`로 정해져 있다. `Release`를 요청받으면
  `CMakePresets.json`의 해당 프리셋 `CMAKE_BUILD_TYPE`을 바꿔야 한다고 알리고, 바꿀지 묻는다.
- iOS는 서명 없이 시뮬레이터용으로 빌드한다. 실제 기기용은 서명 설정이 필요하다고 알린다.
- 출력은 `Build/<Platform>/build.log`에 저장한다(예: `cmake --build ... > Build/<Platform>/build.log 2>&1`).
  화면에는 전체 로그를 붙이지 않고 4절의 표만 보여 준다.
- 실패해도 고치지 않고 표로 보고한다. 사용자가 요청하면 고친다.

## 4. 오류·경고 표

`build.log`에서 진단 줄을 모은다.

| 형식 | 예 |
|---|---|
| clang·gcc·Xcode | `/path/Source/Sum.cpp:11:5: error: use of undeclared identifier 'x'` |
| MSVC | `C:\path\Source\Sum.cpp(11,5): warning C4100: 'Argc': unreferenced parameter` |
| 링커 | `ld: symbol(s) not found ...`, `undefined reference to ...`, `LNK2019: ...` |
| CMake | `CMake Error at Source/CMakeLists.txt:12 ...` |

정리 규칙:

- 경로는 프로젝트 루트 기준 상대 경로로 바꾼다. 프로젝트 밖(시스템 헤더, `ThirdParty/vcpkg`)이면 그대로 둔다.
- 같은 위치·같은 메시지는 한 줄로 합치고 `(×3)`처럼 횟수를 붙인다(PCH·여러 번역 단위에서 반복되는 경고).
- `note:` 줄은 따로 줄을 만들지 않고, 필요하면 바로 위 항목의 내용 끝에 짧게 덧붙인다.
- 정렬: 오류 → 경고, 같은 종류 안에서는 파일 → 줄 → 열 순서.
- 코드 칸에는 경고 플래그(`-Wunused-parameter`)나 MSVC 코드(`C4100`, `LNK2019`)를 넣는다. 없으면 비운다.
- 항목이 30개를 넘으면 30개까지 보여 주고 나머지 개수와 `build.log` 경로를 알린다.

```markdown
| 종류 | 위치 | 코드 | 내용 |
|---|---|---|---|
| 오류 | `Source/Sum.cpp:11:5` | | use of undeclared identifier 'x' |
| 경고 | `Source/World.cpp:8:14` | `-Wunused-parameter` | unused parameter 'Argc' (×2) |
```

오류·경고가 없으면 표 대신 "오류 0, 경고 0"이라고 쓴다.

## 5. 보고

- 성공·실패, 플랫폼·구성, 오류·경고 개수를 첫 줄에 쓰고 4절의 표를 붙인다.
- 성공했으면 결과물 경로를 알린다: `Binaries/<Platform>/<ProjectName>`(Windows `.exe`, iOS `.app`).
- 현재 OS와 같은 데스크톱 플랫폼이면 실행해 볼지 묻는다. 요청하면 실행하고 출력을 보여 준다.
