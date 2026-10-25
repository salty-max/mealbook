# Mealbook's data and pages

Where the recipes come from and how the chefs' pages are kept (moved from
CLAUDE.md on 20 October 2026). The voices the pages follow:
`../ideas/cookbook-voices.md`; the plan: `../ideas/cookbook.md`.

## The recipes (`scripts/recipes.ts`)

- `scripts/recipes.ts`: the recipes from wow-data's databases, each game's
  own (`--check` in `bun run check`): every dish of the cooking skill line
  (185, a spell that creates an item), what it makes and how many (Classic
  Era's client a base and a die, Forever's the number), its ingredients and
  counts, the skill it is learned at (the lowest of its sources', a quest's
  own skill from wow-data's `quest.skill_value`), yellow and grey (the
  client's trivial ranks; green is halfway, as the game's window shows), its
  chapter (`data/chapters.json`, by hand: the script refuses a dish without
  one), how it is learned, each recipe item's sources (who sells it and a
  limited stock, who drops it, read back from the Classic database's loot
  templates, a world drop said as one, the quests; `bound` when it binds
  when picked up or is a quest's, the client's ItemSparse Bonding 1 or 4:
  never traded, no auction hunt). `auctioneers`: the neutral auction
  houses', where a recipe only the other side gets is traded (an
  auctioneer, npc flag 4096, who sells nothing, Questie flagging a smith in
  Searing Gorge one too, serving neither side, placed, named in every
  language: Booty Bay's, Gadgetzan's and Everlook's in both games, their
  `npcs` rows too). Classic Era leaves out
  a dish its world can't teach (Season of Discovery's, the Crystal Throat
  Lozenge): 81 dishes. Forever keeps its own whose recipe no source has seen
  yet (`unknown`, 29 on 20 October 2026, before launch): a page when learned, never on the road.
  Who and where, for the road's vendors and the hunts: `npcs` (every seller
  of a recipe, the three likeliest droppers of each, the quest givers: the
  side it serves, from its faction template's enemies (Alliance 469, Horde
  67, or the groups), else Questie's word for it (wow-data's
  `creature.friendly`: Forever's new vendors have no template), one
  friendly to all standing in a capital its city's; a seller with neither
  left out, no one sent to it;
  its zone, the AreaTable id where most of its spawns are (an id of
  Questie's own for an instance, 10026 Dire Maul: the instance map's one
  area), its name the client's; a spot there, 0-100, none in an instance;
  its levels and rank) and `quests` (giver, side from the race mask, the
  bits' sides the client's ChrRaces as BigInts (Forever's Skyborne on bits
  32 and 33), else the giver's, level, the level it opens at, zone). `ranks` (the skill line's rank spells, by the cap they open, their
  tier the effect 118's value: what teaches each, the spells whose effect 36
  learns it, trainers, a cookbook and who sells it, a quest's reward; the
  level and skill asked; one taught rank a cap, Forever's second chain of
  Cooking spells nothing teaches left out): Apprentice and Journeyman from
  the cooking trainers, Expert from the Expert Cookbook (Shandrina, Wulan),
  Artisan from the quest Clamlette Surprise. A recipe item's `drops`: the
  likeliest droppers and their percent (the best chance, then the most
  spawns; Forever's sources give none yet). `ingredients` (every reagent:
  who sells it, any stock (four a side and continent, the capitals' first,
  a zone each); the creatures that drop it (no one's people: a member of a
  side by the template's group, the Warsong's scouts; one who talks
  (`npc_flags`) and isn't hostile to every player, a quest giver the
  Classic database gives clam meat, an innkeeper Questie says drops her
  wares; friends with both; one hostile to a side only, Dalaran's in
  Alterac, kept as that side's prey, the book hides it from the other; for
  each side: placed ones, out of a battleground, ordinary ones, one no
  source places, Alterac Valley's, a rare or a boss only where nothing else
  carries it, half the best chance at least, two a continent and zone side,
  eight at most); every zone it is fished in (a zone's fishing, its
  reference template, a school's pools; Questie's Fishing Bobber,
  `fishing`, where no zone is said: no source places the Greater Sagefish
  Schools); a herb's Herbalism and the zones its nodes grow in (their loot
  or a template it references); a container holding it one time in ten at
  least by its own chance, a clam; the zones it is `picked` up in, a chest
  of the world the same, a giant clam, a Warpwood Pod, a barrel of milk, not
  a treasure chest's share of food) and `zones` (each one named there: its
  continent, its side). A chance the Classic database gives as nought in a
  group: that group's equal share of what its own chances leave (Elwynn's
  fishing, the Brilliant Smallfish 59 in a hundred), the recipes' drops'
  too. The sellers and droppers named in every language, Forever's nameless
  traces left out.
  Also `i18n/names.json`, the game's names in every language, the client's:
  the cooking skill line's (Classic Era's skill list names a skill only by
  its name), Herbalism's, the chefs', and each game's npcs (complete in every language,
  the build refuses one missing) and quests (where the language has the
  title: none in Italian; a page names the giver instead), which
  `scripts/locales.ts` puts in each Text file (`ns.npcNames`,
  `ns.questNames`, this game's).

## The chefs' pages

- `recipes/<chef>/<chapter>.md`: the chefs' pages, one `## <spell> <name>`
  section a dish, every dish of both games for both chefs (132 each):
  English, plain ASCII. Their translations in
  `i18n/<locale>/recipes/<chef>/` (French, German, Spanish: esMX reads esES's
  with `i18n/esMX/regional.json`'s names), the same sections, stamped against the English they were translated from
  (`i18n/<locale>/recipes-stamp.json`). `scripts/pages.ts` checks them (no
  semicolons, the lengths: 70 to 100 words, 130 to 150 for the signature
  dishes, a fifth more in a translation; an ingredient of another dish
  named on a page; a translation whose English changed since, `--stamp`
  once read) and writes `Pages_<locale>.lua` (`ns.pages[chef][spell]`, and
  `ns.classicNames`: a translation uses Forever's place names,
  `i18n/<locale>/classic-names.json` swaps Classic Era's back in on that
  client). The chef is the character's faction's.
