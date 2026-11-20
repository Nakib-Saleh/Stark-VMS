# Quality-gate checks for scripts/quality-ratchet.sh.
# /stack copies this file to scripts/quality-checks.sh and keeps only the lines for the
# project's stack. Sourced by bash — plain variable assignments only.
#
# CHECKS     space-separated check names (letters, digits, underscore)
# <name>_cmd    command to run (output is captured, exit code is inspected)
# <name>_match  extended regex matching EXACTLY ONE line per issue in that output
# BUILD_CMD  optional; run by `quality-ratchet.sh --ci` before the checks
#
# Verify each regex once against real output: a regex that never matches makes the
# gate pass forever. (The ratchet fails a check that exits non-zero with 0 matches.)

CHECKS="typecheck lint"
BUILD_CMD=""

# ── TypeScript / JavaScript ────────────────────────────────────────────────
typecheck_cmd='npx tsc --noEmit'
typecheck_match='error TS[0-9]+'
lint_cmd='npx eslint . --format unix'
lint_match=':[0-9]+:[0-9]+: '
# BUILD_CMD='npm run build'

# ── Python ─────────────────────────────────────────────────────────────────
# typecheck_cmd='mypy .'                      ; typecheck_match=': error: '
# typecheck_cmd='pyright'                     ; typecheck_match=' - error: '
# lint_cmd='ruff check . --output-format concise' ; lint_match=':[0-9]+:[0-9]+: '

# ── Go ─────────────────────────────────────────────────────────────────────
# typecheck_cmd='go vet ./...'                ; typecheck_match='\.go:[0-9]+:[0-9]+: '
# lint_cmd='golangci-lint run'                ; lint_match='\.go:[0-9]+:[0-9]+: '
# BUILD_CMD='go build ./...'

# ── Rust ───────────────────────────────────────────────────────────────────
# typecheck_cmd='cargo check --message-format short' ; typecheck_match=': error'
# lint_cmd='cargo clippy --message-format short'      ; lint_match=': (warning|error)'

# ── PHP ────────────────────────────────────────────────────────────────────
# typecheck_cmd='vendor/bin/phpstan analyse --error-format=raw --no-progress' ; typecheck_match=':[0-9]+:'

# ── Dart / Flutter ─────────────────────────────────────────────────────────
# CHECKS="analyze"
# analyze_cmd='dart analyze'                  ; analyze_match='^ *(error|warning|info) - '

# ── C# / .NET ──────────────────────────────────────────────────────────────
# CHECKS="build"
# build_cmd='dotnet build --nologo -clp:NoSummary' ; build_match=': (error|warning) [A-Z]+[0-9]+'
