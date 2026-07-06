#!/usr/bin/env bash
# sync-to-testserver.sh — Sync the CLI-Tools workspace to a remote macOS dev host.
set -euo pipefail

REMOTE_HOST="${REMOTE_HOST:-testserver}"
REMOTE_ROOT="${REMOTE_ROOT:-/Users/developer/Documents/workspaces/CLI-Tools}"
LOCAL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DRY_RUN=false
WIP_MODE=false
COMMAND=""

usage() {
  cat <<'USAGE'
Usage: scripts/sync-to-testserver.sh <command> [options]

Commands:
  bootstrap   Install remote toolchain and clone CLI-Tools if missing
  status      Compare local and remote branch, commit, and dirty state
  push        Sync local workspace to the remote host
  pull        Sync remote workspace back to local (after remote-first work)

Options:
  --dry-run   Print actions without executing them
  --wip       Push uncommitted working-tree changes via rsync (default: git via origin)
  --help, -h  Show this help

Environment:
  REMOTE_HOST   SSH host alias (default: testserver)
  REMOTE_ROOT   Remote repo path (default: ~/Documents/workspaces/CLI-Tools)

Examples:
  scripts/sync-to-testserver.sh bootstrap
  scripts/sync-to-testserver.sh status
  scripts/sync-to-testserver.sh push
  scripts/sync-to-testserver.sh push --wip
  scripts/sync-to-testserver.sh pull
USAGE
}

log() { printf '==> %s\n' "$*"; }
warn() { printf '!! %s\n' "$*" >&2; }

run() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

ssh_cmd() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run] ssh %s ' "$REMOTE_HOST"
    printf '%q ' "$@"
    printf '\n'
  else
    ssh "$REMOTE_HOST" "$@"
  fi
}

require_ssh() {
  if ! ssh -o BatchMode=yes -o ConnectTimeout=10 "$REMOTE_HOST" 'true' 2>/dev/null; then
    warn "Cannot reach $REMOTE_HOST over SSH"
    exit 1
  fi
}

local_branch() {
  git -C "$LOCAL_ROOT" rev-parse --abbrev-ref HEAD
}

local_head() {
  git -C "$LOCAL_ROOT" rev-parse HEAD
}

local_dirty() {
  if ! git -C "$LOCAL_ROOT" diff --quiet \
    || ! git -C "$LOCAL_ROOT" diff --cached --quiet \
    || [[ -n "$(git -C "$LOCAL_ROOT" ls-files --others --exclude-standard)" ]]; then
    return 0
  fi
  return 1
}

local_ahead_of_origin() {
  git -C "$LOCAL_ROOT" rev-list --count "origin/$(local_branch)..HEAD" 2>/dev/null || echo 0
}

cmd_bootstrap() {
  require_ssh
  log "Bootstrapping $REMOTE_HOST"

  ssh_cmd bash -s "$REMOTE_ROOT" <<'REMOTE_BOOTSTRAP'
set -euo pipefail
REMOTE_ROOT="$1"

if ! grep -q "CLI-Tools remote dev" ~/.zshenv 2>/dev/null; then
  cat >> ~/.zshenv <<'EOF'

# CLI-Tools remote dev (non-interactive SSH)
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)" 2>/dev/null || true
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/.local/bin:$PATH"
EOF
fi

git config --global url."git@github.com:".insteadOf "https://github.com/"

if ! command -v golangci-lint >/dev/null 2>&1; then
  brew install golangci-lint
fi

mkdir -p "$(dirname "$REMOTE_ROOT")"
if [[ ! -d "$REMOTE_ROOT/.git" ]]; then
  git clone --recurse-submodules git@github.com:dl-alexandre/homebrew-tap.git "$REMOTE_ROOT"
fi

go version
golangci-lint version
gh auth status -h github.com 2>&1 | head -3
REMOTE_BOOTSTRAP
}

local_snapshot() {
  if [[ ! -d "$LOCAL_ROOT/.git" ]]; then
    echo "missing"
    return
  fi

  local branch head dirty
  branch="$(git -C "$LOCAL_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo HEAD)"
  head="$(git -C "$LOCAL_ROOT" rev-parse --short=12 HEAD 2>/dev/null || echo none)"
  dirty="clean"
  if local_dirty; then
    dirty="dirty"
  fi
  printf '%s %s %s\n' "$branch" "$head" "$dirty"
}

remote_snapshot() {
  ssh_cmd bash -s "$REMOTE_ROOT" <<'REMOTE_SNAPSHOT'
set -euo pipefail
ROOT="$1"
if [[ ! -d "$ROOT/.git" ]]; then
  echo "missing"
  exit 0
fi
cd "$ROOT"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo HEAD)"
head="$(git rev-parse --short=12 HEAD 2>/dev/null || echo none)"
dirty="clean"
if ! git diff --quiet || ! git diff --cached --quiet || [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
  dirty="dirty"
fi
printf '%s %s %s\n' "$branch" "$head" "$dirty"
REMOTE_SNAPSHOT
}

