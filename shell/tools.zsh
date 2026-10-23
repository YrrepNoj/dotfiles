# Version managers and tool completions, each loaded only when installed.

# Load nvm in non-login interactive terminals too.
_dotfiles_nvm_script="$NVM_DIR/nvm.sh"
if [[ ! -s "$_dotfiles_nvm_script" && -n "$HOMEBREW_PREFIX" ]]; then
  _dotfiles_nvm_script="$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
fi
[[ ! -s "$_dotfiles_nvm_script" ]] || source "$_dotfiles_nvm_script"
unset _dotfiles_nvm_script
# Tab completion for nvm subcommands and installed versions.
[[ ! -s "$NVM_DIR/bash_completion" ]] || source "$NVM_DIR/bash_completion"

if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init - zsh)"
fi

if command -v kubectl >/dev/null 2>&1; then
  source <(kubectl completion zsh)
fi
