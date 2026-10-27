#!/usr/bin/env bash
set -euo pipefail
export IMAGE_VERSION=1.0 ONEC_VERSION=8.3.27.2130
export GITHUB_ACTIONS=true GITHUB_RUN_ID=123456 GITHUB_RUN_ATTEMPT=1
export GITHUB_SHA=0123456789012345678901234567890123456789
export GITHUB_REF=refs/heads/main GITHUB_REF_TYPE=branch
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export GITHUB_OUTPUT="$tmp/outputs"
plan() {
  local expected=$1
  shift
  : > "$GITHUB_OUTPUT"
  env "$@" bash scripts/ci-plan.sh
  grep -Fx "formats=$expected" "$GITHUB_OUTPUT"
}
plan '["deb","run"]' GITHUB_EVENT_NAME=push
plan '["deb"]' GITHUB_EVENT_NAME=push GITHUB_REF=refs/tags/v1.0 GITHUB_REF_TYPE=tag
plan '["deb"]' GITHUB_EVENT_NAME=workflow_dispatch INSTALL_FORMAT=''
plan '["run"]' GITHUB_EVENT_NAME=workflow_dispatch INSTALL_FORMAT=run
plan '["run"]' GITHUB_EVENT_NAME=workflow_dispatch INSTALL_FORMAT=run GITHUB_REF=refs/tags/v1.0 GITHUB_REF_TYPE=tag
reject() {
  if env "$@" bash scripts/ci-plan.sh; then echo 'FAIL: invalid plan accepted'; exit 1; fi
}
reject GITHUB_EVENT_NAME=workflow_dispatch INSTALL_FORMAT=bad
reject GITHUB_EVENT_NAME=push GITHUB_REF=refs/tags/v2.0 GITHUB_REF_TYPE=tag
reject GITHUB_EVENT_NAME=pull_request
echo 'PASS: branch matrix, automatic DEB release and manual format selection'
