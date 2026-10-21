-- The road tab: from the skill now to 300 (Road.lua), its legs on the left
-- (a recipe from one skill to another, one to learn first, a stop to train),
-- the road on the page (each leg as a card, where it stops: the hunts open
-- there), and a leg's own
-- page: where to learn its recipe (the nearest trainer or vendor of the
-- character's side), its casts, its colours, its ingredients and how many of
-- each, against the bags; a stop's: how the rank is learned there (the
-- cooking trainers, the cookbook and who sells it, the quest: Recipes_<game>'s
-- ranks) and what it asks. A character who doesn't cook yet: the road from 1,
-- learning cooking first.
local _, ns = ...
local K, L, D, ui = ns.kit, ns.kit.L, ns.data, ns.ui
local T = ui.T
local book, list, page
local current -- (a leg's index, else the road)
local legs = {}
local rows = {}

local function style(row, kind)
  row.count:SetPoint("RIGHT", -4, 0)
  row.text:SetPoint("LEFT", kind == "overview" and 4 or 14, 0)
  row.text:SetPoint("RIGHT", row.count, "LEFT", -4, 0)
  row.text:SetFont(ns.kit.BODY_FONT, 12, "")
  row.text:SetTextColor(unpack(kind == "overview" and T.gold or T.text))
  return 18
end

-- (who serves the character's side, the nearest first)
local function serving(ids)
  local out, mine = {}, ns.hunts.mine()
  for _, id in ipairs(ids or {}) do
    local n = D.npcs[id]
    if n and ns.hunts.serves(n.side, mine) then table.insert(out, id) end
  end
  return ui.byNearness(out)
end

-- Where a recipe the road needs is learned: a cooking trainer (one the skill
-- itself gives: the trainer's too), else a vendor of the side, the nearest.
-- (once a recipe a road: the planner asks at every point)
local function learnableOnce()
  local seen = {}
  return function(spell)
    if seen[spell] == nil then
      local s = ns.hunts.sources(spell, ns.hunts.mine())
      if s.skill or s.trainer then
        seen[spell] = { trainer = true }
      elseif #s.shop > 0 then
        seen[spell] = { vendor = serving(s.shop)[1] }
      else
        seen[spell] = false
      end
    end
    return seen[spell] or nil
  end
end

local function plan()
  local char = ns.book()
  local skill, max = ns.skill()
  local known = char and char.known or {}
  local learnable = learnableOnce()
  if skill == 0 then
    -- (no cooking yet: learning it first, then the road from 1)
    local road = ns.road.plan(known, 1, 75, ui.have, 300, learnable)
    table.insert(road, 1, { train = 75, from = 0, rank = D.ranks and D.ranks[75] })
    return road
  end
  return ns.road.plan(known, skill, max, ui.have, 300, learnable)
end

local RANK_NAMES = { [75] = L["Apprentice"], [150] = L["Journeyman"], [225] = L["Expert"], [300] = L["Artisan"] }

local function legTitle(leg)
  if leg.train == 75 then return L["Learn cooking"] end
  if leg.train then return L["Train %s"]:format(RANK_NAMES[leg.train] or "") end
  return ns.dishName(leg.spell)
end

-- A stop's line: how its rank is learned, short.
local function trainLine(leg)
  local r = leg.rank or {}
  if leg.train == 75 then
    return r.level and L["From a cooking trainer, from level %d"]:format(r.level) or L["From a cooking trainer"]
  end
  if r.trainers then return L["At %d: from a cooking trainer"]:format(leg.from) end
  if r.items then
    local seller = serving(r.sellers)[1]
    if seller then return L["At %d: a cookbook, sold by %s"]:format(leg.from, ui.npcName(seller)) end
  end
  if r.quests then
    local q = D.quests[r.quests[1]] or {}
    if q.giver then return L["At %d: a quest from %s"]:format(leg.from, ui.npcName(q.giver)) end
  end
  return L["At %d: the next rank"]:format(leg.from)
end

local function refreshList()
  list:begin()
  local row = list:add("overview", L["The road to 300"])
  row:SetScript("OnClick", function()
    current = nil
    ns.refresh()
  end)
  if not current then list:pick(row) end
  for i, leg in ipairs(legs) do
    local r = list:add(
      "leg",
      (leg.learn and "+ " or "") .. legTitle(leg),
      leg.train and "" or ("%d-%d"):format(leg.from, leg.to)
    )
    r:SetScript("OnClick", function()
      current = i
      ns.refresh()
    end)
    if current == i then list:pick(r) end
  end
  list:finish()
end

-- The hunts open at this skill, a word and the way to them (HuntsBook.lua).
local function huntsLine(skill)
  local open = ns.hunts.list(ns.book().known, skill, ns.hunts.mine())
  if #open == 0 then return end
  page:paragraph(
    K.plural(
      #open,
      "%d hunt is open at your skill: a recipe to find rather than buy.",
      "%d hunts are open at your skill: recipes to find rather than buy."
    ):format(#open),
    T.soft
  )
  page:chips({ { L["See the hunts"], ns.openHunts } })
end

local function showRoad()
  local skill = ns.skill()
  local casts, toLearn = 0, 0
  for _, leg in ipairs(legs) do
    if leg.spell then casts = casts + math.ceil(leg.casts - 1e-9) end
    if leg.learn then toLearn = toLearn + 1 end
  end
  page:start(L["The road to 300"], L["From cooking %d"]:format(skill), ui.icon(ui.ICON))
  page:stats({
    { tostring(skill), L["cooking now"] },
    { tostring(toLearn), L["recipes to learn"] },
    { ("~%d"):format(casts), L["casts to 300"] },
  })
  if skill == 0 then
    page:paragraph(
      L["Learn cooking from a cooking trainer, then open your cooking window once: the road follows your skill from there."],
      T.soft
    )
  end
  page:paragraph(
    L["Each step is the surest recipe you know, or one to learn from a trainer or a vendor of your side. Orange always raises your skill, yellow and green less often, so the casts are what it takes on average."],
    T.soft
  )
  page:section(L["The road"])
  for i, leg in ipairs(legs) do
    local open = function()
      current = i
      ns.refresh()
    end
    if leg.train then
      page:card(legTitle(leg), trainLine(leg), ui.icon("Interface\\Icons\\INV_Misc_Book_09"), open)
    elseif leg.learn then
      page:card(
        legTitle(leg),
        L["%d to %d: learn it, then about %d casts"]:format(leg.from, leg.to, math.ceil(leg.casts - 1e-9)),
        ui.dishPicture(leg.spell),
        open
      )
    else
      page:card(
        legTitle(leg),
        L["%d to %d: about %d casts"]:format(leg.from, leg.to, math.ceil(leg.casts - 1e-9)),
        ui.dishPicture(leg.spell),
        open
      )
    end
  end
  if legs.stuck then
    page:section(L["Where the road stops"])
    page:paragraph(
      L["At %d nothing you know or can learn from a trainer or a vendor of your side raises your skill any more."]:format(
        legs.stuck
      ),
      T.soft
    )
    huntsLine(legs.stuck)
  elseif #legs == 0 then
    page:paragraph(L["Nothing left to cook: your skill is as high as it goes."], T.soft)
  else
    huntsLine(skill)
  end
end

-- Where to go: an npc's card (its name, where it stands, what it is there).
local function npcCard(id, what, icon)
  local at = ui.where(id)
  page:card(ui.npcName(id), table.concat(at ~= "" and { what, at } or { what }, "  -  "), ui.icon(icon))
end

-- A stop's page: how its rank is learned, and what it asks.
local function showTrain(leg)
  local r = leg.rank or {}
  page:start(legTitle(leg), L["At cooking %d"]:format(leg.from), ui.icon("Interface\\Icons\\INV_Misc_Book_09"))
  if leg.train == 75 then
    page:paragraph(L["Any cooking trainer teaches cooking, and its first recipes with it."], T.soft)
  else
    page:paragraph(L["Your skill can't go past %d until you learn the next rank."]:format(leg.from), T.soft)
  end
  if r.level or r.skill then
    page:section(L["It asks"])
    if r.level then page:row(L["Level"], tostring(r.level)) end
    if r.skill then page:row(L["Cooking"], tostring(r.skill)) end
  end
  if r.trainers then
    page:section(L["Where to learn it"])
    local trainers = serving(r.trainers)
    for i = 1, math.min(#trainers, 3) do
      npcCard(trainers[i], L["a cooking trainer"], "Interface\\Icons\\INV_Misc_Food_15")
    end
    if #trainers > 3 then
      page:paragraph(
        K.plural(
          #trainers - 3,
          "and %d other cooking trainer of your side",
          "and %d other cooking trainers of your side"
        )
          :format(#trainers - 3),
        T.soft
      )
    end
  end
  if r.items then
    page:section(L["The cookbook"])
    local books = {}
    for _, item in ipairs(r.items) do
      table.insert(books, { item, nil, false, 1 })
    end
    page:items(books)
    for _, seller in ipairs(serving(r.sellers)) do
      npcCard(seller, L["sells it"], "Interface\\Icons\\INV_Misc_Coin_02")
    end
  end
  for _, q in ipairs(r.quests or {}) do
    page:section(L["The quest"])
    local qq = D.quests[q] or {}
    local giver = qq.giver and ui.npcName(qq.giver) or ""
    local title = ui.questName(q) or (giver ~= "" and L["A quest from %s"]:format(giver) or L["A quest"])
    local bits = {}
    if qq.giver then
      local at = ui.where(qq.giver)
      table.insert(bits, at ~= "" and ("%s, %s"):format(giver, at) or giver)
    end
    page:card(title, table.concat(bits, "  -  "), ui.icon("Interface\\GossipFrame\\AvailableQuestIcon"))
  end
end

local function showLeg(leg)
  if leg.train then return showTrain(leg) end
  local d = D.recipes[leg.spell]
  local shopping, casts = ns.road.shopping(leg)
  -- (what the bags still lack of the leg's ingredients, all of them: the
  -- leg's own skill points are its line, from and to)
  local toGet = 0
  for _, it in ipairs(shopping) do
    toGet = toGet + math.max(0, it[2] - ui.have(it[1]))
  end
  page:start(legTitle(leg), L["%d to %d"]:format(leg.from, leg.to), ui.dishPicture(leg.spell))
  page:stats({
    { ("~%d"):format(casts), L["casts"] },
    { tostring(ns.road.cookable(d, ui.have)), L["you can cook now"] },
    { tostring(toGet), L["still to get"] },
  })
  if leg.learn then
    page:section(L["Learn it first"])
    if leg.learn.trainer then
      local trainer = serving(D.ranks and D.ranks[150] and D.ranks[150].trainers)[1]
      if trainer then
        npcCard(trainer, L["a cooking trainer"], "Interface\\Icons\\INV_Misc_Food_15")
      else
        page:paragraph(L["From a cooking trainer"], T.soft)
      end
    elseif leg.learn.vendor then
      npcCard(leg.learn.vendor, L["sells the recipe"], "Interface\\Icons\\INV_Misc_Coin_02")
    end
  end
  page:section(L["What it takes"])
  local items = {}
  for _, it in ipairs(shopping) do
    local item, n = it[1], it[2]
    local missing = math.max(0, n - ui.have(item))
    table.insert(items, {
      item,
      nil,
      false,
      n,
      function(tip)
        tip:AddLine(L["In your bags: %d"]:format(ui.have(item)), 1, 1, 1)
        if missing > 0 then tip:AddLine(L["Still to get: %d"]:format(missing), 1, 0.82, 0) end
        ns.pantry.addSources(tip, item)
      end,
    })
  end
  page:items(items)
  -- (where each comes from: the easiest way, the item's tooltip every way)
  page:section(L["Where to get them"])
  for _, it in ipairs(shopping) do
    local item = it[1]
    page:card(
      K.itemName(item, ""),
      ns.pantry.easiest(ns.pantry.sources(item)),
      function(p) p.tex:SetTexture(K.itemIcon(item)) end
    )
  end
  page:section(L["Skill"])
  page:row(L["Colours"], ui.thresholds(d))
  -- (a recipe still to learn has no page in the book yet)
  if ns.knows(leg.spell) then page:chips({ { L["Open its recipe"], function() ns.openDish(leg.spell) end } }) end
end

local function refresh()
  legs = plan()
  if current and not legs[current] then current = nil end
  local skill = ns.skill()
  book.count:SetText(L["Cooking %d"]:format(skill))
  refreshList()
  if current then
    showLeg(legs[current])
  else
    showRoad()
  end
  page:finish()
end

ns.addTab(ns.TAB.road, {
  build = function(b)
    book = b
    list = ui.newList(book.left, style, rows, true)
    page = ui.newPage(book.sheet, "MealbookRoadPage")
  end,
  show = function(n)
    local here = n == ns.TAB.road
    list:SetShown(here)
    page:SetShown(here)
  end,
  refresh = refresh,
})

-- Open the road at one of its legs (its index on the left).
function ns.openRoadLeg(i)
  current = i
  ns.openTab(ns.TAB.road)
end
