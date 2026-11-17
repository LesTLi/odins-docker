#!/usr/bin/env bash
set -euo pipefail
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
mkdir -p "$HOME/.1C/1cestart"
cfg="$HOME/.1C/1cestart/1cestart.cfg"
helper=scripts/configure-runtime.sh
read_config() { iconv -f UTF-16 -t UTF-8 "$cfg"; }
expect_value() {
  local content
  content=$(read_config)
  [[ $(grep -c '^UseHWLicenses=' <<< "$content") == 1 ]]
  grep -Fx "UseHWLicenses=$1" <<< "$content"
}
env -u ONEC_USE_HW_LICENSES bash "$helper"
expect_value 0
ONEC_USE_HW_LICENSES=1 bash "$helper"
expect_value 1
ONEC_USE_HW_LICENSES=0 bash "$helper"
expect_value 0
printf 'KeepMe=Привет\nUseHwLicenses=0\n  UseHWLicenses = 1\nCommonInfoBases=first\nCommonInfoBases=second\n' > "$cfg"
ONEC_USE_HW_LICENSES=1 bash "$helper"
expect_value 1
[[ $(read_config | grep -c '^CommonInfoBases=') == 2 ]]
read_config | grep -Fx 'KeepMe=Привет'
ONEC_USE_HW_LICENSES=0 bash "$helper"
expect_value 0
read_config | grep -Fx 'KeepMe=Привет'
before=$(sha256sum "$cfg")
for value in '' 2 true '1;exit 0'; do
  if ONEC_USE_HW_LICENSES="$value" bash "$helper" >"$tmp/error" 2>&1; then
    echo 'FAIL: invalid value accepted' >&2; exit 1
  fi
  grep -F 'ONEC_USE_HW_LICENSES must be 0 or 1' "$tmp/error"
  [[ $(sha256sum "$cfg") == "$before" ]]
done
chmod 444 "$cfg"
if bash "$helper" >"$tmp/error" 2>&1; then
  echo 'FAIL: read-only configuration accepted' >&2; exit 1
fi
grep -F 'must be a writable regular file' "$tmp/error"
[[ $(sha256sum "$cfg") == "$before" ]]
chmod 600 "$cfg"
mv "$cfg" "$cfg.original"
ln -s "$cfg.original" "$cfg"
if bash "$helper" >"$tmp/error" 2>&1; then
  echo 'FAIL: configuration symlink accepted' >&2; exit 1
fi
[[ -L $cfg && $(sha256sum "$cfg.original" | cut -d ' ' -f1) == "${before%% *}" ]]
echo 'PASS: runtime license configuration preserves settings and validates input'
