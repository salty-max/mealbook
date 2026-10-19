-- The pantry: what the ingredients in hand cook into, and where they come
-- from (P.sources: the road's legs and the dishes' pages). On an ingredient's
-- tooltip, a line naming the dishes the character knows that use it, each in
-- its colour now, the surest first (`/mealbook tooltips` and the Options
-- page turn it off); and
-- for the Recipes tab's front page, the dishes the bags can cook now and how
-- many times.
local _, ns = ...
local L, D = ns.kit.L, ns.data
local P = {}
ns.pantry = P

-- (an ingredient's item: the dishes that use it, every one of this game's)
local uses = {}
for _, spell in ipairs(D.order) do
  local d = D.recipes[spell]
  for i = 1, #d.reagents, 2 do
    local item = d.reagents[i]
    uses[item] = uses[item] or {}
    table.insert(uses[item], spell)
  end
end
P.uses = uses

local function surest(skill)
  return function(a, b)
    local ca, cb = ns.road.chance(D.recipes[a], skill), ns.road.chance(D.recipes[b], skill)
    if math.abs(ca - cb) > 1e-9 then return ca > cb end
    return D.recipes[a].yellow > D.recipes[b].yellow
  end
end

-- The known dishes an item cooks into, the surest at this skill first.
function P.dishes(item, known, skill)
  local out = {}
  for _, spell in ipairs(uses[item] or {}) do
    if known[spell] then table.insert(out, spell) end
  end
  table.sort(out, surest(skill))
  return out
end

-- The known dishes the bags can cook now: { spell, casts }, those that still
-- raise the skill first, then the most casts.
function P.cookable(known, skill, have)
  local out = {}
  for spell in pairs(known) do
    local d = D.recipes[spell]
    if d then
      local n = ns.road.cookable(d, have)
      if n > 0 then table.insert(out, { spell, n }) end
    end
  end
  table.sort(out, function(a, b)
    local ca, cb = ns.road.chance(D.recipes[a[1]], skill), ns.road.chance(D.recipes[b[1]], skill)
    if (ca > 0) ~= (cb > 0) then return ca > 0 end
    if math.abs(ca - cb) > 1e-9 then return ca > cb end
    if a[2] ~= b[2] then return a[2] > b[2] end
    return a[1] < b[1]
  end)
  return out
end

