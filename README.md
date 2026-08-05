# gen1recomp_mods

Mods for [gen1recomp](https://github.com/bryanthaboi/gen1recomp) (LÖVE2D / Lua). Each mod lives in its own folder at the repo root.

API docs: [gen1recomp wiki](https://github.com/bryanthaboi/gen1recomp/wiki)

# Move Learn Plus

When a Pokémon learns a new move and must forget an old one, the bottom panel shows **POWER**
and **PP** (max) for the selected move and for the move being learned.

In a Poké Mart **BUY** list, highlighting a TM/HM shows that move’s **POWER**
and **ACC** in the clerk footer.

Works across Red / Blue / Yellow via the engine move registry. Disabling
the mod restores the stock `MoveLearnMenu` and `ShopMenu`.

## Install

1. Copy this folder into the game's `mods/` directory  
   (or import the release zip)
2. Enable it in Options → Mod Manager
3. Restart (or `POKEPORT_DEV=1` + F5 while developing)

## When it appears

- Forget-move screen (party full of moves while learning — level-up, TM,
  evolution, etc.)
- Mart BUY list when the cursor is on a TM or HM

## Options

| Option | Default | Meaning |
|--------|---------|---------|
| SHOW STATS | on | Enriched forget panel + mart TM footer; off = vanilla text |

## Notes

- Status moves show `POWER --`.
- Forget panel PP is the move's **max** PP from data (not current remaining).
- Mart footer example: `BUBBLEBEAM` / `POWER 65 ACC 100`.
- Accuracy and type on the forget panel are still out of scope.
- Content mod (`affects_link: false`); overrides `MoveLearnMenu` and
  `ShopMenu`. If panels look vanilla, APPLY & RESTART and confirm the mod
  is enabled (not merely staged).
- GitHub releases for in-game Update must use tag **`vX.Y.Z`** (e.g. `v1.1.0`)
  with asset **`move_learn_plus-X.Y.Z.zip`**. Prefixed tags are ignored by
  the launcher.
- License: [MIT](LICENSE) · Changes: [CHANGELOG.md](CHANGELOG.md)
