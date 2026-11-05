---
name: vcpkg
description: |
  C++ 프로젝트의 vcpkg 의존성을 관리한다. `install <패키지> [STATIC|DYNAMIC]`(기본 STATIC,
  iOS·Android는 항상 STATIC)은 ThirdParty/vcpkg.json에 추가하고, DYNAMIC이면
  ThirdParty/vcpkg-triplets/Linkage.cmake에 적고, Source/CMakeLists.txt에 FIND_PACKAGE·
  TARGET_LINK_LIBRARIES를 넣은 뒤 configure로 설치한다. `remove <패키지>`는 되돌리고 `list`는
  목록을 보여 준다. 처음이면 ThirdParty/vcpkg 서브모듈·triplet·프리셋까지 준비한다.
  "vcpkg로 fmt 설치해줘", "라이브러리 추가해줘", "패키지 빼줘"에 쓴다.
argument-hint: 'install <패키지> [STATIC|DYNAMIC] | remove <패키지> | list'
---

# vcpkg 의존성

## 0. 공통

- 프로젝트 루트는 git 최상위 폴더다(`git rev-parse --show-toplevel`). 그곳에 `CMakePresets.json`이 없으면 멈추고
  `/bckim:cmake <프로젝트명>`으로 먼저 만들라고 알린다.
- 연결 방식 인자는 대소문자를 가리지 않는다. 없으면 STATIC이다.
- 패키지 이름은 vcpkg 포트 이름이다. `ThirdParty/vcpkg/ports/<패키지>/`가 없으면 멈추고 비슷한 이름을 찾아 제안한다
  (`ls ThirdParty/vcpkg/ports | grep -i <일부>`).

## 1. 처음 한 번: vcpkg 준비

`ThirdParty/vcpkg/scripts/buildsystems/vcpkg.cmake`가 없을 때만 한다. 이미 있는 파일은 덮어쓰지 않는다.

1. 서브모듈
   - `.gitmodules`에 `ThirdParty/vcpkg`가 없으면: `git submodule add --depth 1 https://github.com/microsoft/vcpkg ThirdParty/vcpkg`
   - 있는데 폴더가 비었으면: `git submodule update --init --depth 1 ThirdParty/vcpkg`
   - 부트스트랩은 하지 않는다. configure할 때 `vcpkg.cmake`가 알아서 준비한다.
2. 아래 파일을 만든다.
3. `CMakePresets.json`을 고친다(아래 표). 다른 값은 건드리지 않는다.

`ThirdParty/vcpkg.json`

```json
{
    "name": "main",
    "version-string": "latest",
    "dependencies": [
    ]
}
```

`ThirdParty/vcpkg-triplets/Linkage.cmake`

```cmake
# 패키지별 연결 방식. 기본은 정적(STATIC)이고, 여기 적은 패키지만 동적(DYNAMIC)이다.
# /bckim:vcpkg install <패키지> DYNAMIC 이 이 목록을 고친다.

# vcpkg는 triplet 파일만 보고 빌드 캐시를 고른다. 이 파일이 바뀌면 다시 빌드하도록 캐시 판단에 넣는다
LIST(APPEND VCPKG_HASH_ADDITIONAL_FILES "${CMAKE_CURRENT_LIST_FILE}")

SET(DYNAMIC_PORTS
)

IF(VCPKG_CMAKE_SYSTEM_NAME STREQUAL "iOS" OR VCPKG_CMAKE_SYSTEM_NAME STREQUAL "Android")
    # iOS·Android는 항상 정적: iOS 동적 라이브러리는 프레임워크로 넣고 서명해야 하고,
    # Android는 .so마다 APK에 넣고 libc++_shared를 맞춰야 한다. 앱 하나에 정적으로 넣는다
    SET(VCPKG_LIBRARY_LINKAGE static)

ELSEIF(PORT IN_LIST DYNAMIC_PORTS)
    SET(VCPKG_LIBRARY_LINKAGE dynamic)

    # Windows DLL은 동적 CRT로만 빌드할 수 있다
    IF(VCPKG_CMAKE_SYSTEM_NAME STREQUAL "" OR VCPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore")
        SET(VCPKG_CRT_LINKAGE dynamic)
    ENDIF()
ENDIF()
```

`ThirdParty/vcpkg-triplets/<triplet>.cmake` 5개. `<triplet>`과 기본 triplet 경로만 다르다.

| 파일 | 기본 triplet 경로 (`ThirdParty/vcpkg/triplets/` 기준) |
|---|---|
| `x64-windows-static.cmake` | `x64-windows-static.cmake` |
| `arm64-osx.cmake` | `arm64-osx.cmake` |
| `arm64-ios-simulator.cmake` | `community/arm64-ios-simulator.cmake` |
| `x64-linux.cmake` | `x64-linux.cmake` |
| `arm64-android.cmake` | `arm64-android.cmake` |

```cmake
# 기본 <triplet> triplet + 패키지별 연결 방식
INCLUDE(${CMAKE_CURRENT_LIST_DIR}/../vcpkg/triplets/<기본 triplet 경로>)
INCLUDE(${CMAKE_CURRENT_LIST_DIR}/Linkage.cmake)
```

