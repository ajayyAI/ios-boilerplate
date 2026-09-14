#!/usr/bin/env bash
# Fails if an installed tool version differs from the pinned one.
# Pinned versions are duplicated in Brewfile comments; update both together.
set -uo pipefail

fail=0

check() {
  local name="$1" expected="$2" cmd="$3" actual
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "error: $name is not installed. Run: brew bundle"
    fail=1
    return
  fi
  actual="$(eval "$cmd" 2>/dev/null | head -n1 | tr -d '[:space:]')"
  if [ "$actual" = "$expected" ]; then
    return
  fi
  # Newer than pinned is a warning: Homebrew upgrades on its own schedule, and a hard
  # failure there trains everyone to delete this check. Older or missing is a failure.
  if [ "$(printf '%s\n%s\n' "$expected" "$actual" | sort -V | tail -n1)" = "$actual" ]; then
    echo "warning: $name is '$actual', newer than pinned '$expected'. Update Brewfile when convenient."
  else
    echo "error: $name is '$actual', older than pinned '$expected'. Run: brew upgrade $name"
    fail=1
  fi
}

check swiftlint   0.65.1 'swiftlint version'
check swiftformat 0.63.0 'swiftformat --version'
check xcbeautify  3.2.1  'xcbeautify --version'
check periphery   3.8.0  'periphery version'
check lefthook    2.1.12 'lefthook version'

exit "$fail"
