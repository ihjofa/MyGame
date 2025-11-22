#!/bin/bash
#
# check-dependencies.sh
# Unity Test CLI実行に必要な依存関係を確認するスクリプト
#

set -euo pipefail

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# チェック結果を記録
declare -a MISSING_DEPENDENCIES=()
declare -a FOUND_DEPENDENCIES=()

# ヘッダーを表示
print_header() {
    echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  Dependency Checker${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# 依存関係をチェック
check_command() {
    local command_name="$1"
    local description="$2"
    local install_hint="$3"

    echo -n "Checking ${description}... "

    if command -v "${command_name}" &> /dev/null; then
        local version
        version=$(${command_name} --version 2>&1 | head -1 || echo "unknown version")

        echo -e "${GREEN}✓ Found${NC}"
        echo -e "  ${BLUE}Version:${NC} ${version}"

        FOUND_DEPENDENCIES+=("${description}")
    else
        echo -e "${RED}✗ Not found${NC}"
        echo -e "  ${YELLOW}Install:${NC} ${install_hint}"

        MISSING_DEPENDENCIES+=("${description}")
    fi

    echo ""
}

# Unityのチェック
check_unity() {
    echo -n "Checking Unity... "

    # find-unity.sh を使用
    if [ -f "${SCRIPT_DIR}/find-unity.sh" ]; then
        local unity_path
        unity_path=$("${SCRIPT_DIR}/find-unity.sh" 2>/dev/null) || {
            echo -e "${RED}✗ Not found${NC}"
            echo -e "  ${YELLOW}Install:${NC} Download from https://unity.com/download"
            echo -e "  ${YELLOW}Or:${NC} Install via UnityHub"
            echo ""
            MISSING_DEPENDENCIES+=("Unity Editor")
            return 1
        }

        echo -e "${GREEN}✓ Found${NC}"
        echo -e "  ${BLUE}Path:${NC} ${unity_path}"

        # バージョン情報を取得
        local version
        version=$("${SCRIPT_DIR}/find-unity.sh" --version 2>/dev/null || echo "Unknown version")
        echo -e "  ${BLUE}Version:${NC} ${version}"

        FOUND_DEPENDENCIES+=("Unity Editor")
    else
        echo -e "${YELLOW}⚠ find-unity.sh not found${NC}"
        echo -e "  ${YELLOW}Cannot auto-detect Unity${NC}"
        echo ""
        MISSING_DEPENDENCIES+=("find-unity.sh")
    fi

    echo ""
}

# Bashバージョンをチェック
check_bash_version() {
    echo -n "Checking Bash version... "

    local bash_version="${BASH_VERSION%%.*}"

    if [ "${bash_version}" -ge 4 ]; then
        echo -e "${GREEN}✓ ${BASH_VERSION}${NC}"
        FOUND_DEPENDENCIES+=("Bash ${BASH_VERSION}")
    else
        echo -e "${YELLOW}⚠ ${BASH_VERSION} (version 4+ recommended)${NC}"
        echo -e "  ${YELLOW}Install:${NC} sudo apt-get install bash"
    fi

    echo ""
}

# プロジェクト構造をチェック
check_project_structure() {
    echo -e "${BOLD}Checking project structure...${NC}\n"

    local project_root
    project_root="$(cd "${SCRIPT_DIR}/.." && pwd)"

    # Unity プロジェクトパスをチェック
    local unity_project="${project_root}/unity/My project"
    echo -n "Unity project directory... "

    if [ -d "${unity_project}" ]; then
        echo -e "${GREEN}✓ Found${NC}"
        echo -e "  ${BLUE}Path:${NC} ${unity_project}"
    else
        echo -e "${RED}✗ Not found${NC}"
        echo -e "  ${YELLOW}Expected:${NC} ${unity_project}"
        MISSING_DEPENDENCIES+=("Unity project directory")
    fi

    echo ""

    # テストディレクトリをチェック
    local test_dir="${unity_project}/Assets/Tests"
    echo -n "Test directory... "

    if [ -d "${test_dir}" ]; then
        echo -e "${GREEN}✓ Found${NC}"
        echo -e "  ${BLUE}Path:${NC} ${test_dir}"

        # PlayModeテストをチェック
        local playmode_tests="${test_dir}/PlayMode"
        if [ -d "${playmode_tests}" ]; then
            local test_count
            test_count=$(find "${playmode_tests}" -name "*.cs" -type f | wc -l)
            echo -e "  ${BLUE}PlayMode tests:${NC} ${test_count} file(s)"
        fi
    else
        echo -e "${YELLOW}⚠ Not found${NC}"
        echo -e "  ${YELLOW}Expected:${NC} ${test_dir}"
    fi

    echo ""
}

# サマリーを表示
print_summary() {
    echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  Summary${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    echo -e "${GREEN}${BOLD}Found:${NC} ${#FOUND_DEPENDENCIES[@]} dependencies"
    for dep in "${FOUND_DEPENDENCIES[@]}"; do
        echo -e "  ${GREEN}✓${NC} ${dep}"
    done

    echo ""

    if [ ${#MISSING_DEPENDENCIES[@]} -gt 0 ]; then
        echo -e "${RED}${BOLD}Missing:${NC} ${#MISSING_DEPENDENCIES[@]} dependencies"
        for dep in "${MISSING_DEPENDENCIES[@]}"; do
            echo -e "  ${RED}✗${NC} ${dep}"
        done
        echo ""
        echo -e "${YELLOW}${BOLD}Action Required:${NC}"
        echo -e "Please install missing dependencies to use Unity Test CLI${NC}\n"
        return 1
    else
        echo -e "${GREEN}${BOLD}✓ All dependencies are satisfied!${NC}"
        echo -e "You can now use Unity Test CLI scripts${NC}\n"
        return 0
    fi
}

# メイン処理
main() {
    print_header

    # 基本的なコマンドツールをチェック
    check_bash_version
    check_command "inotifywait" "inotify-tools (for file watching)" "sudo apt-get install inotify-tools"
    check_command "timeout" "timeout command" "usually pre-installed (coreutils)"
    check_command "xmllint" "XML parser (optional)" "sudo apt-get install libxml2-utils"

    echo ""

    # Unity をチェック
    check_unity

    # プロジェクト構造をチェック
    check_project_structure

    # サマリーを表示
    if print_summary; then
        exit 0
    else
        exit 1
    fi
}

# スクリプト実行
main "$@"
