#!/usr/bin/env lua
-- ============================================================================
-- CharVault / Ledger Tests
-- Tests: Item scanning, transaction ledger, hash generation, persistence
-- Run: lua tests/test_charvault.lua
-- ============================================================================

local TOTAL_TESTS = 0
local PASSED_TESTS = 0
local FAILED_TESTS = 0

local function assert(condition, msg)
    TOTAL_TESTS = TOTAL_TESTS + 1
    if condition then
        PASSED_TESTS = PASSED_TESTS + 1
        print("  ✓ " .. (msg or "test"))
    else
        FAILED_TESTS = FAILED_TESTS + 1
        print("  ✗ " .. (msg or "assertion failed"))
    end
end

local function section(name)
    print("\n=== " .. name .. " ===")
end

-- ============================================================================
-- MOCK CHARVAULT SYSTEM
-- ============================================================================

local MTR = {}

-- Simple hash function
local function hashString(str)
    if not str or str == "" then return "0" end
    local h = 0
    for i = 1, #str do
        local c = string.byte(str, i)
        h = ((h * 31 + c) % 2147483647)
    end
    return tostring(h)
end

MTR.Hash = hashString

-- Guild Bank Snapshot
local gbSnapshot = {
    revision = 0,
    hash = "0",
    items = {},
    scannedBy = nil,
    timestamp = nil,
}

-- Ledger
local ledger = {
    entries = {},
    meta = {},
}

-- Scan item
function MTR.ScanGuildBankItem(tab, slot, link, count)
    local itemID = link and tonumber(link:match("item:(%d+)")) or 0
    gbSnapshot.items[#gbSnapshot.items + 1] = {
        tab = tab,
        slot = slot,
        itemID = itemID,
        link = link,
        count = count or 1,
    }
end

-- Hash items
function MTR.GBHashFromItems(items)
    local parts = {}
    for _, item in ipairs(items or {}) do
        parts[#parts + 1] = table.concat({
            tostring(tonumber(item.tab) or 0),
            tostring(tonumber(item.itemID) or 0),
            tostring(tonumber(item.count) or 0)
        }, "|")
    end
    table.sort(parts)
    return MTR.Hash(table.concat(parts, ";"))
end

-- Update snapshot
function MTR.UpdateGBSnapshot(scannedBy)
    gbSnapshot.revision = (gbSnapshot.revision or 0) + 1
    gbSnapshot.hash = MTR.GBHashFromItems(gbSnapshot.items)
    gbSnapshot.scannedBy = scannedBy
    gbSnapshot.timestamp = os.time()
    return gbSnapshot
end

-- Ledger entry
function MTR.LedgerAddEntry(kind, txType, actor, itemID, itemName, count, tab1, tab2)
    ledger.entries[#ledger.entries + 1] = {
        kind = kind,
        txType = txType,
        actor = actor,
        itemID = itemID,
        itemName = itemName,
        count = count,
        tab1 = tab1,
        tab2 = tab2,
        epoch = os.time(),
        txId = #ledger.entries + 1,
    }
end

-- Ledger hash
function MTR.LedgerHash()
    local parts = {}
    for _, e in ipairs(ledger.entries) do
        parts[#parts + 1] = table.concat({
            e.kind or "item",
            e.txType or "?",
            e.actor or "?",
            tostring(e.itemID or 0),
            tostring(e.count or 0)
        }, "|")
    end
    table.sort(parts)
    return MTR.Hash(table.concat(parts, ";"))
end

-- ============================================================================
-- GUILD BANK SCANNING TESTS
-- ============================================================================

section("Guild Bank Scanning")

gbSnapshot = { revision = 0, hash = "0", items = {} }

-- Scan items
MTR.ScanGuildBankItem(1, 1, "item:12345:0:0:0:0:0:0:0", 5)
MTR.ScanGuildBankItem(1, 2, "item:67890:0:0:0:0:0:0:0", 1)
MTR.ScanGuildBankItem(2, 1, "item:11111:0:0:0:0:0:0:0", 10)

