#!/bin/bash
set -e

CURRENT_OS="$(uname -s)"
SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"

echo "🚀 开始安装开发环境..."

# 检测 SCRIPT_DIR 是否为目标仓库（包含 mise.toml 和 dotfiles）
# 覆盖 curl | bash、cat install.sh | bash、bash install.sh 等场景
if [[ ! -f "$SCRIPT_DIR/mise.toml" ]] || [[ ! -d "$SCRIPT_DIR/dotfiles" ]]; then
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

# macOS 上 Homebrew 要求非 root 用户；Linux 路径走 mise，root 也支持
if [[ "$CURRENT_OS" == "Darwin" ]] && [[ "$EUID" -eq 0 ]]; then
  echo "❌ macOS 下检测到 root 用户。Homebrew 要求在非 root 用户下安装。"
  echo ""
  echo "请先创建一个普通用户，再切换到该用户后重新运行此脚本："
  echo "  sudo sysadminctl -addUser <username> -fullName \"<Full Name>\" -password -"
  echo "  sudo dseditgroup -o edit -a <username> -t user admin   # 如需管理员权限"
  echo "  su - <username>"
  echo "  cd \"$(printf '%s' "$SCRIPT_DIR")\" && ./install.sh"
  exit 1
fi

# ---------------------------------------------------------------------------
# 中国大陆镜像加速（macOS 下的 Homebrew 镜像与 Linux 下的 mise 代理提示共用）
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# 安装 mise 并应用工具清单（macOS / Linux 共用）
# ---------------------------------------------------------------------------
_install_mise() {
  if ! command -v mise &>/dev/null; then
    echo "📦 安装 mise..."
    curl -fsSL https://mise.run | sh
  else
    echo "✅ mise 已安装"
  fi

  export PATH="$HOME/.local/bin:$PATH"

  if ! command -v mise &>/dev/null; then
    echo "❌ mise 安装失败或不在 PATH ($HOME/.local/bin) 中，无法继续。"
    exit 1
  fi

  mkdir -p "$HOME/.config/mise"
  ln -sf "$SCRIPT_DIR/mise.toml" "$HOME/.config/mise/config.toml"

  echo "📦 通过 mise 安装工具链（首次需下载，可能耗时较久）..."
  mise install || {
    echo "⚠️  mise install 部分失败，常见原因：网络受限、GitHub release 限流。"
    echo "   可设置 https_proxy 或 GITHUB_TOKEN 后重新运行。"
  }
}

# ---------------------------------------------------------------------------
# macOS 字体安装（脚本下载 GitHub release 替代 cask）
# ---------------------------------------------------------------------------
_install_fonts_macos() {
  local font_dir="$HOME/Library/Fonts"
  mkdir -p "$font_dir"

  if ! ls "$font_dir"/MapleMono-NF-CN-*.ttf >/dev/null 2>&1; then
    echo "📦 下载 Maple Mono NF CN..."
    local tmp; tmp=$(mktemp -d)
    if curl -fsSL -o "$tmp/maple.zip" \
        "https://github.com/subframe7536/maple-font/releases/latest/download/MapleMono-NF-CN.zip"; then
      unzip -q -o "$tmp/maple.zip" -d "$font_dir"
      echo "✅ Maple Mono NF CN 已安装"
    else
      echo "⚠️  Maple Mono 下载失败，跳过"
    fi
    rm -rf "$tmp"
  else
    echo "✅ Maple Mono NF CN 已存在"
  fi

  if ! ls "$font_dir"/JetBrainsMonoNerdFont-*.ttf >/dev/null 2>&1; then
    echo "📦 下载 JetBrains Mono Nerd Font..."
    local tmp; tmp=$(mktemp -d)
    if curl -fsSL -o "$tmp/jb.zip" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"; then
      unzip -q -o "$tmp/jb.zip" -d "$font_dir"
      echo "✅ JetBrains Mono Nerd Font 已安装"
    else
      echo "⚠️  JetBrains Mono 下载失败，跳过"
    fi
    rm -rf "$tmp"
  else
    echo "✅ JetBrains Mono Nerd Font 已存在"
  fi
}

