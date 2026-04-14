# Agent Notes

## Project shape

- Engine: Godot 4.6.x
- Entry scene: `welcome.tscn`
- Gameplay scene: `main.tscn`
- Main gameplay script: `scripts/GameOfLife.gd`
- Global app state:
  - `GameSettings` autoload for language/text
  - `SafeArea` autoload for safe-area insets

## Current UX decisions

- Default app language is English.
- The welcome screen is portrait-first and mobile-oriented.
- Typography is intentionally split:
  - `Tiny5` for the large title treatment
  - `VT323` for readable UI text and HUD controls
- Gameplay starts from a random live board.
- The in-game HUD is intentionally minimal:
  - play/pause
  - clear
  - random
  - menu
  - speed slider
- There is no dedicated `Step` or `Pattern` button in the current HUD.

## Android rendering policy

- Real phones should use `mobile`.
- Android emulators should use `gl_compatibility`.
- Do not hand-edit `project.godot` permanently just to test one target.
- Use the explicit launcher scripts at the repo root:
  - `./run_android_emulator.sh`
  - `./run_android_phone.sh`
- Shared implementation lives in `scripts/run_android_target.sh`.
- That script temporarily rewrites the renderer for export, then restores the original values automatically.

## Testing policy

- Use `tests/test_runner.gd` for the lightweight headless suite.
- Use `scripts/GameOfLifeBoard.gd` for deterministic Conway rule tests.
- Standard local validation commands:
  - `godot --headless --path . --quit`
  - `godot --headless --path . --script res://tests/test_runner.gd`

## Operational notes

- Godot may print macOS certificate warnings in headless mode on this machine. They have not been blocking.
- The export helper can print RID/resource leak warnings on shutdown. Treat them as noise unless export actually fails.
- Local runtime artifacts such as `Library/` and `.tmp/` are ignored and should not be committed.
