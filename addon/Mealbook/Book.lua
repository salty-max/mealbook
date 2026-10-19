-- The cookbook as a book: the family's window (portrait, title bar), its tabs
-- (Recipes, The road, Hunts, Achievements: each a file of its own, *Book.lua, registered with
-- ns.addTab), and what every tab is made of (ns.ui): the kit's look in the
-- cookbook's theme, its list on the left and page on the right. /mealbook
-- opens it.
local _, ns = ...
local K, L = ns.kit, ns.kit.L

-- ── look ─────────────────────────────────────────────────────────────────────
-- The kit's (Kit.lua), in the kitchen's theme: a copper accent, the panels a
-- faint warm brown, like a page near the stove.
K.theme({
  accent = { 0.95, 0.68, 0.38 },
  ring = { 0.72, 0.45, 0.24 },
  bar = { 0.85, 0.55, 0.25 },
  tint = { 1.00, 0.94, 0.86 },
  shade = { 0.04, 0.02, 0.01, 0.55 },
  highlight = { 1.00, 0.85, 0.65 },
})
local T = K.T
local ICON = "Interface\\AddOns\\Mealbook\\Media\\Logo"

-- The skill's colours, the game's cooking window's.
local COLOURS = {
  red = { "|cffff2020", L["too hard"] },
  orange = { "|cffff8040", L["orange"] },
  yellow = { "|cffffff00", L["yellow"] },
  green = { "|cff40c040", L["green"] },
  grey = { "|cff808080", L["grey"] },
}

-- The chapters, in the book's order.
local CHAPTERS = {
  { "meat", L["Roasts and grills"], "Interface\\Icons\\INV_Misc_Food_14" },
  { "fish", L["Fish and seafood"], "Interface\\Icons\\INV_Misc_Fish_18" },
  { "soup", L["Soups and stews"], "Interface\\Icons\\INV_Drink_17" },
  { "bake", L["Eggs, pies and bakes"], "Interface\\Icons\\INV_Misc_Food_13" },
  { "drink", L["Drinks"], "Interface\\Icons\\INV_Drink_10" },
  { "feast", L["Feasts"], "Interface\\Icons\\INV_Misc_Food_15" },
  { "fire", L["Fires and ovens"], "Interface\\Icons\\Spell_Fire_Fire" },
}

-- ── the window ───────────────────────────────────────────────────────────────
local book
local TAB = { recipes = 1, road = 2, hunts = 3, milestones = 4 }
ns.TAB = TAB
local tabs, TITLES = {}, { L["Recipes"], L["The road"], L["Hunts"], L["Achievements"] }
function ns.addTab(n, tab) tabs[n] = tab end

function ns.refresh()
  local tab = book and tabs[book.selectedTab]
  if tab and tab.built then tab.refresh() end
end

function ns.showTab(n)
  if not book then return end
  book.selectedTab = n
  if PanelTemplates_SetTab then PanelTemplates_SetTab(book, n) end
  local tab = tabs[n]
  if not tab.built then
    tab.build(book)
    tab.built = true
  end
  -- (a tab over both panels, the achievements' board: the list, the sheet and
  -- the search put away)
  book.left:SetShown(not tab.whole)
  book.sheet:SetShown(not tab.whole)
  book.search:SetShown(not tab.whole)
  for _, t in ipairs(tabs) do
    if t.built then t.show(n) end
  end
  ns.refresh()
end

local function build()
  local window = K.gameWindow("MealbookFrame", "Mealbook", ICON)
  book = window or K.dialog("MealbookFrame", "Mealbook")
  K.movable(book, 780, 560)
  local edge = window and 8 or 14
  book.count = K.label(book, K.BODY_FONT, 11, T.gold)
  book.count:SetPoint("TOPLEFT", 64, -36)
  book.left = K.panel(book, true)
  book.left:SetPoint("TOPLEFT", edge, -58)
  book.left:SetPoint("BOTTOMLEFT", edge, edge)
  book.left:SetWidth(244)
  book.sheet = K.panel(book)
  book.sheet:SetPoint("TOPLEFT", book.left, "TOPRIGHT", 4, 32)
  book.sheet:SetPoint("BOTTOMRIGHT", -edge, edge)
  book.search = CreateFrame("EditBox", "MealbookSearch", book, "SearchBoxTemplate")
  book.search:SetHeight(20)
  book.search:SetPoint("TOPLEFT", book.left, "TOPLEFT", 18, -10)
  book.search:SetPoint("TOPRIGHT", book.left, "TOPRIGHT", -12, -10)
  book.search:HookScript("OnTextChanged", function() ns.refresh() end)
  book.selectedTab = TAB.recipes
  book:SetScript("OnShow", function() ns.showTab(book.selectedTab) end)
  K.tabs(book, TITLES, function(n) ns.showTab(n) end)
end

local function window()
  if not book then build() end
  return book
end

function ns.toggle() window():SetShown(not book:IsShown()) end

function ns.openTab(n)
  window()
  book.selectedTab = n
  if book:IsShown() then
    ns.showTab(n)
  else
    book:Show()
  end
end
function ns.openRoad() ns.openTab(TAB.road) end
function ns.openHunts() ns.openTab(TAB.hunts) end

-- What the game tells while the book is open shows at once (a moment later:
-- a batch of dishes cooks one cast after another).
local pending = false
ns.onChange = function()
  if not (book and book:IsShown()) or pending then return end
  pending = true
  C_Timer.After(0.3, function()
    pending = false
    ns.refresh()
  end)
end

