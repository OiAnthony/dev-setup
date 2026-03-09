# 开发环境自动化还原

快速在新 macOS 或 Linux（Ubuntu）机器上还原开发环境。

## 快速开始

### 一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/你的用户名/dev-setup/main/install.sh | bash
```

### 克隆后安装

```bash
git clone https://github.com/你的用户名/dev-setup.git
cd dev-setup
chmod +x install.sh
./install.sh
```

安装完成后运行：

```bash
source ~/.zshrc
```

## 包含的工具

- Git + GitHub CLI
- Node.js
- Python
- Docker + Docker Compose
- 常用 CLI 工具（curl、wget、vim）

## 维护

### 添加新工具

```bash
brew install 新工具名
brew bundle dump --force
git commit -am "Add 新工具名"
git push
```

### 更新配置文件

编辑 `dotfiles/.zshrc`，然后提交：

```bash
git commit -am "Update zshrc"
git push
```

## 项目结构

```
dev-setup/
├── install.sh      # 主安装脚本
├── Brewfile        # 软件清单
├── dotfiles/       # 配置文件
│   └── .zshrc
└── README.md
```

## 注意事项

- 支持 macOS 和 Linux（Ubuntu）
- 使用 Homebrew 统一管理软件包
- 可重复运行 install.sh（幂等性）
- 不要提交敏感信息（SSH 私钥、API token）
