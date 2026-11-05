---
name: cmake-build
description: |
  C++ CMake 프로젝트를 플랫폼별로 빌드한다. `cmake --build Build/<플랫폼>`을 실행하고 결과물
  Binaries/<플랫폼>/을 알린다. 플랫폼은 Windows, macOS, Linux, iOS, Android이고 생략하면 현재
  운영체제로 한다. 구성은 Debug(기본) 또는 Release. 결과는 매번 같은 형식으로, 오류·경고를 칸 맞춘 목록으로 보고한다.
  처음부터 다시 빌드하는 것은 `/bckim:cmake-rebuild`. Build/<플랫폼>/이 없으면 `/bckim:cmake-preset <플랫폼>`부터 한다. C++ CMake 프로젝트에서
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
  화면에는 전체 로그를 붙이지 않고 4절의 목록만 보여 준다.
- 실패해도 고치지 않고 목록으로 보고한다. 사용자가 요청하면 고친다.

## 4. 오류·경고 목록

이번 빌드의 `build.log`에서만 진단 줄을 모은다. 지난 빌드의 오류·경고는 목록에도 문장에도 넣지 않는다.

| 형식 | 예 |
|---|---|
| clang·gcc·Xcode | `/path/Source/Sum.cpp:11:5: error: use of undeclared identifier 'x'` |
| MSVC | `C:\path\Source\Sum.cpp(11,5): warning C4100: 'Argc': unreferenced parameter` |
| 링커 | `ld: warning: object file (.../libfmtd.a[2](format.cc.o)) was built for newer ...`, `undefined reference to ...`, `LNK2019: ...` |
| CMake | `CMake Error at Source/CMakeLists.txt:12 ...` |

정리 규칙:

- 경로는 프로젝트 루트 기준 상대 경로로 바꾼다. 프로젝트 밖(시스템 헤더, `ThirdParty/vcpkg`)이면 그대로 둔다.
- 링커 진단은 파일 칸에 관련 라이브러리·오브젝트 이름만 쓰고(예: `libfmtd.a(format.cc.o)`), 줄:열 칸은 비운다.
- 같은 위치·같은 메시지는 한 줄로 합치고 `(×3)`처럼 횟수를 붙인다(PCH·여러 번역 단위·Xcode 중복 출력).
- `note:` 줄은 따로 줄을 만들지 않고, 필요하면 바로 위 항목의 내용 끝에 짧게 덧붙인다.
- 정렬: 오류 → 경고, 같은 종류 안에서는 파일 → 줄 → 열 순서.
- 코드에는 경고 플래그(`-Wunused-parameter`)나 MSVC 코드(`C4100`, `LNK2019`)를 넣는다. 없으면 공백으로 채운다.
- 항목이 30개를 넘으면 30개까지 보여 주고 나머지 개수와 `build.log` 경로를 알린다.

## 5. 보고

결과는 매번 아래 형식 그대로 쓴다. 표(`|`·테두리)는 쓰지 않고, 코드 블록 안에서 공백으로 칸만 맞춘다.

````markdown
**<Platform> <Config> 빌드 <성공|실패>** · 오류 <N> · 경고 <N> · 컴파일 <N>개 파일

```
오류  Source/Sum.cpp              11:5                       use of undeclared identifier 'x'
경고  Source/Warn.cpp              3:22  -Wunused-parameter  unused parameter 'Argc' (×2)
경고  Source/Warn.cpp              8:15  -Wsign-compare      comparison of integers of different signs
경고  Source/Network/Socket.cpp  105:9   -Wshadow            declaration shadows a local variable
경고  libfmtd.a(format.cc.o)                                 built for newer 'macOS' version (27.0) than being linked (12.0)
```

- 결과물: `Binaries/<Platform>/<ProjectName>`
- 로그: `Build/<Platform>/build.log`
````

- 한 줄이 진단 하나다. 칸 순서는 종류 → 파일 → 줄:열 → 코드 → 내용이고, 칸 사이는 공백 두 칸이다. 머리글 줄은 쓰지 않는다.
- 종류는 항상 `오류`·`경고` 두 글자라 폭이 같다.
- 파일·코드 칸은 그 칸에서 가장 긴 값에 맞춰 뒤를 공백으로 채운다. 이 칸들에는 한글을 넣지 않는다(터미널에서 한글은 폭이
  2칸이라 정렬이 어긋난다).
- 줄:열 칸은 `:`가 세로로 맞게 쓴다. 줄 번호는 가장 긴 줄 번호 자릿수에 맞춰 앞을 공백으로 채우고(오른쪽 정렬),
  열 번호는 뒤를 공백으로 채운다. 줄 번호가 없는 진단(링커 등)은 이 칸 전체를 공백으로 채운다.
- 오류·경고가 없으면 코드 블록 대신 `경고가 없습니다.` 한 줄만 쓴다.
- 컴파일 수는 이번 빌드에서 실제로 컴파일한 소스 파일 수다(로그의 `CompileC`, `Building CXX object`, MSVC 파일 이름 줄).
  0이고 링크도 없었으면 요약 아래에 "바뀐 소스가 없어 컴파일·링크하지 않았습니다. 남아 있는 경고를 모두 보려면
  `/bckim:cmake-rebuild <Platform>`" 한 줄만 덧붙인다.
- 실패하면 결과물 줄 대신 "결과물 없음"이라고 쓴다.
- 현재 운영체제와 같은 데스크톱 플랫폼이면 마지막에 실행해 볼지 묻는다. 요청하면 실행하고 출력을 보여 준다.
