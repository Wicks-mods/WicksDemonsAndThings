-- Wick's Demons and Things
-- UI.lua: brand-styled options panel.
--   * Single pane (no tabs) — toggles for the 4 bars, lock-all, reset-all,
--     status diagnostic.
--   * Opened via bare /wdt; closed via × button.

local ADDON, ns = ...
if not WickCore then return end   -- said once in Core.lua
local WD = WicksDemons

WD.UI = {}
local UI = WD.UI

-- ============================================================
-- Palette, from WickCore through Core.lua's adapter
-- ============================================================
local Chrome        = WD.Chrome
local C_BG          = WD.C.BG
local C_HEADER_BG   = WD.C.HEADER
local C_BORDER      = WD.C.BORDER
local C_GREEN       = WD.C.GREEN
local C_TEXT_NORMAL = WD.C.TEXT
local C_TEXT_DIM    = WD.C.DIM
local C_BTN_BG      = WD.C.HEADER
local C_BTN_HOVER   = WD.C.BORDER
local Ink, Paint    = WD.Ink, WD.Paint

local PANEL_W = 360
local PANEL_H = 400
local TITLE_H = 28
local PADDING = 12
local ROW_H   = 22

-- ============================================================
-- Brand helpers, all through the adapter
-- ============================================================
local function SetRGBA(tex, c) Paint(tex, c) end
local NewTexture, NewText, AddBorder, AddCornerAccents = WD.NewTexture, WD.NewText, WD.AddBorder, WD.AddCornerAccents

-- ============================================================
-- Custom checkbox (brand-styled)
-- ============================================================
local function NewCheckbox(parent, label, getter, setter)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_H)

    local box = CreateFrame("Button", nil, row)
    box:SetSize(16, 16)
    box:SetPoint("LEFT", row, "LEFT", 0, 0)
    NewTexture(box, "BACKGROUND", C_BTN_BG):SetAllPoints(box)
    AddBorder(box, C_BORDER)

    local check = box:CreateTexture(nil, "OVERLAY")
    Paint(check, C_GREEN)
    check:SetPoint("TOPLEFT",     box, "TOPLEFT",      3, -3)
    check:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -3,  3)

    local lbl = NewText(row, 11, C_TEXT_NORMAL)
    lbl:SetPoint("LEFT", box, "RIGHT", 8, 0)
    lbl:SetText(label)

    local function refresh()
        if getter() then check:Show() else check:Hide() end
    end
    refresh()

    box:SetScript("OnClick", function()
        setter(not getter())
        refresh()
        if UI.RefreshAll then UI:RefreshAll() end
    end)
    box:SetScript("OnEnter", function() Ink(lbl, C_GREEN) end)
    box:SetScript("OnLeave", function() Ink(lbl, C_TEXT_NORMAL) end)

    row._refresh = refresh
    row._label   = lbl
    row._box     = box
    return row
end

-- ============================================================
-- Custom button (brand-styled)
-- ============================================================
local function NewButton(parent, label, width, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width or 120, 24)
    local bg = NewTexture(b, "BACKGROUND", C_BTN_BG)
    bg:SetAllPoints(b)
    AddBorder(b, C_BORDER)
    local lbl = NewText(b, 11, C_TEXT_NORMAL)
    lbl:SetPoint("CENTER")
    lbl:SetText(label)
    b:SetScript("OnEnter", function() SetRGBA(bg, C_BTN_HOVER); Ink(lbl, C_GREEN) end)
    b:SetScript("OnLeave", function() SetRGBA(bg, C_BTN_BG);    Ink(lbl, C_TEXT_NORMAL) end)
    b:SetScript("OnClick", onClick)
    return b
end

