#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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
brew bundle --file="$SCRIPT_DIR/Brewfile"

# 安装 Oh My Zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "📦 安装 Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "✅ Oh My Zsh 已安装"
fi

# 安装 Zsh 插件（如果使用 Kaku 则跳过）
if [[ -f "$HOME/.config/kaku/zsh/kaku.zsh" ]]; then
  echo "✅ 检测到 Kaku，跳过插件安装（由 Kaku 管理）"
else
  echo "📦 安装 Zsh 插件..."
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  fi

  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  fi

  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]]; then
    git clone https://github.com/zsh-users/zsh-completions.git "$ZSH_CUSTOM/plugins/zsh-completions"
  fi
fi

# 配置文件
echo "🔗 配置 dotfiles..."
ln -sf "$SCRIPT_DIR/dotfiles/.gitconfig" ~/.gitconfig
mkdir -p ~/.config
ln -sf "$SCRIPT_DIR/dotfiles/starship.toml" ~/.config/starship.toml

# 追加 source 到 ~/.zshrc
DEV_SETUP_SOURCE="source \"$SCRIPT_DIR/dotfiles/dev-setup.zsh\""
if [[ -f ~/.zshrc ]] && ! grep -q "dev-setup.zsh" ~/.zshrc; then
  echo "" >> ~/.zshrc
  echo "# Dev Setup Environment" >> ~/.zshrc
  echo "$DEV_SETUP_SOURCE" >> ~/.zshrc
  echo "✅ 已追加配置到 ~/.zshrc"
elif [[ ! -f ~/.zshrc ]]; then
  echo "$DEV_SETUP_SOURCE" > ~/.zshrc
  echo "✅ 已创建 ~/.zshrc"
else
  echo "✅ ~/.zshrc 已包含 dev-setup 配置"
fi

# 可选工具安装
echo ""
echo "📦 可选工具安装"
read -p "是否安装 Bun (JavaScript 运行时)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  curl -fsSL https://bun.sh/install | bash
fi

read -p "是否安装 pnpm (Node.js 包管理器)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  curl -fsSL https://get.pnpm.io/install.sh | sh -
fi

read -p "是否安装 SDKMAN (Java 版本管理)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  curl -s "https://get.sdkman.io" | bash
fi

echo ""
echo "✨ 安装完成！"
echo ""
echo "📝 后续步骤："
echo "1. 修改 ~/.gitconfig 中的用户名和邮箱"
echo "2. 运行 'source ~/.zshrc' 或重启终端"
echo "3. (可选) 取消注释 ~/.zshrc 中的 Starship 配置以启用自定义提示符"
