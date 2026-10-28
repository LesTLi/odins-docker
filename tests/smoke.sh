#!/usr/bin/env bash
set -euo pipefail
tag=${1:?image tag} kind=${2:?server or onec-test} mode=${3:-full}
# shellcheck source=versions.env
source versions.env
export EXPECTED_ONESCRIPT_VERSION=$ONESCRIPT_VERSION
tmp=$(mktemp -d)
container=''
cleanup() {
  [[ -z $container ]] || docker rm -f "$container" >/dev/null 2>&1 || true
  sudo rm -rf "$tmp"
}
trap cleanup EXIT
trap 'status=$?; printf "Smoke failed at line %s (exit %s)\n" "$LINENO" "$status" >&2; exit "$status"' ERR
docker run --rm "$tag" bash -ec '
  test "$(id -u)" = 10001; test "$(id -g)" = 10001
  test "$(id -un)" = usr1cv8; test "$(id -gn)" = grp1cv8
  test "$HOME" = /home/usr1cv8; test -w "$HOME"
  test "$(getent passwd 10001 | cut -d : -f 6)" = "$HOME"
'
[[ $(printf 'stdin value\n' | docker run --rm -i "$tag" cat) == 'stdin value' ]]
for identity in 10001:10001 23456:23457; do
  for license_value in 0 1; do
    docker run --rm --user "$identity" -e ONEC_USE_HW_LICENSES="$license_value" "$tag" bash -ec '
      test "$(iconv -f UTF-16 -t UTF-8 "$HOME/.1C/1cestart/1cestart.cfg" | grep -c "^UseHWLicenses=$ONEC_USE_HW_LICENSES$")" = 1
    '
  done
  docker run --rm --user "$identity" "$tag" bash -ec '
    iconv -f UTF-16 -t UTF-8 "$HOME/.1C/1cestart/1cestart.cfg" | grep -Fx UseHWLicenses=0
  '
  mkdir -p "$tmp/work space"
  sudo chown "${identity/:/:}" "$tmp/work space"
  docker run --rm --user "$identity" --mount "type=bind,src=$tmp/work space,dst=/workspace" \
    "$tag" bash -ec 'test "$(id -u)" != 0; getent passwd "$(id -u)"; test -w "$HOME"; touch /workspace/owned; printf "%s\n" "argument with spaces" > /workspace/argument'
  [[ $(stat -c '%u:%g' "$tmp/work space/owned") == "$identity" ]]
  [[ $(cat "$tmp/work space/argument") == 'argument with spaces' ]]
  sudo rm "$tmp/work space/owned" "$tmp/work space/argument"
  if [[ $mode == full ]]; then
    docker run --rm --user "$identity" "$tag" ibcmd --help
    if [[ $kind == server ]]; then
      docker run --rm --user "$identity" "$tag" bash -ec 'test ! -e /opt/1cv8/current/1cv8; test ! -e /opt/1cv8/current/1cv8c'
    fi
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
        mkdir "$HOME/init-dev-regression"
        cd "$HOME/init-dev-regression"
        status=0
        timeout 120 vrunner init-dev >init-dev.log 2>&1 || status=$?
        cat init-dev.log
        test "$status" = 0
        test -s build/ib/1Cv8.1CD
        if grep -E "AT-SPI:|org[.]a11y[.]Bus|dbind-WARNING|ОШИБКА[[:space:]]*-" init-dev.log; then
          echo "Unexpected client error or accessibility bus warning during init-dev" >&2
          exit 1
        fi
      '
    fi
    docker run --rm --user "$identity" -e EXPECTED_ONESCRIPT_VERSION "$tag" bash -ec '
      oscript -version | tee "$HOME/oscript-version.txt"
      grep -F "$EXPECTED_ONESCRIPT_VERSION" "$HOME/oscript-version.txt"
      opm list; vrunner version; java -version
      xdpyinfo >/dev/null
      nircmd savescreenshot "$HOME/screen shot.png"
      test -s "$HOME/screen shot.png"
    '
  fi
done
status=0
docker run --rm -e ONEC_USE_HW_LICENSES=invalid "$tag" bash -c 'echo UNEXPECTED_COMMAND' >"$tmp/invalid.log" 2>&1 || status=$?
[[ $status != 0 ]]
grep -F 'ONEC_USE_HW_LICENSES must be 0 or 1' "$tmp/invalid.log"
if grep -q UNEXPECTED_COMMAND "$tmp/invalid.log"; then
  echo 'Command ran despite invalid license configuration' >&2
  exit 1
fi
status=0
docker run --rm "$tag" bash -c 'exit 42' || status=$?
[[ $status == 42 ]]
container=$(docker run -d "$tag" bash -c 'trap "echo TERM_HANDLED; exit 0" TERM; echo CHILD_READY; while :; do sleep 1; done')
ready=false
for ((attempt=0; attempt<100; attempt++)); do
  if docker logs "$container" >"$tmp/container.log" 2>&1 && grep -q CHILD_READY "$tmp/container.log"; then ready=true; break; fi
  [[ $(docker inspect -f '{{.State.Running}}' "$container") == true ]] || break
  sleep 0.2
done
$ready || { docker logs "$container"; echo 'Child did not start' >&2; exit 1; }
docker stop --time 10 "$container" >/dev/null
docker logs "$container" >"$tmp/container.log" 2>&1
grep -q TERM_HANDLED "$tmp/container.log"
status=$(docker inspect -f '{{.State.ExitCode}}' "$container")
[[ $status == 0 || $status == 143 ]]
echo "PASS: $tag ($mode)"
