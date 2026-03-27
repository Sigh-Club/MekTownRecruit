#!/usr/bin/env lua
-- ============================================================================
-- DKP System Tests
-- Tests: DKP operations, standings, bulk awards, balance calculations
-- Run: lua tests/test_dkp.lua
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
-- MOCK DKP SYSTEM
-- ============================================================================

local MTR = {}
local dkpLedger = {}

local function getDate()
    return "2026-03-27"
end

function MTR.DKPEnsure(name)
    dkpLedger[name] = dkpLedger[name] or { balance = 0, history = {} }
    return dkpLedger[name]
end

function MTR.DKPAdd(name, amount, reason, officer)
    local entry = MTR.DKPEnsure(name)
    entry.balance = (entry.balance or 0) + amount
    entry.history[#entry.history + 1] = {
        date = getDate(),
        amount = amount,
        reason = reason or "?",
        officer = officer or "System",
    }
end

function MTR.DKPSet(name, amount, officer)
    local entry = MTR.DKPEnsure(name)
    local diff = amount - (entry.balance or 0)
    entry.balance = amount
    entry.history[#entry.history + 1] = {
        date = getDate(),
        amount = diff,
        reason = "Set by " .. (officer or "System"),
        officer = officer or "System",
    }
end

function MTR.DKPBalance(name)
    local entry = dkpLedger[name]
    if not entry then return 0 end
    return entry.balance or 0
end

function MTR.DKPStandings()
    local standings = {}
    for name, entry in pairs(dkpLedger) do
        standings[#standings + 1] = {
            name = name,
            balance = entry.balance or 0,
        }
    end
    table.sort(standings, function(a, b)
        return a.balance > b.balance
    end)
    return standings
end

function MTR.DKPBulkAward(names, amount, reason)
    if not names or #names == 0 then return end
    for _, name in ipairs(names) do
        MTR.DKPAdd(name, amount, reason, "System")
    end
end

-- ============================================================================
-- DKP OPERATION TESTS
-- ============================================================================

section("DKP Operations")

-- Test DKPAdd positive
MTR.DKPAdd("Player1", 10, "Raid attendance", "Officer1")
assert(MTR.DKPBalance("Player1") == 10, "DKPAdd: positive amount adds correctly")

-- Test DKPAdd negative (deduction)
MTR.DKPAdd("Player1", -5, "Late", "Officer1")
assert(MTR.DKPBalance("Player1") == 5, "DKPAdd: negative amount deducts correctly")

-- Test DKPEnsure creates new player
local balance = MTR.DKPBalance("NewPlayer")
assert(balance == 0, "DKPEnsure: new player starts at 0")

-- Test DKPSet
MTR.DKPSet("Player1", 100, "GM")
assert(MTR.DKPBalance("Player1") == 100, "DKPSet: sets balance correctly")

-- Test history recording
local entry = dkpLedger["Player1"]
assert(#entry.history == 3, "History: all transactions recorded")

-- ============================================================================
-- DKP STANDINGS TESTS
-- ============================================================================

section("DKP Standings")

-- Add multiple players with different balances
MTR.DKPAdd("TopPlayer", 500, "Test", "System")
MTR.DKPAdd("MidPlayer", 250, "Test", "System")
MTR.DKPAdd("LowPlayer", 50, "Test", "System")

local standings = MTR.DKPStandings()
assert(#standings == 4, "Standings: counts all players")

-- First should be highest
assert(standings[1].name == "TopPlayer", "Standings: sorted by balance descending")
assert(standings[1].balance == 500, "Standings: highest balance first")

-- Last should be lowest
assert(standings[#standings].name == "LowPlayer", "Standings: lowest at bottom")

-- ============================================================================
-- BULK AWARD TESTS
-- ============================================================================

section("Bulk Awards")

local raidMembers = {"Raid1", "Raid2", "Raid3"}
MTR.DKPBulkAward(raidMembers, 20, "Raid attendance")

assert(MTR.DKPBalance("Raid1") == 20, "BulkAward: first member gets award")
assert(MTR.DKPBalance("Raid2") == 20, "BulkAward: second member gets award")
assert(MTR.DKPBalance("Raid3") == 20, "BulkAward: third member gets award")

-- Test empty list
MTR.DKPBulkAward({}, 100, "Should not crash")
assert(true, "BulkAward: empty list handled")

-- ============================================================================
-- EDGE CASES
-- ============================================================================

section("Edge Cases")

-- Negative balance allowed
MTR.DKPAdd("DebtedPlayer", -100, "Deduction", "Officer")
assert(MTR.DKPBalance("DebtedPlayer") == -100, "Negative balance allowed")

-- Zero amount
MTR.DKPAdd("ZeroPlayer", 0, "Zero test", "Officer")
assert(MTR.DKPBalance("ZeroPlayer") == 0, "Zero amount handled")

-- Very large numbers
MTR.DKPAdd("RichPlayer", 999999, "Big award", "Officer")
assert(MTR.DKPBalance("RichPlayer") == 999999, "Large numbers handled")

-- ============================================================================
-- SUMMARY
-- ============================================================================

section("Test Summary")
print(string.format("Total: %d | Passed: %d | Failed: %d", TOTAL_TESTS, PASSED_TESTS, FAILED_TESTS))

if FAILED_TESTS == 0 then
    print("\n🎉 All DKP tests passed!")
    os.exit(0)
else
    print("\n❌ Some tests failed!")
    os.exit(1)
end
