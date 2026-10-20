/**
 * The chefs' pages: recipes/<chef>/<chapter>.md (English) and
 * i18n/<locale>/recipes/<chef>/<chapter>.md (a translation), each a section a
 * dish, "## <spell id> <the dish's name>" then its paragraphs, into
 * addon/Mealbook/Pages_<locale>.lua (the client loads its own: the TOCs name
 * Pages_[TextLocale].lua; a language with no translation gets the English).
 *
 * The voices' rules (../ideas/cookbook-voices.md) the build can check:
 *   - every dish of either game (scripts/recipes.ts) has a page from each chef
 *   - no semicolons, in any language; plain ASCII in the English
 *   - a page's length: 70 to 100 words, 130 to 150 for a signature dish (said
 *     when outside; refused far outside); a translation runs longer
 *   - an ingredient a page names is the recipe's own, under the name the
 *     language's client gives it (wow-data's, by id: Lean Wolf Flank is
 *     "Steak de loup" in French); the longest names first, so "Big Bear Meat"
 *     isn't read as "Bear Meat"
 *   - a translation stamped with its English (i18n/<locale>/recipes-stamp.json,
 *     --stamp): an English page changed since is said
 * A translation names places as Forever's client does; Classic Era's names
 * where they differ (i18n/<locale>/classic-names.json, Hurlevent: Stormwind)
 * go in the Pages file, swapped in on Classic Era by the book.
 *
 *   bun scripts/pages.ts           write the Pages files
 *   bun scripts/pages.ts --check   fail if one isn't up to date or a rule breaks
 *   bun scripts/pages.ts --stamp   record each translation's English as read
 *   bun scripts/pages.ts --partial the pages still to write counted, not refused
 */
