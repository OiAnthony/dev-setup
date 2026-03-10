#!/usr/bin/env bash
set -euo pipefail

# 集成测试脚本：验证 install.sh 在干净环境下的安装结果

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

# 检查命令是否存在
check_command() {
    local cmd=$1
    if command -v "$cmd" >/dev/null 2>&1; then
        log_info "✓ $cmd is installed"
        return 0
    else
        log_error "✗ $cmd is NOT installed"
        return 1
    fi
}

# 检查目录是否存在
check_directory() {
    local dir=$1
    if [[ -d "$dir" ]]; then
        log_info "✓ Directory exists: $dir"
        return 0
    else
        log_error "✗ Directory NOT found: $dir"
        return 1
    fi
}

# 检查文件是否存在
check_file() {
    local file=$1
    if [[ -f "$file" ]]; then
        log_info "✓ File exists: $file"
        return 0
    else
        log_error "✗ File NOT found: $file"
        return 1
    fi
}

# 检查软链接
check_symlink() {
    local link=$1
    local target=$2
    if [[ -L "$link" ]]; then
        local actual_target
        actual_target=$(readlink "$link")
        if [[ "$actual_target" == "$target" ]]; then
            log_info "✓ Symlink correct: $link -> $target"
            return 0
        else
            log_error "✗ Symlink target mismatch: $link -> $actual_target (expected: $target)"
            return 1
        fi
    else
        log_error "✗ Not a symlink: $link"
        return 1
    fi
}

# 检查文件内容包含指定字符串
check_file_contains() {
    local file=$1
    local pattern=$2
    if grep -q "$pattern" "$file" 2>/dev/null; then
        log_info "✓ File contains pattern: $file"
        return 0
    else
        log_error "✗ File does NOT contain pattern: $file"
        return 1
    fi
}

# 主测试流程
main() {
    local with_kaku=false

    # 解析参数
    if [[ "${1:-}" == "--with-kaku" ]]; then
        with_kaku=true
        log_info "Running with Kaku simulation"
    fi

    # 如果是 Kaku 测试，创建模拟文件
    if [[ "$with_kaku" == true ]]; then
        log_info "Creating Kaku simulation..."
        mkdir -p "$HOME/.config/kaku/zsh"
        echo "# Mock Kaku config" > "$HOME/.config/kaku/zsh/kaku.zsh"
    fi

    # 运行 install.sh
    log_info "Running install.sh..."
    cd "$PROJECT_ROOT"

    # 设置非交互模式（跳过可选工具提示）
    export CI=true

    if ! ./install.sh; then
        log_error "install.sh failed"
        exit 1
    fi

    log_info "Verifying installation results..."
    local failed=0

    # 1. 验证 Homebrew 包
    log_info "Checking Homebrew packages..."
    for cmd in git gh node python3 go starship fzf fd rg jq nvim zoxide tree; do
        check_command "$cmd" || ((failed++))
    done

    # 2. 验证 Oh My Zsh
    log_info "Checking Oh My Zsh..."
    check_directory "$HOME/.oh-my-zsh" || ((failed++))

    # 3. 验证 Zsh 插件（根据 Kaku 状态）
    log_info "Checking Zsh plugins..."
    if [[ "$with_kaku" == true ]]; then
        # Kaku 路径：插件应该被跳过
        if [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]; then
            log_error "✗ Plugin should NOT be installed (Kaku detected)"
            ((failed++))
        else
            log_info "✓ Plugins correctly skipped (Kaku detected)"
        fi
    else
        # 非 Kaku 路径：插件应该被安装
        check_directory "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" || ((failed++))
        check_directory "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" || ((failed++))
        check_directory "$HOME/.oh-my-zsh/custom/plugins/zsh-completions" || ((failed++))
    fi

    # 4. 验证软链接
    log_info "Checking symlinks..."
    check_symlink "$HOME/.gitconfig" "$PROJECT_ROOT/dotfiles/.gitconfig" || ((failed++))
    check_symlink "$HOME/.config/starship.toml" "$PROJECT_ROOT/dotfiles/starship.toml" || ((failed++))

    # 5. 验证 .zshrc 配置
    log_info "Checking .zshrc..."
    check_file "$HOME/.zshrc" || ((failed++))
    check_file_contains "$HOME/.zshrc" "source.*dev-setup.zsh" || ((failed++))

    # 6. 验证额外工具（容忍失败）
    log_info "Checking optional tools..."
    if [[ -d "$HOME/.bun" ]]; then
        log_info "✓ Bun installed"
    else
        log_warn "⚠ Bun not installed (optional)"
    fi

    if [[ -d "$HOME/.sdkman" ]]; then
        log_info "✓ SDKMAN installed"
    else
        log_warn "⚠ SDKMAN not installed (optional)"
    fi

    if command -v pnpm >/dev/null 2>&1; then
        log_info "✓ pnpm installed"
    else
        log_warn "⚠ pnpm not installed (optional)"
    fi

    # 总结
    echo ""
    if [[ $failed -eq 0 ]]; then
        log_info "========================================="
        log_info "All tests passed! ✓"
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


