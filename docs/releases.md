# Mealbook's artwork, releases and what's not done

(Moved from CLAUDE.md on 20 October 2026.)

## Artwork

`assets/logo-master.png` is the original generated logo, with 1024px and
512px PNG exports and the exact prompt in `assets/logo-prompts.json`.
`addon/Mealbook/Media/Logo.tga` is the uncompressed 256px game texture,
rounded as the siblings' (radius 34), used by both TOCs' IconTexture and
the cookbook window's portrait. The mark is an open copper-bound cookbook
with a wooden spoon and an ink drawing of a steaming pot, in the family's
painted gold and navy style.

## Releases

Releases (prepared 19 October 2026, as Palaver's): `.pkgmeta` (the
BigWigs packager: addon/Mealbook alone), `.github/workflows/release.yml` (a
tag vX.Y.Z: the tag checked as a release's, `bun run check:ci`, the package
checked to be the folder, each store's token and the TOCs' ids, then
GitHub, CurseForge and Wago; HOLD_STORES=true holds the stores; by hand,
`-f stores=curseforge|wago` retries one store alone), `ci.yml` (every
push: `bun run check:ci` (locales, lint, the nine sims, the package); the recipes' and pages'
checks need wow-data's databases, so the daily job runs them),
`game-data.yml` (daily: recipes, pages, locales from wow-data's pins),
`scripts/release.sh --version X.Y.Z [--hold] NOTES.md`. The store page
`addon/CURSEFORGE.md` (title "Mealbook: Cooking Guide & Cookbook", the
summary the TOCs' Notes).

## Not yet

- The opt-in collector (the kit's `K.collect`): Ravenpost reads the four
  older addons' `<Addon>Collect` only (`shared.go`), so Mealbook's (and
  Palaver's) needs Ravenpost's list and a release too.
- To check in the game: whether Classic Era's IsPlayerSpell knows a recipe
  (else the window's read is the only one), Forever's C_TradeSkillUI as the
  sim models it, the "Where to get them" cards (measured with the game's
  font against the card's 380 pixels, not seen).
- The Greater Sagefish Schools' places: wow-data has them (52 pooled
  spawns of object 180684), but `recipes.ts` reads spawns by entity only,
  never through a pool, so Raw Greater Sagefish says only "caught fishing".
  A spawns-with-pools helper in wow-data's `db.ts` would give them (the
  audit of 30 October 2026, Part 3).
