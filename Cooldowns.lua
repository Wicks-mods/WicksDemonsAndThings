-- Wick's Demons and Things
-- Cooldowns.lua: warlock cooldown / proc icon strip.
--   * Filters by spec (active talent tab) for procs; CDs filter by spellKnown.
--   * Auto-rebuilds on PLAYER_TALENT_UPDATE (respec).
--   * 0.25s polling for cooldown spirals + aura time-remaining.

local ADDON, ns = ...
if not WickCore then return end   -- said once in Core.lua
local WD = WicksDemons

WD.Cooldowns = {}
local CT = WD.Cooldowns

-- Palette and chrome from WickCore through Core.lua's adapter, so the
-- bar follows the suite's look and theme.
local C_BG, C_BORDER, C_GREEN, C_TEXT_NORMAL, C_TEXT_DIM = WD.C.BG, WD.C.BORDER, WD.C.GREEN, WD.C.TEXT, WD.C.DIM
local Ink, Paint = WD.Ink, WD.Paint

local ICON_SIZE = 32
local ICON_GAP  = 3
local PADDING   = 5

-- ============================================================
-- Tracked entries
-- ============================================================
-- `spell` = cast name (used by /cast and GetSpellCooldown)
-- `aura`  = buff/debuff name (used for proc detection)
-- `kind`  = "cd" / "proc" / "both"
-- `unit`  = "player" or "target"; defaults to player
-- `harmful` = true if checked via UnitDebuff (e.g. Shadow Vulnerability)
-- `spec`  = optional gate for proc-kind entries (active spec must match)
local TRACKED = {
    -- Baseline cooldowns (always shown if known)
    { spell = "Banish",                kind = "cd", short = "Ban",
      icon = "Interface\\Icons\\Spell_Shadow_Cripple" },
    { spell = "Curse of Doom",         kind = "cd", short = "CoD",
      icon = "Interface\\Icons\\Spell_Shadow_AuraOfDarkness" },

    -- Affliction
    { spell = "Death Coil",            kind = "cd", short = "DC",   spec = "affliction" },
    { spell = "Howl of Terror",        kind = "cd", short = "Howl", spec = "affliction" },
    { aura  = "Shadow Trance",         kind = "proc", short = "NF", spec = "affliction",
      displayName = "Nightfall (Shadow Trance)",
      icon = "Interface\\Icons\\Spell_Shadow_Twilight" },

    -- Demonology
    { spell = "Fel Domination",        kind = "cd", short = "FelDom", spec = "demonology" },

    -- Destruction
    { spell = "Conflagrate",           kind = "cd", short = "Conf",  spec = "destruction" },
    { spell = "Shadowfury",            kind = "cd", short = "SF",    spec = "destruction" },
    { spell = "Soulshatter",           kind = "cd", short = "Shat",  spec = "destruction" },
    { aura  = "Shadow Vulnerability",  kind = "proc", short = "ImpSB",
      unit = "target", harmful = true, spec = "destruction",
      displayName = "Improved Shadow Bolt (target debuff)",
      icon = "Interface\\Icons\\Spell_Shadow_ShadowBolt" },
}

-- ============================================================
-- Brand chrome helpers
-- ============================================================
local NewTexture, AddBorder, AddCornerAccents = WD.NewTexture, WD.AddBorder, WD.AddCornerAccents

-- ============================================================
-- Aura / spell helpers
-- ============================================================
local function findAura(unit, name, harmful)
    if not unit or unit == "" then return nil end
    if unit ~= "player" and not UnitExists(unit) then return nil end
    local fn = harmful and UnitDebuff or UnitBuff
    for i = 1, 40 do
        -- TBC 2.5.5: count is at position 3 (rank was removed). See findAura
        -- in WicksTotemsAndThings/CooldownTracker.lua for the full signature.
        local n, _, count, _, duration, expirationTime = fn(unit, i)
        if not n then return nil end
        if n == name then return n, count or 0, expirationTime or 0, duration or 0 end
    end
    return nil
end

local function spellKnown(name)
    if not name or name == "" then return false end
    if not GetSpellInfo or not GetSpellInfo(name) then return false end
    local start = GetSpellCooldown(name)
    return start ~= nil
end

