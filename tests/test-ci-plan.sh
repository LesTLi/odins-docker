#!/usr/bin/env bash
set -euo pipefail
export IMAGE_VERSION=1.0 ONEC_VERSION=8.3.27.2130
export GITHUB_ACTIONS=true GITHUB_RUN_ID=123456 GITHUB_RUN_ATTEMPT=1
export GITHUB_SHA=0123456789012345678901234567890123456789
export GITHUB_REF=refs/heads/main GITHUB_REF_TYPE=branch
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/scripts"
cp scripts/ci-plan.sh scripts/image-metadata.sh "$tmp/scripts/"
cp versions.env "$tmp/versions.env"
sed -i '/^INSTALL_FORMAT=/d' "$tmp/versions.env"
printf '\nINSTALL_FORMAT=deb\n' >> "$tmp/versions.env"
unset INSTALL_FORMAT
export GITHUB_OUTPUT="$tmp/outputs"
plan() {
  local expected=$1
  shift
  : > "$GITHUB_OUTPUT"
  env "$@" bash "$tmp/scripts/ci-plan.sh"
  grep -Fx "formats=$expected" "$GITHUB_OUTPUT"
}
plan '["deb"]' GITHUB_EVENT_NAME=push
plan '["deb"]' GITHUB_EVENT_NAME=push GITHUB_REF=refs/tags/v1.0 GITHUB_REF_TYPE=tag
plan '["deb"]' GITHUB_EVENT_NAME=workflow_dispatch
sed -i 's/^INSTALL_FORMAT=.*/INSTALL_FORMAT=run/' "$tmp/versions.env"
plan '["run"]' GITHUB_EVENT_NAME=push
plan '["run"]' GITHUB_EVENT_NAME=push GITHUB_REF=refs/tags/v1.0 GITHUB_REF_TYPE=tag
plan '["run"]' GITHUB_EVENT_NAME=workflow_dispatch
plan '["run"]' GITHUB_EVENT_NAME=workflow_dispatch GITHUB_REF=refs/tags/v1.0 GITHUB_REF_TYPE=tag
reject() {
  if env "$@" bash "$tmp/scripts/ci-plan.sh"; then echo 'FAIL: invalid plan accepted'; exit 1; fi
}
reject GITHUB_EVENT_NAME=push GITHUB_REF=refs/tags/v2.0 GITHUB_REF_TYPE=tag
reject GITHUB_EVENT_NAME=pull_request
sed -i 's/^INSTALL_FORMAT=.*/INSTALL_FORMAT=bad/' "$tmp/versions.env"
reject GITHUB_EVENT_NAME=push
reject GITHUB_EVENT_NAME=workflow_dispatch
echo 'PASS: versions.env selects one format for branches, releases and manual builds'
