#!/usr/bin/env bash
set -euo pipefail
die() { echo "Distribution: $*" >&2; exit 1; }
[[ $# == 6 ]] || die 'expected SOURCE FORMAT IMAGE VERSION INPUT OUTPUT'
source_kind=$1 format=$2 image=$3 version=$4 input=$5 output=$6
[[ $source_kind == local || $source_kind == download ]] || die 'invalid source'
[[ $format == deb || $format == run ]] || die 'invalid format'
[[ $image == server || $image == onec-test ]] || die 'invalid image'
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || die 'invalid version'
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
if [[ $source_kind == download ]]; then
  bash "$(dirname "$0")/download.sh" "$format" "$image" "$version" "$tmp/download"
  input="$tmp/download"
fi
[[ -d $input ]] || die 'input directory does not exist'
mkdir -p "$tmp/unpacked" "$tmp/selected" "$output"
[[ -z $(find "$output" -mindepth 1 -print -quit) ]] || die 'output must be empty'
# Extract only regular distribution files, never links or arbitrary archive paths.
python3 "$(dirname "$0")/extract.py" "$input" "$tmp/unpacked"
if [[ $format == run ]]; then
  mapfile -d '' files < <(find "$tmp/unpacked" -type f -name "setup-full-$version-x86_64.run" -print0)
  [[ ${#files[@]} == 1 ]] || die 'expected exactly one matching full RUN installer'
  cp "${files[0]}" "$tmp/selected/"
else
  components=(common server)
  [[ $image != onec-test ]] || components+=(client)
  for component in "${components[@]}"; do
    selected=()
    while IFS= read -r -d '' file; do
      name=$(dpkg-deb -f "$file" Package) || die 'invalid DEB'
      [[ $name == "1c-enterprise-$version-$component" ]] || continue
      [[ $(dpkg-deb -f "$file" Architecture) == amd64 ]] || die 'wrong package architecture'
      [[ $(dpkg-deb -f "$file" Version) == "${version%.*}-${version##*.}" ]] || die 'wrong package version'
      selected+=("$file")
    done < <(find "$tmp/unpacked" -type f -name '*.deb' -print0)
    [[ ${#selected[@]} == 1 ]] || die "expected exactly one $component package for $version"
    cp "${selected[0]}" "$tmp/selected/"
  done
fi
cp "$tmp/selected/"* "$output/"
