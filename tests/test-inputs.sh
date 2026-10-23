#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
script="$root/scripts/acquire.sh"
[[ -f "$script" ]] || { echo 'FAIL: acquire.sh is missing'; exit 1; }
reject() {
  if bash "$script" "$@" >"$tmp/error" 2>&1; then
    echo 'FAIL: invalid input was accepted'; exit 1
  fi
}
reject invalid deb server 8.3.27.2130 "$tmp" "$tmp/out"
reject local invalid server 8.3.27.2130 "$tmp" "$tmp/out"
reject local deb invalid 8.3.27.2130 "$tmp" "$tmp/out"
reject local deb server bad-version "$tmp" "$tmp/out"
reject local deb server 8.3.27.2130 "$tmp/absent" "$tmp/out"
mkdir -p "$tmp/input with spaces"
reject local deb server 8.3.27.2130 "$tmp/input with spaces" "$tmp/out"
echo 'PASS: invalid and missing distribution inputs rejected'