-- ============================================================
-- Title bar (two-tone "Wick's <name>" + × close)
-- ============================================================
local function buildTitleBar(frame)
    local bar = CreateFrame("Frame", nil, frame)
    bar:SetHeight(TITLE_H)
    bar:SetPoint("TOPLEFT",  frame, "TOPLEFT",   1, -1)
    bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    NewTexture(bar, "BACKGROUND", C_HEADER_BG):SetAllPoints(bar)

    local div = NewTexture(bar, "BORDER", C_BORDER)
    div:SetPoint("BOTTOMLEFT"); div:SetPoint("BOTTOMRIGHT")
    div:SetHeight(1)

    local tApo = NewText(bar, 12, C_GREEN)
    tApo:SetPoint("LEFT", bar, "LEFT", 12, 0)
    tApo:SetText("Wick's")
    local tRest = NewText(bar, 12, C_TEXT_NORMAL)
    tRest:SetPoint("LEFT", tApo, "RIGHT", 5, 0)
    tRest:SetText("Demons and Things")

    -- × close button
    local closeBtn = CreateFrame("Button", nil, bar)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("RIGHT", bar, "RIGHT", -6, 0)
    local x = NewText(closeBtn, 14, C_TEXT_NORMAL)
    x:SetPoint("CENTER")
    x:SetText("×")
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    closeBtn:SetScript("OnEnter", function() Ink(x, C_GREEN) end)
    closeBtn:SetScript("OnLeave", function() Ink(x, C_TEXT_NORMAL) end)

    -- Drag the panel from the title bar
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function() frame:StartMoving() end)
    bar:SetScript("OnDragStop",  function()
        frame:StopMovingOrSizing()
        local p, _, _, x2, y2 = frame:GetPoint()
        WicksDemonsDB.ui = WicksDemonsDB.ui or {}
        WicksDemonsDB.ui.point, WicksDemonsDB.ui.x, WicksDemonsDB.ui.y = p, x2, y2
    end)

    return bar
end

-- ============================================================
-- Section header text
-- ============================================================
local function NewSectionLabel(parent, text)
    local f = NewText(parent, 11, C_TEXT_DIM)
    f:SetText(text:upper())
    return f
end

-- ============================================================
-- Build
-- ============================================================
function UI:Build()
    if self.frame then return self.frame end

    WicksDemonsDB.ui = WicksDemonsDB.ui or { point = "CENTER", x = 0, y = 0 }
    local cfg = WicksDemonsDB.ui

    local frame = CreateFrame("Frame", "WicksDemonsOptionsFrame", UIParent)
    frame:SetSize(PANEL_W, PANEL_H)
    frame:SetPoint(cfg.point or "CENTER", UIParent, cfg.point or "CENTER", cfg.x or 0, cfg.y or 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:Hide()

    NewTexture(frame, "BACKGROUND", C_BG):SetAllPoints(frame)
    AddBorder(frame)
    AddCornerAccents(frame)

    buildTitleBar(frame)

    -- Body container
    local body = CreateFrame("Frame", nil, frame)
    body:SetPoint("TOPLEFT",     frame, "TOPLEFT",     PADDING, -(TITLE_H + PADDING))
    body:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PADDING, PADDING)

    local y = 0

    -- BARS section
    local hdrBars = NewSectionLabel(body, "Bars")
    hdrBars:SetPoint("TOPLEFT", body, "TOPLEFT", 0, -y)
    y = y + 18

    local function makeBarToggle(key, label)
        local row = NewCheckbox(body, label,
            function() return not WicksDemonsDB[key].hidden end,
            function(v)
                if WicksDemonsDB[key] then WicksDemonsDB[key].hidden = not v end
                local mod = ({ soul = WD.SoulBar, pet = WD.PetBar, cd = WD.Cooldowns, shard = WD.ShardCounter })[key]
                if v then if mod and mod.Show then mod:Show() end
                else      if mod and mod.Hide then mod:Hide() end end
            end)
        row:SetPoint("TOPLEFT",  body, "TOPLEFT",  4, -y)
        row:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, -y)
        y = y + ROW_H
        return row
    end

    self._rowSoul  = makeBarToggle("soul",  "Soul bar (utility items + rituals)")
    self._rowPet   = makeBarToggle("pet",   "Pet bar (summons + Demo utility)")
    self._rowCD    = makeBarToggle("cd",    "Cooldown / proc bar")
    self._rowShard = makeBarToggle("shard", "Shard counter")

    y = y + 6

    -- 1px divider
    local div1 = NewTexture(body, "BORDER", C_BORDER)
    div1:SetPoint("TOPLEFT",  body, "TOPLEFT",  0, -y)
    div1:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, -y)
    div1:SetHeight(1)
    y = y + 10

    -- LOCK section
    local hdrLock = NewSectionLabel(body, "Movement")
    hdrLock:SetPoint("TOPLEFT", body, "TOPLEFT", 0, -y)
    y = y + 18

    self._rowLock = NewCheckbox(body, "Lock all bars in place",
        function()
            -- "locked" = all four are locked. Mixed state reads as unlocked.
            return WicksDemonsDB.soul.locked and WicksDemonsDB.pet.locked
                and WicksDemonsDB.cd.locked and WicksDemonsDB.shard.locked
        end,
        function(v)
            for _, k in ipairs({ "soul", "pet", "cd", "shard" }) do
                WicksDemonsDB[k].locked = v
            end
        end)
    self._rowLock:SetPoint("TOPLEFT",  body, "TOPLEFT",  4, -y)
    self._rowLock:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, -y)
    y = y + ROW_H + 4

    local resetBtn = NewButton(body, "Reset all positions", 160, function()
        if WD.SoulBar      and WD.SoulBar.ResetPosition      then WD.SoulBar:ResetPosition()      end
        if WD.PetBar       and WD.PetBar.ResetPosition       then WD.PetBar:ResetPosition()       end
        if WD.Cooldowns    and WD.Cooldowns.ResetPosition    then WD.Cooldowns:ResetPosition()    end
        if WD.ShardCounter and WD.ShardCounter.ResetPosition then WD.ShardCounter:ResetPosition() end
        UI:RefreshAll()
    end)
    resetBtn:SetPoint("TOPLEFT", body, "TOPLEFT", 4, -y)
    y = y + 30

    -- 1px divider
    local div2 = NewTexture(body, "BORDER", C_BORDER)
    div2:SetPoint("TOPLEFT",  body, "TOPLEFT",  0, -y)
    div2:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, -y)
    div2:SetHeight(1)
    y = y + 10

    -- STATUS section
    local hdrStatus = NewSectionLabel(body, "Status")
    hdrStatus:SetPoint("TOPLEFT", body, "TOPLEFT", 0, -y)
    y = y + 18

    local function statusRow(text)
        local f = NewText(body, 11, C_TEXT_DIM)
        f:SetPoint("TOPLEFT", body, "TOPLEFT", 4, -y)
        f:SetText(text)
        y = y + 16
        return f
    end

    self._statusClass = statusRow("...")
    self._statusSpec  = statusRow("...")
    self._statusShard = statusRow("...")

    y = y + 6
    local hint = NewText(body, 9, C_TEXT_DIM)
    hint:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", 4, 0)
    hint:SetText("Drag the title bar to move. Type /wdt help for slash commands.")

    self.frame = frame
    self.body  = body

    self:RefreshAll()
    return frame
