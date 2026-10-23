#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=versions.env
source /build/versions.env
export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8 LC_ALL=C.UTF-8
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl mono-runtime ca-certificates-mono \
  libmono-i18n4.0-all libmono-system-runtime-serialization4.0-cil
curl --fail --location --retry 3 --proto '=https' \
  "https://github.com/EvilBeaver/OneScript/releases/download/v$ONESCRIPT_VERSION/onescript-engine_${ONESCRIPT_VERSION}_all.deb" -o /tmp/onescript.deb
echo "$ONESCRIPT_SHA256  /tmp/onescript.deb" | sha256sum --check --strict
apt-get install -y --no-install-recommends /tmp/onescript.deb
opm install "opm@$OPM_VERSION"
if [[ ${1:-test} == downloader ]]; then
  # OPM bundles fluent without all of its transitive runtime dependencies.
  opm install -f "fluent@$FLUENT_VERSION"
  opm install "yard@$YARD_VERSION"
  yard --help
else
  opm install "vanessa-runner@$VRUNNER_VERSION"
  curl --fail --location --retry 3 --proto '=https' \
    "https://github.com/vanessa-opensource/add/releases/download/v$ADD_VERSION/add-$ADD_VERSION.ospx" -o /tmp/add.ospx
  echo "$ADD_SHA256  /tmp/add.ospx" | sha256sum --check --strict
  opm install -f /tmp/add.ospx
  rm /tmp/add.ospx
fi
rm -f /tmp/onescript.deb
rm -rf /var/lib/apt/lists/*
