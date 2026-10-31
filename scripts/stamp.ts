/**
 * --stamp's languages: `--stamp frFR [deDE …]` or `--stamp all`. A stamp says
 * "this translation was read against this English", so one language's read
 * never marks another's current: a bare --stamp is refused.
 */
export function stampLocales(args: string[], translated: string[]): string[] | string {
  const at = args.indexOf("--stamp");
  if (at < 0) return [];
  const given: string[] = [];
  for (const a of args.slice(at + 1)) {
    if (a.startsWith("--")) break;
    given.push(a);
  }
  if (!given.length) return `--stamp takes a language (${translated.join(", ")}) or "all": a stamp is one language's read`;
  if (given.includes("all")) return given.length === 1 ? [...translated] : `--stamp: "all" stands alone`;
  const unknown = given.filter((l) => !translated.includes(l));
  if (unknown.length) return `--stamp: ${unknown.join(", ")} is not a translated language (${translated.join(", ")})`;
  return given;
}
