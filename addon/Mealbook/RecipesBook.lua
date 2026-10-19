-- The Recipes tab: the dishes this character knows, by chapter, and each
-- dish's page: what it makes, its colours now and at each threshold, its
-- ingredients as the game's items (counts, tooltips, how many in the bags),
-- how it was learned and how often cooked. The chef's own page of each dish
-- goes above the facts once written (cookbook-voices.md).
local _, ns = ...
local L, D, ui = ns.kit.L, ns.data, ns.ui
local T = ui.T
local book, list, page
local current
local rows = {}

local function style(row, kind)
  if kind == "section" then
    row.text:SetPoint("LEFT", 4, 0)
    row.text:SetPoint("RIGHT", -4, 0)
    row.text:SetFont(ns.kit.TITLE_FONT, 14, "")
    row.text:SetTextColor(unpack(T.gold))
    return 22
  end
  row.count:SetPoint("RIGHT", -4, 0)
  row.text:SetPoint("LEFT", kind == "overview" and 4 or 14, 0)
  row.text:SetPoint("RIGHT", row.count, "LEFT", -4, 0)
  row.text:SetFont(ns.kit.BODY_FONT, 12, "")
  row.text:SetTextColor(unpack(kind == "overview" and T.gold or T.text))
  return 18
end

local function known()
  local out = {}
  local char = ns.book()
  for _, spell in ipairs(D.order) do
    if char and char.known[spell] then table.insert(out, spell) end
  end
  return out
end

local function refreshList()
  local q, char = ui.query(), ns.book()
  local skill = ns.skill()
  list:begin()
  if q == "" then
    local row = list:add("overview", L["Your cookbook"])
    row:SetScript("OnClick", function()
      current = nil
      ns.refresh()
    end)
    if not current then list:pick(row) end
  end
  local any = false
  for _, chapter in ipairs(ui.CHAPTERS) do
    local first = true
    for _, spell in ipairs(known()) do
      local name = ns.dishName(spell)
      if D.recipes[spell].chapter == chapter[1] and (q == "" or name:lower():find(q, 1, true)) then
        if first then
          list:gap(6)
          list:add("section", chapter[2])
          first = false
        end
        any = true
        -- (each in its colour now, as the cooking window lists it)
        local colour = ns.road.colour(D.recipes[spell], skill)
        local row = list:add("dish", ui.colourCode(colour) .. name .. "|r", char.cooked[spell] or 0)
        row:SetScript("OnClick", function()
          current = spell
          ns.refresh()
        end)
        if current == spell then list:pick(row) end
      end
    end
  end
  if not any and q ~= "" then list:add("section", L["Nothing found"]) end
  list:finish()
end

local HOW = {
  skill = L["With the skill itself"],
  trainer = L["From a cooking trainer"],
  quest = L["From a quest"],
}

-- The chef's page of the dish: a note in their hand, signed (the kit's
-- aside). A translation names places as Forever's client does: Classic Era's
-- names swapped in there (ns.classicNames, from the Pages file).
local function swapped(text)
  if ns.forever or not ns.classicNames then return text end
  for forever, classic in pairs(ns.classicNames) do
    text = text:gsub(forever:gsub("%p", "%%%0"), (classic:gsub("%%", "%%%%")))
  end
  return text
end
-- The chef's page as the book shows it, its paragraphs (nil: none).
function ns.pageText(chef, spell)
  local paragraphs = ns.pages and ns.pages[chef] and ns.pages[chef][spell]
  if not paragraphs then return nil end
  local out = {}
  for i, p in ipairs(paragraphs) do
    out[i] = swapped(p)
  end
  return out
end
local function chefPage(spell)
  local chef = ns.chef()
  local text = ns.pageText(chef, spell)
  if text then page:text({ { table.concat(text, "\n\n"), aside = true, sign = ns.chefName(chef) } }) end
end

