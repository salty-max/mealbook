# Mealbook

A World of Warcraft addon for Classic Era and World of Warcraft: Forever: a
chef's cookbook that fills in as you learn to cook, and the road to 300.

- **Recipes:** every recipe you know gets its page, by chapter: what it
  makes, its colours now and at each threshold, its ingredients as the
  game's items (with how many you carry), how you learned it, how often you
  cooked it.
- **The road:** from your skill now to 300, the surest recipe you know at
  each step, how many casts it takes on average, what to buy or gather,
  where to train, and what to learn when your recipes run out.

`/mealbook` opens the book, `/mealbook road` the road.

Work in progress: the chefs' pages, the hunts for rare recipes, the
milestones and the translations are next.

## Building

```bash
bun run check     # everything a commit needs
bun run package   # a test zip in dist/
```

The recipes come from [wow-data](https://github.com/salty-max/wow-data),
beside this folder.

## License

MIT.
