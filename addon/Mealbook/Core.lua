-- Mealbook: this character's cookbook, the events every file listens to
-- (ns.on, ns.onUnit), the cooking skill and the recipes known as the game
-- tells them, and /mealbook. The road (Road.lua) reads them; the book shows
-- them (Book.lua and its tabs).
--
--   MealbookChar (SavedVariablesPerCharacter), whose book: guid
--     known[spell] = { at, level }     each recipe learned (the game's cooking
--                                      window read, the spell known, the
--                                      game's line when one is learned)
--     cooked[spell] = n                each dish cooked
--     first[spell] = { at, level }     the first time it was cooked
--     skill = { rank, max, at }        the cooking skill as last read
--     peak                             the highest skill read
--     milestones[id] = { at, level, retro } each achievement earned
--                                      (Milestones.lua)
--   MealbookSettings (SavedVariables): chef, the reader's pick ("kendor",
--     "eunice"), else their faction's; tooltips (false: no pantry line on
--     an ingredient's tooltip, /mealbook tooltips)
--
-- Every record by id: a dish by its spell, an ingredient by its item; their
-- names are the game's, in the client's language, when shown.
local _, ns = ...
local L, D = ns.kit.L, ns.data
ns.PREFIX = "|cffe0a050Mealbook:|r "

-- Forever hides some values from addons ("secret values"): never compare one.
ns.secret = issecretvalue or function() return false end

local char
function ns.book() return char end

-- ── events ───────────────────────────────────────────────────────────────────
-- Every file listens through ns.on (an event a client doesn't know is never
-- heard), unit events through ns.onUnit. Nothing is heard before the login.
local frame = CreateFrame("Frame")
local listeners = {}

