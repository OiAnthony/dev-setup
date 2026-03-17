# ============================================================================
# Dev Setup - 统一的开发环境配置
# ============================================================================
# 使用方式: 在 ~/.zshrc 中添加: source /path/to/dev-setup/dotfiles/dev-setup.zsh

# =========== 基础环境 ===========

export PATH=$HOME/.local/bin:$PATH
export EDITOR=nvim

# =========== Shell 框架 ===========

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git npm node docker python docker-compose)
source $ZSH/oh-my-zsh.sh

# =========== Homebrew ===========

# 中国大陆镜像加速（通过 DEV_SETUP_CHINA_MIRROR=1/0 覆盖，或自动网络探测）
_dev_setup_is_china() {
  [[ "$DEV_SETUP_CHINA_MIRROR" == "1" ]] && return 0
  [[ "$DEV_SETUP_CHINA_MIRROR" == "0" ]] && return 1

  local cache_file="$HOME/.cache/dev-setup-china-mirror"
  if [[ -f "$cache_file" ]] && [[ -z $(find "$cache_file" -mtime +1 2>/dev/null) ]]; then
    [[ "$(cat "$cache_file")" == "CN" ]] && return 0 || return 1
  fi

  local country
  country=$(curl -s --max-time 2 https://ipinfo.io/country 2>/dev/null | tr -d '[:space:]')
  [[ -z "$country" ]] && country=$(curl -s --max-time 2 http://ip-api.com/line/?fields=countryCode 2>/dev/null | tr -d '[:space:]')

  mkdir -p "$(dirname "$cache_file")"
  echo "${country:-UNKNOWN}" > "$cache_file"
  [[ "$country" == "CN" ]] && return 0
  return 1
}

if _dev_setup_is_china; then
  export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
  export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
  export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
  export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
fi

# 初始化 Homebrew 环境（兼容 macOS 和 Linux）
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# =========== 别名 ===========

# 使用 Zsh 内置 hash 表检测（更快）
(( $+commands[podman] )) && alias docker="podman"
(( $+commands[code-insiders] )) && alias code="code-insiders"
(( $+commands[lazygit] )) && alias lg="lazygit"
alias python="python3"
alias pip="pip3"
alias cc="claude"
alias oc="opencode"

# =========== CLI 工具 ===========

# 清理所有缓存文件的辅助函数
dev-setup-clear-cache() {
  rm -f ~/.fzf.zsh ~/.zoxide.zsh ~/.starship.zsh
  echo "✓ 缓存已清理,请重新加载 shell: source ~/.zshrc"
}

# fzf - 使用缓存文件避免每次执行进程替换（1天自动刷新）
if command -v fzf &> /dev/null; then
  if [[ ! -f ~/.fzf.zsh ]] || [[ -n $(find ~/.fzf.zsh -mtime +1 2>/dev/null) ]]; then
    fzf --zsh > ~/.fzf.zsh
  fi
  source ~/.fzf.zsh
fi

fzf-cd() {
  local dir
  dir=$(fd --type directory "${1:-.}" | fzf --preview 'ls -la {} | head -20')
  [[ -n $dir ]] && cd "$dir"
}

# zoxide - 使用缓存文件避免每次 eval（1天自动刷新）
if command -v zoxide &> /dev/null; then
  if [[ ! -f ~/.zoxide.zsh ]] || [[ -n $(find ~/.zoxide.zsh -mtime +1 2>/dev/null) ]]; then
    zoxide init zsh > ~/.zoxide.zsh
  fi
  source ~/.zoxide.zsh
fi

# yazi（支持 cd 跟随）
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# thefuck - 懒加载（仅在首次使用时初始化）
fuck() {
  unfunction fuck
  eval $(thefuck --alias)
  fuck "$@"
}

# =========== 包管理器 ===========

# Volta - Node.js 版本管理器
export VOLTA_HOME="${VOLTA_HOME:-$HOME/.volta}"
export PATH="$VOLTA_HOME/bin:$PATH"

# pnpm - 优先使用环境变量，fallback 到默认路径
export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"
typeset -U PATH path
path=($PNPM_HOME $path)
export PATH

# bun - 优先使用环境变量，fallback 到默认路径，跳过补全脚本
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
export PATH="$BUN_INSTALL/bin:$PATH"

# SDKMAN - 懒加载（仅在首次使用 sdk 命令时初始化）
export SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"
sdk() {
  unfunction sdk
  [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
  sdk "$@"
}

# =========== 开发环境 ===========

# Go - 优先使用 GOPATH 环境变量，fallback 到默认路径
if command -v go &> /dev/null; then
  export PATH=$PATH:${GOPATH:-$HOME/go}/bin
fi

# Android SDK（完整 Android 开发环境才需要）
# export ANDROID_HOME=$HOME/Library/Android/sdk
# export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
# export PATH=$PATH:$ANDROID_HOME/platform-tools
# export PATH=$PATH:$ANDROID_HOME/build-tools/36.1.0

# OpenCode
export OPENCODE_EXPERIMENTAL_MARKDOWN=1
export OPENCODE_EXPERIMENTAL_LSP_TY=1
export OPENCODE_EXPERIMENTAL_LSP_TOOL=1

# =========== Kaku 集成（或 Fallback） ===========

if [[ -f "$HOME/.config/kaku/zsh/kaku.zsh" ]]; then
  source "$HOME/.config/kaku/zsh/kaku.zsh"
else
  # Starship - 使用缓存文件避免每次 eval（1天自动刷新）
  if (( $+commands[starship] )); then
    if [[ ! -f ~/.starship.zsh ]] || [[ -n $(find ~/.starship.zsh -mtime +1 2>/dev/null) ]]; then
      starship init zsh > ~/.starship.zsh
    fi
    source ~/.starship.zsh
  fi

  export CLICOLOR=1
  export LSCOLORS="Gxfxcxdxbxegedabagacad"

  HISTSIZE=50000
  SAVEHIST=50000
  HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
  setopt HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS HIST_REDUCE_BLANKS HIST_IGNORE_SPACE
  setopt SHARE_HISTORY APPEND_HISTORY INC_APPEND_HISTORY EXTENDED_HISTORY
  setopt interactive_comments auto_cd auto_pushd pushd_ignore_dups pushdminus
  bindkey -e

  alias ll='ls -lhF'
  alias la='ls -lAhF'
  alias l='ls -CF'
  alias ...='../..'
  alias ....='../../..'
  alias .....='../../../..'
  alias ......='../../../../..'
  alias md='mkdir -p'
  alias rd=rmdir
  alias grep='grep --color=auto'
  alias egrep='grep -E --color=auto'
  alias fgrep='grep -F --color=auto'
  alias g='git'
  alias ga='git add'
  alias gaa='git add --all'
  alias gb='git branch'
  alias gbd='git branch -d'
  alias gc='git commit -v'
  alias gcmsg='git commit -m'
  alias gco='git checkout'
  alias gcb='git checkout -b'
  alias gd='git diff'
  alias gds='git diff --staged'
  alias gf='git fetch'
  alias gl='git pull'
  alias gp='git push'
  alias gst='git status'
  alias gss='git status -s'
  alias glo='git log --oneline --decorate'
  alias glg='git log --stat'
  alias glgp='git log --stat -p'

  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  [[ -d "$ZSH_CUSTOM/plugins/zsh-completions/src" ]] && fpath=("$ZSH_CUSTOM/plugins/zsh-completions/src" $fpath)

  autoload -Uz compinit
  [[ -n "${ZDOTDIR:-$HOME}/.zcompdump"(#qN.mh+24) ]] && compinit || compinit -C

  [[ -f "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
    source "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

  if [[ -f "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    export ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)
    source "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  fi
fi
