/**
 * The cookbook's facts, from wow-data's databases (../wow-data, its pinned
 * sources), each game's own:
 *
 *   addon/Mealbook/Recipes_Classic.lua, Recipes_Forever.lua: every dish of
 *     the cooking skill line (185): what it makes and how many, its
 *     ingredients and their counts (the client's SpellReagents), the skill it
 *     is learned at and its colours (orange from the learning, yellow and grey
 *     the client's own trivial ranks, green halfway: the game's window), its
 *     chapter (data/chapters.json), how it is learned (with the skill, a
 *     trainer, a recipe item, a quest: wow-data's recipe_source); and each
 *     recipe item's sources: who sells it (a limited stock said), which
 *     creatures drop it (the Classic database's loot, its templates read
 *     back to their creatures; a world drop through a reference template
 *     said as one), which quests give it.
 *
 * A dish is a spell of the skill line that creates an item (the ranks of
 * Cooking and Classic's campfire make none). Classic Era leaves out a dish
 * its world can't teach (Season of Discovery's, whose recipe items no one
 * sells or drops there; the Crystal Throat Lozenge): a book never shows a
 * page no one can earn. Forever keeps one whose recipe no source has seen
 * yet (its own, before launch: `unknown`), the road never sending anyone
 * after it.
 *
 *   i18n/names.json: the game's own names Mealbook shows or reads in every
 *     language, the client's, for scripts/locales.ts: the cooking skill
 *     line's (Classic Era's skill list names it only so), the chefs', and
 *     each game's npcs and quests the Recipes files name (who sells a
 *     recipe, drops it, gives it), by id.
 *
 *   bun scripts/recipes.ts           write them
 *   bun scripts/recipes.ts --check   fail if one isn't up to date, or a dish
 *                                    has no chapter in data/chapters.json
 */
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { openDb } from "../../wow-data/src/db";

const ROOT = join(import.meta.dir, "..");
const ADDON = join(ROOT, "addon", "Mealbook");
const COOKING = 185;
type Game = "classic" | "forever";
export const CHAPTERS = ["fish", "soup", "meat", "bake", "drink", "feast", "fire"] as const;
type Chapter = (typeof CHAPTERS)[number];

export type Dish = {
  spell: number;
  name: string; // (English, for the script's own messages and the order only: the addon names it by id)
  item: number;
  made: [number, number];
  learn: number;
  yellow: number;
  grey: number;
  chapter: Chapter;
  reagents: [number, number][];
  from: { skill?: true; trainer?: true; items: number[]; quests: number[] };
  unknown?: true;
};
export type RecipeItem = {
  item: number;
  spell: number;
  sold: number[];
  limited: Record<number, number>;
  dropped: number[];
  drops: [number, number][]; // (the likeliest droppers: npc, percent)
  world?: true;
  quests: number[];
};
// Who and where, for the road's vendors and the hunts: a side ("A", "H": the
// faction it serves; none: either, or a creature to kill), the zone (an
// AreaTable id, its name the client's), a spot on its map (0-100, whole),
// the levels, the rank.
export type Npc = { id: number; side?: "A" | "H"; unknown?: true; area?: number; x?: number; y?: number; lvl?: [number, number]; rank?: number };
export type Quest = { id: number; giver?: number; side?: "A" | "H"; level?: number; min?: number; area?: number };

// The capitals: someone friendly to all who stands in one serves its side
// (the Winter Veil's vendors in Orgrimmar or Stormwind).
const CAPITALS: Record<number, "A" | "H"> = { 1519: "A", 16509: "A", 1537: "A", 1657: "A", 1637: "H", 1497: "H", 1638: "H" };
// (a quest's race mask: each playable race's bit and side from the game's own
// ChrRaces, as BigInts: Forever's Skyborne sit on bits 32 and 33)

const chapters = (): Record<string, Chapter> => JSON.parse(readFileSync(join(ROOT, "data", "chapters.json"), "utf8"));

