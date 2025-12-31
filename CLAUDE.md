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

### Debug/Testing Features
**Battle Scene Debug Buttons** (top-right corner):
- **Force Victory**: Instantly kill all enemies and trigger victory
- **Force Defeat**: Instantly kill all allies and trigger defeat
- Use these to quickly test the full run loop (Battle → Internal Affairs → Fateful Encounter → Next Battle)

**Battle Simulator** (headless testing):
```bash
# Run combat simulations without GUI
cd husamguk
"C:\BIN\Godot_v4.5.1-stable_win64\Godot_v4.5.1-stable_win64_console.exe" --path . --headless scenes/battle_simulator.tscn

# Edit simulation_config.yaml to configure scenarios
# Results output to: output/simulation/<scenario_name>/
#   - battles.csv (raw data)
#   - summary.json (statistics)
```

See [Battle Simulator Guide](husamguk/docs/BATTLE_SIMULATOR.md) for detailed usage.

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

### Complete Game Flow (Phase 3D)

```
Main Menu (scenes/main_menu.tscn)
  ↓ [Start New Run]
  ↓ GameManager.start_new_run() → creates RunState, loads Battle 1
  ↓
Battle Stage 1 (scenes/battle.tscn)
  ↓ [Victory] GameManager.on_battle_ended() → saves unit states to RunState
  ↓
Internal Affairs (scenes/internal_affairs.tscn)
  ↓ 3 governance choices from 4 categories (Military/Economic/Diplomatic/Personnel)
  ↓ InternalAffairsManager.execute_event() → modifies RunState (stats, deck, flags)
  ↓
Fateful Encounter (scenes/fateful_encounter.tscn)  # Phase 3D: Narrative NPC encounters
  ↓ Random NPC appears (1 of 5: Doseon, Yi Je-ma, Wonhyo, Uisang, Choi Chi-won)
  ↓ NPC offers 3 themed enhancements (filtered by NPC's theme tags)
  ↓ Choose 1 enhancement (1 common, 1 rare, 1 legendary)
  ↓ GameManager.on_enhancement_selected() → adds to RunState.active_enhancements
  ↓ RunState.current_stage += 1
  ↓
Battle Stage 2
  ↓ Units restored from RunState (HP, stats, buffs carry forward)
  ↓ Enhancements applied
  ↓ [Victory] → Internal Affairs → Fateful Encounter
  ↓
Battle Stage 3
  ↓ [Victory or Defeat]
  ↓
Victory/Defeat Screen (scenes/victory_screen.tscn or defeat_screen.tscn)
  ↓ Display run statistics (stages cleared, battles won, choices made, enhancements)
  ↓ [Return to Main Menu] GameManager.clear_run() → RunState = null
  ↓
Main Menu
```

### Project Structure (Phase 4 Wave System)

```
husamguk/
├── src/
│   ├── autoload/                    # Global singletons
│   │   ├── data_manager.gd          # ✅ YAML loading, battle data, NPC/theme filtering, localization
│   │   ├── game_manager.gd          # ✅ Run orchestration, scene transitions, wave battles
│   │   └── save_manager.gd          # ✅ Stub for Phase 4 meta-progression
│   ├── core/                        # Data classes
│   │   ├── unit.gd                  # ✅ ATB system (4x speed), buff management
│   │   ├── general.gd               # ✅ Skill execution, cooldown tracking (resets each stage)
│   │   ├── buff.gd                  # ✅ Stat modification system
│   │   ├── card.gd                  # ✅ Card effects and targeting
│   │   └── run_state.gd             # ✅ Run-level state persistence
│   ├── systems/
│   │   ├── battle/
│   │   │   └── battle_manager.gd    # ✅ Wave system, dual-layer timing, state machine
│   │   └── internal_affairs/
│   │       └── internal_affairs_manager.gd  # ✅ Event system
│   ├── tools/
│   │   └── battle_simulator.gd      # ✅ Headless combat simulator
│   └── ui/
│       ├── battle/                  # ✅ SkillBar, CardHand, UnitDisplay, Wave UI
│       ├── internal_affairs/        # ✅ ChoiceButton, InternalAffairsUI
│       ├── enhancement/             # ✅ EnhancementCard (reused by Fateful Encounter)
│       ├── fateful_encounter/       # ✅ NPCPortraitDisplay, FatefulEncounterUI
│       ├── main_menu_ui.gd          # ✅ Main menu
│       ├── victory_ui.gd            # ✅ Victory screen
│       └── defeat_ui.gd             # ✅ Defeat screen
│
├── scenes/
│   ├── main_menu.tscn               # ✅ Entry point
│   ├── battle.tscn                  # ✅ Battle scene (wave-based)
│   ├── battle_simulator.tscn        # ✅ Battle simulator (headless)
│   ├── internal_affairs.tscn        # ✅ Governance choices
│   ├── fateful_encounter.tscn       # ✅ Fateful Encounter (Phase 3D)
│   ├── victory_screen.tscn          # ✅ Victory screen
│   └── defeat_screen.tscn           # ✅ Defeat screen
├── data/
│   ├── generals/                    # ✅ 9 generals YAML
│   ├── units/                       # ✅ 6 unit types YAML
│   ├── cards/                       # ✅ 13 cards YAML
│   ├── events/                      # ✅ 20 events YAML (4 categories)
│   ├── enhancements/                # ✅ 14 enhancements YAML (with theme tags)
│   ├── npcs/                        # ✅ 5 NPCs YAML (Phase 3D)
│   ├── battles/                     # ✅ 3 battle definitions YAML (Phase 4 - Wave system)
│   └── localization/                # ✅ Korean/English (216 strings each)
├── addons/yaml/                     # ✅ godot-yaml parser addon
├── assets/audio/                    # ✅ Battle BGM (looping)
├── docs/                            # ✅ Design documents & guides
│   └── BATTLE_SIMULATOR.md          # ✅ Battle simulator usage guide
├── simulation_config.yaml           # ✅ Battle simulator scenarios
├── output/simulation/               # ✅ Simulator output (CSV/JSON)
└── mods/                            # 🔲 MOD system (Phase 4+)
```

