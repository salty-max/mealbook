-- The cookbook's settings, each character's own (its profile, "Name - Realm",
-- the kit's: Kit.lua), all kept in MealbookSettings so that one character
-- can take another's: chosen among this game's characters, or brought by a
-- code (/mealbook export, /mealbook import CODE). Their page in the game's
-- Options (AddOns tab): /mealbook settings, or a right-click on the minimap
-- button; the welcome page (Welcome.lua) offers them too.
--
--   MealbookSettings.profiles["Name - Realm"] = { chef, tooltips,
--     minimapHidden, minimapAngle, welcomed }
--   (the test builds' account-wide chef and tooltips, taken into the
--   character's profile at its login)
local _, ns = ...
local K = ns.kit
local L = K.L

-- (chef: 0, the character's side's chef, 1 Kendor Kabonka, 2 Eunice Burch
-- (a number: the kit's codes carry numbers);
-- minimapAngle: the button's place around the minimap, in degrees, 165 on
-- the left above the siblings' (200 to 250); welcomed: never copied)
local DEFAULTS = {
  chef = 0,
  tooltips = true,
  minimapHidden = false,
  minimapAngle = 165,
  welcomed = false,
}
local SHARED = { "chef", "tooltips", "minimapHidden", "minimapAngle" }
ns.CHEF_CHOICES = { [0] = false, [1] = "kendor", [2] = "eunice" }

-- The profiles: a code "MB1:c0:t1:h0:a165".
local P = K.profiles({
  saved = function()
    if type(MealbookSettings) ~= "table" then MealbookSettings = {} end
    return MealbookSettings
  end,
  defaults = DEFAULTS,
  shared = SHARED,
  letters = { chef = "c", tooltips = "t", minimapHidden = "h", minimapAngle = "a" },
  tag = "MB1",
  changed = function(key)
    if key == "minimapHidden" or key == "minimapAngle" then
      if ns.updateMinimapButton then ns.updateMinimapButton() end
    elseif key == "chef" and ns.onChange then
      ns.onChange()
    end
  end,
})
ns.profiles = P

-- This character's profile at its login: its own, else the defaults (the
-- test builds' account-wide values taken in, once).
function ns.loadProfile()
  local old = type(MealbookSettings) == "table" and MealbookSettings or {}
  local chef, tooltips = old.chef, old.tooltips
  old.chef, old.tooltips = nil, nil
  P:load()
  if chef == "kendor" or chef == "eunice" then P:set("chef", chef == "kendor" and 1 or 2) end
  if tooltips == false then P:set("tooltips", false) end
end
function ns.option(key) return P:get(key) end
function ns.setOption(key, value) P:set(key, value) end

local category

function ns.createSettingsPanel()
  if category or not (Settings and Settings.RegisterVerticalLayoutCategory) then return end
  category = Settings.RegisterVerticalLayoutCategory("Mealbook")

  local chef = Settings.RegisterProxySetting(
    category,
    "MEALBOOK_CHEF",
    Settings.VarType.Number,
    L["The chef's pages"],
    DEFAULTS.chef,
    function() return ns.option("chef") end,
    function(value) ns.setOption("chef", value) end
  )
  Settings.CreateDropdown(category, chef, function()
    local options = Settings.CreateControlTextContainer()
    options:Add(0, L["Your side's chef"])
    options:Add(1, ns.chefName("kendor"))
    options:Add(2, ns.chefName("eunice"))
    return options:GetData()
  end, L["Whose pages the book shows above each dish: your side's chef, or the other one."])

  local function checkbox(key, name, tooltip, invert)
    invert = invert or false
    local setting = Settings.RegisterProxySetting(
      category,
      "MEALBOOK_" .. key:upper(),
      Settings.VarType.Boolean,
      name,
      not DEFAULTS[key] == invert,
      function() return ns.option(key) ~= invert end,
      function(value) ns.setOption(key, value ~= invert) end
    )
    Settings.CreateCheckbox(category, setting, tooltip)
  end
  checkbox(
    "tooltips",
    L["Dishes on ingredients' tooltips"],
    L["An ingredient's tooltip names the dishes you know it cooks into."]
  )
  checkbox("minimapHidden", L["Minimap button"], L["The book by the minimap: click to open it, drag to move it."], true)

  -- Another character's settings (of this game), for this one.
  K.copySetting(
    category,
    "MEALBOOK_COPYFROM",
    P,
    L["Another character's choices, for this one (of this game: Classic and Forever keep their own). From elsewhere: /mealbook export there, then /mealbook import CODE here."],
    function(other) print(ns.PREFIX .. L["%s's settings copied."]:format(other)) end
  )

  Settings.RegisterAddOnCategory(category)
end

function ns.openSettings()
  if category then Settings.OpenToCategory(category:GetID()) end
  return category ~= nil
end
