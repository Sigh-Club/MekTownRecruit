# MekTown Recruit

An all-in-one guild management suite for WoW 3.3.5a, designed to make running a guild easier for officers and members alike. Replaces half a dozen separate addons and external spreadsheets with one unified, in-game interface.

<img width="1024" height="1536" alt="MTR" src="https://github.com/user-attachments/assets/814b659b-cc70-4102-91fd-6709ab58a32b" />

## Addon Info

- **Current Version:** `2.2.0`
- **Target Client:** `30300` (WoW 3.3.5a)
- **SavedVariables:** `MekTownRecruitDB`

## Features

### Recruit Scanner
Automatically spots and invites players looking for a guild based on keyword matching, with built-in configurable welcome whispers. Set it and forget it — passive recruitment without spamming global channels.

### DKP System
Full ledger for awarding, deducting, and syncing DKP between officers. Includes an in-game auctioneer and roll tracker for loot distribution. All transactions sync instantly across online officers.

### Attendance Tracking
One-click raid attendance snapshots and boss kill tracking. Simple, fast, and synced.

### Guild Tree
Maps alts to mains by scanning officer/public notes. Everyone can see who is who without asking in guild chat.

### Character Vault & Guild Bank Ledger
A persistent, searchable history of guild bank items and gold that far exceeds the default 3.3.5a log limit. Automatically deduplicates transactions so multiple officers scanning doesn't create duplicate entries. Gold logs are tracked natively with a fallback that monitors bank balance directly.

### Inactivity Management
Tracks inactive players and syncs a safe whitelist across officers. Guild Master (Rank 0) and Officers (Rank 1) are hard-coded immune to inactivity kicks. Whitelisted members (vacation, military deployment, etc.) are also protected.

### Group Radar & LFG
Member-facing tools that parse global LFG/LFM chat into a clickable, filterable interface. Makes finding dungeon and raid groups painless for everyone.

### Guild Ads
Automated guild advertisement posting to configurable channels on a timer.

### Peer-to-Peer Sync Engine
The backbone of the addon. Silently syncs DKP, recruits, bank ledgers, inactivity data, guild trees, and character vaults between all guild members using chunked `SendAddonMessage` packets (strict 255-byte compliance). SHA-1 style hashing and revision IDs prevent data corruption. Members receive data; only officers can broadcast.

### Loot Detection
Event-driven loot prompts with configurable quality thresholds. Catches loot drops in real-time and alerts officers.

### Auction & Roll System
Integrated in-game auctioneer and roll tracker for fair loot distribution during raids. Item links are preserved as clickable links in all raid/party/guild announcements. When a winner is declared, the addon automatically gives the item to the winner via Master Loot if the loot window is open — no manual distribution needed.

## Permissions

Tabs are visible to everyone, but buttons that change guild data are restricted.

**Officers & Guild Master:**
Full access — recruit scanner, DKP modifications, auctions, inactivity kicks, and manual sync repairs.

**Members:**
View-only access to Guild Tree, DKP Standings, Character Vault, Guild Bank Ledger. Full access to Group Radar and LFG tools.

## Installation

1. Close your game client.
2. Download and drop the `MekTownRecruit` folder into your AddOns directory:
   `World of Warcraft/Interface/AddOns/MekTownRecruit`
3. Launch the game, click **AddOns** at character select, and enable **MekTown Recruit**.
4. In-game, type `/mek config` to open the main window.

## Getting Started

1. **Settings:** `/mek config`
2. **Verify Sync:** `/mek sync status`
3. **Character Vault:** `/mek chars`
4. **Group Finder:** `/mek radar` or `/mek lfg`

## Command Reference

### General
- `/mek help` - Shows all available commands.
- `/mek config` - Opens the main UI.
- `/mek on` / `/mek off` - Toggles the recruiting scanner.
- `/mtrid` - Shows your current guild identity mapping.

### DKP & Raiding
- `/mek dkp standings` - View current DKP balances.
- `/mek dkp balance <name>` - Check a specific player.
- `/mek att start [zone]` - Begin attendance tracking.
- `/mek att end` - End tracking.

### Utilities
- `/mek chars` - Open Character Vault.
- `/mek radar` - Open Group Radar.
- `/mek lfg` - Post LFG.

### Officer Commands (Restricted)
- `/mek dkp award <name> <points> [reason]`
- `/mek dkp deduct <name> <points> [reason]`
- `/mek dkp set <name> <points>` (GM only)
- `/mek dkp snapshot`
- `/mek inactive kick`
- `/mek inactive whitelist add/remove <name>`
- `/mek sync repair all` - Force a manual sync request.

## Under the Hood

Built strictly for the 3.3.5a engine. No retail `C_Timer` mixins. All heavy sync operations are chunked to respect legacy 255-byte chat limits. A centralized master tick scheduler (`MTR.TickAdd`) replaces dozens of individual `OnUpdate` frames, keeping CPU overhead minimal during raids.

```text
MekTownRecruit/
├── Core.lua         (Init, settings, utilities)
├── GuildData.lua    (Guild identity, sync primitives)
├── Settings.lua     (Configuration defaults)
├── DKP.lua          (DKP system & sync)
├── Auction.lua      (Auctioneer)
├── Roll.lua         (Roll tracker)
├── Recruit.lua      (Scanner & invites)
├── Attendance.lua   (Raid tracking)
├── Inactivity.lua   (Kick whitelist & immunity)
├── LootDetect.lua   (Loot event detection)
├── GuildAds.lua     (Auto-ad poster)
├── GuildTree.lua    (Alt/main tracking)
├── GroupRadar.lua   (LFG tools)
├── CharVault.lua    (Character vault & bank ledger)
├── Minimap.lua      (Minimap button)
├── Commands.lua     (Slash router)
└── UI_*.lua         (Interface panels)
```

## Credits

Thanks to all the officers and testers who broke this repeatedly until it worked, and to the 3.3.5a UI dev community for the engine workarounds.

---

### v2.2.0
- Fixed item links — roll/auction announcements now show clickable links instead of plain text
- Auto-give loot — winner automatically receives the item via Master Loot when loot window is open

### v2.1.1
- Sync engine hardened for concurrent officer broadcasts
- Guild-agnostic defaults and UI text
- Inactivity immunity for GM/Officers, synced whitelist
- LootDetect script handler fix
- Same-revision sync acceptance for append-only logs
- 62 automated tests