export function cookbook(game: Game) {
  const db = openDb(game);
  const all = <T>(sql: string, ...p: (number | string)[]) => db.query(sql).all(...p) as T[];
  // (how many it makes: Classic Era's client a base and a die, base + 1 to
  // base + sides; Forever's the number itself, EffectBasePointsF)
  const effectCols = new Set(all<{ name: string }>("PRAGMA table_info(client_SpellEffect)").map((c) => c.name));
  const count = effectCols.has("EffectBasePoints") ? "e.EffectBasePoints + 1 least, e.EffectBasePoints + max(1, e.EffectDieSides) most" : "round(e.EffectBasePointsF) least, round(e.EffectBasePointsF) most";
  const rows = all<{ spell: number; yellow: number; grey: number; item: number; least: number; most: number; name: string | null }>(
    `SELECT s.Spell spell, s.TrivialSkillLineRankLow yellow, s.TrivialSkillLineRankHigh grey,
       e.EffectItemType item, ${count}, n.name name
     FROM client_SkillLineAbility s
     JOIN client_SpellEffect e ON e.SpellID = s.Spell AND e.Effect = 24 AND e.EffectItemType > 0
     LEFT JOIN name n ON n.kind = 'spell' AND n.id = s.Spell AND n.locale = 'enUS'
     WHERE s.SkillLine = ? GROUP BY s.Spell`,
    COOKING,
  );
  const sources = all<{ spell_id: number; kind: string; ref_id: number | null; skill_value: number | null }>(
    "SELECT spell_id, kind, ref_id, skill_value FROM recipe_source WHERE skill_line_id = ?",
    COOKING,
  );
  // (a quest's recipe: the skill the quest asks, wow-data's quest.skill_value)
  const questSkill = new Map(
    all<{ id: number; skill_value: number }>("SELECT id, skill_value FROM quest WHERE skill_line_id = ? AND skill_value > 0", COOKING).map((q) => [q.id, q.skill_value]),
  );
  const reagentRows = all<Record<string, number>>(`SELECT * FROM client_SpellReagents WHERE SpellID IN (${rows.map((r) => r.spell).join(",") || 0})`);

  // A recipe item's sources.
  const itemIds = [...new Set(sources.filter((s) => s.kind === "item" && s.ref_id).map((s) => s.ref_id!))];
  const ids = itemIds.join(",") || "0";
  const vendors = all<{ npc_id: number; item_id: number; max_count: number | null }>(`SELECT DISTINCT npc_id, item_id, max_count FROM vendor WHERE item_id IN (${ids})`);
  const rewards = all<{ quest_id: number; ref_id: number }>(`SELECT DISTINCT quest_id, ref_id FROM quest_reward WHERE kind IN ('item', 'choice') AND ref_id IN (${ids})`);
  // (the Classic database's loot: templates, read back to the creatures that
  // carry them; a reference template reached from many: a world drop)
  const loot = all<{ kind: string; source_id: number; item_id: number; source: string; chance: number | null }>(
    `SELECT kind, source_id, item_id, source, chance FROM loot WHERE item_id IN (${ids})`,
  );
  const chance = new Map<string, number>(); // (item:npc, the best percent a source gives)
  const byTemplate = new Map<number, number[]>();
  for (const c of all<{ id: number; loot_id: number }>("SELECT id, loot_id FROM creature WHERE loot_id IS NOT NULL AND loot_id > 0 AND removed IS NOT 1"))
    byTemplate.set(c.loot_id, [...(byTemplate.get(c.loot_id) ?? []), c.id]);
  const items = new Map<number, RecipeItem>();
  const recipeOf = new Map<number, number>();
  for (const s of sources) if (s.kind === "item" && s.ref_id) recipeOf.set(s.ref_id, s.spell_id);
  const itemFor = (id: number) => {
    if (!items.has(id)) items.set(id, { item: id, spell: recipeOf.get(id)!, sold: [], limited: {}, dropped: [], drops: [], quests: [] });
    return items.get(id)!;
  };
  for (const v of vendors) {
    const it = itemFor(v.item_id);
    if (!it.sold.includes(v.npc_id)) it.sold.push(v.npc_id);
    if (v.max_count) it.limited[v.npc_id] = v.max_count;
  }
  for (const r of rewards) if (!itemFor(r.ref_id).quests.includes(r.quest_id)) itemFor(r.ref_id).quests.push(r.quest_id);
  for (const l of loot) {
    const it = itemFor(l.item_id);
    if (l.kind === "reference") it.world = true;
    else if (l.kind === "creature") {
      // (Questie's and Wowhead's are creatures; the Classic database's, templates)
      const creatures = l.source === "classicdb" || l.source === "players" ? (byTemplate.get(l.source_id) ?? []) : [l.source_id];
      for (const c of creatures) {
        if (!it.dropped.includes(c)) it.dropped.push(c);
        // (a negative chance drops only on its quest: no hunt)
        if (l.chance !== null && l.chance > 0) chance.set(`${it.item}:${c}`, Math.max(chance.get(`${it.item}:${c}`) ?? 0, l.chance));
      }
    } else it.world = true; // (an object's, a container's: found, not hunted)
  }
  for (const it of items.values()) {
    it.sold.sort((a, b) => a - b);
    it.dropped.sort((a, b) => a - b);
    it.quests.sort((a, b) => a - b);
  }
  const obtainable = (id: number) => {
    const it = items.get(id);
    return !!it && (it.sold.length > 0 || it.dropped.length > 0 || it.quests.length > 0 || !!it.world);
  };

  const named = chapters();
  const dishes: Dish[] = [];
  const unchaptered: string[] = [];
  for (const r of rows) {
    const mine = sources.filter((s) => s.spell_id === r.spell);
    const from: Dish["from"] = { items: [], quests: [] };
    for (const s of mine) {
      if (s.kind === "skill") from.skill = true;
      else if (s.kind === "trainer") from.trainer = true;
      else if (s.kind === "item" && s.ref_id && !from.items.includes(s.ref_id) && (game === "forever" || obtainable(s.ref_id))) from.items.push(s.ref_id);
      else if (s.kind === "quest" && s.ref_id && !from.quests.includes(s.ref_id)) from.quests.push(s.ref_id);
    }
    from.items.sort((a, b) => a - b);
    const known = from.skill || from.trainer || from.quests.length > 0 || from.items.some(obtainable);
    if (!known && game === "classic") continue;
    const chapter = named[String(r.spell)];
    if (!chapter) {
      unchaptered.push(`${r.spell} ${r.name}`);
      continue;
    }
    if (!CHAPTERS.includes(chapter)) throw new Error(`data/chapters.json: ${r.spell} has no such chapter "${chapter}"`);
    const learned = mine
      .map((s) => s.skill_value ?? (s.kind === "quest" && s.ref_id ? (questSkill.get(s.ref_id) ?? null) : null))
      .filter((v): v is number => v !== null && v > 0);
    const reagents: [number, number][] = [];
    const rr = reagentRows.find((x) => x.SpellID === r.spell);
    for (let i = 0; rr && i < 8; i++) if (rr[`Reagent_${i}`] > 0) reagents.push([rr[`Reagent_${i}`], rr[`ReagentCount_${i}`] || 1]);
    dishes.push({
      spell: r.spell,
      name: r.name ?? String(r.spell),
      item: r.item,
      made: [Math.max(1, r.least), Math.max(1, r.most)],
      learn: learned.length ? Math.min(...learned) : 1,
      yellow: r.yellow,
      grey: r.grey,
      chapter,
      reagents,
      from,
      ...(!known && { unknown: true as const }),
    });
  }
  const used = new Set(dishes.flatMap((d) => d.from.items));
  const kept = [...items.values()].filter((it) => used.has(it.item)).sort((a, b) => a.item - b.item);

  // Who and where. Spawns: each creature's zone (where most of its spawns
  // are) and a spot there.
  // (a zone the client knows: an AreaTable id; Questie names some
  // instances by ids of its own, 10026 for Dire Maul: the instance's own
  // zone then, the one area of its map, from the Classic database's spawn)
  const areas = new Set(all<{ ID: number }>("SELECT ID FROM client_AreaTable").map((r) => r.ID));
  const rootOf = new Map<number, number>();
  for (const r of all<{ map: number; area: number; n: number }>(
    "SELECT ContinentID map, min(ID) area, count(*) n FROM client_AreaTable WHERE ParentAreaID = 0 GROUP BY ContinentID",
  ))
    if (r.n === 1) rootOf.set(r.map, r.area);
  const spawnsOf = (ids: number[]) => {
    const out = new Map<number, { area: number; x: number | null; y: number | null }[]>();
    if (!ids.length) return out;
    const mapOf = new Map<number, number>();
    for (const r of all<{ id: number; map: number }>(
      `SELECT entity_id id, min(map_id) map FROM spawn WHERE kind = 'creature' AND map_id IS NOT NULL AND entity_id IN (${ids.join(",")}) GROUP BY entity_id`,
    ))
      mapOf.set(r.id, r.map);
    for (const r of all<{ id: number; area: number; x: number | null; y: number | null }>(
      `SELECT entity_id id, area_id area, ux x, uy y FROM spawn WHERE kind = 'creature' AND area_id IS NOT NULL AND entity_id IN (${ids.join(",")})`,
    )) {
      const area = areas.has(r.area) ? r.area : rootOf.get(mapOf.get(r.id) ?? -1);
      if (area === undefined) continue;
      // (a spot on the map, 0-100: an instance's -1 is none)
      const onMap = r.x !== null && r.y !== null && r.x >= 0 && r.x <= 100 && r.y >= 0 && r.y <= 100;
      out.set(r.id, [...(out.get(r.id) ?? []), { area, x: onMap ? r.x : null, y: onMap ? r.y : null }]);
    }
    return out;
  };
  // The likeliest droppers: the best chance, then the most spawns (the
  // easiest found).
  const allDroppers = [...new Set(kept.flatMap((it) => it.dropped))];
  const dropSpawns = spawnsOf(allDroppers);
  for (const it of kept) {
    it.drops = it.dropped
      .map((c) => [c, chance.get(`${it.item}:${c}`) ?? 0] as [number, number])
      .filter(([c]) => dropSpawns.has(c))
      .sort((a, b) => b[1] - a[1] || (dropSpawns.get(b[0])?.length ?? 0) - (dropSpawns.get(a[0])?.length ?? 0) || a[0] - b[0])
      .slice(0, 3)
      .map(([c, p]) => [c, Math.round(p * 10) / 10] as [number, number]);
  }
  const questIds = [...new Set([...kept.flatMap((it) => it.quests), ...dishes.flatMap((d) => d.from.quests)])];
  const questRows = questIds.length
    ? all<{ id: number; level: number | null; min_level: number | null; zone_id: number | null; races: number | null }>(
        `SELECT id, level, min_level, zone_id, races FROM quest WHERE id IN (${questIds.join(",")})`,
      )
    : [];
  const giverOf = new Map<number, number>();
  if (questIds.length)
    for (const r of all<{ quest_id: number; entity_id: number }>(
      `SELECT quest_id, min(entity_id) entity_id FROM quest_relation WHERE role = 'start' AND kind = 'creature' AND quest_id IN (${questIds.join(",")}) GROUP BY quest_id`,
    ))
      giverOf.set(r.quest_id, r.entity_id);
  const npcIds = [...new Set([...kept.flatMap((it) => [...it.sold, ...it.drops.map(([c]) => c)]), ...giverOf.values()])].sort((a, b) => a - b);
  const spawns = spawnsOf(npcIds);
  // (Questie's word for the sides a creature is friendly to, where wow-data
  // has it: a creature without a faction template, Forever's new vendors)
  const hasFriendly = all<{ name: string }>("PRAGMA table_info(creature)").some((c) => c.name === "friendly");
  const facts = new Map(
    (npcIds.length
      ? all<{ id: number; min_level: number | null; max_level: number | null; rank: number | null; tmpl: number | null; eg: number | null; en: string | null; friendly: string | null }>(
          `SELECT c.id, c.min_level, c.max_level, c.rank, t.ID tmpl, t.EnemyGroup eg, t.Enemies_0||','||t.Enemies_1||','||t.Enemies_2||','||t.Enemies_3 en,
             ${hasFriendly ? "c.friendly" : "NULL"} friendly
           FROM creature c LEFT JOIN client_FactionTemplate t ON t.ID = c.faction_id WHERE c.id IN (${npcIds.join(",")})`,
        )
      : []
    ).map((r) => [r.id, r]),
  );
  const npcs: Npc[] = [];
  for (const id of npcIds) {
    const f = facts.get(id);
    const here = spawns.get(id) ?? [];
    const byArea = new Map<number, number>();
    for (const sp of here) byArea.set(sp.area, (byArea.get(sp.area) ?? 0) + 1);
    const area = [...byArea].sort((a, b) => b[1] - a[1] || a[0] - b[0])[0]?.[0];
    const spot = here.find((sp) => sp.area === area && sp.x !== null && sp.y !== null);
    // (its side: whom its faction template is hostile to, Alliance's 469 or
    // Horde's 67 among its enemies, or the groups; friendly to both in a
    // capital: that capital's)
    const enemies = (f?.en ?? "").split(",").map(Number);
    const hostileA = !!f && (((f.eg ?? 0) & 2) !== 0 || enemies.includes(469));
    const hostileH = !!f && (((f.eg ?? 0) & 4) !== 0 || enemies.includes(67));
    let side: Npc["side"] = hostileA && !hostileH ? "H" : hostileH && !hostileA ? "A" : undefined;
    if (!f?.tmpl) side = f?.friendly === "A" ? "A" : f?.friendly === "H" ? "H" : undefined;
    if (!hostileA && !hostileH && side === undefined && area !== undefined) side = CAPITALS[area];
    // (no faction template and no source's word: whom it serves is unknown,
    // so no one is sent to it)
    const unknown = !f?.tmpl && !f?.friendly;
    npcs.push({
      id,
      ...(side && { side }),
      ...(unknown && { unknown: true as const }),
      ...(area !== undefined && { area }),
      ...(spot && { x: Math.round(spot.x!), y: Math.round(spot.y!) }),
      ...(f?.min_level && { lvl: [f.min_level, f.max_level ?? f.min_level] as [number, number] }),
      ...(f?.rank && { rank: f.rank }),
    });
  }
  const npcOf = new Map(npcs.map((n) => [n.id, n]));
  for (const it of kept) {
    it.sold = it.sold.filter((v) => !npcOf.get(v)?.unknown);
    for (const v of Object.keys(it.limited).map(Number)) if (npcOf.get(v)?.unknown) delete it.limited[v];
  }
  let allianceRaces = 0n, hordeRaces = 0n;
  for (const r of all<{ bit: number; side: number }>("SELECT PlayableRaceBit bit, Alliance side FROM client_ChrRaces WHERE PlayableRaceBit >= 0")) {
    if (r.side === 0) allianceRaces |= 1n << BigInt(r.bit);
    else if (r.side === 1) hordeRaces |= 1n << BigInt(r.bit);
  }
  const quests: Quest[] = questRows
    .map((q) => {
      const giver = giverOf.get(q.id);
      const races = BigInt(q.races ?? 0);
      const a = (races & allianceRaces) !== 0n, h = (races & hordeRaces) !== 0n;
      const side: Quest["side"] = a && !h ? "A" : h && !a ? "H" : giver !== undefined ? npcOf.get(giver)?.side : undefined;
      const area = q.zone_id && q.zone_id > 0 ? q.zone_id : giver !== undefined ? npcOf.get(giver)?.area : undefined;
      return {
        id: q.id,
        ...(giver !== undefined && { giver }),
        ...(side && { side }),
        ...(q.level && q.level > 0 && { level: q.level }),
        ...(q.min_level && q.min_level > 0 && { min: q.min_level }),
        ...(area && { area }),
      };
    })
    .sort((a, b) => a.id - b.id);
  db.close();
  // (the npcs something still names: a seller no one is sent to, gone)
  const pointed = new Set<number>([...kept.flatMap((it) => [...it.sold, ...it.drops.map(([c]) => c)]), ...quests.flatMap((q) => (q.giver ? [q.giver] : []))]);
  // (the book's order: by the skill a dish is learned at, its yellow, its name)
  dishes.sort((a, b) => a.learn - b.learn || a.yellow - b.yellow || a.name.localeCompare(b.name));
  return { dishes, items: kept, npcs: npcs.filter((n) => pointed.has(n.id)), quests, unchaptered };
}

