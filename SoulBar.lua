-- Wick's Demons and Things
-- SoulBar.lua: secure-action strip for warlock utility items + rituals.
--   * Use Healthstone / Use Soulstone — type=item, name lookup auto-resolves
--     to whichever rank is in the bag. If none present, click silently no-ops.
--   * Create Healthstone / Create Soulstone / Ritual of Summoning /
--     Ritual of Souls / Eye of Kilrogg — type=spell. Filtered to spells the
--     warlock actually knows.

local ADDON, ns = ...
if not WickCore then return end   -- said once in Core.lua
local WD = WicksDemons

WD.SoulBar = {}
local SB = WD.SoulBar

-- Palette and chrome from WickCore through Core.lua's adapter, so the
-- bar follows the suite's look and theme.
local C_BG, C_BORDER, C_GREEN, C_TEXT_NORMAL, C_TEXT_DIM = WD.C.BG, WD.C.BORDER, WD.C.GREEN, WD.C.TEXT, WD.C.DIM
local Ink, Paint = WD.Ink, WD.Paint

local ICON_SIZE = 32
local ICON_GAP  = 3
local PADDING   = 5

-- TBC Anniversary 2.5.5 moved several inventory functions into the
-- C_Container namespace. Resolve once at load and fall back to the legacy
-- globals for older clients. GetContainerItemInfo also changed shape (table
-- with named fields instead of multi-return), so wrap it in a helper that
-- normalizes both forms to "just the texture".
local GetItemCooldown      = (C_Container and C_Container.GetItemCooldown)      or GetItemCooldown
local GetContainerNumSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
local GetContainerItemLink = (C_Container and C_Container.GetContainerItemLink) or GetContainerItemLink
local _GCII = (C_Container and C_Container.GetContainerItemInfo) or GetContainerItemInfo
local function GetContainerItemTexture(bag, slot)
    if not _GCII then return nil end
    local r = _GCII(bag, slot)
    if type(r) == "table" then return r.iconFileID end
    return r  -- legacy form: first return was the texture
end

-- ============================================================
-- Tracked utility actions
-- ============================================================
-- `kind`:
--   "combo" = use the item by id if present in bag, else cast the spell.
--             Driven by a macrotext that gets rebuilt on bag-scan; we never
--             include both lines so there's no "you already have one" spam.
--   "spell" = cast by name (filtered to spells the warlock knows).
local UTILITY = {
    { kind = "combo", item = "Healthstone", spell = "Create Healthstone", short = "HS",
      icon = "Interface\\Icons\\INV_Stone_04",
      label = "Healthstone (use if available, else create)" },
    { kind = "combo", item = "Soulstone",   spell = "Create Soulstone",   short = "SS",
      icon = "Interface\\Icons\\Spell_Shadow_SoulGem",
      label = "Soulstone (use if available, else create)" },
    { kind = "spell", spell = "Ritual of Summoning", short = "Sum",
      label = "Ritual of Summoning" },
    { kind = "spell", spell = "Ritual of Souls",    short = "RoS",
      label = "Ritual of Souls (1 shard)" },
    { kind = "spell", spell = "Eye of Kilrogg",     short = "EoK",
      label = "Eye of Kilrogg" },
}

-- ============================================================
-- Brand chrome helpers
-- ============================================================
local NewTexture, AddBorder, AddCornerAccents = WD.NewTexture, WD.AddBorder, WD.AddCornerAccents

local function spellKnown(name)
    if not name or name == "" then return false end
    if not GetSpellInfo then return false end
    if not GetSpellInfo(name) then return false end
    -- A known spell returns a non-nil cooldown tuple; an unknown one returns nil.
    local start = GetSpellCooldown(name)
    return start ~= nil
end

-- ============================================================
-- Bag scan: find the highest-rank instance of an item by name (substring
-- match, so "Healthstone" finds Minor / Lesser / Greater / Major / Master /
-- Fel Healthstone). Returns (itemId, iconTexture) or nil.
--
-- We pick the *highest itemId* among matches because TBC's rank progression
-- assigns increasing itemIds: Master Healthstone (22106) > Major (22105) >
-- Greater (5511) > Healthstone (5512) > Lesser (5510) > Minor (5509). Same
-- pattern for Soulstones (Master = 22116). Without this, a player carrying
-- an old Lesser Healthstone alongside a freshly-made Major would bind to
-- the lower rank.
-- ============================================================
local function findBagItemByName(name)
    if not name then return nil end
    local bestId, bestTex = nil, nil
    for bag = 0, NUM_BAG_SLOTS or 4 do
        local slots = GetContainerNumSlots and GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local link = GetContainerItemLink and GetContainerItemLink(bag, slot)
            if link then
                local n = link:match("%[(.-)%]")
                if n and n:find(name, 1, true) then
                    local id = tonumber(link:match("item:(%d+)"))
                    if id and (not bestId or id > bestId) then
                        bestId = id
                        bestTex = GetContainerItemTexture(bag, slot)
                    end
                end
            end
        end
    end
    return bestId, bestTex
