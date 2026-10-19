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
  Who and where, for the road's vendors and the hunts: `npcs` (every seller
  of a recipe, the three likeliest droppers of each, the quest givers: the
  side it serves, from its faction template's enemies (Alliance 469, Horde
  67, or the groups), one friendly to all standing in a capital its city's;
  its zone, the AreaTable id where most of its spawns are, its name the
  client's; a spot there, 0-100; its levels and rank) and `quests` (giver,
  side from the race mask else the giver's, level, the level it opens at,
  zone). A recipe item's `drops`: the likeliest droppers and their percent
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
  (UNIT_SPELLCAST_SUCCEEDED), `/mealbook` (`road`).
- `Hunts.lua`: a recipe's sources for the character's side (`H.mine()`,
  UnitFactionGroup), split in two: the shop (a trainer, the skill, a vendor
  who sells it to that side without a limit) and the finds (a vendor's
  limited stock, the droppers, a world drop, a quest of that side's). A dish
  is a hunt when it isn't known, no shop has it for that side and a find
  does; open when the skill reaches the one it is learned at (`H.list`:
  open, the skill the next opens at, found of all; those still raising the
  skill first).
- `Road.lua`: the game's skill-up rule (orange always, grey never, between
  (grey - skill) / (grey - yellow)), the road from the skill now (each point
  the surest recipe known, then one the bags can cook, then the fewest
  ingredients; a leg per recipe, its casts the sum of one over the chance; a
  stop to train at each cap; where no recipe known goes on, `stuck`), a
  leg's shopping list, the recipes worth learning (the shop's only, for the
  character's side: a vendor named with where it stands, the one in the
  character's zone if one is; the rest are hunts, a line pointing there).
- `Book.lua`: the family's window and tabs in the kitchen's copper theme,
  the parts every tab uses (`ns.ui`); `RecipesBook.lua` (the dishes known by
  chapter, each in its colour now; a dish's page: its figures, ingredients
  and what it makes as the game's items, its colours, how it was learned;
  the chef's page above the facts); `RoadBook.lua` (the
  road's legs, the road as cards, where it stops and what to learn there; a
  leg's page: its casts and shopping list against the bags); `HuntsBook.lua`
  (the hunts open now, found of all, the next to open; a hunt's page: the
  recipe and the dish as items, where to look as cards: a stall's stock,
  the droppers' zone, levels and chance, a quest's title or its giver; zone
  names the client's, `ui.where`).
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

- The Milestones, the pantry (an
  ingredient's tooltip line), the welcome page, the minimap button, the
  opt-in collector, German.
- To check in the game: whether Classic Era's IsPlayerSpell knows a recipe
  (else the window's read is the only one), Forever's C_TradeSkillUI as the
  sim models it.
- The CurseForge and Wago projects (their ids in the TOCs:
  X-Curse-Project-ID, X-Wago-ID; secrets CURSEFORGE_TOKEN, WAGO_API_TOKEN
  and INBOX_EVENTS_TOKEN), batched with
  Palaver's at the user's ask (19 October 2026); then Mealbook in Ravenpost's
  inbox (`src/digest.ts`, `src/stats.ts`) and the siblings' store pages.
  The store page is a draft: read it again against what ships.

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
