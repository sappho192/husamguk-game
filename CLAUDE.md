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
  ↓ Random NPC appears (1 of 5: Jwaja, Hwata, Ugil, Namhwa, Sugyeong)
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

### Project Structure (Phase 3D Complete)

```
husamguk/
├── src/
│   ├── autoload/                    # Global singletons
│   │   ├── data_manager.gd          # ✅ YAML loading, NPC/theme filtering, localization
│   │   ├── game_manager.gd          # ✅ Run orchestration, scene transitions
│   │   └── save_manager.gd          # ✅ Stub for Phase 4
│   ├── core/                        # Data classes
│   │   ├── unit.gd                  # ✅ ATB system, buff management
│   │   ├── general.gd               # ✅ Skill execution, cooldown tracking
│   │   ├── buff.gd                  # ✅ Stat modification system
│   │   ├── card.gd                  # ✅ Card effects and targeting
│   │   └── run_state.gd             # ✅ Run-level state persistence
│   ├── systems/
│   │   ├── battle/
│   │   │   └── battle_manager.gd    # ✅ Dual-layer timing, state machine
│   │   └── internal_affairs/
│   │       └── internal_affairs_manager.gd  # ✅ Event system
│   ├── tools/
│   │   └── battle_simulator.gd      # ✅ Headless combat simulator (Phase 3D+)
│   └── ui/
│       ├── battle/                  # ✅ SkillBar, CardHand, UnitDisplay, etc.
│       ├── internal_affairs/        # ✅ ChoiceButton, InternalAffairsUI
│       ├── enhancement/             # ✅ EnhancementCard (reused by Fateful Encounter)
│       ├── fateful_encounter/       # ✅ NPCPortraitDisplay, FatefulEncounterUI
│       ├── main_menu_ui.gd          # ✅ Main menu
│       ├── victory_ui.gd            # ✅ Victory screen
│       └── defeat_ui.gd             # ✅ Defeat screen
│
├── scenes/
│   ├── main_menu.tscn               # ✅ Entry point
│   ├── battle.tscn                  # ✅ Battle scene
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
- ✅ Implemented (Phase 3D complete)
- 🔲 Not yet implemented (Phase 4+)

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

### NPCs (`data/npcs/_schema.yaml`) - Phase 3D
- 5 legendary figures: Jwaja, Hwata, Ugil, Namhwa, Sugyeong
- Each NPC has unique dialogue (greeting, dialogue, offer)
- **Enhancement themes**: NPCs offer enhancements matching their themes
  - Medical (Jwaja, Hwata): healing, defense, support
  - Mystic (Ugil, Namhwa): mystic, buff, speed
  - Strategist (Sugyeong): tactical, card, command
- Background color for visual theming
- Portrait path (placeholder system in Phase 3D)

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

**Phase 4 (Meta-Progression)** 🔲 NEXT
- 🔲 SaveManager implementation (save/load functionality)
- 🔲 Meta-progression unlocks (permanent upgrades)
- 🔲 Enemy scaling across stages
- 🔲 Additional content (more events, enhancements, cards)
- 🔲 Balance tuning and polish

## Implementation Status

### ✅ Completed Components (Phase 3D)

**Core Classes:**
- `src/core/unit.gd` - ATB system, buff management, effective stat calculation
- `src/core/general.gd` - Skill execution, cooldown tracking
- `src/core/buff.gd` - Stat modification (buffs/debuffs) with duration tracking
- `src/core/card.gd` - Card effect execution, targeting, penalty system
- `src/core/run_state.gd` - Run-level state persistence (unit states, deck, enhancements, event flags)

**Autoload Managers:**
- `src/autoload/data_manager.gd` - YAML loading, NPC/theme filtering, localization, factory methods
- `src/autoload/game_manager.gd` - Run orchestration, scene transitions (updated to Fateful Encounter)
- `src/autoload/save_manager.gd` - Meta-progression stub (Phase 4)

**Systems:**
- `src/systems/battle/battle_manager.gd` - Dual-layer timing, state machine (RUNNING/PAUSED_FOR_CARD)
- `src/systems/internal_affairs/internal_affairs_manager.gd` - Event selection, effect execution

**UI Components:**
- Battle: `battle_ui.gd`, `unit_display.gd`, `skill_bar.gd`, `skill_button.gd`, `card_hand.gd`, `card_display.gd`
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
  - 216 localization strings each language (ko.yaml, en.yaml)

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
13. **Cooldown Reset Between Battles**: General skill cooldowns are NOT persisted in RunState - they reset to 0 at the start of each new battle stage (all skills available)
14. **Debug Force Victory/Defeat**: Use direct HP/alive manipulation instead of `take_damage()` to bypass defense calculations

### 🔲 Not Yet Implemented (Phase 4+)

**Formation System:**
- Pre-battle formation selection UI
- Front/back positioning logic (currently hardcoded in unit data)

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
