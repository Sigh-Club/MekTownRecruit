#!/usr/bin/env lua
-- ============================================================================
-- Core Functionality Tests
-- Tests: DB initialization, profiles, utilities, hash functions
-- Run: lua tests/test_core.lua
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
-- MOCK MTR (Core functions we want to test)
-- ============================================================================

local MekTownRecruit = {}
local MTR = MekTownRecruit

-- Copy the actual hash function
function MTR.Hash(str)
    if not str or str == "" then return "0" end
    local h = 0
    for i = 1, #str do
        local c = string.byte(str, i)
        h = ((h * 31 + c) % 2147483647)
    end
    return tostring(h)
end

function MTR.DeepCopy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = MTR.DeepCopy(v)
    end
    return copy
end

function MTR.Trunc(text, maxChars)
    if not text then return "" end
    text = tostring(text)
    if #text <= maxChars then return text end
    return text:sub(1, maxChars - 3) .. "..."
end

function MTR.FormatDays(days)
    if not days then return "0" end
    if days == 0 then return "0" end
    if days == 1 then return "1 day" end
    return days .. " days"
end

function MTR.ItemLinkToName(link)
    if not link then return nil end
    return link:match("%[(.-)%]")
end

function MTR.IsItemLink(str)
    if not str or type(str) ~= "string" then return false end
    return str:match("|Hitem:") ~= nil
end

function MTR.StripChatEscapes(msg, allowLinks)
    if msg == nil then return "" end
    msg = tostring(msg)
    msg = msg:gsub("[\r\n]+", " ")
    local keptLinks = {}
    if allowLinks then
        msg = msg:gsub("|H[^|]+|h.-|h", function(link)
            keptLinks[#keptLinks + 1] = link
            return "MTRLINK" .. #keptLinks .. "MTRLINK"
        end)
    end
    msg = msg:gsub("|c%x%x%x%x%x%x%x%x", "")
    msg = msg:gsub("|r", "")
    if not allowLinks then
        msg = msg:gsub("|H.-|h(.-)|h", "%1")
    end
    msg = msg:gsub("||", "|")
    if allowLinks then
        msg = msg:gsub("MTRLINK(%d+)MTRLINK", function(i)
            return keptLinks[tonumber(i)] or ""
        end)
    end
    return msg
end

-- ============================================================================
-- PROFILE SYSTEM TESTS
-- ============================================================================

section("Profile System")

local function createMockDB()
    return {
        activeProfile = "Default",
        profiles = {
            Default = {
                keywords = {"test1", "test2"},
                whisperTemplates = {"template1"},
                enabled = true,
                minimapButton = true,
            }
        }
    }
end

local db = createMockDB()

function MTR.GetProfileValue(key, default)
    local profile = db.profiles[db.activeProfile]
    if not profile then return default end
    return profile[key] ~= nil and profile[key] or default
end

function MTR.SetProfileValue(key, value)
    local profile = db.profiles[db.activeProfile]
    if not profile then return end
    profile[key] = value
end

function MTR.SetProfileBoolean(key, flag)
    MTR.SetProfileValue(key, flag == true)
end

function MTR.GetProfileBoolean(key, default)
    local val = MTR.GetProfileValue(key, default)
    return val == true or val == 1
end

-- Test profile get/set
MTR.SetProfileValue("testKey", "testValue")
assert(MTR.GetProfileValue("testKey") == "testValue", "Profile value set/get works")

-- Test profile boolean
MTR.SetProfileBoolean("boolKey", true)
assert(MTR.GetProfileBoolean("boolKey") == true, "Profile boolean true works")

MTR.SetProfileBoolean("boolKey2", false)
assert(MTR.GetProfileBoolean("boolKey2") == false, "Profile boolean false works")

-- Test default value
assert(MTR.GetProfileValue("nonexistent", "default") == "default", "Default value works")

-- Test deep copy
local original = {a = 1, b = {c = 2}}
local copy = MTR.DeepCopy(original)
copy.b.c = 99
assert(original.b.c == 2, "DeepCopy creates independent copy")

-- ============================================================================
-- UTILITY FUNCTION TESTS
-- ============================================================================

section("Utility Functions")

-- Hash function tests
assert(MTR.Hash("hello") == MTR.Hash("hello"), "Hash is deterministic")
assert(MTR.Hash("hello") ~= MTR.Hash("world"), "Hash differs for different strings")
assert(MTR.Hash("") == "0", "Hash of empty string returns 0")
assert(MTR.Hash(nil) == "0", "Hash of nil returns 0")

-- Truncation tests
assert(MTR.Trunc("hello", 10) == "hello", "Trunc: short string unchanged")
assert(MTR.Trunc("hello world", 8) == "hello...", "Trunc: long string truncated")
assert(MTR.Trunc(nil, 10) == "", "Trunc: nil returns empty")

-- Format days tests
assert(MTR.FormatDays(0) == "0", "FormatDays: 0 days")
assert(MTR.FormatDays(1) == "1 day", "FormatDays: 1 day")
assert(MTR.FormatDays(7) == "7 days", "FormatDays: 7 days")
assert(MTR.FormatDays(nil) == "0", "FormatDays: nil returns 0")

-- Item link tests
assert(MTR.IsItemLink("|cff0070dd|Hitem:12345:0:0:0:0:0:0:0|h[Epic Sword]|h|r") == true, "IsItemLink: valid link")
assert(MTR.IsItemLink("just a string") == false, "IsItemLink: plain text")
assert(MTR.IsItemLink(nil) == false, "IsItemLink: nil returns false")

assert(MTR.ItemLinkToName("[Epic Sword]") == "Epic Sword", "ItemLinkToName extracts name")
assert(MTR.ItemLinkToName("no brackets") == nil, "ItemLinkToName: no brackets returns nil")

-- Chat escape stripping
assert(MTR.StripChatEscapes("|cff000000Hello|r") == "Hello", "StripChatEscapes removes color codes")
assert(MTR.StripChatEscapes("Hello\nWorld") == "Hello World", "StripChatEscapes removes newlines")
assert(MTR.StripChatEscapes(nil) == "", "StripChatEscapes: nil returns empty")

-- ============================================================================
-- SUMMARY
-- ============================================================================

section("Test Summary")
print(string.format("Total: %d | Passed: %d | Failed: %d", TOTAL_TESTS, PASSED_TESTS, FAILED_TESTS))

if FAILED_TESTS == 0 then
    print("\n🎉 All core tests passed!")
    os.exit(0)
else
    print("\n❌ Some tests failed!")
    os.exit(1)
end
