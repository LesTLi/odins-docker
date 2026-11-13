#!/usr/bin/env bash
set -euo pipefail
prepare_runtime() {
  local uid gid identity passwd_file group_file
  uid=$(id -u) gid=$(id -g)
  if [[ ${jenkins_agent:-0} == 1 ]]; then
    # docker exec видит HOME, заданный при создании контейнера.
    (umask 077; mkdir -p "$HOME")
    if [[ ! -w $HOME ]]; then
      echo 'Set HOME to a writable directory at container creation' >&2
      exit 1
    fi
  else
    if [[ -z ${HOME:-} || ! -d $HOME || ! -w $HOME ]]; then
      HOME=$(mktemp -d /tmp/onec-home.XXXXXXXX)
      export HOME
    fi
    if ! getent passwd "$uid" >/dev/null; then
      identity=$(mktemp -d /tmp/onec-identity.XXXXXXXX)
      passwd_file=$identity/passwd
      group_file=$identity/group
      export NSS_WRAPPER_PASSWD=$passwd_file NSS_WRAPPER_GROUP=$group_file
      export LD_PRELOAD="/usr/lib/x86_64-linux-gnu/libnss_wrapper.so${LD_PRELOAD:+:$LD_PRELOAD}"
    fi
  fi
  if [[ -n ${passwd_file:-} ]]; then
    cp /etc/passwd "$passwd_file"
    cp /etc/group "$group_file"
    if ! getent passwd "$uid" >/dev/null; then
      printf 'onec_%s:x:%s:%s:1C user:%s:/bin/bash\n' "$uid" "$uid" "$gid" "$HOME" >> "$passwd_file"
    fi
    if ! getent group "$gid" >/dev/null; then
      printf 'onec_%s:x:%s:\n' "$gid" "$gid" >> "$group_file"
    fi
  fi
  export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
  export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
  mkdir -p "$HOME/.1cv8" "$HOME/.1C/1cestart" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
  /usr/local/bin/configure-onec-runtime
}

if [[ ${ONEC_IMAGE:-server} == onec-test ]]; then
  # shellcheck source=scripts/test-entrypoint.sh
  source /usr/local/bin/test-entrypoint
fi
prepare_runtime
exec "$@"
