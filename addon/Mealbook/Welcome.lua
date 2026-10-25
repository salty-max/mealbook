-- The welcome (the kit's, Kit.lua): once per character, a few seconds after
-- its first login (out of combat; /mealbook welcome shows it again), laid out
-- as the book's window: on the left what Mealbook is and whose book it is;
-- on the right this character's choices (Settings.lua: the chef, the
-- ingredients' tooltip line, the minimap button), then another character's
-- to take, chosen among this game's or brought by a code (/mealbook export
-- there). Closing it, however, is enough to have seen it.
local _, ns = ...
local K = ns.kit
local L = K.L

local LOGO = "Interface\\AddOns\\Mealbook\\Media\\Logo"

local W = K.welcome({
  name = "MealbookWelcome",
  title = L["Welcome to Mealbook"],
  art = LOGO,
  logo = LOGO,
  heading = "Mealbook",
  tagline = L["A chef's cookbook, and the road to 300."],
  intro = function()
    return L["Every recipe you learn gets its page, with a word from a chef of Azeroth: %s for the Alliance, %s for the Horde."]:format(
      ns.chefName("kendor"),
      ns.chefName("eunice")
    ) .. "\n\n" .. L["The road tells you what to cook next, how many times and what to buy, from your skill now to 300. The hunts keep the recipes you have to find rather than buy."] .. "\n\n" .. L["Open your cooking window once: the book reads the recipes you already know."]
  end,
  profiles = ns.profiles,
  choices = function()
    return {
      {
        text = L["The chef's pages"],
        hint = L["Whose pages the book shows above each dish."],
        options = {
          { value = 0, text = L["Your side's chef"] },
          { value = 1, text = ns.chefName("kendor") },
          { value = 2, text = ns.chefName("eunice") },
        },
        get = function() return ns.option("chef") end,
        set = function(v) ns.setOption("chef", v) end,
      },
      {
        text = L["Dishes on ingredients' tooltips"],
        hint = L["An ingredient's tooltip names the dishes you know it cooks into."],
        get = function() return ns.option("tooltips") end,
        set = function(v) ns.setOption("tooltips", v) end,
      },
      K.minimapChoice(ns.option, ns.setOption),
    }
  end,
  footnote = L["Change them any time: /mealbook settings, or a right-click on the minimap button. /mealbook opens the book."],
  open = { text = L["Open the book"], click = function() ns.toggle() end },
  exportHint = L["Copy it (Ctrl+C), then on another character: Use a code, or /mealbook import CODE."],
  importHint = L["Paste the code (/mealbook export on the other character), then press Enter."],
  refused = L["That isn't a Mealbook settings code."],
})

ns.welcome = W -- (its frame, rows, picker and code: for the tests)
function ns.showWelcome(mode) W:Show(mode) end

K.welcomeOnce(W, ns.profiles, function() return ns.book() ~= nil end)
