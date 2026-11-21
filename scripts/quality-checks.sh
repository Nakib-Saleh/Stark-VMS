# Quality-gate checks for scripts/quality-ratchet.sh (Spring Boot backend + Flutter Web frontend).
# Sourced by bash — plain variable assignments only.
# gradlew is not committed as executable, so it is invoked with `bash gradlew` (works on Linux CI and Git Bash).

CHECKS="backend_compile backend_test frontend_analyze frontend_test"
# The web build must succeed before anything ships (Phase 6); a failed build stops the gate.
BUILD_CMD='cd frontend && flutter build web --release'

# javac errors: "path/File.java:12: error: message". Gradle repeats each one indented in its
# failure summary, so only count the unindented line (verified: 1 planted error = 1 match).
backend_compile_cmd='cd backend && bash gradlew compileJava compileTestJava --console=plain'
backend_compile_match='^[^[:space:]].*\.java:[0-9]+: error:'

# Gradle prints one "Class > method() FAILED" line per failing test. Needs PostgreSQL on localhost:5432.
backend_test_cmd='cd backend && bash gradlew test --console=plain'
backend_test_match=' > .* FAILED$'

# flutter analyze: "  info - message - lib/x.dart:3:8 - rule" (older SDKs use • instead of -)
frontend_analyze_cmd='cd frontend && flutter analyze --no-pub'
frontend_analyze_match='^ *(error|warning|info) (-|•) '

# flutter test (expanded reporter) ends each failing or hung test's line with " [E]" (verified: 1 planted failure = 1 match). Hive-backed
# widget tests write to the OS temp folder only (see frontend/test/auth_routing_test.dart).
frontend_test_cmd='cd frontend && flutter test --no-pub --reporter expanded --timeout 60s'
frontend_test_match=' \[E\]$'
