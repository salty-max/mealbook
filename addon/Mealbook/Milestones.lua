-- Milestones: the cookbook's achievements ("achievements" to the player, as
-- the family's other books). The ranks (cooking learned, each rank trained,
-- 300), the recipes known, the dishes cooked, the first dish of each chapter
-- this game has, the hunts found. Each character earns its own, and each
-- remembers when and at what level:
--   MealbookChar.milestones[id] = { at, level, retro }
-- Earned as the game's own achievements are: its fanfare, its own alert
-- (behind a switch of the options: achievementToast), a line in chat. Those already deserved when the book
-- first looks (a cook from before milestones, at the login) are recorded
-- quietly.
local _, ns = ...
local K, L, D = ns.kit, ns.kit.L, ns.data
local ICON = "Interface\\AddOns\\Mealbook\\Media\\Logo"

-- (the kit's achievements: K.deeds, the family's one way; the game's alert
-- behind a switch, the fanfare, a line in chat)
local GROUP_ICONS = {
  ranks = "Interface\\Icons\\INV_Misc_Food_15",
  recipes = "Interface\\Icons\\INV_Misc_Book_11",
  cooked = "Interface\\Icons\\INV_Misc_Food_14",
  firsts = "Interface\\Icons\\INV_Misc_Food_13",
  hunts = "Interface\\Icons\\INV_Misc_Bag_10_Blue",
}
ns.milestoneIcons = GROUP_ICONS
local A = K.deeds({
  saved = function()
    local c = ns.book()
    if not c then return nil end
    c.milestones = c.milestones or {}
    return c.milestones
  end,
  name = "Mealbook",
  prefix = ns.PREFIX,
  art = ICON,
  kicker = L["Mealbook achievement"],
  alert = function() return ns.option("achievementToast") end,
  open = function(id)
    if ns.openMilestones then ns.openMilestones(id) end
  end,
  picture = function(d) return K.icon(GROUP_ICONS[d.group] or ICON) end,
  banners = K.banners({ name = "MealbookBanner", art = ICON }),
  changed = function()
    if ns.onChange then ns.onChange() end
  end,
})
ns.deeds = A
ns.milestones, ns.milestoneById = A.list, A.byId
local function add(group, id, title, text, progress, visible) A:add(group, id, title, text, progress, visible) end

local function book() return ns.book() end
-- (a recipe only the other side gets, learned at the auction house, counts
-- for no achievement: not known, not cooked, not a chapter's first)
local function counts(spell) return D.recipes[spell] ~= nil and not ns.hunts.theirs(spell, ns.hunts.mine()) end
local function known()
  local c = book()
  local n = 0
  for spell in pairs(c and c.known or {}) do
    if counts(spell) then n = n + 1 end
  end
  return n
end
local function cooked()
  local c = book()
  local n = 0
  for spell, times in pairs(c and c.cooked or {}) do
    if counts(spell) then n = n + times end
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
-- (the last: every dish this side can learn in this game on its own, not the
-- auction house's, a known one no source has seen yet counting too)
local function learnable()
  local mine, n = ns.hunts.mine(), 0
  local c = book()
  for _, spell in ipairs(D.order) do
    local d = D.recipes[spell]
    local s = ns.hunts.sources(spell, mine)
    local h = ns.hunts.of(spell, mine)
    local reachable = not d.unknown and (s.skill or s.trainer or #s.shop > 0 or (h ~= nil and not h.auction))
    if reachable or (c and c.known[spell] and counts(spell)) then n = n + 1 end
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
        if d and d.chapter == chapter and counts(spell) then return 1, 1 end
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
function ns.earnedMilestone(id) return A:earned(id) end
-- Listed: earned, or one this character can earn.
function ns.milestoneVisible(m) return A:visible(m) end
-- Earned, and listed.
function ns.milestoneCount() return A:count() end
-- quiet: record without a word (reached before the book looked: the login).
function ns.checkMilestones(quiet) return A:check(quiet) end
ns.progressed = ns.checkMilestones
