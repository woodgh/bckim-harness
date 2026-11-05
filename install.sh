#!/usr/bin/env bash
# bckim-harness 설치 스크립트 (macOS·Linux)
#
# 저장소 파일을 각 에이전트 설정 폴더에 링크로 연결한다. 여러 번 실행해도 안전하다.
#   ./install.sh              설치
#   ./install.sh --uninstall  이 저장소를 가리키는 링크만 지운다
#
# 이미 다른 파일이 있으면 덮어쓰지 않고 건너뛴 뒤 마지막에 알린다.

set -u

H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CANONICAL="$HOME/orca/bckim-harness"
MODE="install"
[ "${1:-}" = "--uninstall" ] && MODE="uninstall"

LINKED=0
ALREADY=0
REMOVED=0
SKIPPED=()

# link <대상 파일> <링크 경로>
link() {
    local target="$1" path="$2"

    if [ "$MODE" = "uninstall" ]; then
        if [ -L "$path" ] && [ "$(readlink "$path")" = "$target" ]; then
            rm "$path" && REMOVED=$((REMOVED + 1)) && echo "  지움      $path"
        fi
        return
    fi

    if [ -L "$path" ]; then
        if [ "$(readlink "$path")" = "$target" ]; then
            ALREADY=$((ALREADY + 1))
            return
        fi
        SKIPPED+=("$path (다른 곳을 가리키는 링크: $(readlink "$path"))")
        return
    fi

    if [ -e "$path" ]; then
        SKIPPED+=("$path (이미 있는 파일)")
        return
    fi

    mkdir -p "$(dirname "$path")"
    ln -s "$target" "$path" && LINKED=$((LINKED + 1)) && echo "  연결      $path"
}

echo "bckim-harness: $H"
[ "$MODE" = "uninstall" ] && echo "링크를 지웁니다." || echo "링크를 연결합니다."

# 0. 스킬·기본 지침은 규칙 파일을 ~/orca/bckim-harness/ 로 가리킨다. 다른 곳에 받았으면 그 경로를 링크로 만든다
if [ "$H" != "$CANONICAL" ]; then
    echo "[경로]"
    link "$H" "$CANONICAL"
fi

# 1. Claude Code
echo "[Claude Code]"
link "$H/AGENTS.md" "$HOME/.claude/CLAUDE.md"
for rule in "$H"/rules/*.md; do
    [ -e "$rule" ] || continue
    link "$rule" "$HOME/.claude/rules/$(basename "$rule")"
done
link "$H" "$HOME/.claude/skills/bckim"

# 2. Codex: 기본 지침은 ~/.codex 와 Orca가 관리하는 계정 폴더마다, 스킬은 ~/.agents/skills
echo "[Codex]"
link "$H/AGENTS.md" "$HOME/.codex/AGENTS.md"
for home in "$HOME/Library/Application Support/orca/codex-accounts"/*/home; do
    [ -d "$home" ] || continue
    link "$H/AGENTS.md" "$home/AGENTS.md"
done
if [ -n "${CODEX_HOME:-}" ] && [ -d "$CODEX_HOME" ]; then
    link "$H/AGENTS.md" "$CODEX_HOME/AGENTS.md"
fi
for skill in "$H"/skills/*/; do
    [ -f "$skill/SKILL.md" ] || continue
    name="$(basename "$skill")"
    link "$H/skills/$name" "$HOME/.agents/skills/$name"
done

# 3. Gemini CLI
echo "[Gemini CLI]"
link "$H/AGENTS.md" "$HOME/.gemini/GEMINI.md"
if command -v gemini >/dev/null 2>&1; then
    if [ "$MODE" = "uninstall" ]; then
        gemini extensions uninstall bckim >/dev/null 2>&1 && echo "  지움      Gemini 확장 bckim"
    elif gemini extensions list 2>/dev/null | grep -q 'bckim'; then
        ALREADY=$((ALREADY + 1))
    else
        echo y | gemini extensions link "$H" >/dev/null 2>&1 && LINKED=$((LINKED + 1)) && echo "  연결      Gemini 확장 bckim" \
            || SKIPPED+=("Gemini 확장 (gemini extensions link 실패. 직접 실행: gemini extensions link $H)")
    fi
else
    echo "  gemini가 없어 확장 연결은 건너뜁니다."
fi

echo
if [ "$MODE" = "uninstall" ]; then
    echo "지운 링크 ${REMOVED}개."
else
    echo "새로 연결 ${LINKED}개, 이미 연결됨 ${ALREADY}개, 건너뜀 ${#SKIPPED[@]}개."
    if [ "${#SKIPPED[@]}" -gt 0 ]; then
        echo "건너뛴 항목 (내용을 확인하고 옮긴 뒤 다시 실행하세요):"
        for item in "${SKIPPED[@]}"; do
            echo "  - $item"
        done
    fi
    echo "Claude Code가 실행 중이면 /reload-plugins, Codex·Gemini는 새 세션부터 적용됩니다."
fi
