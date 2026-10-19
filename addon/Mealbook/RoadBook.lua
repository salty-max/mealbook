-- The road tab: from the skill now to 300 (Road.lua), its legs on the left
-- (a recipe from one skill to another, a stop to train), the road on the page
-- (each leg as a card, where it stops and the recipes worth learning there),
-- and a leg's own page: its casts, its colours, its ingredients and how many
-- of each, against the bags.
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

local function plan()
  local char = ns.book()
  local skill, max = ns.skill()
  return ns.road.plan(char and char.known or {}, skill, max, ui.have)
end

local function rankName(cap) return cap <= 150 and L["Journeyman"] or cap <= 225 and L["Expert"] or L["Artisan"] end

local function legTitle(leg)
  if leg.train then return L["Train %s"]:format(rankName(leg.train)) end
  return ns.dishName(leg.spell)
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
    local r = list:add("leg", legTitle(leg), leg.train and "" or ("%d-%d"):format(leg.from, leg.to))
    r:SetScript("OnClick", function()
      current = i
      ns.refresh()
    end)
    if current == i then list:pick(r) end
  end
  list:finish()
end

local function worthCards(skill)
  local mine = ns.hunts.mine()
  local worth = ns.road.worth(ns.book().known, skill, 5, mine)
  if #worth == 0 then return end
  page:section(L["Worth learning now"])
  for _, spell in ipairs(worth) do
    local d = D.recipes[spell]
    local s = ns.hunts.sources(spell, mine)
    local how
    if s.skill or s.trainer then
      how = L["From a cooking trainer"]
    else
      -- (a vendor's, the one where the character stands if one is)
      local v = ui.nearest(s.shop)
      local at = ui.where(v)
      how = at ~= "" and L["Sold by %s, %s"]:format(ui.npcName(v), at) or L["Sold by %s"]:format(ui.npcName(v))
    end
    page:card(
      ns.dishName(spell),
      ("%s  -  %s"):format(ui.colourWord(ns.road.colour(d, skill)), how),
      ui.dishPicture(spell)
    )
  end
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
  local skill, max = ns.skill()
  local casts, steps = 0, 0
  for _, leg in ipairs(legs) do
    if leg.spell then
      casts = casts + math.ceil(leg.casts - 1e-9)
      steps = steps + (leg.to - leg.from)
    end
  end
  page:start(L["The road to 300"], L["From cooking %d"]:format(skill), ui.icon(ui.ICON))
  page:stats({
    { tostring(skill), L["cooking now"] },
    { tostring(steps), L["points on the road"] },
    { tostring(casts), L["casts, about"] },
  })
  if skill == 0 and max == 0 then
    page:paragraph(
      L["Learn cooking from a cooking trainer, then open your cooking window: the road starts from there."],
      T.soft
    )
    worthCards(1)
    return
  end
  page:paragraph(
    L["Each step is the surest recipe you know at that skill. Orange always raises it, yellow and green less often, so the casts are what it takes on average."],
    T.soft
  )
  page:section(L["The road"])
  for i, leg in ipairs(legs) do
    if leg.train then
      page:card(
        L["Train %s"]:format(rankName(leg.train)),
        L["At %d: a cooking trainer opens the next %d points."]:format(leg.from, 75),
        ui.icon("Interface\\Icons\\INV_Misc_Book_09"),
        function()
          current = i
          ns.refresh()
        end
      )
    else
      page:card(
        legTitle(leg),
        L["%d to %d: about %d casts"]:format(leg.from, leg.to, math.ceil(leg.casts - 1e-9)),
        ui.dishPicture(leg.spell),
        function()
          current = i
          ns.refresh()
        end
      )
    end
  end
  if legs.stuck then
    page:section(L["Where the road stops"])
    page:paragraph(
      L["At %d no recipe you know raises your skill any more. Learn one of these to go on."]:format(legs.stuck),
      T.soft
    )
    worthCards(legs.stuck)
    huntsLine(legs.stuck)
  elseif #legs == 0 then
    page:paragraph(L["Nothing left to cook: your skill is as high as it goes."], T.soft)
  else
    worthCards(skill)
    huntsLine(skill)
  end
end

local function showLeg(leg)
  if leg.train then
    page:start(
      L["Train %s"]:format(rankName(leg.train)),
      L["At cooking %d"]:format(leg.from),
      ui.icon("Interface\\Icons\\INV_Misc_Book_09")
    )
    page:paragraph(
      L["Your skill can't go past %d until you train. A cooking trainer teaches the next rank."]:format(leg.from),
      T.soft
    )
    return
  end
  local d = D.recipes[leg.spell]
  local shopping, casts = ns.road.shopping(leg)
  page:start(legTitle(leg), L["%d to %d"]:format(leg.from, leg.to), ui.dishPicture(leg.spell))
  page:stats({
    { tostring(casts), L["casts, about"] },
    { tostring(ns.road.cookable(d, ui.have)), L["you can cook now"] },
    { tostring(leg.to - leg.from), L["points"] },
  })
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
      end,
    })
  end
  page:items(items)
  page:section(L["Skill"])
  page:row(L["Colours"], ui.thresholds(d))
  page:chips({ { L["Open its recipe"], function() ns.openDish(leg.spell) end } })
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
