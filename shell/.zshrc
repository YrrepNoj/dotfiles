# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your oh-my-zsh installation.
export ZSH="/Users/jon/.oh-my-zsh"


# Go 1.18

export PATH="$PATH:/usr/local/go/bin"

## GIT ##
# ~/.oh-my-zsh/plugins/git/git.plugin.zsh

# Set name of the theme to load 
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="mm/dd/yyyy"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh


source <(kubectl completion zsh)

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

# Misc. Dev aliases & funcs
grepGoFiles(){
    if [ "$#" -ne 2 ]; then
        GREPPATH="."
    else
        GREPPATH="$2"
    fi
    grep -rnsiI "$1" --include="*.go" "$GREPPATH"
}

grepYamlFiles(){
    if [ "$#" -ne 2 ]; then
        GREPPATH="."
    else
        GREPPATH="$2"
    fi
    grep -rnsiI "$1" --include="*.yaml" "$GREPPATH"
}

grepGoAndYamlFiles(){
    if [ "$#" -ne 2 ]; then
        GREPPATH="."
    else
        GREPPATH="$2"
    fi
    grep -rnsiI "$1" --include="*.go" --include="*.yaml" "$GREPPATH"
}

grepMarkdownFiles(){
    if [ "$#" -ne 2 ]; then
        GREPPATH="."
    else
        GREPPATH="$2"
    fi
    grep -rnsiI "$1" --include="*.md" --include="*.mdx" "$GREPPATH"
}

grepHistory(){
    history | grep "$1"
}

alias proj="cd /Users/jon/projects"
alias cdzarf="cd /Users/jon/projects/du/zarf/zarf"
alias bb="cd /Users/jon/projects/du/bigbang"
alias scratch="cd /Users/jon/projects/scratch"

alias gg=grepGoFiles
alias gy=grepYamlFiles
alias ggy=grepGoAndYamlFiles
alias gm=grepMarkdownFiles
alias gh=grepHistory
alias hg=grepHistory

alias kdc="kind delete cluster && kind create cluster"

# kubectl aliases
alias k=kubectl
#compdef __start_kubectl k     # supposed to be for auto-complete but doesn't seem necessary
alias kgpa="kubectl get pods -A"
alias kgp="kubectl get pods"
alias kge="kubectl get events"
alias kghr="kubectl get hr"
alias kgs="kubectl get services"

watchEvents() {
  watch -n 0.5 "kubectl get events -n $1 --sort-by='.metadata.creationTimestamp' | tail -32"
}
alias kwe=watchEvents


fluxSync(){
   flux suspend hr "$@";   sleep 5;  flux resume hr "$@"
}
alias kfs=fluxSync

# Stuff for Golang
export GOPATH=/Users/jon/go
export GOBIN=/Users/jon/go/bin
export PATH=$PATH:$GOBIN


# GPG signing for git
export GPG_TTY=$(tty)

# NVM
export NVM_DIR=$HOME/.nvm
[ -s "/usr/local/opt/nvm/nvm.sh" ] && \. "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# Zarf Helpers
export PATH="$PATH:/Users/jon/projects/du/zarf/zarf/build"
alias zarf=zarf-mac-intel
alias build-zarf="cdzarf && make build-cli-mac-intel && cd -"
alias build-zarf-init="cdzarf && make init-package && cd -"
alias build-zarf-all="cdzarf && make build-cli-mac-intel init-package && cd -"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
# __conda_setup="$('/Users/jon/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
# if [ $? -eq 0 ]; then
#     eval "$__conda_setup"
# else
#     if [ -f "/Users/jon/opt/anaconda3/etc/profile.d/conda.sh" ]; then
#         . "/Users/jon/opt/anaconda3/etc/profile.d/conda.sh"
#     else
#         export PATH="/Users/jon/opt/anaconda3/bin:$PATH"
#     fi
# fi
# unset __conda_setup
# <<< conda initialize <<<

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
