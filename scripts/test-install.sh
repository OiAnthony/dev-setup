#!/usr/bin/env bash
set -euo pipefail

# 集成测试脚本：验证 install.sh 在干净环境下的安装结果
# 同时覆盖：
#   - macOS 路径（Homebrew + Brewfile） — 实际只在 mac runner 上执行
#   - Linux 普通用户路径（apt + mise）
#   - Linux root 路径（apt + mise）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }

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

# 通过 mise 检测工具是否可用（mise 安装的工具不一定在裸 PATH 中，需要 mise which）
check_via_mise() {
    local tool=$1
    if mise which "$tool" >/dev/null 2>&1; then
        log_info "✓ mise provides: $tool"
        return 0
    else
        log_error "✗ mise does NOT provide: $tool"
        return 1
    fi
}

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

main() {
    local with_kaku=false
    if [[ "${1:-}" == "--with-kaku" ]]; then
        with_kaku=true
        log_info "Running with Kaku simulation"
    fi

    if [[ "$with_kaku" == true ]]; then
        log_info "Creating Kaku simulation..."
        mkdir -p "$HOME/.config/kaku/zsh"
        echo "# Mock Kaku config" > "$HOME/.config/kaku/zsh/kaku.zsh"
    fi

    log_info "Running install.sh..."
    cd "$PROJECT_ROOT"
    export CI=true

    if ! ./install.sh; then
        log_error "install.sh failed"
        exit 1
    fi

    # install.sh 把 mise 装到 ~/.local/bin/mise，但 export 在子进程中失效
    export PATH="$HOME/.local/bin:$PATH"

    log_info "Verifying installation results..."
    local failed=0
    local os
    os="$(uname -s)"

    if [[ "$os" == "Darwin" ]]; then
        # macOS: Homebrew 包应直接在 PATH 中
        log_info "Checking Homebrew packages (macOS)..."
        for cmd in git gh node python3 go starship fzf fd rg jq nvim zoxide tree lazygit; do
            check_command "$cmd" || ((failed++))
        done
    else
        # Linux: 基础工具来自 apt，开发 CLI 来自 mise（不一定在裸 PATH）
        log_info "Checking apt-installed base tools (Linux)..."
        for cmd in git curl wget vim zsh zip unzip tree htop jq; do
            check_command "$cmd" || ((failed++))
        done

        log_info "Checking mise binary..."
        check_command mise || ((failed++))

        log_info "Checking mise-managed tools..."
        # 仅检查关键工具；其余非关键工具（btop/yazi）在低速网络下可能未装完
        for tool in starship fzf zoxide fd rg gh lazygit delta nvim node go python uv; do
            check_via_mise "$tool" || ((failed++))
        done

        log_info "Checking mise config symlink..."
        check_symlink "$HOME/.config/mise/config.toml" "$PROJECT_ROOT/mise.toml" || ((failed++))
    fi

    log_info "Checking Oh My Zsh..."
    check_directory "$HOME/.oh-my-zsh" || ((failed++))

    log_info "Checking Zsh plugins..."
    if [[ "$with_kaku" == true ]]; then
        if [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]; then
            log_error "✗ Plugin should NOT be installed (Kaku detected)"
            ((failed++))
        else
            log_info "✓ Plugins correctly skipped (Kaku detected)"
        fi
    else
        check_directory "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" || ((failed++))
        check_directory "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" || ((failed++))
        check_directory "$HOME/.oh-my-zsh/custom/plugins/zsh-completions" || ((failed++))
    fi

    log_info "Checking dotfile symlinks..."
    check_symlink "$HOME/.gitconfig" "$PROJECT_ROOT/dotfiles/.gitconfig" || ((failed++))
    check_symlink "$HOME/.config/starship.toml" "$PROJECT_ROOT/dotfiles/starship.toml" || ((failed++))

    log_info "Checking .zshrc..."
    check_file "$HOME/.zshrc" || ((failed++))
    check_file_contains "$HOME/.zshrc" "source.*dev-setup.zsh" || ((failed++))

    log_info "Checking optional tools..."
    if [[ -d "$HOME/.bun" ]]; then
        log_info "✓ Bun installed"
    else
        log_warn "⚠ Bun not installed (optional)"
    fi

    if [[ "$os" == "Darwin" ]] && [[ -d "$HOME/.sdkman" ]]; then
        log_info "✓ SDKMAN installed (macOS)"
    fi

    if command -v pnpm >/dev/null 2>&1; then
        log_info "✓ pnpm installed"
    else
        log_warn "⚠ pnpm not installed (optional)"
    fi

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
