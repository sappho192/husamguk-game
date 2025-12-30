# 후삼국시대 (Husamguk)

2D ATB roguelite strategy game based on the Later Three Kingdoms period of ancient Korea.

**Built with Godot 4.5 | GDScript | Data-driven YAML architecture**

## Quick Start

### Prerequisites
- Godot 4.5+ installed
- Windows 10/11 (primary development platform)
- GitGuardian installed (check [here](https://docs.gitguardian.com/ggshield-docs/integrations/git-hooks/pre-commit))

### Opening the Project
```bash
# Option 1: Command line (if godot is in PATH)
cd husamguk
godot project.godot

# Option 2: Godot Project Manager
# Import: C:\REPO\husamguk-game\husamguk\project.godot
```

### Running the Game
- Press **F5** in Godot Editor to run the full game
- Main scene: `scenes/main_menu.tscn` (complete run loop)

## Current Status: Phase 3D Complete ✅

**Phase 1 (Battle Core)** - Complete:
- ✅ ATB combat system with individual unit gauges
- ✅ Data-driven architecture using YAML files
- ✅ 6 base unit types (Infantry, Cavalry, Archer)
- ✅ 9 generals (3 nations × 3 roles)
- ✅ Trait system (anti-cavalry, berserker, charge, etc.)
- ✅ Korean/English localization

**Phase 2 (Combat Expansion)** - Complete:
- ✅ General unique skills (9 skills with damage/buff/debuff/heal effects)
- ✅ Skill cooldown system (independent of ATB)
- ✅ Global turn timer (10-second intervals)
- ✅ Card system (13 cards: starter deck + advanced cards)
- ✅ Buff/debuff system with duration tracking
- ✅ Player skill activation (click to use, ATB-independent)
- ✅ Skill bar UI (left side, shows unit status and cooldowns)
- ✅ Card hand UI (bottom, 3-5 cards with draw mechanics)
- ✅ Dual-layer timing (individual ATB + global turn pauses)

**Phase 3 (Internal Affairs Connection)** - Complete:
- ✅ GameManager autoload (run orchestration and scene flow)
- ✅ RunState class (full unit state carry-forward between battles)
- ✅ Internal Affairs system (20 events across 4 categories: Military, Economic, Diplomatic, Personnel)
- ✅ Enhancement system (14 enhancements: 5 common, 5 rare, 4 legendary)
- ✅ Main menu and victory/defeat screens
- ✅ Complete 3-stage run loop with statistics tracking
- ✅ Event flag system for branching choices

**Phase 3D (Fateful Encounter)** - Complete:
- ✅ Narrative-driven NPC encounter system (replacing simple enhancement selection)
- ✅ 5 legendary NPCs (Jwaja, Hwata, Ugil, Namhwa, Sugyeong) with unique dialogue
- ✅ Theme-based enhancement filtering (healing, mystic, tactical, etc.)
- ✅ Horizontal layout: NPC portrait + info on left, dialogue on right
- ✅ 14 enhancements extended with theme tags
- ✅ 216 localization strings per language (Korean/English)

**What's Playable:**
- Full roguelite run: Main Menu → 3 Battle Stages → Victory/Defeat
- Between each stage: Internal Affairs (3 governance choices) → Fateful Encounter (meet 1 of 5 NPCs)
- NPCs offer themed enhancements matching their character (physicians offer healing, mystics offer buffs, etc.)
- Unit HP, stats, and buffs carry forward through all battles
- Run statistics tracking (stages cleared, battles won, choices made, enhancements gained)

**Next: Phase 4 (Meta-Progression)**
- Save/load system (permanent progression)
- Meta-progression unlocks (persistent upgrades)
- Enemy scaling across stages
- Additional content (more events, enhancements, cards)

## Documentation

- [Game Design Document](docs/game_design_document.md) - Core gameplay design (Korean)
- [Technical Design Document](docs/technical_design_document.md) - Architecture & systems
- [CLAUDE.md](CLAUDE.md) - Development guidance for Claude Code
- [Battle Simulator Guide](husamguk/docs/BATTLE_SIMULATOR.md) - Headless combat testing & balance tuning
- [Data Schemas](husamguk/data/) - YAML schema definitions

## Development Tools

### Battle Simulator
Headless combat simulator for balance testing:
- Run battles without GUI for fast iteration
- Test various unit/general combinations
- Output CSV (raw data) + JSON (statistics)
- 10x accelerated simulation speed

See [Battle Simulator Guide](husamguk/docs/BATTLE_SIMULATOR.md) for usage.

## Related Links

- [Issue Tracker](https://husamguk.atlassian.net/jira/software/projects/KAN/boards/1?atlOrigin=eyJpIjoiNDU0YTI2NGQxY2EyNDU4NTllOGM3MWNiNmIzZTZkYmIiLCJwIjoiaiJ9)

## Project Structure

```
husamguk/
├── src/
│   ├── autoload/                    # Global singletons
│   │   ├── data_manager.gd          # YAML loading, localization, factory methods
│   │   ├── game_manager.gd          # Run orchestration, scene transitions
│   │   └── save_manager.gd          # Meta-progression (stub for Phase 4)
│   ├── core/                        # Data classes
│   │   ├── unit.gd                  # ATB system, buff management
│   │   ├── general.gd               # Skill execution
│   │   ├── card.gd                  # Card effects
│   │   ├── buff.gd                  # Stat modifications
│   │   └── run_state.gd             # Run-level state persistence
│   ├── systems/
│   │   ├── battle/                  # BattleManager (dual-layer timing)
│   │   └── internal_affairs/        # InternalAffairsManager (event system)
│   ├── tools/                       # Development tools
│   │   └── battle_simulator.gd      # Headless battle simulator
│   └── ui/
│       ├── battle/                  # SkillBar, CardHand, UnitDisplay
│       ├── internal_affairs/        # ChoiceButton, InternalAffairsUI
│       ├── enhancement/             # EnhancementCard (reused by Fateful Encounter)
│       ├── fateful_encounter/       # NPCPortraitDisplay, FatefulEncounterUI
│       ├── main_menu_ui.gd          # Main menu
│       ├── victory_ui.gd            # Victory screen
│       └── defeat_ui.gd             # Defeat screen
├── scenes/
│   ├── main_menu.tscn              # Entry point
│   ├── battle.tscn                 # Battle scene
│   ├── battle_simulator.tscn       # Battle simulator (headless)
│   ├── internal_affairs.tscn       # Governance choices
│   ├── fateful_encounter.tscn      # Fateful Encounter (Phase 3D)
│   ├── victory_screen.tscn         # Victory screen
│   └── defeat_screen.tscn          # Defeat screen
├── data/
│   ├── generals/                   # 9 generals YAML
│   ├── units/                      # 6 unit types YAML
│   ├── cards/                      # 13 cards YAML
│   ├── events/                     # 20 events YAML (4 categories)
│   ├── enhancements/               # 14 enhancements YAML (with theme tags)
│   ├── npcs/                       # 5 NPCs YAML (Phase 3D)
│   └── localization/               # ko.yaml, en.yaml (216 strings each)
├── addons/yaml/                    # godot-yaml parser addon
├── docs/                           # Design documents & guides
│   └── BATTLE_SIMULATOR.md         # Battle simulator usage guide
├── simulation_config.yaml          # Battle simulator scenarios
└── output/simulation/              # Simulator output (CSV/JSON)
```

## Technology Stack

- **Engine**: Godot 4.5
- **Language**: GDScript
- **Data Format**: YAML (using [godot-yaml](https://github.com/fimbul-works/godot-yaml))
- **Architecture**: Data-driven, MOD-ready
- **Localization**: Korean (primary), English (secondary)

## License

[License information to be added]
