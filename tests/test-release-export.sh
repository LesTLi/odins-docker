#!/usr/bin/env bash
set -euo pipefail
tmp=$(mktemp -d)
export IMAGE_VERSION=1.0 ONEC_VERSION=8.3.27.2130 INSTALL_FORMAT=${2:-deb}
export GITHUB_ACTIONS=true GITHUB_RUN_ID=987654 GITHUB_RUN_ATTEMPT=1
export GITHUB_SHA=0123456789012345678901234567890123456789
export GITHUB_REF=refs/tags/v1.0 GITHUB_REF_TYPE=tag GITHUB_EVENT_NAME=${1:-push}
export GITHUB_OUTPUT="$tmp/outputs" GITHUB_STEP_SUMMARY="$tmp/summary"
# shellcheck source=scripts/image-metadata.sh
source scripts/image-metadata.sh
kind=${3:-server}
init_image_metadata "$kind"
repository=onec-server
[[ $kind != onec-test ]] || repository=onec-test
expected_tag="$repository:1.0-1c8.3.27.2130"
expected_stem="${expected_tag/:/_}"
[[ $IMAGE_ARCHIVE_STEM == "$expected_stem" ]]
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
bash scripts/export-image.sh "$kind" "$candidate" "$tmp/release"
docker image inspect "$expected_tag" >/dev/null
if docker image inspect "$expected_tag-b987654" >/dev/null 2>&1; then
  echo "Релизный TAR восстановил тег сборки $expected_tag-b987654" >&2
  exit 1
fi
(cd "$tmp/release" && sha256sum --check ./*.tar.sha256)
grep -Fx "artifact_name=$expected_stem" "$GITHUB_OUTPUT"
[[ $(find "$tmp/release" -maxdepth 1 -type f | wc -l) == 3 ]]
for extension in tar tar.sha256 metadata.json; do
  test -s "$tmp/release/$expected_stem.$extension"
done
python3 - "$tmp/release/$expected_stem.metadata.json" "$expected_tag" <<'PY'
import json
import os
import sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
assert data["tags"] == [sys.argv[2]]
assert data["run_id"] == "987654" and data["run_attempt"] == 1
assert data["archive_roundtrip_verified"] is True
assert data["image_version"] == "1.0" and data["onec_version"] == "8.3.27.2130"
assert data["install_format"] == os.environ["INSTALL_FORMAT"]
PY
printf 'PASS: TAR восстанавливает только %s\n' "$expected_tag"
