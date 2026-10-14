# Shared environment for login and interactive shells on macOS and Linux.
# zsh ties PATH to the path array; keep entries unique when sourced twice.
typeset -U path PATH

# Prefer an available Homebrew installation for this platform.
_dotfiles_brew=""
if (( $+commands[brew] )); then
  _dotfiles_brew=$commands[brew]
else
  case "$OSTYPE" in
    darwin*) _dotfiles_brew_candidates=(/opt/homebrew/bin/brew /usr/local/bin/brew) ;;
    linux*)  _dotfiles_brew_candidates=(/home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew") ;;
    *)       _dotfiles_brew_candidates=() ;;
  esac
  for _dotfiles_candidate in "${_dotfiles_brew_candidates[@]}"; do
    if [[ -x "$_dotfiles_candidate" ]]; then
      _dotfiles_brew=$_dotfiles_candidate
      break
    fi
  done
fi
if [[ -n "$_dotfiles_brew" ]]; then
  eval "$("$_dotfiles_brew" shellenv)"
fi
unset _dotfiles_brew _dotfiles_brew_candidates _dotfiles_candidate

export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
export GOPATH="${GOPATH:-$HOME/go}"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
case "$OSTYPE" in
  darwin*) export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}" ;;
  *)       export PNPM_HOME="${PNPM_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/pnpm}" ;;
esac

# Include standalone Go installations and optional user tools only if present.
for _dotfiles_bin in /usr/local/go/bin "$PYENV_ROOT/bin" "$PYENV_ROOT/shims" \
  "$GOPATH/bin" "${GOBIN:-$GOPATH/bin}" "$HOME/.opencode/bin" \
  "$PNPM_HOME" "$PNPM_HOME/bin" "$HOME/.local/bin"; do
  [[ ! -d "$_dotfiles_bin" ]] || path=("$_dotfiles_bin" "${path[@]}")
done
unset _dotfiles_bin

# Postgres CLI (keg-only libpq) and macOS user-site Python scripts, if present.
[[ -z "$HOMEBREW_PREFIX" || ! -d "$HOMEBREW_PREFIX/opt/libpq/bin" ]] || path=("$HOMEBREW_PREFIX/opt/libpq/bin" "${path[@]}")
[[ "$OSTYPE" != darwin* || ! -d "$HOME/Library/Python/3.9/bin" ]] || path+=("$HOME/Library/Python/3.9/bin")

if [[ -f "$HOME/.local/bin/env" ]]; then
  source "$HOME/.local/bin/env"
fi
[[ ! -n "$TTY" ]] || export GPG_TTY="$TTY"
export PATH
