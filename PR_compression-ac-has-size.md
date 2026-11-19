Title: fix(store): report compression-store payload size from the frame footer

## What and why

`CompressionStore::has_with_results` overwrote a present digest key's
size with `digest.size_bytes()`. For a CAS blob that is the uncompressed
length. For an action-cache entry the digest is the Action, so `has()`
returned the Action size. After #2974, `FastSlowStore` sizes an
`ExactSize` fill from that answer and `validate_size` returns `DATA_LOSS`
when the stored ActionResult is a different length.

Present digest keys now report `Footer.uncompressed_data_size` from its
fixed place in the frame footer. Missing keys stay `None`, zero-digest
keys stay 0, and string keys keep the stored framed size. A truncated or
unreadable footer is an `Internal` error, matching `get_part`; the store
does not fall back to the digest size.

Fixes #3194

## How was this verified?

On Linux x86_64 with `rustc`/`cargo` 1.97.1 (not the Nix flake; Bazel
and `pre-commit` were not installed).

Untouched `upstream/main` at `12e8ae20`:

```
cargo +1.97.1 test -p nativelink-store --test compression_store_test
```

18 passed, 0 failed.

The three new tests, run against that same impl with only the test file
added:

- `has_reports_the_stored_uncompressed_size_when_the_digest_size_differs`
  failed with `has()` = `Some(167)` instead of `Some(334)`.
- `compressed_slow_tier_refills_when_digest_size_is_the_action_size`
  failed with `DATA_LOSS: Expected 167 upload bytes, received 334`.
- `has_errors_when_the_frame_footer_cannot_be_read` failed because a
  present garbage object still reported `Some(167)`.

On this branch, the same `cargo +1.97.1 test -p nativelink-store --test
compression_store_test` command is 21 passed, 0 failed, including the
existing CAS `has()` size test and
`compressed_slow_tier_refills_filesystem_with_the_uncompressed_size`.

Also ran `cargo +1.97.1 clippy -p nativelink-store --test
compression_store_test -- -D warnings` (pass) and `vale` 3.12.0 on
`compose-stores.mdx` (0 errors, 0 warnings, 0 suggestions). `rustfmt`
from 1.97.1 on the touched Rust files. Not verified: Bazel
`//nativelink-store:integration`, `bazel test //...`, and `pre-commit
run -a`.

## Risk

If the footer cannot be read, `has()` now returns `Internal` instead of
a guessed size. Callers that assumed a present compression-store object
always has a numeric size will see an error on a truncated frame; that
matches `get_part`. CAS existence checks for present digest keys now
read 13 bytes from the inner store, so a slow backend sees one extra
ranged read per hit. A wrong footer value would size a `fast_slow` fill
incorrectly and show up as `DATA_LOSS` on the fill, the same symptom the
Action size causes today.

## AI assistance

An agent wrote it and I reviewed every line.

## Demo

![demo](https://raw.githubusercontent.com/mvanhorn/pr-demo-assets/main/osc-bulk-1118n/compression-ac-has-size/preview.gif)

Full recording (MP4): https://raw.githubusercontent.com/mvanhorn/pr-demo-assets/main/osc-bulk-1118n/compression-ac-has-size/out.mp4
