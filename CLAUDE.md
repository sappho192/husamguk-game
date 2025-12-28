# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Husamguk** is a 2D ATB (Active Time Battle) roguelite strategy game based on the Later Three Kingdoms period of ancient Korea. Built with **Godot 4.5** using **GDScript**, this is a data-driven game where all content (generals, units, cards, events) is defined in YAML files.

**Key Characteristics:**
- 30-minute roguelite runs split into 3 stages
- Dual-layer combat: Individual unit ATB + global turn system for cards
- Internal affairs (governance) between battles
- MOD-first architecture with file-based data merging
- Korean and English localization

**Issue Tracker:** https://husamguk.atlassian.net/jira/software/projects/KAN/boards/1

## Development Commands

### Opening the Project
```bash
# Open in Godot Editor (if godot is in PATH)
cd husamguk
godot project.godot

# Or use Godot's project manager to import C:\REPO\husamguk-game\husamguk\project.godot
```

### Running the Game
- Press **F5** in Godot Editor to run the current scene
- Press **F6** to run a specific scene
- Main scene will be defined in `project.godot`

### Data Validation
All YAML files in `data/` follow schemas defined in `_schema.yaml` files. When adding or modifying game data:
1. Reference the appropriate schema file (e.g., `data/generals/_schema.yaml`)
2. Follow the structure in the `example:` section
3. Use localization keys, never hardcoded strings

## Architecture Overview

### Core Design Principle: Data-Driven Everything

**All game content is YAML-defined.** Adding new generals, units, cards, or events means creating/modifying YAML files, not hardcoding in scripts.

```
[YAML files] → [DataManager loads & merges MODs] → [Runtime Dictionary]
     ↓
[Factory pattern creates objects] → [GameManager manages state]
     ↓
[Systems process logic] → [UI reflects via signals]
```

### Autoload Singletons (src/autoload/)

The game uses Godot's autoload pattern for global managers:

- **GameManager**: Run state, stage progression (1-3), game flow orchestration
- **DataManager**: YAML loading, MOD merging (load_order priority), data queries
- **SaveManager**: Meta-progression persistence (permanent unlocks, separate from ephemeral run state)
- **AudioManager**: BGM/SFX playback management

**Critical:** Never access data files directly. Always query through `DataManager`.

### Project Structure (Current)

```
husamguk/
├── src/
│   ├── autoload/              # Global singletons
│   │   └── data_manager.gd    # ✅ YAML loading, localization, factory methods
│   ├── core/                  # Data classes
│   │   ├── unit.gd            # ✅ ATB system, buff management, effective stats
│   │   ├── general.gd         # ✅ Skill execution, cooldown tracking
│   │   ├── buff.gd            # ✅ Stat modification system
│   │   └── card.gd            # ✅ Card effects and targeting
│   ├── systems/
│   │   ├── battle/
│   │   │   └── battle_manager.gd  # ✅ Dual-layer timing, state machine
│   │   ├── internal_affairs/  # 🔲 Not yet implemented (Phase 3)
│   │   └── roguelite/         # 🔲 Not yet implemented (Phase 3)
│   └── ui/
│       └── battle/
│           ├── battle_ui.gd        # ✅ Main battle controller with deck management
│           ├── unit_display.gd    # ✅ Unit UI component with HP/ATB bars
│           ├── skill_bar.gd       # ✅ Left sidebar skill buttons
│           ├── skill_button.gd    # ✅ Individual skill button UI
│           ├── card_hand.gd       # ✅ Bottom card display container
│           ├── card_display.gd    # ✅ Individual card UI
│           └── placeholder_sprite.gd  # ✅ Colored rectangle fallback
│
├── scenes/
│   └── battle.tscn            # ✅ Main battle scene (Phase 2 complete)
├── data/
│   ├── generals/              # ✅ 9 generals YAML data with skills
│   │   ├── hubaekje.yaml
│   │   ├── taebong.yaml
│   │   └── silla.yaml
│   ├── units/
│   │   └── base_units.yaml    # ✅ 6 unit types YAML data
│   ├── cards/                 # ✅ Card system
│   │   ├── starter_deck.yaml  # ✅ 5 common cards (10 total)
│   │   └── advanced_cards.yaml # ✅ 8 rare/legendary cards
│   └── localization/          # ✅ Korean/English strings (99 each)
│       ├── ko.yaml
│       └── en.yaml
├── addons/
│   └── yaml/                  # ✅ godot-yaml parser addon (fimbul-works)
├── assets/                    # 🔲 Placeholder system in use
└── mods/                      # 🔲 MOD system not yet implemented
```

**Legend:**
- ✅ Implemented (Phase 2 complete)
- 🔲 Not yet implemented (future phases)

### MOD System Architecture

**MODs are first-class citizens.** The architecture supports user extensions from day one.

**Load Strategy:**
1. Base data loaded from `data/`
2. MOD folders in `mods/` loaded by `load_order` priority (in `mod.yaml`)
3. Deep merge: Later MODs override earlier ones (nested properties merged, not replaced)
4. Supports both data (YAML) and asset (sprites/audio) extensions

