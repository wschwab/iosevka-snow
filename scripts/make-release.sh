#!/usr/bin/env bash
# Build Iosevka Snow and pack it into a deterministic release tarball.
#
# Determinism matters because consumers pin the archive's hash: entries are
# sorted, mtimes and ownership zeroed, and gzip's own timestamp suppressed, so
# rebuilding from the same inputs reproduces the same bytes and therefore the
# same hash.
set -euo pipefail

version="${1-}"
if [[ -z "$version" ]]; then
  echo "usage: make-release.sh <version>   # e.g. 34.4.0" >&2
  exit 64
fi

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$here/dist"
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

echo "==> building Iosevka Snow $version from default.nix (expect CPU-minutes)"
font="$(nix build --no-link --print-out-paths \
  --expr "with import <nixpkgs> {}; callPackage $here/default.nix {}")"

echo "==> staging fonts and license from $font"
install -d "$stage/share/fonts/truetype"
install -m 0644 "$font"/share/fonts/truetype/*.ttf "$stage/share/fonts/truetype/"
install -m 0644 "$here/LICENSE-Iosevka-OFL-1.1.md" "$stage/"

archive="$out/iosevka-snow-$version-ttf.tar.gz"
install -d "$out"

# --sort=name and the zeroed metadata are what make this reproducible; gzip -n
# suppresses the embedded timestamp that would otherwise change every run.
tar --create \
  --directory "$stage" \
  --sort=name \
  --mtime=@0 \
  --owner=0 --group=0 --numeric-owner \
  --mode='go-w' \
  --format=gnu \
  . | gzip -9 -n > "$archive"

echo "==> $archive"
echo "    sha256 (file)     : $(sha256sum "$archive" | cut -d' ' -f1)"
echo "    hash   (unpacked) : $(nix hash path --type sha256 --sri "$stage")"
echo
echo "The unpacked hash is what fetchzip pins; the file hash documents the asset."
