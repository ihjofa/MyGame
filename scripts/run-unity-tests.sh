#!/bin/bash
#
# run-unity-tests.sh
# Unity Test Framework のテストをCLIから実行するスクリプト
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
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 設定
UNITY_PROJECT_PATH="${PROJECT_ROOT}/unity/My project"
TEST_RESULTS_DIR="${PROJECT_ROOT}/test-results"
DEFAULT_TIMEOUT=1800  # 30分（秒）

# 使用方法を表示
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Run Unity Test Framework tests from command line"
    echo ""
    echo "Options:"
    echo "  -m, --mode <mode>       Test mode: playmode, editmode, or both (default: both)"
    echo "  -t, --timeout <seconds> Timeout in seconds (default: ${DEFAULT_TIMEOUT})"
    echo "  -v, --verbose           Verbose logging"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Run all tests (PlayMode and EditMode)"
    echo "  $0 -m playmode          # Run PlayMode tests only"
    echo "  $0 -m editmode          # Run EditMode tests only"
    echo "  $0 -t 3600              # Run with 1 hour timeout"
    exit 0
}

# Unity実行ファイルを検出
find_unity_executable() {
    local unity_path

    # find-unity.sh を使用
    if [ -f "${SCRIPT_DIR}/find-unity.sh" ]; then
        unity_path=$("${SCRIPT_DIR}/find-unity.sh" 2>/dev/null) || {
            echo -e "${RED}ERROR: Unity not found${NC}" >&2
            echo -e "${YELLOW}Please install Unity or set UNITY_PATH environment variable${NC}" >&2
            return 1
        }
        echo "${unity_path}"
        return 0
    else
        echo -e "${RED}ERROR: find-unity.sh not found${NC}" >&2
        return 1
    fi
}

# テスト結果ディレクトリを作成
prepare_test_results_dir() {
    mkdir -p "${TEST_RESULTS_DIR}"
}

# 単一モードのテストを実行
run_test_mode() {
    local unity_path="$1"
    local test_mode="$2"
    local timeout="$3"
    local verbose="${4:-false}"

    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)

    local test_results_file="${TEST_RESULTS_DIR}/${test_mode}-results-${timestamp}.xml"
    local log_file="${TEST_RESULTS_DIR}/${test_mode}-log-${timestamp}.txt"

    # Windows版Unity (.exe) の場合、パスをWindows形式に変換
    local project_path="${UNITY_PROJECT_PATH}"
    local results_file="${test_results_file}"
    local log_file_path="${log_file}"

    if [[ "${unity_path}" =~ \.exe$ ]]; then
        echo -e "${YELLOW}Detected Windows Unity, converting paths...${NC}" >&2

        # WSLパスをWindows形式に変換
        if command -v wslpath &> /dev/null; then
            project_path=$(wslpath -w "${UNITY_PROJECT_PATH}")
            results_file=$(wslpath -w "${test_results_file}")
            log_file_path=$(wslpath -w "${log_file}")
        else
            echo -e "${RED}WARNING: wslpath not found, paths may not work correctly${NC}" >&2
        fi
    fi

    echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  Running ${test_mode} Tests${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    echo -e "${BLUE}Unity Path:${NC}      ${unity_path}"
    echo -e "${BLUE}Project Path:${NC}    ${project_path}"
    echo -e "${BLUE}Test Mode:${NC}       ${test_mode}"
    echo -e "${BLUE}Results File:${NC}    ${results_file}"
    echo -e "${BLUE}Log File:${NC}        ${log_file_path}"
    echo -e "${BLUE}Timeout:${NC}         ${timeout}s\n"

    # Unityコマンドを構築
    local unity_args=(
        -batchmode
        -projectPath "${project_path}"
        -runTests
        -testMode "${test_mode}"
        -testResults "${results_file}"
        -logFile "${log_file_path}"
    )

    if [ "${verbose}" == "true" ]; then
        unity_args+=(-loglevel verbose)
    fi

    # テスト実行
    echo -e "${YELLOW}Starting test execution...${NC}\n"

    local start_time
    start_time=$(date +%s)

    local exit_code=0

    # タイムアウト付きでUnityを実行
    if timeout "${timeout}" "${unity_path}" "${unity_args[@]}" > /dev/null 2>&1; then
        exit_code=0
    else
        exit_code=$?
    fi

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # 実行時間を表示
    echo -e "${BLUE}Test execution completed in ${duration}s${NC}\n"

    # 終了コードに応じた処理
    case ${exit_code} in
        0)
            echo -e "${GREEN}${BOLD}✓ All tests passed${NC}\n"
            ;;
        2)
            echo -e "${YELLOW}${BOLD}⚠ Some tests failed${NC}\n"
            ;;
        124)
            echo -e "${RED}${BOLD}✗ Test execution timed out after ${timeout}s${NC}\n"
            return 124
            ;;
        *)
            echo -e "${RED}${BOLD}✗ Test execution error (exit code: ${exit_code})${NC}\n"
            return ${exit_code}
            ;;
    esac

    # 結果ファイルが存在する場合、パース
    if [ -f "${test_results_file}" ]; then
        if [ -f "${SCRIPT_DIR}/parse-test-results.sh" ]; then
            "${SCRIPT_DIR}/parse-test-results.sh" "${test_results_file}" || {
                # パーサーがエラーを返した場合（失敗したテストがある）
                return 1
            }
        else
            echo -e "${YELLOW}Warning: parse-test-results.sh not found${NC}" >&2
        fi
    else
        echo -e "${RED}ERROR: Test results file not created: ${test_results_file}${NC}" >&2
        echo -e "${YELLOW}Check log file for details: ${log_file}${NC}" >&2
        return 1
    fi

    return 0
}

