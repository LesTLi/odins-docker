#!/usr/bin/env bash
set -euo pipefail
# Run only on the disposable GitHub runner, never on a host with an installed 1C.
[[ ${GITHUB_ACTIONS:-} == true ]] || { echo 'Requires disposable Actions runner' >&2; exit 1; }
[[ ! -e /opt/1cv8 ]] || { echo '/opt/1cv8 already exists' >&2; exit 1; }
sudo mkdir -p /opt/1cv8/current/conf /opt/1cv8/conf
printf 'KeepMe=yes\nSystemLanguage=EN\nSystemLanguage=EN\n' | sudo tee /opt/1cv8/conf/conf.cfg >/dev/null
sudo bash scripts/configure-platform.sh onec-test
sudo bash scripts/configure-platform.sh onec-test
grep -Fx 'KeepMe=yes' /opt/1cv8/conf/conf.cfg
[[ $(grep -c '^SystemLanguage=' /opt/1cv8/conf/conf.cfg) == 1 ]]
grep -Fx 'ConfLocation=/opt/1cv8/conf' /opt/1cv8/current/conf/conf.cfg
grep -Fx 'SystemLanguage=RU' /opt/1cv8/conf/conf.cfg
grep -Fx 'DisableUnsafeActionProtection=.*' /opt/1cv8/conf/conf.cfg
grep -Fx 'FtsJavaOpts=--add-opens java.base/java.lang=ALL-UNNAMED' /opt/1cv8/conf/conf.cfg
grep -Fx 'UseHWLicenses=0' /opt/1cv8/common/1cestart.cfg
