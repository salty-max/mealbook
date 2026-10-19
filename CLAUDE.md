# Mealbook

A World of Warcraft addon: a chef's cookbook that fills in as the character
learns to cook, and the road to 300 (what to cook next, how many times, with
what). The first chapter of the professions addon (`../ideas/professions.md`),
planned in `../ideas/cookbook.md`: the chefs (Kendor Kabonka for the
Alliance, Eunice Burch for the Horde), their voices (`../ideas/cookbook-voices.md`,
waiting for the user's read), the Hunts, the Milestones, the pantry.
Started 19 October 2026. Local only so far: no GitHub repository, no store
page.

## Layout

- `addon/Mealbook`: one package for every game (`Mealbook_Vanilla.toc`:
  Classic Era, 11509; `_Camelot.toc`: Forever, 16001; no TBC Anniversary:
  the family dropped it), the same but for the interface and the game's
  recipes (`Recipes_Classic.lua`, `Recipes_Forever.lua`). Loads its recipes,
  `Kit.lua` (the kit's copy, `bun run kit:sync`; never edit it),
  `Locale.lua`, `Text_[TextLocale].lua`, `Core.lua`, `Road.lua`, `Book.lua`,
  `RecipesBook.lua`, `RoadBook.lua`.
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
  Also `i18n/skill_line.json`, the cooking skill line's name in every
  language, the client's own (Classic Era's skill list names a skill only by
  its name), which `scripts/locales.ts` puts in each Text file.
- `Core.lua`: the book (`MealbookChar`: known, cooked, first, skill, peak;
  ids only), the events (`ns.on`, `ns.onUnit`), the skill (Forever's
  professions by the skill line's id, Classic Era's skill list by its name
  in the client's language), the recipes known (IsPlayerSpell at the login,
  quietly; the cooking window's lines, Classic Era's TradeSkillUI calls and
  Forever's C_TradeSkillUI; Forever's NEW_RECIPE_LEARNED; the game's own
  line when a recipe is learned, ERR_LEARN_RECIPE_S), a dish cooked
  (UNIT_SPELLCAST_SUCCEEDED), `/mealbook` (`road`).
- `Road.lua`: the game's skill-up rule (orange always, grey never, between
  (grey - skill) / (grey - yellow)), the road from the skill now (each point
  the surest recipe known, then one the bags can cook, then the fewest
  ingredients; a leg per recipe, its casts the sum of one over the chance; a
  stop to train at each cap; where no recipe known goes on, `stuck`), a
  leg's shopping list, the recipes worth learning (from a trainer, a vendor,
  a quest: a drop is a hunt).
- `Book.lua`: the family's window and tabs in the kitchen's copper theme,
  the parts every tab uses (`ns.ui`); `RecipesBook.lua` (the dishes known by
  chapter, each in its colour now; a dish's page: its figures, ingredients
  and what it makes as the game's items, its colours, how it was learned;
  the chef's page goes above the facts once written); `RoadBook.lua` (the
  road's legs, the road as cards, where it stops and what to learn there; a
  leg's page: its casts and shopping list against the bags).
- `addon/test/game.lua` (Palaver's frames, events and timers; the skill as
  each client tells it, the recipes known, the cooking window, the dishes'
  names by id, the bags) and `addon/test/sim.lua`: a first login, the
  window, a recipe learned, dishes cooked, the road, the book's tabs, on
  Classic Era, Forever and a French client (`bun run check` runs all).
- Languages: Mealbook's own words through `L` (`i18n/<locale>/words.json`,
  `bun run locales`); English only so far. The dishes', ingredients' and
  recipes' names are the game's, by id, in the client's language.

## Not yet

- The chefs' pages (`recipes/<chef>/<spell>.md`, the voices first read by
  the user), the Hunts tab (recipe drops and limited-stock vendors, named
  through name files from wow-data), the Milestones, the pantry (an
  ingredient's tooltip line), the welcome page, the minimap button, the
  opt-in collector, French and German.
- To check in the game: whether Classic Era's IsPlayerSpell knows a recipe
  (else the window's read is the only one), Forever's C_TradeSkillUI as the
  sim models it.
- A GitHub repository, `.pkgmeta`, the release workflow, the store page.

## Commands

```bash
bun run check        # kit, recipes, languages, lint, the sim on three clients, TOCs
bun run package      # dist/Mealbook-<version>.zip for a test in the game
bun run recipes      # the recipes again, after wow-data's databases change
bun run kit:sync     # after a change to ../addon-kit/Kit.lua
bun run locales      # after a new L["..."] (then --keys for i18n/words.json)
```

## Conventions

The family's (`../CLAUDE.md`): Conventional Commits, lowercase subjects, no AI
co-author trailers; commit locally, ask before any push, release or deploy;
no semicolons in what players read, in any language.
