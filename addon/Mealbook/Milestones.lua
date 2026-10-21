-- Milestones: the cookbook's achievements ("achievements" to the player, as
-- the family's other books). The ranks (cooking learned, each rank trained,
-- 300), the recipes known, the dishes cooked, the first dish of each chapter
-- this game has, the hunts found. Each character earns its own, and each
-- remembers when and at what level:
--   MealbookChar.milestones[id] = { at, level, retro }
-- Earned as the game's own achievements are: its fanfare, a banner among its
-- alerts (the kit's), a line in chat. Those already deserved when the book
-- first looks (a cook from before milestones, at the login) are recorded
-- quietly.
local _, ns = ...
local K, L, D = ns.kit, ns.kit.L, ns.data
local ICON = "Interface\\AddOns\\Mealbook\\Media\\Logo"

local list = {}
ns.milestones = list
ns.milestoneById = {}
local function add(group, id, title, text, progress, visible)
  local m = { group = group, id = id, title = title, text = text, progress = progress, visible = visible }
  table.insert(list, m)
  ns.milestoneById[id] = m
end

local function book() return ns.book() end
local function known()
  local c = book()
  local n = 0
  for spell in pairs(c and c.known or {}) do
    if D.recipes[spell] then n = n + 1 end
  end
  return n
end
local function cooked()
  local c = book()
  local n = 0
  for _, times in pairs(c and c.cooked or {}) do
    n = n + times
  end
  return n
end

-- ── the ranks ────────────────────────────────────────────────────────────────
-- (the skill's cap: 75 apprentice, 150 journeyman, 225 expert, 300 artisan)
local function cap()
  local _, max = ns.skill()
  return max or 0
end
add("ranks", "rank-75", L["Apprentice Cook"], L["Learn to cook."], function() return cap() >= 75 and 1 or 0, 1 end)
add(
  "ranks",
  "rank-150",
  L["Journeyman Cook"],
  L["Train to Journeyman."],
  function() return cap() >= 150 and 1 or 0, 1 end
)
add("ranks", "rank-225", L["Expert Cook"], L["Train to Expert."], function() return cap() >= 225 and 1 or 0, 1 end)
add("ranks", "rank-300", L["Artisan Cook"], L["Train to Artisan."], function() return cap() >= 300 and 1 or 0, 1 end)
add(
  "ranks",
  "skill-300",
  L["Three Hundred"],
  L["Reach cooking 300."],
  function() return math.min(ns.skill(), 300), 300 end
)

-- ── the recipes known ────────────────────────────────────────────────────────
-- (the last: every dish this side can learn in this game, a hunt at the
-- auction house too, the known ones it can't counting as well)
local function learnable()
  local mine, n = ns.hunts.mine(), 0
  local c = book()
  for _, spell in ipairs(D.order) do
    local d = D.recipes[spell]
    local s = ns.hunts.sources(spell, mine)
    local reachable = not d.unknown and (s.skill or s.trainer or #s.shop > 0 or ns.hunts.of(spell, mine) ~= nil)
    if reachable or (c and c.known[spell]) then n = n + 1 end
  end
  return n
end
for _, step in ipairs({
  { 10, L["A Few Good Dishes"] },
  { 25, L["A Notebook of Recipes"] },
  { 50, L["Fifty Dishes"] },
  { 75, L["A Cook's Library"] },
}) do
  local need, title = step[1], step[2]
  -- (a step past what this side can learn in this game: none, the whole book
  -- the last)
  add(
    "recipes",
    "known-" .. need,
    title,
    L["Know %d recipes."]:format(need),
    function() return known(), need end,
    function() return need < learnable() end
  )
end
add(
  "recipes",
  "known-all",
  L["The Whole Book"],
  L["Know every recipe your side can learn."],
  function() return known(), learnable() end
)

-- ── the dishes cooked ────────────────────────────────────────────────────────
for _, step in ipairs({
  { 50, L["Fifty Plates"] },
  { 250, L["Kitchen Duty"] },
  { 1000, L["A Thousand Meals"] },
  { 5000, L["Feeding an Army"] },
}) do
  local need, title = step[1], step[2]
  add("cooked", "cooked-" .. need, title, L["Cook %d dishes."]:format(need), function() return cooked(), need end)
end

-- ── the first of each chapter ────────────────────────────────────────────────
-- (a chapter this game has no dish in has none)
local FIRSTS = {
  { "meat", L["First Roast"], L["Cook a dish of roasts and grills."] },
  { "fish", L["Fresh from the Water"], L["Cook a dish of fish or seafood."] },
  { "soup", L["A Pot on the Fire"], L["Cook a soup or a stew."] },
  { "bake", L["Out of the Oven"], L["Cook an egg dish, a pie or a bake."] },
  { "drink", L["Something to Drink"], L["Make a drink."] },
  { "feast", L["A Table for Everyone"], L["Cook a feast."] },
  { "fire", L["Kindled"], L["Build a cooking fire or an oven."] },
}
for _, f in ipairs(FIRSTS) do
  local chapter = f[1]
  local any = false
  for _, spell in ipairs(D.order) do
    if D.recipes[spell].chapter == chapter then any = true end
  end
  if any then
    add("firsts", "first-" .. chapter, f[2], f[3], function()
      local c = book()
      for spell in pairs(c and c.cooked or {}) do
        local d = D.recipes[spell]
        if d and d.chapter == chapter then return 1, 1 end
      end
      return 0, 1
    end)
  end
end

-- ── the hunts ────────────────────────────────────────────────────────────────
local function hunts()
  local c = book()
  local _, _, found, total = ns.hunts.list(c and c.known or {}, ns.skill(), ns.hunts.mine())
  return found, total
end
add("hunts", "hunts-1", L["A Find"], L["Learn a recipe from a hunt."], function() return math.min(hunts(), 1), 1 end)
add(
  "hunts",
  "hunts-5",
  L["Five Finds"],
  L["Learn five recipes from hunts."],
  function() return math.min(hunts(), 5), 5 end,
  function() return select(2, hunts()) > 5 end
)
add("hunts", "hunts-all", L["Nothing Left to Find"], L["Learn every recipe of your side's hunts."], function()
  local found, total = hunts()
  return found, total
end)

-- ── earning ──────────────────────────────────────────────────────────────────
function ns.earnedMilestone(id)
  local c = book()
  return c and c.milestones and c.milestones[id]
end

-- Listed: earned, or one this character can earn.
function ns.milestoneVisible(m) return ns.earnedMilestone(m.id) ~= nil or not m.visible or m.visible() end

-- Earned, and listed.
function ns.milestoneCount()
  local n, shown = 0, 0
  for _, m in ipairs(list) do
    if ns.earnedMilestone(m.id) then n = n + 1 end
    if ns.milestoneVisible(m) then shown = shown + 1 end
  end
  return n, shown
end

-- The fanfare of the game's achievements (a client without it: none).
local FANFARE = 12891
local function fanfare() pcall(PlaySound, FANFARE, "Master") end

local banners
local GROUP_ICONS = {
  ranks = "Interface\\Icons\\INV_Misc_Food_15",
  recipes = "Interface\\Icons\\INV_Misc_Book_11",
  cooked = "Interface\\Icons\\INV_Misc_Food_14",
  firsts = "Interface\\Icons\\INV_Misc_Food_13",
  hunts = "Interface\\Icons\\INV_Misc_Bag_10_Blue",
}
ns.milestoneIcons = GROUP_ICONS

local function announce(m)
  print(ns.PREFIX .. L["Achievement earned: %s."]:format("|cffffd100[" .. m.title .. "]|r"))
  fanfare()
  banners = banners or K.banners({ name = "MealbookBanner", art = ICON })
  banners:show({
    picture = K.icon(GROUP_ICONS[m.group] or ICON),
    kicker = L["Mealbook achievement"],
    title = m.title,
    tip = m.text,
    click = function()
      if ns.openMilestones then ns.openMilestones(m.id) end
    end,
  })
end

-- quiet: record without a word (reached before the book looked: the login).
function ns.checkMilestones(quiet)
  local c = book()
  if not c then return end
  c.milestones = c.milestones or {}
  local earned = false
  for _, m in ipairs(list) do
    if not c.milestones[m.id] and ns.milestoneVisible(m) then
      local done, need = m.progress()
      if need > 0 and done >= need then
        c.milestones[m.id] = { at = time(), level = UnitLevel("player"), retro = quiet or nil }
        earned = true
        if not quiet then announce(m) end
      end
    end
  end
  if earned and ns.onChange then ns.onChange() end
  return earned
end
ns.progressed = ns.checkMilestones
