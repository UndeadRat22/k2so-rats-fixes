#!/bin/sh
# E2E test: k2-greenhouse-plus sand/glass unification, physical flow.
#
# Runs the full K2SO stack plus the real k2-greenhouse-plus. Phase A runs
# WITHOUT the fix mod and expects the duplicate private chain to be live
# (the building recipe demands k2gp-glass, recycling returns k2gp-glass).
# Phase B runs WITH k2so-rats-fixes and expects K2's chain (kr-glass both
# ways, no k2gp items leaking).
#
# Usage: tests/run-e2e-greenhouse.sh
# Env:   FACTORIO_BIN=/path/to/factorio
#        E2E_WORK_DIR=/tmp/k2so-greenhouse-e2e
. "$(dirname "$0")/lib.sh"

WORK="${E2E_WORK_DIR:-/tmp/k2so-greenhouse-e2e}"

SCENARIO_NAME="greenhouse-craft-recycle"
BENCHMARK_TICKS=8000
RESULT_REL="script-output/e2e-greenhouse/result.json"

# The fix's subject mod; the K2SO stack comes from the default set.
EXTRA_MOD_GLOBS="k2-greenhouse-plus_*.zip"

print_result() {
  phase="$1"
  expected="$2"
  python3 - "$WORK/$RESULT_REL" "$expected" <<'EOF' || die "[$phase] mismatch"
import json, sys
with open(sys.argv[1]) as f:
    r = json.load(f)
print(f"  verdict:         {r['verdict']}")
print(f"  message:         {r.get('message')}")
print(f"  fix mod active:  {r['fix_mod_present']}")
print(f"  glass (recipe):  {r.get('glass_ingredient')}")
print(f"  glass consumed:  {r.get('glass_consumed')}")
print(f"  crafted:         {r.get('crafted')}")
print(f"  recycler output: {r.get('recycler_outputs')}")
print(f"  k2gp leak:       {r.get('k2gp_leak')}")
if r.get("recycler_diag"):
    print(f"  recycler diag:   {r['recycler_diag']}")
if r["verdict"] != sys.argv[2]:
    print(f"  EXPECTED {sys.argv[2]} -> TEST FAILED", file=sys.stderr)
    sys.exit(1)
EOF
}

require_factorio

echo "=== k2so-rats-fixes greenhouse e2e ==="

echo "=== Phase A: no fix mod (expect BUG_REPRODUCED) ==="
prepare_work_dir "$WORK" "$SCENARIO_NAME"
write_mod_list "$WORK" k2-greenhouse-plus
run_scenario2map A "$WORK" "$SCENARIO_NAME"
run_benchmark A "$WORK" "$SCENARIO_NAME" "$BENCHMARK_TICKS"
[ -f "$WORK/$RESULT_REL" ] \
  || { tail -40 "$WORK/phase-A-benchmark.log"; die "[A] no result JSON produced"; }
print_result A BUG_REPRODUCED
echo "Phase A passed (bug reproduced)."

echo
echo "=== Phase B: with k2so-rats-fixes (expect FIXED) ==="
ln -sfn "$MOD_DIR" "$WORK/mods/k2so-rats-fixes"
write_mod_list "$WORK" k2-greenhouse-plus k2so-rats-fixes
run_scenario2map B "$WORK" "$SCENARIO_NAME"
run_benchmark B "$WORK" "$SCENARIO_NAME" "$BENCHMARK_TICKS"
[ -f "$WORK/$RESULT_REL" ] \
  || { tail -40 "$WORK/phase-B-benchmark.log"; die "[B] no result JSON produced"; }
print_result B FIXED
echo "Phase B passed (fix verified)."

echo
echo "ALL GREENHOUSE E2E PHASES PASSED (logs in $WORK)"