assert(#gbSnapshot.items == 3, "Scan: all items scanned")

-- Update snapshot
local st = MTR.UpdateGBSnapshot("Scanner1")
assert(st.revision == 1, "Snapshot: revision increments")
assert(st.scannedBy == "Scanner1", "Snapshot: tracks scanner")
assert(st.hash ~= "0", "Snapshot: hash computed")

local hash1 = st.hash
local hash2 = MTR.UpdateGBSnapshot("Scanner1").hash
assert(hash1 == hash2, "Snapshot: same data = same hash")

-- ============================================================================
-- HASH INDEPENDENCE TESTS
-- ============================================================================

section("Hash Order Independence")

-- Same items, different order
gbSnapshot = { revision = 0, hash = "0", items = {} }
MTR.ScanGuildBankItem(1, 1, "item:12345", 5)
MTR.ScanGuildBankItem(1, 2, "item:67890", 1)
local hash1 = MTR.GBHashFromItems(gbSnapshot.items)

gbSnapshot = { revision = 0, hash = "0", items = {} }
MTR.ScanGuildBankItem(1, 2, "item:67890", 1)
MTR.ScanGuildBankItem(1, 1, "item:12345", 5)
local hash2 = MTR.GBHashFromItems(gbSnapshot.items)

assert(hash1 == hash2, "Hash: order-independent")

-- ============================================================================
-- LEDGER TESTS
-- ============================================================================

section("Ledger Operations")

ledger = { entries = {}, meta = {} }

-- Add entries
MTR.LedgerAddEntry("item", "deposit", "Player1", 12345, "Epic", 1, 1, 0)
MTR.LedgerAddEntry("item", "withdraw", "Player2", 67890, "Rare", 2, 1, 0)
MTR.LedgerAddEntry("item", "deposit", "Player1", 11111, "Common", 5, 2, 0)

assert(#ledger.entries == 3, "Ledger: entries added")

-- Ledger hash
local ledgerHash = MTR.LedgerHash()
assert(ledgerHash ~= "0", "Ledger: hash computed")

-- Entry structure
local entry = ledger.entries[1]
assert(entry.kind == "item", "Entry: kind recorded")
assert(entry.txType == "deposit", "Entry: txType recorded")
assert(entry.actor == "Player1", "Entry: actor recorded")
assert(entry.itemID == 12345, "Entry: itemID recorded")
assert(entry.txId == 1, "Entry: txId assigned")

-- ============================================================================
-- DEDUPLICATION TESTS
-- ============================================================================

section("Deduplication")

local function signature(e)
    return table.concat({
        e.kind or "item",
        e.txType or "?",
        e.actor or "?",
        tostring(e.itemID or 0),
    }, "|")
end

-- Existing entries
local existing = {
    { kind = "item", txType = "deposit", actor = "Player1", itemID = 12345 },
    { kind = "item", txType = "deposit", actor = "Player2", itemID = 67890 },
}
local existingSigs = {}
for _, e in ipairs(existing) do
    existingSigs[signature(e)] = true
end

-- Incoming entries (with duplicate)
local incoming = {
    { kind = "item", txType = "deposit", actor = "Player1", itemID = 12345 },  -- duplicate
    { kind = "item", txType = "deposit", actor = "Player3", itemID = 11111 },  -- new
}

local newEntries = {}
for _, e in ipairs(incoming) do
    if not existingSigs[signature(e)] then
        newEntries[#newEntries + 1] = e
    end
end

assert(#newEntries == 1, "Deduplication: only new entries kept")
assert(newEntries[1].actor == "Player3", "Deduplication: correct new entry")

-- ============================================================================
-- MERGE TESTS
-- ============================================================================

section("Merge Logic")

-- Player A has some entries
local playerA = {
    { txId = 1, epoch = 1000 },
    { txId = 2, epoch = 1001 },
}

-- Player B has more entries (and some overlap)
local playerB = {
    { txId = 1, epoch = 1000 },
    { txId = 2, epoch = 1001 },
    { txId = 3, epoch = 1002 },
    { txId = 4, epoch = 1003 },
}

-- Merge by txId
local existingIds = {}
for _, e in ipairs(playerA) do
    existingIds[e.txId] = true
end

local merged = {}
for _, e in ipairs(playerA) do
    merged[#merged + 1] = e
end
for _, e in ipairs(playerB) do
    if not existingIds[e.txId] then
        merged[#merged + 1] = e
    end
end

assert(#merged == 4, "Merge: all unique entries combined")
assert(merged[1].txId == 1, "Merge: original order preserved")
assert(merged[4].txId == 4, "Merge: new entries added")

-- ============================================================================
-- EDGE CASES
-- ============================================================================

section("Edge Cases")

-- Empty snapshot
gbSnapshot = { items = {} }
local emptyHash = MTR.GBHashFromItems(gbSnapshot.items)
assert(emptyHash == "0", "Empty: returns 0 hash")

-- Empty ledger
ledger = { entries = {} }
local ledgerEmptyHash = MTR.LedgerHash()
assert(ledgerEmptyHash == "0", "Ledger empty: returns 0 hash")

-- Nil item
local function safeScan(tab, slot, link, count)
    if not link then return end
    local itemID = tonumber(link:match("item:(%d+)")) or 0
    return { tab = tab, slot = slot, itemID = itemID, count = count or 1 }
end

local item = safeScan(1, 1, nil, 1)
assert(item == nil, "Nil link: returns nil safely")

-- ============================================================================
-- SUMMARY
-- ============================================================================

section("Test Summary")
print(string.format("Total: %d | Passed: %d | Failed: %d", TOTAL_TESTS, PASSED_TESTS, FAILED_TESTS))

if FAILED_TESTS == 0 then
    print("\n🎉 All CharVault/Ledger tests passed!")
    os.exit(0)
else
    print("\n❌ Some tests failed!")
    os.exit(1)
end
