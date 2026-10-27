#!/usr/bin/env bash
set -euo pipefail
value=${ONEC_USE_HW_LICENSES-0}
case $value in
  0|1) ;;
  *) echo 'ONEC_USE_HW_LICENSES must be 0 or 1' >&2; exit 1 ;;
esac
directory="${HOME:?HOME must be initialized}/.1C/1cestart"
file="$directory/1cestart.cfg"
mkdir -p "$directory"
if [[ -L $file || ( -e $file && ( ! -f $file || ! -w $file ) ) ]]; then
  echo "Runtime configuration must be a writable regular file: $file" >&2
  exit 1
fi
umask 077
decoded=$(mktemp "$directory/.1cestart-source.XXXXXXXX")
next=$(mktemp "$directory/.1cestart-next.XXXXXXXX")
trap 'rm -f "$decoded" "$next"' EXIT
source_file=$file
if [[ ! -e $source_file ]]; then
  source_file=/opt/1cv8/common/1cestart.cfg
fi
if [[ -f $source_file ]]; then
  signature=$(od -An -tx1 -N2 "$source_file" | tr -d ' \n')
  encoding=UTF-8
  case $signature in
    fffe|feff) encoding=UTF-16 ;;
    ??00) encoding=UTF-16LE ;;
  esac
  iconv -f "$encoding" -t UTF-8 "$source_file" > "$decoded"
fi
# The platform user configuration is UTF-16LE. Keep all unrelated entries,
# including repeated settings such as CommonInfoBases. Replace only this key.
printf '\377\376' > "$next"
{
  sed '1s/^\xEF\xBB\xBF//' "$decoded" |
    awk 'tolower($0) !~ /^[[:space:]]*usehwlicenses[[:space:]]*=/'
  printf '\nUseHWLicenses=%s\n' "$value"
} | iconv -f UTF-8 -t UTF-16LE >> "$next"
mv -f "$next" "$file"
