#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN="$SCRIPT_DIR/run.sh"
PASS=0; FAIL=0; TOTAL=0
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  ((TOTAL++))
  if echo "$haystack" | grep -qF -- "$needle"; then
    ((PASS++)); echo "  PASS: $desc"
  else
    ((FAIL++)); echo "  FAIL: $desc (output missing '$needle')"
  fi
}

assert_exit_code() {
  local desc="$1" expected="$2"
  shift 2
  local output
  set +e; output=$("$@" 2>&1); local actual=$?; set -e
  ((TOTAL++))
  if [ "$expected" -eq "$actual" ]; then
    ((PASS++)); echo "  PASS: $desc"
  else
    ((FAIL++)); echo "  FAIL: $desc (expected exit $expected, got $actual)"
  fi
}

echo "=== Tests for env-check ==="

# Happy path: check tool we know exists
echo "Core:"
result=$("$RUN" bash 2>&1 || true)
assert_contains "finds bash" "bash" "$result"
assert_contains "shows OK status" "OK" "$result"

# Check multiple tools
result=$("$RUN" bash git 2>&1 || true)
assert_contains "checks multiple tools" "git" "$result"

# Edge case: tool that doesn't exist
echo "Edge cases:"
result=$("$RUN" nonexistent_tool_xyz123 2>&1 || true)
assert_contains "reports missing tool" "MISSING" "$result"

# From requirements file
echo "File input:"
echo -e "bash\ngit" > "$TMPDIR/requirements.txt"
result=$("$RUN" --file "$TMPDIR/requirements.txt" 2>&1 || true)
assert_contains "reads from file" "bash" "$result"

# Error handling
echo "Errors:"
assert_exit_code "no args fails" 1 "$RUN"

# Help
echo "Help:"
result=$("$RUN" --help 2>&1)
assert_contains "help works" "Usage:" "$result"

# JSON output
echo "Format:"
result=$("$RUN" bash --format json 2>&1 || true)
assert_contains "json has name field" '"name"' "$result"

echo ""
echo "=== Results: $PASS/$TOTAL passed ==="
[ "$FAIL" -eq 0 ] || { echo "BLOCKED: $FAIL test(s) failed"; exit 1; }
