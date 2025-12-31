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

## Current Status: Phase 5 (Corps & Grid System) In Progress ✅

**Phase 1 (Battle Core)** - Complete:
- ✅ ATB combat system with individual unit gauges
- ✅ Data-driven architecture using YAML files
- ✅ 6 base unit types (Infantry, Cavalry, Archer)
- ✅ 9 generals (3 nations × 3 roles)
- ✅ Trait system (anti-cavalry, berserker, charge, etc.)
- ✅ Korean/English localization

**Phase 2 (Combat Expansion)** - Complete:
- ✅ General unique skills (9 skills with damage/buff/debuff/heal effects)
- ✅ Skill cooldown system (independent of ATB, resets each stage)
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
- ✅ 5 Korean historical NPCs (Doseon, Yi Je-ma, Wonhyo, Uisang, Choi Chi-won) with unique dialogue
- ✅ Theme-based enhancement filtering (healing, mystic, tactical, etc.)
- ✅ Horizontal layout: NPC portrait + info on left, dialogue on right
- ✅ 14 enhancements extended with theme tags
- ✅ 216 localization strings per language (Korean/English)

**Phase 4 (Wave System & Combat Improvements)** - Complete:
- ✅ Wave-based battle system (3-4 waves per stage)
- ✅ Battle data schema and YAML definitions
- ✅ Wave rewards (HP recovery, global turn reset, buff extension)
- ✅ Wave UI (counter, transition messages)
- ✅ ATB speed optimization (4x faster: ~2.5s per action instead of 10s)
- ✅ Dynamic enemy spawning per wave

**Phase 5 (Corps & Grid System)** - Complete:
- ✅ Phase 5A: 16×16 tile-based terrain grid system
  - 6 terrain types with stat modifiers (plain, mountain, forest, river, road, wall)
  - 3 stage maps with spawn zones
  - TileDisplay and TileGridUI components
- ✅ Phase 5B: Corps system (generals commanding soldier groups)
  - 6 corps templates (infantry, cavalry, archer variants)
  - 5 formations with stat modifiers (학익진, 봉시진, 방원진, 장사진, 어린진)
  - Corps positioning on grid (one corps per tile)
  - Attack range by unit type (Infantry: 1, Cavalry: 2, Archer: 4-5)
- ✅ Phase 5C: Enhanced ATB with command system
  - 5 command types (ATTACK, DEFEND, EVADE, WATCH, MOVE)
  - Movement phase during global turns
  - CommandPanel UI and MovementOverlay
  - CorpsDisplay component with HP/ATB bars
  - 283 localization strings per language (Korean/English)

**Next Steps:**
- 🔲 Full integration with existing wave battle system (Phase 6)
- 🔲 Meta-progression system (save/load)

**What's Playable:**
- Full roguelite run: Main Menu → 3 Battle Stages (with waves) → Victory/Defeat
- **Stage 1**: 3 waves (2, 3, 4 enemies) - Tutorial difficulty
- **Stage 2**: 3 waves (3, 3, 4 enemies) - Medium difficulty
- **Stage 3**: 3 waves (3, 4, 5 enemies) - Final boss with 2 generals
- Between each stage: Internal Affairs (3 governance choices) → Fateful Encounter (meet 1 of 5 NPCs)
- Wave rewards: HP recovery (10-20%), global turn reset, buff duration extension
- NPCs offer themed enhancements matching their character
- Unit HP, stats, and buffs carry forward through all battles
- General skills reset to 0 cooldown at the start of each new stage
- Run statistics tracking (stages cleared, battles won, choices made, enhancements gained)

**Development Roadmap:**
- Phase 6: Integration of corps/grid system with wave battles (replace unit-based with corps-based combat)
- Phase 7: Meta-progression system (permanent unlocks, save/load) and content expansion (more battles, events, cards, enhancements)
- Post-Phase-7: Balance tuning and polish based on playtesting
- Long-term: MOD system full implementation

