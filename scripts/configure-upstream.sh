#!/usr/bin/env bash
set -euo pipefail

upstream_url='https://github.com/BaaRai/ARTEX.git'

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo 'Run this from inside a Git working tree.' >&2
  exit 2
}

if git remote get-url upstream >/dev/null 2>&1; then
  existing="$(git remote get-url upstream)"
  if [[ "$existing" != "$upstream_url" ]]; then
    echo "The upstream remote already points to an unexpected URL: $existing" >&2
    exit 3
  fi
else
  git remote add upstream "$upstream_url"
fi

git fetch upstream --prune --tags
git fetch origin refs/heads/source/main:refs/remotes/origin/source/main

echo 'Configured upstream remote:'
git remote -v
echo
echo 'Upstream main versus preserved source snapshot:'
git log --oneline --left-right origin/source/main...upstream/main || true
