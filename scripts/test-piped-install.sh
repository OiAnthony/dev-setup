#!/usr/bin/env bash
set -euo pipefail

# 回归测试：覆盖 curl | bash -> exec 本地 install.sh -> exec zsh -l 的 stdin 继承问题。

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

main() {
    local tmpdir=""

    if ! command -v zsh >/dev/null 2>&1; then
        log_info "Installing zsh for regression test..."
        sudo apt-get update -y >/dev/null
        sudo apt-get install -y zsh >/dev/null
    fi

    tmpdir=$(mktemp -d)
    trap 'tmpdir="${tmpdir-}"; [[ -n "$tmpdir" ]] && rm -rf "$tmpdir"' EXIT

    local home_dir="$tmpdir/home"
    mkdir -p "$home_dir"
    printf '%s\n' 'print -r -- "__ZSH_STARTED__"' > "$home_dir/.zprofile"

    local residue_script="$tmpdir/residue.zsh"
    printf '%s\n' 'print -r -- "__PIPE_RESIDUE__"' > "$residue_script"

    local child_unsafe="$tmpdir/child-unsafe.sh"
    printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' 'exec zsh -l' > "$child_unsafe"
    chmod +x "$child_unsafe"

    local child_safe="$tmpdir/child-safe.sh"
    printf '%s\n' \
        '#!/usr/bin/env bash' \
        'set -euo pipefail' \
        'if [[ -t 0 ]]; then' \
        '  exec zsh -l' \
        'elif exec 3</dev/tty 2>/dev/null; then' \
        '  exec 3<&-' \
        '  exec zsh -l < /dev/tty' \
        'else' \
        '  printf "%s\\n" "__NO_TTY__"' \
        '  exit 1' \
        'fi' > "$child_safe"
    chmod +x "$child_safe"

    local piped_unsafe="$tmpdir/piped-unsafe.sh"
    printf '#!/usr/bin/env bash\nset -euo pipefail\nexec bash %q\n' "$child_unsafe" > "$piped_unsafe"

    local piped_safe="$tmpdir/piped-safe.sh"
    printf '#!/usr/bin/env bash\nset -euo pipefail\nexec bash %q\n' "$child_safe" > "$piped_safe"

    local runner_unsafe="$tmpdir/run-unsafe.sh"
    printf '#!/usr/bin/env bash\nset -euo pipefail\ncat %q %q | bash\n' "$piped_unsafe" "$residue_script" > "$runner_unsafe"
    chmod +x "$runner_unsafe"

    local runner_safe="$tmpdir/run-safe.sh"
    printf '#!/usr/bin/env bash\nset -euo pipefail\ncat %q %q | bash\n' "$piped_safe" "$residue_script" > "$runner_safe"
    chmod +x "$runner_safe"

    log_info "Reproducing the old piped stdin bug..."
    local unsafe_output
    unsafe_output=$(HOME="$home_dir" "$runner_unsafe" 2>&1)

    [[ "$unsafe_output" == *"__ZSH_STARTED__"* ]] || {
        log_error "unsafe case did not start zsh"
        exit 1
    }

    [[ "$unsafe_output" == *"__PIPE_RESIDUE__"* ]] || {
        log_error "unsafe case did not consume piped residue"
        exit 1
    }

    log_info "Verifying the fixed stdin handoff..."
    local safe_output
    safe_output=$(HOME="$home_dir" "$runner_safe" 2>&1 || true)

    [[ "$safe_output" == *"__NO_TTY__"* ]] || {
        log_error "safe case did not skip shell activation without tty"
        exit 1
    }

    [[ "$safe_output" != *"__PIPE_RESIDUE__"* ]] || {
        log_error "safe case still consumed piped residue"
        exit 1
    }

    log_info "Piped stdin regression test passed! ✓"
}

main "$@"
