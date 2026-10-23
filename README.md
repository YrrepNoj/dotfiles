# dotfiles
Collection of configuration files I like to use


This will be bulty up slowly but hopefully steadily.

Might end up heavily incorporating (or simply forking) concepts from https://github.com/holman/dotfiles

Shell configuration supports macOS (Apple Silicon and Intel) and Linux. Link
`~/.zshrc` to `shell/zshrc` and `~/.zprofile` to `shell/zprofile`, or source
them from your own files. Both startup files load the shared environment
(`shell/env.zsh`), so interactive non-login terminals receive the same tool paths.

`shell/zshrc` is a small loader for these modules:

| Module | Contents |
| --- | --- |
| `prompt.zsh` | oh-my-zsh (with compinit) and the prompt theme. Load before the others. |
| `tools.zsh` | nvm, pyenv, kubectl completion. |
| `aliases.zsh` | Kubernetes, Docker, notification, terminal and editor helpers. |
| `git.zsh` | `gtree` and the `gwt*` worktree commands with completion. |
| `lima.zsh` | Sources the Lima AI sandbox helpers from the work-automtaion repo when `limactl` is installed. |

The Lima AI sandbox VM clones this repo to `~/.dotfiles` and sources
`shell/zshrc` from its own `~/.zshrc`.

Homebrew is detected from PATH or its standard platform locations. Optional
Oh My Zsh plugins, Powerlevel10k, nvm, and pyenv load when installed. Without
Powerlevel10k, the prompt uses oh-my-posh with `ohmyposh/powerlevel10k_lean.omp.json`
when `oh-my-posh` is installed, and falls back to `robbyrussell` otherwise. Go, pnpm,
and pyenv settings honor existing environment overrides. Lima helpers require `limactl` and the work-automtaion checkout (the template
path can be set with `AI_SANDBOX_YAML`). The custom Linux llama-swap alias
is available only when its executable exists.

`codex/config.toml` holds the portable Codex CLI settings (model, personality,
reasoning effort, status line). Machine-specific entries such as project trust,
plugins and MCP servers stay out of it; Codex writes those to the live
`~/.codex/config.toml` itself.

The merge removes the legacy yabai/skhd configuration and the old
`shell/.tmux.conf` and `shell/.p10k.zsh` files. Use `aerospace/aerospace.toml`
for AeroSpace on macOS and `tmux/tmux.conf` for tmux. A separate existing
`~/.p10k.zsh` is still loaded when present.
