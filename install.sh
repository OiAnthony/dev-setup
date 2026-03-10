#!/bin/bash
set -e

CURRENT_OS="$(uname -s)"
SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"

echo "🚀 开始安装开发环境..."

# 检测 SCRIPT_DIR 是否为目标仓库（包含 Brewfile 和 dotfiles）
# 覆盖 curl | bash、cat install.sh | bash、bash install.sh 等场景
if [[ ! -f "$SCRIPT_DIR/Brewfile" ]] || [[ ! -d "$SCRIPT_DIR/dotfiles" ]]; then
  echo "📥 检测到脚本不在仓库目录中，正在克隆仓库..."
  REPO_URL="https://github.com/OiAnthony/dev-setup.git"
  INSTALL_DIR="$HOME/.dev-setup"

  if [[ -d "$INSTALL_DIR/.git" ]]; then
    echo "✅ 仓库已存在，更新到最新版本..."
    cd "$INSTALL_DIR"

    # 验证是否为目标仓库（兼容 HTTPS 和 SSH remote）
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
    if [[ "$REMOTE_URL" =~ (https://github\.com/|git@github\.com:)OiAnthony/dev-setup(\.git)?$ ]]; then
      git pull origin main
    else
      echo "⚠️  $INSTALL_DIR 不是目标仓库，跳过更新"
      echo "   当前 remote: $REMOTE_URL"
      echo "   预期 remote: https://github.com/OiAnthony/dev-setup.git 或 git@github.com:OiAnthony/dev-setup.git"
      exit 1
    fi
  else
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
  fi

  # 重新执行脚本（此时 SCRIPT_DIR 指向仓库目录）
  exec bash "$INSTALL_DIR/install.sh"
fi

# Homebrew 要求使用非 root 用户安装，提前阻止错误场景
if [[ "$EUID" -eq 0 ]]; then
  echo "❌ 检测到当前正在以 root 用户运行。Homebrew 要求在非 root 用户下安装。"
  echo ""
  echo "请先创建一个普通用户，再切换到该用户后重新运行此脚本。"
  echo ""
  if [[ "$CURRENT_OS" == "Darwin" ]]; then
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
  elif [[ "$CURRENT_OS" == "Linux" ]]; then
    echo "Linux 示例："
    echo "  sudo adduser <username>"
    echo "  sudo usermod -aG sudo <username>    # 如需 sudo 权限"
    echo "  su - <username>"
    echo "  cd \"$(printf '%s' "$SCRIPT_DIR")\" && ./install.sh"
  else
    echo "当前系统: $CURRENT_OS"
    echo "请创建一个普通用户并切换后，再回到当前目录执行:"
    echo "  cd \"$(printf '%s' "$SCRIPT_DIR")\" && ./install.sh"
  fi
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

  # 在非交互式环境下，Homebrew 安装需要提前获取 sudo 权限
  if [[ ! -t 0 ]]; then
    echo "⚠️  检测到非交互式环境（stdin 不是 TTY）"
    echo "Homebrew 安装需要 sudo 权限，请先运行以下命令获取权限："
    echo ""
    echo "  sudo -v"
    echo ""
    echo "然后重新运行此脚本，或者使用以下命令一次性完成："
    echo ""
    echo "  sudo -v && ./install.sh"
    echo ""
    exit 1
  fi

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
