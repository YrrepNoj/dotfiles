# Aliases and small helpers. Machine-specific ones are defined only where they work.

### Kubernetes
alias k='kubectl'
alias kgpa='kubectl get pods -A'
alias kgpu="kubectl describe nodes  |  tr -d '\000' | sed -n -e '/^Name/,/Roles/p' -e '/^Capacity/,/Allocatable/p' -e '/^Allocated resources/,/Events/p'  | grep -e Name  -e  nvidia.com  | perl -pe 's/\n//'  |  perl -pe 's/Name:/\n/g' | sed 's/nvidia.com\/gpu:\?//g'  | sed '1s/^/Node Available(GPUs)  Used(GPUs)/' | sed 's/$/ 0 0 0/'  | awk '{print \$1, \$2, \$3}'  | column -t"

watchEvents() {
  watch -n 0.5 "kubectl get events -n $1 --sort-by='.metadata.creationTimestamp' | tail -32"
}
alias kwe=watchEvents

### Docker
alias dka='docker ps -aq | xargs docker stop | xargs docker rm'

### Notifications
alias notify='echo -en "\007"'
alias notify3='notify && sleep 1 && notify && sleep 1 && notify'
alias notify6='notify3 && notify3'

### Machine-specific
# Wakes the "thrawn" machine over the network, sending to both of its MAC addresses.
# Only defined where wakeonlan is installed.
if command -v wakeonlan >/dev/null 2>&1; then
  alias wakethrawn="wakeonlan 08:bf:b8:76:cb:97 && wakeonlan 08:bf:b8:76:cb:96"
fi

# This custom build is Linux-specific; expose it only when installed.
if [[ "$OSTYPE" == linux* && -x "$HOME/projects/purgatory/llama-swap/build/llama-swap-linux-amd64" ]]; then
  alias lllama-swap='"$HOME/projects/purgatory/llama-swap/build/llama-swap-linux-amd64"'
fi

### Terminal and editor
alias vim=nvim

ttt() {
  if [ $# -eq 0 ]; then
    tmux ls
  else
    if [ -n "$TMUX" ]; then
      # This is a nested session to unset the TMUX var and change the styling to make it obvious that it's nested
      TMUX= tmux new-session -A -s "$1" \; set status-style "bg=green" \; set status-fg black
    else
      tmux new-session -A -s "$1"
    fi
  fi
}

dog() {
  # If any argument is -l, enable line numbers
  if [[ " $* " == *" -l "* ]]; then
    # Remove -l from args and run with line numbers
    local args=()
    for arg in "$@"; do
      [[ "$arg" != "-l" ]] && args+=("$arg")
    done
    pygmentize -g -O linenos=1 "${args[@]}"
  else
    pygmentize -g "$@"
  fi
}
