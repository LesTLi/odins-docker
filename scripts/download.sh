#!/usr/bin/env bash
set -euo pipefail
set +x
# Mono must decode Cyrillic command-line filters as UTF-8 in this RUN too.
export LANG=C.UTF-8 LC_ALL=C.UTF-8
format=$1 image=$2 version=$3 output=$4
[[ -s /run/secrets/onec_username && -s /run/secrets/onec_password ]] || {
  echo 'Download requires ONEC_USERNAME and ONEC_PASSWORD BuildKit secrets' >&2; exit 1;
}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$output"
filters=('Сервер 1С:Предприятия \(64-bit\) для DEB-based Linux-систем$')
if [[ $format == run ]]; then
  filters=('Технологическая платформа 1С:Предприятия \(64-bit\) для Linux$')
elif [[ $image == onec-test ]]; then
  filters+=('Клиент 1С:Предприятия \(64-bit\) для DEB-based Linux-систем$')
fi
for filter in "${filters[@]}"; do
  # Vendor CLI may print authentication details on failure: keep output ephemeral.
  if ! yard releases --user "$(cat /run/secrets/onec_username)" \
    --pwd "$(cat /run/secrets/onec_password)" get \
    --app-filter 'Технологическая платформа.*8\.3' \
    --version-filter "^${version//./\\.}$" --distr-filter "$filter" \
    --download-existing --download-limit 1 --path "$output" >"$tmp/log" 2>&1; then
    echo '1C download failed; check account access, version and portal availability' >&2
    python3 "$(dirname "$0")/download-diagnostic.py" "$tmp/log" >&2
    exit 1
  fi
  python3 "$(dirname "$0")/download-diagnostic.py" "$tmp/log"
  printf 'Downloaded distribution files: deb=%s run=%s archives=%s\n' \
    "$(find "$output" -type f -name '*.deb' -printf . | wc -c)" \
    "$(find "$output" -type f -name '*.run' -printf . | wc -c)" \
    "$(find "$output" -type f \( -name '*.gz' -o -name '*.zip' -o -name '*.xz' \) -printf . | wc -c)"
done
