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
import type * as WowDb from "../../wow-data/src/db";
import { familyPath } from "./root";

// through the family folder, from a worktree too (scripts/root.ts)
const { openDb } = (await import(familyPath("wow-data", "src", "db.ts"))) as typeof WowDb;

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
export type Npc = {
  id: number;
  side?: "A" | "H";
  unknown?: true;
  area?: number;
  map?: number; // (its zone's continent or instance: AreaTable's ContinentID, for the nearest)
  city?: true; // (it stands in a capital)
  x?: number;
  y?: number;
  lvl?: [number, number];
  rank?: number;
};
export type Quest = { id: number; giver?: number; side?: "A" | "H"; level?: number; min?: number; area?: number };
// Where an ingredient comes from: who sells it (as many as a side needs to
// find one near: the capitals first, then a zone each), the likeliest
// creatures to drop it (npc, percent), the zones it is fished in (a zone's
// fishing, a school's pools), the Herbalism a node of it asks and the zones
// the nodes grow in, the containers it is found in (a clam), the zones it is
// picked up in (a chest of the world: a giant clam, a pod).
export type Ingredient = {
  item: number;
  sold: number[];
  drops: [number, number][];
  fished: number[];
  fishing?: true; // (caught fishing, where no source says)
  herb?: number;
  herbZones: number[];
  inside: number[];
  picked: number[];
};
// A zone named by the ingredients: its continent and the side it belongs to.
export type Zone = { id: number; map: number; side?: "A" | "H" };

// A rank of the skill (its cap: 75 Apprentice, 150 Journeyman, 225 Expert,
// 300 Artisan): its spell and what teaches it, trainers, a book and who
// sells it, quests; the level and the skill it asks.
export type Rank = { cap: number; spell: number; trainers: number[]; items: number[]; sellers: number[]; quests: number[]; level?: number; skill?: number };

// The capitals: someone friendly to all who stands in one serves its side
// (the Winter Veil's vendors in Orgrimmar or Stormwind).
const CAPITALS: Record<number, "A" | "H"> = { 1519: "A", 16509: "A", 1537: "A", 1657: "A", 1637: "H", 1497: "H", 1638: "H" };
// (a quest's race mask: each playable race's bit and side from the game's own
// ChrRaces, as BigInts: Forever's Skyborne sit on bits 32 and 33)

const chapters = (): Record<string, Chapter> => JSON.parse(readFileSync(join(ROOT, "data", "chapters.json"), "utf8"));