`arm64-osx.cmake`와 `arm64-ios-simulator.cmake`에는 아래 두 줄을 더한다. 값은 `CMakePresets.json`의 해당 프리셋
`CMAKE_OSX_DEPLOYMENT_TARGET`과 같게 한다(macOS `12.0`, iOS `15.0`). 빠지면 vcpkg가 SDK 기본 버전으로 빌드해 링크할 때
`was built for newer 'macOS' version` 경고가 난다. 프리셋 값을 바꾸면 여기도 같이 바꾼다.

```cmake

# 프리셋(CMAKE_OSX_DEPLOYMENT_TARGET)과 같은 대상으로 빌드한다. 다르면 링크할 때 버전 경고가 난다
SET(VCPKG_OSX_DEPLOYMENT_TARGET 12.0)
```

`CMakePresets.json` 변경

| 프리셋 | 추가 |
|---|---|
| `Base` | `"toolchainFile": "${sourceDir}/ThirdParty/vcpkg/scripts/buildsystems/vcpkg.cmake"`, `cacheVariables`에 `"VCPKG_MANIFEST_DIR": "${sourceDir}/ThirdParty"`, `"VCPKG_OVERLAY_TRIPLETS": "${sourceDir}/ThirdParty/vcpkg-triplets"`, `"VCPKG_INSTALL_OPTIONS": "--clean-after-build"`(빌드 뒤 소스·중간 파일 삭제, 로그만 남김) |
| `Windows` | `"VCPKG_TARGET_TRIPLET": "x64-windows-static"` |
| `macOS` | `"VCPKG_TARGET_TRIPLET": "arm64-osx"` |
| `iOS` | `"VCPKG_TARGET_TRIPLET": "arm64-ios-simulator"` |
| `Linux` | `"VCPKG_TARGET_TRIPLET": "x64-linux"` |
| `Android` | `"VCPKG_TARGET_TRIPLET": "arm64-android"`. 기존 `toolchainFile`(NDK)은 `cacheVariables`의 `"VCPKG_CHAINLOAD_TOOLCHAIN_FILE"`로 옮기고, `toolchainFile`은 Base와 같은 vcpkg 경로로 바꾼다 |

## 2. `install <패키지> [STATIC|DYNAMIC]`

1. vcpkg가 준비되지 않았으면 1절부터 한다.
2. `ThirdParty/vcpkg.json`의 `dependencies`에 선택 기능을 끈 형태로 추가한다. 도구·예제 같은 기본 기능을 빌드하지 않기 위해서다.
   이미 있으면 연결 방식만 맞춘다.

   ```json
   { "name": "fmt", "default-features": false }
   ```

   사용자가 기능을 요청했거나 configure가 필요한 기능이 없다고 실패하면 그 기능만 `"features": ["..."]`로 켠다.
   포트의 기능 목록은 `ThirdParty/vcpkg/ports/<패키지>/vcpkg.json`의 `features`에 있다.
3. 연결 방식
   - DYNAMIC: `Linkage.cmake`의 `DYNAMIC_PORTS`에 한 줄 추가한다. Windows·macOS·Linux에만 적용되고,
     iOS·Android는 항상 STATIC이다.
   - STATIC: `DYNAMIC_PORTS`에 있으면 뺀다.
4. CMake 연결: `ThirdParty/vcpkg/ports/<패키지>/usage`가 있으면 그 내용대로, 없으면 configure 출력의 사용법
   안내대로 `Source/CMakeLists.txt`의 `ADD_EXECUTABLE` 아래에 대문자로 추가한다.

   ```cmake
   FIND_PACKAGE(fmt CONFIG REQUIRED)
   TARGET_LINK_LIBRARIES(${PROJECT_NAME} PRIVATE fmt::fmt)
   ```

5. 현재 OS의 프리셋으로 configure해 설치를 확인한다(`/bckim:cmake-preset`과 같은 절차). 처음에는 vcpkg 준비와
   패키지 빌드로 1분 이상 걸릴 수 있다고 미리 알린다.

## 3. `remove <패키지>`

`vcpkg.json`, `DYNAMIC_PORTS`, `Source/CMakeLists.txt`의 `FIND_PACKAGE`·`TARGET_LINK_LIBRARIES`에서 뺀다.
코드에 그 패키지의 `#include`가 남아 있으면 위치를 알리고 지우지는 않는다. 다시 configure해 확인한다.

## 4. `list`

`vcpkg.json`의 패키지마다 연결 방식(STATIC/DYNAMIC)을 표로 보여 준다.

## 5. 보고

- 바뀐 파일, 패키지와 연결 방식, configure 결과를 알린다. 다음 단계는 `/bckim:cmake-build <Platform>`.
- DYNAMIC을 골랐으면 덧붙인다.
  - Windows: DLL은 vcpkg가 `Binaries/Windows/`로 복사한다. 앱은 정적 CRT, DLL은 동적 CRT라 C++ 타입(`std::string` 등)을
    경계로 주고받으면 문제가 생길 수 있다.
  - macOS·Linux: 라이브러리는 `Build/<Platform>/vcpkg_installed/`에 있다. 배포하려면 함께 복사해야 한다.
  - iOS·Android: DYNAMIC을 지정해도 정적으로 빌드된다.
- 커밋은 하지 않는다. 서브모듈 추가(`.gitmodules`, `ThirdParty/vcpkg`)와 바뀐 파일을 알리고 커밋할지 묻는다.