**Example:**
```yaml
# mods/balance_patch/mod.yaml
id: "balance_patch"
load_order: 100

# mods/balance_patch/data/generals/gyeonhwon.yaml
generals:
  - id: "gyeonhwon"
    base_stats:
      combat: 90  # Overrides base 95, keeps other stats
```

## Combat System: Dual-Layer Design

The combat system has **two independent timing layers**, which is unusual and requires careful state management:

### Layer 1: Individual Unit ATB
- Each unit has an ATB gauge (0-100)
- Fills at unit's ATB speed (multiplier, base 1.0)
- Gauge reaches 100 → unit executes auto-attack, ATB resets
- **Continuous**: No global pause, units act as they become ready

### Layer 2: Global Turn System
- Separate tick every 10 seconds (GLOBAL_TURN_INTERVAL)
- **Pauses ATB** during card selection (PAUSED_FOR_CARD state)
- Player uses 1 card from deck (max 1 card/global turn)
- Resumes ATB after card resolution
- Ticks buff durations and skill cooldowns

### Skills: Independent of ATB
- **Critical Design Decision**: Skills are ATB-independent (Phase 2 revision)
- Skills activate via click on SkillBar UI (left sidebar)
- Ready when cooldown = 0 (no ATB requirement)
- Using skill does NOT reset ATB
- Cooldown decrements on global turns only

**Why This Matters:** State management must handle:
- Two pause states: RUNNING, PAUSED_FOR_CARD
- ATB continues during normal combat
- Skills usable anytime (cooldown-based)
- Card effects that modify buffs/ATB speeds

## Data Schema System

