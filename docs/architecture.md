# Mealbook's architecture

The addon file by file (moved from CLAUDE.md on 20 October 2026; the map
stays there). The recipes' data and the chefs' pages: `docs/data.md`.

## The package

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

## The files

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
- `Pantry.lua`: where an ingredient comes from, for the cook (`P.sources`:
  the sellers of its side, the creatures it may hunt (none of its own
  side's, half the likeliest's chance at least), the droppers and zones the
  nearest first; one line, `P.easiest`: a seller, else where it is fished,
  the herb's (Herbalism by its name in the client's, `ns.herbName`), the
  nearest creature, a container or a chest of the world first where no
  creature drops it one time in ten, else caught fishing, else sold only to
  the other side; every way on a tooltip, `P.addSources`, the road's and the
  dishes' ingredients). An ingredient's dishes (every dish's reagents, by item):
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
  where nothing known or learnable goes on, `stuck`: only the hunts go on,
  a line pointing there), a leg's shopping list. The whole road from 1, for
  either side: about 307 casts, 9 recipes to learn (Charred Wolf Meat to
  Baked Salmon).
- `Book.lua`: the family's window and tabs in the kitchen's copper theme,
  the parts every tab uses (`ns.ui`; the page again when the game tells an
  item's name late, `GET_ITEM_INFO_RECEIVED`, only for one the book shows
  and the game found); `RecipesBook.lua` (the dishes known by
  chapter, each in its colour now; a dish's page: its figures, ingredients
  and what it makes as the game's items, its colours, how it was learned;
  the chef's page above the facts); `RoadBook.lua` (the
  road's legs, the road as cards, where it stops; a leg's page: where to
  learn its recipe, its casts and shopping list against the bags, where to
  get each ingredient as cards (`P.easiest`); a stop's
  page: how its rank is learned, the nearest trainers of the side (same
  zone, then the character's continent, a capital's first: `ui.byNearness`,
  the data's `map` and `city`; zones the same way, the cook's side's or
  neither's first, `ui.zonesByNearness`; either keeps the list's own order
  between equals; the planner's lookups once a recipe a road), the
  cookbook and who sells it, the quest, and what it asks; no cooking yet:
  the road from 1, learning cooking first); `HuntsBook.lua`
  (the hunts open now, found of all, the next to open; a hunt's page: the
  recipe and the dish as items, where to look as cards: a stall's stock,
  the droppers' zone, levels and chance, a quest's title or its giver; zone
  names the client's, `ui.where`); `MilestonesBook.lua` (the achievements'
  tab over both panels, `whole`: the kit's board, a row per achievement
  under its group, earned or how far along).

## Tests

- `addon/test/game.lua` (the addon's files loaded as its TOC lists them;
  Palaver's frames, events and timers; a zone's name by its id, the
  faction (`state.faction`); the skill as
  each client tells it, the recipes known, the cooking window, the dishes'
  names by id, the bags) and `addon/test/sim.lua`: a first login, the
  window, a recipe learned, dishes cooked, the road, the book's tabs, on
  Classic Era, Forever and a French client (`bun run check` runs all).

## Languages

- Languages: Mealbook's own words through `L` (`i18n/<locale>/words.json`,
  `bun run locales`): English and French (interface and pages), the other
  clients English until translated. The dishes', ingredients' and
  recipes' names are the game's, by id, in the client's language.
