# 후삼국시대 (Husamguk)

2D ATB roguelite strategy game based on the Later Three Kingdoms period of ancient Korea.

**Built with Godot 4.5 | GDScript | Data-driven YAML architecture**

## Quick Start

### Prerequisites
- Godot 4.5+ installed
- Windows 10/11 (primary development platform)

### Opening the Project
```bash
# Option 1: Command line (if godot is in PATH)
cd husamguk
godot project.godot

# Option 2: Godot Project Manager
# Import: C:\REPO\husamguk-game\husamguk\project.godot
```

### Running the Game
- Press **F5** in Godot Editor to run
- Main scene: `scenes/battle.tscn` (Phase 1 demo)

## Current Status: Phase 1 Complete ✅

**Phase 1 (Battle Core)** has been implemented:
- ✅ ATB combat system with individual unit gauges
- ✅ Data-driven architecture using YAML files
- ✅ 6 base unit types (Infantry, Cavalry, Archer)
- ✅ 9 generals (3 nations × 3 roles)
- ✅ Trait system (anti-cavalry, berserker, charge, etc.)
- ✅ Auto-combat AI for testing
- ✅ Korean/English localization
- ✅ Placeholder graphics (colored rectangles)

**What's Playable:**
- 3v3 auto-battle demo showing ATB system and trait bonuses
- Units: Spearman, Swordsman, Archer, Light Cavalry, Heavy Cavalry, Crossbowman

**Next: Phase 2 (Combat Expansion)**
- General unique skills with cooldowns
- Global turn card system
- Player action choices (skill vs auto-attack)
- Formation selection UI

## Documentation

- [Game Design Document](docs/game_design_document.md) - Core gameplay design (Korean)
- [Technical Design Document](docs/technical_design_document.md) - Architecture & systems
- [CLAUDE.md](CLAUDE.md) - Development guidance for Claude Code
- [Data Schemas](husamguk/data/) - YAML schema definitions

## Related Links

- [Issue Tracker](https://husamguk.atlassian.net/jira/software/projects/KAN/boards/1?atlOrigin=eyJpIjoiNDU0YTI2NGQxY2EyNDU4NTllOGM3MWNiNmIzZTZkYmIiLCJwIjoiaiJ9)

## Project Structure

```
husamguk/
├── src/
│   ├── autoload/          # Global singletons (DataManager)
│   ├── core/              # Data classes (Unit, General)
│   ├── systems/battle/    # BattleManager
│   └── ui/battle/         # Battle UI components
├── scenes/                # .tscn files
├── data/
│   ├── generals/          # 9 generals YAML data
│   ├── units/             # 6 unit types YAML data
│   └── localization/      # ko.yaml, en.yaml
├── addons/yaml/           # godot-yaml parser addon
└── docs/                  # Design documents
```

## Technology Stack

- **Engine**: Godot 4.5
- **Language**: GDScript
- **Data Format**: YAML (using [godot-yaml](https://github.com/fimbul-works/godot-yaml))
- **Architecture**: Data-driven, MOD-ready
- **Localization**: Korean (primary), English (secondary)

## License

[License information to be added]
