-- The pantry: what the ingredients in hand cook into. On an ingredient's
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
