#!/usr/bin/env bash
set -euo pipefail
set +x
# Фильтры каталога 1С содержат кириллицу.
export LANG=C.UTF-8 LC_ALL=C.UTF-8
format=$1 image=$2 version=$3 output=$4
http_timeout=120
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
for index in "${!filters[@]}"; do
  filter=${filters[$index]}
  started=$SECONDS
  # Полный лог YARD может содержать адреса с токенами и данные авторизации.
  if yard releases --user "$(cat /run/secrets/onec_username)" \
    --pwd "$(cat /run/secrets/onec_password)" --timeout "$http_timeout" get \
    --app-filter 'Технологическая платформа.*8\.3' \
    --version-filter "^${version//./\\.}$" --distr-filter "$filter" \
    --download-existing --download-limit 1 --path "$output" >"$tmp/log" 2>&1; then
    :
  else
    status=$?
    printf '1C download failed: image=%s, distribution=%s/%s, exit=%s, elapsed=%ss, HTTP timeout=%ss\n' \
      "$image" "$((index + 1))" "${#filters[@]}" "$status" "$((SECONDS - started))" "$http_timeout" >&2
    python3 "$(dirname "$0")/download-diagnostic.py" "$tmp/log" >&2
    exit 1
  fi
  python3 "$(dirname "$0")/download-diagnostic.py" "$tmp/log"
  printf 'Downloaded distribution files: deb=%s run=%s archives=%s\n' \
    "$(find "$output" -type f -name '*.deb' -printf . | wc -c)" \
    "$(find "$output" -type f -name '*.run' -printf . | wc -c)" \
    "$(find "$output" -type f \( -name '*.gz' -o -name '*.zip' -o -name '*.xz' \) -printf . | wc -c)"
done
if [[ -z $(find "$output" -type f -print -quit) ]]; then
  if yard releases --user "$(cat /run/secrets/onec_username)" \
    --pwd "$(cat /run/secrets/onec_password)" list \
    --app-filter 'Технологическая платформа' --version-filter "^${version//./\\.}$" \
    --output-file "$tmp/catalog.json" >"$tmp/list-log" 2>&1; then
    python3 "$(dirname "$0")/catalog-diagnostic.py" "$tmp/catalog.json"
  else
    python3 "$(dirname "$0")/download-diagnostic.py" "$tmp/list-log"
  fi
  echo '1C portal returned no distribution files' >&2
  exit 1
fi
