#!/usr/bin/env bash
set -euo pipefail
image=${1:?image}
# shellcheck source=scripts/image-metadata.sh
source scripts/image-metadata.sh
init_image_metadata "$image"
export IMAGE_TAG="odins-ci:$image-${INSTALL_FORMAT:?format}"
export DIST_SOURCE=download
bash scripts/build.sh "$image"
bash tests/smoke.sh "$IMAGE_TAG" "$image"
DIST_EXPORT_DIR="$PWD/distr" bash scripts/build.sh "$image"
export DIST_SOURCE=local
bash scripts/build.sh "$image"
bash tests/smoke.sh "$IMAGE_TAG" "$image"
printf '### %s / image %s / 1C %s / %s\nDownload and local build + smoke tests passed.\n' "$image" "$IMAGE_VERSION" "$ONEC_VERSION" "$INSTALL_FORMAT" >> "$GITHUB_STEP_SUMMARY"
bash scripts/image-size-report.sh "$IMAGE_TAG" | tee "$RUNNER_TEMP/image-size-$image-$INSTALL_FORMAT.txt"
# Distribution and compiler caches are no longer needed; keep the loaded image.
docker buildx prune --all --force
bash scripts/export-image.sh "$image" "$IMAGE_TAG" "$RUNNER_TEMP/image-artifacts/$image-$INSTALL_FORMAT"
cp "$RUNNER_TEMP/image-size-$image-$INSTALL_FORMAT.txt" "$RUNNER_TEMP/image-artifacts/$image-$INSTALL_FORMAT/size-report.txt"
