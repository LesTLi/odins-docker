#!/usr/bin/env bash
set -euo pipefail
export IMAGE_VERSION=1.0.0 ONEC_VERSION=8.3.27.2130 INSTALL_FORMAT=run
export GITHUB_RUN_ID=123456 GITHUB_RUN_ATTEMPT=1 GITHUB_ACTIONS=true
export GITHUB_SHA=0123456789012345678901234567890123456789
export GITHUB_REF=refs/heads/main GITHUB_REF_TYPE=branch GITHUB_EVENT_NAME=push
# shellcheck source=scripts/image-metadata.sh
source scripts/image-metadata.sh
init_image_metadata onec-test
[[ $IMAGE_BUILD_TAG == odins-onec-test:1.0.0-1c8.3.27.2130-run-b123456-a1 ]]
[[ -z $IMAGE_RELEASE_TAG ]]
[[ $IMAGE_REVISION == "$GITHUB_SHA" ]]
first=$IMAGE_BUILD_TAG
GITHUB_RUN_ATTEMPT=2 init_image_metadata onec-test
[[ $IMAGE_BUILD_TAG != "$first" && $IMAGE_BUILD_TAG == *-a2 ]]
GITHUB_RUN_ID=123457 init_image_metadata onec-test
[[ $IMAGE_BUILD_TAG != "$first" && $IMAGE_BUILD_TAG == *-b123457-a1 ]]
GITHUB_REF=refs/tags/v1.0.0 GITHUB_REF_TYPE=tag init_image_metadata server
[[ $IMAGE_RELEASE_TAG == odins-server:1.0.0-1c8.3.27.2130-run ]]
GITHUB_REF=refs/tags/v1.0.0 GITHUB_REF_TYPE=tag GITHUB_RUN_ATTEMPT=2 init_image_metadata server
[[ -z $IMAGE_RELEASE_TAG ]]
reject() {
  if ( "$@" ); then echo 'FAIL: invalid version metadata accepted' >&2; exit 1; fi
}
reject env GITHUB_REF=refs/tags/v2.0.0 GITHUB_REF_TYPE=tag bash -c 'source scripts/image-metadata.sh; init_image_metadata server'
reject env IMAGE_VERSION=01.0.0 bash -c 'source scripts/image-metadata.sh; init_image_metadata server'
reject env GITHUB_RUN_ATTEMPT=0 bash -c 'source scripts/image-metadata.sh; init_image_metadata server'
reject env GITHUB_SHA=bad-sha bash -c 'source scripts/image-metadata.sh; init_image_metadata server'
reject env INSTALL_FORMAT=bad bash -c 'source scripts/image-metadata.sh; init_image_metadata server'
reject env ONEC_VERSION=bad bash -c 'source scripts/image-metadata.sh; init_image_metadata server'
reject init_image_metadata unknown
echo 'PASS: versioning, release gates and rerun identity'
