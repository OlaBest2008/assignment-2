#!/usr/bin/env bash

IMAGE="diagnostic-tool:test"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "Building local test Docker image..."
docker build -t "$IMAGE" . >/dev/null

echo "Running test suite..."

TMP_OUT=$(mktemp)

# Test 1: Help command
docker run --rm "$IMAGE" help > "$TMP_OUT" 2>&1 || true
if grep -q "Usage: diagnostic" "$TMP_OUT"; then
    pass "Command 'help' outputs usage guide"
else
    fail "Command 'help' failed"
fi

# Test 2: System command
docker run --rm "$IMAGE" system > "$TMP_OUT" 2>&1 || true
if grep -q "SYSTEM DIAGNOSTICS" "$TMP_OUT"; then
    pass "Command 'system' displays system info"
else
    fail "Command 'system' failed"
fi

# Test 3: Disk command
docker run --rm "$IMAGE" disk > "$TMP_OUT" 2>&1 || true
if grep -q "DISK DIAGNOSTICS" "$TMP_OUT"; then
    pass "Command 'disk' displays disk info"
else
    fail "Command 'disk' failed"
fi

# Test 4: Invalid command handling (expects exit code 2)
set +e
docker run --rm "$IMAGE" invalid-command >/dev/null 2>&1
RC=$?
set -e
if [ "$RC" -ne 0 ]; then
    pass "Invalid command returns non-zero code ($RC)"
else
    fail "Invalid command unexpectedly returned 0"
fi

# Test 5: Missing host for network command (expects exit code 2)
set +e
docker run --rm "$IMAGE" network >/dev/null 2>&1
RC_NET=$?
set -e
if [ "$RC_NET" -eq 2 ]; then
    pass "Network command without host parameter returns exit code 2"
else
    fail "Network command missing host returned exit code $RC_NET (expected 2)"
fi

rm -f "$TMP_OUT"

echo "----------------------------------------"
echo "Test Results: $PASS Passed, $FAIL Failed"
echo "----------------------------------------"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0