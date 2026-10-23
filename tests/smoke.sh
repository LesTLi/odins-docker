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
    docker run --rm --user "$identity" "$tag" bash -ec '
      oscript -version; opm list; vrunner --version; java -version
      xdpyinfo >/dev/null
      nircmd savescreenshot "$HOME/screen shot.png"
      test -s "$HOME/screen shot.png"
    '
  fi
done
status=0
docker run --rm "$tag" bash -c 'exit 42' || status=$?
[[ $status == 42 ]]
container=$(docker run -d "$tag" sleep 300)
docker stop --time 10 "$container" >/dev/null
[[ $(docker inspect -f '{{.State.ExitCode}}' "$container") != 137 ]]
echo "PASS: $tag ($mode)"
