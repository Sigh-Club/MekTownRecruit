# Fix Item Links & Auto-Give Loot

## Problem 1: Item links displayed as plain text

### Root Cause
`MTR.DKPAnnounce()` (DKP.lua:188) calls `MTR.SendChatSafe(msg, chan)` without passing `allowLinks`. `SendChatSafe` calls `StripChatEscapes(msg, nil)`, which strips `|Hitem:...|h[Name]|h` down to just the name text — destroying the clickable link.

### Fix

#### 1. DKP.lua — Add `allowLinks` parameter to `DKPAnnounce` (line 188)

**Before:**
```lua
function MTR.DKPAnnounce(msg, useRW)
    local chan
    if IsInRaid() then
        chan = "RAID"
    elseif IsInGroup() then
        chan = "PARTY"
    else
        chan = "GUILD"
    end
    MTR.SendChatSafe(msg, chan)
    if useRW and IsInRaid() and (IsRaidLeader() or UnitIsGroupAssistant("player")) then
        MTR.SendChatSafe(msg, "RAID_WARNING")
    end
end
```

**After:**
```lua
function MTR.DKPAnnounce(msg, useRW, allowLinks)
    local chan
    if IsInRaid() then
        chan = "RAID"
    elseif IsInGroup() then
        chan = "PARTY"
    else
        chan = "GUILD"
    end
    MTR.SendChatSafe(msg, chan, nil, nil, allowLinks)
    if useRW and IsInRaid() and (IsRaidLeader() or UnitIsGroupAssistant("player")) then
        MTR.SendChatSafe(msg, "RAID_WARNING", nil, nil, allowLinks)
    end
end
```

#### 2. Roll.lua — Update all 6 `DKPAnnounce` calls to pass `true` for `allowLinks`

**Line 120-121** (TIE announcement):
```lua
-- Before:
MTR.DKPAnnounce(">>> TIE for "..tieLink.." between "..names.."! Reroll: /roll. You have "..
    (MTR.activeRoll.rollDuration or 60).."s!", MTR.activeRoll.useRW)
-- After:
MTR.DKPAnnounce(">>> TIE for "..tieLink.." between "..names.."! Reroll: /roll. You have "..
    (MTR.activeRoll.rollDuration or 60).."s!", MTR.activeRoll.useRW, true)
```

**Line 129-131** (Winner announcement):
```lua
-- Before:
MTR.DKPAnnounce(msg, MTR.activeRoll.useRW)
-- After:
MTR.DKPAnnounce(msg, MTR.activeRoll.useRW, true)
```

**Line 220** (Close Rolls button):
```lua
-- Before:
MTR.DKPAnnounce(">>> ROLLS CLOSED for "..(MTR.activeRoll.itemLink or "["..MTR.activeRoll.item.."]")..". Declaring winner...", MTR.activeRoll.useRW)
-- After:
MTR.DKPAnnounce(">>> ROLLS CLOSED for "..(MTR.activeRoll.itemLink or "["..MTR.activeRoll.item.."]")..". Declaring winner...", MTR.activeRoll.useRW, true)
```

**Line 231** (Cancel button):
```lua
-- Before:
MTR.DKPAnnounce(">>> Roll CANCELLED for "..(MTR.activeRoll.itemLink or "["..MTR.activeRoll.item.."]")..".", MTR.activeRoll.useRW)
-- After:
MTR.DKPAnnounce(">>> Roll CANCELLED for "..(MTR.activeRoll.itemLink or "["..MTR.activeRoll.item.."]")..".", MTR.activeRoll.useRW, true)
```

**Line 250** (Timer auto-close):
```lua
-- Before:
MTR.DKPAnnounce(">>> ROLLS CLOSED for "..(MTR.activeRoll.itemLink or "["..MTR.activeRoll.item.."]")..". Calculating...", MTR.activeRoll.useRW)
-- After:
MTR.DKPAnnounce(">>> ROLLS CLOSED for "..(MTR.activeRoll.itemLink or "["..MTR.activeRoll.item.."]")..". Calculating...", MTR.activeRoll.useRW, true)
```

