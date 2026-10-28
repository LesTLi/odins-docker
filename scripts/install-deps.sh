#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
echo 'ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true' | debconf-set-selections
apt-get install -y --no-install-recommends \
  ca-certificates locales tzdata tini libnss-wrapper fontconfig ttf-mscorefonts-installer \
  libfreetype6 libcairo2 libharfbuzz0b libfribidi0 libgsf-bin liblcms2-2 \
  libkrb5-3 libgssapi-krb5-2 libglib2.0-0 libodbc2 libtcmalloc-minimal4
if [[ $1 == ui ]]; then
  apt-get install -y --no-install-recommends \
    libgtk-3-0 libgtk2.0-0 libwebkit2gtk-4.0-37 libglu1-mesa policykit-1 at-spi2-core \
    zenity x11-utils evince xvfb xauth x11vnc dbus-x11 scrot \
    openjdk-17-jre-headless git pandoc iproute2 iputils-ping net-tools procps
  install -d -m 1777 /tmp/.X11-unix
fi
locale-gen ru_RU.UTF-8
fc-match Arial | grep -qi arial
rm -rf /var/lib/apt/lists/*
