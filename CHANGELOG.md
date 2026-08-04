# Changelog

All notable changes to **Move Learn Plus** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project versions with the `version` field in `manifest.json`.

## [1.0.1] — 2026-08-04

<!-- release-title: Drop NEW prefix on learned move -->

### Changed

- Bottom panel shows the new move name **without** the `NEW` prefix.

## [1.0.0] — 2026-08-04

<!-- release-title: First stable release -->

First stable release. Forget-move POWER / PP panel is semver-stable from here.

### Added

- Bottom panel on the forget-move screen with **POWER** and **PP** (max) for
  the highlighted move and for the move being learned.
- Option **SHOW STATS** (default on); off restores the vanilla
  “Which move should be forgotten?” text.
- Status moves show `POWER --`.

### Notes

- Reimplements `MoveLearnMenu` (no `engine_internals`) so learn / HM /
  abandon flow stays Gen 1–style; disable the mod to restore the stock menu.
- `manifest.github` points at `Zetto22/move_learn_plus`.

## [0.1.2] — 2026-08-04

<!-- release-title: Label POWER instead of ATK -->

### Changed

- Bottom panel label **ATK** renamed to **POWER** (status moves still show
  `POWER --`).

## [0.1.1] — 2026-08-04

<!-- release-title: Forget-list ATK and PP panel -->

### Added

- Bottom panel on the forget-move screen with **ATK** (power) and **PP**
  (max) for the highlighted move and for the move being learned (`NEW`).
- Option **SHOW STATS** (default on); off restores the vanilla
  “Which move should be forgotten?” text.
- Status moves show `ATK --`.

### Notes

- Reimplements `MoveLearnMenu` (no `engine_internals`) so learn / HM /
  abandon flow stays with the mod while the list UI stays Gen 1–style.
- `manifest.github` points at `Zetto22/move_learn_plus`.