# ---------------------------------------------------------------------------
# Linux 下使用系统包管理器安装基础工具
# ---------------------------------------------------------------------------
_install_base_linux() {
  local pkgs=(git curl wget vim zsh zip unzip tree htop jq build-essential ca-certificates)
  local sudo_cmd=""
  [[ "$EUID" -ne 0 ]] && sudo_cmd="sudo"

  if command -v apt-get &>/dev/null; then
    echo "📦 使用 apt-get 安装基础工具..."
    $sudo_cmd apt-get update -y
    $sudo_cmd apt-get install -y "${pkgs[@]}"
  elif command -v dnf &>/dev/null; then
    echo "📦 使用 dnf 安装基础工具..."
    # dnf 用 @development-tools 替代 build-essential
    $sudo_cmd dnf install -y git curl wget vim zsh zip unzip tree htop jq ca-certificates
    $sudo_cmd dnf groupinstall -y "Development Tools" || true
  elif command -v yum &>/dev/null; then
    echo "📦 使用 yum 安装基础工具..."
    $sudo_cmd yum install -y git curl wget vim zsh zip unzip tree htop jq ca-certificates
    $sudo_cmd yum groupinstall -y "Development Tools" || true
  elif command -v pacman &>/dev/null; then
    echo "📦 使用 pacman 安装基础工具..."
    $sudo_cmd pacman -Sy --noconfirm git curl wget vim zsh zip unzip tree htop jq base-devel ca-certificates
  elif command -v apk &>/dev/null; then
    echo "📦 使用 apk 安装基础工具..."
    $sudo_cmd apk add --no-cache git curl wget vim zsh zip unzip tree htop jq build-base ca-certificates
  else
    echo "❌ 未识别的 Linux 发行版包管理器。"
    echo "   请手动安装: ${pkgs[*]}，然后重新运行此脚本。"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# 配置默认 Shell 为 Zsh（确认 zsh 已安装后执行）
# ---------------------------------------------------------------------------
_configure_default_shell() {
  local current_shell
  current_shell="$(basename "$SHELL")"
  if [[ "$current_shell" == "zsh" ]]; then
    echo "✅ Zsh 已是默认 Shell"
    return 0
  fi

  local zsh_path
  zsh_path="$(command -v zsh)"
  if [[ -z "$zsh_path" ]]; then
    echo "⚠️  未找到 zsh，跳过默认 shell 切换"
    return 0
  fi

  local sudo_cmd=""
  [[ "$EUID" -ne 0 ]] && sudo_cmd="sudo"

  # 确保 zsh 路径在 /etc/shells 中
  if [[ -f /etc/shells ]] && ! grep -qxF "$zsh_path" /etc/shells; then
    echo "📝 将 $zsh_path 添加到 /etc/shells..."
    echo "$zsh_path" | $sudo_cmd tee -a /etc/shells >/dev/null
  fi

  # chsh 在容器/某些 root 环境下可能失败（如 PAM 限制），退化为修改 /etc/passwd
  if chsh -s "$zsh_path" 2>/dev/null; then
    echo "✅ 默认 Shell 已切换为 $zsh_path（下次登录生效）"
  elif [[ "$EUID" -eq 0 ]] && command -v usermod &>/dev/null; then
    usermod -s "$zsh_path" "$(id -un)" && \
      echo "✅ 默认 Shell 已切换为 $zsh_path（通过 usermod，下次登录生效）"
  else
    echo "⚠️  无法切换默认 Shell，请手动执行: chsh -s $zsh_path"
  fi
}

# ===========================================================================
# 平台分流：macOS → Homebrew 本体 + mise + 字体；Linux（含 root）→ apt + mise
# ===========================================================================

if [[ "$CURRENT_OS" == "Darwin" ]]; then
  # -------------------------------------------------------------------------
  # macOS 路径：保留 Homebrew 本体（用户日常 brew install），工具链交给 mise
  # -------------------------------------------------------------------------

  _configure_default_shell

  if _dev_setup_is_china; then
    echo "🇨🇳 检测到中国大陆网络，使用 USTC 镜像加速 Homebrew..."
    export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
    export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
    export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
    export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
  fi

  if ! command -v brew &> /dev/null; then
    echo "📦 安装 Homebrew（仅本体，工具链由 mise 管理）..."

    # 在非交互式环境下（如 curl | bash），stdin 被管道占用
    # 需要通过 /dev/tty 获取 sudo 权限
    if [[ ! -t 0 ]]; then
      echo "⚠️  检测到非交互式环境，尝试通过终端获取 sudo 权限..."
      if [[ -e /dev/tty ]]; then
        sudo -v < /dev/tty
      elif sudo -n true 2>/dev/null; then
        echo "✅ 已有 sudo 权限"
      else
        echo "❌ 无法获取 sudo 权限（无终端且无免密 sudo）"
        echo "请先运行: sudo -v && curl -fsSL https://raw.githubusercontent.com/OiAnthony/dev-setup/main/install.sh | bash"
        exit 1
      fi
    fi

    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # macOS Apple Silicon 需要添加到 PATH
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  else
    echo "✅ Homebrew 已安装"
  fi

  # 中国大陆网络下 mise 仍走 GitHub release
  if _dev_setup_is_china; then
    if [[ -z "${https_proxy:-}${HTTPS_PROXY:-}" ]] && [[ -z "${GITHUB_TOKEN:-}" ]]; then
      echo "   ⚠️  mise 通过 GitHub release 拉取二进制，建议设置 https_proxy 或 GITHUB_TOKEN 加速。"
      echo "   示例: export https_proxy=http://127.0.0.1:7890"
    fi
  fi

  _install_mise
  _install_fonts_macos

elif [[ "$CURRENT_OS" == "Linux" ]]; then
  # -------------------------------------------------------------------------
  # Linux 路径（含 root）：apt/dnf/apk + mise
  # -------------------------------------------------------------------------

  _install_base_linux
  _configure_default_shell

  # 中国大陆网络提示（mise 无官方镜像，依赖 https_proxy / GITHUB_TOKEN）
  if _dev_setup_is_china; then
    echo "🇨🇳 检测到中国大陆网络。"
    if [[ -z "${https_proxy:-}${HTTPS_PROXY:-}" ]] && [[ -z "${GITHUB_TOKEN:-}" ]]; then
      echo "   ⚠️  mise 通过 GitHub release 拉取二进制，建议设置 https_proxy 或 GITHUB_TOKEN 加速。"
      echo "   示例: export https_proxy=http://127.0.0.1:7890"
    fi
  fi

  _install_mise

else
  echo "❌ 不支持的操作系统: $CURRENT_OS"
  exit 1
fi

# ===========================================================================
# 共用步骤：Oh My Zsh、dotfiles、Bun、pnpm
# ===========================================================================

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

# 配置文件软链接
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

# Bun（双平台）
if ! command -v bun &> /dev/null; then
  echo "📦 安装 Bun..."
  curl -fsSL https://bun.sh/install | bash
else
  echo "✅ Bun 已安装"
fi

# pnpm（双平台）
if ! command -v pnpm &> /dev/null; then
  echo "📦 安装 pnpm..."
  curl -fsSL https://get.pnpm.io/install.sh | sh -
else
  echo "✅ pnpm 已安装"
fi

echo ""
echo "✨ 安装完成！"
echo ""
echo "📝 后续步骤："
echo "1. 修改 ~/.gitconfig 中的用户名和邮箱"
if [[ "$CURRENT_OS" == "Linux" ]]; then
  echo "2. 通过 mise 管理工具版本: mise ls / mise use node@22"
fi
echo ""

# 自动激活新环境（CI 环境下跳过，避免吞掉后续测试）
if [[ "${CI:-}" == "true" ]] || [[ "${DEV_SETUP_NO_EXEC:-}" == "1" ]]; then
  echo "ℹ️  CI/non-interactive mode detected, skipping shell exec."
  exit 0
fi

echo "🔄 正在激活新环境..."
echo "   (如需返回原 shell，请运行 'exit')"
echo ""
sleep 1
exec zsh -l
