#!/usr/bin/env bash
set -euo pipefail
case ${GITHUB_EVENT_NAME:-} in
  push|workflow_dispatch) ;;
  *) echo 'Unsupported build event' >&2; exit 1 ;;
esac
# CI always selects from the checked-out versions.env, never a form override.
unset INSTALL_FORMAT
# Validate versions and release refs before spending time on image builds.
# shellcheck source=scripts/image-metadata.sh
source "$(dirname "$0")/image-metadata.sh"
init_image_metadata server
formats="[\"$INSTALL_FORMAT\"]"
printf 'formats=%s\n' "$formats" >> "${GITHUB_OUTPUT:?Actions outputs file}"
printf 'Formats: %s; release: %s\n' "$formats" "${IMAGE_RELEASE_TAG:-development build}"
