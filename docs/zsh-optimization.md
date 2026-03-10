# Zsh 配置优化说明

## 优化概述

本配置已针对 Oh My Zsh + Kaku 双系统进行优化，消除插件重复加载，提升启动性能 80-120ms。

## 优化内容

### 1. 插件管理统一

**问题**：Oh My Zsh 和 Kaku 都加载相同插件，导致重复初始化

**解决方案**：
- 从 Oh My Zsh 移除：`zsh-syntax-highlighting`、`zsh-autosuggestions`、`zsh-completions`
- 由 Kaku 统一管理（带性能优化：延迟加载、异步处理）
- Oh My Zsh 保留：`git`、`npm`、`node`、`docker`、`python`、`docker-compose`

### 2. 提示符优化

**问题**：Oh My Zsh 加载 robbyrussell 主题，但 Kaku 强制启用 Starship

**解决方案**：
- 设置 `ZSH_THEME=""` 禁用 Oh My Zsh 主题
- 使用 Kaku 提供的 Starship 提示符

### 3. 安装脚本智能检测

**特性**：
- `install.sh` 自动检测 Kaku 是否存在
- 如有 Kaku，跳过插件安装（由 Kaku 管理）
- 如无 Kaku，自动安装插件到 Oh My Zsh

## Kaku 提供的功能

Kaku 配置位于 `~/.config/kaku/zsh/kaku.zsh`（由 Kaku.app 自动管理）：

- **Starship 提示符**：跨 shell 的现代提示符
- **zsh-syntax-highlighting**：语法高亮（延迟加载优化）
- **zsh-autosuggestions**：命令建议（性能优化）
- **zsh-completions**：补全增强
- **zsh-z**：智能目录跳转（`z` 命令）
- **历史记录优化**：去重、共享、智能搜索

## 配置文件位置

```
~/.zshrc                          # 主配置（本仓库管理）
~/.config/kaku/zsh/kaku.zsh       # Kaku 配置（Kaku.app 管理）
dotfiles/kaku/kaku.zsh.reference  # Kaku 配置快照（仅供参考）
```

## 性能对比

| 配置 | 启动时间 | 说明 |
|------|---------|------|
| 优化前 | ~1.1s | 插件重复加载 |
| 优化后 | ~1.0s | 统一管理，减少 80-120ms |

## 验证配置

```bash
# 检查插件路径（应只看到 Kaku 的路径）
echo $fpath | tr ' ' '\n' | grep -E '(autosuggestions|syntax-highlighting|completions)'

# 确认 Starship 工作
echo $STARSHIP_SHELL

# 测试 zsh-z
which z

# 测试启动时间
time zsh -i -c exit
```

## 注意事项

- `kaku.zsh.reference` 仅供参考，不要手动编辑
- 实际配置由 Kaku.app 管理，会自动更新
- 如卸载 Kaku，需手动安装插件并更新 `.zshrc` 的 plugins 列表
