-- Wick's Demons and Things
-- ShardCounter.lua: small movable badge showing the warlock's soul shard count.
--   * Big OUTLINE number over the shard icon, brand chrome.
--   * Updates on BAG_UPDATE; tooltip shows total count.

local ADDON, ns = ...
if not WickCore then return end   -- said once in Core.lua
local WD = WicksDemons

WD.ShardCounter = {}
local SC = WD.ShardCounter

-- Palette and chrome from WickCore through Core.lua's adapter, so the
-- bar follows the suite's look and theme.
local C_BG, C_BORDER, C_GREEN, C_TEXT_NORMAL, C_TEXT_DIM = WD.C.BG, WD.C.BORDER, WD.C.GREEN, WD.C.TEXT, WD.C.DIM
local Ink, Paint = WD.Ink, WD.Paint

local FRAME_W = 56
local FRAME_H = 56

-- ============================================================
-- Brand chrome helpers
-- ============================================================
local NewTexture, AddBorder, AddCornerAccents = WD.NewTexture, WD.AddBorder, WD.AddCornerAccents

-- ============================================================
-- Public API
-- ============================================================
function SC:Count()
    if not GetItemCount then return 0 end
    return GetItemCount(WD.SHARD_ITEM_ID, false) or 0
end

function SC:Refresh()
    if not self.frame or not self.text then return end
    local n = self:Count()
    self.text:SetText(tostring(n))
    -- Color by abundance: low = dim / red-tinted, healthy = cream, max = green
    if n == 0 then
        self.text:SetTextColor(0.85, 0.30, 0.30, 1)
    elseif n <= 3 then
        self.text:SetTextColor(C_TEXT_DIM[1] + 0.2, C_TEXT_DIM[2] + 0.2, C_TEXT_DIM[3] + 0.2, 1)
    elseif n >= 28 then
        -- Bag is a 32-slot soul bag; warn near cap
        Ink(self.text, C_GREEN)
    else
        Ink(self.text, C_TEXT_NORMAL)
    end
end

-- ============================================================
-- Build
-- ============================================================
local function build()
    local cfg = WicksDemonsDB.shard

    local f = CreateFrame("Frame", "WicksDemonsShardCounter", UIParent)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(10)
    f:SetSize(FRAME_W, FRAME_H)
    f:ClearAllPoints()
    f:SetPoint(cfg.point, UIParent, cfg.point, cfg.x, cfg.y)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if cfg.locked or WicksDemons:Claimed(self) then return end
        self:StartMoving()
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, _, x, y = self:GetPoint()
        cfg.point, cfg.x, cfg.y = p, x, y
    end)

    WicksDemons:Movable(f, "demons_shards", "Demons: shards", cfg)
    NewTexture(f, "BACKGROUND", C_BG):SetAllPoints(f)
    AddBorder(f)
    AddCornerAccents(f, 5, 2)

    -- Shard icon (faded background)
    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Gem_Amethyst_02")
    icon:SetPoint("TOPLEFT", 4, -4)
    icon:SetPoint("BOTTOMRIGHT", -4, 4)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetVertexColor(1, 1, 1, 0.55)

    -- Big number, outlined
    local text = f:CreateFontString(nil, "OVERLAY")
    WD.Chrome:SetFont(text, 22, "THICKOUTLINE")
    text:SetPoint("CENTER", 0, 0)
    Ink(text, C_TEXT_NORMAL)
    text:SetText("0")

    -- "Shards" label
    local lbl = f:CreateFontString(nil, "OVERLAY")
    lbl:SetFont("Fonts\\ARIALN.TTF", 9, "OUTLINE")
    lbl:SetPoint("BOTTOM", 0, 3)
    Ink(lbl, C_TEXT_DIM)
    lbl:SetText("SHARDS")

    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Soul Shards", C_TEXT_NORMAL[1], C_TEXT_NORMAL[2], C_TEXT_NORMAL[3])
        GameTooltip:AddLine(("In bags: %d"):format(SC:Count()),
            C_GREEN[1], C_GREEN[2], C_GREEN[3])
        GameTooltip:AddLine("Drag to move", C_TEXT_DIM[1], C_TEXT_DIM[2], C_TEXT_DIM[3])
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return f, text, cfg
end

-- ============================================================
-- Lifecycle
-- ============================================================
function SC:Init()
    if self.initialized then return end
    if not WD.isWarlock then return end
    self.initialized = true

    local f, text, cfg = build()
    self.frame = f
    self.text  = text
    self.cfg   = cfg

    if cfg.hidden then f:Hide() else f:Show() end
    self:Refresh()
end

WD:On("LOGIN",      function() SC:Init() end)
WD:On("BAG_UPDATE", function() if SC.Refresh then SC:Refresh() end end)

function SC:Show()  if self.frame then self.frame:Show(); self.cfg.hidden = false end end
function SC:Hide()  if self.frame then self.frame:Hide(); self.cfg.hidden = true  end end
function SC:Toggle() if self.frame then if self.frame:IsShown() then self:Hide() else self:Show() end end end
function SC:ResetPosition()
    if not self.cfg or not self.frame then return end
    if WicksDemons:Claimed(self.frame) then WicksDemons:MovedByUI(); return end
    self.cfg.point = "CENTER"
    self.cfg.x = 0; self.cfg.y = 240
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 240)
    self.frame:Show()
    self.cfg.hidden = false
end
