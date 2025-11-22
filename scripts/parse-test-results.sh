#!/bin/bash
#
# parse-test-results.sh
# Unity Test Framework のXML結果を解析して表示するスクリプト
#

set -euo pipefail

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 使用方法を表示
usage() {
    echo "Usage: $0 <test-results.xml>"
    echo ""
    echo "Parse Unity Test Framework NUnit XML results and display summary"
    exit 1
}

# XMLファイルから値を抽出
extract_xml_value() {
    local xml_file="$1"
    local xpath="$2"

    # grep + sed でシンプルに抽出
    grep -oP "${xpath}" "${xml_file}" 2>/dev/null || echo "0"
}

# テスト結果サマリーを表示
display_summary() {
    local xml_file="$1"

    echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  Test Results Summary${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    # XML から統計情報を抽出
    local total passed failed skipped errors

    total=$(extract_xml_value "${xml_file}" 'total="\K[0-9]+' | head -1)
    passed=$(extract_xml_value "${xml_file}" 'passed="\K[0-9]+' | head -1)
    failed=$(extract_xml_value "${xml_file}" 'failed="\K[0-9]+' | head -1)
    skipped=$(extract_xml_value "${xml_file}" 'skipped="\K[0-9]+' | head -1)

    # エラーがある場合
    errors=$(grep -c 'result="Failed"' "${xml_file}" 2>/dev/null || echo "0")

    # デフォルト値設定
    total=${total:-0}
    passed=${passed:-0}
    failed=${failed:-0}
    skipped=${skipped:-0}

    # サマリー表示
    echo -e "  ${BOLD}Total Tests:${NC}    ${total}"
    echo -e "  ${GREEN}${BOLD}✓ Passed:${NC}       ${GREEN}${passed}${NC}"

    if [ "${failed}" -gt 0 ]; then
        echo -e "  ${RED}${BOLD}✗ Failed:${NC}       ${RED}${failed}${NC}"
    else
        echo -e "  ${GREEN}${BOLD}✗ Failed:${NC}       ${GREEN}${failed}${NC}"
    fi

    if [ "${skipped}" -gt 0 ]; then
        echo -e "  ${YELLOW}${BOLD}○ Skipped:${NC}      ${YELLOW}${skipped}${NC}"
    fi

    echo ""

    # 成功率を計算
    if [ "${total}" -gt 0 ]; then
        local success_rate
        success_rate=$(awk "BEGIN {printf \"%.1f\", (${passed}/${total})*100}")

        if [ "${failed}" -eq 0 ]; then
            echo -e "  ${GREEN}${BOLD}Success Rate: ${success_rate}%${NC}"
        else
            echo -e "  ${YELLOW}${BOLD}Success Rate: ${success_rate}%${NC}"
        fi
    fi

    echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# 失敗したテストの詳細を表示
display_failures() {
    local xml_file="$1"

    # 失敗したテストがあるかチェック
    if ! grep -q 'result="Failed"' "${xml_file}" 2>/dev/null; then
        return 0
    fi

    echo -e "${RED}${BOLD}Failed Tests:${NC}\n"

    # XMLから失敗したテストを抽出
    local in_failed_test=0
    local test_name=""
    local failure_message=""
    local stack_trace=""
    local line_num=0

    while IFS= read -r line; do
        # 失敗したテストケースの開始を検出
        if echo "${line}" | grep -q 'result="Failed"'; then
            in_failed_test=1
            test_name=$(echo "${line}" | grep -oP 'fullname="\K[^"]+' || echo "Unknown Test")
            failure_message=""
            stack_trace=""
        fi

        # 失敗メッセージを抽出
        if [ ${in_failed_test} -eq 1 ]; then
            if echo "${line}" | grep -q '<message>'; then
                failure_message=$(echo "${line}" | sed 's/<message><!\[CDATA\[//; s/\]\]><\/message>//' | sed 's/<message>//; s/<\/message>//')
            fi

            # スタックトレースを抽出
            if echo "${line}" | grep -q '<stack-trace>'; then
                stack_trace=$(echo "${line}" | sed 's/<stack-trace><!\[CDATA\[//; s/\]\]><\/stack-trace>//' | sed 's/<stack-trace>//; s/<\/stack-trace>//')
            fi

            # テストケースの終了を検出
            if echo "${line}" | grep -q '</test-case>'; then
                in_failed_test=0

                # 失敗したテストの詳細を表示
                echo -e "${RED}✗${NC} ${BOLD}${test_name}${NC}"

                if [ -n "${failure_message}" ]; then
                    echo -e "  ${YELLOW}Message:${NC}"
                    echo -e "  ${failure_message}" | fold -w 80 -s | sed 's/^/    /'
                fi

                if [ -n "${stack_trace}" ]; then
                    echo -e "  ${BLUE}Stack Trace:${NC}"
                    echo -e "  ${stack_trace}" | fold -w 80 -s | sed 's/^/    /'
                fi

                echo ""
            fi
        fi
    done < "${xml_file}"
}

# メイン処理
main() {
    # 引数チェック
    if [ $# -eq 0 ]; then
        usage
    fi

    local xml_file="$1"

    # ファイル存在チェック
    if [ ! -f "${xml_file}" ]; then
        echo -e "${RED}ERROR: File not found: ${xml_file}${NC}" >&2
        exit 1
    fi

    # XMLファイルが空でないかチェック
    if [ ! -s "${xml_file}" ]; then
        echo -e "${RED}ERROR: File is empty: ${xml_file}${NC}" >&2
        exit 1
    fi

    # サマリーを表示
    display_summary "${xml_file}"

    # 失敗したテストの詳細を表示
    display_failures "${xml_file}"

    # 終了コードを設定（失敗があれば1）
    local failed
    failed=$(extract_xml_value "${xml_file}" 'failed="\K[0-9]+' | head -1)
    failed=${failed:-0}

    if [ "${failed}" -gt 0 ]; then
        exit 1
    fi

    exit 0
}

# スクリプト実行
main "$@"