**Legend:**
- ✅ Implemented (Phase 4 Wave system in progress)
- 🔲 Not yet implemented (Phase 4 meta-progression)

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

## Combat System: Dual-Layer Design + Wave System + Grid-Based Corps

The combat system has **two independent timing layers** + **wave-based encounters** + **16×16 grid tactical positioning** (Phase 5):

### Layer 1: Individual Unit ATB
- Each unit has an ATB gauge (0-100)
- Fills at unit's ATB speed (multiplier, base 1.0)
- **Phase 4 optimization**: Scale factor 40 (~2.5s per action for speed 1.0, 4x faster than before)
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
- **Phase 4 fix**: Cooldowns reset to 0 at the start of each new stage (fresh general instances)

### Wave System (Phase 4)
- Each battle consists of 3-4 waves defined in YAML
- **Stage 1**: 3 waves (2, 3, 4 enemies) - Tutorial difficulty
- **Stage 2**: 3 waves (3, 3, 4 enemies) - Medium difficulty
- **Stage 3**: 3 waves (3, 4, 5 enemies) - Final boss with 2 generals
- Wave transition: 2-second pause with "Wave X Complete!" message
- Wave rewards after each wave clear (except first wave):
  - HP recovery (10-20% of max HP)
  - Global turn reset (instant card draw)
  - Buff duration extension (1-3 turns)
- UI displays: Wave counter (top center), transition messages (center screen)
- Enemy units dynamically spawned per wave (previous wave enemies cleared)

### Grid-Based Corps System (Phase 5)
- **16×16 tile grid** with terrain effects (plain, mountain, forest, river, road, wall)
- **Corps = General + Soldiers**: One corps occupies one tile
  - Corps templates define soldier type, count, stats, formations
  - Generals assigned to corps provide leadership bonuses (+1 soldier per 10 leadership)
- **Attack Range** by unit type:
  - Infantry: Range 1 (melee)
  - Cavalry: Range 2 (charge distance)
  - Archer: Range 4-5 (ranged)
- **5 Command Types** (selected when ATB fills):
  - ATTACK: Target enemy corps within range
  - DEFEND: +50% DEF for 1 turn
  - EVADE: +0.3 ATB speed for 1 turn
  - WATCH: Counterattack readiness (TODO)
  - MOVE: Queue movement for next global turn
- **5 Formations** (stat modifiers only, not spatial):
  - 학익진 (Crane Wing): +30% ATK, -10% DEF, +0.1 ATB
  - 봉시진 (Arrow Point): +50% ATK, -30% DEF, +0.2 ATB, +1 MOV
  - 방원진 (Circular): -20% ATK, +50% DEF, -0.2 ATB, -1 MOV
  - 장사진 (Serpent): -15% DEF, +0.15 ATB, +2 MOV
  - 어린진 (Fish Scale): +15% ATK, +15% DEF
