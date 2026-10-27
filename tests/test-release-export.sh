#!/usr/bin/env bash
set -euo pipefail
tmp=$(mktemp -d)
export IMAGE_VERSION=1.0 ONEC_VERSION=8.3.27.2130 INSTALL_FORMAT=deb
export GITHUB_ACTIONS=true GITHUB_RUN_ID=987654 GITHUB_RUN_ATTEMPT=1
export GITHUB_SHA=0123456789012345678901234567890123456789
export GITHUB_REF=refs/tags/v1.0 GITHUB_REF_TYPE=tag GITHUB_EVENT_NAME=push
export GITHUB_OUTPUT="$tmp/outputs" GITHUB_STEP_SUMMARY="$tmp/summary"
# shellcheck source=scripts/image-metadata.sh
source scripts/image-metadata.sh
init_image_metadata server
candidate=odins-fixture:release
cleanup() {
  docker image rm "$candidate" "$IMAGE_BUILD_TAG" "$IMAGE_RELEASE_TAG" >/dev/null 2>&1 || true
  rm -rf "$tmp"
}
trap cleanup EXIT
mkdir "$tmp/context"
printf 'fixture\n' > "$tmp/context/payload"
printf 'FROM scratch\nCOPY payload /payload\n' > "$tmp/context/Dockerfile"
docker build --network=none --tag "$candidate" \
  --label "org.opencontainers.image.version=$IMAGE_VERSION" \
  --label "org.opencontainers.image.revision=$IMAGE_REVISION" \
  --label "org.opencontainers.image.source=$IMAGE_SOURCE" \
  --label "org.opencontainers.image.created=$IMAGE_CREATED" \
  --label "io.github.lestli.odins-docker.onec.version=$ONEC_VERSION" \
  --label "io.github.lestli.odins-docker.install.format=$INSTALL_FORMAT" "$tmp/context"
bash scripts/export-image.sh server "$candidate" "$tmp/release"
(cd "$tmp/release" && sha256sum --check ./*.tar.sha256)
python3 - "$tmp/release/$IMAGE_ARCHIVE_STEM.metadata.json" <<'PY'
import json
import os
import sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
assert data["tags"] == [os.environ["IMAGE_BUILD_TAG"], os.environ["IMAGE_RELEASE_TAG"]]
assert data["run_id"] == "987654" and data["run_attempt"] == 1
assert data["archive_roundtrip_verified"] is True
assert data["image_version"] == "1.0" and data["onec_version"] == "8.3.27.2130"
assert data["tags"][1] == "onec-server:1.0-1c8.3.27.2130"
PY
echo 'PASS: release alias and exact build tag survive TAR export/load'
