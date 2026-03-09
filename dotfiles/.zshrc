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

# 历史记录
HISTSIZE=10000
SAVEHIST=10000
