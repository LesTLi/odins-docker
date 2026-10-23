#!/usr/bin/env bash
set -euo pipefail
set_key() {
  local file=$1 key=$2 value=$3
  mkdir -p "$(dirname "$file")"
  touch "$file"
  sed -i "/^[[:space:]]*$key[[:space:]]*=/d" "$file"
  printf '\n%s=%s\n' "$key" "$value" >> "$file"
  chmod 644 "$file"
}
set_key /opt/1cv8/conf/conf.cfg DisableUnsafeActionProtection '.*'
set_key /opt/1cv8/conf/conf.cfg SystemLanguage RU
set_key /opt/1cv8/common/1cestart.cfg UseHWLicenses 0
if [[ $1 == onec-test ]]; then
  set_key /opt/1cv8/conf/conf.cfg FtsJavaOpts '--add-opens java.base/java.lang=ALL-UNNAMED'
fi