- **Movement Phase**: MOVE commands execute during global turns (after card selection)
- **Terrain Effects**: Plains (neutral), Mountains (+DEF), Forest (+DEF, -ATB), River (-DEF, slow), Road (+ATB, -DEF), Wall (impassable)

**Why This Matters:** State management must handle:
- Four pause states: RUNNING, PAUSED_FOR_CARD, WAVE_TRANSITION, MOVEMENT_PHASE
- ATB continues during normal combat
- Skills usable anytime (cooldown-based)
- Card effects that modify buffs/ATB speeds
- Wave transitions with reward application
- General instance recreation between stages (cooldown reset)
- Corps positioning on grid (one corps per tile)
- Attack range validation before attacks
- Command queuing and execution

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

### NPCs (`data/npcs/_schema.yaml`) - Phase 3D
- 5 Korean historical figures: Doseon, Yi Je-ma, Wonhyo, Uisang, Choi Chi-won
- Each NPC has unique dialogue (greeting, dialogue, offer)
- **Enhancement themes**: NPCs offer enhancements matching their themes
  - Geomancy/Medicine (Doseon, Yi Je-ma): healing, defense, support
  - Buddhist Monks (Wonhyo, Uisang): mystic, buff, speed
  - Scholar (Choi Chi-won): tactical, card, command
- Background color for visual theming
- Portrait path (placeholder system in Phase 3D)

### Battles (`data/battles/_schema.yaml`) - Phase 4
- Wave-based battle definitions for each stage
- Each battle has 3-4 waves with enemy composition
- Wave structure:
  - `enemies`: Array of unit IDs with optional general assignments
  - `wave_rewards`: HP recovery %, global turn reset, buff extension
- Example: Stage 1 has 3 waves (2→3→4 enemies), Stage 3 has 3 waves (3→4→5 enemies)
- Supports boss waves with multiple generals

### Terrain (`data/terrain/_schema.yaml`) - Phase 5A
- 6 terrain types with visual and mechanical effects
- Properties: color, movement_cost, defense/attack/atb modifiers, passable flag
- Examples: Plain (neutral), Mountain (+30% DEF, -10% ATK, 2.5× cost), Forest (+20% DEF, -5% ATB, 1.5× cost), River (-20% DEF, -10% ATK, 3× cost), Road (-10% DEF, +5% ATB, 0.5× cost), Wall (impassable)

### Maps (`data/maps/_schema.yaml`) - Phase 5A
- 16×16 grid layouts with terrain IDs
- Spawn zones for ally and enemy corps (Vector2i arrays)
- Example: stage_1_map has central plains with mountain flanks

### Corps (`data/corps/_schema.yaml`) - Phase 5B
- Corps templates: ID, category (infantry/cavalry/archer), soldier count, soldier unit ID
- Base stats: hp_per_soldier, attack_per_soldier, defense, atb_speed, movement_range, **attack_range**
- Available formations (array of formation IDs)
- Traits (optional, same as unit traits)
- General's leadership adds +1 soldier per 10 points

### Formations (`data/formations/_schema.yaml`) - Phase 5B
- Formation definitions with stat modifiers (NOT spatial positioning)
- Modifiers: attack_modifier (%), defense_modifier (%), atb_modifier (flat), movement_modifier (flat)
- Category restrictions (which unit types can use this formation)
- 5 base formations: default, hakik, bongsi, bangwon, jangsa, eorin

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

- **3 turns per internal affairs phase** (fixed, confirmed requirement)
- Each turn: 3 options from categories (Military, Economic, Diplomatic, Personnel)
- Each choice triggers a specific event from that category
- Effects: Stat changes, card acquisition, event flags, penalties
- **20 total events**: 5 Military, 5 Economic, 5 Diplomatic, 5 Personnel

**Architecture Note:** Event flags enable branching choices in later turns/stages. The flag system persists within a run but resets between runs.

**Implementation (Phase 3):**
- `InternalAffairsManager`: Event selection, condition checking, effect execution
- `InternalAffairsUI`: 3 sequential choice displays with category-based styling
- `ChoiceButton`: Individual event option with color-coded categories

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

**Phase 3 (Internal Affairs Connection)** ✅ COMPLETE
- ✅ GameManager autoload (run orchestration, scene transitions)
- ✅ RunState class (full unit state persistence: HP, stats, buffs, general cooldowns)
- ✅ Internal Affairs system (20 events, 4 categories, InternalAffairsManager)
- ✅ Enhancement system (14 enhancements: 5 common, 5 rare, 4 legendary)
- ✅ Main menu, victory/defeat screens with statistics
- ✅ Complete 3-stage run loop
- ✅ Event flag system for branching choices
- ✅ 189 localization strings (Korean + English)

