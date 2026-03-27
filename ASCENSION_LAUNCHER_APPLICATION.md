# Addon Submission: MekTown Recruit

**Author:** Talzanar
**Repository:** [https://github.com/Talzanar/MekTownRecruit](https://github.com/Talzanar/MekTownRecruit)
**Version:** 2.1.1
**Client:** WoW 3.3.5a (Ascension Classless)

---

## 📖 Overview

**MekTown Recruit** is a comprehensive, all-in-one guild management suite built specifically for the Ascension 3.3.5a environment. 

Originally developed to manage the massive scale and daily operations of the *MekTown Choppaz* on Area 52, it has evolved into a robust, peer-to-peer synchronized toolkit that replaces the need for half a dozen separate, aging addons and external spreadsheets. 

It provides an intuitive, unified interface where officers can manage the backend of the guild, while regular members get access to powerful, centralized LFG and vault tools.

## ✨ Core Features & Why The Community Needs It

### 1. Peer-to-Peer Synchronization (The Backbone)
Ascension guilds are highly active, with multiple officers operating across different timezones. MekTown Recruit utilizes a highly optimized, custom `SendAddonMessage` sync engine (chunked to strictly respect legacy 255-byte limits) with SHA-1 style hashing and Revision IDs.
* **Why it matters:** DKP balances, Guild Bank Ledgers, Kick Logs, and Inactivity Whitelists are automatically and silently synchronized between online officers. No more desyncs or "who has the latest spreadsheet?" moments.

### 2. The Permanent Guild Bank & Gold Ledger
The default 3.3.5a guild bank log is notoriously short, often wiping out history after a busy raid night. MekTown Recruit solves this.
* **Features:** Maintains a permanent, searchable, deduplicated ledger of both items **and gold**. Because the 3.3.5 API for gold logs can be flaky, the addon features a custom fallback that dynamically tracks real-time gold deltas when the bank is open.
* **Why it matters:** Ultimate transparency and security for guild banks. Officers can track exactly who deposited or withdrew what, days or weeks after it happened.

### 3. Integrated DKP & Loot Management
A fully functional DKP system built directly into the game.
* **Features:** One-click DKP awards for boss kills or attendance, player balance tracking, and an integrated in-game Auctioneer and Roll Tracker for loot distribution.
* **Why it matters:** Keeps loot drama to a minimum. All DKP transactions are instantly synced to other officers, and members can view the live DKP standings directly in their addon window.

### 4. Smart Recruitment & Member Management
* **Features:** A highly configurable keyword scanner that monitors chat for players looking for guilds, automatically sending customizable welcome whispers and invites. It also includes an Inactivity Manager to safely prune the roster while protecting whitelisted members (like deployed military or players on vacation).
* **Why it matters:** Guilds can passively recruit targeted players without spamming global channels. Roster management becomes a 2-minute task rather than a 2-hour chore.

### 5. Member-Facing Tools (Group Radar)
MekTown Recruit isn't just for officers.
* **Features:** Regular guild members get access to **Group Radar**, a clean UI that parses global LFG/LFM chat and organizes it into a clickable, filterable interface, alongside a clean interface for viewing the Guild Tree (Alts mapped to Mains) and the Character Vault.
* **Why it matters:** Gives every member of the guild a reason to install the addon, drastically improving their daily quality of life on Ascension.

## 🛠️ Technical Adherence & Stability

I built this project strictly for the 3.3.5a engine limits. It is highly optimized to ensure it creates zero combat lag or frame drops, even during heavy sync operations.

* **No Retail API Bleed:** Strictly utilizes classic `FrameXML` and `CreateFrame`. No modern `C_Timer` or retail mixins were used, preventing Lua errors on the Ascension client.
* **Zero OnUpdate Spam:** Instead of dozens of individual tickers, the addon uses a centralized `MTR.TickAdd()` master scheduler. Only one frame fires an `OnUpdate`, drastically reducing CPU overhead.
* **Safe Permissions:** Regular guild members can *receive* sync data (like DKP standings or Vault snapshots) but are hard-coded to be unable to *broadcast* sync pings or scans, preventing malicious database manipulation.
* **Raid Safe:** Includes user-toggles to automatically hide all addon windows the moment a player enters combat or zones into an instance, preventing UI-related deaths.

## 📌 Summary

**MekTown Recruit** brings modern, Discord-level guild management directly into the 3.3.5a client. It is stable, heavily tested in live environments, and designed to respect both the game's engine limits and the player's screen space. 

I believe it would be an incredibly valuable addition to the Ascension Launcher for any guild looking to streamline their operations.

Thank you for your time and consideration!
