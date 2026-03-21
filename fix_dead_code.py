import re

# Auction.lua
with open("Auction.lua", "r") as f:
    text = f.read()
text = re.sub(r'local amount = (.*?)\n', r'local _ = \1\n', text)
with open("Auction.lua", "w") as f:
    f.write(text)

# Inactivity.lua
with open("Inactivity.lua", "r") as f:
    text = f.read()
text = re.sub(r'local totalDays = (.*?)\n', r'local _ = \1\n', text)
with open("Inactivity.lua", "w") as f:
    f.write(text)

# Core.lua
with open("Core.lua", "r") as f:
    text = f.read()
text = re.sub(r'local function GetActiveProfileTable\(\)[\s\S]*?end\n\n', '', text)
with open("Core.lua", "w") as f:
    f.write(text)

# GuildTree.lua
with open("GuildTree.lua", "r") as f:
    text = f.read()
text = re.sub(r'local function GetAlts\(mainName\)[\s\S]*?end\n\n', '', text)
with open("GuildTree.lua", "w") as f:
    f.write(text)

# Settings.lua
with open("Settings.lua", "r") as f:
    text = f.read()
text = re.sub(r'local function splitPath\(path\)[\s\S]*?end\n\n', '', text)
with open("Settings.lua", "w") as f:
    f.write(text)

# CharVault.lua
with open("CharVault.lua", "r") as f:
    text = f.read()
text = re.sub(r'local function GBL_ParseTextLogMessage\(tab, rawMsg, scanBy\)[\s\S]*?end\n\n', '', text)
text = re.sub(r'local function GBL_ScrapeVisibleLogFrame\(tab, entries, scanBy\)[\s\S]*?end\n\n', '', text)
with open("CharVault.lua", "w") as f:
    f.write(text)