**Phase 3D (Fateful Encounter)** ✅ COMPLETE
- ✅ NPC system (5 legendary figures with unique dialogue)
- ✅ Theme-based enhancement filtering (healing, mystic, tactical, etc.)
- ✅ Narrative-driven encounter UI (Arknights-inspired)
- ✅ NPC portrait display component with theming
- ✅ Fateful Encounter scene replaces simple enhancement selection
- ✅ 14 enhancements extended with theme tags
- ✅ 27 additional localization strings (Korean + English → 216 total)
- ✅ DataManager NPC loading and theme filtering API

**Phase 4 (Wave System & Combat Improvements)** ✅ COMPLETE
- ✅ Wave-based battle system (3-4 waves per stage)
- ✅ Battle data schema and YAML definitions (data/battles/)
- ✅ Wave rewards (HP recovery, global turn reset, buff extension)
- ✅ Wave UI (counter, transition messages)
- ✅ ATB speed optimization (4x faster: 2.5s → from 10s per action)
- ✅ Dynamic enemy spawning per wave
- ✅ General cooldown reset between stages (fresh instances)

**Phase 5 (Corps & Grid System)** 🔄 IN PROGRESS
- ✅ Phase 5A: 16×16 tile-based terrain grid
  - ✅ 6 terrain types with modifiers (plain, mountain, forest, river, road, wall)
  - ✅ TerrainTile and BattleMap classes
  - ✅ 3 stage maps with spawn zones
  - ✅ TileDisplay (40×40px) and TileGridUI (640×640px) components
  - ✅ DataManager terrain/map loading
- ✅ Phase 5B: Corps system
  - ✅ Corps class (general + soldiers, positioning on grid)
  - ✅ 6 corps templates (spear, sword, light/heavy cavalry, archer, crossbow)
  - ✅ Formation class (5 formations: 학익진, 봉시진, 방원진, 장사진, 어린진)
  - ✅ Attack range by unit type (Infantry: 1, Cavalry: 2, Archer: 4-5)
  - ✅ CorpsDisplay component (HP/ATB bars, soldier count)
- ✅ Phase 5C: Enhanced ATB with commands
  - ✅ CorpsCommand class (5 command types)
  - ✅ CommandPanel UI (ATTACK, DEFEND, EVADE, WATCH, MOVE)
  - ✅ MovementOverlay (range highlighting, destination selection)
  - ✅ Movement phase execution during global turns
  - ✅ BattleManager command queue and execution
  - ✅ Attack range validation
  - ✅ CorpsBattleUI integration (test scene)
  - ✅ 67 additional localization strings (Korean + English → 283 total)
- 🔲 Integration with existing wave battle system (replace unit-based with corps-based)
- 🔲 SaveManager implementation (save/load functionality)
- 🔲 Meta-progression unlocks (permanent upgrades)

## Implementation Status

### ✅ Completed Components (Phase 5 Corps System)

**Core Classes:**
- `src/core/unit.gd` - ATB system (4x speed), buff management, effective stat calculation
- `src/core/general.gd` - Skill execution, cooldown tracking (resets each stage)
- `src/core/buff.gd` - Stat modification (buffs/debuffs) with duration tracking
- `src/core/card.gd` - Card effect execution, targeting, penalty system
- `src/core/run_state.gd` - Run-level state persistence (unit states, deck, enhancements, event flags)
- `src/core/terrain_tile.gd` - Terrain data with stat modifiers (Phase 5A)
- `src/core/battle_map.gd` - 16×16 grid with spawn zones (Phase 5A)
- `src/core/corps.gd` - Corps (general + soldiers), ATB, attack range (Phase 5B)
- `src/core/formation.gd` - Formation stat modifiers (Phase 5B)
- `src/core/corps_command.gd` - Command system (5 types) (Phase 5C)

**Autoload Managers:**
- `src/autoload/data_manager.gd` - YAML loading, battle data, NPC/theme filtering, localization, factory methods
- `src/autoload/game_manager.gd` - Run orchestration, scene transitions, wave battle integration
- `src/autoload/save_manager.gd` - Meta-progression stub (Phase 4)

**Systems:**
- `src/systems/battle/battle_manager.gd` - Wave system, corps positioning, command queue, attack range, state machine (RUNNING/PAUSED_FOR_CARD/WAVE_TRANSITION/MOVEMENT_PHASE)
- `src/systems/internal_affairs/internal_affairs_manager.gd` - Event selection, effect execution

