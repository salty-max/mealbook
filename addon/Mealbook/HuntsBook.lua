-- The Hunts tab: the recipes to find rather than buy (Hunts.lua), open at the
-- character's skill, on the left; the hunts on the page (how many found, the
-- next to open); and a hunt's own page: the recipe and the dish, and where to
-- look, each find as a card: a stall's limited stock (who, where, how many
-- at once), the likeliest creatures to drop it (where, their level, how
-- often), a world drop, a quest (its title where the language has one, else
-- its giver; where, its level).
local _, ns = ...
local K, L, D, ui = ns.kit, ns.kit.L, ns.data, ns.ui
local T = ui.T
local book, list, page
local current -- (a hunt's spell, else the hunts)
local rows = {}

local KINDS = {
  stall = { L["a stall"], "Interface\\Icons\\INV_Misc_Coin_02" },
  drop = { L["a drop"], "Interface\\Icons\\INV_Misc_Bag_10_Blue" },
  quest = { L["a quest"], "Interface\\GossipFrame\\AvailableQuestIcon" },
}
local RARE = { [2] = true, [4] = true } -- (rare elite, rare)

local function style(row, kind)
  row.count:SetPoint("RIGHT", -4, 0)
  row.text:SetPoint("LEFT", kind == "overview" and 4 or 14, 0)
  row.text:SetPoint("RIGHT", row.count, "LEFT", -4, 0)
  row.text:SetFont(ns.kit.BODY_FONT, 12, "")
  row.text:SetTextColor(unpack(kind == "overview" and T.gold or T.text))
  row.count:SetTextColor(unpack(T.soft))
  return 18
end

local function hunts()
  local skill = ns.skill()
  return skill, ns.hunts.mine(), ns.hunts.list(ns.book().known, skill, ns.hunts.mine())
end

local function refreshList(open)
  list:begin()
  local row = list:add("overview", L["Hunts"], tostring(#open))
  row:SetScript("OnClick", function()
    current = nil
    ns.refresh()
  end)
  if not current then list:pick(row) end
  local q = ui.query()
  local mine = ns.hunts.mine()
  for _, spell in ipairs(open) do
    local name = ns.dishName(spell)
    if q == "" or name:lower():find(q, 1, true) then
      local r = list:add("hunt", name, KINDS[ns.hunts.kind(ns.hunts.of(spell, mine))][1])
      r:SetScript("OnClick", function()
        current = spell
        ns.refresh()
      end)
      if current == spell then list:pick(r) end
    end
  end
  list:finish()
end

-- A find's line: who, where, and what to know.
local function stallCard(npc, stock)
  local at = ui.where(npc)
  local bits = { L["sells %d at a time, then waits to restock"]:format(stock) }
  if at ~= "" then table.insert(bits, 1, at) end
  page:card(ui.npcName(npc), table.concat(bits, "  -  "), ui.icon(KINDS.stall[2]))
end

local function dropCard(npc, percent)
  local n = D.npcs[npc] or {}
  local bits = { ui.where(npc) }
  if n.lvl then
    table.insert(
      bits,
      n.lvl[1] == n.lvl[2] and L["level %d"]:format(n.lvl[1]) or L["level %d-%d"]:format(n.lvl[1], n.lvl[2])
    )
  end
  if RARE[n.rank] then table.insert(bits, L["rare"]) end
  if percent and percent >= 1 then
    table.insert(bits, L["%d%% of the time"]:format(math.floor(percent + 0.5)))
  elseif percent and percent > 0 then
    table.insert(bits, L["under 1% of the time"])
  end
  local shown = {}
  for _, b in ipairs(bits) do
    if b ~= "" then table.insert(shown, b) end
  end
  page:card(ui.npcName(npc), table.concat(shown, "  -  "), ui.icon(KINDS.drop[2]))
end

local function questCard(id)
  local qq = D.quests[id] or {}
  local title = ui.questName(id)
  local giver = qq.giver and ui.npcName(qq.giver) or ""
  local bits = {}
  if title and giver ~= "" then table.insert(bits, L["from %s"]:format(giver)) end
  local zone = ui.zoneName(qq.area)
  if zone then table.insert(bits, zone) end
  if qq.min then table.insert(bits, L["from level %d"]:format(qq.min)) end
  page:card(
    title or (giver ~= "" and L["A quest from %s"]:format(giver) or L["A quest"]),
    table.concat(bits, "  -  "),
    ui.icon(KINDS.quest[2])
  )
end

local function showHunt(spell)
  local mine = ns.hunts.mine()
  local s = ns.hunts.of(spell, mine)
  local d = D.recipes[spell]
  local skill = ns.skill()
  page:start(
    ns.dishName(spell),
    table.concat({ L["A hunt"], ui.colourWord(ns.road.colour(d, skill)) }, "  -  "),
    ui.dishPicture(spell)
  )
  page:section(L["The recipe"])
  local items = {}
  if s.item then table.insert(items, { s.item, nil, false, 1 }) end
  table.insert(items, { d.item, nil, false, d.made[1] })
  page:items(items)
  page:row(L["Learned at"], L["cooking %d"]:format(d.learn))
  page:row(L["Colours"], ui.thresholds(d))
  page:section(L["Where to look"])
  for _, npc in ipairs(s.limited) do
    local stock
    for _, item in ipairs(d.items or {}) do
      local it = D.recipeItems[item]
      stock = stock or (it and it.limited and it.limited[npc])
    end
    stallCard(npc, stock or 1)
  end
  for _, q in ipairs(s.quests) do
    questCard(q)
  end
  for _, drop in ipairs(s.drops) do
    dropCard(drop[1], drop[2])
  end
  if s.world then page:paragraph(L["Also a world drop: any creature around its level may carry it."], T.soft) end
  if #s.limited > 0 then
    page:paragraph(L["A stall holds only a few and restocks slowly: if it's gone, come back later."], T.soft)
  end
end

local function showHunts(skill, open, nextAt, found, total)
  page:start(L["Hunts"], L["At cooking %d"]:format(skill), ui.icon(ui.ICON))
  page:stats({
    { tostring(#open), L["open now"] },
    { ("%d / %d"):format(found, total), L["found"] },
    { nextAt and tostring(nextAt) or "-", L["the next opens at"] },
  })
  page:paragraph(
    L["Some recipes no trainer teaches and no shop keeps for long: a stall with one at a time, a creature that drops it, a quest. Each opens here when your skill is ready for it."],
    T.soft
  )
  if #open == 0 then
    page:paragraph(
      nextAt and L["None open at your skill. The next opens at cooking %d."]:format(nextAt)
        or L["None left to find: every hunt of your side is in your book."],
      T.soft
    )
    return
  end
  page:section(L["Open now"])
  local mine = ns.hunts.mine()
  for _, spell in ipairs(open) do
    local kind = KINDS[ns.hunts.kind(ns.hunts.of(spell, mine))]
    page:card(
      ns.dishName(spell),
      table.concat({ ui.colourWord(ns.road.colour(D.recipes[spell], skill)), kind[1] }, "  -  "),
      ui.dishPicture(spell),
      function()
        current = spell
        ns.refresh()
      end
    )
  end
end

local function refresh()
  local skill, _, open, nextAt, found, total = hunts()
  book.count:SetText(K.plural(#open, "%d hunt open", "%d hunts open"):format(#open))
  if current and (ns.knows(current) or not ns.hunts.of(current, ns.hunts.mine())) then current = nil end
  refreshList(open)
  if current then
    showHunt(current)
  else
    showHunts(skill, open, nextAt, found, total)
  end
  page:finish()
end

ns.addTab(ns.TAB.hunts, {
  build = function(b)
    book = b
    list = ui.newList(book.left, style, rows, true)
    page = ui.newPage(book.sheet, "MealbookHuntsPage")
  end,
  show = function(n)
    local here = n == ns.TAB.hunts
    list:SetShown(here)
    page:SetShown(here)
  end,
  refresh = refresh,
})

function ns.openHunt(spell)
  current = spell
  ns.openTab(ns.TAB.hunts)
end