-- An ingredient's line: "Cooks into Crocolisk Steak, Crocolisk Gumbo" (three
-- at most, then how many more); none for an item no known dish uses.
local SHOWN = 3
function P.line(item)
  local char = ns.book()
  if not (char and item and uses[item]) then return nil end
  local skill = ns.skill()
  local dishes = P.dishes(item, char.known, skill)
  if #dishes == 0 then return nil end
  local names = {}
  for i = 1, math.min(#dishes, SHOWN) do
    local spell = dishes[i]
    names[i] = ns.ui.colourCode(ns.road.colour(D.recipes[spell], skill)) .. ns.dishName(spell) .. "|r"
  end
  local text = table.concat(names, ", ")
  if #dishes > SHOWN then text = text .. " " .. L["and %d more"]:format(#dishes - SHOWN) end
  return L["Cooks into %s"]:format(text)
end

-- ── where an ingredient comes from ───────────────────────────────────────────
-- (Recipes_<game>'s ingredients: who sells it, the likeliest droppers, where
-- it is fished, the Herbalism its nodes ask and where they grow), for the
-- character: the sellers of its side, the creatures it may hunt (none of
-- its own side's, half the likeliest one's chance at least), the zones the
-- nearest first (between equals the data's order: the likeliest).
function P.sources(item)
  local ing = D.ingredients and D.ingredients[item]
  if not ing then return nil end
  local mine, ui = ns.hunts.mine(), ns.ui
  local sellers = {}
  for _, v in ipairs(ing.sold or {}) do
    local n = D.npcs[v]
    if n and ns.hunts.serves(n.side, mine) then table.insert(sellers, v) end
  end
  local hunted, best = {}, 0
  for i = 1, #(ing.drops or {}), 2 do
    local n = D.npcs[ing.drops[i]]
    if n and n.side ~= mine then
      table.insert(hunted, { ing.drops[i], ing.drops[i + 1] })
      best = math.max(best, ing.drops[i + 1])
    end
  end
  local drops = {}
  for _, d in ipairs(hunted) do
    if d[2] >= best / 2 then table.insert(drops, d) end
  end
  return {
    sellers = ui.byNearness(sellers),
    drops = ui.zonesByNearness(drops, function(d) return D.npcs[d[1]].area end),
    fished = ui.zonesByNearness(ing.fished),
    herb = ing.herb,
    herbZones = ui.zonesByNearness(ing.herbZones),
    inside = ing.inside or {},
    picked = ui.zonesByNearness(ing.picked),
    best = best,
    fishing = ing.fishing,
    -- (sold, but by the other side's vendors only)
    otherSide = #sellers == 0 and #(ing.sold or {}) > 0 or nil,
  }
end

local function joined(list, n, f)
  local out = {}
  for i = 1, math.min(#list, n) do
    local v = f(list[i])
    if v and v ~= "" then table.insert(out, v) end
  end
  return table.concat(out, ", ")
end

-- The easiest way to it, one short line (a card's): a seller of the side,
-- else where it is fished, else the herb's (a fish or a herb some creature
-- carries now and then), else the nearest creature, a container or a chest
-- of the world before creatures that drop it less than one time in ten (a
-- clam's meat), else caught fishing, else the other side's goods.
function P.easiest(src)
  local ui = ns.ui
  if not src then return L["no source known yet"] end
  if src.sellers[1] then
    local v, at = src.sellers[1], ui.where(src.sellers[1])
    return at ~= "" and L["sold by %s, %s"]:format(ui.npcName(v), at) or L["sold by %s"]:format(ui.npcName(v))
  end
  if src.fished[1] then return L["fished in %s"]:format(joined(src.fished, 2, ui.zoneName)) end
  if src.herb then
    local where = joined(src.herbZones, 1, ui.zoneName)
    return where ~= "" and L["%s %d, %s"]:format(ns.herbName, src.herb, where)
      or L["%s %d"]:format(ns.herbName, src.herb)
  end
  if not src.drops[1] or src.best < 10 then
    if src.inside[1] then
      return L["found in %s"]:format(joined(src.inside, 2, function(i) return ns.kit.itemName(i, "") end))
    end
    if src.picked[1] then return L["picked up in %s"]:format(joined(src.picked, 2, ui.zoneName)) end
  end
  if src.drops[1] then
    -- (its zone, no spot: a creature roams)
    local c = src.drops[1][1]
    local at = ui.zoneName(D.npcs[c].area)
    return at and L["drops from %s, %s"]:format(ui.npcName(c), at) or L["drops from %s"]:format(ui.npcName(c))
  end
  if src.fishing then return L["caught fishing"] end
  if src.otherSide then return L["sold only to the other side"] end
  return L["no source known yet"]
end

-- Every way to it, on its tooltip.
function P.addSources(tip, item)
  local src, ui = P.sources(item), ns.ui
  if not src then return end
  local function line(text) tip:AddLine(text, 0.95, 0.68, 0.38, true) end
  if src.sellers[1] then
    line(L["Sold by %s"]:format(joined(src.sellers, 2, function(v)
      local at = ui.where(v)
      return at ~= "" and ("%s (%s)"):format(ui.npcName(v), at) or ui.npcName(v)
    end)))
  end
  if src.drops[1] then
    line(L["Drops from %s"]:format(joined(src.drops, 3, function(d)
      local n, bits = D.npcs[d[1]] or {}, {}
      local zone = ui.zoneName(n.area)
      if zone then table.insert(bits, zone) end
      if n.lvl then
        table.insert(bits, n.lvl[1] == n.lvl[2] and tostring(n.lvl[1]) or ("%d-%d"):format(n.lvl[1], n.lvl[2]))
      end
      if d[2] and d[2] >= 1 then
        table.insert(bits, L["%d%%"]:format(math.floor(d[2] + 0.5)))
      elseif d[2] and d[2] > 0 then
        table.insert(bits, "<" .. L["%d%%"]:format(1))
      end
      return #bits > 0 and ("%s (%s)"):format(ui.npcName(d[1]), table.concat(bits, ", ")) or ui.npcName(d[1])
    end)))
  end
  if src.fished[1] then line(L["Fished in %s"]:format(joined(src.fished, 3, ui.zoneName))) end
  if src.fishing then line(L["Caught fishing"]) end
  if src.herb then
    local where = joined(src.herbZones, 3, ui.zoneName)
    line(
      where ~= "" and L["%s %d: %s"]:format(ns.herbName, src.herb, where) or L["%s %d"]:format(ns.herbName, src.herb)
    )
  end
  if src.inside[1] then
    line(L["Found in %s"]:format(joined(src.inside, 2, function(i) return ns.kit.itemName(i, "") end)))
  end
  if src.picked[1] then line(L["Picked up in %s"]:format(joined(src.picked, 3, ui.zoneName))) end
  if src.otherSide then line(L["Sold only to the other side"]) end
end

local function addLine(tip, item)
  if ns.option and not ns.option("tooltips") then return end
  if ns.secret(item) then return end
  local line = P.line(item)
  if line then tip:AddLine(line, 0.95, 0.68, 0.38, true) end
end

-- The game's tooltips: the modern client's post-call for every item tooltip,
-- else the item tooltips' own hook (the game's and a chat link's).
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
  TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tip, data)
    if data then addLine(tip, data.id) end
  end)
else
  local function onItem(tip)
    local _, link = tip:GetItem()
    local item = link and tonumber(link:match("item:(%d+)"))
    if item then addLine(tip, item) end
  end
  for _, tip in ipairs({ GameTooltip, ItemRefTooltip }) do
    if tip and tip.HookScript then tip:HookScript("OnTooltipSetItem", onItem) end
  end
end
