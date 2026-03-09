#!/bin/bash
set -e

echo "🚀 开始安装开发环境..."

# 检测并安装 Homebrew
if ! command -v brew &> /dev/null; then
  echo "📦 安装 Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Linux 需要添加到 PATH
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
else
  echo "✅ Homebrew 已安装"
fi

# 安装所有软件
echo "📦 安装软件包..."
brew bundle --file="$(dirname "$0")/Brewfile"

# 软链接配置文件
echo "🔗 配置 dotfiles..."
ln -sf "$(pwd)/dotfiles/.zshrc" ~/.zshrc

echo "✨ 安装完成！请运行 'source ~/.zshrc' 或重启终端"
