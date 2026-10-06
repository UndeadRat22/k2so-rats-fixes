#!/bin/sh
# E2E test for k2so-rats-fixes with the full K2SO stack as actually used in
# game (Krastorio2, Krastorio2-spaced-out, k2so-assets,
# Krastorio2-spaced-out-tweaks, nulls-k2so-tweaks,
# xy-k2so-enhancements-nulls-fork, PlanetsLib, and their dependencies).
#
# Phase A runs WITHOUT the fix mod and expects the bug to be reproduced
# (crafted biomass inherits parent spoilage, the loop never recovers).
# Phase B runs WITH the fix mod and expects fully fresh output.
#
# Usage: tests/run-e2e.sh
# Env:   FACTORIO_BIN=/path/to/factorio
#        E2E_WORK_DIR=/tmp/k2so-fixes-e2e
set -eu
MOD_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FACTORIO="${FACTORIO_BIN:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
WORK="${E2E_WORK_DIR:-/tmp/k2so-fixes-e2e}"
FACTORIO_MODS="$HOME/Library/Application Support/factorio/mods"

SCENARIO_NAME="biomass-stall"
BENCHMARK_TICKS=16000
RESULT_REL="script-output/e2e-biomass/result.json"

die() { echo "ERROR: $*" >&2; exit 1; }

[ -x "$FACTORIO" ] || die "Factorio binary not found: $FACTORIO (set FACTORIO_BIN)"

prepare_work_dir() {
  rm -rf "$WORK"
  mkdir -p "$WORK"/mods "$WORK"/saves "$WORK"/script-output "$WORK"/scenarios
  cp -R "$MOD_DIR/tests/scenario/$SCENARIO_NAME" "$WORK/scenarios/$SCENARIO_NAME"

  for f in \
    "$FACTORIO_MODS"/Krastorio2_*.zip \
    "$FACTORIO_MODS"/Krastorio2Assets_*.zip \
    "$FACTORIO_MODS"/Krastorio2MenuSimulations_*.zip \
    "$FACTORIO_MODS"/flib_*.zip \
    "$FACTORIO_MODS"/ChangeInserterDropLane_*.zip \
    "$FACTORIO_MODS"/k2so-assets_*.zip \
    "$FACTORIO_MODS"/Krastorio2-spaced-out_*.zip \
    "$FACTORIO_MODS"/Krastorio2-spaced-out-tweaks_*.zip \
    "$FACTORIO_MODS"/nulls-k2so-tweaks_*.zip \
    "$FACTORIO_MODS"/xy-k2so-enhancements-nulls-fork_*.zip \
    "$FACTORIO_MODS"/PlanetsLib_*.zip; do
    [ -f "$f" ] && ln -sfn "$f" "$WORK/mods/$(basename "$f")"
  done

  # Krastorio2-spaced-out_*.zip deliberately does NOT match
  # Krastorio2-spaced-out-tweaks (underscore vs dash).
  # nulls-k2so-tweaks + xy-k2so-enhancements-nulls-fork + PlanetsLib are
  # included to mirror the actual runtime stack this fix must survive.

  cat > "$WORK/config.ini" <<EOF
[path]
read-data=$(dirname "$(dirname "$FACTORIO")")/data
write-data=$WORK

[general]
locale=en
EOF
}

write_mod_list() {
  # base + built-ins + K2 chain; the fix mod is added in phase B.
  with_fix="$1"
  python3 - "$WORK/mods/mod-list.json" "$with_fix" <<'EOF'
import json, sys
mods = ["base", "space-age", "quality", "elevated-rails",
        "Krastorio2", "Krastorio2Assets", "Krastorio2MenuSimulations",
        "flib", "ChangeInserterDropLane", "Krastorio2-spaced-out",
        "k2so-assets", "Krastorio2-spaced-out-tweaks",
        "nulls-k2so-tweaks", "xy-k2so-enhancements-nulls-fork",
        "PlanetsLib"]
if sys.argv[2] == "yes":
    mods.append("k2so-rats-fixes")
with open(sys.argv[1], "w") as f:
    json.dump({"mods": [{"name": m, "enabled": True} for m in mods]}, f, indent=2)
EOF
}

run_game() {
  phase="$1"
  echo "--- [$phase] scenario -> map"
  "$FACTORIO" --config "$WORK/config.ini" --scenario2map "$SCENARIO_NAME" \
    --disable-audio > "$WORK/phase-$phase-scenario2map.log" 2>&1 \
    || { tail -30 "$WORK/phase-$phase-scenario2map.log"; die "[$phase] scenario2map failed"; }

  echo "--- [$phase] benchmark"
  "$FACTORIO" --config "$WORK/config.ini" \
    --benchmark "$WORK/saves/$SCENARIO_NAME.zip" \
    --benchmark-ticks "$BENCHMARK_TICKS" --disable-audio \
    > "$WORK/phase-$phase-benchmark.log" 2>&1 \
    || { tail -30 "$WORK/phase-$phase-benchmark.log"; die "[$phase] benchmark failed"; }

  [ -f "$WORK/$RESULT_REL" ] \
    || { tail -40 "$WORK/phase-$phase-benchmark.log"; die "[$phase] no result JSON produced"; }
}

print_result() {
  phase="$1"
  expected="$2"
  python3 - "$WORK/$RESULT_REL" "$expected" <<'EOF' || die "[$phase] mismatch"
import json, sys
with open(sys.argv[1]) as f:
    r = json.load(f)
print(f"  verdict:        {r['verdict']}")
print(f"  message:        {r.get('message')}")
print(f"  fix mod active: {r['fix_mod_present']}")
print(f"  recipe product: {r.get('recipe_product')}")
c1, c2 = r.get("craft1") or {}, r.get("craft2") or {}
o1, o2 = c1.get("output") or {}, c2.get("output") or {}
print(f"  craft1 output:  count={o1.get('count')} spoil_percent={o1.get('spoil_percent')} ticks_left={o1.get('ticks_left')}")
print(f"  craft2 output:  count={o2.get('count')} spoil_percent={o2.get('spoil_percent')} ticks_left={o2.get('ticks_left')}")
if r["verdict"] != sys.argv[2]:
    print(f"  EXPECTED {sys.argv[2]} -> TEST FAILED", file=sys.stderr)
    if r.get("machine_diag"):
        print(json.dumps(r["machine_diag"], indent=2))
    sys.exit(1)
EOF
}

echo "=== k2so-rats-fixes e2e ==="

echo "=== Phase A: no fix mod (expect BUG_REPRODUCED) ==="
prepare_work_dir
write_mod_list no
run_game A
print_result A BUG_REPRODUCED
echo "Phase A passed (bug reproduced)."

echo
echo "=== Phase B: with k2so-rats-fixes (expect FIXED) ==="
ln -sfn "$MOD_DIR" "$WORK/mods/k2so-rats-fixes"
write_mod_list yes
run_game B
print_result B FIXED
echo "Phase B passed (fix verified)."

echo
echo "ALL E2E PHASES PASSED (logs in $WORK)"
