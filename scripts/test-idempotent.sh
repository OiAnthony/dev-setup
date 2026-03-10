#!/usr/bin/env bash
set -euo pipefail

# 幂等性测试脚本：验证 install.sh 可以安全重复运行

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

main() {
    cd "$PROJECT_ROOT"

    # 设置非交互模式
    export CI=true

    log_info "Running install.sh first time..."
    if ! ./install.sh; then
        log_error "First run failed"
        exit 1
    fi

    log_info "Recording state after first run..."
    local gitconfig_md5
    local starship_md5
    local zshrc_lines
    local source_count

    gitconfig_md5=$(md5sum "$HOME/.gitconfig" | awk '{print $1}')
    starship_md5=$(md5sum "$HOME/.config/starship.toml" | awk '{print $1}')
    zshrc_lines=$(wc -l < "$HOME/.zshrc")
    source_count=$(grep -c "source.*dev-setup.zsh" "$HOME/.zshrc" || true)

    log_info "State recorded:"
    log_info "  .gitconfig md5: $gitconfig_md5"
    log_info "  starship.toml md5: $starship_md5"
    log_info "  .zshrc lines: $zshrc_lines"
    log_info "  source count: $source_count"

    log_info "Running install.sh second time..."
    if ! ./install.sh; then
        log_error "Second run failed"
        exit 1
    fi

    log_info "Verifying state after second run..."
    local failed=0

    # 验证软链接未改变
    local gitconfig_md5_after
    local starship_md5_after

    gitconfig_md5_after=$(md5sum "$HOME/.gitconfig" | awk '{print $1}')
    starship_md5_after=$(md5sum "$HOME/.config/starship.toml" | awk '{print $1}')

    if [[ "$gitconfig_md5" == "$gitconfig_md5_after" ]]; then
        log_info "✓ .gitconfig unchanged"
    else
        log_error "✗ .gitconfig changed"
        ((failed++))
    fi

    if [[ "$starship_md5" == "$starship_md5_after" ]]; then
        log_info "✓ starship.toml unchanged"
    else
        log_error "✗ starship.toml changed"
        ((failed++))
    fi

    # 验证 .zshrc 中 source 行只出现一次
    local source_count_after
    source_count_after=$(grep -c "source.*dev-setup.zsh" "$HOME/.zshrc" || true)

    if [[ "$source_count_after" -eq 1 ]]; then
        log_info "✓ .zshrc source line appears exactly once"
    else
        log_error "✗ .zshrc source line appears $source_count_after times (expected: 1)"
        ((failed++))
    fi

    # 总结
    echo ""
    if [[ $failed -eq 0 ]]; then
        log_info "========================================="
        log_info "Idempotent test passed! ✓"
        log_info "========================================="
        exit 0
    else
        log_error "========================================="
        log_error "$failed test(s) failed ✗"
        log_error "========================================="
        exit 1
    fi
}

main "$@"
