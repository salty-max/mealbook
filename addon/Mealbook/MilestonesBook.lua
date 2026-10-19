-- The Achievements tab, over both panels: the kit's board (the figures on
-- top: all earned, and each group's; then one row per achievement under its
-- group's heading and how many of it are earned: its group's picture, its
-- ring gold once earned, the title, what it asks, when it was earned or how
-- far along it is). Achievements: Milestones.lua.
local _, ns = ...
local K, L = ns.kit, ns.kit.L
local book, panel, board
ns.milestoneRows = {} -- (for the tests)
local picked -- (one opened from its banner: picked out, in view)

local GROUPS = {
  { "ranks", L["Ranks"], ns.milestoneIcons.ranks, "all" },
  { "recipes", L["Recipes known"], ns.milestoneIcons.recipes, "all" },
  { "cooked", L["Dishes cooked"], ns.milestoneIcons.cooked, "all" },
  { "firsts", L["Firsts"], ns.milestoneIcons.firsts, "all" },
  { "hunts", L["Hunts"], ns.milestoneIcons.hunts, "all" },
}
local FIGURES = { { "all", L["earned"] } }

local function items()
  local out = {}
  for _, m in ipairs(ns.milestones) do
    if ns.milestoneVisible(m) then
      table.insert(out, {
        id = m.id,
        group = m.group,
        title = m.title,
        text = m.text,
        earned = ns.earnedMilestone(m.id),
        progress = m.progress,
      })
    end
  end
  return out
end

local function refresh()
  local n, all = ns.milestoneCount()
  book.count:SetText(L["%d of %d achievements"]:format(n, all))
  board:refresh(picked)
end

ns.addTab(ns.TAB.milestones, {
  whole = true,
  build = function(b)
    book = b
    panel = K.panel(book)
    panel:SetPoint("TOPLEFT", book.left, "TOPLEFT")
    panel:SetPoint("BOTTOMRIGHT", book.sheet, "BOTTOMRIGHT")
    board = K.board({
      parent = panel,
      name = "MealbookMilestones",
      groups = GROUPS,
      figures = FIGURES,
      items = items,
      rows = ns.milestoneRows,
    })
  end,
  show = function(n) panel:SetShown(n == ns.TAB.milestones) end,
  refresh = refresh,
})

-- Open the book at the achievements, one of them picked out.
function ns.openMilestones(id)
  picked = id
  ns.openTab(ns.TAB.milestones)
end
