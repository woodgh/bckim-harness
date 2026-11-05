---
paths:
  - "**/*.{h,hh,hpp,hxx,c,cc,cpp,cxx,inl,ixx,mm}"
  - "**/CMakeLists.txt"
  - "**/CMakePresets.json"
---
<!--
C++ 규칙. Claude Code는 ~/.claude/rules/cpp.md 링크로 C/C++ 파일을 다룰 때 자동으로 붙는다.
Codex·Gemini는 전역 AGENTS.md의 안내에 따라 이 파일을 읽는다.
-->

# C++ 규칙

표준 C++20과 표준 라이브러리로 Windows·macOS·Linux·iOS·Android를 한 소스로 빌드한다.
규칙은 사용자의 Forward·WndUI 코드에서 추출했다.

프로젝트 루트의 `AGENTS.md`·`CLAUDE.md`·`.clang-format`이 있으면 그것이 우선이다. 다른 저장소와
공유하는 코드는 스타일만을 위해 고치지 않고, 스타일만을 위한 대규모 재작성도 하지 않는다.

## 1. 폴더 구성

```
<Project>/
├── CMakeLists.txt           # 프로젝트 공통 설정, ADD_SUBDIRECTORY(Source)
├── CMakePresets.json        # 플랫폼 = 프리셋 이름 (Windows / macOS / Linux / iOS / Android)
├── .gitignore               # Build/, Binaries/
├── .clang-format            # 하네스 rules/cpp.clang-format
├── Source/
│   ├── CMakeLists.txt       # 타깃
│   ├── Pch.h, Pch.cpp       # 표준·OS 헤더는 Pch.h에만
│   ├── <Project>.cpp
│   └── <Module>/Foo.h, Foo.cpp
├── Build/<Platform>/        # 빌드 파일, git 제외
└── Binaries/<Platform>/     # 결과물
```

새 프로젝트는 `/bckim:cmake`가 이 구조로 만든다. 리뷰는 `/bckim:review`.

- 폴더·파일 이름은 PascalCase. 클래스 하나에 `.h`/`.cpp` 한 쌍을 같은 폴더에 둔다(`include/`·`src/` 분리 없음).
- 플랫폼은 프리셋이 정한다(`cmake --preset <Platform>`). 프리셋 이름이 `Build/<Platform>/`, `Binaries/<Platform>/`
  폴더 이름이 된다.
- 플랫폼마다 다른 부분은 같은 파일 안에서 `#if defined(...)`로 나눈다(5절).
- CMake 명령은 대문자(`ADD_LIBRARY`, `IF()`/`ENDIF()`), 4칸 들여쓰기, `CMAKE_CXX_STANDARD 20`.
  MSVC는 `/utf-8`. 이유가 있는 설정에는 `#` 한글 주석을 단다.

## 2. 이름

| 대상 | 규칙 | 예 |
|---|---|---|
| 클래스·구조체·타입 별칭 | PascalCase | `Buffer` |
| enum | `enum class` + `E` 접두사 | `EIOType` |
| public·protected 함수, 자유 함수 | PascalCase | `WriteBytes` |
| private 함수 | camelCase | `releaseReference` |
| 매개변수·지역 변수 | PascalCase | `const int64_t Size`, `auto Found` |
| 데이터 멤버 | camelCase + `_` | `recvBytes_`, `isActive_` |
| 상수 | `k` + PascalCase | `kMaxEvents` |
| 전역 / 파일 static | `g` + PascalCase / `s_` + camelCase | `gApp`, `s_windowCount` |
| 매크로 | UPPER_SNAKE | `APP_API` |
| 템플릿 매개변수 | `T`, 가변 팩 `ARGS... Args` | |

- 줄이지 않는다(`Count`, `Buffer`). 루프 인덱스는 `Index`. `Get` 접두사 없이 `Capacity()`.
- bool은 `isActive_`, `HasState()` 형태. 단위를 이름에 쓴다: `TimeoutMs`, `recvBytes_`.
- enum은 `None = 0`으로 시작해 `Max`로 끝난다.

## 3. 형식

`.clang-format`(하네스 `rules/cpp.clang-format`, 프로젝트 루트에 `.clang-format`으로 둔다)이 형식을 정한다. 사용자 원본 `WndApp.cpp`에 적용하면 차이가 0줄이다.

- Allman 중괄호, 공백 4칸, 한 문장은 길어도 한 줄.
- 왼쪽 맞춤만: 대입·선언·줄 끝 주석을 열 맞춤하지 않는다(enum 값의 `=`만 예외).
- 빈 매개변수는 `(void)`, 템플릿 꺾쇠 안 공백 `std::shared_ptr< Session >`, 포인터·참조는 타입에 붙인다.
- 함수 뒤와 멤버 선언 사이에 빈 줄 하나. 한 문장 본문의 `if`는 중괄호 생략 가능.
- 클래스는 그룹마다 `public:`을 반복: 생성자·소멸자 → 연산자 → 공개 API → 접근자 → private 함수 → 데이터.

```cpp
/*
* Buffer.h는 Runtime 배포판의 일부입니다 (<author>).
* Copyright (c) <year> <author>
*/
#ifndef _BUFFER_H_
#define _BUFFER_H_

/**
    수신 바이트를 모았다가 완성된 프레임 단위로 꺼낸다
*/
class Buffer
{
public:
    Buffer(void) = default;

    Buffer(const Buffer&) = delete;

public:
    // WriteBytes는 Bytes를 버퍼 끝에 붙인다.
    // Args:
    //   Bytes: 붙일 바이트.
    //   Reason: 실패하면 ENOBUFS.
    bool WriteBytes(std::span< const uint8_t > Bytes, int32_t& Reason);

public:
    size_t ReadableBytes(void) const
    {
        return recvBytes_ - readBytes_;
    }

private:
    std::vector< uint8_t > buffer_;

    size_t recvBytes_ = 0;

    size_t readBytes_ = 0;
};

#endif//_BUFFER_H_
```