const list = (xs: number[]) => `{ ${xs.join(", ")} }`;

export function lua(game: Game): string {
  const { dishes, items, npcs, quests } = cookbook(game);
  const out = [
    `-- Generated by scripts/recipes.ts from wow-data's ${game === "classic" ? "Classic Era" : "Forever"} database: edit the script or data/chapters.json, not this file.`,
    "-- recipes[spell]: what it makes (item, made = { least, most }), the skill it is",
    "-- learned at and its colours (learn, yellow, grey: green is halfway), its",
    "-- chapter, its ingredients (item, count, item, count...), how it is learned",
    "-- (skill, trainer, items: recipe items, quests), unknown: no source seen yet.",
    "-- recipeItems[item]: the recipe it teaches, who sells it (limited: [npc] =",
    "-- the stock), who drops it (drops: the likeliest, npc, percent...; world: a",
    "-- drop of many), the quests that give it.",
    "-- npcs[id]: the sellers, the likeliest droppers, the quest givers: side (A, H:",
    "-- the faction it serves), area (its zone), x, y (a spot there), lvl, rank.",
    "-- quests[id]: giver, side, level, min (the level it opens at), area.",
    "local _, ns = ...",
    "ns.data = {",
    `  skillLine = ${COOKING},`,
    "  order = {",
    ...chunk(dishes.map((d) => d.spell)).map((c) => `    ${c.join(", ")},`),
    "  },",
    "  recipes = {",
  ];
  for (const d of dishes) {
    const f = d.from;
    const parts = [
      `item = ${d.item}`,
      `made = { ${d.made[0]}, ${d.made[1]} }`,
      `learn = ${d.learn}`,
      `yellow = ${d.yellow}`,
      `grey = ${d.grey}`,
      `chapter = "${d.chapter}"`,
      `reagents = ${list(d.reagents.flat())}`,
    ];
    if (f.skill) parts.push("skill = true");
    if (f.trainer) parts.push("trainer = true");
    if (f.items.length) parts.push(`items = ${list(f.items)}`);
    if (f.quests.length) parts.push(`quests = ${list(f.quests)}`);
    if (d.unknown) parts.push("unknown = true");
    out.push(`    [${d.spell}] = { ${parts.join(", ")} }, -- ${d.name}`);
  }
  out.push("  },", "  recipeItems = {");
  for (const it of items) {
    const parts = [`spell = ${it.spell}`];
    if (it.sold.length) parts.push(`sold = ${list(it.sold)}`);
    const limited = Object.entries(it.limited);
    if (limited.length) parts.push(`limited = { ${limited.map(([npc, n]) => `[${npc}] = ${n}`).join(", ")} }`);
    if (it.dropped.length) parts.push(`dropped = ${list(it.dropped.slice(0, 40))}`);
    if (it.drops.length) parts.push(`drops = ${list(it.drops.flat())}`);
    if (it.world) parts.push("world = true");
    if (it.quests.length) parts.push(`quests = ${list(it.quests)}`);
    out.push(`    [${it.item}] = { ${parts.join(", ")} },`);
  }
  out.push("  },", "  npcs = {");
  for (const n of npcs) {
    const parts: string[] = [];
    if (n.side) parts.push(`side = "${n.side}"`);
    if (n.area) parts.push(`area = ${n.area}`);
    if (n.x !== undefined) parts.push(`x = ${n.x}`, `y = ${n.y}`);
    if (n.lvl) parts.push(`lvl = { ${n.lvl[0]}, ${n.lvl[1]} }`);
    if (n.rank) parts.push(`rank = ${n.rank}`);
    out.push(`    [${n.id}] = { ${parts.join(", ")} },`);
  }
  out.push("  },", "  quests = {");
  for (const q of quests) {
    const parts: string[] = [];
    if (q.giver) parts.push(`giver = ${q.giver}`);
    if (q.side) parts.push(`side = "${q.side}"`);
    if (q.level) parts.push(`level = ${q.level}`);
    if (q.min) parts.push(`min = ${q.min}`);
    if (q.area) parts.push(`area = ${q.area}`);
    out.push(`    [${q.id}] = { ${parts.join(", ")} },`);
  }
  out.push("  },", "}");
  return `${out.join("\n")}\n`;
}

