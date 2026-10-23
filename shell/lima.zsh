# Lima AI sandbox helpers: bake the golden image, clone it per project, run
# baton against a clone. Defined only where limactl is installed. The template
# itself (ai-sandbox.yaml) lives in the work-automtaion repo.
(( $+commands[limactl] )) || return 0

export AI_SANDBOX_YAML="${AI_SANDBOX_YAML:-$HOME/projects/ellecon/work-automtaion/lima/ai-sandbox.yaml}"
export AI_SANDBOX_BASE="${AI_SANDBOX_BASE:-ai-sandbox-base}"

# Bake the golden image once. --mount-none suppresses the inherited ~ mount
# from template:docker-rootful so $HOME is never exposed and nothing host-path
# pollutes the clones. Stops it after so clones copy a cold, consistent disk.
#
# Auth step: after provisioning completes, the function pauses so you can
# authenticate Claude Code via OAuth (uses your Claude.ai subscription, not
# API-key billing). In a second terminal:
#   limactl shell ai-sandbox-base
#   claude auth login   # follow the browser prompt
#   codex login --device-auth   # enter the code shown at the printed URL
#   exit
# Then return here and press Enter to stop and seal the image.
ai-sandbox-bake() {
  local env_file="$(dirname "$AI_SANDBOX_YAML")/.env"
  if [[ ! -f "$env_file" ]]; then
    echo "ai-sandbox-bake: .env not found at $env_file" >&2
    return 1
  fi
  source "$env_file"
  if [[ -z "${CLAUDE_CODE_NOTIFY_URL:-}" ]]; then
    echo "ai-sandbox-bake: CLAUDE_CODE_NOTIFY_URL not set in $env_file" >&2
    return 1
  fi
  limactl start --name "$AI_SANDBOX_BASE" --mount-none \
    --param "CLAUDE_CODE_NOTIFY_URL=$CLAUDE_CODE_NOTIFY_URL" \
    "$AI_SANDBOX_YAML" || return 1

  echo ""
  echo "Provisioning complete. Authenticate Claude Code and Codex before sealing the image:"
  echo "  limactl shell $AI_SANDBOX_BASE"
  echo "  claude auth login"
  echo "  codex login --device-auth"
  echo "  exit"
  echo ""
  read "?Press Enter when both are authenticated to stop and seal the golden image..."

  limactl stop "$AI_SANDBOX_BASE" \
    && echo "Golden image '$AI_SANDBOX_BASE' baked and stopped."
}

# Clone the golden image for the current dir. Instance name defaults to the
# basename of $PWD (override with an arg). Mount is introduced ONLY here.
# TTYD binds to TTYD_HOST_IP from .env (optional), defaulting to 127.0.0.1.
# Fails fast if an instance with that name already exists.
ai-sandbox-clone() {
  local name="${1:-$(basename "$PWD")}"
  local env_file="$(dirname "$AI_SANDBOX_YAML")/.env"
  local port bind_ip
  port=$(_ai_sandbox_free_port)
  # Read in a subshell so sourcing .env doesn't leak its values into this shell.
  bind_ip=$([[ -f "$env_file" ]] && source "$env_file"; echo "${TTYD_HOST_IP:-}")
  bind_ip="${bind_ip:-127.0.0.1}"
  if limactl list -q | grep -qx "$name"; then
    echo "ai-sandbox-clone: instance '$name' already exists." >&2
    echo "  Reuse it:  limactl shell $name" >&2
    echo "  Or remove: limactl delete -f $name" >&2
    return 1
  fi
  limactl clone --mount-only "$PWD:w" --start \
    --set ".portForwards[0].hostPort = $port | .portForwards[0].hostIP = \"$bind_ip\"" \
    "$AI_SANDBOX_BASE" "$name" \
    && echo "Cloned '$name' with $PWD mounted writable. TTYD: http://$bind_ip:$port"
}

# Convenience: clone (or reuse) for $PWD, then drop into a shell.
ai-sandbox() {
  local name="${1:-$(basename "$PWD")}"
  limactl list -q | grep -qx "$name" || ai-sandbox-clone "$name" || return 1

  limactl shell "$name"
}

# Run baton on the host with Codex in this repo's clone (created if missing):
# baton's git, gh and UI stay on the Mac, the agent's commands and edits run
# in the VM. Args go to baton, e.g. `ai-sandbox-baton ENG-2481.md`.
ai-sandbox-baton() {
  local common root name
  # The main checkout, even from a subdirectory or a worktree inside it.
  common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) \
    || { echo "ai-sandbox-baton: not in a git repo" >&2; return 1; }
  root=$(dirname "$common")
  name=$(basename "$root")
  if ! limactl list -q | grep -qx "$name"; then
    (cd "$root" && ai-sandbox-clone "$name") || return 1
  fi
  AI_SANDBOX_VM="$name" baton --codex "$(dirname "$AI_SANDBOX_YAML")/bin/codex-in-vm" "$@"
}

# Find the first TCP port >= 9001 not currently bound on the host.
_ai_sandbox_free_port() {
  local port=9001
  while lsof -iTCP:$port -sTCP:LISTEN -t &>/dev/null; do
    (( port++ ))
  done
  echo $port
}
