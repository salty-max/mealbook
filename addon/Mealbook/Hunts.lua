-- The hunts: recipes that are finds, as Yonder's quarries are. A recipe's
-- sources for the character's side, split in two: the shop (a trainer, the
-- skill itself, a vendor who sells it to that side without a limit: the
-- road's, Road.lua) and the finds (a vendor's limited stock, a creature that
-- drops it, a world drop, a quest of that side's). A dish is a hunt when it
-- isn't known, the character cooks at the skill it is learned at, no shop
-- has it for them and a find does, or only the other side gets it and trades
-- it at a neutral auction house (a recipe that binds when picked up never).
-- Never a list of everything: a hunt opens with the skill. The other side's
-- recipes count for nothing but their auction hunts: not the achievements,
-- not the hunts' own figures.
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

-- The other side.
function H.other(mine) return mine == "A" and "H" or "A" end

local function npc(id) return D.npcs and D.npcs[id] end
local function has(list, v)
  for _, x in ipairs(list) do
    if x == v then return true end
  end
  return false
end
local function quest(id) return D.quests and D.quests[id] end

-- The answers below come from the game's data alone (Recipes_<game>.lua,
-- never changed after the load), so each is built once a side and kept: a
-- dish cast checks every achievement, which asks them of every dish. Shared,
-- so read only.
local NONE = {} -- (a side's key where there's no side: a test client)
local function memo(build)
  local bySide = {}
  return function(spell, mine)
    local key = mine or NONE
    local cache = bySide[key]
    if not cache then
      cache = {}
      bySide[key] = cache
    end
    local hit = cache[spell]
    if hit == nil then
      -- (n: as many answers as the build gave, a nil "no" one too)
      hit = { n = 0 }
      local function keep(...)
        hit.n = math.max(1, select("#", ...))
        for i = 1, hit.n do
          hit[i] = (select(i, ...))
        end
      end
      keep(build(spell, mine))
      cache[spell] = hit
    end
    return unpack(hit, 1, hit.n)
  end
end

-- A dish's sources for a side: shop (vendors selling freely), limited
-- (vendors with a stock), drops ({ npc, percent }), world (a drop of many),
-- quests; skill and trainer as the dish says.
local function sources(spell, mine)
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
H.sources = memo(sources)

-- A recipe item of the dish someone can trade (none: each binds when picked up).
local function traded(d)
  for _, item in ipairs(d.items or {}) do
    local it = D.recipeItems[item]
    if it and not it.bound then return item end
  end
end

local function finds(s) return #s.limited > 0 or #s.drops > 0 or #s.quests > 0 or s.world end

-- Does only the other side get it: none of this side's, a vendor, a stall or
-- a quest of theirs (a drop and a world drop are either side's)? This side's
-- sources and theirs if so (none: a test client, of neither side).
local function theirs(spell, mine)
  local d = D.recipes[spell]
  if not d or d.unknown or not mine then return nil end
  local s = H.sources(spell, mine)
  if s.skill or s.trainer or #s.shop > 0 or finds(s) then return nil end
  local o = H.sources(spell, H.other(mine))
  if #o.shop == 0 and #o.limited == 0 and #o.quests == 0 then return nil end
  return s, o
end
H.theirs = memo(theirs)

-- Is it a hunt for this side, whatever the skill? Its sources if so: a find
-- of its own, else (auction) a recipe only the other side gets (other: their
-- sources) and trades (item), where the game has a neutral auction house.
local function of(spell, mine)
  local d = D.recipes[spell]
  if not d or d.unknown then return nil end
  local s = H.sources(spell, mine)
  if s.skill or s.trainer or #s.shop > 0 then return nil end
  if finds(s) then return s end
  local _, o = H.theirs(spell, mine)
  local item = o and #(D.auctioneers or {}) > 0 and traded(d)
  if not item then return nil end
  -- (a copy: the sources stay as they are, shared)
  local hunt = {}
  for k, v in pairs(s) do
    hunt[k] = v
  end
  hunt.auction, hunt.other, hunt.item = true, o, item
  return hunt
end
H.of = memo(of)

-- The hunts open at this skill: not known, learned at or below it, the
-- side's own (open) and the auction house's apart (auction), each those that
-- still raise the skill first (the surest first), then the rest, the latest
-- opened first. Also the skill the next of the side's own opens at, and how
-- many of them the character has found (known) of all: the auction house's
-- count for none of these.
function H.list(known, skill, mine)
  local open, auction, nextAt, found, total = {}, {}, nil, 0, 0
  for _, spell in ipairs(D.order) do
    local s = H.of(spell, mine)
    if s then
      local d = D.recipes[spell]
      if s.auction then
        if not known[spell] and d.learn <= skill then table.insert(auction, spell) end
      else
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
  end
  local road = ns.road
  local function surest(a, b)
    local da, db = D.recipes[a], D.recipes[b]
    local ca, cb = road.chance(da, skill), road.chance(db, skill)
    if (ca > 0) ~= (cb > 0) then return ca > 0 end
    if ca > 0 and math.abs(ca - cb) > 1e-9 then return ca > cb end
    if da.learn ~= db.learn then return da.learn > db.learn end
    return a < b
  end
  table.sort(open, surest)
  table.sort(auction, surest)
  return open, nextAt, found, total, auction
end

-- A hunt's kind, for its row: the first find it has (a stall's stock, a
-- drop, a quest), else the auction house.
function H.kind(s)
  if s.auction then return "auction" end
  if #s.limited > 0 then return "stall" end
  if #s.drops > 0 or s.world then return "drop" end
  return "quest"
end