end

-- ============================================================
-- Bar construction
-- ============================================================
local function buildHost(count)
    local cfg = WicksDemonsDB.soul

    local barW = PADDING * 2 + math.max(1, count) * ICON_SIZE + math.max(0, count - 1) * ICON_GAP
    local barH = PADDING * 2 + ICON_SIZE

    local host = CreateFrame("Frame", "WicksDemonsSoulBar", UIParent)
    host:SetFrameStrata("MEDIUM")
    host:SetFrameLevel(10)
    host:SetSize(barW, barH)
    host:ClearAllPoints()
    host:SetPoint(cfg.point, UIParent, cfg.point, cfg.x, cfg.y)
    host:SetMovable(true)
    host:EnableMouse(true)
    host:SetClampedToScreen(true)
    host:RegisterForDrag("LeftButton")
    host:SetScript("OnDragStart", function(self)
        if cfg.locked or WicksDemons:Claimed(self) then return end
        self:StartMoving()
    end)
    host:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, _, x, y = self:GetPoint()
        cfg.point, cfg.x, cfg.y = p, x, y
    end)

    WicksDemons:Movable(host, "demons_soul", "Demons: soul bar", cfg)
    NewTexture(host, "BACKGROUND", C_BG):SetAllPoints(host)
    AddBorder(host)
    AddCornerAccents(host)

    return host, cfg
end

-- Forward drags from a child button to the host frame, so the user can
-- grab the bar from anywhere (not only the 5px padding edge). Secure
-- buttons consume mouse-up via RegisterForClicks, which would otherwise
-- swallow the host's OnDragStop and leave the bar stuck to the cursor.
local function attachDragForward(button, host, cfg)
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function()
        if cfg.locked or WicksDemons:Claimed(host) then return end
        host:StartMoving()
    end)
    button:SetScript("OnDragStop", function()
        host:StopMovingOrSizing()
        local p, _, _, x, y = host:GetPoint()
        cfg.point, cfg.x, cfg.y = p, x, y
    end)
end

local function buildButton(host, entry, index, cfg)
    local b = CreateFrame("Button", nil, host, "SecureActionButtonTemplate")
    b:RegisterForClicks("AnyUp", "AnyDown")
    b:SetSize(ICON_SIZE, ICON_SIZE)
    b:SetPoint("TOPLEFT", host, "TOPLEFT",
        PADDING + (index - 1) * (ICON_SIZE + ICON_GAP), -PADDING)
    attachDragForward(b, host, cfg)

    if entry.kind == "combo" then
        -- Macro mode. Refresh rebuilds macrotext on each bag scan (out of
        -- combat). Initial placeholder is the cast-fallback so the button
        -- works on first click before a refresh fires.
        b:SetAttribute("type", "macro")
        b:SetAttribute("macrotext", "#showtooltip\n/cast " .. entry.spell)
    elseif entry.kind == "spell" then
        b:SetAttribute("type", "spell")
        b:SetAttribute("spell", entry.spell)
    end

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    -- Resolve icon: spells use GetSpellTexture; combo prefers the bag item
    -- texture (so an in-bag stone shows the item icon), else falls back to
    -- the spell texture.
    local tex
    if entry.kind == "spell" then
        tex = GetSpellTexture and GetSpellTexture(entry.spell)
    elseif entry.kind == "combo" then
        local _, bagTex = findBagItemByName(entry.item)
        tex = bagTex or (GetSpellTexture and GetSpellTexture(entry.spell)) or entry.icon
    end
    if tex then icon:SetTexture(tex) else icon:SetColorTexture(0.1, 0.1, 0.15, 1) end
    b._icon = icon

    -- 1px frame
    local function edge(p1, p2, w, h)
        local t = b:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(0, 0, 0, 0.85)
        t:SetPoint(p1); t:SetPoint(p2)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
    end
    edge("TOPLEFT", "TOPRIGHT", nil, 1)
    edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
    edge("TOPLEFT", "BOTTOMLEFT", 1, nil)
    edge("TOPRIGHT", "BOTTOMRIGHT", 1, nil)

    -- Cooldown spiral
    local cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
    cd:SetAllPoints(b)
    cd:SetDrawEdge(false)
    cd:SetSwipeColor(0, 0, 0, 0.7)
    b._cd = cd

    -- Tooltip
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(entry.label or entry.spell or entry.item or "?",
            C_TEXT_NORMAL[1], C_TEXT_NORMAL[2], C_TEXT_NORMAL[3])
        if entry.kind == "combo" then
            local id = findBagItemByName(entry.item)
            if id then
                GameTooltip:AddLine(("Click: use %s in bag"):format(entry.item),
                    C_GREEN[1], C_GREEN[2], C_GREEN[3])
            else
                GameTooltip:AddLine(("Click: cast %s"):format(entry.spell),
                    C_TEXT_DIM[1], C_TEXT_DIM[2], C_TEXT_DIM[3])
            end
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Combo buttons: mark dirty + refresh immediately after a click. The
    -- secure /use ran synchronously, so the bag is already changed by the
    -- time PostClick fires; this gives an instant macrotext rebuild instead
    -- of waiting for BAG_UPDATE (and avoids being stuck on /use after the
    -- item is consumed). MarkBagDirty is the public API; assigning the
    -- local upvalue directly wouldn't work — buildButton is defined before
    -- the local declaration, so the upvalue would resolve as a global.
    if entry.kind == "combo" then
        b:SetScript("PostClick", function()
            if SB.MarkBagDirty then SB:MarkBagDirty() end
            if SB.Refresh      then SB:Refresh()      end
        end)
    end

    return b
