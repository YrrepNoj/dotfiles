# oh-my-zsh and the prompt theme. oh-my-zsh runs compinit, so load this before
# any module that registers completions.

# Path to your oh-my-zsh installation.
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#
# Prompt selection, in order of preference:
#   1. Powerlevel10k, when installed as an oh-my-zsh custom theme.
#   2. oh-my-posh, when the binary is installed. It uses the config tracked in
#      this repo (ohmyposh/), so every machine gets the same prompt without a
#      copy in ~/.config. oh-my-posh draws the prompt itself, so ZSH_THEME is
#      left empty to keep oh-my-zsh from setting one; it starts further down,
#      after oh-my-zsh has loaded.
#   3. robbyrussell, oh-my-zsh's default, so a machine with neither installed
#      still has a usable prompt.
#
# ${(%):-%N} is the path of this file. :A resolves any symlink to the repo copy,
# and :h:h climbs from shell/prompt.zsh up to the repo root.
_dotfiles_omp_config="${${(%):-%N}:A:h:h}/ohmyposh/powerlevel10k_lean.omp.json"
ZSH_THEME=""
if [[ -f "${ZSH_CUSTOM:-$ZSH/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
  ZSH_THEME="powerlevel10k/powerlevel10k"
elif ! command -v oh-my-posh >/dev/null 2>&1 || [[ ! -f "$_dotfiles_omp_config" ]]; then
  ZSH_THEME="robbyrussell"
fi
# An empty ZSH_THEME at this point means option 2, oh-my-posh.

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)
for _dotfiles_plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  if [[ -d "${ZSH_CUSTOM:-$ZSH/custom}/plugins/$_dotfiles_plugin" || -d "$ZSH/plugins/$_dotfiles_plugin" ]]; then
    plugins+=("$_dotfiles_plugin")
  fi
done
unset _dotfiles_plugin

# User configuration
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit
  compinit
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Start oh-my-posh when the prompt selection near the top picked it (empty
# ZSH_THEME). It runs after oh-my-zsh and ~/.p10k.zsh so nothing replaces its prompt.
if [[ -z "$ZSH_THEME" ]]; then
  eval "$(oh-my-posh init zsh --config "$_dotfiles_omp_config")"
fi
unset _dotfiles_omp_config
