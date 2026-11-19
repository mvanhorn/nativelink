# Demo: ExistenceCacheStore remove invalidation

This orphan branch holds the recording only. The product change is
`feat/existence-cache-invalidate` (`d0958989130d50b5fcb12873318d5f1b686469c0`),
branched from `upstream/main` at `12e8ae20df13c92efa74efc5ac7ec8a392ceb35c`.

## What the recording is

A live xfce4-terminal session on Xvfb `:99` (1920x1080), captured with ffmpeg
`x11grab`. It is not a replay, so there is no "Replay of real captured command
output" banner. `demo.sh` is the script that ran in that window.

Held scenes, about 4 s each:

1. Untouched `upstream/main` SHA `12e8ae20`.
2. `cargo test -p nativelink-store --test existence_store_test --profile=smol remove_evicts_presence_and_the_next_has_reports_missing -- --test-threads=1 --nocapture` on that worktree: **FAIL** (exit 101). `remove` is still the `StoreDriver` default, so the assertion that a copy was dropped fails.
3. The same command on `feat/existence-cache-invalidate`: **PASS** (exit 0).
4. `remove_noop_backend_drops_presence_and_keeps_durable_data` on the branch: **PASS**. Local presence is gone; the durable blob is still there.

`out.mp4` is that capture (H.264 yuv420p, 1920x1080, 30 fps, 23.90 s).
`preview.gif` is derived from it with `palettegen` / `paletteuse` (1280x720,
10 fps, 64 colours, 1 921 617 bytes).

`commands.log` and `logs/` are the full suites used for the PR body, not just
the filtered tests in the video: existence and ONTAP tests on main and on the
branch, plus clippy and rustfmt `--check`.

## Toolchain

`rustc 1.97.1 (8bab26f4f 2026-07-14)` / `cargo 1.97.1 (c980f4866 2026-06-30)`,
Linux x86_64. Bazel, vale, and pre-commit were not installed in this
environment.

## Do not open a pull request from this branch

Paste `PR_existence-cache-invalidate.md` when a person opens the PR against
TraceMachina/nativelink from `feat/existence-cache-invalidate`.
