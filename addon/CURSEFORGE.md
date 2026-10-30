# Mealbook: Cooking Guide & Cookbook

<!-- Project description for curseforge.com and Wago (bun addon-kit/store.ts).
The project's title on the stores: "Mealbook: Cooking Guide & Cookbook" (the
addon's own name stays Mealbook). A draft, 19 October 2026: Mealbook is not
released yet, read it again against what ships (the Hunts, the Milestones,
the pantry) before the first release. -->

<!-- Summary (the project's summary on CurseForge and Wago, and the TOCs' Notes):
A chef's cookbook that fills in as you learn to cook, and the road to 300: what to cook next and how many. -->

Mealbook is a cookbook that fills in as your character learns to cook, written by a real chef of Azeroth, and a guide that takes your cooking from where it is now to 300. Every recipe you learn gets its page, and the road tells you what to cook next, how many times, and what to buy on the way.

For Classic Era (including Hardcore and Season of Discovery) and World of Warcraft: Forever, in one download.

## The cookbook

Your recipes sit in chapters: meat, fish, soups, baking, drinks, feasts and campfires. Each shows its colour for your skill right now, from orange to grey, so you can see at a glance what still teaches you something.

A dish's page holds what it makes and how many, its ingredients as the game's own items with how many you carry, the skill where it turns yellow, green and grey, how you learned it, and how often you've cooked it.

Above the facts, the chef has a word about the dish. Alliance cooks read **Kendor Kabonka**, Stormwind's master of cooking recipes, proud, exacting and rarely impressed. Horde cooks read **Eunice Burch**, who teaches in the Undercity's kitchens, cannot taste the food any more and cooks by smell and memory. Every dish has a page from each of them. `/mealbook chef` lets you read the other one.

## The road to 300

From your skill now to 300, even from nothing, Mealbook plans the whole road:

- at each step, the **surest recipe**, one you know or one to learn from a trainer or a vendor of your side, with a new recipe only when it's worth the trip,
- **how many casts** each leg takes on average, by the game's own skill-up rule,
- **where to learn** each new recipe, the trainer or the vendor and where they stand,
- **each rank** as it really works: Journeyman from a cooking trainer, Expert from the Expert Cookbook and who sells it, Artisan from its quest, with the level and skill each asks,
- a **shopping list** for each leg, checked against your bags, and **where to get** each ingredient: the nearest vendor of your side, the creatures that drop it and how often, where it's fished, the herb and the Herbalism it asks.

The road changes as you cook and learn. Open it with `/mealbook road`.

## The pantry

Hover an ingredient and its tooltip names the dishes you know it cooks into, each in its colour for your skill. In the book, it also tells where the ingredient comes from. The book's front page shows what your bags can cook right now, and how many times.

## Hunts

Some recipes no trainer teaches and no shop keeps for long. Mealbook keeps them as hunts, each opening when your skill is ready for it:

- **a stall's limited stock**, like Super-Seller 680's in Desolace: who sells it, where, how many at a time,
- **a drop**: the likeliest creatures to carry it, their zone, their level and how often it falls,
- **a quest**: who gives it, where, and from what level,
- **the auction house**, for a recipe only the other faction can learn, like Crispy Bat Wing for an Alliance cook: the neutral auction houses of Booty Bay, Gadgetzan and Everlook, the nearest first, and where the other side finds it. These count for no achievement.

The hunts tab counts how many you've found and when the next one opens.

## Achievements

The book keeps its own achievements: each cooking rank trained and 300 reached, the recipes you know, the dishes you've cooked, your first dish of each kind and the hunts you've found. Each one earned comes with the game's fanfare and its own achievement alert (a switch in the settings turns the alert off), and the book remembers when and at what level.

## Compatibility

One download covers Classic Era, Hardcore, Season of Discovery and World of Warcraft: Forever. Each game gets its own recipes: Forever's new dishes are in its book. Season of Discovery's own dishes are left out.

The dishes, ingredients and places are the game's own, in your client's language. Mealbook's own words and the chefs' pages speak English, French, German and Spanish. German and Spanish are first translations: corrections are welcome on GitHub. Both Spanish clients share one text, each with its own game names and decimal separator. Other clients get English for those.

## Settings and commands

Open the book with `/mealbook` or the minimap button. The welcome page appears once per character and can be reopened with `/mealbook welcome`.

Settings are under **Options > AddOns > Mealbook**, through `/mealbook settings` or a right-click on the minimap button: whose pages the book shows, the achievements' alert and sound, how long banners stay, the ingredients' tooltip line and the minimap button. Each character has its own. Copy another character's within the same game, or use `/mealbook export` and `/mealbook import CODE`.

- `/mealbook road` opens the road to 300.
- `/mealbook chef` switches to the other chef's pages.
- `/mealbook tooltips` turns the ingredients' tooltip line off or on.
- `/mealbook minimap` shows or hides the minimap button.

## Other addons

These share Mealbook's look and work independently:

- **[Hearthtale](https://www.curseforge.com/wow/addons/hearthtale)** ([Wago](https://addons.wago.io/addons/E6gzPnN1)) writes a diary for your character as you play, with an epitaph when a Hardcore life ends.
- **[Lorekeeper's Codex](https://www.curseforge.com/wow/addons/lorekeepers-codex)** ([Wago](https://addons.wago.io/addons/j6jAL0NR)) unlocks lore pages as you explore Azeroth and meet its people.
- **[Yonder](https://www.curseforge.com/wow/addons/yonder)** ([Wago](https://addons.wago.io/addons/ZKbq5y61)) offers exploration riddles, rare hunts, a bestiary, an atlas and records of your fish and herbs.
- **[Second Wind](https://www.curseforge.com/wow/addons/second-wind)** ([Wago](https://addons.wago.io/addons/XKqEjbKy)) gives you a debrief after a close call or death.
- **[Palaver](https://www.curseforge.com/wow/addons/palaver)** ([Wago](https://addons.wago.io/addons/ZKbqbO61)) puts quests and NPC conversations in a large panel beside the one you speak to, read and answered from the keyboard.
- **[Goodwill](https://www.curseforge.com/wow/addons/goodwill)** ([Wago](https://addons.wago.io/addons/ZKbqa961)) shows every faction's road to Exalted from where you stand, with a chapter of its story at each standing.
- **[Yours Truly](https://www.curseforge.com/wow/addons/yours-truly)** ([Wago](https://addons.wago.io/addons/j6jAx1NR)) brings letters from the people whose quest chains you finished, waiting at your next mailbox.

## Support

Mealbook is free and will stay free. If it's spared you a few stacks of wasted meat on the way to 300, you can support the addon with a coffee on [Ko-fi](https://ko-fi.com/salty_max). Thank you.

## Source

MIT licensed: [github.com/salty-max/mealbook](https://github.com/salty-max/mealbook). Recipes, their skill levels and sources come from the game's own tables, the CMaNGOS Classic database, Questie's data and Wowhead for Forever's newest. Thanks to their contributors. Not affiliated with Blizzard Entertainment.
