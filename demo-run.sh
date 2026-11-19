#!/bin/bash
# Real before/after run of the compression-store has() size tests.
set +e
export TERM="${TERM:-xterm-256color}"
HOLD_SECS="${HOLD_SECS:-3}"
hold() { sleep "$HOLD_SECS"; }

UPSTREAM_BIN=/tmp/demo-bins/upstream-compression_store_test
FEAT_BIN=/tmp/demo-bins/feat-compression_store_test
HAS_FILTER=has_reports_the_stored_uncompressed_size_when_the_digest_size_differs
FILL_FILTER=compressed_slow_tier_refills_when_digest_size_is_the_action_size
CAS_FILTER=compressed_slow_tier_refills_filesystem_with_the_uncompressed_size

run_test() {
  local bin="$1"
  local filter="$2"
  echo "\$ cargo +1.97.1 test -p nativelink-store --test compression_store_test \\"
  echo "    ${filter} -- --nocapture --test-threads=1"
  echo
  "$bin" --color always "${filter}" --nocapture --test-threads=1 2>&1 \
    | grep -vE ' (TRACE|DEBUG) '
  echo "exit=${PIPESTATUS[0]}"
  echo
}

sleep 1
echo
echo "NativeLink  compression-store has() size"
echo "Issue #3194  DATA_LOSS on action-cache fills through a compression store"
echo
hold

echo "========  BEFORE: untouched upstream/main  ========"
git -C /tmp/nativelink-upstream-main log -1 --format='%h %s'
echo
run_test "$UPSTREAM_BIN" "$HAS_FILTER"
hold
run_test "$UPSTREAM_BIN" "$FILL_FILTER"
hold

clear
echo
echo "========  AFTER: feat/compression-ac-has-size  ========"
git -C /workspace log -1 --format='%h %s'
echo
run_test "$FEAT_BIN" "$HAS_FILTER"
hold
run_test "$FEAT_BIN" "$FILL_FILTER"
hold
run_test "$FEAT_BIN" "$CAS_FILTER"
hold

echo "Done. has() reports the footer payload size; the fast_slow fill succeeds;"
echo "the matching-digest CAS refill still works."
hold
sleep 1
