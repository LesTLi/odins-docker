#!/usr/bin/env bash
set -euo pipefail
image=${1:?tested image tag}
printf 'Docker image size (bytes): '
docker image inspect --format '{{.Size}}' "$image"
# Inspect the actual installed filesystem, without modifying the image.
docker run --rm --user 0:0 --entrypoint /bin/bash "$image" -ec '
  echo "Platform directories (KiB):"
  du -x -k --max-depth=2 /opt/1cv8 | sort -nr
  echo "Largest platform files (bytes):"
  find /opt/1cv8 -type f -printf "%s\t%p\n" | sort -nr | sed -n "1,30p"
  echo "Installed DEB packages (package, version, installed KiB):"
  dpkg-query -W -f="\${Package}\t\${Version}\t\${Installed-Size}\n"
'
