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
package() {
  local name=$1 version=$2 arch=$3
  mkdir -p "$tmp/pkg/DEBIAN"
  printf 'Package: %s\nVersion: %s\nArchitecture: %s\nMaintainer: Test <test@example.invalid>\nDescription: fixture\n' "$name" "$version" "$arch" > "$tmp/pkg/DEBIAN/control"
  dpkg-deb --build "$tmp/pkg" "$tmp/input with spaces/$name.deb" >/dev/null
}
package 1c-enterprise-8.3.27.2130-common 8.3.27-2130 amd64
reject local deb server 8.3.27.2130 "$tmp/input with spaces" "$tmp/out"
package 1c-enterprise-8.3.27.2130-server 8.3.27-2130 arm64
reject local deb server 8.3.27.2130 "$tmp/input with spaces" "$tmp/out"
package 1c-enterprise-8.3.27.2130-server 8.3.27-2130 amd64
bash "$script" local deb server 8.3.27.2130 "$tmp/input with spaces" "$tmp/out"
[[ $(find "$tmp/out" -name '*.deb' | wc -l) == 2 ]]
reject local deb onec-test 8.3.27.2130 "$tmp/input with spaces" "$tmp/client-out"
echo 'PASS: invalid and missing distribution inputs rejected'
