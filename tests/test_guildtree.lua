#!/usr/bin/env lua
-- ============================================================================
-- GuildTree Tests
-- Tests: Alt/main relationships, hash generation, sync state
-- Run: lua tests/test_guildtree.lua
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
-- MOCK GUILD TREE SYSTEM
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

-- Family tree storage: charName -> { main = mainName or nil }
local familyTree = {}

function MTR.GTSetAlt(charName, mainName)
    familyTree[charName] = { main = mainName }
end

function MTR.GTSetMain(charName)
    if familyTree[charName] then
        familyTree[charName].main = nil
    end
end

function MTR.GTRemove(charName)
    familyTree[charName] = nil
end

function MTR.GTGetMain(name)
    local entry = familyTree[name]
    if not entry then return nil end
    return entry.main
end

function MTR.GTIsAlt(name)
    return familyTree[name] and familyTree[name].main ~= nil
end

function MTR.GTGetAlts(mainName)
    local alts = {}
    for name, entry in pairs(familyTree) do
        if entry.main == mainName then
            alts[#alts + 1] = name
        end
    end
    table.sort(alts)
    return alts
end

-- Encode full tree for sync
local function GTEncodeFull()
    local parts = {}
    for name, entry in pairs(familyTree) do
        if entry.main then
            parts[#parts + 1] = name .. "|" .. entry.main
        end
    end
    table.sort(parts)
    return table.concat(parts, ";")
end

-- Sync state
local syncState = {
    revision = 0,
    hash = "0",
}

function MTR.GTTouch()
    syncState.revision = (syncState.revision or 0) + 1
    syncState.hash = MTR.Hash(GTEncodeFull())
    return syncState
end

function MTR.GTSyncState()
    return syncState
end

-- ============================================================================
-- GUILD TREE TESTS
-- ============================================================================

section("Basic Alt/Main Operations")

-- Test setting alt
MTR.GTSetAlt("Alt1", "Main1")
assert(MTR.GTGetMain("Alt1") == "Main1", "GTSetAlt: sets main correctly")

-- Test getting alts
local alts = MTR.GTGetAlts("Main1")
assert(#alts == 1, "GTGetAlts: returns alts")
assert(alts[1] == "Alt1", "GTGetAlts: correct alt name")

-- Test multiple alts
MTR.GTSetAlt("Alt2", "Main1")
MTR.GTSetAlt("Alt3", "Main1")
alts = MTR.GTGetAlts("Main1")
assert(#alts == 3, "GTGetAlts: multiple alts counted")

-- Test GTIsAlt
assert(MTR.GTIsAlt("Alt1") == true, "GTIsAlt: returns true for alt")
assert(not MTR.GTIsAlt("Main1"), "GTIsAlt: returns false for main")

-- Test removing alt
MTR.GTRemove("Alt1")
assert(MTR.GTGetMain("Alt1") == nil, "GTRemove: removes alt relationship")

-- Test setting main (removes alt status)
MTR.GTSetMain("Main1")
assert(MTR.GTGetMain("Main1") == nil, "GTSetMain: clears main status")

-- ============================================================================
-- HASH TESTS
-- ============================================================================

section("Hash Consistency")

-- Reset tree
familyTree = {}

-- Empty tree hash
local st = MTR.GTTouch()
assert(st.hash == "0", "Hash: empty tree returns 0")

-- Single alt
familyTree = {}
MTR.GTSetAlt("Player1", "Main1")
st = MTR.GTTouch()
local hash1 = st.hash
assert(hash1 ~= "0", "Hash: non-empty tree returns non-zero")

-- Same relationship, same hash (deterministic) - compute hash without incrementing revision
local hash2 = MTR.Hash(GTEncodeFull())
assert(hash1 == hash2, "Hash: consistent for same data")

-- ============================================================================
-- REVISION TESTS
-- ============================================================================

section("Revision Tracking")

-- Each touch increments revision
local initialRev = syncState.revision
MTR.GTTouch()
assert(syncState.revision == initialRev + 1, "Revision: increments on touch")

local rev2 = syncState.revision
MTR.GTTouch()
assert(syncState.revision == rev2 + 1, "Revision: increments each time")

-- ============================================================================
-- EDGE CASES
-- ============================================================================

section("Edge Cases")

-- Setting alt to same main multiple times
familyTree = {}
MTR.GTSetAlt("Player", "Main")
local h1 = MTR.GTTouch().hash
MTR.GTSetAlt("Player", "Main")  -- set again
local h2 = MTR.GTTouch().hash
assert(h1 == h2, "Same alt/main produces same hash")

-- Main with no alts
familyTree = {}
local mainAlts = MTR.GTGetAlts("LoneMain")
assert(#mainAlts == 0, "GetAlts: returns empty for main with no alts")

-- ============================================================================
-- SYNC SIMULATION
-- ============================================================================

section("Sync Simulation")

-- Simulate two officers with same data
familyTree = {}
MTR.GTSetAlt("Alt1", "Main1")
MTR.GTSetAlt("Alt2", "Main1")
local st1 = MTR.GTTouch()

-- Another officer with same data
familyTree = {}
MTR.GTSetAlt("Alt2", "Main1")
MTR.GTSetAlt("Alt1", "Main1")  -- different order
local st2 = MTR.GTTouch()

-- Hashes should match regardless of order
assert(st1.hash == st2.hash, "Sync: hash order-independent")

-- ============================================================================
-- SUMMARY
-- ============================================================================

section("Test Summary")
print(string.format("Total: %d | Passed: %d | Failed: %d", TOTAL_TESTS, PASSED_TESTS, FAILED_TESTS))

if FAILED_TESTS == 0 then
    print("\n🎉 All GuildTree tests passed!")
    os.exit(0)
else
    print("\n❌ Some tests failed!")
    os.exit(1)
end
