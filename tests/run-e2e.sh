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
. "$(dirname "$0")/lib.sh"

WORK="${E2E_WORK_DIR:-/tmp/k2so-fixes-e2e}"

SCENARIO_NAME="biomass-stall"
BENCHMARK_TICKS=16000
RESULT_REL="script-output/e2e-biomass/result.json"

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

require_factorio

echo "=== k2so-rats-fixes e2e ==="

echo "=== Phase A: no fix mod (expect BUG_REPRODUCED) ==="
prepare_work_dir "$WORK" "$SCENARIO_NAME"
write_mod_list "$WORK"
run_scenario2map A "$WORK" "$SCENARIO_NAME"
run_benchmark A "$WORK" "$SCENARIO_NAME" "$BENCHMARK_TICKS"
[ -f "$WORK/$RESULT_REL" ] \
  || { tail -40 "$WORK/phase-A-benchmark.log"; die "[A] no result JSON produced"; }
print_result A BUG_REPRODUCED
echo "Phase A passed (bug reproduced)."

echo
echo "=== Phase B: with k2so-rats-fixes (expect FIXED) ==="
ln -sfn "$MOD_DIR" "$WORK/mods/k2so-rats-fixes"
write_mod_list "$WORK" k2so-rats-fixes
run_scenario2map B "$WORK" "$SCENARIO_NAME"
run_benchmark B "$WORK" "$SCENARIO_NAME" "$BENCHMARK_TICKS"
[ -f "$WORK/$RESULT_REL" ] \
  || { tail -40 "$WORK/phase-B-benchmark.log"; die "[B] no result JSON produced"; }
print_result B FIXED
echo "Phase B passed (fix verified)."

echo
echo "ALL E2E PHASES PASSED (logs in $WORK)"