**UI Components:**
- Battle (Unit-based): `battle_ui.gd`, `unit_display.gd`, `skill_bar.gd`, `skill_button.gd`, `card_hand.gd`, `card_display.gd`
- Battle (Corps-based): `tile_display.gd`, `tile_grid_ui.gd`, `corps_display.gd`, `command_panel.gd`, `movement_overlay.gd`, `corps_battle_ui.gd` (Phase 5)
- Internal Affairs: `internal_affairs_ui.gd`, `choice_button.gd`
- Fateful Encounter: `fateful_encounter_ui.gd`, `npc_portrait_display.gd`, `enhancement_card.gd` (reused)
- Menus: `main_menu_ui.gd`, `victory_ui.gd`, `defeat_ui.gd`

**Data Layer:**
- All YAML data files:
  - 9 generals with skills (hubaekje.yaml, taebong.yaml, silla.yaml)
  - 6 unit types (base_units.yaml)
  - 13 cards (starter_deck.yaml, advanced_cards.yaml)
  - 20 events (military_events.yaml, economic_events.yaml, diplomatic_events.yaml, personnel_events.yaml)
  - 14 enhancements with theme tags (combat_enhancements.yaml)
  - 5 NPCs with dialogue (fateful_encounter_npcs.yaml)
  - 3 battle definitions (stage_battles.yaml) - Phase 4 Wave system
  - 6 terrain types (base_terrain.yaml) - Phase 5A
  - 3 stage maps (stage_maps.yaml) - Phase 5A
  - 6 corps templates (base_corps.yaml) - Phase 5B
  - 5 formations (base_formations.yaml) - Phase 5B
  - 283 localization strings each language (ko.yaml, en.yaml)

**Critical Implementation Notes:**
1. **godot-yaml API**: Uses `YAML.parse()` with `has_error()` and `get_data()` methods (fimbul-works version)
2. **Keyword Conflict**: Avoid using "trait" as variable name (reserved keyword) - use "trait_data" instead
3. **RefCounted Classes**: Unit, General, Card, Buff, RunState all extend RefCounted (not Node)
4. **UI Timing**: All UI components create children in `_init()`, but set text in `_ready()` (after DataManager loads)
5. **Class Preloading**: All files preload dependencies using `const` (e.g., `const Buff = preload("...")`)
6. **Null Safety**: YAML optional fields checked with `data.get("field", null)` before assignment to typed properties
7. **Skills ATB-Independent**: Skills do NOT require or reset ATB (Phase 2 design revision)
8. **Buff Duration**: Ticks on global turns only (not ATB turns) for consistency
9. **Audio Looping**: Set `stream.loop = true` in code for reliable looping (import file settings may not persist)
10. **Scene Z-Index**: Background ColorRects use `z_index = -1` to prevent covering UI elements
11. **Await Safety**: Check `is_inside_tree()` before and after `await` to prevent errors during scene transitions
12. **Localization Timing**: Never call `DataManager.get_localized()` in `_init()` - DataManager loads after scene instantiation
13. **Cooldown Reset Between Stages**: General instances recreated in `_prepare_next_stage()` to reset cooldowns to 0 (not persisted in RunState)
14. **Debug Force Victory/Defeat**: Use direct HP/alive manipulation instead of `take_damage()` to bypass defense calculations
15. **Wave UI Duplication Fix**: In wave battles, `_on_battle_started()` only creates enemy UI if `total_waves == 0` (standalone test), otherwise `_on_wave_started()` creates enemy UI
16. **ATB Speed Scale Factor**: Set to 40 in `unit.gd:62` for ~2.5s per action (4x faster than original 10s)
17. **Corps Attack Range** (Phase 5B): All attacks validate range before execution. Infantry (1), Cavalry (2), Archer (4-5). Use `corps.is_target_in_range(target)` to check. UI highlights only valid targets.
18. **Corps Mouse Filter** (Phase 5C): All child elements in CorpsDisplay must have `mouse_filter = MOUSE_FILTER_IGNORE` to prevent blocking parent click events

### 🔲 Not Yet Implemented (Phase 5+)

**Corps-Unit Integration:**
- Replace unit-based wave battles with corps-based battles
- Integrate grid/terrain system into main battle scene
- Card system targeting for corps instead of units

**MOD System:**
- MOD loading from `mods/` directory
- Deep merge strategy
- load_order priority handling
- Asset override support

**Meta-Progression:**
- SaveManager implementation (save/load)
- Permanent unlocks across runs
- Player progression tracking

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
