#!/bin/bash
#
# find-unity.sh
# Unity エディタの実行ファイルパスを自動検出するスクリプト
#

set -euo pipefail

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Unity実行ファイルを検索
find_unity() {
    local unity_path=""

    # Method 1: PATH環境変数から検索
    if command -v unity-editor &> /dev/null; then
        unity_path=$(which unity-editor)
        echo -e "${GREEN}Found Unity in PATH: ${unity_path}${NC}" >&2
        echo "${unity_path}"
        return 0
    fi

    if command -v Unity &> /dev/null; then
        unity_path=$(which Unity)
        echo -e "${GREEN}Found Unity in PATH: ${unity_path}${NC}" >&2
        echo "${unity_path}"
        return 0
    fi

    # Method 2: WSL2環境でWindowsのUnityを検索
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo -e "${YELLOW}WSL2 environment detected, searching for Windows Unity...${NC}" >&2

        local windows_unityhub_paths=(
            "/mnt/c/Program Files/Unity/Hub/Editor"
            "/mnt/c/Program Files (x86)/Unity/Hub/Editor"
            "/mnt/d/Program Files/Unity/Hub/Editor"
        )

        for hub_path in "${windows_unityhub_paths[@]}"; do
            if [ -d "${hub_path}" ]; then
                # 最新バージョンのUnityを検索（バージョン番号でソート）
                while IFS= read -r unity_version_path; do
                    local editor_path="${unity_version_path}/Editor/Unity.exe"
                    if [ -f "${editor_path}" ]; then
                        echo -e "${GREEN}Found Unity (Windows) in UnityHub: ${editor_path}${NC}" >&2
                        echo "${editor_path}"
                        return 0
                    fi
                done < <(find "${hub_path}" -maxdepth 1 -type d 2>/dev/null | sort -V -r)
            fi
        done
    fi

    # Method 3: Linux版UnityHub管理下のエディタを検索
    local unityhub_paths=(
        "$HOME/.local/share/UnityHub/Editor"
        "$HOME/Unity/Hub/Editor"
        "/opt/Unity/Hub/Editor"
    )

    for hub_path in "${unityhub_paths[@]}"; do
        if [ -d "${hub_path}" ]; then
            # 最新バージョンのUnityを検索
            while IFS= read -r unity_version_path; do
                local editor_path="${unity_version_path}/Editor/Unity"
                if [ -f "${editor_path}" ] && [ -x "${editor_path}" ]; then
                    echo -e "${GREEN}Found Unity in UnityHub: ${editor_path}${NC}" >&2
                    echo "${editor_path}"
                    return 0
                fi
            done < <(find "${hub_path}" -maxdepth 1 -type d | sort -V -r)
        fi
    done

    # Method 3: 一般的なインストールパスを検索
    local common_paths=(
        "/opt/Unity/Editor/Unity"
        "/usr/bin/unity-editor"
        "/usr/local/bin/Unity"
        "$HOME/Unity/Editor/Unity"
    )

    for path in "${common_paths[@]}"; do
        if [ -f "${path}" ] && [ -x "${path}" ]; then
            echo -e "${GREEN}Found Unity at: ${path}${NC}" >&2
            echo "${path}"
            return 0
        fi
    done

    # Method 4: システム全体を検索（時間がかかる可能性あり）
    echo -e "${YELLOW}Searching for Unity in common directories...${NC}" >&2

    local search_dirs=(
        "/opt"
        "$HOME/.local"
        "$HOME"
    )

    for search_dir in "${search_dirs[@]}"; do
        if [ -d "${search_dir}" ]; then
            while IFS= read -r found_path; do
                if [ -x "${found_path}" ]; then
                    echo -e "${GREEN}Found Unity at: ${found_path}${NC}" >&2
                    echo "${found_path}"
                    return 0
                fi
            done < <(find "${search_dir}" -name "Unity" -type f 2>/dev/null | grep -E "Editor/Unity$" | head -1)
        fi
    done

    echo -e "${RED}ERROR: Unity installation not found${NC}" >&2
    echo -e "${YELLOW}Please install Unity or set UNITY_PATH environment variable${NC}" >&2
    return 1
}

# Unity バージョンを取得
get_unity_version() {
    local unity_path="$1"

    # Windows版Unity (.exe) の場合、実行権限チェックをスキップ
    if [[ ! "${unity_path}" =~ \.exe$ ]] && [ ! -x "${unity_path}" ]; then
        echo -e "${RED}ERROR: Unity executable not found or not executable: ${unity_path}${NC}" >&2
        return 1
    fi

    if [ ! -f "${unity_path}" ]; then
        echo -e "${RED}ERROR: Unity executable not found: ${unity_path}${NC}" >&2
        return 1
    fi

    # Unityのバージョンを取得（-versionフラグ）
    local version_output
    version_output=$("${unity_path}" -version 2>&1 | head -1 || echo "Unknown")

    echo "${version_output}"
}

# メイン処理
main() {
    # 環境変数 UNITY_PATH が設定されていればそれを使用
    if [ -n "${UNITY_PATH:-}" ]; then
        # Windows版Unity (.exe) の場合、実行権限チェックをスキップ
        if [[ "${UNITY_PATH}" =~ \.exe$ ]]; then
            if [ -f "${UNITY_PATH}" ]; then
                echo -e "${GREEN}Using UNITY_PATH: ${UNITY_PATH}${NC}" >&2
                echo "${UNITY_PATH}"

                # バージョン情報を表示
                if [ "${1:-}" == "--version" ]; then
                    get_unity_version "${UNITY_PATH}"
                fi

                return 0
            else
                echo -e "${RED}ERROR: UNITY_PATH is set but file not found: ${UNITY_PATH}${NC}" >&2
                return 1
            fi
        else
            if [ -f "${UNITY_PATH}" ] && [ -x "${UNITY_PATH}" ]; then
                echo -e "${GREEN}Using UNITY_PATH: ${UNITY_PATH}${NC}" >&2
                echo "${UNITY_PATH}"

                # バージョン情報を表示
                if [ "${1:-}" == "--version" ]; then
                    get_unity_version "${UNITY_PATH}"
                fi

                return 0
            else
                echo -e "${RED}ERROR: UNITY_PATH is set but file is not executable: ${UNITY_PATH}${NC}" >&2
                return 1
            fi
        fi
    fi

    # Unity を検索
    local unity_path
    unity_path=$(find_unity)

    if [ -z "${unity_path}" ]; then
        return 1
    fi

    # Unityパスを出力
    echo "${unity_path}"

    # バージョン情報を表示（--versionオプション）
    if [ "${1:-}" == "--version" ]; then
        get_unity_version "${unity_path}" >&2
    fi

    return 0
}

# スクリプト実行
main "$@"