function chunk(xs: number[], n = 10): number[][] {
  const out: number[][] = [];
  for (let i = 0; i < xs.length; i += n) out.push(xs.slice(i, i + n));
  return out;
}

// The game's own names in every language the game has, the client's: the
// cooking skill line's (Classic Era's skill list names a skill only by its
// name), the chefs' (their creatures'), for scripts/locales.ts to put in each
// language's Text file.
const LOCALES = ["enUS", "enGB", "deDE", "frFR", "esES", "esMX", "ruRU", "ptBR", "itIT", "koKR", "zhCN", "zhTW"];
export const CHEF_NPCS = { kendor: 340, eunice: 4552 };
export type Names = {
  skillLine: string;
  kendor: string;
  eunice: string;
  // (each game's: the npcs and quests its Recipes file names, by id; a
  // creature's name in every language, a quest's where the language has it:
  // none, and the page says "a quest from" its giver)
  npcs: Record<Game, Record<string, string>>;
  quests: Record<Game, Record<string, string>>;
};
export function gameNames(): Record<string, Names> {
  const games: Record<Game, ReturnType<typeof cookbook>> = { classic: cookbook("classic"), forever: cookbook("forever") };
  const byLocale = (db: ReturnType<typeof openDb>, kind: string, ids: number[]) => {
    const out = new Map<string, Record<string, string>>();
    if (!ids.length) return out;
    for (const r of db.query(`SELECT locale, id, name FROM name WHERE kind = ? AND id IN (${ids.join(",")})`).all(kind) as { locale: string; id: number; name: string }[]) {
      const m = out.get(r.locale) ?? {};
      m[r.id] = r.name;
      out.set(r.locale, m);
    }
    return out;
  };
  const db = openDb("classic");
  const named = (kind: string, id: number) =>
    Object.fromEntries((db.query("SELECT locale, name FROM name WHERE kind = ? AND id = ?").all(kind, id) as { locale: string; name: string }[]).map((r) => [r.locale, r.name]));
  const skill = named("skill_line", COOKING);
  const chefs = Object.fromEntries(Object.entries(CHEF_NPCS).map(([chef, npc]) => [chef, named("creature", npc)]));
  db.close();
  const per: Record<Game, { npcs: Map<string, Record<string, string>>; quests: Map<string, Record<string, string>>; npcIds: number[] }> = {} as never;
  for (const game of ["classic", "forever"] as Game[]) {
    const g = openDb(game);
    const npcIds = games[game].npcs.map((n) => n.id);
    per[game] = { npcs: byLocale(g, "creature", npcIds), quests: byLocale(g, "quest", games[game].quests.map((q) => q.id)), npcIds };
    g.close();
  }
  const out: Record<string, Names> = {};
  for (const l of LOCALES) {
    const own = l === "enGB" ? "enUS" : l;
    const from = (by: Record<string, string>) => by[own];
    const entry: Names = { skillLine: from(skill)!, kendor: from(chefs.kendor)!, eunice: from(chefs.eunice)!, npcs: { classic: {}, forever: {} }, quests: { classic: {}, forever: {} } };
    for (const k of ["skillLine", "kendor", "eunice"] as const) if (!entry[k]) throw new Error(`no ${k} name in ${l}`);
    for (const game of ["classic", "forever"] as Game[]) {
      const npcs = per[game].npcs.get(own) ?? {};
      const missing = per[game].npcIds.filter((id) => !npcs[id]);
      // (a creature unnamed in a language: the family's rule, no English in its place)
      if (missing.length) throw new Error(`${game}: no ${l} name for creature ${missing.slice(0, 5).join(", ")}${missing.length > 5 ? "..." : ""}`);
      entry.npcs[game] = Object.fromEntries(per[game].npcIds.map((id) => [id, npcs[id]]));
      entry.quests[game] = per[game].quests.get(own) ?? {};
    }
    out[l] = entry;
  }
  return out;
}