-- (one listener's error is reported, and the others still hear the event)
local function run(fn, ...)
  local ok, err = pcall(fn, ...)
  if not ok then geterrorhandler()(err) end
end

frame:SetScript("OnEvent", function(_, event, ...)
  if event == "PLAYER_LOGIN" then run(ns.login) end
  if not char then return end
  for _, fn in ipairs(listeners[event] or {}) do
    run(fn, ...)
  end
end)
frame:RegisterEvent("PLAYER_LOGIN")

function ns.on(event, fn)
  if not listeners[event] then
    listeners[event] = {}
    pcall(frame.RegisterEvent, frame, event)
  end
  table.insert(listeners[event], fn)
end

local unitFrame = CreateFrame("Frame")
local unitListeners = {}
unitFrame:SetScript("OnEvent", function(_, event, ...)
  if not char then return end
  for _, fn in ipairs(unitListeners[event] or {}) do
    run(fn, ...)
  end
end)
function ns.onUnit(event, unit, fn)
  if not unitListeners[event] then
    unitListeners[event] = {}
    pcall(unitFrame.RegisterUnitEvent, unitFrame, event, unit)
  end
  table.insert(unitListeners[event], fn)
end

-- ── the dishes ───────────────────────────────────────────────────────────────
-- A dish's facts (Recipes_<game>.lua), its name and the item it makes, by id.
function ns.recipe(spell) return D.recipes[spell] end
function ns.dishName(spell)
  local name = GetSpellInfo and GetSpellInfo(spell)
  if not name and C_Spell and C_Spell.GetSpellName then name = C_Spell.GetSpellName(spell) end
  return name or ("#" .. spell)
end

-- The dish an item is (a window's line names the item made where it gives no
-- recipe link).
local byItem = {}
for spell, d in pairs(D.recipes) do
  byItem[d.item] = byItem[d.item] or spell
end
function ns.dishOfItem(item) return item and byItem[item] end

local function at() return { at = time(), level = UnitLevel("player") } end

-- ── the skill ────────────────────────────────────────────────────────────────
-- Forever's professions by their skill line's id (GetProfessionInfo's
-- seventh); Classic Era's skill list by its name in the client's language
-- (ns.skillName, from the game's own data).
local RANKS = { 75, 150, 225, 300 }
ns.RANKS = RANKS

local function setSkill(rank, max)
  if ns.secret(rank) or not rank or rank <= 0 then return end
  local old, oldMax = char.skill and char.skill.rank, char.skill and char.skill.max
  char.skill = { rank = rank, max = max or oldMax or 75, at = time() }
  char.peak = math.max(char.peak or 0, rank)
  if old ~= rank or oldMax ~= char.skill.max then
    if ns.onChange then ns.onChange() end
    -- (the achievements: a point or a rank trained; the login's quietly)
    if ns.progressed and ns.loggedIn then ns.progressed() end
  end
end

function ns.readSkill()
  if GetProfessions and GetProfessionInfo then
    local slots = { GetProfessions() }
    for i = 1, select("#", GetProfessions()) do
      local index = slots[i]
      if index then
        local _, _, rank, max, _, _, line = GetProfessionInfo(index)
        if line == D.skillLine then return setSkill(rank, max) end
      end
    end
  end
  if GetNumSkillLines and GetSkillLineInfo and ns.skillName then
    for i = 1, GetNumSkillLines() do
      local name, header, _, rank, _, _, max = GetSkillLineInfo(i)
      if not header and name == ns.skillName then return setSkill(rank, max) end
    end
  end
end

function ns.skill() return char and char.skill and char.skill.rank or 0, char and char.skill and char.skill.max or 0 end

-- ── the recipes known ────────────────────────────────────────────────────────
-- A recipe joins the book the first time the game says it is known: quietly
-- at the login (a character who already cooks), else with a line in chat.
function ns.learnt(spell, quietly)
  if not D.recipes[spell] or char.known[spell] then return end
  char.known[spell] = at()
  if not quietly then
    print(ns.PREFIX .. L["A new page: %s."]:format("|cffffd27f" .. ns.dishName(spell) .. "|r"))
    if ns.onLearnt then ns.onLearnt(spell) end
    if ns.progressed then ns.progressed() end
  end
  if ns.onChange then ns.onChange() end
end
function ns.knows(spell) return char and char.known[spell] ~= nil end

-- Every dish the game says this character knows (IsPlayerSpell: a recipe is
-- a spell the character has).
function ns.askKnown(quietly)
  if not IsPlayerSpell then return end
  for _, spell in ipairs(D.order) do
    if IsPlayerSpell(spell) then ns.learnt(spell, quietly) end
  end
end

-- The cooking window's lines, each client's own calls (Blizzard's
-- TradeSkillUI on Classic Era, its Professions on Forever).
local function spellOfLink(link) return link and tonumber(link:match("enchant:(%d+)") or link:match("Hspell:(%d+)")) end
local function itemOfLink(link) return link and tonumber(link:match("item:(%d+)")) end

function ns.readWindow()
  if C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs then
    local ids = C_TradeSkillUI.GetAllRecipeIDs() or {}
    local ours = false
    for _, id in ipairs(ids) do
      if D.recipes[id] then
        ours = true
        local info = C_TradeSkillUI.GetRecipeInfo(id)
        if info and info.learned then ns.learnt(id) end
      end
    end
    if ours then ns.readSkill() end
    return
  end
  if not (GetTradeSkillLine and GetNumTradeSkills) then return end
  local name, rank, max = GetTradeSkillLine()
  if name ~= ns.skillName then return end
  setSkill(rank, max)
  for i = 1, GetNumTradeSkills() do
    local _, kind = GetTradeSkillInfo(i)
    if kind and kind ~= "header" then
      local spell = spellOfLink(GetTradeSkillRecipeLink and GetTradeSkillRecipeLink(i))
        or ns.dishOfItem(itemOfLink(GetTradeSkillItemLink and GetTradeSkillItemLink(i)))
      if spell then ns.learnt(spell) end
    end
  end
end

-- ── the login ────────────────────────────────────────────────────────────────
local function newBook(guid) return { guid = guid, known = {}, cooked = {}, first = {} } end

function ns.login()
  local guid = UnitGUID("player")
  if type(MealbookChar) ~= "table" or MealbookChar.guid ~= guid then MealbookChar = newBook(guid) end
  char = MealbookChar
  char.known, char.cooked, char.first = char.known or {}, char.cooked or {}, char.first or {}
  MealbookSettings = type(MealbookSettings) == "table" and MealbookSettings or {}
  ns.readSkill()
  ns.askKnown(true)
  -- (achievements already deserved: recorded quietly)
  if ns.progressed then ns.progressed(true) end
  ns.loggedIn = true
  local rank = ns.skill()
  local n = 0
  for _ in pairs(char.known) do
    n = n + 1
  end
  if n > 0 or rank > 0 then
    print(
      ns.PREFIX
        .. ns.kit.plural(n, "%d recipe, cooking %d.", "%d recipes, cooking %d."):format(n, rank)
        .. " "
        .. L["/mealbook opens the book."]
    )
  end
end

-- The window open or changed: its recipes, the skill.
ns.on("TRADE_SKILL_SHOW", ns.readWindow)
ns.on("TRADE_SKILL_UPDATE", ns.readWindow)
ns.on("TRADE_SKILL_LIST_UPDATE", ns.readWindow)
ns.on("NEW_RECIPE_LEARNED", function(id) ns.learnt(id) end)
ns.on("SKILL_LINES_CHANGED", ns.readSkill)
-- (a recipe learned from its item or a trainer: the game's line in chat, then
-- the recipes asked again)
ns.on("CHAT_MSG_SYSTEM", function(msg)
  if ns.secret(msg) or not ERR_LEARN_RECIPE_S then return end
  local pattern = "^" .. ERR_LEARN_RECIPE_S:gsub("([%.%(%)%-%+%*%?%[%]%^%$])", "%%%1"):gsub("%%s", ".+") .. "$"
  if msg:find(pattern) then ns.askKnown(false) end
end)

-- A dish cooked: counted by its cast.
ns.onUnit("UNIT_SPELLCAST_SUCCEEDED", "player", function(_, _, spell)
  if ns.secret(spell) or not D.recipes[spell] then return end
  char.cooked[spell] = (char.cooked[spell] or 0) + 1
  if not char.first[spell] then char.first[spell] = at() end
  ns.learnt(spell, true) -- (cooked, so known: a book that missed it)
  if ns.onChange then ns.onChange() end
  if ns.progressed then ns.progressed() end
end)

-- ── the chef ─────────────────────────────────────────────────────────────────
-- Whose book: the reader's pick, else their faction's chef (Kendor Kabonka
-- the Alliance's, Eunice Burch the Horde's).
ns.CHEFS = { "kendor", "eunice" }
function ns.chef()
  local pick = MealbookSettings and MealbookSettings.chef
  if pick == "kendor" or pick == "eunice" then return pick end
  return UnitFactionGroup("player") == "Horde" and "eunice" or "kendor"
end
function ns.chefName(chef) return ns.chefNames and ns.chefNames[chef or ns.chef()] or "" end

-- ── /mealbook ────────────────────────────────────────────────────────────────
SLASH_MEALBOOK1 = "/mealbook"
SlashCmdList.MEALBOOK = function(msg)
  msg = strtrim((msg or ""):lower())
  if msg == "road" then
    if ns.openRoad then ns.openRoad() end
  elseif msg == "chef" then
    MealbookSettings.chef = ns.chef() == "kendor" and "eunice" or "kendor"
    print(ns.PREFIX .. L["Your cookbook is now %s's."]:format(ns.chefName()))
    if ns.onChange then ns.onChange() end
  elseif msg == "tooltips" then
    MealbookSettings.tooltips = MealbookSettings.tooltips == false
    print(
      ns.PREFIX
        .. (
          MealbookSettings.tooltips and L["Ingredients' tooltips name the dishes they cook into."]
          or L["Ingredients' tooltips left as the game's."]
        )
    )
  elseif ns.toggle then
    ns.toggle()
  end
end
