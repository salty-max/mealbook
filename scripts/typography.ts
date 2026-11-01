/**
 * French typography in Mealbook's French (decision Q1, 31 October 2026, as
 * the client writes it): a no-break space (U+00A0) before : ? ! and a percent
 * sign, and inside « ». Over the authored French: the chefs' pages
 * (i18n/frFR/recipes/), the values of words.json and the TOCs' Notes-frFR
 * (terms.ts checks those too). The kit's words (i18n/kit/) are the kit's copy,
 * set in addon-kit. Idempotent.
 *
 *   bun scripts/typography.ts           fix them
 *   bun scripts/typography.ts --check   fail if one is left (the check runs it)
 */
import { readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join, relative } from "node:path";

const ROOT = new URL("..", import.meta.url).pathname;
const FR = join(ROOT, "i18n/frFR");
const NBSP = "\u00a0";

/** One string's French typography (a format blank's "%s" is no percent sign). */
export function typeset(s: string): string {
  return s
    .replace(/[ \t]+([:?!])(?=[\s"»)\\*_…',.!?]|$)/gm, `${NBSP}$1`)
    .replace(/(\p{L})([?!])/gu, `$1${NBSP}$2`)
    .replace(/(\d)[ \t]*%(?![sdif%$\d])/g, `$1${NBSP}%`)
    .replace(/[ \t]+%%/g, `${NBSP}%%`)
    .replace(/«[ \t\u00a0]*/g, `«${NBSP}`)
    .replace(/[ \t\u00a0]*»/g, `${NBSP}»`);
}

/** Each file's new text: a page file's body after its front matter,
 * words.json's values (never its English keys), a TOC's Notes-frFR line only. */
function fixed(file: string): string {
  const text = readFileSync(file, "utf8");
  if (file.endsWith(".toc")) return text.replace(/^(## Notes-frFR:)(.*)$/m, (_, k, v) => k + typeset(v));
  // (words.json: the values only, a line each, the English keys untouched)
  if (!file.endsWith(".md")) return text.replace(/^(\s*"(?:[^"\\]|\\.)*": )(.*)$/gm, (_, k, v) => k + typeset(v));
  const [, head, body] = text.match(/^(---\n[^]*?\n---\n)([^]*)$/) ?? ["", "", text];
  return head + typeset(body);
}

const recipes = join(FR, "recipes");
const files = [
  ...readdirSync(recipes).flatMap((chef) => readdirSync(join(recipes, chef)).filter((f) => f.endsWith(".md")).map((f) => join(recipes, chef, f))),
  join(FR, "words.json"),
  ...readdirSync(join(ROOT, "addon/Mealbook")).filter((f) => f.endsWith(".toc")).map((f) => join(ROOT, "addon/Mealbook", f)),
];
const check = process.argv.includes("--check");
const left = files.filter((f) => fixed(f) !== readFileSync(f, "utf8"));
if (check) {
  if (left.length) {
    console.error(`✗ French typography (a no-break space before : ? ! %, inside « »): run bun scripts/typography.ts\n  ${left.map((f) => relative(ROOT, f)).join("\n  ")}`);
    process.exit(1);
  }
  console.log(`✓ French typography: ${files.length} files`);
} else {
  for (const f of left) writeFileSync(f, fixed(f));
  console.log(`✓ French typography: ${left.length} files fixed of ${files.length}`);
}
