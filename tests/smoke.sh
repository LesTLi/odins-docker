#!/usr/bin/env bash
set -euo pipefail
tag=${1:?image tag} kind=${2:?server or onec-test} mode=${3:-full}
tmp=$(mktemp -d)
container=''
cleanup() {
  [[ -z $container ]] || docker rm -f "$container" >/dev/null 2>&1 || true
  sudo rm -rf "$tmp"
}
trap cleanup EXIT
docker run --rm "$tag" bash -ec 'test "$(id -u)" != 0; test -w "$HOME"'
[[ $(printf 'stdin value\n' | docker run --rm -i "$tag" cat) == 'stdin value' ]]
for identity in 10001:10001 23456:23457; do
  mkdir -p "$tmp/work space"
  sudo chown "${identity/:/:}" "$tmp/work space"
  docker run --rm --user "$identity" --mount "type=bind,src=$tmp/work space,dst=/workspace" \
    "$tag" bash -ec 'test "$(id -u)" != 0; getent passwd "$(id -u)"; test -w "$HOME"; touch /workspace/owned; printf "%s\n" "argument with spaces" > /workspace/argument'
  [[ $(stat -c '%u:%g' "$tmp/work space/owned") == "$identity" ]]
  [[ $(cat "$tmp/work space/argument") == 'argument with spaces' ]]
  sudo rm "$tmp/work space/owned" "$tmp/work space/argument"
  if [[ $mode == full ]]; then
    docker run --rm --user "$identity" "$tag" ibcmd --help
    docker run --rm --user "$identity" "$tag" bash -ec '
      for expected in "DisableUnsafeActionProtection=.*" "SystemLanguage=RU"; do
        test "$(grep -Fxc "$expected" /opt/1cv8/conf/conf.cfg)" = 1
      done
      test "$(grep -Fxc "UseHWLicenses=0" /opt/1cv8/common/1cestart.cfg)" = 1
      test -x /opt/1cv8/current/ibcmd
      ! ldd /opt/1cv8/current/ibcmd | grep "not found"
    '
  fi
  if [[ $kind == onec-test ]]; then
    if [[ $mode == full ]]; then
      docker run --rm --user "$identity" "$tag" bash -ec '
        for executable in 1cv8 1cv8c; do
          binary=$(command -v "$executable")
          test -x "$binary"
          dependencies=$(ldd "$binary")
          ! grep -q "not found" <<< "$dependencies"
        done
        grep -Fx "FtsJavaOpts=--add-opens java.base/java.lang=ALL-UNNAMED" /opt/1cv8/conf/conf.cfg
      '
    fi
    docker run --rm --user "$identity" "$tag" bash -ec '
      oscript -version; opm list; vrunner version; java -version
      xdpyinfo >/dev/null
      nircmd savescreenshot "$HOME/screen shot.png"
      test -s "$HOME/screen shot.png"
    '
  fi
done
status=0
docker run --rm "$tag" bash -c 'exit 42' || status=$?
[[ $status == 42 ]]
container=$(docker run -d "$tag" bash -c 'trap "echo TERM_HANDLED; exit 0" TERM; echo CHILD_READY; while :; do sleep 1; done')
ready=false
for ((attempt=0; attempt<100; attempt++)); do
  if docker logs "$container" 2>&1 | grep -q CHILD_READY; then ready=true; break; fi
  [[ $(docker inspect -f '{{.State.Running}}' "$container") == true ]] || break
  sleep 0.2
done
$ready || { docker logs "$container"; echo 'Child did not start' >&2; exit 1; }
docker stop --time 10 "$container" >/dev/null
docker logs "$container" 2>&1 | grep -q TERM_HANDLED
status=$(docker inspect -f '{{.State.ExitCode}}' "$container")
[[ $status == 0 || $status == 143 ]]
echo "PASS: $tag ($mode)"
