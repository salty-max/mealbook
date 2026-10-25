-- The book's button on the minimap (the kit's: Kit.lua): click to open the
-- book, right-click for its settings, drag to move it around the minimap.
-- Its place (and whether it shows) is kept with this character's settings
-- (Settings.lua).
local _, ns = ...
local K = ns.kit

local M

function ns.createMinimapButton()
  if M then return end
  M = K.minimapButton({
    name = "MealbookMinimapButton",
    icon = "Interface\\AddOns\\Mealbook\\Media\\Logo",
    crop = true,
    title = "Mealbook",
    lines = function()
      local skill = ns.skill()
      local char, n = ns.book(), 0
      for _ in pairs(char and char.known or {}) do
        n = n + 1
      end
      return { K.plural(n, "%d recipe, cooking %d.", "%d recipes, cooking %d."):format(n, skill) }
    end,
    click = function() ns.toggle() end,
    rightClick = function() ns.openSettings() end,
    get = ns.option,
    set = ns.setOption,
  })
end

function ns.updateMinimapButton()
  if M then M:update() end
end
