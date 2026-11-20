#!/usr/bin/env bash
# Baseline-aware quality gate. Fails only on failures NEW since the recorded baseline.
# New project: baseline is 0, so this is a strict gate.
# Existing project: green from day one, still catches regressions.
#
# Stack-agnostic: the checks live in scripts/quality-checks.sh (written by /stack).
#   bash scripts/quality-ratchet.sh              run the gate
#   bash scripts/quality-ratchet.sh --baseline   record current counts as the baseline
#   bash scripts/quality-ratchet.sh --ci         run BUILD_CMD first, then the gate
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

CONFIG="scripts/quality-checks.sh"
BASELINE_FILE=".quality-baseline.json"
MODE="${1:-}"

if [ ! -f "$CONFIG" ]; then
  echo "Gate not configured: no $CONFIG. Run /stack (or copy scripts/quality-checks.example.sh)."
  exit 1
fi
# shellcheck source=/dev/null
. "$CONFIG"
if [ -z "${CHECKS:-}" ]; then
  echo "Gate not configured: CHECKS is empty in $CONFIG."
  exit 1
fi

if [ "$MODE" = "--ci" ] && [ -n "${BUILD_CMD:-}" ]; then
  echo "Build: $BUILD_CMD"
  bash -c "$BUILD_CMD" || { echo "FAIL build"; exit 1; }
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
FAIL=0

# Run every check once; store its output and issue count.
for c in $CHECKS; do
  cmd_var="${c}_cmd"; match_var="${c}_match"
  cmd="${!cmd_var:-}"; match="${!match_var:-}"
  if [ -z "$cmd" ] || [ -z "$match" ]; then
    echo "FAIL $c: ${c}_cmd and ${c}_match must both be set in $CONFIG"
    FAIL=1; continue
  fi
  bash -c "$cmd" > "$TMP_DIR/$c.out" 2>&1
  rc=$?
  n=$(grep -cE "$match" "$TMP_DIR/$c.out" || true)
  printf -v "now_$c" '%s' "$n"
  if [ "$rc" -eq 127 ]; then
    echo "FAIL $c: tool not found — install it or fix ${c}_cmd"; FAIL=1
  elif [ "$rc" -ne 0 ] && [ "$n" -eq 0 ]; then
    # Non-zero exit but zero matched issues: the regex is wrong or the tool crashed.
    echo "FAIL $c: exited $rc but ${c}_match counted 0 issues — check the regex"
    head -10 "$TMP_DIR/$c.out"; FAIL=1
  fi
done

write_baseline() {
  { echo "{"; local first=1
    for c in $CHECKS; do
      v="now_$c"; [ $first -eq 1 ] || echo ","; first=0
      printf '  "%s": %s' "$c" "${!v:-0}"
    done; echo; echo "}"; } > "$BASELINE_FILE"
}

if [ "$MODE" = "--baseline" ]; then
  [ "$FAIL" -eq 0 ] || { echo "Baseline NOT recorded — fix the check errors above first."; exit 1; }
  write_baseline
  echo "Baseline recorded:"; cat "$BASELINE_FILE"
  exit 0
fi

if [ ! -f "$BASELINE_FILE" ]; then
  echo "No baseline. Run: bash scripts/quality-ratchet.sh --baseline"
  exit 1
fi

LOWER=0; SUMMARY=""
for c in $CHECKS; do
  v="now_$c"; now="${!v:-}"
  [ -n "$now" ] || continue
  base=$(grep -oE "\"$c\"[[:space:]]*:[[:space:]]*[0-9]+" "$BASELINE_FILE" | grep -oE '[0-9]+$')
  if [ -z "$base" ]; then
    echo "note: no baseline for '$c' — treating as 0 (strict). Re-run --baseline if intended."
    base=0
  fi
  SUMMARY="$SUMMARY $c $now/$base,"
  if [ "$now" -gt "$base" ]; then
    m="${c}_match"
    echo "FAIL $c: $now (baseline $base) — $((now - base)) new"
    grep -E "${!m}" "$TMP_DIR/$c.out" | head -20
    FAIL=1
  elif [ "$now" -lt "$base" ]; then
    LOWER=1
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "PASS —${SUMMARY%,}"
  # Ratchet down automatically when the code improves.
  if [ "$LOWER" -eq 1 ]; then write_baseline; echo "Baseline lowered."; fi
fi
exit $FAIL
