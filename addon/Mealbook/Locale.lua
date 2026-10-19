-- The reader's language. The client loads its own Text_<locale>.lua next (the
-- TOCs name Text_[TextLocale].lua; scripts/locales.ts writes them from
-- i18n/), which hands its words to ns.translate: English stays wherever it
-- says nothing. The dishes' and ingredients' names are the game's, by their
-- ids, in the client's language: never translated here.
local _, ns = ...
local K = ns.kit

-- (is n the "one" form? English, German, Spanish: 1; French: 0 and 1)
local PLURALS = {
  one = function(n) return n == 1 end,
  fr = function(n) return n == 0 or n == 1 end,
  none = function() return false end,
}

function ns.translate(t)
  for english, word in pairs(t.words or {}) do
    K.L[english] = word
  end
  if t.plural and PLURALS[t.plural] then K.isOne = PLURALS[t.plural] end
end

-- The game this is: Forever's client is a modern one (interface 1.60, 16001).
local build = select(4, GetBuildInfo())
ns.forever = build >= 16000 and build < 17000

-- The game's own names in the reader's language (its Text file, from
-- wow-data's databases): the cooking skill line's, as the client's skill
-- list writes it (Classic Era names a skill only by its name there),
-- Herbalism's (a herb's line), the chefs', and this game's npcs and quests by id (who sells a recipe, drops
-- it, gives it). A quest the language has no title for has none: its page
-- names its giver instead.
function ns.names(t)
  ns.skillName = t.skillLine
  ns.herbName = t.herbalism
  ns.chefNames = t.chefs or {}
  local game = ns.forever and "forever" or "classic"
  ns.npcNames = t.npcs and t.npcs[game] or {}
  ns.questNames = t.quests and t.quests[game] or {}
end
