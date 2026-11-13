#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
image=${1:?Usage: build.sh server|onec-test}
[[ $image == server || $image == onec-test ]] || exit 2
# shellcheck source=scripts/image-metadata.sh
source scripts/image-metadata.sh
init_image_metadata "$image"
source_kind=${DIST_SOURCE:-local}
format=${INSTALL_FORMAT:-deb}
[[ $source_kind == local || $source_kind == download ]] || exit 2
[[ $format == deb || $format == run ]] || exit 2
[[ $ONEC_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || exit 2
args=(--file "$image/Dockerfile" --build-arg "BASE_IMAGE=$BASE_IMAGE"
  --build-arg "IMAGE_VERSION=$IMAGE_VERSION"
  --build-arg "ONEC_VERSION=$ONEC_VERSION" --build-arg "INSTALL_FORMAT=$format"
  --build-arg "DIST_SOURCE=$source_kind"
  --label "org.opencontainers.image.version=$IMAGE_VERSION"
  --label "org.opencontainers.image.revision=$IMAGE_REVISION"
  --label "org.opencontainers.image.source=$IMAGE_SOURCE"
  --label "org.opencontainers.image.created=$IMAGE_CREATED"
  --label "io.github.lestli.odins-docker.onec.version=$ONEC_VERSION"
  --label "io.github.lestli.odins-docker.install.format=$format")
if [[ $source_kind == download ]]; then
  : "${ONEC_USERNAME:?Set ONEC_USERNAME}" "${ONEC_PASSWORD:?Set ONEC_PASSWORD}"
  args+=(--secret 'id=onec_username,env=ONEC_USERNAME' --secret 'id=onec_password,env=ONEC_PASSWORD')
fi
if [[ -n ${DIST_EXPORT_DIR:-} ]]; then
  args+=(--target distribution-export --output "type=local,dest=$DIST_EXPORT_DIR")
else
  args+=(--target runtime --load --tag "${IMAGE_TAG:-$IMAGE_BUILD_TAG}")
fi
docker buildx build "${args[@]}" .
