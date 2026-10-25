-- The reader's language. The client loads its own Text_<locale>.lua next (the
-- TOCs name Text_[TextLocale].lua; scripts/locales.ts writes them from
-- i18n/), which hands its words to ns.translate: English stays wherever it
-- says nothing. The dishes' and ingredients' names are the game's, by their
-- ids, in the client's language: never translated here.
local _, ns = ...
local K = ns.kit

-- (the kit's: the language's plural rule, every word through it; which game
-- this is the kit says too, ns.forever)
function ns.translate(t) K.translate(t) end

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