local function showDish(spell)
  local d, char = D.recipes[spell], ns.book()
  local skill = ns.skill()
  local colour = ns.road.colour(d, skill)
  local chapter
  for _, c in ipairs(ui.CHAPTERS) do
    if c[1] == d.chapter then chapter = c[2] end
  end
  page:start(ns.dishName(spell), table.concat({ chapter or "", ui.colourWord(colour) }, "  -  "), ui.dishPicture(spell))
  chefPage(spell)
  local made = d.made[1] == d.made[2] and tostring(d.made[1]) or ("%d-%d"):format(d.made[1], d.made[2])
  page:stats({
    { tostring(char.cooked[spell] or 0), L["cooked"] },
    { made, L["a cast makes"] },
    { tostring(ns.road.cookable(d, ui.have)), L["you can cook now"] },
  })
  page:section(L["Ingredients"])
  local items = {}
  for i = 1, #d.reagents, 2 do
    local item, n = d.reagents[i], d.reagents[i + 1]
    table.insert(items, {
      item,
      nil,
      false,
      n,
      function(tip) tip:AddLine(L["In your bags: %d"]:format(ui.have(item)), 1, 1, 1) end,
    })
  end
  page:items(items)
  page:section(L["It makes"])
  page:items({ { d.item, nil, false, d.made[1] } })
  page:section(L["Skill"])
  page:row(L["Colours"], ui.thresholds(d))
  page:row(L["Now"], ("%s (%d)"):format(ui.colourWord(colour), skill))
  page:section(L["Your page"])
  local learned = char.known[spell]
  page:row(L["Learned"], learned and L["%s, you were level %d"]:format(ui.day(learned), learned.level or 0))
  local first = char.first[spell]
  page:row(L["First cooked"], first and L["%s, you were level %d"]:format(ui.day(first), first.level or 0))
  local ways = {}
  for _, how in ipairs({ "skill", "trainer", "quest" }) do
    if d[how] or (how == "quest" and d.quests) then table.insert(ways, HOW[how]) end
  end
  if d.items then table.insert(ways, L["From a recipe"]) end
  page:row(L["How it is learned"], #ways > 0 and table.concat(ways, ", ") or L["Not seen yet"])
  if d.items then
    local recipes = {}
    for _, item in ipairs(d.items) do
      table.insert(recipes, { item, nil, false, 1 })
    end
    page:items(recipes)
  end
end

local function showOverview()
  local char = ns.book()
  local skill, max = ns.skill()
  local n, cooked = 0, 0
  for _, spell in ipairs(known()) do
    n = n + 1
    cooked = cooked + (char.cooked[spell] or 0)
  end
  page:start(L["Your cookbook"], ns.kit.plural(n, "%d recipe", "%d recipes"):format(n), ui.icon(ui.ICON))
  page:stats({
    { skill > 0 and ("%d / %d"):format(skill, max) or "-", L["cooking"] },
    { tostring(n), ns.kit.plural(n, "recipe", "recipes") },
    { tostring(cooked), L["dishes cooked"] },
  })
  if n == 0 then
    page:paragraph(
      L["No recipe yet. Open your cooking window once: every recipe you know gets its page, and each new one after."],
      T.soft
    )
    return
  end
  page:section(L["Chapters"])
  for _, chapter in ipairs(ui.CHAPTERS) do
    local count = 0
    for _, spell in ipairs(known()) do
      if D.recipes[spell].chapter == chapter[1] then count = count + 1 end
    end
    if count > 0 then
      page:card(chapter[2], ns.kit.plural(count, "%d recipe", "%d recipes"):format(count), ui.icon(chapter[3]))
    end
  end
end

local function refresh()
  local n = #known()
  book.count:SetText(ns.kit.plural(n, "%d recipe", "%d recipes"):format(n))
  refreshList()
  if current and ns.knows(current) then
    showDish(current)
  else
    current = nil
    showOverview()
  end
  page:finish()
end

ns.addTab(ns.TAB.recipes, {
  build = function(b)
    book = b
    list = ui.newList(book.left, style, rows, true)
    page = ui.newPage(book.sheet, "MealbookRecipePage")
  end,
  show = function(n)
    local here = n == ns.TAB.recipes
    list:SetShown(here)
    page:SetShown(here)
  end,
  refresh = refresh,
})

function ns.openDish(spell)
  current = spell
  ns.openTab(ns.TAB.recipes)
end
