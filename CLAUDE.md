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

### Project Structure (Planned)

```
husamguk/
├── src/
│   ├── autoload/              # Global singletons
│   ├── core/                  # Data classes (general.gd, unit.gd, card.gd, etc.)
│   ├── systems/
│   │   ├── internal_affairs/  # Governance choice system
│   │   ├── battle/            # ATB combat + global turns
│   │   └── roguelite/         # Enhancement/meta-progression
│   └── ui/                    # UI components by scene
│
├── scenes/                    # .tscn files
├── data/                      # Base YAML data (generals, units, cards, events, localization)
├── assets/                    # Sprites, audio, fonts
└── mods/                      # User MOD extensions
```

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
- Gauge reaches 100 → unit ready for action
- Player chooses: skill (with cooldown) or auto-attack
- **Continuous**: No global pause, units act as they become ready

### Layer 2: Global Turn System
- Separate tick every ~10 seconds
- **Pauses individual ATB** during card selection
- Player uses 1 card from deck (max 1 card/global turn)
- Resumes individual ATB after card resolution

**Why This Matters:** State management must handle:
- ATB progression while global turn is inactive
- Pause/resume during card usage
- Skill cooldowns vs global turn count
- Card effects that modify ATB speeds

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

**Phase 1 (Priority):** Battle Core
- YAML parser integration (addon needed)
- Unit class with ATB system
- Basic attack mechanics, combat UI
- Battle end conditions

**Phase 2:** Combat Expansion
- General unique skills
- Global turn card system
- Card deck and drawing
- Formation selection

**Phase 3:** Internal Affairs Connection
- Governance UI (3 choice display)
- Stage progression flow
- Enhancement selection screen

**Phase 4:** Full Loop
- 3-stage connection
- Game over/clear conditions
- Main menu integration
- SaveManager persistence

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