end

-- ============================================================
-- Refresh state-bound widgets (called after any external change)
-- ============================================================
function UI:RefreshAll()
    if not self.frame then return end
    if self._rowSoul  and self._rowSoul._refresh  then self._rowSoul:_refresh()  end
    if self._rowPet   and self._rowPet._refresh   then self._rowPet:_refresh()   end
    if self._rowCD    and self._rowCD._refresh    then self._rowCD:_refresh()    end
    if self._rowShard and self._rowShard._refresh then self._rowShard:_refresh() end
    if self._rowLock  and self._rowLock._refresh  then self._rowLock:_refresh()  end

    if self._statusClass then
        self._statusClass:SetText(("Class: %s"):format(
            WD.isWarlock and "Warlock" or (WD.playerClass or "(unknown)")))
    end
    if self._statusSpec then
        self._statusSpec:SetText(("Spec: %s"):format(
            WD:GetActiveSpec() or "(unknown)"))
    end
    if self._statusShard and WD.ShardCounter and WD.ShardCounter.Count then
        self._statusShard:SetText(("Soul shards in bag: %d"):format(WD.ShardCounter:Count()))
    end
end

-- ============================================================
-- Public API
-- ============================================================
function UI:Show()    self:Build(); self.frame:Show(); self:RefreshAll() end
function UI:Hide()    if self.frame then self.frame:Hide() end end
function UI:Toggle()
    self:Build()
    if self.frame:IsShown() then self.frame:Hide() else self:Show() end
end

WD:On("LOGIN",      function() UI:Build() end)
WD:On("BAG_UPDATE", function() if UI._statusShard then UI:RefreshAll() end end)
