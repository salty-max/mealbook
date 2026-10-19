-- The hunts: recipes that are finds, as Yonder's quarries are. A recipe's
-- sources for the character's side, split in two: the shop (a trainer, the
-- skill itself, a vendor who sells it to that side without a limit: the
-- road's, Road.lua) and the finds (a vendor's limited stock, a creature that
-- drops it, a world drop, a quest of that side's). A dish is a hunt when it
-- isn't known, the character cooks at the skill it is learned at, no shop
-- has it for them and a find does. Never a list of everything: a hunt opens
-- with the skill.
local _, ns = ...
local D = ns.data
local H = {}
ns.hunts = H

-- The side the character cooks for: "A", "H" (none: neither, a test client).
function H.mine()
  local f = UnitFactionGroup and UnitFactionGroup("player")
  return f == "Horde" and "H" or f == "Alliance" and "A" or nil
end

-- Does someone of that side serve this character? (none: either side)
function H.serves(side, mine) return side == nil or mine == nil or side == mine end

local function npc(id) return D.npcs and D.npcs[id] end
local function has(list, v)
  for _, x in ipairs(list) do
    if x == v then return true end
  end
  return false
end
local function quest(id) return D.quests and D.quests[id] end

-- A dish's sources for a side: shop (vendors selling freely), limited
-- (vendors with a stock), drops ({ npc, percent }), world (a drop of many),
-- quests; skill and trainer as the dish says.
function H.sources(spell, mine)
  local d = D.recipes[spell]
  local out = { shop = {}, limited = {}, drops = {}, quests = {} }
  if not d then return out end
  out.skill, out.trainer = d.skill, d.trainer
  local function addQuest(q)
    local qq = quest(q)
    if H.serves(qq and qq.side, mine) and not has(out.quests, q) then table.insert(out.quests, q) end
  end
  for _, q in ipairs(d.quests or {}) do
    addQuest(q)
  end
  for _, item in ipairs(d.items or {}) do
    local it = D.recipeItems[item]
    if it then
      out.item = out.item or item
      for _, v in ipairs(it.sold or {}) do
        local n = npc(v)
        if H.serves(n and n.side, mine) then
          table.insert((it.limited and it.limited[v]) and out.limited or out.shop, v)
        end
      end
      local drops = it.drops or {}
      for i = 1, #drops, 2 do
        table.insert(out.drops, { drops[i], drops[i + 1] })
      end
      if it.world then out.world = true end
      for _, q in ipairs(it.quests or {}) do
        addQuest(q)
      end
    end
  end
  return out
end

-- Is it a hunt for this side, whatever the skill? Its sources if so.
function H.of(spell, mine)
  local d = D.recipes[spell]
  if not d or d.unknown then return nil end
  local s = H.sources(spell, mine)
  if s.skill or s.trainer or #s.shop > 0 then return nil end
  if #s.limited == 0 and #s.drops == 0 and #s.quests == 0 and not s.world then return nil end
  return s
end

-- The hunts open at this skill: not known, learned at or below it. Those
-- that still raise the skill first (the surest first), then the rest, the
-- latest opened first. Also the skill the next one opens at, and how many
-- hunts the character has found (known) of all this side's.
function H.list(known, skill, mine)
  local open, nextAt, found, total = {}, nil, 0, 0
  for _, spell in ipairs(D.order) do
    if H.of(spell, mine) then
      local d = D.recipes[spell]
      total = total + 1
      if known[spell] then
        found = found + 1
      elseif d.learn <= skill then
        table.insert(open, spell)
      elseif not nextAt or d.learn < nextAt then
        nextAt = d.learn
      end
    end
  end
  local road = ns.road
  table.sort(open, function(a, b)
    local da, db = D.recipes[a], D.recipes[b]
    local ca, cb = road.chance(da, skill), road.chance(db, skill)
    if (ca > 0) ~= (cb > 0) then return ca > 0 end
    if ca > 0 and math.abs(ca - cb) > 1e-9 then return ca > cb end
    if da.learn ~= db.learn then return da.learn > db.learn end
    return a < b
  end)
  return open, nextAt, found, total
end

-- A hunt's kind, for its row: the first find it has (a stall's stock, a
-- drop, a quest).
function H.kind(s)
  if #s.limited > 0 then return "stall" end
  if #s.drops > 0 or s.world then return "drop" end
  return "quest"
end