**Line 306** (Roll open announcement):
```lua
-- Before:
MTR.DKPAnnounce(">>> ROLL FOR LOOT: "..announceItem.." ("..rollType..") - /roll"..timeStr, useRW)
-- After:
MTR.DKPAnnounce(">>> ROLL FOR LOOT: "..announceItem.." ("..rollType..") - /roll"..timeStr, useRW, true)
```

#### 3. Roll.lua — Fix roll frame title to show clickable item link (line 46)

**Before:**
```lua
rollFrame._title:SetText("|cffd4af37["..MTR.activeRoll.item.."] "..MTR.activeRoll.rollType.."|r")
```

**After:**
```lua
rollFrame._title:SetText("|cffd4af37"..(MTR.activeRoll.itemLink or "["..MTR.activeRoll.item.."]").." "..MTR.activeRoll.rollType.."|r")
```

#### 4. Auction.lua — Update all `DKPAnnounce` calls to pass `true` for `allowLinks`

**Line 151-153** (Award Highest):
```lua
-- Before:
local msg = string.format(">>> AUCTION WINNER: %s wins [%s] for %d DKP! New balance: %d pts.",
    entry.name, MTR.activeBid.item, entry.amount, MTR.DKPBalance(entry.name))
MTR.DKPAnnounce(msg, MTR.activeBid.useRW)
-- After:
local winLink = MTR.activeBid.itemLink or ("["..MTR.activeBid.item.."]")
local msg = string.format(">>> AUCTION WINNER: %s wins %s for %d DKP! New balance: %d pts.",
    entry.name, winLink, entry.amount, MTR.DKPBalance(entry.name))
MTR.DKPAnnounce(msg, MTR.activeBid.useRW, true)
```

**Line 183-185** (Award Player):
```lua
-- Before:
local msg = string.format(">>> AUCTION WINNER: %s wins [%s] for %d DKP! New balance: %d pts.",
    n, MTR.activeBid.item, amt, MTR.DKPBalance(n))
MTR.DKPAnnounce(msg, MTR.activeBid.useRW)
-- After:
local winLink = MTR.activeBid.itemLink or ("["..MTR.activeBid.item.."]")
local msg = string.format(">>> AUCTION WINNER: %s wins %s for %d DKP! New balance: %d pts.",
    n, winLink, amt, MTR.DKPBalance(n))
MTR.DKPAnnounce(msg, MTR.activeBid.useRW, true)
```

**Line 203** (Close Bids):
```lua
-- Before:
MTR.DKPAnnounce(">>> BIDDING CLOSED for "..(MTR.activeBid.itemLink or "["..MTR.activeBid.item.."]")..". Awarding shortly...", MTR.activeBid.useRW)
-- After:
MTR.DKPAnnounce(">>> BIDDING CLOSED for "..(MTR.activeBid.itemLink or "["..MTR.activeBid.item.."]")..". Awarding shortly...", MTR.activeBid.useRW, true)
```

**Line 214** (Cancel):
```lua
-- Before:
MTR.DKPAnnounce(">>> Auction CANCELLED for "..(MTR.activeBid.itemLink or "["..MTR.activeBid.item.."]")..".", MTR.activeBid.useRW)
-- After:
MTR.DKPAnnounce(">>> Auction CANCELLED for "..(MTR.activeBid.itemLink or "["..MTR.activeBid.item.."]")..".", MTR.activeBid.useRW, true)
```

**Lines 232-233** (Timer auto-close):
```lua
-- Before:
MTR.DKPAnnounce(">>> BIDDING CLOSED for "..(MTR.activeBid.itemLink or "["..MTR.activeBid.item.."]")..". Awarding shortly...", MTR.activeBid.useRW)
-- After:
MTR.DKPAnnounce(">>> BIDDING CLOSED for "..(MTR.activeBid.itemLink or "["..MTR.activeBid.item.."]")..". Awarding shortly...", MTR.activeBid.useRW, true)
```

#### 5. Auction.lua — Fix auction frame title (line 43)

**Before:**
```lua
auctionFrame._title:SetText("|cffd4af37" .. MTR.activeBid.item .. "|r")
```

**After:**
```lua
auctionFrame._title:SetText("|cffd4af37" .. (MTR.activeBid.itemLink or "["..MTR.activeBid.item.."]") .. "|r")
```

