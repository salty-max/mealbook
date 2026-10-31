# Mealbook

A World of Warcraft addon: a chef's cookbook that fills in as the character
learns to cook, and the road to 300 (what to cook next, how many times, with
what). The first chapter of the professions addon (`../ideas/professions.md`),
planned in `../ideas/cookbook.md`: the chefs (Kendor Kabonka for the
Alliance, Eunice Burch for the Horde), their voices (`docs/voices.md`,
the rules and cards the pages follow), the Hunts, the Milestones, the pantry.
Started 19 October 2026. On GitHub (salty-max/mealbook, public, 19
October 2026), released since v0.1.0 (21 October 2026) on GitHub,
CurseForge and Wago. Classic Era (11509) and Forever (16001),
one package. Read the family's CLAUDE.md (`../CLAUDE.md`) first.

## Where things are

| What | Where |
|---|---|
| The addon file by file: the package, Core, Settings, Hunts, Milestones, Pantry, Road, the book's tabs, the tests, languages | `docs/architecture.md` |
| The recipes from wow-data (`scripts/recipes.ts`: dishes, sources, npcs, ingredients, ranks) and the chefs' pages (`scripts/pages.ts`) | `docs/data.md` |
| Artwork, the release pipeline, what isn't done yet | `docs/releases.md` |
| The chefs' voices: how a page reads, the two cards, the French | `docs/voices.md` |
| The plan | `../ideas/cookbook.md` |
| The pages themselves | `recipes/<chef>/<chapter>.md`, French in `i18n/frFR/recipes/<chef>/` |
| The chapters, by hand | `data/chapters.json` |
| The store page | `addon/CURSEFORGE.md` |

## Commands

```bash
bun run check        # kit, saved ids, recipes, languages, pages, lint, the sim on nine clients, TOCs
bun run check:ci     # what CI and the release gate run: no family folder (the kit, the saved ids and the generators' checks aside)
bun scripts/root.ts --run addon-kit/regional.ts   # esMX's game names from wow-data into i18n/esMX/regional.resolved.json (first, after a wow-data change; --check is in `check`)
bun run ids          # every table saved-ids.json lists keeps the ids it had at the fork point from origin/main (addon-kit's ids.ts)
bun scripts/root.ts --run addon-kit/q.ts check -- bun run check   # the same, quiet, stamping the tree for the push
bun run package      # dist/Mealbook-<version>.zip for a test in the game
bun run recipes      # the recipes again, after wow-data's databases change
bun run kit:sync     # after a change to the kit (Kit.lua, Media, scripts/root.ts)
bun run locales      # after a new L["..."] (then --keys for i18n/words.json)
bun scripts/pages.ts --stamp frFR   # once that translation was read against its changed English (a language, or all)
scripts/release.sh --version X.Y.Z [--hold] NOTES.md   # check, tag, push; Actions publish
```

## Hard rules

- The game's data comes from wow-data's databases only (`scripts/recipes.ts`,
  through `scripts/root.ts`, the kit's copy). Generated files
  (`Recipes_*.lua`, `Text_*.lua`, `Pages_*.lua`, `i18n/names.json`) are
  never edited by hand; `--check` fails a stale one.
- A regenerated table keeps every id a saved book may hold (`saved-ids.json`,
  `bun run ids` in the check): an id leaves only with the user's go, under
  `removed`.
- Saved data (`MealbookChar`) keeps ids only. Dishes, ingredients, recipes,
  npcs and zones are named by id in the client's language, never matched
  by an English name.
- Every dish of both games has a page from both chefs. Pages are English
  in plain ASCII, 70 to 100 words (130 to 150 for a signature dish, a fifth
  more in a translation: 70 to 120, 130 to 180), no semicolons in any language, no ingredient of
  another dish named. A translation is stamped against its English.
- Classic Era leaves out a dish its world can't teach. Forever keeps one no
  source has seen yet (`unknown`): a page when learned, never on the road.
- `Kit.lua`, `Media/`, `scripts/root.ts` (and `root.py`), `scripts/locales-lib.ts`, `scripts/package-lib.ts`,
  `i18n/kit/` (the kit's words, translated once), `wow.yml`, `stylua.toml` and
  `addon/test/wowmock.lua` (the tests' game) are the kit's copies: edit addon-kit, then `bun run kit:sync`. The addon's
  own globals for selene are `mealbook.yml`.
- No other addon's API, even optional. Stepping aside for a rival is fine.
- Conventional Commits, lowercase subjects, no AI trailers. Commit locally;
  ask before any push, release or deploy. The pre-push hook wants a check
  stamp on the tree (q), which `release.sh` makes after the version bump.
