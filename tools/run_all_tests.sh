#!/bin/bash
# Runs every tests/test_*.gd headless and prints one line per suite plus a total.
# Suites that extend SceneTree run directly; suites that extend Node go through tests/run_node_test.gd.
# A suite counts as failed on a non-zero exit code, a "[FAIL]" line, a script error or a failed assert.
#
# Usage: tools/run_all_tests.sh [log_dir]
GODOT="${GODOT:-/c/Godot/godot_console.exe}"
cd "$(dirname "$0")/.." || exit 1
LOGS="${1:-/tmp/wlo_test_logs}"
mkdir -p "$LOGS"
total=0
failed=0
for f in tests/test_*.gd; do
  name=$(basename "$f" .gd)
  if head -n 3 "$f" | grep -q "^extends Node"; then
    timeout 100 "$GODOT" --headless --path . --script res://tests/run_node_test.gd -- "res://$f" > "$LOGS/$name.log" 2>&1
  else
    timeout 100 "$GODOT" --headless --path . --script "res://$f" > "$LOGS/$name.log" 2>&1
  fi
  code=$?
  bad=$(grep -cE "\[FAIL\]|SCRIPT ERROR|Assertion failed|Parse Error" "$LOGS/$name.log")
  total=$((total + 1))
  if [ "$code" -ne 0 ] || [ "$bad" -ne 0 ]; then
    failed=$((failed + 1))
    echo "FAIL $name (exit=$code, problems=$bad)"
  else
    echo "ok   $name"
  fi
done
echo "TOTAL $total suites, $failed failed"
[ "$failed" -eq 0 ]
