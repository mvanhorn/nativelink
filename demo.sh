#!/usr/bin/env bash
# Real commands for the existence-cache invalidate demo.
set -u
export PATH="/usr/local/cargo/bin:${HOME}/.cargo/bin:${PATH}"
export CARGO_TERM_COLOR=always
export RUST_LOG=error
export TERM=xterm-256color
rm -f /tmp/demo-done

bold() { printf '\n\033[1;97m%s\033[0m\n' "$1"; }
hold() { sleep 4; }

clear
bold "BEFORE: untouched upstream/main"
printf 'SHA  %s\n' "$(git -C /tmp/nl-main rev-parse HEAD)"
printf 'tool %s / %s\n' "$(rustc --version)" "$(cargo --version)"
hold

bold "cargo test remove_evicts_presence... on upstream/main"
cd /tmp/nl-main
CARGO_TARGET_DIR=/tmp/nl-main-target cargo test -p nativelink-store \
  --test existence_store_test --profile=smol \
  remove_evicts_presence_and_the_next_has_reports_missing \
  -- --test-threads=1 --nocapture --color=always
printf '\n\033[1;31mexit %s  FAIL: remove is still a no-op; has() keeps the stale positive\033[0m\n' "$?"
hold

bold "AFTER: feat/existence-cache-invalidate"
cd /workspace
printf 'SHA  %s\n' "$(git rev-parse HEAD)"
cargo test -p nativelink-store --test existence_store_test --profile=smol \
  remove_evicts_presence_and_the_next_has_reports_missing \
  -- --test-threads=1 --nocapture --color=always
printf '\n\033[1;32mexit %s  PASS: presence dropped; next has() asks the backend\033[0m\n' "$?"
hold

bold "Durable copy still present after metadata invalidation"
cargo test -p nativelink-store --test existence_store_test --profile=smol \
  remove_noop_backend_drops_presence_and_keeps_durable_data \
  -- --test-threads=1 --nocapture --color=always
printf '\n\033[1;32mexit %s  PASS: index dropped; durable blob kept (removed=true is not implied)\033[0m\n' "$?"
hold

bold "done"
sleep 4
touch /tmp/demo-done
sleep 2