-- ============================================================
-- Bar construction
-- ============================================================
local function buildHost(visibleEntries)
    local cfg = WicksDemonsDB.cd
    local count = #visibleEntries
    local barW = PADDING * 2 + math.max(1, count) * ICON_SIZE + math.max(0, count - 1) * ICON_GAP
    local barH = PADDING * 2 + ICON_SIZE

    local host = CreateFrame("Frame", "WicksDemonsCDBar", UIParent)
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

    WicksDemons:Movable(host, "demons_cooldowns", "Demons: cooldowns", cfg)
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

local function buildIcon(host, entry, index, cfg)
    local b = CreateFrame("Button", nil, host, "SecureActionButtonTemplate")
    b:RegisterForClicks("AnyUp", "AnyDown")
    b:SetSize(ICON_SIZE, ICON_SIZE)
    b:SetPoint("TOPLEFT", host, "TOPLEFT",
        PADDING + (index - 1) * (ICON_SIZE + ICON_GAP), -PADDING)
    attachDragForward(b, host, cfg)

    if entry.spell then
        b:SetAttribute("type", "spell")
        b:SetAttribute("spell", entry.spell)
    end

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local tex
    if entry.spell then tex = GetSpellTexture and GetSpellTexture(entry.spell) end
    if not tex and entry.aura then tex = GetSpellTexture and GetSpellTexture(entry.aura) end
    if not tex and entry.icon then tex = entry.icon end
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

    -- Active glow (proc up)
    local glow = b:CreateTexture(nil, "OVERLAY")
    Paint(glow, C_GREEN, 0.45)
    glow:SetAllPoints(b)
    glow:Hide()
    b._glow = glow

    -- Stack / time-remaining text
    local stack = b:CreateFontString(nil, "OVERLAY")
    WD.Chrome:SetFont(stack, 14, "OUTLINE")
    stack:SetPoint("BOTTOMRIGHT", -2, 1)
    Ink(stack, C_GREEN)
    stack:SetText("")
    b._stack = stack

    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:ClearLines()
        local title = entry.displayName or entry.spell or entry.aura or entry.short or "?"
        GameTooltip:AddLine(title, C_TEXT_NORMAL[1], C_TEXT_NORMAL[2], C_TEXT_NORMAL[3])
        GameTooltip:AddLine(entry.kind == "proc" and "Proc tracker" or "Cooldown tracker",
            C_TEXT_DIM[1], C_TEXT_DIM[2], C_TEXT_DIM[3])
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return b
end

-- ============================================================
-- Refresh
-- ============================================================
function CT:Refresh()
    if not self.icons then return end
    -- Skip the per-entry aura+CD scan when the bar isn't on screen.
    if not self.host or not self.host:IsShown() then return end
    for _, e in ipairs(self.entries) do
        local b = self.icons[e]
        if b then
            local now = GetTime()

            local auraName, count, expirationTime
            if e.aura then
                auraName, count, expirationTime = findAura(e.unit or "player", e.aura, e.harmful)
            end

            local onCD, cdRemaining = false, 0
            if e.spell then
                local start, dur = GetSpellCooldown(e.spell)
                if start and start > 0 and dur and dur > 1.5 then
                    onCD = true
                    cdRemaining = (start + dur) - now
                end
            end

            if auraName then
                b._glow:Show()
                if count and count > 1 then
                    b._stack:SetText(tostring(count))
                elseif expirationTime and expirationTime > 0 then
                    local r = expirationTime - now
                    if r > 60 then b._stack:SetText(("%dm"):format(math.floor(r / 60)))
                    elseif r > 0 then b._stack:SetText(("%d"):format(math.ceil(r)))
                    else b._stack:SetText("") end
                else
                    b._stack:SetText("")
                end
                b._cd:Hide()
                if b._icon.SetDesaturated then b._icon:SetDesaturated(false) end
                b._icon:SetVertexColor(1, 1, 1)
            elseif onCD then
                b._glow:Hide()
                b._stack:SetText("")
                b._cd:SetCooldown(GetSpellCooldown(e.spell))
                b._cd:Show()
                if b._icon.SetDesaturated then b._icon:SetDesaturated(false) end
                b._icon:SetVertexColor(0.45, 0.45, 0.45)
            else
                b._glow:Hide()
                b._stack:SetText("")
                b._cd:Hide()
                if e.kind == "proc" then
                    if b._icon.SetDesaturated then b._icon:SetDesaturated(true) end
                    b._icon:SetVertexColor(0.55, 0.55, 0.55)
                else
                    if b._icon.SetDesaturated then b._icon:SetDesaturated(false) end
                    b._icon:SetVertexColor(1, 1, 1)
                end
            end
        end
    end
