#!/usr/bin/env bash
set -euo pipefail
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/existing"
export GITHUB_ACTIONS=true GITHUB_RUN_ID=123456 GITHUB_RUN_ATTEMPT=1
export GITHUB_SHA=0123456789012345678901234567890123456789
export GITHUB_REF=refs/heads/main GITHUB_REF_TYPE=branch GITHUB_EVENT_NAME=push
export DOCKER_MUTATION_MARKER="$tmp/mutated"
cat > "$tmp/bin/docker" <<'SH'
#!/usr/bin/env bash
if [[ $* == 'image inspect candidate' ]]; then
  printf '[{"Os":"linux","Architecture":"amd64","Config":{"Labels":{}}}]\n'
else
  touch "$DOCKER_MUTATION_MARKER"
  exit 7
fi
SH
chmod +x "$tmp/bin/docker"
export PATH="$tmp/bin:$PATH"
if bash scripts/export-image.sh server candidate "$tmp/existing" >"$tmp/error" 2>&1; then
  echo 'FAIL: existing output accepted' >&2; exit 1
fi
grep -q 'must not already exist' "$tmp/error"
[[ ! -e $DOCKER_MUTATION_MARKER ]]
if bash scripts/export-image.sh server candidate "$tmp/rejected" >"$tmp/error" 2>&1; then
  echo 'FAIL: unlabeled image accepted' >&2; exit 1
fi
grep -q 'Incorrect image label' "$tmp/error"
[[ ! -e $DOCKER_MUTATION_MARKER ]]
[[ -z $(find "$tmp/rejected" -type f -print -quit) ]]
echo 'PASS: export rejects wrong provenance and existing output before mutation'
