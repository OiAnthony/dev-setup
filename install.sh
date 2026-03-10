#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🚀 开始安装开发环境..."

# Homebrew 要求使用非 root 用户安装，提前阻止错误场景
if [[ "$EUID" -eq 0 ]]; then
  echo "❌ 检测到当前正在以 root 用户运行。Homebrew 要求在非 root 用户下安装。"
  echo ""
  echo "请先创建一个普通用户，再切换到该用户后重新运行此脚本。"
  echo ""
  echo "macOS 示例（图形界面）："
  echo "  1. 打开 系统设置 > 用户与群组"
  echo "  2. 点击 添加用户"
  echo "  3. 选择 标准 或 管理员 账户类型"
  echo "  4. 使用新用户登录后执行: ./install.sh"
  echo ""
  echo "macOS 示例（终端）："
  echo "  sudo sysadminctl -addUser <username> -fullName \"<Full Name>\" -password -"
  echo "  sudo dseditgroup -o edit -a <username> -t user admin   # 如需管理员权限"
  echo "  su - <username>"
  echo "  cd \"$(printf '%s' "$SCRIPT_DIR")\" && ./install.sh"
  echo ""
  echo "Linux 示例："
  echo "  sudo adduser <username>"
  echo "  sudo usermod -aG sudo <username>    # 如需 sudo 权限"
  echo "  su - <username>"
  echo "  cd \"$(printf '%s' "$SCRIPT_DIR")\" && ./install.sh"
  exit 1
fi

# 中国大陆镜像加速
_dev_setup_is_china() {
  [[ "$DEV_SETUP_CHINA_MIRROR" == "1" ]] && return 0
  [[ "$DEV_SETUP_CHINA_MIRROR" == "0" ]] && return 1

  local country
  country=$(curl -s --max-time 2 https://ipinfo.io/country 2>/dev/null | tr -d '[:space:]')
  [[ -z "$country" ]] && country=$(curl -s --max-time 2 http://ip-api.com/line/?fields=countryCode 2>/dev/null | tr -d '[:space:]')

  # 同时写入缓存供 dev-setup.zsh 使用
  local cache_file="$HOME/.cache/dev-setup-china-mirror"
  mkdir -p "$(dirname "$cache_file")"
  echo "${country:-UNKNOWN}" > "$cache_file"

  [[ "$country" == "CN" ]] && return 0
  return 1
}

if _dev_setup_is_china; then
  echo "🇨🇳 检测到中国大陆网络，使用 USTC 镜像加速..."
  export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
  export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
  export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
  export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
fi

# 检测并安装 Homebrew
if ! command -v brew &> /dev/null; then
  echo "📦 安装 Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # macOS Apple Silicon 需要添加到 PATH
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  # Linux 需要添加到 PATH
  elif [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
else
  echo "✅ Homebrew 已安装"
fi

# 校验 brew 是否可用，后续流程完全依赖 brew
if ! command -v brew &> /dev/null; then
  echo "❌ Homebrew 安装失败或不在 PATH 中，无法继续安装。"
  echo "请参考 https://brew.sh 手动安装后重新运行此脚本。"
  exit 1
fi

# 安装所有软件
echo "📦 安装软件包..."
if brew bundle check --file="$SCRIPT_DIR/Brewfile" &>/dev/null; then
  echo "✅ 所有 Brewfile 包已安装"
else
  brew bundle --file="$SCRIPT_DIR/Brewfile"
fi

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
  {
    echo ""
    echo "# Dev Setup Environment"
    echo "$DEV_SETUP_SOURCE"
  } >> ~/.zshrc
  echo "✅ 已追加配置到 ~/.zshrc"
elif [[ ! -f ~/.zshrc ]]; then
  echo "$DEV_SETUP_SOURCE" > ~/.zshrc
  echo "✅ 已创建 ~/.zshrc"
else
  echo "✅ ~/.zshrc 已包含 dev-setup 配置"
fi

# 安装 Volta（Node.js 版本管理器）
if [[ ! -d "$HOME/.volta" ]]; then
  echo "📦 安装 Volta..."
  curl https://get.volta.sh | bash
  export VOLTA_HOME="$HOME/.volta"
  export PATH="$VOLTA_HOME/bin:$PATH"
  echo "📦 通过 Volta 安装 Node.js..."
  volta install node
else
  echo "✅ Volta 已安装"
fi

# 安装 Bun
if ! command -v bun &> /dev/null; then
  echo "📦 安装 Bun..."
  curl -fsSL https://bun.sh/install | bash
else
  echo "✅ Bun 已安装"
fi

# 安装 pnpm
if ! command -v pnpm &> /dev/null; then
  echo "📦 安装 pnpm..."
  curl -fsSL https://get.pnpm.io/install.sh | sh -
else
  echo "✅ pnpm 已安装"
fi

# 安装 SDKMAN
if [[ ! -d "$HOME/.sdkman" ]]; then
  echo "📦 安装 SDKMAN..."
  curl -s "https://get.sdkman.io" | bash
else
  echo "✅ SDKMAN 已安装"
fi

echo ""
echo "✨ 安装完成！"
echo ""
echo "📝 后续步骤："
echo "1. 修改 ~/.gitconfig 中的用户名和邮箱"
echo "2. 运行 'source ~/.zshrc' 或重启终端"
echo "3. (可选) 取消注释 ~/.zshrc 中的 Starship 配置以启用自定义提示符"
