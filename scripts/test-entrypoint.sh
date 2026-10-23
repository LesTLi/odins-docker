#!/usr/bin/env bash
set -euo pipefail
export DISPLAY=${DISPLAY:-:99}
children=()
# Invoked indirectly by the EXIT trap.
# shellcheck disable=SC2317
cleanup() { kill "${children[@]}" 2>/dev/null || true; wait 2>/dev/null || true; }
trap cleanup EXIT
trap 'exit 143' TERM
trap 'exit 130' INT
Xvfb "$DISPLAY" -screen 0 "${XVFB_SCREEN:-1440x900x24}" -nolisten tcp &
children+=("$!")
ready=false
for ((attempt=0; attempt<100; attempt++)); do
  kill -0 "${children[0]}" || { echo 'Xvfb failed' >&2; exit 1; }
  if xdpyinfo >/dev/null 2>&1; then ready=true; break; fi
  sleep 0.1
done
$ready || { echo 'Xvfb readiness timeout' >&2; exit 1; }
if [[ ${ENABLE_VNC:-0} == 1 ]]; then
  : "${VNC_PASSWORD_FILE:?Set VNC_PASSWORD_FILE to a mounted x11vnc password file}"
  [[ -r $VNC_PASSWORD_FILE ]] || exit 1
  x11vnc -display "$DISPLAY" -rfbauth "$VNC_PASSWORD_FILE" -forever -shared -rfbport 5900 &
  children+=("$!")
fi
"$@" &
children+=("$!")
status=0
wait "${children[-1]}" || status=$?
exit "$status"