-- (an item's name the game tells late: the page again, its names in; only
-- one the book shows, a dish, an ingredient, a recipe, a container, and one
-- the game found: an item it never knows would ask again at each page)
local shown
local function bookItems()
  if shown then return shown end
  shown = {}
  local D = ns.data
  for _, d in pairs(D.recipes or {}) do
    if d.item then shown[d.item] = true end
    for i = 1, #(d.reagents or {}), 2 do
      shown[d.reagents[i]] = true
    end
  end
  for item in pairs(D.recipeItems or {}) do
    shown[item] = true
  end
  for item, ing in pairs(D.ingredients or {}) do
    shown[item] = true
    for _, c in ipairs(ing.inside or {}) do
      shown[c] = true
    end
  end
  for _, r in pairs(D.ranks or {}) do
    for _, i in ipairs(r.items or {}) do
      shown[i] = true
    end
  end
  return shown
end
ns.on("GET_ITEM_INFO_RECEIVED", function(item, success)
  if success and bookItems()[item] and ns.onChange then ns.onChange() end
end)

-- ── the parts every tab is made of ───────────────────────────────────────────
local function query() return strtrim((book.search:GetText() or ""):lower()) end
local function day(stamp) return K.day(stamp and stamp.at) end
local function colourWord(name) return COLOURS[name][1] .. COLOURS[name][2] .. "|r" end
local function colourCode(name) return COLOURS[name][1] end
-- A dish's colours at its thresholds: orange 1, yellow 45, green 65, grey 85.
local function thresholds(d)
  return table.concat({
    COLOURS.orange[1] .. d.learn .. "|r",
    COLOURS.yellow[1] .. d.yellow .. "|r",
    COLOURS.green[1] .. ns.road.green(d) .. "|r",
    COLOURS.grey[1] .. d.grey .. "|r",
  }, "  ")
end
local function have(item) return GetItemCount and GetItemCount(item) or 0 end
local function dishPicture(spell)
  local d = ns.recipe(spell)
  return function(p) p.tex:SetTexture(d and K.itemIcon(d.item) or ICON) end
end

-- Who and where (Recipes_<game>.lua's npcs and quests): a zone's name is the
-- client's, by its id; an npc's and a quest's the Text file's. A quest the
-- language has no title for: none (its giver named instead).
local function zoneName(area)
  local name = area and C_Map and C_Map.GetAreaInfo and C_Map.GetAreaInfo(area)
  return type(name) == "string" and name ~= "" and name or nil
end
local function npcName(id) return ns.npcNames and ns.npcNames[id] or "" end
local function questName(id) return ns.questNames and ns.questNames[id] end
-- "Stormwind City 75, 37": its zone and a spot there (a zone alone when the
-- data has no spot).
local function where(id)
  local n = ns.data.npcs and ns.data.npcs[id]
  local zone = n and zoneName(n.area)
  if not zone then return "" end
  if n.x then return ("%s %d, %d"):format(zone, n.x, n.y) end
  return zone
end
-- A list sorted by a rank, the list's own order kept between equals.
local function ranked(list, rank)
  local out, at = {}, {}
  for i, v in ipairs(list or {}) do
    out[i], at[v] = v, i
  end
  local r = {}
  for _, v in ipairs(out) do
    r[v] = rank(v)
  end
  table.sort(out, function(a, b)
    if r[a] ~= r[b] then return r[a] < r[b] end
    return at[a] < at[b]
  end)
  return out
end

-- Several npcs, the nearest first: one in the zone the character stands in,
-- then one on its continent (a capital's first), then a capital's, then the
-- rest (the data's map: AreaTable's continent; the character's, the game's
-- instance map: 0 the Eastern Kingdoms, 1 Kalimdor).
local function byNearness(ids)
  local here = GetRealZoneText and GetRealZoneText()
  local map = GetInstanceInfo and select(8, GetInstanceInfo())
  return ranked(ids, function(id)
    local n = ns.data.npcs and ns.data.npcs[id] or {}
    if here and zoneName(n.area) == here then return 0 end
    if map and n.map == map then return n.city and 1 or 2 end
    return n.city and 3 or 4
  end)
end
local function nearest(ids) return byNearness(ids)[1] end

-- Zones the nearest first (an ingredient's, Recipes_<game>'s zones): the one
-- the character stands in, then its continent's of its side or neither's,
-- then its continent's, then its side's elsewhere, then the rest (one the
-- data doesn't place last). `zoneOf` the zone of each, for a list of others.
local function zonesByNearness(list, zoneOf)
  local here = GetRealZoneText and GetRealZoneText()
  local map = GetInstanceInfo and select(8, GetInstanceInfo())
  local mine = ns.hunts and ns.hunts.mine()
  return ranked(list, function(v)
    local id = v
    if zoneOf then id = zoneOf(v) end
    local z = id and ns.data.zones and ns.data.zones[id]
    if not z then return 5 end
    if here and zoneName(id) == here then return 0 end
    local ours = z.side == nil or z.side == mine
    if map and z.map == map then return ours and 1 or 2 end
    return ours and 3 or 4
  end)
end

ns.ui = {
  T = T,
  ICON = ICON,
  CHAPTERS = CHAPTERS,
  query = query,
  day = day,
  colourWord = colourWord,
  colourCode = colourCode,
  thresholds = thresholds,
  have = have,
  dishPicture = dishPicture,
  zoneName = zoneName,
  npcName = npcName,
  questName = questName,
  where = where,
  nearest = nearest,
  byNearness = byNearness,
  zonesByNearness = zonesByNearness,
  icon = K.icon,
  newList = K.list,
  newPage = function(parent, name) return K.page(parent, name, { labelWidth = 110, pairs = {} }) end,
}
