#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=versions.env
source /build/versions.env
export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8 LC_ALL=C.UTF-8
apt-get update
if [[ ${1:-test} == downloader ]]; then
  apt-get install -y --no-install-recommends ca-certificates curl unzip libicu70 libssl3 libstdc++6 zlib1g
  curl --fail --location --retry 3 --proto '=https' \
    "https://github.com/EvilBeaver/OneScript/releases/download/v$DOWNLOADER_ONESCRIPT_VERSION/OneScript-$DOWNLOADER_ONESCRIPT_VERSION-linux-x64.zip" -o /tmp/onescript.zip
  echo "$DOWNLOADER_ONESCRIPT_SHA256  /tmp/onescript.zip" | sha256sum --check --strict
  mkdir -p /opt/onescript
  unzip -q /tmp/onescript.zip -d /opt/onescript
  chmod +x /opt/onescript/bin/oscript /opt/onescript/bin/opm
  ln -s /opt/onescript/bin/oscript /usr/local/bin/oscript
  # OPM resolves ../lib from its own script path; a symlink would change it.
  printf '#!/bin/sh\nexec /opt/onescript/bin/opm "$@"\n' > /usr/local/bin/opm
  chmod 755 /usr/local/bin/opm
  export OSCRIPTBIN=/usr/local/bin
  rm /tmp/onescript.zip
else
apt-get install -y --no-install-recommends ca-certificates curl mono-runtime ca-certificates-mono \
  libmono-i18n4.0-all libmono-system-runtime-serialization4.0-cil
curl --fail --location --retry 3 --proto '=https' \
  "https://github.com/EvilBeaver/OneScript/releases/download/v$ONESCRIPT_VERSION/onescript-engine_${ONESCRIPT_VERSION}_all.deb" -o /tmp/onescript.deb
echo "$ONESCRIPT_SHA256  /tmp/onescript.deb" | sha256sum --check --strict
apt-get install -y --no-install-recommends /tmp/onescript.deb
opm install "opm@$OPM_VERSION"
fi
if [[ ${1:-test} == downloader ]]; then
  # OPM bundles fluent without all of its transitive runtime dependencies.
  opm install "fluent@$FLUENT_VERSION"
  curl --fail --location --retry 3 --proto '=https' \
    "https://github.com/arkuznetsov/yard/releases/download/v.$YARD_VERSION/yard-$YARD_VERSION.ospx" -o /tmp/yard.ospx
  echo "$YARD_SHA256  /tmp/yard.ospx" | sha256sum --check --strict
  opm install -f /tmp/yard.ospx
  rm /tmp/yard.ospx
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
