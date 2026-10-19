-- Mealbook played through: a cook's first login (the recipes known taken
-- quietly), the cooking window read, a recipe learned from its item, dishes
-- cooked, the road to 300 from the skill now, and the book opened on each
-- tab. FOREVER=1, LOCALE=frFR: those clients.
local G = dofile("addon/test/game.lua")
local s, fire, ns = G.state, G.fire, G.ns
local count = 0
local function check(ok, what)
  if not ok then error("✗ " .. what, 2) end
  count = count + 1
end
local L = ns.kit.L
local function said(text)
  for _, line in ipairs(s.printed) do
    if line:find(text, 1, true) then return true end
  end
  return false
end
-- (the start of a line the addon says, in the client's language)
local NEW_PAGE = L["A new page: %s."]:match("^(.-)%%s")

-- ── a cook's first login ─────────────────────────────────────────────────────
s.skill = { rank = 12, max = 75 }
s.known = { [2538] = true, [2540] = true, [8604] = true }
G.login()
local char = MealbookChar
check(char.guid == s.guid, "the book is this character's")
check(ns.skill() == 12, "the cooking skill read, by its id (Forever) or its name in the client's language")
check(char.known[2538] and char.known[2540] and char.known[8604], "the recipes the character knows, taken")
check(not said(NEW_PAGE), "quietly at the first login")
check(said(L["%d recipes, cooking %d."]:format(3, 12)), "the login's line: the recipes and the skill")

-- ── the cooking window ───────────────────────────────────────────────────────
s.printed = {}
G.openWindow({ 2538, 2540, 8604, 6412 })
check(char.known[6412], "a recipe the window lists joins the book")
check(said(NEW_PAGE), "said in chat")

-- ── a recipe learned from its item ───────────────────────────────────────────
s.printed = {}
s.known[2795] = true
fire("CHAT_MSG_SYSTEM", ERR_LEARN_RECIPE_S:format("Beer Basted Boar Ribs"))
check(char.known[2795], "the game's line: the recipes asked again, the new one in")
if G.FOREVER then
  s.known[2539] = true
  fire("NEW_RECIPE_LEARNED", 2539)
  check(char.known[2539], "Forever: a recipe learned, told by its own event")
end

-- ── dishes cooked ────────────────────────────────────────────────────────────
fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-1", 2538)
fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-2", 2538)
fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-3", 133) -- (a fireball: no dish)
check(char.cooked[2538] == 2 and char.first[2538], "each dish cooked counted, the first time kept")
check(char.cooked[133] == nil, "a spell that's no dish isn't")

-- ── the achievements ─────────────────────────────────────────────────────────
local earned = char.milestones or {}
check(earned["rank-75"] and earned["rank-75"].retro, "an achievement already deserved at the login: recorded quietly")
check(not said(L["Achievement earned: %s."]:format("|cffffd100[" .. L["Apprentice Cook"] .. "]|r")), "without a word")
check(earned["first-meat"] and not earned["first-meat"].retro, "the first roast cooked: earned")
check(said(L["Achievement earned: %s."]:format("|cffffd100[" .. L["First Roast"] .. "]|r")), "said in chat")
check(MealbookBanner1 and MealbookBanner1:IsShown(), "and its banner among the game's alerts")
check(not earned["first-fish"], "a chapter not cooked yet: not earned")
local feasts = false
for _, m in ipairs(ns.milestones) do
  if m.id == "first-feast" then feasts = true end
end
check(feasts == (G.FOREVER and true or false), "a chapter's first only where the game has its dishes")

-- ── the road ─────────────────────────────────────────────────────────────────
local R = ns.road
local wolf = ns.recipe(2538) -- (Charred Wolf Meat: orange to 45, grey at 85)
check(R.colour(wolf, 12) == "orange" and R.chance(wolf, 12) == 1, "orange: always a point")
check(
  R.colour(wolf, 50) == "yellow" and math.abs(R.chance(wolf, 50) - 35 / 40) < 1e-9,
  "yellow: (grey - skill) / (grey - yellow)"
)
check(
  R.colour(wolf, 70) == "green" and R.colour(wolf, 85) == "grey" and R.chance(wolf, 85) == 0,
  "green halfway, grey never"
)
local known = { [2538] = true, [2540] = true, [8604] = true }
local legs = R.plan(known, 12, 75, function() return 0 end)
check(legs[1].spell and legs[1].from == 12, "the road starts at the skill now")
local trained = false
for _, leg in ipairs(legs) do
  if leg.train == 150 and leg.from == 75 then trained = true end
end
check(trained, "at 75, a stop to train Journeyman")
check(legs.stuck == 85, "where every recipe known is grey, the road stops")
local first = legs[1]
check(math.abs(first.casts - (first.to - first.from)) < 1e-9 or first.to > 45, "orange points: a cast each")
local worth = R.worth(known, 85, 5)
check(#worth > 0, "the recipes worth learning where it stops")
for _, spell in ipairs(worth) do
  check(R.chance(ns.recipe(spell), 85) > 0 and not known[spell], "each still raises the skill there, and is new")
end
-- (the bags: a recipe cooked from what is carried preferred, at the same chance)
s.bags = { [2672] = 10 } -- Stringy Wolf Meat
local egg = ns.recipe(8604)
check(R.cookable(wolf, function(i) return s.bags[i] or 0 end) == 10, "how many casts the bags allow")
check(R.cookable(egg, function(i) return s.bags[i] or 0 end) == 0, "none without its ingredients")
local withBags = R.plan(known, 12, 75, function(i) return s.bags[i] or 0 end)
check(withBags[1].spell == 2538, "the same chance: the one the bags can cook first")
local shopping, casts = R.shopping(withBags[1])
check(casts >= 1 and shopping[1][1] == 2672, "a leg's ingredients, its casts rounded up")

-- ── the chef ─────────────────────────────────────────────────────────────────
check(ns.chef() == "kendor", "an Alliance cook's book is Kendor's")
local kendor = ns.pageText("kendor", 2538)
check(kendor and #kendor > 0 and #ns.pageText("eunice", 2538) > 0, "every dish has both chefs' pages")
SlashCmdList.MEALBOOK("chef")
check(ns.chef() == "eunice" and MealbookSettings.chef == "eunice", "/mealbook chef: the other chef's book")
check(said(ns.chefName("eunice")), "said in chat, with her name as the game gives it")
SlashCmdList.MEALBOOK("chef")
check(ns.chef() == "kendor", "and back")
if G.LOCALE == "frFR" then
  -- (a French page names places as Forever does: Classic Era's names swapped in there)
  local p = ns.pageText("kendor", 2795)[1]
  if G.FOREVER then
    check(p:find("Hurlevent"), "Forever: Hurlevent, as its client names Stormwind")
  else
    check(p:find("Stormwind") and not p:find("Hurlevent"), "Classic Era: Stormwind, as its French client names it")
  end
end

-- ── the hunts ────────────────────────────────────────────────────────────────
local H, D = ns.hunts, ns.data
check(H.mine() == "A", "the character's side: the Alliance")
-- every npc and quest the data names: a name (an npc's in every language)
local unnamed = 0
for id in pairs(D.npcs) do
  if not ns.npcNames[id] or ns.npcNames[id] == "" then unnamed = unnamed + 1 end
end
check(unnamed == 0, "every seller, dropper and quest giver named in the client's language")
-- the Winter Veil's vendors stand in the capitals: their side is their city's
if not G.FOREVER then
  check(D.npcs[13420].side == "H" and D.npcs[13435].side == "A", "a capital's vendor serves its side")
end
local function hunts(side)
  local out, wrong = {}, 0
  for _, spell in ipairs(D.order) do
    local s = H.of(spell, side)
    if s then
      table.insert(out, spell)
      if s.skill or s.trainer or #s.shop > 0 then wrong = wrong + 1 end
      if #s.limited + #s.drops + #s.quests == 0 and not s.world then wrong = wrong + 1 end
      for _, v in ipairs(s.limited) do
        if D.npcs[v].side and D.npcs[v].side ~= side then wrong = wrong + 1 end
      end
      for _, q in ipairs(s.quests) do
        if D.quests[q].side and D.quests[q].side ~= side then wrong = wrong + 1 end
      end
    end
  end
  return out, wrong
end
local forA, wrongA = hunts("A")
local forH, wrongH = hunts("H")
check(#forA > 0 and #forH > 0, "hunts for each side")
check(wrongA == 0 and wrongH == 0, "a hunt: no shop for its side, a find of its side")
-- the road's recipes worth learning: only from the shop of the cook's side
local shopWrong = 0
for _, side in ipairs({ "A", "H" }) do
  for _, spell in ipairs(R.worth({}, 300, nil, side)) do
    local s = H.sources(spell, side)
    if not (s.skill or s.trainer or #s.shop > 0) then shopWrong = shopWrong + 1 end
    for _, v in ipairs(s.shop) do
      if D.npcs[v].side and D.npcs[v].side ~= side then shopWrong = shopWrong + 1 end
    end
  end
end
check(shopWrong == 0, "the road sends no one to a stall of the other side, nor after a hunt")
local open0, next0 = H.list({}, 1, "A")
check(#open0 == 0 and next0 and next0 > 1, "at cooking 1 no hunt is open, the next said")
local open300, next300, found, total = H.list({}, 300, "A")
check(#open300 > 0 and next300 == nil and found == 0 and total == #forA, "at 300 every hunt of the side is open")
local known1 = { [open300[1]] = { at = 0 } }
local open1, _, found1 = H.list(known1, 300, "A")
check(found1 == 1 and #open1 == #open300 - 1, "a hunt found leaves the list and counts")
for i = 2, #open300 do
  local a, b = D.recipes[open300[i - 1]], D.recipes[open300[i]]
  if R.chance(a, 300) == 0 and R.chance(b, 300) > 0 then check(false, "the hunts that still raise the skill first") end
end

-- ── the book ─────────────────────────────────────────────────────────────────
SlashCmdList.MEALBOOK("")
check(MealbookFrame and MealbookFrame:IsShown(), "/mealbook opens the book")
ns.refresh()
ns.openDish(2538)
ns.refresh()
SlashCmdList.MEALBOOK("road")
check(MealbookFrame.tab == 2, "/mealbook road opens the road")
ns.openMilestones("first-meat")
check(MealbookFrame.tab == 4 and #ns.milestoneRows > 0, "the achievements' board, one picked out")
check(not MealbookFrame.left:IsShown() and not MealbookFrame.sheet:IsShown(), "over both panels")
-- the hunts' tab and every hunt's page, on each side (a page that fails to
-- draw fails here)
local skillBefore = char.skill
char.skill = { rank = 300, max = 300, at = 0 }
for _, side in ipairs({ "Alliance", "Horde" }) do
  s.faction = side
  ns.openHunts()
  check(MealbookFrame.tab == 3, "the hunts' tab")
  for _, spell in ipairs(H.list({}, 300, H.mine())) do
    ns.openHunt(spell)
  end
end
-- a quest the language has no title for: its giver named instead
local q = next(D.quests)
local title = ns.questNames[q]
ns.questNames[q] = nil
for _, spell in ipairs(D.order) do
  local src = H.of(spell, "A") or H.of(spell, "H")
  if src and src.quests[1] == q then ns.openHunt(spell) end
end
ns.questNames[q] = title
s.faction = nil
char.skill = skillBefore
ns.openRoad()
fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-4", 2540)
G.advance(0.5)
check(char.cooked[2540] == 1, "a dish cooked while the book is open")

io.write(("Mealbook: %d checks passed (%s, %s).\n"):format(count, G.LOCALE, G.FOREVER and "Forever" or "Classic Era"))