---

## Problem 2: Auto-give loot to winner

### Implementation

#### 1. Core.lua — Add `MTR.TryGiveLoot(itemLink, playerName)` utility

Add this function near the other utility functions (around line 520, after `IsItemLink`):

```lua
function MTR.TryGiveLoot(itemLink, playerName)
    if not itemLink or not playerName then return false end

    if not LootFrame or not LootFrame:IsShown() then
        MTR.MPE("Loot window not open — please give "..(MTR.ItemLinkToName(itemLink) or "item").." to "..playerName.." manually.")
        return false
    end

    if not (IsRaidLeader() or UnitIsGroupAssistant("player")) then
        MTR.MPE("You are not raid leader/assistant — cannot auto-give loot.")
        return false
    end

    local targetName = playerName:match("^([^%-]+)") or playerName
    local numSlots = GetNumLootItems()
    for slot = 1, numSlots do
        local slotLink = GetLootSlotLink(slot)
        if slotLink and slotLink == itemLink then
            for ci = 1, 40 do
                local candName = GetMasterLootCandidate(slot, ci)
                if not candName then break end
                local candShort = candName:match("^([^%-]+)") or candName
                if candShort == targetName then
                    GiveMasterLoot(slot, ci)
                    MTR.MP("|cff00ff00Auto-gave |r"..itemLink.."|cff00ff00 to "..playerName.."|r")
                    return true
                end
            end
            MTR.MPE(playerName.." not found in loot candidates for this item. Please distribute manually.")
            return false
        end
    end

    MTR.MPE("Item "..(MTR.ItemLinkToName(itemLink) or "?").." not found in loot window. Please distribute manually.")
    return false
end
```

#### 2. Roll.lua — Call `TryGiveLoot` from `RollDeclareWinner` (after line 131)

Insert after the `MTR.DKPAnnounce(msg, ...)` line (line 131) and before the bid log insert (line 133):

```lua
    MTR.TryGiveLoot(MTR.activeRoll.itemLink, winner)
```

#### 3. Auction.lua — Call `TryGiveLoot` from "Award Highest" handler (after line 153)

Insert after `MTR.DKPAnnounce(msg, ...)` (line 153) and before `MTR.activeBid = nil` (line 154):

```lua
                    MTR.TryGiveLoot(MTR.activeBid.itemLink, entry.name)
```

#### 4. Auction.lua — Call `TryGiveLoot` from "Award Player" handler (after line 185)

Insert after `MTR.DKPAnnounce(msg, ...)` (line 185) and before `MTR.activeBid = nil` (line 186):

```lua
                    MTR.TryGiveLoot(MTR.activeBid.itemLink, n)
```

---

## Summary of all file changes

| File | Change |
|------|--------|
| `DKP.lua:188-201` | Add `allowLinks` param to `DKPAnnounce`, pass through to `SendChatSafe` |
| `Roll.lua:46` | Frame title: use `itemLink` instead of `[item]` |
| `Roll.lua:120-121` | TIE announce: pass `true` for allowLinks |
| `Roll.lua:129-131` | Winner announce: pass `true` for allowLinks |
| `Roll.lua:131` | After winner announce: call `TryGiveLoot` |
| `Roll.lua:220` | Close Rolls: pass `true` for allowLinks |
| `Roll.lua:231` | Cancel: pass `true` for allowLinks |
| `Roll.lua:250` | Timer close: pass `true` for allowLinks |
| `Roll.lua:306` | Roll open: pass `true` for allowLinks |
| `Auction.lua:43` | Frame title: use `itemLink` |
| `Auction.lua:151-153` | Award Highest: use `itemLink` in msg, pass `true` for allowLinks, call `TryGiveLoot` |
| `Auction.lua:183-185` | Award Player: use `itemLink` in msg, pass `true` for allowLinks, call `TryGiveLoot` |
| `Auction.lua:203` | Close Bids: pass `true` for allowLinks |
| `Auction.lua:214` | Cancel: pass `true` for allowLinks |
| `Auction.lua:232-233` | Timer close: pass `true` for allowLinks |
| `Core.lua:~520` | Add `MTR.TryGiveLoot` utility function |
