---
name: cmake
description: |
  C++20 CMake 새 프로젝트를 git 저장소로 만든다. 루트 CMakeLists.txt·CMakePresets.json·.gitignore,
  Source/에 CMakeLists.txt·Pch.h·Pch.cpp·<프로젝트명>.cpp. 파일만 만들고, 빌드 파일 생성은
  `/bckim:cmake-preset <플랫폼>`, 빌드는 `/bckim:cmake-build <플랫폼>`이 한다. "C++ 새 프로젝트
  만들어줘", "CMake 프로젝트 생성", "C++ 프로젝트 뼈대 잡아줘"에 쓴다. 다른 언어에는 쓰지 않는다.
  코드는 ~/orca/bckim-harness/rules/cpp.md 규칙을 따른다.
argument-hint: '<프로젝트명>'
---

# C++ 새 프로젝트 (CMake)

## 1. 이름과 위치

- 프로젝트 이름은 PascalCase다(`Forward`, `WndUI`). 다른 형태로 오면 PascalCase로 바꿔 한 번 확인한다.
- 현재 폴더 아래 `<ProjectName>/`에 만든다. 이미 있고 비어 있지 않으면 멈추고 묻는다. 덮어쓰지 않는다.
- 배너 값: 작성자는 `git config user.name`, 연도는 올해. 묻지 않고 채운다.

## 2. 구조

```
<ProjectName>/
├── CMakeLists.txt            # 공통 설정, ADD_SUBDIRECTORY(Source)
├── CMakePresets.json         # 플랫폼 = 프리셋 이름
├── .gitignore                # Build/, Binaries/
├── .history/                 # 수정 기록 (기본 지침 AGENTS.md 참고). 처음에는 .gitkeep만
├── Source/
│   ├── CMakeLists.txt        # 실행 파일 타깃
│   ├── Pch.h
│   ├── Pch.cpp
│   └── <ProjectName>.cpp
├── Build/<Platform>/         # 빌드 파일
└── Binaries/<Platform>/      # 결과물
```

플랫폼은 프리셋이 정한다. `cmake --preset macOS`이면 프리셋이 `PLATFORM_NAME=macOS`를 넘기고, 그 값으로
`Build/macOS/`, `Binaries/macOS/`가 정해진다. 프리셋 없이 configure하면 멈춘다.

아래 파일 7개와 빈 `.history/.gitkeep`을 `<ProjectName>`, `<year>`, `<author>`를 채워 만든다. `Build/`와 `Binaries/`는
빌드할 때 생긴다. 그 밖의 파일은 사용자가 요청할 때만 만든다.

`CMakeLists.txt`

```cmake
CMAKE_MINIMUM_REQUIRED(VERSION 3.22)

PROJECT(<ProjectName> LANGUAGES CXX)

# 플랫폼은 프리셋이 정한다 (cmake --preset <Platform>)
IF(NOT DEFINED PLATFORM_NAME)
    MESSAGE(FATAL_ERROR "프리셋으로 configure하세요: cmake --preset <Windows|macOS|Linux|iOS|Android>")
ENDIF()

SET(CMAKE_CXX_STANDARD 20)
SET(CMAKE_CXX_STANDARD_REQUIRED ON)

# 결과물은 Binaries/<Platform>/에 모은다. 생성기 식을 붙여 Visual Studio·Xcode가 Debug/Release 하위 폴더를 만들지 않게 한다
SET(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/Binaries/${PLATFORM_NAME}/$<$<CONFIG:Debug>:>)
SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/Binaries/${PLATFORM_NAME}/$<$<CONFIG:Debug>:>)
SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/Binaries/${PLATFORM_NAME}/$<$<CONFIG:Debug>:>)

# 정적 런타임: 배포 대상 PC에 VC++ 재배포 패키지를 요구하지 않는다
IF(MSVC)
    SET(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
ENDIF()

ADD_COMPILE_OPTIONS("$<$<CXX_COMPILER_ID:MSVC>:/utf-8>")

ADD_SUBDIRECTORY(Source)
```

`CMakePresets.json`

