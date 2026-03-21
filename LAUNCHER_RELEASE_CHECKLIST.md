# MekTownRecruit Launcher Release Checklist

## Build/Static
- [ ] `luac -p` passes for all addon Lua files.
- [ ] `luacheck` has no errors (warnings reviewed/accepted).
- [ ] `.toc` version and notes are correct for release build.

## Multi-Client Sync Validation (same guild)
Run with at least 3 clients: GM, Officer, Member.

### DKP
- [ ] Officer awards DKP; other officer receives balance + history updates.
- [ ] New login requests full sync and converges.
- [ ] Stale snapshot is rejected (no rollback).
- [ ] `/mek sync status` shows DKP revision/hash and ACK peers.

### Recruit History
- [ ] Officer whisper/invite records replicate to officer peers.
- [ ] Offline officer logs in and recovers history via `RH:REQ` replay.
- [ ] Hash mismatch test rejects bad payload and preserves local data.

### Inactivity Kick Log
- [ ] Kick event replicates to officer peers.
- [ ] Offline officer logs in and recovers kick history.
- [ ] ACKs are tracked in sync status.

### Guild Tree
- [ ] Set alt/main/delete syncs to officer peers.
- [ ] Fresh login runs `GT:REQ:<hash>` and converges.
- [ ] Snapshot hash mismatch is rejected.

### Guild Bank Snapshot
- [ ] Officer scan broadcasts snapshot to all online guild members.
- [ ] Member login requests snapshot with known hash and converges.
- [ ] Stale or hash-mismatched snapshot is rejected.

### Guild Bank Ledger
- [ ] Officer scan broadcasts ledger snapshot with revision/hash.
- [ ] Member/officer request ledger sync and converge.
- [ ] ACKs are tracked and visible in status.
- [ ] Newest transaction appears at top after scan (no inverted ordering).
- [ ] Recent entries (under 24h) display rough time.
- [ ] Older entries display day-based age text.
- [ ] Re-scan does not reshuffle old rows as newly recent.
- [ ] Duplicate transactions are not retained after repeated scans.

## Security/Scope
- [ ] Cross-guild messages are ignored.
- [ ] Officer-gated channels reject non-officer authoritative writes.
- [ ] Member workflows cannot perform officer-only write actions.

## UI/Operational
- [ ] `/mek sync status` output is readable and complete.
- [ ] `/mek sync verify` validates event chain.
- [ ] `/mek sync repair all` triggers domain requests correctly.
- [ ] Adaptive debug works as expected (`/mek debug chat off`, module-only enable).

## Final Packaging
- [ ] Remove debug-only temporary text/logs if any.
- [ ] Smoke-test fresh install and upgrade path with existing SavedVariables.
- [ ] Tag and publish release build for Ascension Launcher review.
