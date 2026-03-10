# ============================================================================
# Dev Setup - 统一的开发环境配置
# ============================================================================
# 使用方式: 在 ~/.zshrc 中添加: source /path/to/dev-setup/dotfiles/dev-setup.zsh

# PATH 配置
export PATH=$HOME/.local/bin:$PATH

# Oh My Zsh 配置
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git npm node docker python docker-compose)
source $ZSH/oh-my-zsh.sh

# 别名
alias docker="podman"
alias code="code-insiders"
alias python="python3"
alias pip="pip3"
alias oc="opencode"

# fzf
source <(fzf --zsh)

# zoxide
eval "$(zoxide init zsh)"

# yazi
export EDITOR=nvim
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# pnpm
export PNPM_HOME="/Users/anthony/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# bun
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Windsurf
export PATH="$HOME/.codeium/windsurf/bin:$PATH"

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# fzf-cd 函数
fzf-cd() {
  local dir
  dir=$(fd --type directory "${1:-.}" | fzf --preview 'ls -la {} | head -20')
  [[ -n $dir ]] && cd "$dir"
}

# Android SDK
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/build-tools/36.1.0

# thefuck
eval $(thefuck --alias)

# Go
export PATH=$PATH:$(go env GOPATH)/bin

# OpenCode
export OPENCODE_EXPERIMENTAL_MARKDOWN=1
export OPENCODE_EXPERIMENTAL_LSP_TY=1
export OPENCODE_EXPERIMENTAL_LSP_TOOL=1

# Kaku Shell Integration
if [[ -f "$HOME/.config/kaku/zsh/kaku.zsh" ]]; then
  source "$HOME/.config/kaku/zsh/kaku.zsh"
else
  command -v starship &> /dev/null && eval "$(starship init zsh)"

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
