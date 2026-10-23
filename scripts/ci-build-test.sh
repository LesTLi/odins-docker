#!/usr/bin/env bash
set -euo pipefail
image=${1:?image}
export IMAGE_TAG="odins-ci:$image-${INSTALL_FORMAT:?format}"
export DIST_SOURCE=download
bash scripts/build.sh "$image"
bash tests/smoke.sh "$IMAGE_TAG" "$image"
DIST_EXPORT_DIR="$PWD/distr" bash scripts/build.sh "$image"
export DIST_SOURCE=local
bash scripts/build.sh "$image"
bash tests/smoke.sh "$IMAGE_TAG" "$image"
printf '### %s / %s\nDownload and local build + smoke tests passed.\n' "$image" "$INSTALL_FORMAT" >> "$GITHUB_STEP_SUMMARY"