end

-- ============================================================
-- Refresh: bag presence + cooldown state + icon resolution
-- ============================================================
-- Bag scans (findBagItemByName) walk every slot in every bag and pattern-
-- match each link, ~80-160 GetContainerItemLink calls per scan. Skipping
-- this on the 0.25s poll when bag contents haven't changed is a big win.
-- BAG_UPDATE marks dirty; the next Refresh re-scans and clears the flag.
local bagDirty = true

function SB:Refresh()
    if not self.icons then return end
    -- Skip the per-entry scan when the bar isn't on screen.
    if not self.host or not self.host:IsShown() then return end

    local inCombat = InCombatLockdown()
    local doBagScan = bagDirty
    bagDirty = false

    for _, e in ipairs(self.entries) do
        local b = self.icons[e]
        if b then
            if e.kind == "combo" then
                if doBagScan then
                    local id, bagTex = findBagItemByName(e.item)
                    -- Build the macrotext fresh based on bag presence. Only
                    -- one of /use or /cast lines is included so we never get
                    -- "you already have one" spam when the item is present.
                    local desired
                    if id then
                        desired = ("#showtooltip\n/use item:%d"):format(id)
                    else
                        desired = ("#showtooltip\n/cast %s"):format(e.spell)
                    end
                    -- SetAttribute is restricted in combat. Defer; the last
                    -- value sticks until combat ends.
                    if not inCombat and b._currentMacro ~= desired then
                        b:SetAttribute("type", "macro")
                        b:SetAttribute("macrotext", desired)
                        b._currentMacro = desired
                    end
                    b._currentItemId = id
                    -- Icon: bag texture if item present, else spell texture.
                    if id and bagTex then
                        b._icon:SetTexture(bagTex)
                    else
                        local tex = (GetSpellTexture and GetSpellTexture(e.spell)) or e.icon
                        if tex then b._icon:SetTexture(tex) end
                    end
                    if b._icon.SetDesaturated then b._icon:SetDesaturated(false) end
                    b._icon:SetVertexColor(1, 1, 1)
                end
                -- CD spiral: prefer item cooldown when present, else spell.
                local id = b._currentItemId
                local cdStart, cdDur
                if id and GetItemCooldown then
                    cdStart, cdDur = GetItemCooldown(id)
                end
                if not cdStart or cdStart == 0 then
                    cdStart, cdDur = GetSpellCooldown(e.spell)
                end
                if cdStart and cdStart > 0 and cdDur and cdDur > 1.5 then
                    b._cd:SetCooldown(cdStart, cdDur); b._cd:Show()
                else
                    b._cd:Hide()
                end
            else
                -- Spell: cooldown via spell name
                if b._icon.SetDesaturated then b._icon:SetDesaturated(false) end
                b._icon:SetVertexColor(1, 1, 1)
                local start, dur = GetSpellCooldown(e.spell)
                if start and start > 0 and dur and dur > 1.5 then
                    b._cd:SetCooldown(start, dur); b._cd:Show()
                else
                    b._cd:Hide()
                end
            end
        end
    end
