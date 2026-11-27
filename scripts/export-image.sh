#!/usr/bin/env bash
set -euo pipefail
image=${1:?image kind} input=${2:?tested image tag} output=${3:?artifact directory}
# shellcheck source=scripts/image-metadata.sh
source "$(dirname "$0")/image-metadata.sh"
init_image_metadata "$image"
[[ ${GITHUB_ACTIONS:-} == true ]] || { echo 'Artifact export requires Actions build identity' >&2; exit 1; }
[[ ! -e $output ]] || { echo 'Artifact output must not already exist' >&2; exit 1; }
mkdir -p "$output"
output=$(cd "$output" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
docker image inspect "$input" > "$tmp/inspect.json"
# Проверяем метки кандидата перед назначением тега и экспортом.
python3 - "$tmp/inspect.json" <<'PY'
import json
import os
import sys

image = json.load(open(sys.argv[1], encoding="utf-8"))[0]
assert image["Os"] == "linux" and image["Architecture"] == "amd64", "Wrong platform"
expected = {
    "org.opencontainers.image.version": os.environ["IMAGE_VERSION"],
    "org.opencontainers.image.revision": os.environ["IMAGE_REVISION"],
    "org.opencontainers.image.source": os.environ["IMAGE_SOURCE"],
    "org.opencontainers.image.created": os.environ["IMAGE_CREATED"],
    "io.github.lestli.odins-docker.onec.version": os.environ["ONEC_VERSION"],
    "io.github.lestli.odins-docker.install.format": os.environ["INSTALL_FORMAT"],
}
for key, value in expected.items():
    assert image["Config"]["Labels"].get(key) == value, f"Incorrect image label: {key}"
PY
original_id=$(docker image inspect -f '{{.Id}}' "$input")
archive_tag=${IMAGE_RELEASE_TAG:-$IMAGE_BUILD_TAG}
if docker image inspect "$archive_tag" >/dev/null 2>&1; then
  echo 'Refusing to replace an existing final tag' >&2; exit 1
fi
docker tag "$input" "$archive_tag"
archive="$output/$IMAGE_ARCHIVE_STEM.tar"
docker image save --output "$archive.partial" "$archive_tag"
mv "$archive.partial" "$archive"
(cd "$output" && sha256sum "$IMAGE_ARCHIVE_STEM.tar" > "$IMAGE_ARCHIVE_STEM.tar.sha256")
# Удаляем тег перед загрузкой, чтобы проверить его восстановление и ID образа.
docker image rm "$archive_tag" >/dev/null
docker image load --input "$archive"
[[ $(docker image inspect -f '{{.Id}}' "$archive_tag") == "$original_id" ]]
docker image inspect "$archive_tag" > "$tmp/restored.json"
python3 - "$tmp/inspect.json" "$tmp/restored.json" "$output/$IMAGE_ARCHIVE_STEM.metadata.json" "$archive.sha256" "$archive_tag" <<'PY'
import json
import os
import pathlib
import sys

before, after = [json.load(open(p, encoding="utf-8"))[0] for p in sys.argv[1:3]]
assert before["Config"]["Labels"] == after["Config"]["Labels"], "Labels changed after load"
metadata = {
    "schema_version": 1,
    "tags": [sys.argv[5]],
    "image_version": os.environ["IMAGE_VERSION"],
    "onec_version": os.environ["ONEC_VERSION"],
    "install_format": os.environ["INSTALL_FORMAT"],
    "distribution_source": "local",
    "tested_sources": ["download", "local"],
    "platform": "linux/amd64",
    "git_revision": os.environ["IMAGE_REVISION"],
    "source": os.environ["IMAGE_SOURCE"],
    "created": os.environ["IMAGE_CREATED"],
    "run_id": os.environ["GITHUB_RUN_ID"],
    "run_attempt": int(os.environ["GITHUB_RUN_ATTEMPT"]),
    "image_id": after["Id"],
    "archive_sha256": pathlib.Path(sys.argv[4]).read_text().split()[0],
    "archive_roundtrip_verified": True,
}
pathlib.Path(sys.argv[3]).write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
if [[ -n ${GITHUB_OUTPUT:-} ]]; then
  printf 'artifact_name=%s\nartifact_path=%s\n' "$IMAGE_ARCHIVE_STEM" "$output" >> "$GITHUB_OUTPUT"
fi
printf 'PASS: TAR save/load identity and labels: %s\n' "$archive_tag"
# Обратные кавычки нужны для разметки Markdown.
# shellcheck disable=SC2016
printf '\n### Downloadable image\nTag: `%s`\nArchive: `%s.tar`\nSHA256 and metadata JSON included. Save/load verified.\n' \
  "$archive_tag" "$IMAGE_ARCHIVE_STEM" >> "$GITHUB_STEP_SUMMARY"