end

-- ============================================================
-- Filter + init
-- ============================================================
local function filterVisible(activeSpec)
    local visible = {}
    for _, e in ipairs(TRACKED) do
        local target = e.spell or e.aura
        local specOK = (not e.spec) or (e.spec == activeSpec)
        if not specOK then
            -- skip
        elseif e.kind == "proc" then
            -- Always include proc entries that pass spec gate, even if the
            -- "spell" form isn't known (the aura is a buff, not a castable).
            table.insert(visible, e)
        elseif spellKnown(target) then
            table.insert(visible, e)
        end
    end
    return visible
end

function CT:Init()
    if self.initialized then return end
    if not WD.isWarlock then return end
    self.initialized = true

    self.activeSpec = WD:GetActiveSpec()
    local visible = filterVisible(self.activeSpec)
    self.entries = visible

    local host, cfg = buildHost(visible)
    self.host = host
    self.cfg  = cfg

    self.icons = {}
    for i, e in ipairs(visible) do
        self.icons[e] = buildIcon(host, e, i, cfg)
    end

    if cfg.hidden then host:Hide() else host:Show() end

    if not self.poll then
        local f = CreateFrame("Frame")
        self.poll = f
        local accum = 0
        f:SetScript("OnUpdate", function(_, elapsed)
            accum = accum + elapsed
            if accum < 0.25 then return end
            accum = 0
            CT:Refresh()
        end)
    end

    -- Event-driven refresh
    local ef = CreateFrame("Frame")
    ef:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    ef:RegisterEvent("PLAYER_TARGET_CHANGED")
    ef:RegisterUnitEvent("UNIT_AURA", "player")
    ef:RegisterUnitEvent("UNIT_AURA", "target")
    ef:SetScript("OnEvent", function() CT:Refresh() end)

    self:Refresh()
end

function CT:RebuildForSpec()
    if not self.host then return self:Init() end
    if InCombatLockdown() then
        self._rebuildPending = true
        return
    end

    local newSpec = WD:GetActiveSpec()
    if not newSpec then return end
    if newSpec == self.activeSpec then return end
    self.activeSpec = newSpec

    if self.icons then
        for _, b in pairs(self.icons) do
            b:Hide(); b:ClearAllPoints(); b:SetParent(nil)
        end
    end
    self.icons = {}

    local visible = filterVisible(self.activeSpec)
    self.entries = visible

    local count = #visible
    local barW = PADDING * 2 + math.max(1, count) * ICON_SIZE + math.max(0, count - 1) * ICON_GAP
    self.host:SetWidth(barW)

    for i, e in ipairs(visible) do
        self.icons[e] = buildIcon(self.host, e, i, self.cfg)
    end

    if not (self.cfg and self.cfg.hidden) then self.host:Show() end
    self:Refresh()
end

WD:On("COMBAT_END", function()
    if WD.Cooldowns and WD.Cooldowns._rebuildPending then
        WD.Cooldowns._rebuildPending = false
        WD.Cooldowns:RebuildForSpec()
    end
end)

WD:On("PLAYER_TALENT_UPDATE",     function() CT:RebuildForSpec() end)
WD:On("CHARACTER_POINTS_CHANGED", function() CT:RebuildForSpec() end)
WD:On("LOGIN",                    function() CT:Init() end)

function CT:Show()  if self.host then self.host:Show(); self.cfg.hidden = false; self:Refresh() end end
function CT:Hide()  if self.host then self.host:Hide(); self.cfg.hidden = true  end end
function CT:Toggle() if self.host then if self.host:IsShown() then self:Hide() else self:Show() end end end
function CT:ResetPosition()
    if not self.cfg or not self.host then return end
    if WicksDemons:Claimed(self.host) then WicksDemons:MovedByUI(); return end
    self.cfg.point = "CENTER"
    self.cfg.x = 0; self.cfg.y = 156
    self.host:ClearAllPoints()
    self.host:SetPoint("CENTER", UIParent, "CENTER", 0, 156)
    self.host:Show()
    self.cfg.hidden = false
end
