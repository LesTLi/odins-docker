#!/usr/bin/env bash
set -euo pipefail
format=$1 image=$2 version=$3 input=$4
export DEBIAN_FRONTEND=noninteractive
printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d
chmod 755 /usr/sbin/policy-rc.d
if [[ $format == deb ]]; then
  apt-get update
  apt-get install -y --no-install-recommends "$input"/*.deb
  rm -rf /var/lib/apt/lists/*
else
  installer="$input/setup-full-$version-x86_64.run"
  # Mount is read-only; execute a temporary copy and delete in this same layer.
  cp "$installer" /tmp/setup.run
  chmod 700 /tmp/setup.run
  components=server,ru
  [[ $image != onec-test ]] || components=server,client_full,client_thin_fib,ru
  /tmp/setup.run --mode unattended --enable-components "$components"
  rm /tmp/setup.run
fi
test -x "/opt/1cv8/x86_64/$version/ibcmd"
ln -s "/opt/1cv8/x86_64/$version" /opt/1cv8/current
for program in ibcmd ibsrv 1cv8 1cv8c rac ras; do
  if [[ -x /opt/1cv8/current/$program ]]; then
    ln -s "/opt/1cv8/current/$program" "/usr/local/bin/$program"
  fi
done
bash /build/scripts/configure-platform.sh "$image"
