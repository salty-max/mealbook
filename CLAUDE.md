# Mealbook

A World of Warcraft addon: a chef's cookbook that fills in as the character
learns to cook, and the road to 300 (what to cook next, how many times, with
what). The first chapter of the professions addon (`../ideas/professions.md`),
planned in `../ideas/cookbook.md`: the chefs (Kendor Kabonka for the
Alliance, Eunice Burch for the Horde), their voices (`../ideas/cookbook-voices.md`,
the cards the pages follow), the Hunts, the Milestones, the pantry.
Started 19 October 2026. On GitHub (salty-max/mealbook, public, 19
October 2026), not yet released: no store page.

## Layout

- `addon/Mealbook`: one package for every game (`Mealbook_Vanilla.toc`:
  Classic Era, 11509; `_Camelot.toc`: Forever, 16001; no TBC Anniversary:
  the family dropped it), the same but for the interface and the game's
  recipes (`Recipes_Classic.lua`, `Recipes_Forever.lua`). Loads its recipes,
  `Kit.lua` (the kit's copy, `bun run kit:sync`; never edit it),
  `Locale.lua`, `Text_[TextLocale].lua`, `Pages_[TextLocale].lua`,
  `Core.lua`, `Settings.lua`, `Road.lua`, `Hunts.lua`, `Milestones.lua`,
  `Pantry.lua`, `Book.lua`, `RecipesBook.lua`, `RoadBook.lua`,
  `HuntsBook.lua`, `MilestonesBook.lua`, `Welcome.lua`, `Minimap.lua` (the
  test game loads them from the TOC).
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
  templates, a world drop said as one, the quests). Classic Era leaves out
  a dish its world can't teach (Season of Discovery's, the Crystal Throat
  Lozenge): 81 dishes. Forever keeps its own whose recipe no source has seen
  yet (`unknown`, 27 before launch): a page when learned, never on the road.
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
  Artisan from the quest Clamlette Surprise. A recipe item's `drops`: the likeliest droppers and their percent
  (the best chance, then the most spawns; Forever's sources give none yet).
  Also `i18n/names.json`, the game's names in every language, the client's:
  the cooking skill line's (Classic Era's skill list names a skill only by
  its name), the chefs', and each game's npcs (complete in every language,
  the build refuses one missing) and quests (where the language has the
  title: none in Italian; a page names the giver instead), which
  `scripts/locales.ts` puts in each Text file (`ns.npcNames`,
  `ns.questNames`, this game's).
- `recipes/<chef>/<chapter>.md`: the chefs' pages, one `## <spell> <name>`
  section a dish, every dish of both games for both chefs (132 each):
  English, plain ASCII. Their French in `i18n/frFR/recipes/<chef>/`, the
  same sections, stamped against the English they were translated from
  (`i18n/frFR/recipes-stamp.json`). `scripts/pages.ts` checks them (no
  semicolons, the lengths: 70 to 100 words, 130 to 150 for the signature
  dishes, a fifth more in a translation; an ingredient of another dish
  named on a page; a translation whose English changed since, `--stamp`
  once read) and writes `Pages_<locale>.lua` (`ns.pages[chef][spell]`, and
  `ns.classicNames`: the French text uses Forever's place names,
  `i18n/frFR/classic-names.json` swaps Classic Era's back in on that
  client). The chef is the character's faction's.
- `Core.lua`: the book (`MealbookChar`: known, cooked, first, skill, peak;
  ids only), the events (`ns.on`, `ns.onUnit`), the skill (Forever's
  professions by the skill line's id, Classic Era's skill list by its name
  in the client's language), the recipes known (IsPlayerSpell at the login,
  quietly; the cooking window's lines, Classic Era's TradeSkillUI calls and
  Forever's C_TradeSkillUI; Forever's NEW_RECIPE_LEARNED; the game's own
  line when a recipe is learned, ERR_LEARN_RECIPE_S), a dish cooked
  (UNIT_SPELLCAST_SUCCEEDED), `/mealbook` (`road`, `chef`, `tooltips`,
  `minimap`, `settings`, `welcome`, `export`, `import CODE`: the code's
  letters as typed).
- `Settings.lua`: each character's settings, the kit's profiles (a profile
  "Name - Realm" in MealbookSettings, copied from another character of this
  game or a code `MB1:...`, `/mealbook export`, `/mealbook import CODE`):
  the chef (0 the side's, 1 Kendor, 2 Eunice: a number, as the codes carry),
  the pantry's tooltip line, the minimap button and its place (165 degrees,
  clear of the siblings'); the test builds' account-wide chef and tooltips
  taken in at the login. The Options page (`/mealbook settings`, a
  right-click on the button). `Welcome.lua`: the kit's welcome page, once
  per character (`/mealbook welcome`). `Minimap.lua`: the book's button, as
  the siblings'.
- `Hunts.lua`: a recipe's sources for the character's side (`H.mine()`,
  UnitFactionGroup), split in two: the shop (a trainer, the skill, a vendor
  who sells it to that side without a limit) and the finds (a vendor's
  limited stock, the droppers, a world drop, a quest of that side's). A dish
  is a hunt when it isn't known, no shop has it for that side and a find
  does; open when the skill reaches the one it is learned at (`H.list`:
  open, the skill the next opens at, found of all; those still raising the
  skill first).
- `Milestones.lua`: the achievements (milestones in the code and the saved
  book, achievements to the player, as Yonder's): the ranks (cooking
  learned, Journeyman, Expert, Artisan by the skill's cap; 300), the recipes
  known (10, 25, 50, 75, every one the side can learn: a step past that
  number not listed, Classic Era's Horde learns 66), the dishes cooked
  (50 to 5000), the first dish of each chapter the game has (Classic Era
  has no feasts or fires), the hunts found (one, five, all). Checked at
  each recipe learned, dish cooked, point or rank (`ns.progressed`, from
  Core), quietly at the login (`retro`); earned: the game's fanfare, a line
  in chat, the kit's banner among the game's alerts (a click opens it).
- `Pantry.lua`: an ingredient's dishes (every dish's reagents, by item):
  on the item's tooltip, the known dishes it cooks into, each in its colour
  now, the surest first, three at most (Forever's tooltip processor, else
  the tooltips' OnTooltipSetItem; `/mealbook tooltips` turns it off,
  the character's `tooltips` setting); the dishes the bags can cook now and how
  many times, on the Recipes tab's front page.
- `Road.lua`: the game's skill-up rule (orange always, grey never, between
  (grey - skill) / (grey - yellow)), the road from the skill now to 300
  (each point the surest recipe known or learnable there: `learnable`, the
  road's book's, a trainer's or a vendor of the side's; a recipe to learn
  only when a tenth surer than one in hand, `LEARN_COST`; at the same chance
  one known, then one the bags can cook, then the fewest ingredients, and of
  those to learn a trainer's, then the one orange the longest; a leg per
  recipe, `learn` where it is learned at its start, its casts the sum of one
  over the chance; a stop at each cap with the rank's sources, `D.ranks`;
  where nothing known or learnable goes on, `stuck`), a leg's shopping
  list, the recipes worth learning where it stops (the shop's of the side;
  the rest are hunts, a line pointing there). The whole road from 1, for
  either side: about 307 casts, 9 recipes to learn (Charred Wolf Meat to
  Baked Salmon).
- `Book.lua`: the family's window and tabs in the kitchen's copper theme,
  the parts every tab uses (`ns.ui`); `RecipesBook.lua` (the dishes known by
  chapter, each in its colour now; a dish's page: its figures, ingredients
  and what it makes as the game's items, its colours, how it was learned;
  the chef's page above the facts); `RoadBook.lua` (the
  road's legs, the road as cards, where it stops; a leg's page: where to
  learn its recipe, its casts and shopping list against the bags; a stop's
  page: how its rank is learned, the nearest trainers of the side, the
  cookbook and who sells it, the quest, and what it asks; no cooking yet:
  the road from 1, learning cooking first); `HuntsBook.lua`
  (the hunts open now, found of all, the next to open; a hunt's page: the
  recipe and the dish as items, where to look as cards: a stall's stock,
  the droppers' zone, levels and chance, a quest's title or its giver; zone
  names the client's, `ui.where`); `MilestonesBook.lua` (the achievements'
  tab over both panels, `whole`: the kit's board, a row per achievement
  under its group, earned or how far along).
- `addon/test/game.lua` (the addon's files loaded as its TOC lists them;
  Palaver's frames, events and timers; a zone's name by its id, the
  faction (`state.faction`); the skill as
  each client tells it, the recipes known, the cooking window, the dishes'
  names by id, the bags) and `addon/test/sim.lua`: a first login, the
  window, a recipe learned, dishes cooked, the road, the book's tabs, on
  Classic Era, Forever and a French client (`bun run check` runs all).
- Languages: Mealbook's own words through `L` (`i18n/<locale>/words.json`,
  `bun run locales`): English and French (interface and pages), the other
  clients English until translated. The dishes', ingredients' and
  recipes' names are the game's, by id, in the client's language.

## Artwork

`assets/logo-master.png` is the original generated logo, with 1024px and
512px PNG exports and the exact prompt in `assets/logo-prompts.json`.
`addon/Mealbook/Media/Logo.tga` is the uncompressed 256px game texture,
rounded as the siblings' (radius 34), used by both TOCs' IconTexture and
the cookbook window's portrait. The mark is an open copper-bound cookbook
with a wooden spoon and an ink drawing of a steaming pot, in the family's
painted gold and navy style.

Releases (prepared 19 October 2026, as Palaver's): `.pkgmeta` (the
BigWigs packager: addon/Mealbook alone), `.github/workflows/release.yml` (a
tag vX.Y.Z: the sims, the package checked to be the folder, then GitHub,
CurseForge and Wago; HOLD_STORES=true holds the stores), `ci.yml` (every
push: locales, lint, the three sims, the package; the recipes' and pages'
checks need wow-data's databases, so the daily job runs them),
`game-data.yml` (daily: recipes, pages, locales from wow-data's pins),
`scripts/release.sh [--version X.Y.Z] [--hold] NOTES.md`. The store page
`addon/CURSEFORGE.md` (title "Mealbook: Cooking Guide & Cookbook", the
summary the TOCs' Notes).

## Not yet

- The opt-in collector (the kit's `K.collect`): Ravenpost reads the four
  older addons' `<Addon>Collect` only (`shared.go`), so Mealbook's (and
  Palaver's) needs Ravenpost's list and a release too. German.
- To check in the game: whether Classic Era's IsPlayerSpell knows a recipe
  (else the window's read is the only one), Forever's C_TradeSkillUI as the
  sim models it.
- The first release: the projects are made (CurseForge 1754441, Wago
  YK9xja6L, their ids in the TOCs, the tokens set, the inbox counting
  them); then the siblings' "Other addons" lines. The store page is a
  draft: read it again against what ships.

## Commands

```bash
bun run check        # kit, recipes, languages, lint, the sim on three clients, TOCs
bun run package      # dist/Mealbook-<version>.zip for a test in the game
bun run recipes      # the recipes again, after wow-data's databases change
bun run kit:sync     # after a change to ../addon-kit/Kit.lua
scripts/release.sh [--version X.Y.Z] [--hold] NOTES.md   # tag, push; Actions publish
bun run locales      # after a new L["..."] (then --keys for i18n/words.json)
```

## Conventions

The family's (`../CLAUDE.md`): Conventional Commits, lowercase subjects, no AI
co-author trailers; commit locally, ask before any push, release or deploy;
no semicolons in what players read, in any language.