if (import.meta.main) {
  const check = process.argv.includes("--check");
  let bad = false;
  {
    const path = join(ROOT, "i18n", "names.json");
    const want = `${JSON.stringify(gameNames(), null, 2)}\n`;
    const have = existsSync(path) ? readFileSync(path, "utf8") : "";
    if (have !== want) {
      if (check) {
        console.error("✗ i18n/names.json is not up to date: bun scripts/recipes.ts");
        bad = true;
      } else writeFileSync(path, want);
    }
  }
  for (const [game, file] of [
    ["classic", "Recipes_Classic.lua"],
    ["forever", "Recipes_Forever.lua"],
  ] as const) {
    const { dishes, unchaptered } = cookbook(game);
    if (unchaptered.length) {
      console.error(`✗ ${game}: no chapter in data/chapters.json for ${unchaptered.join(", ")}`);
      bad = true;
      continue;
    }
    const want = lua(game);
    const path = join(ADDON, file);
    const have = existsSync(path) ? readFileSync(path, "utf8") : "";
    if (have === want) console.log(`✓ ${file}: ${dishes.length} dishes${dishes.some((d) => d.unknown) ? `, ${dishes.filter((d) => d.unknown).length} with no source seen yet` : ""}`);
    else if (check) {
      console.error(`✗ ${file} is not up to date: bun scripts/recipes.ts`);
      bad = true;
    } else {
      writeFileSync(path, want);
      console.log(`wrote ${file}: ${dishes.length} dishes`);
    }
  }
  if (bad) process.exit(1);
}
