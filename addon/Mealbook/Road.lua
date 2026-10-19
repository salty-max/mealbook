-- The road to 300: from the skill now, what to cook next, how many times, and
-- with what. The game's own rule: a recipe always raises the skill while it
-- is orange (under its yellow), never once grey; between, the chance falls in
-- a straight line, (grey - skill) / (grey - yellow): the colours the cooking
-- window shows (green halfway between yellow and grey).
--
-- The road: for every point from the skill now to the goal, the surest
-- recipe known (then one whose ingredients are in the bags, then the fewest
-- ingredients, then the book's order), consecutive points cooked with one
-- recipe a leg, its casts the sum of one over the chance at each point. At a
-- rank's cap (75, 150, 225), a stop to train the next. Where no recipe known
-- raises the skill any more, the road stops: the recipes worth learning there
-- (R.worth) go on from it.
local _, ns = ...
local D = ns.data
local R = {}
ns.road = R

function R.green(d) return math.floor((d.yellow + d.grey) / 2) end

function R.colour(d, skill)
  if skill < d.learn then return "red" end
  if skill < d.yellow then return "orange" end
  if skill < R.green(d) then return "yellow" end
  if skill < d.grey then return "green" end
  return "grey"
end

function R.chance(d, skill)
  if skill < d.learn or skill >= d.grey then return 0 end
  if skill < d.yellow then return 1 end
  return (d.grey - skill) / (d.grey - d.yellow)
end

-- (how many ingredients a cast takes, all told)
local function weight(d)
  local n = 0
  for i = 2, #d.reagents, 2 do
    n = n + d.reagents[i]
  end
  return n
end

-- How many casts the bags allow (have: an item's count, GetItemCount's).
function R.cookable(d, have)
  local most
  for i = 1, #d.reagents, 2 do
    local can = math.floor((have(d.reagents[i]) or 0) / d.reagents[i + 1])
    most = most and math.min(most, can) or can
  end
  return most or 0
end

-- The rank cap a skill is under, and the next (75, 150, 225, 300).
local function capOf(max)
  for _, cap in ipairs(ns.RANKS) do
    if (max or 75) <= cap then return cap end
  end
  return 300
end

-- The surest recipe of these at this skill.
local function best(known, skill, have)
  local pick, pickChance, pickCan
  for _, spell in ipairs(D.order) do
    local d = known[spell] and D.recipes[spell]
    if d then
      local c = R.chance(d, skill)
      if c > 0 then
        local can = have and R.cookable(d, have) > 0 or false
        local better = not pick
          or c > pickChance + 1e-9
          or (
            math.abs(c - pickChance) < 1e-9
            and (can and not pickCan or can == pickCan and weight(d) < weight(D.recipes[pick]))
          )
        if better then
          pick, pickChance, pickCan = spell, c, can
        end
      end
    end
  end
  return pick, pickChance
end

-- The road from skill to goal (300 unless said): its legs, each { spell, from,
-- to, casts } or { train = the next cap }, and stuck, the skill where no
-- recipe known goes further.
function R.plan(known, skill, max, have, goal)
  goal = goal or 300
  local legs, s, cap = {}, skill, capOf(max)
  while s < goal do
    if s >= cap then
      if cap >= 300 then break end
      table.insert(legs, { train = cap + 75, from = s })
      cap = cap + 75
    end
    local spell, chance = best(known, s, have)
    if not spell then
      legs.stuck = s
      break
    end
    local leg = legs[#legs]
    if leg and leg.spell == spell then
      leg.to, leg.casts = s + 1, leg.casts + 1 / chance
    else
      table.insert(legs, { spell = spell, from = s, to = s + 1, casts = 1 / chance })
    end
    s = s + 1
  end
  return legs
end

-- A leg's ingredients: every item and how many, its casts rounded up.
function R.shopping(leg)
  local d = D.recipes[leg.spell]
  local casts = math.ceil(leg.casts - 1e-9)
  local out = {}
  for i = 1, #d.reagents, 2 do
    table.insert(out, { d.reagents[i], d.reagents[i + 1] * casts })
  end
  return out, casts
end

-- The recipes worth learning at this skill: not known, learnable now (the
-- skill they ask), still raising it, from the shop (a trainer, the skill
-- itself, a vendor who sells it to the character's side without a limit:
-- the rest are hunts, Hunts.lua), the surest first.
function R.worth(known, skill, limit, mine)
  local out = {}
  for _, spell in ipairs(D.order) do
    local d = D.recipes[spell]
    if not known[spell] and not d.unknown and skill >= d.learn and R.chance(d, skill) > 0 then
      local s = ns.hunts.sources(spell, mine)
      if s.skill or s.trainer or #s.shop > 0 then table.insert(out, spell) end
    end
  end
  table.sort(out, function(a, b)
    local ca, cb = R.chance(D.recipes[a], skill), R.chance(D.recipes[b], skill)
    if math.abs(ca - cb) > 1e-9 then return ca > cb end
    return D.recipes[a].yellow > D.recipes[b].yellow
  end)
  if limit then
    for i = #out, limit + 1, -1 do
      out[i] = nil
    end
  end
  return out
end
