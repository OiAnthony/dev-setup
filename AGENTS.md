# AGENTS.md

## Repo Shape

- `install.sh` is the installer entrypoint. It handles platform split, clones/updates the repo when run outside the repo, creates symlinks, appends one `source ".../dotfiles/dev-setup.zsh"` line to `~/.zshrc`, installs Oh My Zsh, optional plugins, Bun, and pnpm.
- `dotfiles/dev-setup.zsh` is the runtime shell config loaded from `~/.zshrc`. Keep its platform checks and Kaku fallback behavior aligned with `install.sh`.
- `mise.toml` is symlinked to `~/.config/mise/config.toml`, so editing it changes the user's global mise config, not just this repo.
- `scripts/test-install.sh` and `scripts/test-idempotent.sh` are the executable spec for install behavior. If installer behavior changes, update tests in the same change.

## Verified Commands

- `make lint` runs `shellcheck install.sh` and `shellcheck dotfiles/dev-setup.zsh`. The zsh file is advisory-only and may warn on valid zsh syntax.
- `make test`, `make test-kaku`, `make test-idempotent`, and `make test-root` all depend on `make build` and require `docker` or `podman`.
- `make test-all` runs `lint -> test -> test-kaku -> test-idempotent -> test-root`.
- For non-interactive verification of `install.sh`, set `CI=true` or `DEV_SETUP_NO_EXEC=1`; otherwise the script ends with `exec zsh -l`.

## Cross-File Invariants

- Kaku detection is the file check `~/.config/kaku/zsh/kaku.zsh` in both `install.sh` and `dotfiles/dev-setup.zsh`. If that logic changes, update both files and `scripts/test-install.sh`.
- Idempotency is a core requirement: rerunning `install.sh` must be safe and must keep exactly one `dev-setup.zsh` source line in `~/.zshrc`.
- Keep symlink targets stable: `~/.gitconfig` -> `dotfiles/.gitconfig`, `~/.config/starship.toml` -> `dotfiles/starship.toml`, `~/.config/mise/config.toml` -> `mise.toml`.

## Platform Gotchas

- macOS blocks `root` and installs Homebrew itself plus `mise` and fonts. Linux explicitly supports `root` and installs base packages via the system package manager before `mise`.
- In tests, mise-managed tools may not be on bare `PATH`; verify them with `mise which <tool>` like `scripts/test-install.sh` does, not only `command -v`.
- Prefer `aqua:` or `ubi:` entries in `mise.toml`. After editing `mise.toml`, run `mise install`.
- Pinned runtimes in `mise.toml`: Node lts, Go latest, Python 3.14, Java 21, uv latest. Bun and pnpm are installed by `install.sh` via their official scripts, not mise.

## Network Notes

- China mirror detection can be forced with `DEV_SETUP_CHINA_MIRROR=1` or disabled with `DEV_SETUP_CHINA_MIRROR=0`. The detected result is cached in `~/.cache/dev-setup-china-mirror`.
- Even in China mode, `mise` still pulls from GitHub releases. Network-related install failures are often resolved by `https_proxy` or `GITHUB_TOKEN`.

## Writing Conventions

- User-facing docs use Simplified Chinese.
- Code comments use Simplified Chinese.
- Git commit messages use English Conventional Commits.
