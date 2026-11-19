# Demo: compression-store `has()` reports footer payload size

Real xterm on Xvfb (1920x1080), recorded with ffmpeg x11grab. The
session runs the compiled `compression_store_test` binaries from
untouched `upstream/main` (`12e8ae20`) and from
`feat/compression-ac-has-size` (`1fa599e0`). Those binaries are what
`cargo +1.97.1 test -p nativelink-store --test compression_store_test`
builds.

## What the recording shows

1. **Before** (`12e8ae20`): `has_reports_the_stored_uncompressed_size_when_the_digest_size_differs`
   fails because `has()` returns `Some(167)` (the Action size in the
   digest) instead of `Some(334)` (the stored ActionResult).
2. **Before**: `compressed_slow_tier_refills_when_digest_size_is_the_action_size`
   fails with `DATA_LOSS: Expected 167 upload bytes, received 334`.
3. **After** (`1fa599e0`): the same `has()` test passes.
4. **After**: the same `fast_slow` fill succeeds.
5. **After**: `compressed_slow_tier_refills_filesystem_with_the_uncompressed_size`
   still passes (CAS digest size equals payload size).

`commands.log` is a `script` capture of the same tests with full
stdout/stderr (including tracing-test TRACE lines). The video filters
those TRACE/DEBUG lines so the pass/fail lines stay on screen.

## Media

- `out.mp4`: 1920x1080, 30 fps, H.264, yuv420p, 23.60 s, 708 frames
- `preview.gif`: 1280x720, 10 fps, 236 frames, 396167 bytes
