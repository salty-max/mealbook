# Mealbook's architecture

The addon file by file (moved from CLAUDE.md on 20 October 2026; the map
stays there). The recipes' data and the chefs' pages: `docs/data.md`.

German and Spanish (deDE, esES, esMX) are held back from players since 1 November 2026 (`HIDDEN_LOCALES` in addon-kit's `locales-lib.ts`): their language files are stubs with the game's names or English, their tests skip (`addon/test/held.lua`), and their `i18n/` stays. Restoring them starts by emptying that list.

## The package

- `addon/Mealbook`: one package for every game (`Mealbook_Vanilla.toc`:
  Classic Era, 11509; `_Camelot.toc`: Forever, 16001), the same but for the interface and the game's
  recipes (`Recipes_Classic.lua`, `Recipes_Forever.lua`). Loads its recipes,
  `Kit.lua` (the kit's copy, `bun run kit:sync`; never edit it),
  `Locale.lua`, `Text_[TextLocale].lua`, `Pages_[TextLocale].lua`,
  `Core.lua`, `Settings.lua`, `Road.lua`, `Hunts.lua`, `Milestones.lua`,
  `Pantry.lua`, `Book.lua`, `RecipesBook.lua`, `RoadBook.lua`,
  `HuntsBook.lua`, `MilestonesBook.lua`, `Welcome.lua`, `Minimap.lua` (the
  test game loads them from the TOC).

## The files

- `Core.lua`: the book (`MealbookChar`: version, known, cooked, first,
  skill, peak; ids only; `version` 1 is 0.1.x's shape, stamped on a book
  from before it), the events (`ns.on`, `ns.onUnit`), the skill (Forever's
  professions by the skill line's id, Classic Era's skill list by its name
  in the client's language), the recipes known (IsPlayerSpell at the login,
  quietly; the cooking window's lines, Classic Era's TradeSkillUI calls and
  Forever's C_TradeSkillUI; Forever's NEW_RECIPE_LEARNED; the game's own
  line when a recipe is learned, ERR_LEARN_RECIPE_S, its pattern built
  once), a dish cooked
  (UNIT_SPELLCAST_SUCCEEDED), `/mealbook`, the kit's command (`road`,
  `chef`, `tooltips`, `minimap`, `settings`, `welcome`, `export`, `import
  CODE`: the code's letters as typed; an unknown word prints the usage, the
  replies capitalised).
- `Settings.lua`: each character's settings, the kit's profiles (a profile
  "Name - Realm" in MealbookSettings, copied from another character of this
  game or a code `MB1:...`, `/mealbook export`, `/mealbook import CODE`):
  the chef (0 the side's, 1 Kendor, 2 Eunice: a number, as the codes carry),
  the achievements' alert (`achievementToast`, a `v` in the code), the
  pantry's tooltip line, the minimap button and its place (165 degrees,
  clear of the siblings'). The Options page (the kit's `K.options`:
  `/mealbook settings`, a right-click on the button). `Welcome.lua`: the kit's welcome page, once
  per character (`/mealbook welcome`). `Minimap.lua`: the book's button, as
  the siblings'.
- `Hunts.lua`: a recipe's sources for the character's side (`H.mine()`,
  UnitFactionGroup), split in two: the shop (a trainer, the skill, a vendor
  who sells it to that side without a limit) and the finds (a vendor's
  limited stock, the droppers, a world drop, a quest of that side's). A dish
  is a hunt when it isn't known, no shop has it for that side and a find
  does, or only the other side gets it (a vendor, a stall, a quest of
  theirs) and its recipe trades: `auction`, bought at a neutral auction
  house (the data's `auctioneers`; one that binds when picked up, `bound`,
  never); open when the skill reaches the one it is learned at (`H.list`:
  open, the skill the next opens at, found of all, the side's own only; the
  auction house's open apart; those still raising the skill first). A
  recipe only the other side gets (`H.theirs`) counts for nothing but its
  auction hunt: no achievement, none of the hunts' figures. `H.sources`,
  `H.theirs` and `H.of` come from the game's data alone, built once a side
  and shared (read only): every dish cast checks the achievements, which ask
  them of every dish (it made over 1 MB of garbage a cast before).
- `Milestones.lua`: the achievements (milestones in the code and the saved
  book, achievements to the player, as Yonder's): the ranks (cooking
  learned, Journeyman, Expert, Artisan by the skill's cap; 300), the recipes
  known (10, 25, 50, 75, every one the side can learn: a step past that
  number not listed, Classic Era's Horde learns 66: the other side's
  recipes, `H.theirs`, never counted, not known, cooked or a chapter's
  first), the dishes cooked
  (50 to 5000), the first dish of each chapter the game has (Classic Era
  has no feasts or fires), the hunts found (one, five, all). Checked at
  each recipe learned, dish cooked, point or rank (`ns.progressed`, from
  Core), quietly at the login (`retro`); earned: the game's fanfare, a line
  in chat, the game's own achievement alert behind a switch
  (`achievementToast`; the kit's banner where a client lacks the alert; a
  click opens the book).
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
  the chef's page above the facts; the select under the search, `effects`: every effect or the one a dish gives, with how many dishes known give it, the kit's `filter` as the Codex's kinds); `RoadBook.lua` (the
  road's legs, the road as cards, where it stops; a leg's page: where to
  learn its recipe, its casts (about), what the bags can cook and still
  lack, its shopping list against the bags, where to get each ingredient
  as cards (`P.easiest`), a link to its recipe's page once known; a stop's
  page: how its rank is learned, the nearest trainers of the side (same
  zone, then the character's continent, a capital's first: `ui.byNearness`,
  the data's `map` and `city`; zones the same way, the cook's side's or
  neither's first, `ui.zonesByNearness`; either keeps the list's own order
  between equals; the planner's lookups once a recipe a road), the
  cookbook and who sells it, the quest, and what it asks; no cooking yet:
  the road from 1, learning cooking first); `HuntsBook.lua`
  (the hunts open now, found of all, the next to open, the side's own; the
  auction house's under their own heading, counting for none of it; a
  hunt's page: the
  recipe and the dish as items, where to look as cards: a stall's stock,
  the droppers' zone, levels and chance, a quest's title or its giver; an
  auction hunt's: the neutral auction houses, an auctioneer a town the
  nearest first, and how the other side gets it; zone names the client's,
  `ui.where`); `MilestonesBook.lua` (the achievements'
  tab over both panels, `whole`: the kit's board, a row per achievement
  under its group, earned or how far along).

## Tests

- `addon/test/game.lua` (the kit's game, `wowmock.lua`: frames, events,
  timers, the character, the map, the Options panel; then Mealbook's own
  world and the addon loaded as its TOC lists it: a zone's name by its id, the
  faction (`state.faction`); the skill as
  each client tells it, the recipes known, the cooking window, the dishes'
  names by id, the bags) and `addon/test/sim.lua`: a first login, the
  window, a recipe learned, dishes cooked, the road, the book's tabs, on
  nine clients: Classic Era and Forever, French, German, Spanish and
  Mexican Spanish (both games for the last three), and an achievement
  check's garbage held under 32 KB (`bun run check` runs all).

## Languages

- Languages: Mealbook's own words through `L` (`i18n/<locale>/words.json`,
  `bun run locales`): English, French, German and Spanish (interface and
  pages; German and Spanish flagged, first translations, `meta.json`), the
  other clients English until translated. The chefs speak to the reader as
  the game's people do: "vous" in French, "Ihr" in German (the interface
  says "du"), "tú" in Spanish, never agreeing with the reader's gender.
  esMX shares esES's words and pages, with its own client's names
  (`i18n/esMX/regional.json` (game names from wow-data through addon-kit/regional.ts, `regional.resolved.json`; the hand file keeps words), swapped in by the build) and decimal point. The dishes', ingredients' and
  recipes' names are the game's, by id, in the client's language.

## The key binding

For a controller player (no keyboard for the slash command, a cursor to steer to the minimap button). `addon/Mealbook/Bindings.xml` and `ns.kit.binding(...)` at the end of `Minimap.lua`: one key or pad button, chosen in the game's Key Bindings under the addon's own heading ("Open <the addon>"), opens and closes the book through `ns.toggle`, as the minimap button's click does. The binding does nothing until the player puts a key on it. The kit's `K.binding`, the file, what the game does in each game and what is not verified: `addon-kit/docs/controller.md`, "Opening by a pad button". `bun run bindings` (part of `check`) checks the file, the function and the package.

## The book's size and the paper look

(13 November 2026, the kit's `O:look()` in `Settings.lua`: the settings `bookSize`, 1 to 4, and `paper`, kept per
character and carried by a settings code as `z` and `p`.) Book size scales the whole window (`K.movable`, the
kit's `K.resize` at once, never past the screen); the paper look is dark ink on the game's quest paper and
takes effect after a reload. Every colour is read from `K.T` when a piece is built, never kept at load; the
chat keeps the game's link yellow and the dark look's name (chat is dark whatever the look). The skill colours (red, orange, yellow, green, grey: the game's cooking window's) are each given a paper colour by hand (`COLOURS` in `Book.lua`, not one darkening rule: that makes yellow and grey near black alike), every one at 3 to 1 or more on the paper and kept apart (the sim asserts both). A tooltip is the game's, dark whatever the look, so its words keep the game's colours (`ui.tipCode`).
`PAPER=1 luajit addon/test/sim.lua` plays a character on the paper at the largest size (in the check);
`RENDER=dir [PAPER=1] luajit addon/test/sim.lua` writes the book as HTML with the real colours
(`addon-kit/render.lua`, Chrome's fonts: the game has the last word).
