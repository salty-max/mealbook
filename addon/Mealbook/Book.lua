-- The cookbook as a book: the family's window (portrait, title bar), its tabs
-- (Recipes, The road: each a file of its own, *Book.lua, registered with
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
local ICON = "Interface\\Icons\\INV_Misc_Food_15"

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
local TAB = { recipes = 1, road = 2 }
ns.TAB = TAB
local tabs, TITLES = {}, { L["Recipes"], L["The road"] }
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
  icon = K.icon,
  newList = K.list,
  newPage = function(parent, name) return K.page(parent, name, { labelWidth = 110, pairs = {} }) end,
}
