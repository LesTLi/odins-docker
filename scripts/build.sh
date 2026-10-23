#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
image=${1:?Usage: build.sh server|onec-test}
[[ $image == server || $image == onec-test ]] || exit 2
version=${ONEC_VERSION:-}
base=${BASE_IMAGE:-}
# shellcheck source=../versions.env
source versions.env
ONEC_VERSION=${version:-$ONEC_VERSION}
BASE_IMAGE=${base:-$BASE_IMAGE}
source_kind=${DIST_SOURCE:-local}
format=${INSTALL_FORMAT:-deb}
[[ $source_kind == local || $source_kind == download ]] || exit 2
[[ $format == deb || $format == run ]] || exit 2
[[ $ONEC_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || exit 2
args=(--file "$image/Dockerfile" --build-arg "BASE_IMAGE=$BASE_IMAGE"
  --build-arg "ONEC_VERSION=$ONEC_VERSION" --build-arg "INSTALL_FORMAT=$format"
  --build-arg "DIST_SOURCE=$source_kind")
if [[ $source_kind == download ]]; then
  : "${ONEC_USERNAME:?Set ONEC_USERNAME}" "${ONEC_PASSWORD:?Set ONEC_PASSWORD}"
  args+=(--secret id=onec_username,env=ONEC_USERNAME --secret id=onec_password,env=ONEC_PASSWORD)
fi
if [[ -n ${DIST_EXPORT_DIR:-} ]]; then
  args+=(--target distribution-export --output "type=local,dest=$DIST_EXPORT_DIR")
else
  args+=(--target runtime --load --tag "${IMAGE_TAG:-odins-$image:$ONEC_VERSION-$format}")
fi
docker buildx build "${args[@]}" .
