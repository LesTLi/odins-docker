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

start_command() {
  # Сохраняем stdin команды при запуске в фоне.
  exec 3<&0
  "$@" <&3 &
  command_pid=$!
  children+=("$command_pid")
  exec 3<&-
}

jenkins_agent=${ONEC_JENKINS_AGENT:-0}
if [[ $jenkins_agent == 1 ]]; then
  if [[ $# != 1 || ${1:-} != cat ]]; then
    echo 'ONEC_JENKINS_AGENT=1 expects the Docker Pipeline cat command' >&2
    exit 1
  fi
  rm -f "${HOME:?Set HOME at container creation}/.onec-ready"
  # Docker Pipeline ищет cat сразу после docker run.
  start_command "$@"
fi

prepare_runtime
Xvfb "$DISPLAY" -screen 0 "${XVFB_SCREEN:-1440x900x24}" -nolisten tcp &
xvfb_pid=$!
children+=("$xvfb_pid")
ready=false
for ((attempt=0; attempt<100; attempt++)); do
  kill -0 "$xvfb_pid" || { echo 'Xvfb failed' >&2; exit 1; }
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
if [[ $jenkins_agent == 1 ]]; then
  touch "$HOME/.onec-ready"
else
  start_command "$@"
fi
status=0
wait "$command_pid" || status=$?
exit "$status"
