#!/bin/sh
# Generic data-stage ("prototype") e2e runner for one named fix.
#
# Each directory under tests/proto/<fix>/ describes a check:
#   env.sh           (optional)  sets EXTRA_MOD_GLOBS (extra zips to link)
#   assert-mod/      a zzz-* mod whose data-final-fixes logs E2E_CHECK markers
#   stubs/<mod>/     (optional) fabricated mods (e.g. a fake "rubia") that put
#                    the dependents' buggy code paths on realistic inputs
#   expected-A.txt   ERE patterns that must appear in the Phase A log
#   expected-B.txt   ERE patterns that must appear in the Phase B log
#
# Phase A runs the real stack (+ stubs) WITHOUT k2so-rats-fixes and must show
# the bug; phase B adds the fix mod and must show the corrected state.
# Data-stage loading happens as part of --scenario2map, so no benchmark is
# needed; the assert mod's log() lines land in the scenario2map log.
#
# Usage: tests/run-proto.sh <fix-name> | tests/run-proto.sh --all
# Env:   FACTORIO_BIN, PROTO_WORK_BASE=/tmp/k2so-proto-e2e
. "$(dirname "$0")/lib.sh"

SCENARIO_NAME="proto-check"

run_one() {
  fix="$1"
  fix_dir="$MOD_DIR/tests/proto/$fix"
  WORK="${PROTO_WORK_BASE:-/tmp/k2so-proto-e2e}/$fix"

  [ -d "$fix_dir" ] || die "unknown fix test: $fix (no $fix_dir)"
  [ -d "$fix_dir/assert-mod" ] || die "missing assert-mod in $fix_dir"

  EXTRA_MOD_GLOBS=""
  STUB_DIR=""
  ASSERT_MOD_ID=""
  if [ -f "$fix_dir/env.sh" ]; then . "$fix_dir/env.sh"; fi
  if [ -d "$fix_dir/stubs" ]; then STUB_DIR="$fix_dir/stubs"; fi
  for d in "$fix_dir"/assert-mod/*/; do
    [ -d "$d" ] && ASSERT_MOD_ID="$(basename "$d")"
  done
  [ -n "$ASSERT_MOD_ID" ] || die "no assert mod directory under $fix_dir/assert-mod/"

  require_factorio

  stub_ids=""
  if [ -n "$STUB_DIR" ]; then
    for d in "$STUB_DIR"/*; do
      [ -d "$d" ] && stub_ids="$stub_ids $(basename "$d")"
    done
  fi

  echo
  echo "=== [proto:$fix] Phase A: no fix mod (expect bug) ==="
  prepare_work_dir "$WORK" "$SCENARIO_NAME"
  cp -R "$fix_dir"/assert-mod/* "$WORK/mods/" 2>/dev/null || true
  write_mod_list "$WORK" "$ASSERT_MOD_ID" $stub_ids
  run_scenario2map A "$WORK" "$SCENARIO_NAME"
  check_log_patterns A "$WORK/phase-A-scenario2map.log" "$fix_dir/expected-A.txt"
  echo "Phase A matched expected bug state."

  echo "=== [proto:$fix] Phase B: with k2so-rats-fixes (expect fixed) ==="
  ln -sfn "$MOD_DIR" "$WORK/mods/k2so-rats-fixes"
  write_mod_list "$WORK" "$ASSERT_MOD_ID" $stub_ids k2so-rats-fixes
  run_scenario2map B "$WORK" "$SCENARIO_NAME"
  check_log_patterns B "$WORK/phase-B-scenario2map.log" "$fix_dir/expected-B.txt"
  echo "Phase B matched fixed state."

  echo "--- [proto:$fix] PASSED"
}

if [ "${1:-}" = "--all" ]; then
  for d in "$MOD_DIR/tests/proto"/*/; do
    [ -d "$d" ] && run_one "$(basename "$d")"
  done
  echo
  echo "ALL PROTO CHECKS PASSED"
elif [ -n "${1:-}" ]; then
  run_one "$1"
else
  die "usage: $0 <fix-name | --all>"
fi