- 헤더 가드는 `#ifndef _NAME_H_` / `#endif//_NAME_H_`(`WndAppInternal.h` → `_WND_APP_INTERNAL_H_`). `#pragma once`는 Unreal 모듈에서만.
- 모든 파일은 배너로 시작한다. `.cpp` include 순서: `Pch.h` → 의존 헤더 → 자기 헤더.
- 주석은 한글. 무엇보다 왜, 그리고 단위와 호출 스레드를 쓴다. Doxygen 태그와 주석 처리한 코드는 쓰지 않는다.

## 4. 관용구

- `!` 대신 명시적 비교: `== false`, `== nullptr`, `== 0`, `.empty() == true`(전처리기 `!defined`는 예외).
- 조기 반환으로 정상 흐름을 왼쪽에 둔다.
- 정수는 `int32_t`·`int64_t`·`uint8_t`, 컨테이너 크기는 `size_t`. `long`은 쓰지 않는다.
- `nullptr`, `static_cast`, 상수는 `constexpr`. 매크로는 플랫폼 분기·export에만.

## 5. 설계

- **오류:** 예외를 던지지 않는다. `bool`을 돌려주고 원인은 마지막 매개변수 `int32_t& Reason`
  (`errno`, `GetLastError()`, 잘못된 입력은 `EINVAL`, 미지원은 `ENOTSUP`). 모든 `return false` 앞에서
  `Reason`을 채운다. 예외를 던지는 표준 함수(`std::stoi`, `at()`)는 피한다.
- **소유권:** 값 우선, 소유권 이전은 `std::unique_ptr`, 정말 공유할 때만 `std::shared_ptr`.
  `new`/`delete`/`malloc`을 직접 쓰지 않는다. OS 핸들은 RAII로 감싼다.
- **크로스 플랫폼:** 플랫폼마다 다른 부분은 `#if defined(_WIN32)` / `__APPLE__`(+`TARGET_OS_IPHONE`) /
  `__ANDROID__`(→ `__linux__`보다 먼저) / `__linux__`로 나누고 `#else #error`로 막는다.
  64비트만 지원한다. 문자열은 UTF-8 `std::string`이고 Windows API 경계에서만 UTF-16으로 바꾼다.
  한 플랫폼을 고치면 나머지 플랫폼의 같은 지점도 고친다.
- **동시성:** `std::jthread` + `std::stop_token`, `std::mutex` + `std::lock_guard`, 원자 연산은 메모리
  순서를 명시. 콜백이 어느 스레드에서 불리는지 주석에 쓴다.
- **단순하게:** 추상 계층·관리자 클래스·매크로를 필요해질 때까지 만들지 않는다. 의존성은 최소로.

## 6. 리뷰할 때 볼 점

`/bckim:review`가 C/C++ 변경을 볼 때 공통 순서에 더해 확인한다.

- **정확성:** 실패 경로의 자원 해제, 미정의 동작(초기화, 범위, 부호 있는 오버플로, 끝난 수명·`string_view`·람다 캡처).
- **크로스 플랫폼:** 한 플랫폼 분기만 고쳤는가, `#if` 분기에 `#else #error`가 있는가, `long`·`wchar_t` 크기 가정,
  UTF-8 처리, Android를 `__linux__`보다 먼저 검사하는가.
- **소유권:** `new`/`delete`/`malloc` 직접 사용, 소유 원시 포인터, 불필요한 `shared_ptr`.
- **오류 처리:** `throw`, `Reason`을 채우지 않는 `return false`, 반환값 무시, 예외를 던지는 표준 함수.
- **동시성:** 잠금 없는 공유 상태, `detach`, 콜백 호출 스레드 표기.
- **스타일:** 이름, `!` 대신 `== false`, `(void)`, 헤더 가드, include 순서, 한글 주석.
- 프로젝트에 `.clang-format`이 있고 `clang-format`이 있으면 `clang-format --dry-run`으로 형식을 확인한다.
  `#endif//` 공백 차이는 무시한다.

## 7. 의존성 (vcpkg)

- 외부 라이브러리는 표준 라이브러리와 OS API로 안 될 때만 들인다. 들일 때는 vcpkg로만 관리한다(`/bckim:vcpkg`).
- vcpkg는 git 서브모듈 `ThirdParty/vcpkg`, 매니페스트는 `ThirdParty/vcpkg.json` 하나다. 시스템에 설치한 패키지에 기대지 않는다.
- 연결 방식은 기본 STATIC이다. DYNAMIC은 `ThirdParty/vcpkg-triplets/Linkage.cmake`의 `DYNAMIC_PORTS`에 적은 패키지만이고,
  Windows·macOS·Linux에만 적용된다. iOS·Android는 항상 STATIC이다.
- 패키지는 `"default-features": false`로 넣고 필요한 기능만 `features`로 켠다. 빌드 뒤 소스·중간 파일은 지운다(`--clean-after-build`).
- triplet은 프리셋이 정한다: Windows `x64-windows-static`, macOS `arm64-osx`, iOS `arm64-ios-simulator`, Linux `x64-linux`,
  Android `arm64-android`(NDK 툴체인은 `VCPKG_CHAINLOAD_TOOLCHAIN_FILE`).
- CMake에서는 `FIND_PACKAGE(<이름> CONFIG REQUIRED)`와 `TARGET_LINK_LIBRARIES(... PRIVATE <타깃>)`로 쓴다.
  `vcpkg_installed` 경로를 직접 적지 않는다.
