#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=../versions.env
source /build/versions.env
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl mono-runtime ca-certificates-mono \
  libmono-i18n4.0-all libmono-system-runtime-serialization4.0-cil
curl --fail --location --retry 3 --proto '=https' \
  "https://github.com/EvilBeaver/OneScript/releases/download/v$ONESCRIPT_VERSION/onescript-engine_${ONESCRIPT_VERSION}_all.deb" -o /tmp/onescript.deb
echo "$ONESCRIPT_SHA256  /tmp/onescript.deb" | sha256sum --check --strict
apt-get install -y --no-install-recommends /tmp/onescript.deb
if [[ ${1:-test} == downloader ]]; then
  opm install "yard@$YARD_VERSION"
else
  opm install "vanessa-runner@$VRUNNER_VERSION"
  opm install "add@$ADD_VERSION"
fi
rm -f /tmp/onescript.deb
rm -rf /var/lib/apt/lists/*