end

-- Public marker for BAG_UPDATE wiring to flag a re-scan.
function SB:MarkBagDirty() bagDirty = true end

-- ============================================================
-- Init / lifecycle
-- ============================================================
function SB:Init()
    if self.initialized then return end
    if not WD.isWarlock then return end
    self.initialized = true

    -- Filter: spells need to be known; items always shown.
    local visible = {}
    for _, e in ipairs(UTILITY) do
        -- Combo + spell entries both require the spell to be known. Combo
        -- needs the create spell as the cast-fallback; without it the button
        -- would only ever do anything when an item is in bag.
        if spellKnown(e.spell) then
            table.insert(visible, e)
        end
    end
    self.entries = visible

    if #visible == 0 then
        return
    end

    local host, cfg = buildHost(#visible)
    self.host = host
    self.cfg  = cfg

    self.icons = {}
    for i, e in ipairs(visible) do
        self.icons[e] = buildButton(host, e, i, cfg)
    end

    if cfg.hidden then host:Hide() else host:Show() end

    -- Polling for cooldown spirals (cheap)
    if not self.poll then
        local f = CreateFrame("Frame")
        self.poll = f
        local accum = 0
        f:SetScript("OnUpdate", function(_, elapsed)
            accum = accum + elapsed
            if accum < 0.25 then return end
            accum = 0
            SB:Refresh()
        end)
    end

    self:Refresh()
end

-- Rebuild visible list when spellbook changes (e.g. trained Ritual of Souls).
function SB:Rebuild()
    if InCombatLockdown() then
        self._rebuildPending = true
        return
    end
    if not self.host then return self:Init() end

    -- Tear down current buttons
    if self.icons then
        for _, b in pairs(self.icons) do
            b:Hide(); b:ClearAllPoints(); b:SetParent(nil)
        end
    end
    self.icons = {}

    local visible = {}
    for _, e in ipairs(UTILITY) do
        -- Combo + spell entries both require the spell to be known. Combo
        -- needs the create spell as the cast-fallback; without it the button
        -- would only ever do anything when an item is in bag.
        if spellKnown(e.spell) then
            table.insert(visible, e)
        end
    end
    self.entries = visible

    local count = #visible
    local barW = PADDING * 2 + math.max(1, count) * ICON_SIZE + math.max(0, count - 1) * ICON_GAP
    self.host:SetWidth(barW)

    for i, e in ipairs(visible) do
        self.icons[e] = buildButton(self.host, e, i, self.cfg)
    end

    if not (self.cfg and self.cfg.hidden) then self.host:Show() end
    self:Refresh()
end

WD:On("COMBAT_END", function()
    if WD.SoulBar and WD.SoulBar._rebuildPending then
        WD.SoulBar._rebuildPending = false
        WD.SoulBar:Rebuild()
    end
    -- Combo buttons that consumed an item mid-combat couldn't have their
    -- macrotext rewritten (SetAttribute is restricted in combat). Force a
    -- bag re-scan now so the next Refresh switches /use to /cast (or vice
    -- versa) without waiting for the next BAG_UPDATE.
    if SB.MarkBagDirty then SB:MarkBagDirty() end
    if SB.Refresh      then SB:Refresh()      end
end)

WD:On("BAG_UPDATE",     function()
    if SB.MarkBagDirty then SB:MarkBagDirty() end
    if SB.Refresh then SB:Refresh() end
end)
WD:On("SPELLS_CHANGED", function() if SB.Rebuild then SB:Rebuild() end end)
WD:On("LOGIN",          function() SB:Init() end)

function SB:Show()
    if not self.host then return end
    self.host:Show()
    self.cfg.hidden = false
    bagDirty = true   -- force a fresh bag scan on first refresh after show
    self:Refresh()
end
function SB:Hide()  if self.host then self.host:Hide(); self.cfg.hidden = true  end end
function SB:Toggle() if self.host then if self.host:IsShown() then self:Hide() else self:Show() end end end
function SB:ResetPosition()
    if not self.cfg or not self.host then return end
    if WicksDemons:Claimed(self.host) then WicksDemons:MovedByUI(); return end
    self.cfg.point = "CENTER"
    self.cfg.x = -180; self.cfg.y = 200
    self.host:ClearAllPoints()
    self.host:SetPoint("CENTER", UIParent, "CENTER", -180, 200)
    self.host:Show()
    self.cfg.hidden = false
end
