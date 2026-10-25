-- The Achievements tab, over both panels: the kit's board (the figures on
-- top: all earned, and each group's; then one row per achievement under its
-- group's heading and how many of it are earned: its group's picture, its
-- ring gold once earned, the title, what it asks, when it was earned or how
-- far along it is). Achievements: Milestones.lua.
local _, ns = ...
local K, L = ns.kit, ns.kit.L
ns.milestoneRows = {} -- (for the tests)

local GROUPS = {
  { "ranks", L["Ranks"], ns.milestoneIcons.ranks, "all" },
  { "recipes", L["Recipes known"], ns.milestoneIcons.recipes, "all" },
  { "cooked", L["Dishes cooked"], ns.milestoneIcons.cooked, "all" },
  { "firsts", L["Firsts"], ns.milestoneIcons.firsts, "all" },
  { "hunts", L["Hunts"], ns.milestoneIcons.hunts, "all" },
}

-- (the kit's tab: K.deedsTab, its board over both panels and the count)
local tab =
  K.deedsTab(ns.deeds, { name = "MealbookMilestones", groups = GROUPS, rows = ns.milestoneRows, n = ns.TAB.milestones })
ns.addTab(ns.TAB.milestones, tab.tab)

-- Open the book at the achievements, one of them picked out.
function ns.openMilestones(id)
  tab:pick(id)
  ns.openTab(ns.TAB.milestones)
end
