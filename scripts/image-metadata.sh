#!/usr/bin/env bash
# Shared by build/export; sourcing this file does not change the environment.
metadata_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

init_image_metadata() {
  local kind=${1:?image} requested_version=${IMAGE_VERSION:-}
  local requested_onec=${ONEC_VERSION:-} requested_base=${BASE_IMAGE:-}
  local requested_format=${INSTALL_FORMAT:-} format suffix repository
  # shellcheck source=versions.env
  source "$metadata_root/versions.env"
  IMAGE_VERSION=${requested_version:-$IMAGE_VERSION}
  ONEC_VERSION=${requested_onec:-$ONEC_VERSION}
  BASE_IMAGE=${requested_base:-$BASE_IMAGE}
  format=${requested_format:-${INSTALL_FORMAT:-}}
  [[ $kind == server || $kind == onec-test ]] || { echo 'Invalid image kind' >&2; return 1; }
  repository=onec-test
  [[ $kind != server ]] || repository=onec-server
  [[ $IMAGE_VERSION =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] || {
    echo 'IMAGE_VERSION must use MAJOR.MINOR without leading zeros' >&2; return 1;
  }
  [[ $ONEC_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Invalid ONEC_VERSION' >&2; return 1; }
  [[ $format == deb || $format == run ]] || { echo 'Invalid INSTALL_FORMAT' >&2; return 1; }
  IMAGE_REVISION=${GITHUB_SHA:-${IMAGE_REVISION:-$(git -C "$metadata_root" rev-parse HEAD)}}
  [[ $IMAGE_REVISION =~ ^[a-fA-F0-9]{40}$ ]] || { echo 'Invalid Git revision' >&2; return 1; }
  IMAGE_SOURCE=${IMAGE_SOURCE:-${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-LesTLi/odins-docker}}
  IMAGE_CREATED=${IMAGE_CREATED:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}
  IMAGE_RELEASE_TAG=''
  if [[ ${GITHUB_ACTIONS:-} == true ]]; then
    [[ ${GITHUB_RUN_ID:-} =~ ^[1-9][0-9]*$ && ${GITHUB_RUN_ATTEMPT:-} =~ ^[1-9][0-9]*$ ]] || {
      echo 'Actions requires valid run ID and attempt' >&2; return 1;
    }
    suffix="b$GITHUB_RUN_ID"
  else
    suffix="local-$(date -u +%Y%m%d%H%M%S)-$RANDOM"
  fi
  IMAGE_BUILD_TAG="$repository:$IMAGE_VERSION-1c$ONEC_VERSION-$format-$suffix"
  if [[ ${GITHUB_REF:-} == refs/tags/* || ${GITHUB_REF_TYPE:-} == tag ]]; then
    [[ ${GITHUB_REF:-} == "refs/tags/v$IMAGE_VERSION" ]] || {
      echo 'Git release tag must match IMAGE_VERSION' >&2; return 1;
    }
    if [[ ${GITHUB_ACTIONS:-} == true ]]; then
      case ${GITHUB_EVENT_NAME:-} in
        push|workflow_dispatch) ;;
        *) echo 'Unsupported release event' >&2; return 1 ;;
      esac
      IMAGE_RELEASE_TAG="$repository:$IMAGE_VERSION-1c$ONEC_VERSION"
    fi
  fi
  IMAGE_ARCHIVE_STEM=${IMAGE_RELEASE_TAG:-$IMAGE_BUILD_TAG}
  IMAGE_ARCHIVE_STEM="${IMAGE_ARCHIVE_STEM/:/_}_linux-amd64"
  INSTALL_FORMAT=$format
  export IMAGE_VERSION ONEC_VERSION BASE_IMAGE INSTALL_FORMAT
  export IMAGE_BUILD_TAG IMAGE_RELEASE_TAG IMAGE_ARCHIVE_STEM IMAGE_REVISION IMAGE_SOURCE IMAGE_CREATED
}