```json
{
    "version": 3,
    "configurePresets": [
        {
            "name": "Base",
            "hidden": true,
            "binaryDir": "${sourceDir}/Build/${presetName}",
            "cacheVariables": {
                "PLATFORM_NAME": "${presetName}"
            }
        },
        {
            "name": "Windows",
            "inherits": "Base",
            "condition": { "type": "equals", "lhs": "${hostSystemName}", "rhs": "Windows" }
        },
        {
            "name": "macOS",
            "inherits": "Base",
            "generator": "Xcode",
            "cacheVariables": {
                "CMAKE_OSX_DEPLOYMENT_TARGET": "12.0",
                "CMAKE_OSX_ARCHITECTURES": "arm64"
            },
            "condition": { "type": "equals", "lhs": "${hostSystemName}", "rhs": "Darwin" }
        },
        {
            "name": "iOS",
            "inherits": "Base",
            "generator": "Xcode",
            "cacheVariables": {
                "CMAKE_SYSTEM_NAME": "iOS",
                "CMAKE_OSX_DEPLOYMENT_TARGET": "15.0"
            },
            "condition": { "type": "equals", "lhs": "${hostSystemName}", "rhs": "Darwin" }
        },
        {
            "name": "Linux",
            "inherits": "Base",
            "generator": "Unix Makefiles",
            "cacheVariables": { "CMAKE_BUILD_TYPE": "Debug" },
            "condition": { "type": "equals", "lhs": "${hostSystemName}", "rhs": "Linux" }
        },
        {
            "name": "Android",
            "inherits": "Base",
            "generator": "Unix Makefiles",
            "toolchainFile": "$env{ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake",
            "cacheVariables": {
                "CMAKE_BUILD_TYPE": "Debug",
                "ANDROID_ABI": "arm64-v8a",
                "ANDROID_PLATFORM": "android-26"
            }
        }
    ]
}
```

`.gitignore`

```gitignore
# Build output
Build/
Binaries/
```

`Source/CMakeLists.txt`

```cmake
FILE(GLOB_RECURSE SOURCE_FILES CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/*.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp"
)

SOURCE_GROUP(TREE "${CMAKE_CURRENT_SOURCE_DIR}" PREFIX "Source Files" FILES ${SOURCE_FILES})

ADD_EXECUTABLE(${PROJECT_NAME} ${SOURCE_FILES})

# 하위 폴더의 소스도 #include "Pch.h"로 쓴다
TARGET_INCLUDE_DIRECTORIES(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

TARGET_PRECOMPILE_HEADERS(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/Pch.h)

IF(MSVC)
    TARGET_COMPILE_OPTIONS(${PROJECT_NAME} PRIVATE /W4)
ELSE()
    TARGET_COMPILE_OPTIONS(${PROJECT_NAME} PRIVATE -Wall -Wextra)
ENDIF()
```

`Source/Pch.h`

```cpp
/*
* Pch.h는 <ProjectName> 배포판의 일부입니다 (<author>).
* Copyright (c) <year> <author>
*/
#ifndef _PCH_H_
#define _PCH_H_

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <memory>
#include <string>
#include <vector>

#if defined(_WIN32)
#if !defined(NOMINMAX)
#define NOMINMAX

#endif
#include <windows.h>

#endif

#endif//_PCH_H_
```

`Source/Pch.cpp`

```cpp
/*
* Pch.cpp는 <ProjectName> 배포판의 일부입니다 (<author>).
* Copyright (c) <year> <author>
*/
#include "Pch.h"
```

`Source/<ProjectName>.cpp`

```cpp
/*
* <ProjectName>.cpp는 <ProjectName> 배포판의 일부입니다 (<author>).
* Copyright (c) <year> <author>
*/
#include "Pch.h"

int main(void)
{
    std::printf("<ProjectName>\n");

    return EXIT_SUCCESS;
}
```

## 3. git 저장소

모든 프로젝트는 각자 git 저장소다. 파일을 만든 뒤 `<ProjectName>/`에서 `git init`을 실행한다.

- 상위 폴더가 이미 git 저장소 안이면(`git -C <상위 폴더> rev-parse --is-inside-work-tree`) 중첩 저장소가 되므로,
  `git init` 전에 그대로 진행할지 묻는다.
- 첫 커밋은 하지 않고, 커밋할지 사용자에게 묻는다.

## 4. 보고

만든 파일 목록과 git 저장소 상태를 보여 주고 다음 단계를 안내한다. 빌드 파일 생성과 빌드는 하지 않는다.

```
cd <ProjectName>
/bckim:cmake-preset <Platform>     # Build/<Platform>/에 빌드 파일 생성
/bckim:cmake-build <Platform>      # 빌드, 결과물은 Binaries/<Platform>/
```

`<Platform>`은 `Windows`, `macOS`, `Linux`, `iOS`, `Android` 중 하나다.

## 파일을 늘릴 때

- 소스는 `Source/` 안 아무 폴더에나 두면 잡힌다(`CONFIGURE_DEPENDS`라 다시 빌드할 때 반영된다).
- 플랫폼마다 다른 부분은 같은 파일 안에서 `#if defined(...)`로 나눈다(C++ 규칙(`~/orca/bckim-harness/rules/cpp.md`) 5절).
- 모든 `.cpp`는 `#include "Pch.h"`로 시작한다. 표준·OS 헤더는 `Pch.h`에 추가한다.