# メイン処理
main() {
    local test_mode="both"
    local timeout="${DEFAULT_TIMEOUT}"
    local verbose=false

    # 引数をパース
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m|--mode)
                test_mode="$2"
                shift 2
                ;;
            -t|--timeout)
                timeout="$2"
                shift 2
                ;;
            -v|--verbose)
                verbose=true
                shift
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

    # Unity実行ファイルを検出
    echo -e "${BLUE}Detecting Unity installation...${NC}"
    local unity_path
    unity_path=$(find_unity_executable) || exit 1

    # Unityバージョンを表示
    echo -e "${GREEN}Unity found!${NC}"
    if [ -f "${SCRIPT_DIR}/find-unity.sh" ]; then
        "${SCRIPT_DIR}/find-unity.sh" --version 2>/dev/null || true
    fi

    # テスト結果ディレクトリを準備
    prepare_test_results_dir

    # プロジェクトパスの存在確認
    if [ ! -d "${UNITY_PROJECT_PATH}" ]; then
        echo -e "${RED}ERROR: Unity project not found: ${UNITY_PROJECT_PATH}${NC}" >&2
        exit 1
    fi

    # テスト実行
    local overall_exit_code=0

    if [ "${test_mode}" == "both" ] || [ "${test_mode}" == "editmode" ]; then
        if ! run_test_mode "${unity_path}" "editmode" "${timeout}" "${verbose}"; then
            overall_exit_code=1
        fi
    fi

    if [ "${test_mode}" == "both" ] || [ "${test_mode}" == "playmode" ]; then
        if ! run_test_mode "${unity_path}" "playmode" "${timeout}" "${verbose}"; then
            overall_exit_code=1
        fi
    fi

    # 最終結果を表示
    echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if [ ${overall_exit_code} -eq 0 ]; then
        echo -e "${GREEN}${BOLD}  ✓ ALL TESTS PASSED${NC}"
    else
        echo -e "${RED}${BOLD}  ✗ SOME TESTS FAILED${NC}"
    fi
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    exit ${overall_exit_code}
}

# スクリプト実行
main "$@"
