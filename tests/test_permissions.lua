#!/usr/bin/env lua
-- ============================================================================
-- Permission & Access Control Tests
-- Tests: Officer checks, GM checks, feature access
-- Run: lua tests/test_permissions.lua
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
-- MOCK PERMISSION SYSTEM
-- ============================================================================

local MTR = {}

-- Role state
MTR.isOfficer = false
MTR.isGM = false

local function CheckIsGM()
    return MTR.isGM
end

local function CheckIsOfficer()
    return MTR.isOfficer
end

MTR.CheckIsGM = CheckIsGM
MTR.CheckIsOfficer = CheckIsOfficer

-- Feature access matrix
local FEATURES = {
    Recruit = { requiresOfficer = true },
    DKP = { requiresOfficer = true },
    Auction = { requiresOfficer = true },
    Roll = { requiresOfficer = true },
    Inactive = { requiresOfficer = true },
    Guild = { requiresOfficer = true },
    Ads = { requiresOfficer = true },
    ["Group Radar"] = { requiresOfficer = false },
    Vault = { requiresOfficer = false },
    Standings = { requiresOfficer = false },
}

function MTR.CanAccess(featureName)
    local feature = FEATURES[featureName]
    if not feature then return false end
    if feature.requiresOfficer then
        return MTR.isOfficer or MTR.isGM
    end
    return true  -- Everyone can access
end

-- ============================================================================
-- PERMISSION TESTS
-- ============================================================================

section("Officer Permission Tests")

-- Regular member (not officer, not GM)
MTR.isOfficer = false
MTR.isGM = false

assert(MTR.CanAccess("Recruit") == false, "Member: cannot access Recruit")
assert(MTR.CanAccess("DKP") == false, "Member: cannot access DKP")
assert(MTR.CanAccess("Auction") == false, "Member: cannot access Auction")
assert(MTR.CanAccess("Inactive") == false, "Member: cannot access Inactive")
assert(MTR.CanAccess("Group Radar") == true, "Member: can access Group Radar")
assert(MTR.CanAccess("Vault") == true, "Member: can access Vault")
assert(MTR.CanAccess("Standings") == true, "Member: can access Standings")

section("Officer Permission Tests")

-- Officer (not GM)
MTR.isOfficer = true
MTR.isGM = false

assert(MTR.CanAccess("Recruit") == true, "Officer: can access Recruit")
assert(MTR.CanAccess("DKP") == true, "Officer: can access DKP")
assert(MTR.CanAccess("Auction") == true, "Officer: can access Auction")
assert(MTR.CanAccess("Inactive") == true, "Officer: can access Inactive")
assert(MTR.CanAccess("Group Radar") == true, "Officer: can access Group Radar")
assert(MTR.CanAccess("Vault") == true, "Officer: can access Vault")
assert(MTR.CanAccess("Standings") == true, "Officer: can access Standings")

section("GM Permission Tests")

-- GM (not officer but GM overrides)
MTR.isOfficer = false
MTR.isGM = true

assert(MTR.CanAccess("Recruit") == true, "GM: can access Recruit (GM overrides)")
assert(MTR.CanAccess("DKP") == true, "GM: can access DKP (GM overrides)")
assert(MTR.CanAccess("Group Radar") == true, "GM: can access Group Radar")
assert(MTR.CanAccess("Vault") == true, "GM: can access Vault")

section("GM + Officer Tests")

-- Both GM and Officer
MTR.isOfficer = true
MTR.isGM = true

assert(MTR.CanAccess("Recruit") == true, "GM+Officer: can access Recruit")
assert(MTR.CanAccess("DKP") == true, "GM+Officer: can access DKP")

section("Edge Cases")

-- Unknown feature
MTR.isOfficer = false
MTR.isGM = false
assert(MTR.CanAccess("UnknownFeature") == false, "Unknown feature: returns false")

-- Nil feature
assert(MTR.CanAccess(nil) == false, "Nil feature: returns false")

-- All features accessible list
local function getAccessibleFeatures(isOfficer, isGM)
    local accessible = {}
    MTR.isOfficer = isOfficer
    MTR.isGM = isGM
    for feature, _ in pairs(FEATURES) do
        if MTR.CanAccess(feature) then
            accessible[#accessible + 1] = feature
        end
    end
    return accessible
end

MTR.isOfficer = false
MTR.isGM = false
local memberFeatures = getAccessibleFeatures(false, false)
assert(#memberFeatures == 3, "Member accessible count: 3 features")

MTR.isOfficer = true
MTR.isGM = false
local officerFeatures = getAccessibleFeatures(true, false)
assert(#officerFeatures == 10, "Officer accessible count: 10 features")

MTR.isOfficer = true
MTR.isGM = true
local gmFeatures = getAccessibleFeatures(true, true)
assert(#gmFeatures == 10, "GM accessible count: 10 features")

-- ============================================================================
-- IS_IN_GUILD CHECKS
-- ============================================================================

section("Guild Status Checks")

local isInGuild = false

function MTR.IsInGuildCheck()
    return isInGuild
end

isInGuild = false
assert(MTR.IsInGuildCheck() == false, "Not in guild: returns false")

isInGuild = true
assert(MTR.IsInGuildCheck() == true, "In guild: returns true")

-- ============================================================================
-- SUMMARY
-- ============================================================================

section("Test Summary")
print(string.format("Total: %d | Passed: %d | Failed: %d", TOTAL_TESTS, PASSED_TESTS, FAILED_TESTS))

if FAILED_TESTS == 0 then
    print("\n🎉 All permission tests passed!")
    os.exit(0)
else
    print("\n❌ Some tests failed!")
    os.exit(1)
end
