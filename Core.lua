-- Wick's Demons and Things
-- Core.lua: namespace, saved variables, event dispatch, slash command,
-- and the chrome adapter the bars draw with.

local ADDON, ns = ...

local Core = WickCore
if not Core then
    -- WickCore is missing or switched off.
    --
    -- The TOC asks for it with OptionalDeps rather than Dependencies on
    -- purpose. A hard dependency makes the client refuse to load this addon
    -- at all, so nothing of ours runs and the player is told nothing beyond
    -- a greyed line in the AddOns list. Loading anyway lets us say what is
    -- wrong and where to get it.
    --
    -- One line for the lot of them, not one per addon: with the whole suite
    -- installed and WickCore switched off, a line each would be a wall.
    local need = _G.WicksNeedCore
    if not need then
        need = {}
        _G.WicksNeedCore = need
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_LOGIN")
        f:SetScript("OnEvent", function()
            table.sort(need)
            print(("|cff4FC778Wick's Mods|r: %s %s WickCore, which is not installed or not switched on. It is in the same download as the rest of the suite: |cffD4C8A1wicksmods.com|r")
                :format(table.concat(need, ", "), #need == 1 and "needs" or "need"))
        end)
    end
    need[#need + 1] = "Wick's Demons and Things"
    return
end
local Chrome = Core.Chrome

-- No saved variable through WickCore: the two tables below stay as they are.
local A = Core:NewAddon("WicksDemonsAndThings", {
    title   = "Wick's Demons and Things",
    version = (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)(ADDON, "Version"),
})

WicksDemonsDB = WicksDemonsDB or {
    version = 1,
    soul   = { point = "CENTER", x = -180, y = 200, hidden = false, locked = false },
    pet    = { point = "CENTER", x =  180, y = 200, hidden = false, locked = false },
    cd     = { point = "CENTER", x =    0, y = 156, hidden = false, locked = false },
    shard  = { point = "CENTER", x =    0, y = 240, hidden = false, locked = false },
    minimap = { hide = false, angle = 200 },
}
WicksDemonsDB.soul    = WicksDemonsDB.soul    or { point = "CENTER", x = -180, y = 200, hidden = false, locked = false }
WicksDemonsDB.pet     = WicksDemonsDB.pet     or { point = "CENTER", x =  180, y = 200, hidden = false, locked = false }
WicksDemonsDB.cd      = WicksDemonsDB.cd      or { point = "CENTER", x =    0, y = 156, hidden = false, locked = false }
WicksDemonsDB.shard   = WicksDemonsDB.shard   or { point = "CENTER", x =    0, y = 240, hidden = false, locked = false }
WicksDemonsDB.minimap = WicksDemonsDB.minimap or { hide = false, angle = 200 }

WicksDemonsCharDB = WicksDemonsCharDB or { version = 1 }

WicksDemons = WicksDemons or {}
local WD = WicksDemons
ns.WD = WD

WD.ADDON = ADDON
WD.A = A

-- ============================================================
-- Chrome adapter
-- ============================================================
-- The bars and the panel draw through here. Palette tokens are
-- references into Chrome.Colors, never copies, so a look or theme change
-- repaints everything at once; the dim label colour is the addon's own.
WD.Chrome = Chrome
WD.C = {
    BG     = Chrome.Colors.voidBG,
    HEADER = Chrome.Colors.shadow,
    BORDER = Chrome.Colors.border,
    GREEN  = Chrome.Colors.fel,
    TEXT   = Chrome.Colors.text,
    DIM    = { 0.42, 0.35, 0.54, 1 },
}
function WD.NewTexture(parent, layer, c) return Chrome:Texture(parent, layer or "BACKGROUND", c) end
function WD.AddBorder(frame, c) Chrome:AddBorder(frame, c) end
function WD.AddCornerAccents(frame) Chrome:AddBrackets(frame) end
-- A colour set on a region after it was made is remembered by Chrome, so
-- a theme change finds it; a colour that is not a token is left alone.
function WD.Ink(fs, c, a)
    fs:SetTextColor(c[1], c[2], c[3], a or c[4] or 1)
    Chrome:Register(fs, c, "text", a)
end
function WD.Paint(tex, c, a)
    tex:SetColorTexture(c[1], c[2], c[3], a or c[4] or 1)
    Chrome:Register(tex, c, "texture", a)
end
function WD.Tint(tex, c, a)
    tex:SetVertexColor(c[1], c[2], c[3], a or c[4] or 1)
    Chrome:Register(tex, c, "vertex", a)
end
function WD.NewText(parent, size, c)
    local f = parent:CreateFontString(nil, "OVERLAY")
    Chrome:SetFont(f, size or 11)
    if c then WD.Ink(f, c) end
    return f
end

local _, playerClass = UnitClass("player")
WD.playerClass = playerClass
WD.isWarlock   = (playerClass == "WARLOCK")

-- Soul Shard itemId. Constant since TBC; used by ShardCounter and any
-- slash-status diagnostic.
WD.SHARD_ITEM_ID = 6265

-- With Wick's UI loaded, its movers place the bars (/wui move) and the
-- locks here stand down for them; WickCore keeps the list.
WD.claimed = setmetatable({}, { __mode = "k" })
function WD:Movable(frame, key, title, cfg)
    local Chrome = WickCore and WickCore.Chrome
    if not (Chrome and Chrome.RegisterMovable) then return end
    Chrome:RegisterMovable(frame, {
        key = key, title = title, addon = ADDON,
        default = ("%s,UIParent,%s,%d,%d"):format(cfg.point or "CENTER", cfg.point or "CENTER", cfg.x or 0, cfg.y or 0),
        onClaim = function() WD.claimed[frame] = true end,
    })
end
function WD:Claimed(frame) return frame ~= nil and self.claimed[frame] == true end
function WD:MovedByUI()
    A:Print("Wick's UI places the bars. Type /wui move to drag them, and right-click a mover to put it back.")
end

-- Pub/sub for module wiring (bar refresh, talent change, combat in/out).
WD._listeners = {}
function WD:On(event, fn)
    self._listeners[event] = self._listeners[event] or {}
    table.insert(self._listeners[event], fn)
end
function WD:Emit(event, ...)
    local list = self._listeners[event]
    if not list then return end
    for _, fn in ipairs(list) do
        local ok, err = pcall(fn, ...)
        if not ok then
            A:Print(("error in %s: %s"):format(event, tostring(err)))
        end
    end
end

-- Event frame
local f = CreateFrame("Frame")
WD.eventFrame = f

local EVENTS = {
    "PLAYER_LOGIN",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
    "BAG_UPDATE",
    "UNIT_PET",
    "PLAYER_TALENT_UPDATE",
    "CHARACTER_POINTS_CHANGED",
    "SPELLS_CHANGED",
}
for _, e in ipairs(EVENTS) do
    pcall(f.RegisterEvent, f, e)
end

f:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        if not WD.isWarlock then
            A:Print("loaded (non-warlock: viewer mode).")
        else
            A:Print("loaded. /wdt for help.")
        end
        WD:Emit("LOGIN")
        return
    end
    if event == "PLAYER_REGEN_DISABLED" then
        WD.inCombat = true
        WD:Emit("COMBAT_START")
    elseif event == "PLAYER_REGEN_ENABLED" then
        WD.inCombat = false
        WD:Emit("COMBAT_END")
    end
    WD:Emit(event, ...)
end)

-- ============================================================
-- Spec detection (active talent tab — for cooldown filtering)
-- ============================================================
-- Warlock tabs in TBC: 1 Affliction, 2 Demonology, 3 Destruction.
local WARLOCK_SPEC_BY_TAB = { "affliction", "demonology", "destruction" }
function WD:GetActiveSpec()
    if not self.isWarlock then return nil end
    if not GetNumTalentTabs or not GetTalentTabInfo then return nil end
    local ok, result = pcall(function()
        local maxIdx, maxPts = 0, -1
        local n = GetNumTalentTabs() or 0
        for i = 1, n do
            local _, _, points = GetTalentTabInfo(i)
            if (points or 0) > maxPts then
                maxPts = points or 0
                maxIdx = i
            end
        end
        if maxPts <= 0 then return nil end
        return WARLOCK_SPEC_BY_TAB[maxIdx]
    end)
    if ok then return result end
    return nil
end

-- ============================================================
-- Keybinding labels (Esc -> Key Bindings -> AddOns)
-- ============================================================
BINDING_HEADER_WICKSDEMONS = "Wick's Demons and Things"

BINDING_NAME_WICKSDEMONS_TOGGLE_SOUL  = "Toggle soul bar"
BINDING_NAME_WICKSDEMONS_TOGGLE_PET   = "Toggle pet bar"
BINDING_NAME_WICKSDEMONS_TOGGLE_CD    = "Toggle cooldown bar"
BINDING_NAME_WICKSDEMONS_TOGGLE_SHARD = "Toggle shard counter"

-- ============================================================
-- Slash command
-- ============================================================
SLASH_WICKSDEMONS1 = "/wdt"
SLASH_WICKSDEMONS2 = "/wicksdemons"
SlashCmdList.WICKSDEMONS = function(input)
    input = (input or ""):gsub("^%s*(.-)%s*$", "%1"):lower()

    local function toggle(mod)
        if mod and mod.Toggle then mod:Toggle() end
    end
    local function reset(mod)
        if mod and mod.ResetPosition then mod:ResetPosition() end
    end

    if input == "" then
        if WD.UI and WD.UI.Toggle then WD.UI:Toggle() end
        return
    end
    if input == "help" or input == "?" then
        A:Print("commands:")
        print("  /wdt             open options panel")
        print("  /wdt soul        toggle soul bar")
        print("  /wdt pet         toggle pet bar")
        print("  /wdt cd          toggle cooldown / proc bar")
        print("  /wdt shard       toggle shard counter")
        print("  /wdt lock        lock all bars in place")
        print("  /wdt unlock      allow dragging bars")
        print("  /wdt reset       reset all bar positions")
        print("  /wdt status      print diagnostic info")
        return
    end

    if input == "soul"  then toggle(WD.SoulBar);       return end
    if input == "pet"   then toggle(WD.PetBar);        return end
    if input == "cd"    then toggle(WD.Cooldowns);     return end
    if input == "shard" then toggle(WD.ShardCounter);  return end

    if input == "lock" then
        for _, key in ipairs({ "soul", "pet", "cd", "shard" }) do
            WicksDemonsDB[key].locked = true
        end
        A:Print("bars locked.")
        return
    end
    if input == "unlock" then
        for _, key in ipairs({ "soul", "pet", "cd", "shard" }) do
            WicksDemonsDB[key].locked = false
        end
        A:Print("bars unlocked.")
        if next(WD.claimed) then WD:MovedByUI() end
        return
    end
    if input == "reset" then
        reset(WD.SoulBar); reset(WD.PetBar); reset(WD.Cooldowns); reset(WD.ShardCounter)
        A:Print("positions reset.")
        return
    end
    if input == "status" then
        A:Print("status:")
        print(("  warlock: %s   spec: %s"):format(
            tostring(WD.isWarlock), tostring(WD:GetActiveSpec() or "(unknown)")))
        for _, key in ipairs({ "soul", "pet", "cd", "shard" }) do
            local cfg = WicksDemonsDB[key]
            print(("  %s: hidden=%s locked=%s point=%s x=%d y=%d"):format(
                key, tostring(cfg.hidden), tostring(cfg.locked),
                cfg.point or "?", cfg.x or 0, cfg.y or 0))
        end
        if WD.ShardCounter and WD.ShardCounter.Count then
            print(("  shards: %d"):format(WD.ShardCounter:Count()))
        end
        return
    end

    A:Print("unknown command. Try /wdt help")
end

-- ============================================================
-- WickCore options page and launcher line
-- ============================================================
-- Which bars show, under Wick's Mods in the game's Options; the rest
-- (locks, positions, diagnostics) is in the addon's own panel.
local BARS = {
    { "soul",  "Soul bar",            "SoulBar" },
    { "pet",   "Pet bar",             "PetBar" },
    { "cd",    "Cooldowns and procs", "Cooldowns" },
    { "shard", "Shard counter",       "ShardCounter" },
}
local function openPanel() if WD.UI and WD.UI.Toggle then WD.UI:Toggle() end end

function A:OnEnable()
    self:RegisterOptions(function(body)
        local O = Core.Options
        local y = 0
        y = O:Note(body, "A warlock's bars: the soul bar, the pet bar, the cooldown and proc strip, and the shard counter. They draw in the look and theme chosen above.", y)
        y = O:Heading(body, "Bars", y)
        for _, row in ipairs(BARS) do
            local key, label, modName = row[1], row[2], row[3]
            y = O:Check(body, label,
                function() return not (WicksDemonsDB[key] and WicksDemonsDB[key].hidden) end,
                function(v)
                    local mod = WD[modName]
                    if v then if mod and mod.Show then mod:Show() end
                    else if mod and mod.Hide then mod:Hide() end end
                end, y)
        end
        y = O:Button(body, "Open the panel", openPanel, y, 160)
        y = O:Note(body, "Locks, positions and a status readout are in the panel, or under /wdt help.", y)
    end)
    self:RegisterLauncher({
        onClick = openPanel,
        tooltip = function(tt)
            tt:AddLine(Chrome:TitleMarkup("Wick's Demons and Things"))
            tt:AddLine("The warlock bars. Click for the panel.", 1, 1, 1)
        end,
    })
end
