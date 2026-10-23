# Lima AI sandbox helpers (ai-sandbox-bake, ai-sandbox-clone, ai-sandbox).
# They live next to the VM template in the work-automtaion repo, so this only
# sources them, and only on machines that have limactl and that checkout.
export AI_SANDBOX_YAML="${AI_SANDBOX_YAML:-$HOME/projects/ellecon/work-automtaion/lima/ai-sandbox.yaml}"
_dotfiles_lima_helpers="${AI_SANDBOX_YAML:h}/example.zshrc"
if (( $+commands[limactl] )) && [[ -r "$_dotfiles_lima_helpers" ]]; then
  source "$_dotfiles_lima_helpers"
fi
unset _dotfiles_lima_helpers
