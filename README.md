# dotfiles
Collection of configuration files I like to use


This will be bulty up slowly but hopefully steadily.

Might end up heavily incorporating (or simply forking) concepts from https://github.com/holman/dotfiles

Shell configuration supports macOS (Apple Silicon and Intel) and Linux. Link
`~/.zshrc` to `shell/zshrc` and `~/.zprofile` to `shell/zprofile`; keep
`shell/env.zsh` alongside them. Both startup files load the shared environment,
so interactive non-login terminals receive the same tool paths.

Homebrew is detected from PATH or its standard platform locations. Optional
Oh My Zsh plugins, Powerlevel10k, nvm, and pyenv load when installed. Go, pnpm,
and pyenv settings honor existing environment overrides. Project aliases use
`$HOME/projects`; Lima helpers require `limactl` and a local sandbox template
(the path can be set with `AI_SANDBOX_YAML`). The custom Linux llama-swap alias
is available only when its executable exists.

The merge removes the legacy yabai/skhd configuration and the old
`shell/.tmux.conf` and `shell/.p10k.zsh` files. Use `aerospace/aerospace.toml`
for AeroSpace on macOS and `tmux/tmux.conf` for tmux. A separate existing
`~/.p10k.zsh` is still loaded when present.
