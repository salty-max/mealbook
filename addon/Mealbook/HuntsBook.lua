-- The Hunts tab: the recipes to find rather than buy (Hunts.lua), open at the
-- character's skill, on the left; the hunts on the page (how many found, the
-- next to open), the auction house's apart (they count for none of it); and
-- a hunt's own page: the recipe and the dish, and where to
-- look, each find as a card: a stall's limited stock (who, where, how many
-- at once), the likeliest creatures to drop it (where, their level, how
-- often), a world drop, a quest (its title where the language has one, else
-- its giver; where, its level); a recipe only the other side gets: the
-- neutral auction houses (an auctioneer a town, the nearest first), and how
-- the other side gets it.
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
  auction = { L["an auction"], "Interface\\Icons\\INV_Misc_Coin_01" },
}
local RARE = { [2] = true, [4] = true } -- (rare elite, rare)

local function style(row, kind)
  if kind == "section" then
    row.text:SetPoint("LEFT", 4, 0)
    row.text:SetPoint("RIGHT", -4, 0)
    row.text:SetFont(ns.kit.TITLE_FONT, 14, "")
    row.text:SetTextColor(unpack(T.gold))
    return 22
  end
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

local function refreshList(open, auction)
  list:begin()
  local row = list:add("overview", L["Hunts"], tostring(#open))
  row:SetScript("OnClick", function()
    current = nil
    ns.refresh()
  end)
  if not current then list:pick(row) end
  local q = ui.query()
  local mine = ns.hunts.mine()
  -- (the side's own, then the auction house's under their heading)
  local function rowsOf(spells, heading)
    local first = true
    for _, spell in ipairs(spells) do
      local name = ns.dishName(spell)
      if ns.kit.finds(name, q) then
        if heading and first then
          list:gap(6)
          list:add("section", heading)
        end
        first = false
        local r = list:add("hunt", name, KINDS[ns.hunts.kind(ns.hunts.of(spell, mine))][1])
        r:SetScript("OnClick", function()
          current = spell
          ns.refresh()
        end)
        if current == spell then list:pick(r) end
      end
    end
  end
  rowsOf(open)
  rowsOf(auction, L["At the auction house"])
  list:finish()
end

-- A find's line: who, where, and what to know.
local function vendorCard(npc)
  local at = ui.where(npc)
  page:card(
    ui.npcName(npc),
    table.concat(at ~= "" and { L["sells it"], at } or { L["sells it"] }, "  -  "),
    ui.icon(KINDS.stall[2])
  )
end

local function stallCard(npc, stock)
  local at = ui.where(npc)
  local bits = { L["%d at a time, restocks slowly"]:format(stock) }
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
  -- (short: the card's line is one, 11 points)
  if percent and percent >= 1 then
    table.insert(bits, L["%d%%"]:format(math.floor(percent + 0.5)))
  elseif percent and percent > 0 then
    table.insert(bits, L["under 1%"])
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

-- (how many a stall holds of the dish's recipe)
local function stockOf(d, npc)
  for _, item in ipairs(d.items or {}) do
    local it = D.recipeItems[item]
    if it and it.limited and it.limited[npc] then return it.limited[npc] end
  end
  return 1
end

-- The neutral auction houses: an auctioneer a town, the nearest first.
local function auctionHouses()
  local out, seen = {}, {}
  for _, id in ipairs(ui.byNearness(D.auctioneers or {})) do
    local area = D.npcs[id] and D.npcs[id].area
    if area and not seen[area] then
      seen[area] = true
      table.insert(out, id)
    end
  end
  return out
end

-- A recipe only the other side gets: where it is traded, and where they
-- find it.
local function showAuction(s, d)
  page:paragraph(
    L["Your side can't get this recipe on its own. The other side can, and may sell it at a neutral auction house, where both sides trade. It counts for no achievement."],
    T.soft
  )
  for _, npc in ipairs(auctionHouses()) do
    local at = ui.where(npc)
    page:card(
      ui.npcName(npc),
      table.concat(at ~= "" and { L["an auctioneer"], at } or { L["an auctioneer"] }, "  -  "),
      ui.icon(KINDS.auction[2])
    )
  end
  page:section(L["How the other side gets it"])
  for _, npc in ipairs(s.other.shop) do
    vendorCard(npc)
  end
  for _, npc in ipairs(s.other.limited) do
    stallCard(npc, stockOf(d, npc))
  end
  for _, q in ipairs(s.other.quests) do
    questCard(q)
  end
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
  if s.auction then return showAuction(s, d) end
  for _, npc in ipairs(s.limited) do
    stallCard(npc, stockOf(d, npc))
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

-- A hunt open now, as a card: its colour, its kind.
local function huntCard(spell, skill, mine)
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

local function showHunts(skill, open, nextAt, found, total, auction)
  page:start(L["Hunts"], L["At cooking %d"]:format(skill), ui.icon(ui.ICON))
  page:stats({
    { tostring(#open), L["open now"] },
    { ("%d / %d"):format(found, total), L["found"] },
    { nextAt and tostring(nextAt) or "-", L["the next opens at"] },
  })
  page:paragraph(
    L["Some recipes no trainer teaches and no shop keeps for long: a stall with one at a time, a creature that drops it, a quest, or one only the other side gets, traded at a neutral auction house. Each opens here when your skill is ready for it."],
    T.soft
  )
  local mine = ns.hunts.mine()
  if #open == 0 then
    page:paragraph(
      nextAt and L["None open at your skill. The next opens at cooking %d."]:format(nextAt)
        or L["None left to find: every hunt of your side is in your book."],
      T.soft
    )
  else
    page:section(L["Open now"])
    for _, spell in ipairs(open) do
      huntCard(spell, skill, mine)
    end
  end
  if #auction > 0 then
    page:section(L["At the auction house"])
    page:paragraph(
      L["Recipes only the other side gets, bought at a neutral auction house. They count for no achievement."],
      T.soft
    )
    for _, spell in ipairs(auction) do
      huntCard(spell, skill, mine)
    end
  end
end

local function refresh()
  local skill, _, open, nextAt, found, total, auction = hunts()
  book.count:SetText(K.plural(#open, "%d hunt open", "%d hunts open"):format(#open))
  if current and (ns.knows(current) or not ns.hunts.of(current, ns.hunts.mine())) then current = nil end
  refreshList(open, auction)
  if current then
    showHunt(current)
  else
    showHunts(skill, open, nextAt, found, total, auction)
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
