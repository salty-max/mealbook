/**
 * i18n/<locale>/ → addon/Mealbook/Text_<locale>.lua, one for every language the
 * game has (a stub where there is no translation yet, so the TOC never names
 * a missing file): each client loads its own, through Text_[TextLocale].lua in
 * the TOCs, and English stays wherever a translation says nothing (Locale.lua).
 * The family's core (scripts/locales-lib.ts, the kit's copy) reads the words,
 * merges the kit's own (i18n/kit/, translated once for every addon), checks
 * them and writes the files.
 *
 *   bun scripts/locales.ts            write the Text files
 *   bun scripts/locales.ts --check    fail if one isn't up to date, a word has
 *                                     no translation, a translation drops or
 *                                     reorders a blank, or prose has a semicolon
 *   bun scripts/locales.ts --keys     write i18n/words.json, every word to translate
 */
import { join } from "node:path";
import { json, q, run } from "./locales-lib";

const ROOT = new URL("..", import.meta.url).pathname;
const I18N = join(ROOT, "i18n");

// The game's own names a language's file carries, every language's whole
// (English one of them): the cooking skill line's, Herbalism's and the
// chefs' (i18n/names.json, written by scripts/recipes.ts from the client's data).
function namesLua(locale: string): string[] {
  type ByGame = Record<string, Record<string, string>>;
  const names: Record<string, { skillLine: string; herbalism: string; kendor: string; eunice: string; npcs: ByGame; quests: ByGame }> = json(join(I18N, "names.json"));
  const mine = names[locale];
  if (!mine) throw new Error(`i18n/names.json names nothing in ${locale}: bun scripts/recipes.ts`);
  // (each game's npcs and quests by id: Recipes_<game>.lua's)
  const byGame = (field: string, t: ByGame) => [
    `  ${field} = {`,
    ...Object.entries(t).flatMap(([game, m]) => [
      `    ${game} = {`,
      ...Object.entries(m)
        .sort(([a], [b]) => Number(a) - Number(b))
        .map(([id, name]) => `      [${id}] = ${q(name)},`),
      "    },",
    ]),
    "  },",
  ];
  return [
    "ns.names({",
    `  skillLine = ${q(mine.skillLine)},`,
    `  herbalism = ${q(mine.herbalism)},`,
    `  chefs = { kendor = ${q(mine.kendor)}, eunice = ${q(mine.eunice)} },`,
    ...byGame("npcs", mine.npcs),
    ...byGame("quests", mine.quests),
    "})",
  ];
}

run({ root: ROOT, addon: "addon/Mealbook", names: namesLua });
