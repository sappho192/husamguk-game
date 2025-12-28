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
- Press **F5** in Godot Editor to run
- Main scene: `scenes/battle.tscn` (Phase 1 demo)

## Current Status: Phase 2 Complete ✅

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

**What's Playable:**
- 3v3 battle with general skills and strategic cards
- Click skills on left sidebar anytime (cooldown-based)
- Play cards when global turn timer reaches 10 seconds
- Auto-attack system continues independently

**Next: Phase 3 (Internal Affairs)**
- Governance system (choice-based events between battles)
- Stage progression (3 stages per run)
- Enhancement selection screen
- Event system implementation

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
│   ├── core/              # Data classes (Unit, General, Card, Buff)
│   ├── systems/battle/    # BattleManager with dual-layer timing
│   └── ui/battle/         # Battle UI (SkillBar, CardHand, UnitDisplay)
├── scenes/                # .tscn files (battle.tscn)
├── data/
│   ├── generals/          # 9 generals YAML (3 nations × 3 roles)
│   ├── units/             # 6 unit types YAML
│   ├── cards/             # 13 cards YAML (starter + advanced)
│   └── localization/      # ko.yaml, en.yaml (99 strings each)
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
