-- A small game for Mealbook's tests (the kit's game, wowmock.lua: frames, events and timers):
-- the cooking skill as each client tells it (Classic Era's skill list by its
-- name, Forever's professions by their id), the recipes the character knows
-- (IsPlayerSpell), the cooking window's lines (Classic Era's TradeSkillUI
-- calls, Forever's C_TradeSkillUI), the dishes' and items' names by id, the
-- bags. FOREVER=1 plays Forever's client, LOCALE=frFR a French one.
local G = dofile("addon/test/wowmock.lua")
local state, FOREVER, LOCALE, obj = G.state, G.FOREVER, G.LOCALE, G.obj
if FOREVER then
  G.invalidEvents.TRADE_SKILL_UPDATE = true
else
  G.invalidEvents.TRADE_SKILL_LIST_UPDATE = true
  G.invalidEvents.NEW_RECIPE_LEARNED = true
end

ERR_LEARN_RECIPE_S = LOCALE == "frFR" and "Vous avez appris à fabriquer un nouvel objet : %s."
  or "You have learned how to create a new item: %s."

-- ── cooking ──────────────────────────────────────────────────────────────────
-- state.skill: { rank, max } (nil: no cooking); state.known[spell]: the
-- recipes the character has; state.window: the cooking window open, its lines
-- (the known recipes, by the book's own spells and their items)
state.known = {}
local SKILL_NAME = LOCALE == "frFR" and "Cuisine" or "Cooking"
if FOREVER then
  -- (Forever: the professions, cooking fifth, by its skill line's id)
  function GetProfessions() return nil, nil, nil, nil, state.skill and 7 or nil end
  function GetProfessionInfo(i)
    if i ~= 7 or not state.skill then return nil end
    return SKILL_NAME, 133971, state.skill.rank, state.skill.max, 0, 0, 185
  end
  C_TradeSkillUI = {
    GetAllRecipeIDs = function()
      local out = {}
      for spell in pairs(state.windowRecipes or {}) do
        table.insert(out, spell)
      end
      table.sort(out)
      return out
    end,
    GetRecipeInfo = function(id) return { recipeID = id, learned = state.known[id] == true } end,
  }
else
  -- (Classic Era: the skill list, by its name in the client's language)
  function GetNumSkillLines() return 3 end
  function GetSkillLineInfo(i)
    if i == 1 then return LOCALE == "frFR" and "Métiers secondaires" or "Secondary Skills", true end
    if i == 2 and state.skill then return SKILL_NAME, false, nil, state.skill.rank, 0, 0, state.skill.max end
    if i == 3 then return LOCALE == "frFR" and "Pêche" or "Fishing", false, nil, 20, 0, 0, 75 end
    return LOCALE == "frFR" and "Langues" or "Languages", true
  end
  function GetTradeSkillLine()
    if not state.window then return "UNKNOWN", 0, 0 end
    return SKILL_NAME, state.skill.rank, state.skill.max
  end
  local lines = function()
    local out = {}
    for spell in pairs(state.windowRecipes or {}) do
      table.insert(out, spell)
    end
    table.sort(out)
    return out
  end
  function GetNumTradeSkills() return state.window and #lines() + 1 or 0 end
  function GetTradeSkillInfo(i)
    if i == 1 then return "Meat", "header" end
    local spell = lines()[i - 1]
    return G.names[spell] or "?", "orange"
  end
  function GetTradeSkillRecipeLink(i)
    local spell = lines()[i - 1]
    return spell and ("|cffffd000|Henchant:%d|h[%s]|h|r"):format(spell, G.names[spell] or "?")
  end
  function GetTradeSkillItemLink() return nil end
end
function IsPlayerSpell(spell) return state.known[spell] == true end

-- the dishes' and items' names by id, in the client's language (the few the
-- tests meet)
G.names = {
  [2538] = "Charred Wolf Meat",
  [2540] = "Roasted Boar Meat",
  [8604] = "Herb Baked Egg",
  [6412] = "Kaldorei Spider Kabob",
  [2539] = "Spiced Wolf Meat",
  [2795] = "Beer Basted Boar Ribs",
}
if FOREVER then
  C_Spell = { GetSpellName = function(id) return G.names[id] end }
else
  function GetSpellInfo(id) return G.names[id] end
end
state.bags = {}
function GetItemCount(item) return state.bags[item] or 0 end
function GetItemInfo(id) return "Item " .. id, nil, 1 end
function GetItemIcon() return 134400 end

-- ── the addon ────────────────────────────────────────────────────────────────
G.load("Mealbook")
-- The cooking window opened, showing these recipes.
function G.openWindow(recipes)
  state.window, state.windowRecipes = true, {}
  for _, spell in ipairs(recipes) do
    state.windowRecipes[spell] = true
    state.known[spell] = true -- (the window lists what the character knows)
  end
  G.fire("TRADE_SKILL_SHOW")
end
return G
