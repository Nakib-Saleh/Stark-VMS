# Quality-gate checks for scripts/quality-ratchet.sh (Spring Boot backend + Flutter Web frontend).
# Sourced by bash — plain variable assignments only.
# gradlew is not committed as executable, so it is invoked with `bash gradlew` (works on Linux CI and Git Bash).
#
# shortcut: no `flutter build web` in BUILD_CMD (slow; analyze catches type errors). Add it before deploy work.

CHECKS="backend_compile backend_test frontend_analyze"
BUILD_CMD=""

# javac errors: "path/File.java:12: error: message". Gradle repeats each one indented in its
# failure summary, so only count the unindented line (verified: 1 planted error = 1 match).
backend_compile_cmd='cd backend && bash gradlew compileJava compileTestJava --console=plain'
backend_compile_match='^[^[:space:]].*\.java:[0-9]+: error:'

# Gradle prints one "Class > method() FAILED" line per failing test. Needs MySQL on localhost:3306 (contextLoads).
backend_test_cmd='cd backend && bash gradlew test --console=plain'
backend_test_match=' > .* FAILED$'

# flutter analyze: "  info - message - lib/x.dart:3:8 - rule" (older SDKs use • instead of -)
frontend_analyze_cmd='cd frontend && flutter analyze --no-pub'
frontend_analyze_match='^ *(error|warning|info) (-|•) '
