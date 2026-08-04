# Move Learn Plus

When a Pokémon learns a new move and must forget an old one, the bottom panel shows **POWER**
and **PP** (max) for the selected move and for the move being learned.

Works across Red / Blue / Yellow via the engine move registry. Disabling
the mod restores the stock `MoveLearnMenu`.

## Install

1. Copy this folder into the game's `mods/` directory  
   (or import the release zip)
2. Enable it in Options → Mod Manager
3. Restart (or `POKEPORT_DEV=1` + F5 while developing)

## When it appears

Automatically, whenever the game opens the forget-move screen (party full
of moves while learning a new one — level-up, TM, evolution, etc.).

## Options

| Option | Default | Meaning |
|--------|---------|---------|
| SHOW STATS | on | Enriched bottom panel; off = vanilla “Which move…” text |

## Notes

- Status moves show `POWER --`.
- PP is the move's **max** PP from data (not current remaining).
- Accuracy and type are out of scope for this version.
- Content mod (`affects_link: false`); there is no hook for forget-list
  labels, so the mod **overrides** the `MoveLearnMenu` screen. If the
  panel still looks vanilla, use APPLY & RESTART and confirm the mod is
  enabled (not merely staged).
- GitHub releases for in-game Update must use tag **`vX.Y.Z`** (e.g. `v1.0.0`)
  with asset **`move_learn_plus-X.Y.Z.zip`**. Prefixed tags are ignored by
  the launcher.
- License: [MIT](LICENSE) · Changes: [CHANGELOG.md](CHANGELOG.md)
