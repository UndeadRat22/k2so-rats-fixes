#!/bin/sh
# Verifies every patch under patches/upstream/ applies cleanly against the
# matching installed mod zip. Run after bumping any observed mod version.
#
# Usage: tests/check-upstream-patches.sh
set -eu
MOD_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PATCH_ROOT="$MOD_DIR/patches/upstream"
MODS_DIR="${FACTORIO_MODS_DIR:-$HOME/Library/Application Support/factorio/mods}"

die() { echo "ERROR: $*" >&2; exit 1; }

zip_for_mod() {
  case "$1" in
    xy-k2so-enhancements-nulls-fork) echo "xy-k2so-enhancements-nulls-fork_*.zip" ;;
    *) echo "$1_*.zip" ;;
  esac
}

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

checked=0
for mod_dir in "$PATCH_ROOT"/*/; do
  mod_name="$(basename "$mod_dir")"
  glob="$(zip_for_mod "$mod_name")"
  zip_path=""
  for candidate in "$MODS_DIR"/$glob; do
    [ -f "$candidate" ] && zip_path="$candidate"
  done
  [ -n "$zip_path" ] || die "no installed zip found for $mod_name (glob $glob)"

  extract="$work/$mod_name"
  mkdir -p "$extract"
  unzip -q "$zip_path" -d "$extract"
  inner="$(find "$extract" -mindepth 1 -maxdepth 1 -type d | head -1)"
  [ -n "$inner" ] || die "unexpected zip layout for $mod_name"

  for patch_file in "$mod_dir"/*.patch; do
    (cd "$inner" && patch -s --dry-run -p1 < "$patch_file") \
      || die "patch fails to apply: $patch_file (against $(basename "$zip_path"))"
    # Re-extract so the next patch in the same mod applies to pristine files.
    rm -rf "$inner"
    unzip -q "$zip_path" -d "$extract"
    inner="$(find "$extract" -mindepth 1 -maxdepth 1 -type d | head -1)"
    echo "OK: $mod_name/$(basename "$patch_file")"
    checked=$((checked + 1))
  done
done

echo "All $checked upstream patches apply cleanly."
