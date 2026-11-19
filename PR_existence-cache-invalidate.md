Title: fix(store): invalidate ExistenceCacheStore entries on remove

<!-- Thanks for contributing to NativeLink.

Everything outside an HTML comment becomes part of the permanent record, so
replace the prompts below with your own words. The comments themselves are
invisible once posted; leaving them in is fine.

You do not need to confirm that tests, formatting or lints pass. CI checks
that, and it is better at it than either of us. -->

## What and why

`ExistenceCacheStore` did not implement `StoreDriver::remove` or
`remove_cached`, so both fell through to the trait default and left a stale
positive in the local index after cache repair. `has()` could then report a
blob the eligible cache copy no longer held. This change drops the local
presence entry on both methods, forwards eligible inner removal on
`ExistenceCacheStore`, and only drops the `OntapS3ExistenceCache` index
(never the S3 object). An in-flight `has()` or `get_part` cannot restore a
just-invalidated positive.

Fixes #2973

## How was this verified?

Toolchain: rustc 1.97.1 (8bab26f4f 2026-07-14), cargo 1.97.1, Linux x86_64.
New tests were copied onto a worktree of untouched `upstream/main` at
`12e8ae20df13c92efa74efc5ac7ec8a392ceb35c` so the same cases could run
before and after.

- `cargo test -p nativelink-store --test existence_store_test --profile=smol -- --test-threads=1`
  - main: FAILED, 9 passed / 6 failed (`remove_evicts_presence_and_the_next_has_reports_missing`, `remove_noop_backend_drops_presence_and_keeps_durable_data`, `remove_backend_error_drops_presence`, `remove_cached_drops_fast_copy_and_keeps_durable`, `truncated_cache_entry_is_evicted_and_refills_from_durable`, `gated_has_during_remove_does_not_restore_stale_positive`)
  - branch: ok, 15 passed / 0 failed
- `cargo test -p nativelink-store --test ontap_s3_existence_cache_store_test --profile=smol -- --test-threads=1`
  - main: FAILED, 5 passed / 1 failed (`remove_drops_index_entry_without_deleting_durable_object`)
  - branch: ok, 6 passed / 0 failed
- `cargo clippy -p nativelink-store --profile=smol --tests -- --deny warnings` — pass
- `cargo fmt -p nativelink-store -- --check` on the four edited Rust files — pass (stable rustfmt warns that `rustfmt.toml` keys `skip_children`, `imports_granularity`, `group_imports`, and `unstable_features` need nightly)

Those tests warm a positive then remove through the wrapper so the next
`has()` is a backend miss; evict a truncated fast copy and refill from
durable (`verify` over `existence_cache` over `fast_slow`); keep durable
data when the inner store returns `Ok(false)` or an error; cover
callback-driven invalidation, `remove_cached` dropping only the fast copy,
a gated concurrent `has()` that must not restore a stale positive, and an
ONTAP index-only drop that leaves the inner object in place.

Not verified: Bazel (`bazel` is not installed here), `vale`, `pre-commit`,
and `bazel test //...`.

## Risk

If invalidation is too eager, a failed inner `remove` still drops the local
positive and the next `has()` pays an extra backend lookup; that is the
intended trade. If it is too weak, a `verify` store sitting above
`existence_cache` over `fast_slow` can keep serving a truncated fast copy
after DataLoss. First to notice: `FindMissingBlobs` or a verified `get`
after repair, and anyone who called `remove` / `remove_cached` on a stack
that includes `existence_cache`. ONTAP `remove` does not delete bucket
objects.

## AI assistance

An agent wrote it and I reviewed every line.

## Demo

![demo](https://raw.githubusercontent.com/mvanhorn/pr-demo-assets/main/osc-bulk-1118n/existence-cache-invalidate/preview.gif)

Full recording (MP4): https://raw.githubusercontent.com/mvanhorn/pr-demo-assets/main/osc-bulk-1118n/existence-cache-invalidate/out.mp4
