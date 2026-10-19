# Mealbook

A World of Warcraft addon for Classic Era and World of Warcraft: Forever: a
chef's cookbook that fills in as you learn to cook, and the road to 300.

- **Recipes:** every recipe you know gets its page, by chapter, written by
  your faction's chef (Kendor Kabonka in Stormwind, Eunice Burch in the
  Undercity): what it makes, its colours now and at each threshold, its
  ingredients as the game's items (with how many you carry), how you
  learned it, how often you cooked it.
- **The road:** from your skill now to 300, the surest recipe you know at
  each step, how many casts it takes on average, what to buy or gather,
  where to train, and what to learn when your recipes run out.

- **Hunts:** the recipes no trainer teaches and no shop keeps for long, a
  stall's limited stock, a creature's drop, a quest, each opening when your
  skill is ready for it: who has it, where, how often.

- **The pantry:** an ingredient's tooltip names the dishes you know it
  cooks into, and the book shows what your bags can cook right now.
- **Achievements:** the ranks, the recipes known, the dishes cooked, the
  first of each kind of dish, the hunts found.

`/mealbook` opens the book, `/mealbook road` the road, `/mealbook tooltips`
turns the ingredients' tooltip line off or on.

In English and French. Work in progress: the welcome page, the minimap
button and the other languages are next.

## Building

```bash
bun run check     # everything a commit needs
bun run package   # a test zip in dist/
```

The recipes come from [wow-data](https://github.com/salty-max/wow-data),
beside this folder.

## License

MIT.
