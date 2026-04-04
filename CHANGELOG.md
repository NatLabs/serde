# Changelog

All notable changes to `serde-core` will be documented here.

## [0.0.2] - 2026-04-04

### Changed
- Replace inlined `submodules/byte-utils/` with the official `byte-utils@0.2.0` mops package.
  The ByteUtils patch (switching from `mo:base` to `mo:core`) has been upstreamed to NatLabs/ByteUtils.
- Bump `moc` toolchain requirement to `1.4.1` (required by `byte-utils@0.2.0` via `core@2.4`).
- Bump `core` dependency to `2.4.0` (aligned with `byte-utils@0.2.0`).

## [0.0.1] - 2026-03-23

### Added
- Initial release mirroring NatLabs/serde (core branch) with NatLabs/ByteUtils inlined
  (refs/pull/3/head), adapted to use `mo:core/*` imports throughout.
- Published to mops as `serde-core@0.0.1`.
