# MekTownRecruit 2.0.0 Release Notes

## Highlights
- Finalized guild-scoped synchronization architecture across DKP, Recruit, Kick Log, Guild Tree, Guild Bank Snapshot, and Guild Bank Ledger.
- Added replay/repair flows for offline recovery and convergence after login.
- Added stale-revision and hash-mismatch rejection paths to prevent rollback/poisoned updates.
- Added ACK tracking by peer for multi-domain sync health visibility.
- Added sync audit commands:
  - `/mek sync status`
  - `/mek sync verify`
  - `/mek sync repair [dkp|guildtree|recruit|kick|gbank|ledger|all]`

## Post-finalization Stabilization
- Guild Bank Ledger ordering corrected to preserve newest-first behavior.
- Ledger dedupe hardened around transaction identity to prevent duplicate persistence.
- Ledger time handling adjusted for practical Ascension/Wrath log semantics:
  - Rough within-day reporting for recent events.
  - Day-based age reporting for older events.
- Added correction path for legacy/poisoned rows that previously appeared as recent.
- Added adaptive debug controls:
  - `/mek debug on|off`
  - `/mek debug chat on|off`
  - `/mek debug module <name> on|off`
  - `/mek debug status`

## Data Integrity Improvements
- Stronger deterministic hash function used for sync payload and event-chain verification.
- Guild identity now includes persistent guild ID metadata.
- Event log append chain includes event IDs and sequence tracking.

## Operational Readiness
- Added `LAUNCHER_RELEASE_CHECKLIST.md` for multi-client QA before Ascension Launcher submission.
- Updated addon version strings to `2.0.0`.

## Notes
- `luac -p` passes for all Lua files.
- `luacheck` reports warnings only (no errors), primarily style/line-length in legacy sections.
- 3.3.5-era guild bank timestamp APIs remain coarse/inconsistent for some rows; addon ledger now normalizes this into stable, synchronized display behavior.
