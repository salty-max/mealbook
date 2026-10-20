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
  sim models it, the "Where to get them" cards (measured with the game's
  font against the card's 380 pixels, not seen).
- The Greater Sagefish Schools' places: no source wow-data reads has them
  (Questie's zone 0, no spawns), so Raw Greater Sagefish says only "caught
  fishing". Wowhead's object pages would give them, through wow-data.
- The first release: the projects are made (CurseForge 1754441, Wago
  YK9xja6L, their ids in the TOCs, the tokens set, the inbox counting
  them); then the siblings' "Other addons" lines. The store page is a
  draft: read it again against what ships.
