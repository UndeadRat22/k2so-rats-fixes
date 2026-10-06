# Shared helpers for k2so-rats-fixes test runners.
# Sourced by tests/run-e2e.sh (gameplay benchmark checks) and
# tests/run-proto.sh (data-stage prototype checks). Expects /bin/sh.
set -eu

MOD_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FACTORIO="${FACTORIO_BIN:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
FACTORIO_MODS="$HOME/Library/Application Support/factorio/mods"

die() { echo "ERROR: $*" >&2; exit 1; }

require_factorio() {
  [ -x "$FACTORIO" ] || die "Factorio binary not found: $FACTORIO (set FACTORIO_BIN)"
}

# Default zip set: the full K2SO stack these fixes must survive, mirroring
# the live mod list (minus third-party planet mods).
DEFAULT_MOD_GLOBS="
Krastorio2_*.zip
Krastorio2Assets_*.zip
Krastorio2MenuSimulations_*.zip
flib_*.zip
ChangeInserterDropLane_*.zip
k2so-assets_*.zip
Krastorio2-spaced-out_*.zip
Krastorio2-spaced-out-tweaks_*.zip
nulls-k2so-tweaks_*.zip
xy-k2so-enhancements-nulls-fork_*.zip
PlanetsLib_*.zip
"

# Base mod ids enabled in every test, in load-relevant order.
DEFAULT_MOD_IDS="base space-age quality elevated-rails Krastorio2 Krastorio2Assets Krastorio2MenuSimulations flib ChangeInserterDropLane Krastorio2-spaced-out k2so-assets Krastorio2-spaced-out-tweaks nulls-k2so-tweaks xy-k2so-enhancements-nulls-fork PlanetsLib"

# prepare_work_dir <work> <scenario-name>
# Builds an isolated Factorio user dir: mods/ (symlinked zips + stub mods),
# saves/, script-output/, scenarios/ + a path-mapping config.ini.
prepare_work_dir() {
  work="$1"
  scenario="$2"

  rm -rf "$work"
  mkdir -p "$work"/mods "$work"/saves "$work"/script-output "$work"/scenarios
  cp -R "$MOD_DIR/tests/scenario/$scenario" "$work/scenarios/$scenario"

  for glob in $DEFAULT_MOD_GLOBS $EXTRA_MOD_GLOBS; do
    for f in "$FACTORIO_MODS"/$glob; do
      [ -f "$f" ] && ln -sfn "$f" "$work/mods/$(basename "$f")"
    done
  done

  # Krastorio2-spaced-out_*.zip deliberately does NOT match
  # Krastorio2-spaced-out-tweaks (underscore vs dash).

  if [ -n "$STUB_DIR" ]; then
    for stub in "$STUB_DIR"/*; do
      [ -d "$stub" ] && cp -R "$stub" "$work/mods/$(basename "$stub")"
    done
  fi

  cat > "$work/config.ini" <<EOF
[path]
read-data=$(dirname "$(dirname "$FACTORIO")")/data
write-data=$work

[general]
locale=en
EOF
}

# write_mod_list <work> <mod-ids...>
# mod-list.json always contains the default chain plus any ids passed in.
write_mod_list() {
  work="$1"; shift
  python3 - "$work/mods/mod-list.json" $DEFAULT_MOD_IDS "$@" <<'EOF'
import json, sys
with open(sys.argv[1], "w") as f:
    json.dump({"mods": [{"name": m, "enabled": True} for m in sys.argv[2:]]}, f, indent=2)
EOF
}

# run_scenario2map <phase> <work> <scenario>
# Full data-stage load; logs land in <work>/phase-<phase>-scenario2map.log.
run_scenario2map() {
  phase="$1"; work="$2"; scenario="$3"
  echo "--- [$phase] scenario -> map"
  "$FACTORIO" --config "$work/config.ini" --scenario2map "$scenario" \
    --disable-audio > "$work/phase-$phase-scenario2map.log" 2>&1 \
    || { tail -30 "$work/phase-$phase-scenario2map.log"; die "[$phase] scenario2map failed"; }
}

# run_benchmark <phase> <work> <scenario> <ticks>
# Drives the actual gameplay checks of a scenario (biomass-style tests).
run_benchmark() {
  phase="$1"; work="$2"; scenario="$3"; ticks="$4"
  echo "--- [$phase] benchmark"
  "$FACTORIO" --config "$work/config.ini" \
    --benchmark "$work/saves/$scenario.zip" \
    --benchmark-ticks "$ticks" --disable-audio \
    > "$work/phase-$phase-benchmark.log" 2>&1 \
    || { tail -30 "$work/phase-$phase-benchmark.log"; die "[$phase] benchmark failed"; }
}

# check_log_patterns <phase> <log-file> <patterns-file>
# Every ERE line in the patterns file must match something in the log.
check_log_patterns() {
  phase="$1"; log_file="$2"; patterns_file="$3"
  line_no=0
  while IFS= read -r pattern || [ -n "$pattern" ]; do
    line_no=$((line_no + 1))
    [ -z "$pattern" ] && continue
    case "$pattern" in \#*) continue ;; esac
    grep -E -- "$pattern" "$log_file" > /dev/null 2>&1 \
      || die "[$phase] expected log pattern not found ($patterns_file:$line_no): $pattern"
  done < "$patterns_file"
}

# Absent-unless-set defaults for parameters consumed by prepare_work_dir.
EXTRA_MOD_GLOBS="${EXTRA_MOD_GLOBS:-}"
STUB_DIR="${STUB_DIR:-}"
