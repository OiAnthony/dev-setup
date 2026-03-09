# Path to your Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Oh My Zsh theme
ZSH_THEME="robbyrussell"

# Oh My Zsh plugins
plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions npm node docker python docker-compose)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Homebrew
if [[ -d "/opt/homebrew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# 别名
alias ll='ls -lah'
alias gs='git status'
alias gp='git pull'
alias docker='podman'
alias code='code-insiders'
alias python='python3'
alias pip='pip3'

# fzf
if command -v fzf &> /dev/null; then
  source <(fzf --zsh)
fi

# zoxide
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

# Starship (可选，取消注释以启用)
# if command -v starship &> /dev/null; then
#   eval "$(starship init zsh)"
# fi

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Go bin
if command -v go &> /dev/null; then
  export PATH=$PATH:$(go env GOPATH)/bin
fi

# 实用函数
fzf-cd() {
  local dir
  dir=$(fd --type directory "${1:-.}" | fzf --preview 'ls -la {} | head -20')
  [[ -n $dir ]] && cd "$dir"
}

# 历史记录
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
