-- The book's button on the minimap: click to open the book, right-click for
-- its settings, drag to move it around the minimap. Its place (and whether
-- it shows) is kept with this character's settings (Settings.lua). Built
-- with the textures of the game's own minimap buttons (the tracking button's
-- border, the zoom highlight), as the siblings'.
local _, ns = ...
local L = ns.kit.L

local button

local function place()
  local angle = math.rad(ns.option("minimapAngle"))
  local r = Minimap:GetWidth() / 2 + 10
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
end

-- While dragging: the angle from the minimap's centre to the cursor.
local function follow()
  local mx, my = Minimap:GetCenter()
  local cx, cy = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale()
  ns.setOption("minimapAngle", math.deg(math.atan2(cy / scale - my, cx / scale - mx)))
  place()
end

function ns.createMinimapButton()
  if button or not Minimap then return end
  button = CreateFrame("Button", "MealbookMinimapButton", Minimap)
  button:SetSize(31, 31)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(8)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:RegisterForDrag("LeftButton")
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local icon = button:CreateTexture(nil, "BACKGROUND")
  icon:SetTexture("Interface\\AddOns\\Mealbook\\Media\\Logo")
  icon:SetSize(20, 20)
  icon:SetPoint("TOPLEFT", 7, -6)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  local border = button:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53)
  border:SetPoint("TOPLEFT")

  button:SetScript("OnClick", function(_, mouse)
    if mouse == "RightButton" then
      ns.openSettings()
    else
      ns.toggle()
    end
  end)
  button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", follow) end)
  button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Mealbook")
    local skill = ns.skill()
    local char, n = ns.book(), 0
    for _ in pairs(char and char.known or {}) do
      n = n + 1
    end
    GameTooltip:AddLine(ns.kit.plural(n, "%d recipe, cooking %d.", "%d recipes, cooking %d."):format(n, skill), 1, 1, 1)
    GameTooltip:AddLine(
      L["Click to open the book, right-click for the settings. Drag to move this button."],
      0.7,
      0.7,
      0.7,
      true
    )
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)

  place()
  ns.updateMinimapButton()
end

function ns.updateMinimapButton()
  if not button then return end
  place()
  button:SetShown(not ns.option("minimapHidden"))
end
