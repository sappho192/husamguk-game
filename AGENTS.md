# Repository Guidelines

## Project Structure & Module Organization
- `husamguk/src/` contains GDScript gameplay code (autoload managers in `autoload/`, core data in `core/`, systems in `systems/`, UI in `ui/`).
- `husamguk/scenes/` holds Godot scenes (entry point: `main_menu.tscn`, battle flow in `battle.tscn`).
- `husamguk/data/` stores YAML-driven content (generals, units, cards, events, battles, terrain, localization).
- `husamguk/assets/` is for art/audio; `husamguk/addons/` includes the YAML parser.
- `husamguk/docs/` and top-level `docs/` contain design and simulator guides.

## Build, Test, and Development Commands
- Open the project: `cd husamguk && godot project.godot` (or import `husamguk/project.godot` in Godot).
- Run the game: press `F5` in Godot (main scene configured in `project.godot`).
- Run a headless battle sim: `godot --headless scenes/battle_simulator.tscn` (uses `simulation_config.yaml`).
- Windows console example: `C:\BIN\Godot_v4.5.1-stable_win64\Godot_v4.5.1-stable_win64_console.exe --path . --headless scenes/battle_simulator.tscn`.

## Coding Style & Naming Conventions
- GDScript uses tab indentation; keep existing formatting.
- Use `snake_case` for variables/functions and `PascalCase` for classes (e.g., `DataManager`).
- Game data is YAML-first: add content in `husamguk/data/` and load through `DataManager` (avoid direct file access).
- Localization: add new strings to `husamguk/data/localization/` and reference keys, not literals.

## Testing Guidelines
- No unit test framework is configured; validate gameplay in the editor and via the battle simulator.
- Simulator outputs to `husamguk/output/simulation/<scenario>/` with `battles.csv` and `summary.json`.
- Use scenario files like `husamguk/simulation_config.yaml` or custom configs (see `husamguk/docs/BATTLE_SIMULATOR.md`).

## Commit & Pull Request Guidelines
- Commit history mostly follows Conventional Commits (e.g., `feat:`, `fix:`, `docs:`, `refactor:`); use these prefixes when possible.
- PRs should describe gameplay impact, list data/schema changes, and include screenshots or GIFs for UI changes.
- Link relevant issues from the Jira board when applicable.

## Agent-Specific Instructions
- Follow YAML schema files (e.g., `husamguk/data/generals/_schema.yaml`) and the `example:` blocks when adding data.
- Prefer updating docs in `husamguk/docs/` when behavior changes (simulator, battle flow, or data formats).