cmd_status() {
  require_ssh

  local local_info remote_info
  local_info="$(local_snapshot)"
  if [[ "$DRY_RUN" == true ]]; then
    remote_info="(skipped in dry-run)"
  else
    remote_info="$(ssh "$REMOTE_HOST" bash -s "$REMOTE_ROOT" <<'REMOTE_SNAPSHOT'
set -euo pipefail
ROOT="$1"
if [[ ! -d "$ROOT/.git" ]]; then
  echo "missing"
  exit 0
fi
cd "$ROOT"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo HEAD)"
head="$(git rev-parse --short=12 HEAD 2>/dev/null || echo none)"
dirty="clean"
if ! git diff --quiet || ! git diff --cached --quiet || [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
  dirty="dirty"
fi
printf '%s %s %s\n' "$branch" "$head" "$dirty"
REMOTE_SNAPSHOT
)"
  fi

  log "Local  ($LOCAL_ROOT):  $local_info"
  log "Remote ($REMOTE_HOST:$REMOTE_ROOT): $remote_info"

  if [[ "$remote_info" == "missing" ]]; then
    warn "Remote repo not found — run: scripts/sync-to-testserver.sh bootstrap"
    exit 1
  fi

  local local_head remote_head
  local_head="$(awk '{print $2}' <<<"$local_info")"
  remote_head="$(awk '{print $2}' <<<"$remote_info")"
  if [[ "$local_head" == "$remote_head" ]]; then
    log "Commits match"
  else
    warn "Commit drift: local=$local_head remote=$remote_head"
  fi
}

push_git() {
  local branch ahead
  branch="$(local_branch)"
  ahead="$(local_ahead_of_origin)"

  if [[ "$ahead" != "0" ]]; then
    log "Pushing $ahead local commit(s) to origin"
    run git -C "$LOCAL_ROOT" push origin "$branch"
  fi

  log "Updating remote checkout from origin/$branch"
  ssh_cmd bash -s "$REMOTE_ROOT" "$branch" <<'REMOTE_PULL'
set -euo pipefail
ROOT="$1"
BRANCH="$2"
cd "$ROOT"
git fetch origin
git checkout "$BRANCH"
git pull --ff-only origin "$BRANCH"
git submodule sync --recursive
git submodule update --init --recursive
REMOTE_PULL
}

push_wip() {
  log "Syncing working tree to $REMOTE_HOST via rsync"
  local rsync_opts=(-az --delete)
  if [[ "$DRY_RUN" == true ]]; then
    rsync_opts+=(-n)
  fi

  run rsync "${rsync_opts[@]}" \
    --exclude '.git/' \
    --exclude '**/.DS_Store' \
    --exclude '**/coverage.out' \
    --exclude '**/bin/' \
    --exclude '**/dist/' \
    "$LOCAL_ROOT/" "$REMOTE_HOST:$REMOTE_ROOT/"
}

cmd_push() {
  require_ssh

  if [[ "$WIP_MODE" == true ]]; then
    push_wip
    return
  fi

  if local_dirty; then
    warn "Local tree has uncommitted changes"
    warn "Commit and push to origin, or rerun with --wip to rsync working-tree files"
    exit 1
  fi

  push_git
  cmd_status
}

cmd_pull() {
  require_ssh

  if [[ "$WIP_MODE" == true ]]; then
    log "Pulling working tree from $REMOTE_HOST via rsync"
    local rsync_opts=(-az --delete)
    if [[ "$DRY_RUN" == true ]]; then
      rsync_opts+=(-n)
    fi
    run rsync "${rsync_opts[@]}" \
      --exclude '.git/' \
      --exclude '**/.DS_Store' \
      --exclude '**/coverage.out' \
      --exclude '**/bin/' \
      --exclude '**/dist/' \
      "$REMOTE_HOST:$REMOTE_ROOT/" "$LOCAL_ROOT/"
    return
  fi

  local branch
  branch="$(ssh "$REMOTE_HOST" "git -C '$REMOTE_ROOT' rev-parse --abbrev-ref HEAD")"
  log "Fetching remote branch $branch from $REMOTE_HOST"
  run git -C "$LOCAL_ROOT" fetch "$REMOTE_HOST:$REMOTE_ROOT" "$branch"
  run git -C "$LOCAL_ROOT" checkout "$branch"
  run git -C "$LOCAL_ROOT" merge --ff-only FETCH_HEAD
  run git -C "$LOCAL_ROOT" submodule sync --recursive
  run git -C "$LOCAL_ROOT" submodule update --init --recursive
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    bootstrap|status|push|pull) COMMAND="$1"; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --wip) WIP_MODE=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) warn "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

if [[ -z "$COMMAND" ]]; then
  usage
  exit 1
fi

case "$COMMAND" in
  bootstrap) cmd_bootstrap ;;
  status) cmd_status ;;
  push) cmd_push ;;
  pull) cmd_pull ;;
esac