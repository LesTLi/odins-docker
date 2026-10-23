#!/usr/bin/env bash
set -euo pipefail
uid=$(id -u) gid=$(id -g)
if [[ -z ${HOME:-} || ! -d $HOME || ! -w $HOME ]]; then
  HOME=$(mktemp -d /tmp/onec-home.XXXXXXXX)
  export HOME
fi
if ! getent passwd "$uid" >/dev/null; then
  identity=$(mktemp -d /tmp/onec-identity.XXXXXXXX)
  cp /etc/passwd "$identity/passwd"
  cp /etc/group "$identity/group"
  printf 'onec_%s:x:%s:%s:1C user:%s:/bin/bash\n' "$uid" "$uid" "$gid" "$HOME" >> "$identity/passwd"
  if ! getent group "$gid" >/dev/null; then
    printf 'onec_%s:x:%s:\n' "$gid" "$gid" >> "$identity/group"
  fi
  export NSS_WRAPPER_PASSWD="$identity/passwd" NSS_WRAPPER_GROUP="$identity/group"
  export LD_PRELOAD="/usr/lib/x86_64-linux-gnu/libnss_wrapper.so${LD_PRELOAD:+:$LD_PRELOAD}"
fi
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
mkdir -p "$HOME/.1cv8" "$HOME/.1C/1cestart" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
if [[ ${ONEC_IMAGE:-server} == onec-test ]]; then
  exec /usr/local/bin/test-entrypoint "$@"
fi
exec "$@"