import { createHash } from "node:crypto";
import { existsSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type * as WowDb from "../../wow-data/src/db";
import { cookbook, type Dish } from "./recipes";
import { familyPath } from "./root";

// through the family folder, from a worktree too (scripts/root.ts)
const { openDb } = (await import(familyPath("wow-data", "src", "db.ts"))) as typeof WowDb;

const ROOT = join(import.meta.dir, "..");
const ADDON = join(ROOT, "addon", "Mealbook");
export const CHEFS = ["kendor", "eunice"] as const;
const LOCALES = ["enUS", "enGB", "deDE", "frFR", "esES", "esMX", "ruRU", "ptBR", "itIT", "koKR", "zhCN", "zhTW"];
const TRANSLATED = ["frFR"];
// (the dozen dishes a chef has more to say about: cookbook-voices.md)
export const SIGNATURE = new Set([2543, 2542, 2795, 15906, 15910, 15865, 15933, 22761, 24801, 25659, 1262978, 1225763, 1225762]);

type Page = { spell: number; title: string; paragraphs: string[]; file: string };

// Every section of a chef's chapter files.
function read(dir: string): Map<number, Page> {
  const out = new Map<number, Page>();
  if (!existsSync(dir)) return out;
  for (const f of readdirSync(dir).filter((f) => f.endsWith(".md")).sort()) {
    const text = readFileSync(join(dir, f), "utf8").replace(/^---\n[\s\S]*?\n---\n/, "");
    for (const part of text.split(/^## /m).slice(1)) {
      const [head, ...rest] = part.split("\n");
      const m = head.match(/^(\d+)\s+(.+)$/);
      if (!m) throw new Error(`${dir}/${f}: "## ${head}" is no "## <spell id> <name>"`);
      const spell = Number(m[1]);
      if (out.has(spell)) throw new Error(`${dir}/${f}: ${spell} twice`);
      const paragraphs = rest
        .join("\n")
        .split(/\n\s*\n/)
        .map((p) => p.replace(/\s*\n\s*/g, " ").trim())
        .filter(Boolean);
      out.set(spell, { spell, title: m[2].trim(), paragraphs, file: `${dir.slice(ROOT.length + 1)}/${f}` });
    }
  }
  return out;
}

const words = (p: Page) => p.paragraphs.join(" ").split(/\s+/).filter(Boolean).length;
const hash = (p: Page) => createHash("sha256").update(p.paragraphs.join("\n\n")).digest("hex").slice(0, 12);
const q = (s: string) => `"${s.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, "\\n")}"`;

// Every dish of either game, and the names every cooking ingredient has in a
// language (the client's, by id, both games' alike).
function dishes(): Map<number, Dish> {
  const all = new Map<number, Dish>();
  for (const game of ["classic", "forever"] as const) for (const d of cookbook(game).dishes) if (!all.has(d.spell)) all.set(d.spell, d);
  return all;
}
function reagentNames(locale: string, ids: number[]): Map<number, string[]> {
  const out = new Map<number, string[]>();
  for (const game of ["classic", "forever"] as const) {
    const db = openDb(game);
    for (const id of ids) {
      const r = db.query("SELECT name FROM name WHERE kind = 'item' AND id = ? AND locale = ?").get(id, locale === "enGB" ? "enUS" : locale) as { name: string } | null;
      if (r && !(out.get(id) ?? []).includes(r.name)) out.set(id, [...(out.get(id) ?? []), r.name]);
    }
    db.close();
  }
  return out;
}

// The ingredients a page names that aren't the recipe's own.
// (compared without case or accents: a page writes "épices fortes" where the
// client writes "Epices fortes", and either is the same ingredient)
const plain = (t: string) => t.normalize("NFD").replace(/\p{M}/gu, "").replace(/[’]/g, "'").toLowerCase();
function strangers(text: string, own: Set<number>, names: Map<number, string[]>): string[] {
  let rest = plain(text);
  const all = [...names].flatMap(([id, ns]) => ns.map((n) => [id, plain(n)] as const)).sort((a, b) => b[1].length - a[1].length);
  const found: string[] = [];
  for (const [id, name] of all) {
    const re = new RegExp(`(^|[^\\p{L}])${name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}(?=$|[^\\p{L}])`, "gu");
    if (!re.test(rest)) continue;
    if (!own.has(id)) found.push(name);
    rest = rest.replace(re, "$1 ");
  }
  return found;
}

function luaFor(locale: string, pages: Record<string, Map<number, Page>>, swaps: Record<string, string>): string {
  const lines = [
    `-- Generated by scripts/pages.ts from ${TRANSLATED.includes(locale) ? `i18n/${locale}/recipes/` : "recipes/"}: edit those, not this file.`,
    "-- pages[chef][spell] = { paragraph, ... }: the chef's page of each dish.",
    "local _, ns = ...",
    "ns.pages = {",
  ];
  for (const chef of CHEFS) {
    lines.push(`  ${chef} = {`);
    for (const p of [...pages[chef].values()].sort((a, b) => a.spell - b.spell))
      lines.push(`    [${p.spell}] = { ${p.paragraphs.map(q).join(", ")} },`);
    lines.push("  },");
  }
  lines.push("}");
  const pairs = Object.entries(swaps);
  lines.push(`-- (the places Classic Era's client names otherwise, swapped in there)`, `ns.classicNames = { ${pairs.map(([a, b]) => `[${q(a)}] = ${q(b)}`).join(", ")} }`);
  return `${lines.join("\n")}\n`;
}

if (import.meta.main) {
  const args = process.argv.slice(2);
  const check = args.includes("--check");
  const all = dishes();
  const reagentIds = [...new Set([...all.values()].flatMap((d) => d.reagents.map(([id]) => id)))];
  const problems: string[] = [];
  const notes: string[] = [];
  const english: Record<string, Map<number, Page>> = {};
  for (const chef of CHEFS) english[chef] = read(join(ROOT, "recipes", chef));

  const verify = (locale: string, chef: string, pages: Map<number, Page>, translated: boolean) => {
    const names = reagentNames(locale, reagentIds);
    for (const p of pages.values()) {
      const d = all.get(p.spell);
      if (!d) {
        problems.push(`${p.file}: ${p.spell} is no dish of either game`);
        continue;
      }
      const text = p.paragraphs.join(" ")
      if (text.includes(";")) problems.push(`${p.file}: ${p.spell}: a semicolon`);
      if (!translated && /[^\x20-\x7e]/.test(text)) problems.push(`${p.file}: ${p.spell}: not plain ASCII`);
      const n = words(p);
      const [lo, hi] = SIGNATURE.has(p.spell) ? [130, 150] : [70, 100];
      const slack = translated ? 1.2 : 1;
      if (n < lo * 0.6 || n > hi * slack * 1.25) problems.push(`${p.file}: ${p.spell}: ${n} words, far from ${lo} to ${hi}`);
      else if (n < lo * 0.9 || n > hi * slack * 1.1) notes.push(`${p.file}: ${p.spell}: ${n} words (${lo} to ${hi})`);
      const odd = strangers(text, new Set(d.reagents.map(([id]) => id)), names);
      if (odd.length) problems.push(`${p.file}: ${p.spell}: names ${odd.map((o) => `"${o}"`).join(", ")}, not this recipe's`);
    }
    // (--partial: while the pages are being written, the missing ones counted, not refused)
    const missing = [...all.keys()].filter((spell) => !pages.has(spell));
    if (missing.length && (translated || args.includes("--partial"))) notes.push(`${chef}${translated ? ` (${locale})` : ""}: ${missing.length} pages to write`);
    else for (const spell of missing) problems.push(`${chef}: no page for ${spell}`);
  };
  for (const chef of CHEFS) verify("enUS", chef, english[chef], false);

  const files: Record<string, string> = {};
  for (const locale of LOCALES) {
    let pages = english;
    let swaps: Record<string, string> = {};
    if (TRANSLATED.includes(locale)) {
      pages = {};
      const stampFile = join(ROOT, "i18n", locale, "recipes-stamp.json");
      const stamps: Record<string, string> = existsSync(stampFile) ? JSON.parse(readFileSync(stampFile, "utf8")) : {};
      const fresh: Record<string, string> = {};
      for (const chef of CHEFS) {
        const mine = read(join(ROOT, "i18n", locale, "recipes", chef));
        verify(locale, chef, mine, true);
        // (a page not translated yet: its English)
        pages[chef] = new Map([...english[chef]].map(([s, p]) => [s, mine.get(s) ?? p]));
        for (const s of mine.keys()) {
          const en = english[chef].get(s);
          if (!en) continue;
          fresh[`${chef}/${s}`] = hash(en);
          if (stamps[`${chef}/${s}`] !== hash(en)) notes.push(`${locale}: ${chef}/${s}: its English changed since it was translated (--stamp once read)`);
        }
      }
      if (args.includes("--stamp")) writeFileSync(stampFile, `${JSON.stringify(fresh, null, 2)}\n`);
      const swapFile = join(ROOT, "i18n", locale, "classic-names.json");
      swaps = existsSync(swapFile) ? JSON.parse(readFileSync(swapFile, "utf8")) : {};
    }
    files[`Pages_${locale}.lua`] = luaFor(locale, pages, swaps);
  }
  for (const n of notes) console.log(`  ${n}`);
  if (problems.length) {
    for (const p of problems) console.error(`✗ ${p}`);
    process.exit(1);
  }
  let stale = false;
  for (const [f, want] of Object.entries(files)) {
    const path = join(ADDON, f);
    const have = existsSync(path) ? readFileSync(path, "utf8") : "";
    if (have === want) continue;
    if (check) {
      console.error(`✗ ${f} is not up to date: bun scripts/pages.ts`);
      stale = true;
    } else writeFileSync(path, want);
  }
  if (stale) process.exit(1);
  const count = (ps: Record<string, Map<number, Page>>) => CHEFS.map((c) => `${c} ${ps[c].size}`).join(", ");
  console.log(`✓ ${all.size} dishes: ${count(english)} pages`);
}
