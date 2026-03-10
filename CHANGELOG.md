# 更新日志

## 2026-03-10

### 重大改进

- **模块化配置**：改用 `dev-setup.zsh` 通过 `source` 加载，不再覆盖 `~/.zshrc`
- **智能 Kaku 集成**：自动检测 Kaku 并跳过插件安装，避免重复加载
- **性能优化**：启动速度提升 80-120ms（详见 `docs/zsh-optimization.md`）

### 配置文件变更

- 删除 `dotfiles/.zshrc`（改为 `dev-setup.zsh`）
- 新增 `dotfiles/dev-setup.zsh`（统一环境配置）
- 更新 `install.sh`（追加模式 + Kaku 检测）
- 简化 `starship.toml`（移除 nodejs/lua 禁用配置）

### 文档更新

- 更新 `README.md`（反映实际项目结构）
- 新增 `docs/zsh-optimization.md`（性能优化说明）
- 新增别名表格和特性列表

### 工具清单

- 新增 `uv`（Python 包管理器）
- 注释 `podman`（可选安装）
