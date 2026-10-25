-- The cookbook's settings, each character's own (its profile, "Name - Realm",
-- the kit's: Kit.lua), all kept in MealbookSettings so that one character
-- can take another's: chosen among this game's characters, or brought by a
-- code (/mealbook export, /mealbook import CODE). Their page in the game's
-- Options (AddOns tab): /mealbook settings, or a right-click on the minimap
-- button; the welcome page (Welcome.lua) offers them too.
--
--   MealbookSettings.profiles["Name - Realm"] = { chef, tooltips,
--     achievementToast, minimapHidden, minimapAngle, welcomed }
--   (the test builds' account-wide chef and tooltips: each character's new
--   profile seeded with them)
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
  minimapAngle = K.MINIMAP_ANGLES.Mealbook,
  achievementToast = true,
  welcomed = false,
}
local SHARED = { "chef", "tooltips", "minimapHidden", "minimapAngle", "achievementToast" }
ns.CHEF_CHOICES = { [0] = false, [1] = "kendor", [2] = "eunice" }

-- The profiles: a code "MB1:c0:t1:h0:a165:v1".
local P = K.profiles({
  saved = function()
    if type(MealbookSettings) ~= "table" then MealbookSettings = {} end
    return MealbookSettings
  end,
  defaults = DEFAULTS,
  shared = SHARED,
  letters = { chef = "c", tooltips = "t", minimapHidden = "h", minimapAngle = "a", achievementToast = "v" },
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

-- This character's profile at its login: its own, else the defaults, a new
-- one seeded with the test builds' account-wide chef and tooltips (left in
-- place: every character takes them in turn).
function ns.loadProfile()
  P:load(function(profile, saved)
    if saved.chef == "kendor" or saved.chef == "eunice" then profile.chef = saved.chef == "kendor" and 1 or 2 end
    if saved.tooltips == false then profile.tooltips = false end
  end)
end
function ns.option(key) return P:get(key) end
function ns.setOption(key, value) P:set(key, value) end

-- The page in the game's Options (the kit's: K.options).
local O

function ns.createSettingsPanel()
  if O then return end
  O = K.options({
    title = "Mealbook",
    key = "MEALBOOK",
    get = ns.option,
    set = ns.setOption,
    defaults = DEFAULTS,
    profiles = P,
    slash = "/mealbook",
    prefix = ns.PREFIX,
  })
  O:choice(
    "chef",
    L["The chef's pages"],
    L["Whose pages the book shows above each dish: your side's chef, or the other one."],
    function() return { { 0, L["Your side's chef"] }, { 1, ns.chefName("kendor") }, { 2, ns.chefName("eunice") } } end
  )
  O:check(
    "tooltips",
    L["Dishes on ingredients' tooltips"],
    L["An ingredient's tooltip names the dishes you know it cooks into."]
  )
  O:check(
    "achievementToast",
    L["Alert for achievements"],
    L["Show each achievement earned in the game's achievement alert. A click on it opens the achievements."]
  )
  O:check("minimapHidden", L["Minimap button"], L["The book by the minimap: click to open it, drag to move it."], true)
  O:copy()
  O:done()
end

function ns.openSettings() return O ~= nil and O:open() end