**Test Scenes:**
- `scenes/battle.tscn` - Unit-based wave battle system (Phases 1-4, currently active)
- `scenes/corps_battle_test.tscn` - Corps-based tactical combat on 16×16 grid (Phase 5 prototype)

## Documentation

- [Game Design Document](docs/game_design_document.md) - Core gameplay design (Korean)
- [Technical Design Document](docs/technical_design_document.md) - Architecture & systems
- [CLAUDE.md](CLAUDE.md) - Development guidance for Claude Code
- [Battle Simulator Guide](husamguk/docs/BATTLE_SIMULATOR.md) - Headless combat testing & balance tuning
- [Data Schemas](husamguk/data/) - YAML schema definitions
- [Issue Tracker](https://husamguk.atlassian.net/jira/software/projects/KAN/boards/1) - Project management & bug tracking

## Development Tools

### Battle Simulator
Headless combat simulator for balance testing:
- Run battles without GUI for fast iteration
- Test various unit/general combinations
- Output CSV (raw data) + JSON (statistics)
- 10x accelerated simulation speed

See [Battle Simulator Guide](husamguk/docs/BATTLE_SIMULATOR.md) for usage.

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
│   │   ├── run_state.gd             # Run-level state persistence
│   │   ├── terrain_tile.gd          # Terrain data (Phase 5A)
│   │   ├── battle_map.gd            # 16×16 grid map (Phase 5A)
│   │   ├── corps.gd                 # Corps (general + soldiers) (Phase 5B)
│   │   ├── formation.gd             # Formation stat modifiers (Phase 5B)
│   │   └── corps_command.gd         # Command system (Phase 5C)
│   ├── systems/
│   │   ├── battle/                  # BattleManager (dual-layer timing)
│   │   └── internal_affairs/        # InternalAffairsManager (event system)
│   ├── tools/                       # Development tools
│   │   └── battle_simulator.gd      # Headless battle simulator
│   └── ui/
│       ├── battle/                  # SkillBar, CardHand, UnitDisplay
│       │   ├── tile_display.gd      # Single tile UI (Phase 5A)
│       │   ├── tile_grid_ui.gd      # 16×16 grid UI (Phase 5A)
│       │   ├── corps_display.gd     # Corps info overlay (Phase 5B)
│       │   ├── command_panel.gd     # Command selection UI (Phase 5C)
│       │   ├── movement_overlay.gd  # Movement range overlay (Phase 5C)
│       │   └── corps_battle_ui.gd   # Corps battle integration (Phase 5C)
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
│   ├── corps_battle_test.tscn      # Corps battle test scene (Phase 5)
│   ├── victory_screen.tscn         # Victory screen
│   └── defeat_screen.tscn          # Defeat screen
├── data/
│   ├── generals/                   # 9 generals YAML
│   ├── units/                      # 6 unit types YAML
│   ├── cards/                      # 13 cards YAML
│   ├── events/                     # 20 events YAML (4 categories)
│   ├── enhancements/               # 14 enhancements YAML (with theme tags)
│   ├── npcs/                       # 5 NPCs YAML (Phase 3D)
│   ├── battles/                    # 3 battle definitions YAML (Phase 4 - Wave system)
│   ├── terrain/                    # 6 terrain types YAML (Phase 5A)
│   ├── maps/                       # 3 stage maps YAML (Phase 5A)
│   ├── corps/                      # 6 corps templates YAML (Phase 5B)
│   ├── formations/                 # 5 formations YAML (Phase 5B)
│   └── localization/               # ko.yaml, en.yaml (283 strings each)
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

This project uses a dual-license structure:

- **Source Code**: [GPL-3.0](LICENSE) - All code in `husamguk/src/`
- **Assets & Documentation**: [CC-BY-SA-4.0](LICENSE) - Files in `husamguk/assets/` and `husamguk/docs/`

See [LICENSE](LICENSE) for full details and license texts.
