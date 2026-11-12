#!/usr/bin/env bash
set -euo pipefail
for ((attempt=0; attempt<100; attempt++)); do
  if [[ -f $HOME/.onec-ready ]] && xdpyinfo >/dev/null 2>&1; then
    exit 0
  fi
  sleep 0.2
done
echo '1C runtime or Xvfb is not ready' >&2
exit 1