All data schemas are in `_schema.yaml` files. Each schema includes:
- Field definitions with types, ranges, enums
- Required vs optional fields
- Descriptions in Korean (game's primary language)
- `example:` section with 2+ working examples

**Key Schemas:**

### Generals (`data/generals/_schema.yaml`)
- 9 base characters: 3 nations × 3 roles
- Roles: `assault` (high damage), `command` (buffs), `special` (turn manipulation)
- Stats: Leadership, Combat, Intelligence, Politics (1-100)
- Unique skills with cooldown, effect type, target, multiplier, conditional bonuses

### Units (`data/units/_schema.yaml`)
- Base types: Infantry, Cavalry, Archer, Special
- Formation: Front (melee/tank) vs Back (ranged/protected)
- Traits: Class bonuses (e.g., Spearman: +50% vs Cavalry)
- ATB speed determines turn frequency

### Cards (`data/cards/_schema.yaml`)
- Rarity: Common, Uncommon, Rare, Legendary
- Effect types: Buff, Debuff, Damage, Heal, Special
- **Penalty system**: Risk-reward (e.g., +40% ATK but -5% HP/turn)
- Conditions: Can restrict by HP threshold, unit count, turn number

### Nations
- **Hubaekje** (견훤): Aggressive, faster ATB
- **Taebong/Goryeo** (왕건): Balanced, diplomatic
- **Silla**: Defensive, stronger late-game

## Localization

**Never hardcode strings.** All text uses localization keys from `data/localization/`.

```yaml
# data/localization/ko.yaml
GENERAL_GYEONHWON: "견훤"
SKILL_FURY_OF_BAEKJE: "백제의 분노"

# data/localization/en.yaml
GENERAL_GYEONHWON: "Gyeonhwon"
SKILL_FURY_OF_BAEKJE: "Fury of Baekje"
```

In code:
```gdscript
# ✅ Correct
var name = DataManager.get_localized("GENERAL_GYEONHWON")

# ❌ Wrong
var name = "견훤"
```

## Roguelite Design: Two Progression Layers

### Run-Level Enhancements (Temporary)
- Acquired during a run, lost at run end
- Examples: Stat buffs, battle cards, first-turn advantage
- Selected after each stage (3 options, pick 1)

### Meta-Progression (Permanent)
- Earned through events and ending rewards
- Unlocks persist across all future runs
- Balanced approach: Not too strong early (following Slay the Spire model)
- Examples: Internal affairs efficiency, base stat increases

**Critical:** `SaveManager` must keep these separate:
- Run state: Ephemeral, discarded on game over/clear
- Meta-progression: Permanent, written to save file

## Internal Affairs System

**Choice-based governance** between battle stages:

- 2-3 turns per stage
- Each turn: 3 options from categories (Military, Economic, Diplomatic, Personnel)
- Each choice triggers a random event from that category
- Effects: Stat changes, card acquisition, event flags, penalties

**Architecture Note:** Event flags enable branching choices in later turns/stages. The flag system must persist within a run but reset between runs.

## Development Phase Roadmap

**Phase 1 (Battle Core)** ✅ COMPLETE
- ✅ YAML parser integration (godot-yaml from fimbul-works)
- ✅ Unit class with ATB system
- ✅ Basic attack mechanics, combat UI
- ✅ Battle end conditions
- ✅ DataManager with factory pattern
- ✅ Trait system implementation
- ✅ 6 unit types, 9 generals data
- ✅ Korean/English localization
- ✅ Placeholder graphics system

**Phase 2 (Combat Expansion)** ✅ COMPLETE
- ✅ General unique skills with cooldowns (9 skills)
- ✅ Global turn card system (10-second intervals, pause/resume ATB)
- ✅ Card deck and drawing mechanics (13 cards, starter + advanced)
- ✅ Buff/debuff system with duration tracking
- ✅ Player skill activation (SkillBar UI on left)
- ✅ Card hand UI (bottom, 3-5 cards)
- ✅ Dual-layer timing system (ATB + global turns)
- ✅ Skills independent of ATB (cooldown-based only)

**Phase 3 (Internal Affairs Connection)** 🔲 NEXT
- 🔲 Governance UI (3 choice display)
- 🔲 Stage progression flow
- 🔲 Enhancement selection screen
- 🔲 Event system implementation

**Phase 4 (Full Loop)** 🔲 PLANNED
- 🔲 3-stage connection
- 🔲 Game over/clear conditions
- 🔲 Main menu integration
- 🔲 SaveManager persistence
- 🔲 Meta-progression system

## Implementation Status

### ✅ Completed Components (Phase 2)

**Core Classes:**
- `src/core/unit.gd` - ATB system, buff management, effective stat calculation
- `src/core/general.gd` - Skill execution, cooldown tracking
- `src/core/buff.gd` - Stat modification (buffs/debuffs) with duration tracking
- `src/core/card.gd` - Card effect execution, targeting, penalty system

**Systems:**
- `src/systems/battle/battle_manager.gd` - Dual-layer timing, state machine (RUNNING/PAUSED_FOR_CARD), skill execution

**UI Components:**
- `src/ui/battle/battle_ui.gd` - Main battle controller with deck management
- `src/ui/battle/unit_display.gd` - HP/ATB bars, visual feedback
- `src/ui/battle/skill_bar.gd` - Left sidebar container for skill buttons
- `src/ui/battle/skill_button.gd` - Individual skill button (shows cooldown/ready state)
- `src/ui/battle/card_hand.gd` - Bottom card display container
- `src/ui/battle/card_display.gd` - Individual card UI with rarity colors
- `src/ui/battle/placeholder_sprite.gd` - Category-based colored rectangles

**Data Layer:**
- `src/autoload/data_manager.gd` - YAML loading, localization, factory methods for cards
- All YAML data files:
  - 9 generals with skills (hubaekje.yaml, taebong.yaml, silla.yaml)
  - 6 unit types (base_units.yaml)
  - 13 cards (starter_deck.yaml, advanced_cards.yaml)
  - 99 localization strings each language (ko.yaml, en.yaml)

**Critical Implementation Notes:**
1. **godot-yaml API**: Uses `YAML.parse()` with `has_error()` and `get_data()` methods (fimbul-works version)
2. **Keyword Conflict**: Avoid using "trait" as variable name (reserved keyword) - use "trait_data" instead
3. **RefCounted Classes**: Unit, General, Card, Buff all extend RefCounted (not Node)
4. **UI Timing**: All UI components create children in `_init()` not `_ready()` to avoid null reference errors
5. **Class Preloading**: All files preload dependencies using `const` (e.g., `const Buff = preload("...")`)
6. **Null Safety**: YAML optional fields checked with `data.get("field", null)` before assignment to typed properties
7. **Skills ATB-Independent**: Skills do NOT require or reset ATB (Phase 2 design revision)
8. **Buff Duration**: Ticks on global turns only (not ATB turns) for consistency

### 🔲 Not Yet Implemented (Phase 3+)

**Formation System:**
- Pre-battle formation selection UI
- Front/back positioning logic (currently hardcoded in unit data)

**MOD System:**
- MOD loading from `mods/` directory
- Deep merge strategy
- load_order priority handling
- Asset override support

**Internal Affairs:**
- Governance UI (3 choice display)
- Event system
- Stage progression
- Enhancement selection

## Asset Placeholder Strategy

During prototyping:
- Use colored rectangles + text labels for sprites
- Implement fallback system if image path not found
- Replace gradually as production assets arrive

**Required Assets (MVP):**
- Portraits: 9 generals @ 256×256px
- Units: 6 base types @ 64×64px with 8-frame animations
- UI: Card frames (4 rarities), buttons, ATB bars
- Audio: 3 BGM tracks, ~8 SFX samples

## Critical Architectural Insights

1. **Data-First Development:** Implement data loading and factory patterns before game logic. Without `DataManager`, nothing else works.

2. **Signal-Based Coupling:** Use Godot signals for all cross-system communication. Avoid direct manager calls where possible.

3. **ATB Complexity:** The dual-layer timing system (individual ATB + global turns) is the most complex part. Test pause/resume states thoroughly.

4. **Card Balancing is Key:** Cards are the primary moment-to-moment decision and meta-progression tool. Penalty cards are a core design element for risk-reward choices.

5. **MOD-First Thinking:** Design all systems to support modding. User extensions are not an afterthought.

6. **Run vs Meta Separation:** Never mix run state with meta-progression in save data. They have completely different lifecycles.

7. **Korean Primary Language:** All design documents and schemas are in Korean. English is secondary. Localization keys support both.