export function cookbook(game: Game) {
  const db = openDb(game);
  const all = <T>(sql: string, ...p: (number | string)[]) => db.query(sql).all(...p) as T[];
  // (a loot row's chance as the game rolls it: the Classic database's nought
  // in a group is an equal share of what the group's own chances leave, a
  // fishing table's Brilliant Smallfish 59 in a hundred; a negative chance
  // drops only on its quest, none)
  const shares = new Map<string, number>();
  const chanceOf = (l: { kind: string; source_id: number; chance: number | null; group_id: number | null; source: string }) => {
    if (l.chance === null || l.chance < 0) return 0;
    if (l.chance > 0 || !l.group_id || l.source !== "classicdb") return l.chance;
    const key = `${l.kind}:${l.source_id}:${l.group_id}`;
    if (!shares.has(key)) {
      const g = all<{ s: number | null; z: number }>(
        "SELECT sum(CASE WHEN chance > 0 THEN chance END) s, sum(chance = 0) z FROM loot WHERE kind = ? AND source_id = ? AND group_id = ? AND source = 'classicdb'",
        l.kind,
        l.source_id,
        l.group_id,
      )[0];
      shares.set(key, g && g.z > 0 ? Math.max(0, 100 - (g.s ?? 0)) / g.z : 0);
    }
    return shares.get(key)!;
  };
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
  // (where no source gives one: the lowest skill the client's recipe items
  // teaching the dish ask, ItemSparse's RequiredSkillRank, whether or not a
  // source has the item: Season of Discovery's in Forever, 20 October 2026)
  const itemSkill = new Map<number, number>();
  for (const r of all<{ spell: number; skill: number }>(
    `SELECT spell, MIN(skill) AS skill FROM (
       SELECT i.spell_id AS spell, s.RequiredSkillRank AS skill FROM item_spell i JOIN client_ItemSparse s ON s.ID = i.item_id
        WHERE i.trigger = 6 AND s.RequiredSkill = ? AND s.RequiredSkillRank > 0
       UNION ALL
       SELECT t.taught_spell_id, s.RequiredSkillRank FROM teaching t JOIN item_spell i ON i.spell_id = t.spell_id JOIN client_ItemSparse s ON s.ID = i.item_id
        WHERE s.RequiredSkill = ? AND s.RequiredSkillRank > 0
     ) GROUP BY spell`,
    COOKING,
    COOKING,
  ))
    itemSkill.set(r.spell, r.skill);
  const reagentRows = all<Record<string, number>>(`SELECT * FROM client_SpellReagents WHERE SpellID IN (${rows.map((r) => r.spell).join(",") || 0})`);

  // A recipe item's sources.
  const itemIds = [...new Set(sources.filter((s) => s.kind === "item" && s.ref_id).map((s) => s.ref_id!))];
  const ids = itemIds.join(",") || "0";
  const vendors = all<{ npc_id: number; item_id: number; max_count: number | null }>(`SELECT DISTINCT npc_id, item_id, max_count FROM vendor WHERE item_id IN (${ids})`);
  const rewards = all<{ quest_id: number; ref_id: number }>(`SELECT DISTINCT quest_id, ref_id FROM quest_reward WHERE kind IN ('item', 'choice') AND ref_id IN (${ids})`);
  // (the Classic database's loot: templates, read back to the creatures that
  // carry them; a reference template reached from many: a world drop)
  const loot = all<{ kind: string; source_id: number; item_id: number; source: string; chance: number | null; group_id: number | null }>(
    `SELECT kind, source_id, item_id, source, chance, group_id FROM loot WHERE item_id IN (${ids})`,
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
        const p = chanceOf(l);
        if (p > 0) chance.set(`${it.item}:${c}`, Math.max(chance.get(`${it.item}:${c}`) ?? 0, p));
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
      learn: learned.length ? Math.min(...learned) : (itemSkill.get(r.spell) ?? 1),
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

  // The ranks: the skill line's spells that set its cap (effect 118, its
  // value the tier: Classic Era's base points and a die of one, Forever's the
  // number), what teaches each (the spells whose effect 36 learns it: a
  // trainer's lesson, a book's use, a quest's cast), and what that asks.
  const tierOf = effectCols.has("EffectBasePoints") ? "e.EffectBasePoints + 1" : "round(e.EffectBasePointsF)";
  const ranks: Rank[] = [];
  for (const r of all<{ spell: number; tier: number }>(
    `SELECT s.Spell spell, ${tierOf} tier FROM client_SkillLineAbility s JOIN client_SpellEffect e ON e.SpellID = s.Spell AND e.Effect = 118 WHERE s.SkillLine = ? ORDER BY tier`,
    COOKING,
  )) {
    const teach = [r.spell, ...all<{ s: number }>("SELECT SpellID s FROM client_SpellEffect WHERE Effect = 36 AND EffectTriggerSpell = ?", r.spell).map((x) => x.s)];
    const list = teach.join(",");
    const trainerRows = all<{ npc: number; level: number | null; skill: number | null }>(
      `SELECT npc_id npc, level, skill_value skill FROM trainer_spell WHERE spell_id IN (${list})`,
    );
    const itemRows = all<{ item: number; level: number | null; skill: number | null }>(
      `SELECT DISTINCT i.item_id item, p.RequiredLevel level, p.RequiredSkillRank skill FROM item_spell i LEFT JOIN client_ItemSparse p ON p.ID = i.item_id WHERE i.spell_id IN (${list})`,
    );
    const sellers = new Set<number>();
    const items: number[] = [];
    for (const it of itemRows) {
      const sold = all<{ npc: number }>("SELECT DISTINCT npc_id npc FROM vendor WHERE item_id = ?", it.item).map((x) => x.npc);
      // (a book no one sells: no way to it, left out)
      if (!sold.length) continue;
      items.push(it.item);
      for (const v of sold) sellers.add(v);
    }
    const questRows = all<{ id: number; level: number | null; skill: number | null }>(
      `SELECT DISTINCT q.id, q.min_level level, q.skill_value skill FROM quest_reward r JOIN quest q ON q.id = r.quest_id
       WHERE r.kind IN ('spell', 'cast') AND r.ref_id IN (${list}) AND q.removed IS NOT 1`,
    );
    const asks = (rows: { level: number | null; skill: number | null }[], k: "level" | "skill") => {
      const v = rows.map((x) => x[k] ?? 0).filter((x) => x > 0);
      return v.length ? Math.min(...v) : undefined;
    };
    const used = [...trainerRows, ...itemRows.filter((it) => items.includes(it.item)), ...questRows];
    ranks.push({
      cap: 75 * r.tier,
      spell: r.spell,
      trainers: [...new Set(trainerRows.map((x) => x.npc))].sort((a, b) => a - b),
      items,
      sellers: [...sellers].sort((a, b) => a - b),
      quests: [...new Set(questRows.map((x) => x.id))].sort((a, b) => a - b),
      ...(asks(used, "level") && { level: asks(used, "level") }),
      ...(asks(used, "skill") && { skill: asks(used, "skill") }),
    });
  }

  // (one rank a cap: Forever's client has a second chain of Cooking ranks
  // that nothing teaches, its own profession's: the one something teaches)
  const taught = (r: Rank) => r.trainers.length + r.items.length + r.quests.length > 0;
  for (let i = ranks.length - 1; i >= 0; i--) {
    const twin = ranks.find((o, j) => j !== i && o.cap === ranks[i].cap);
    if (twin && (!taught(ranks[i]) || (taught(twin) && ranks.indexOf(twin) < i))) ranks.splice(i, 1);
  }

  // The ingredients' sources.
  const ingredientIds = [...new Set(dishes.flatMap((d) => d.reagents.map(([i]) => i)))].sort((a, b) => a - b);
  const zoneParent = new Map(
    all<{ id: number; parent: number; map: number; mask: number }>("SELECT ID id, ParentAreaID parent, ContinentID map, FactionGroupMask mask FROM client_AreaTable").map((r) => [r.id, r]),
  );
  // (a subzone's zone: up its parents to the top)
  const zoneOf = (area: number) => {
    let a = area;
    for (let i = 0; i < 5 && (zoneParent.get(a)?.parent ?? 0) > 0; i++) a = zoneParent.get(a)!.parent;
    return zoneParent.has(a) ? a : undefined;
  };
  const objectsByTemplate = new Map<number, number[]>();
  const objectType = new Map<number, number>();
  for (const o of all<{ id: number; type: number | null; loot_id: number | null }>("SELECT id, type, loot_id FROM object")) {
    if (o.type !== null) objectType.set(o.id, o.type);
    if (o.loot_id) objectsByTemplate.set(o.loot_id, [...(objectsByTemplate.get(o.loot_id) ?? []), o.id]);
  }
  // (a battleground's, an arena's: a creature there no cook's road)
  const pvpMaps = new Set(all<{ id: number }>("SELECT ID id FROM client_Map WHERE InstanceType IN (3, 4)").map((r) => r.id));
  const herbNodes = new Map<number, number>();
  const gatheredObjects = new Set<number>();
  for (const g of all<{ id: number; skill_line_id: number; min_skill: number }>("SELECT object_id id, skill_line_id, min_skill FROM gathering_node")) {
    gatheredObjects.add(g.id);
    if (g.skill_line_id === 182) herbNodes.set(g.id, Math.min(herbNodes.get(g.id) ?? Infinity, g.min_skill));
  }
  const vendorCandidates = new Map<number, number[]>();
  const ingredients: Ingredient[] = [];
  const zoneIds = new Set<number>();
  const ingredientDroppers: number[] = [];
  for (const item of ingredientIds) {
    const sold = all<{ npc: number }>("SELECT DISTINCT npc_id npc FROM vendor WHERE item_id = ? AND max_count IS NULL", item).map((r) => r.npc);
    vendorCandidates.set(item, sold);
    // (who sells it, any stock: Questie's drops name an innkeeper's wares)
    const sells = new Set(all<{ npc: number }>("SELECT DISTINCT npc_id npc FROM vendor WHERE item_id = ?", item).map((r) => r.npc));
    // (droppers: the Classic database's templates read back to their creatures,
    // Questie's and Wowhead's creatures; the best chance each)
    const best = new Map<number, number>();
    for (const l of all<{ kind: string; source_id: number; chance: number | null; group_id: number | null; source: string }>(
      "SELECT kind, source_id, chance, group_id, source FROM loot WHERE kind = 'creature' AND item_id = ? AND (chance IS NULL OR chance >= 0)",
      item,
    )) {
      const creatures = l.source === "classicdb" || l.source === "players" ? (byTemplate.get(l.source_id) ?? []) : [l.source_id];
      for (const c of creatures) if (!sells.has(c)) best.set(c, Math.max(best.get(c) ?? 0, chanceOf(l)));
    }
    // (fishing: a zone's table, or the template it references)
    const fishedAreas = new Map<number, number>();
    for (const f of all<{ area: number; kind: string; source_id: number; chance: number | null; group_id: number | null; source: string; rs: number | null; rc: number | null; rg: number | null }>(
      `SELECT f.source_id area, f.kind, f.source_id, f.chance, f.group_id, f.source, r.source_id rs, r.chance rc, r.group_id rg
       FROM loot f LEFT JOIN loot r ON r.kind = 'reference' AND r.source_id = f.ref_id AND r.item_id = ?
       WHERE f.kind = 'fishing' AND (f.item_id = ? OR r.item_id IS NOT NULL)`,
      item,
      item,
    )) {
      const z = zoneOf(f.area);
      const p = f.rs !== null ? (chanceOf(f) * chanceOf({ kind: "reference", source_id: f.rs, chance: f.rc, group_id: f.rg, source: f.source })) / 100 : chanceOf(f);
      if (z !== undefined) fishedAreas.set(z, Math.max(fishedAreas.get(z) ?? 0, p));
    }
    // (the objects whose loot holds it, the likeliest chance each: a row of
    // their own or of a template theirs references; the Classic database's
    // by their template, Questie's and Wowhead's by the object; `own`, the
    // chance a row gives it by name, not a share of a treasure's goods)
    const holders = new Map<number, number>();
    const own = new Map<number, number>();
    const hold = (source: string, id: number, p: number, named: number) => {
      for (const o of source === "classicdb" || source === "players" ? (objectsByTemplate.get(id) ?? []) : [id]) {
        holders.set(o, Math.max(holders.get(o) ?? 0, p));
        own.set(o, Math.max(own.get(o) ?? 0, named));
      }
    };
    for (const l of all<{ kind: string; source_id: number; chance: number | null; group_id: number | null; source: string }>(
      "SELECT kind, source_id, chance, group_id, source FROM loot WHERE kind = 'object' AND item_id = ? AND (chance IS NULL OR chance >= 0)",
      item,
    ))
      hold(l.source, l.source_id, chanceOf(l), l.chance ?? 0);
    for (const l of all<{ kind: string; source_id: number; chance: number | null; group_id: number | null; source: string; rs: number; rc: number | null; rg: number | null }>(
      `SELECT p.kind, p.source_id, p.chance, p.group_id, p.source, r.source_id rs, r.chance rc, r.group_id rg FROM loot r
       JOIN loot p ON p.kind = 'object' AND p.ref_id = r.source_id WHERE r.kind = 'reference' AND r.item_id = ? AND (r.chance IS NULL OR r.chance >= 0)`,
      item,
    ))
      hold(
        l.source,
        l.source_id,
        (chanceOf(l) * chanceOf({ kind: "reference", source_id: l.rs, chance: l.rc, group_id: l.rg, source: l.source })) / 100,
        ((l.chance ?? 0) * (l.rc ?? 0)) / 100,
      );
    const zonesOf = (objects: number[], into: Map<number, number>) => {
      if (objects.length)
        for (const r of all<{ area: number; n: number }>(
          `SELECT area_id area, count(*) n FROM spawn WHERE kind = 'object' AND area_id IS NOT NULL AND entity_id IN (${objects.join(",")}) GROUP BY area_id`,
        )) {
          const z = zoneOf(r.area);
          if (z !== undefined) into.set(z, (into.get(z) ?? 0) + r.n);
        }
    };
    // (a school's pools: objects of type 25, a fishing hole, where it is
    // fished too; Questie's Fishing Bobber, 35591, holding it: caught
    // fishing, no zone said)
    const fishedObjects = [...holders.keys()].filter((o) => objectType.get(o) === 25 || o === 35591);
    const schoolZones = new Map<number, number>();
    zonesOf(
      fishedObjects.filter((o) => objectType.get(o) === 25),
      schoolZones,
    );
    for (const z of schoolZones.keys()) if (!fishedAreas.has(z)) fishedAreas.set(z, 0);
    // (a container it is found in: a clam, the likeliest first; one in ten at
    // least by its own chance, not a lockbox's odd herb or a share of its
    // goods)
    const insideAt = new Map<number, number>();
    for (const l of all<{ source_id: number; chance: number }>("SELECT source_id, chance FROM loot WHERE kind = 'item' AND item_id = ? AND chance > 0", item))
      insideAt.set(l.source_id, Math.max(insideAt.get(l.source_id) ?? 0, l.chance));
    const inside = [...insideAt]
      .filter(([, p]) => p >= 10)
      .sort((a, b) => b[1] - a[1] || a[0] - b[0])
      .slice(0, 2)
      .map(([i]) => i);
    // (herbs: the nodes whose loot holds it, their Herbalism, where they grow)
    const nodes = [...holders].filter(([o, p]) => p > 0 && herbNodes.has(o)).map(([o]) => ({ id: o, skill: herbNodes.get(o)! }));
    const herbCount = new Map<number, number>();
    zonesOf(
      nodes.map((n) => n.id),
      herbCount,
    );
    // (picked up: a chest of the world, type 3, no skill's gathering node,
    // holding it one time in ten at least by its own chance: a giant clam, a
    // pod, not a treasure chest's share of food; where most of them stand)
    const pickedCount = new Map<number, number>();
    zonesOf(
      [...own].filter(([o, p]) => p >= 10 && objectType.get(o) === 3 && !gatheredObjects.has(o)).map(([o]) => o),
      pickedCount,
    );
    // (every zone, the likeliest first: the book shows the cook's nearest)
    const fished = [...fishedAreas].sort((a, b) => b[1] - a[1] || a[0] - b[0]).map(([z]) => z);
    const herbZones = [...herbCount].sort((a, b) => b[1] - a[1] || a[0] - b[0]).map(([z]) => z);
    const picked = [...pickedCount].sort((a, b) => b[1] - a[1] || a[0] - b[0]).map(([z]) => z);
    for (const z of [...fished, ...herbZones, ...picked]) zoneIds.add(z);
    const drops = [...best].map(([c, p]) => [c, p] as [number, number]);
    ingredientDroppers.push(...drops.map(([c]) => c));
    ingredients.push({
      item,
      sold,
      drops,
      fished,
      ...(nodes.length && { herb: Math.min(...nodes.map((n) => n.skill)) }),
      herbZones,
      inside,
      picked,
      ...(fishedObjects.length > 0 && fished.length === 0 && { fishing: true as const }),
    });
  }
  // (an ingredient's sellers and droppers named in every language, else no
  // help: Forever's new creatures some traces leave nameless)
  const ingredientNpcs = [...new Set(ingredients.flatMap((i) => [...i.sold, ...i.drops.map(([c]) => c)]))];
  const namedAll = new Set(
    ingredientNpcs.length
      ? all<{ id: number }>(
          `SELECT id FROM name WHERE kind = 'creature' AND locale IN (${LOCALES.filter((l) => l !== "enGB").map((l) => `'${l}'`).join(",")})
           AND id IN (${ingredientNpcs.join(",")}) GROUP BY id HAVING count(DISTINCT locale) = ${LOCALES.length - 1}`,
        ).map((r) => r.id)
      : [],
  );

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
  const questIds = [...new Set([...kept.flatMap((it) => it.quests), ...dishes.flatMap((d) => d.from.quests), ...ranks.flatMap((r) => r.quests)])];
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
  const npcIds = [
    ...new Set([
      ...kept.flatMap((it) => [...it.sold, ...it.drops.map(([c]) => c)]),
      ...giverOf.values(),
      ...ranks.flatMap((r) => [...r.trainers, ...r.sellers]),
      ...[...vendorCandidates.values()].flat(),
      ...ingredientDroppers,
    ]),
  ].sort((a, b) => a - b);
  const spawns = spawnsOf(npcIds);
  // (Questie's word for the sides a creature is friendly to, where wow-data
  // has it: a creature without a faction template, Forever's new vendors)
  const hasFriendly = all<{ name: string }>("PRAGMA table_info(creature)").some((c) => c.name === "friendly");
  const facts = new Map(
    (npcIds.length
      ? all<{ id: number; min_level: number | null; max_level: number | null; rank: number | null; tmpl: number | null; eg: number | null; en: string | null; fg: number | null; fr: string | null; nf: number | null; g: number | null; friendly: string | null }>(
          `SELECT c.id, c.min_level, c.max_level, c.rank, t.ID tmpl, t.EnemyGroup eg, t.Enemies_0||','||t.Enemies_1||','||t.Enemies_2||','||t.Enemies_3 en,
             c.npc_flags nf, t.FactionGroup g, t.FriendGroup fg, t.Friend_0||','||t.Friend_1||','||t.Friend_2||','||t.Friend_3||','||t.Friend_4||','||t.Friend_5||','||t.Friend_6||','||t.Friend_7 fr,
             ${hasFriendly ? "c.friendly" : "NULL"} friendly
           FROM creature c LEFT JOIN client_FactionTemplate t ON t.ID = c.faction_id WHERE c.id IN (${npcIds.join(",")})`,
        )
      : []
    ).map((r) => [r.id, r]),
  );
  const continentOf = new Map(all<{ id: number; map: number }>("SELECT ID id, ContinentID map FROM client_AreaTable").map((r) => [r.id, r.map]));
  const npcs: Npc[] = [];
  // (someone's people, no one's prey for a meal: a member of a side (the
  // template's group: the Warsong's scouts, Theramore's guards), one who
  // talks and isn't hostile to every player (a quest giver, a vendor: the
  // Classic database gives the Barrens' quest givers clam meat; a Dredge
  // Crusher's gossip no shield), friends with both; one only hostile to a
  // side, Dalaran's in Alterac, that side's prey, the book's to sort;
  // Questie's "friendly" means no more than not hostile, a boar's too)
  const peaceful = new Set<number>();
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
    const friends = (f?.fr ?? "").split(",").map(Number);
    if (((f?.g ?? 0) & 6) !== 0 || ((f?.nf ?? 0) !== 0 && ((f?.eg ?? 0) & 1) === 0) || ((f?.fg ?? 0) & 6) === 6 || (friends.includes(469) && friends.includes(67))) peaceful.add(id);
    npcs.push({
      id,
      ...(side && { side }),
      ...(unknown && { unknown: true as const }),
      ...(area !== undefined && { area }),
      ...(area !== undefined && continentOf.has(area) && { map: continentOf.get(area) }),
      ...(area !== undefined && CAPITALS[area] && { city: true as const }),
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
  // (an ingredient's sellers: those a side can be sent to, the capitals'
  // first, then a zone each, four a side and continent; its droppers: the
  // creatures, not someone's people, for each side those it may hunt (not
  // its own side's): placed ones, out of a battleground, ordinary ones (one
  // no source places, Alterac Valley's Frostwolves, a rare, a boss, only
  // where nothing else carries it), half the best chance
  // at least, the
  // likeliest two a continent and its zones' side, eight at most, the best
  // chance, then the most spawns; either named in every language, else no
  // help: Forever's new creatures some traces leave nameless)
  for (const ing of ingredients) {
    ing.sold = ing.sold.filter((v) => namedAll.has(v));
    ing.drops = ing.drops.filter(([c]) => namedAll.has(c) && !peaceful.has(c));
    const picked: number[] = [];
    const buckets = new Map<string, number[]>();
    const sellers = ing.sold
      .map((v) => npcOf.get(v))
      .filter((n): n is Npc => !!n && !n.unknown && n.area !== undefined)
      .sort((a, b) => Number(!!b.city) - Number(!!a.city) || a.id - b.id);
    for (const n of sellers) {
      const key = `${n.side ?? "-"}:${n.map ?? "-"}`;
      const got = buckets.get(key) ?? [];
      if (got.length >= 4 || got.some((o) => npcOf.get(o)?.area === n.area)) continue;
      got.push(n.id);
      buckets.set(key, got);
      picked.push(n.id);
    }
    ing.sold = picked.sort((a, b) => a - b);
    const spawnCount = (c: number) => spawns.get(c)?.length ?? 0;
    const pick = (drops: [number, number][]) => {
      const placed = drops.filter(([c]) => spawns.has(c));
      if (placed.length) drops = placed;
      const open = drops.filter(([c]) => !pvpMaps.has(npcOf.get(c)?.map ?? -1));
      if (open.length) drops = open;
      const ordinary = drops.filter(([c]) => (npcOf.get(c)?.rank ?? 0) <= 1);
      if (ordinary.length) drops = ordinary;
      const bestChance = Math.max(0, ...drops.map(([, p]) => p));
      const perPlace = new Map<string, number>();
      return drops
        .filter(([, p]) => p >= bestChance / 2)
        .sort((a, b) => b[1] - a[1] || spawnCount(b[0]) - spawnCount(a[0]) || a[0] - b[0])
        .filter(([c]) => {
          const n = npcOf.get(c);
          const key = `${n?.map ?? "-"}:${(n?.area !== undefined && zoneParent.get(n.area)?.mask) || 0}`;
          perPlace.set(key, (perPlace.get(key) ?? 0) + 1);
          return perPlace.get(key)! <= 2;
        })
        .slice(0, 8);
    };
    const chosen = new Map<number, number>();
    for (const side of ["A", "H"]) for (const [c, p] of pick(ing.drops.filter(([c]) => npcOf.get(c)?.side !== side))) chosen.set(c, p);
    ing.drops = [...chosen]
      .sort((a, b) => b[1] - a[1] || spawnCount(b[0]) - spawnCount(a[0]) || a[0] - b[0])
      .map(([c, p]) => [c, Math.round(p * 10) / 10] as [number, number]);
    // (a dropper's zone, for its side: the nearest of the cook's first)
    for (const [c] of ing.drops) {
      const a = npcOf.get(c)?.area;
      if (a !== undefined && zoneParent.has(a)) zoneIds.add(a);
    }
  }
  const zones: Zone[] = [...zoneIds]
    .sort((a, b) => a - b)
    .map((id) => {
      const z = zoneParent.get(id)!;
      return { id, map: z.map, ...(z.mask === 2 ? { side: "A" as const } : z.mask === 4 ? { side: "H" as const } : {}) };
    });
  // (a rank's trainers and sellers no one can be sent to: gone too)
  for (const r of ranks) {
    r.trainers = r.trainers.filter((v) => !npcOf.get(v)?.unknown);
    r.sellers = r.sellers.filter((v) => !npcOf.get(v)?.unknown);
  }
  const pointed = new Set<number>([
    ...kept.flatMap((it) => [...it.sold, ...it.drops.map(([c]) => c)]),
    ...quests.flatMap((q) => (q.giver ? [q.giver] : [])),
    ...ranks.flatMap((r) => [...r.trainers, ...r.sellers]),
    ...ingredients.flatMap((i) => [...i.sold, ...i.drops.map(([c]) => c)]),
  ]);
  // (the book's order: by the skill a dish is learned at, its yellow, its name)
  dishes.sort((a, b) => a.learn - b.learn || a.yellow - b.yellow || a.name.localeCompare(b.name));
  return { dishes, items: kept, npcs: npcs.filter((n) => pointed.has(n.id)), quests, ranks, ingredients, zones, unchaptered };
}

const list = (xs: number[]) => `{ ${xs.join(", ")} }`;

export function lua(game: Game): string {
  const { dishes, items, npcs, quests, ranks, ingredients, zones } = cookbook(game);
  const out = [
    `-- Generated by scripts/recipes.ts from wow-data's ${game === "classic" ? "Classic Era" : "Forever"} database: edit the script or data/chapters.json, not this file.`,
    "-- recipes[spell]: what it makes (item, made = { least, most }), the skill it is",
    "-- learned at and its colours (learn, yellow, grey: green is halfway), its",
    "-- chapter, its ingredients (item, count, item, count...), how it is learned",
    "-- (skill, trainer, items: recipe items, quests), unknown: no source seen yet.",
    "-- recipeItems[item]: the recipe it teaches, who sells it (limited: [npc] =",
    "-- the stock), who drops it (drops: the likeliest, npc, percent...; world: a",
    "-- drop of many), the quests that give it.",
    "-- npcs[id]: the sellers, the likeliest droppers, the quest givers, the",
    "-- trainers: side (A, H: the faction it serves), area (its zone), map (its",
    "-- continent or instance), city (in a capital), x, y (a spot), lvl, rank.",
    "-- quests[id]: giver, side, level, min (the level it opens at), area.",
    "-- ingredients[item]: who sells it (sold), the likeliest droppers (drops: npc,",
    "-- percent...), the zones it is fished in (fished), the Herbalism its nodes",
    "-- ask (herb) and the zones they grow in (herbZones), the containers it is",
    "-- found in (inside), the zones it is picked up in (picked: a chest of the world).",
    "-- zones[id]: an ingredient's zone: its continent (map), its side.",
    "-- ranks[cap]: the skill's rank that opens up to cap: its spell, who teaches",
    "-- it (trainers), the book (items) and who sells it (sellers), the quests;",
    "-- the level and the skill it asks.",
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
    if (n.map !== undefined) parts.push(`map = ${n.map}`);
    if (n.city) parts.push("city = true");
    if (n.x !== undefined) parts.push(`x = ${n.x}`, `y = ${n.y}`);
    if (n.lvl) parts.push(`lvl = { ${n.lvl[0]}, ${n.lvl[1]} }`);
    if (n.rank) parts.push(`rank = ${n.rank}`);
    out.push(`    [${n.id}] = { ${parts.join(", ")} },`);
  }
  out.push("  },", "  ingredients = {");
  for (const ing of ingredients) {
    const parts: string[] = [];
    if (ing.sold.length) parts.push(`sold = ${list(ing.sold)}`);
    if (ing.drops.length) parts.push(`drops = ${list(ing.drops.flat())}`);
    if (ing.fished.length) parts.push(`fished = ${list(ing.fished)}`);
    if (ing.fishing) parts.push("fishing = true");
    if (ing.herb !== undefined) parts.push(`herb = ${ing.herb}`);
    if (ing.herbZones.length) parts.push(`herbZones = ${list(ing.herbZones)}`);
    if (ing.inside.length) parts.push(`inside = ${list(ing.inside)}`);
    if (ing.picked.length) parts.push(`picked = ${list(ing.picked)}`);
    out.push(`    [${ing.item}] = { ${parts.join(", ")} },`);
  }
  out.push("  },", "  zones = {");
  for (const z of zones) out.push(`    [${z.id}] = { map = ${z.map}${z.side ? `, side = "${z.side}"` : ""} },`);
  out.push("  },", "  ranks = {");
  for (const r of ranks) {
    const parts = [`spell = ${r.spell}`];
    if (r.trainers.length) parts.push(`trainers = ${list(r.trainers)}`);
    if (r.items.length) parts.push(`items = ${list(r.items)}`, `sellers = ${list(r.sellers)}`);
    if (r.quests.length) parts.push(`quests = ${list(r.quests)}`);
    if (r.level) parts.push(`level = ${r.level}`);
    if (r.skill) parts.push(`skill = ${r.skill}`);
    out.push(`    [${r.cap}] = { ${parts.join(", ")} },`);
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
// name), Herbalism's (a herb's line), the chefs' (their creatures'), for
// scripts/locales.ts to put in each language's Text file.
const LOCALES = ["enUS", "enGB", "deDE", "frFR", "esES", "esMX", "ruRU", "ptBR", "itIT", "koKR", "zhCN", "zhTW"];
export const CHEF_NPCS = { kendor: 340, eunice: 4552 };
export type Names = {
  skillLine: string;
  herbalism: string;
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
  const herbalism = named("skill_line", 182);
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
    const entry: Names = { skillLine: from(skill)!, herbalism: from(herbalism)!, kendor: from(chefs.kendor)!, eunice: from(chefs.eunice)!, npcs: { classic: {}, forever: {} }, quests: { classic: {}, forever: {} } };
    for (const k of ["skillLine", "herbalism", "kendor", "eunice"] as const) if (!entry[k]) throw new Error(`no ${k} name in ${l}`);
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
