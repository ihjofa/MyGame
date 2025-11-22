#!/bin/bash
#
# watch-and-test.sh
# ファイル変更を監視して自動的にUnityテストを実行するスクリプト
#

set -euo pipefail

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 設定
WATCH_DIR="${PROJECT_ROOT}/unity/My project/Assets"
DEBOUNCE_SECONDS=3
TEST_MODE="playmode"

# 使用方法を表示
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Watch for file changes and automatically run Unity tests"
    echo ""
    echo "Options:"
    echo "  -d, --dir <directory>   Directory to watch (default: Assets/)"
    echo "  -m, --mode <mode>       Test mode: playmode, editmode, or both (default: playmode)"
    echo "  -w, --wait <seconds>    Debounce wait time in seconds (default: ${DEBOUNCE_SECONDS})"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Watch Assets/ and run PlayMode tests"
    echo "  $0 -m both              # Run both PlayMode and EditMode tests"
    echo "  $0 -w 5                 # Wait 5 seconds after last change before running tests"
    exit 0
}

# inotifywait の存在確認
check_inotifywait() {
    if ! command -v inotifywait &> /dev/null; then
        echo -e "${RED}ERROR: inotifywait not found${NC}" >&2
        echo -e "${YELLOW}Please install inotify-tools:${NC}" >&2
        echo -e "  ${CYAN}sudo apt-get install inotify-tools${NC}" >&2
        echo -e "  ${CYAN}# or${NC}" >&2
        echo -e "  ${CYAN}sudo yum install inotify-tools${NC}" >&2
        return 1
    fi
    return 0
}

# テストを実行
run_tests() {
    local test_mode="$1"

    echo -e "\n${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}  Change detected - Running tests...${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    local start_time
    start_time=$(date +%s)

    # run-unity-tests.sh を実行
    if [ -f "${SCRIPT_DIR}/run-unity-tests.sh" ]; then
        if "${SCRIPT_DIR}/run-unity-tests.sh" -m "${test_mode}"; then
            local end_time
            end_time=$(date +%s)
            local duration=$((end_time - start_time))

            echo -e "\n${GREEN}${BOLD}✓ Tests completed successfully in ${duration}s${NC}\n"
        else
            local end_time
            end_time=$(date +%s)
            local duration=$((end_time - start_time))

            echo -e "\n${RED}${BOLD}✗ Tests failed after ${duration}s${NC}\n"
        fi
    else
        echo -e "${RED}ERROR: run-unity-tests.sh not found${NC}" >&2
        return 1
    fi

    echo -e "${MAGENTA}${BOLD}Watching for changes...${NC}\n"
}

# ファイル監視ループ
watch_loop() {
    local watch_dir="$1"
    local test_mode="$2"
    local debounce_seconds="$3"

    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  File Watcher Started${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    echo -e "${BLUE}Watch Directory:${NC}  ${watch_dir}"
    echo -e "${BLUE}Test Mode:${NC}        ${test_mode}"
    echo -e "${BLUE}Debounce Time:${NC}    ${debounce_seconds}s"
    echo -e "${BLUE}File Patterns:${NC}    *.cs, *.inputactions\n"

    echo -e "${MAGENTA}${BOLD}Watching for changes... (Press Ctrl+C to stop)${NC}\n"

    # 最後の変更時刻を記録
    local last_change_time=0
    local test_pending=false

    # inotifywaitでファイル変更を監視
    inotifywait -m -r -e modify,create,delete,move \
        --include '.*\.(cs|inputactions)$' \
        "${watch_dir}" 2>/dev/null | \
    while read -r directory event filename; do
        # 変更を検出
        echo -e "${YELLOW}Change detected:${NC} ${directory}${filename} (${event})"

        # 現在時刻を取得
        local current_time
        current_time=$(date +%s)

        # デバウンス処理
        last_change_time=${current_time}
        test_pending=true

        # バックグラウンドでデバウンス待機
        (
            sleep "${debounce_seconds}"

            # 待機後に最新の変更時刻をチェック
            local time_since_last_change=$(($(date +%s) - last_change_time))

            # デバウンス期間中に新しい変更がなければテスト実行
            if [ ${time_since_last_change} -ge ${debounce_seconds} ] && [ "${test_pending}" == "true" ]; then
                test_pending=false
                run_tests "${test_mode}"
            fi
        ) &
    done
}

# シグナルハンドラー（Ctrl+C対応）
cleanup() {
    echo -e "\n\n${YELLOW}Stopping file watcher...${NC}"
    # すべてのバックグラウンドジョブを終了
    jobs -p | xargs -r kill 2>/dev/null || true
    exit 0
}

# メイン処理
main() {
    local watch_dir="${WATCH_DIR}"
    local test_mode="${TEST_MODE}"
    local debounce_seconds="${DEBOUNCE_SECONDS}"

    # 引数をパース
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--dir)
                watch_dir="$2"
                shift 2
                ;;
            -m|--mode)
                test_mode="$2"
                shift 2
                ;;
            -w|--wait)
                debounce_seconds="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo -e "${RED}ERROR: Unknown option: $1${NC}" >&2
                usage
                ;;
        esac
    done

    # テストモードの検証
    if [[ ! "${test_mode}" =~ ^(playmode|editmode|both)$ ]]; then
        echo -e "${RED}ERROR: Invalid test mode: ${test_mode}${NC}" >&2
        echo -e "${YELLOW}Valid modes: playmode, editmode, both${NC}" >&2
        exit 1
    fi

    # 監視ディレクトリの存在確認
    if [ ! -d "${watch_dir}" ]; then
        echo -e "${RED}ERROR: Watch directory not found: ${watch_dir}${NC}" >&2
        exit 1
    fi

    # inotifywaitの存在確認
    check_inotifywait || exit 1

    # シグナルハンドラーを設定
    trap cleanup SIGINT SIGTERM

    # 初回テスト実行
    echo -e "${CYAN}Running initial tests...${NC}\n"
    run_tests "${test_mode}" || true

    # ファイル監視ループ開始
    watch_loop "${watch_dir}" "${test_mode}" "${debounce_seconds}"
}

# スクリプト実行
main "$@"
