#!/usr/bin/env bash
set -euo pipefail
case ${GITHUB_EVENT_NAME:-} in
  workflow_dispatch)
    format=${INSTALL_FORMAT:-deb}
    [[ $format == deb || $format == run ]] || { echo 'Select deb or run' >&2; exit 1; }
    formats="[\"$format\"]"
    ;;
  push)
    format=deb
    if [[ ${GITHUB_REF:-} == refs/tags/* ]]; then
      formats='["deb"]'
    else
      formats='["deb","run"]'
    fi
    ;;
  *) echo 'Unsupported build event' >&2; exit 1 ;;
esac
export INSTALL_FORMAT=$format
# Validate versions and release refs before spending time on image builds.
# shellcheck source=scripts/image-metadata.sh
source "$(dirname "$0")/image-metadata.sh"
init_image_metadata server
printf 'formats=%s\n' "$formats" >> "${GITHUB_OUTPUT:?Actions outputs file}"
printf 'Formats: %s; release: %s\n' "$formats" "${IMAGE_RELEASE_TAG:-development build}"
