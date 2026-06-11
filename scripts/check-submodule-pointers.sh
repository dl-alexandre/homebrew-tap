#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="check"

if [[ "${1:-}" == "--update" ]]; then
  MODE="update"
elif [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'USAGE'
Usage: scripts/check-submodule-pointers.sh [--update]

Compare each submodule gitlink in the parent repo with the configured branch
in .gitmodules. With --update, fast-forward initialized submodules to those
remote branch heads and stage the parent gitlink changes.
USAGE
  exit 0
fi

status=0

while read -r key path; do
  name="${key#submodule.}"
  name="${name%.path}"
  url="$(git -C "$ROOT" config -f .gitmodules --get "submodule.$name.url")"
  branch="$(git -C "$ROOT" config -f .gitmodules --get "submodule.$name.branch" || true)"
  branch="${branch:-master}"

  recorded="$(git -C "$ROOT" rev-parse ":$path" 2>/dev/null || git -C "$ROOT" rev-parse "HEAD:$path")"
  if git -C "$ROOT/$path" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "$ROOT/$path" fetch -q origin "$branch"
    remote="$(git -C "$ROOT/$path" rev-parse "origin/$branch")"
  else
    remote="$(git ls-remote "$url" "refs/heads/$branch" | awk '{print $1}')"
  fi

  if [[ -z "$remote" ]]; then
    echo "missing remote branch: $path -> $branch"
    status=1
    continue
  fi

  if [[ "$recorded" == "$remote" ]]; then
    printf 'ok       %s -> %s (%s)\n' "$path" "$branch" "${recorded:0:12}"
    continue
  fi

  printf 'outdated %s -> %s (%s -> %s)\n' "$path" "$branch" "${recorded:0:12}" "${remote:0:12}"
  status=1

  if [[ "$MODE" == "update" ]]; then
    git -C "$ROOT" submodule update --init "$path"
    git -C "$ROOT/$path" fetch origin "$branch"
    git -C "$ROOT/$path" checkout "$branch"
    git -C "$ROOT/$path" pull --ff-only origin "$branch"
    git -C "$ROOT" add "$path"
  fi
done < <(git -C "$ROOT" config -f .gitmodules --get-regexp '^submodule\..*\.path$')

if [[ "$MODE" == "update" ]]; then
  exit 0
fi

exit "$status"
