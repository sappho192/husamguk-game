# 후삼국시대 로그라이트 전략 게임 - 기술 설계 문서

## 1. 개발 환경

| 항목 | 내용 |
|------|------|
| 엔진 | Godot Engine 4.5 |
| 언어 | GDScript |
| 그래픽 | 3D like (prerendered 2D) |
| 데이터 포맷 | YAML |
| 타겟 플랫폼 | PC (게임패드 지원) |

---

## 2. 프로젝트 구조

### 2.1 Phase 5C 구현 상태 (2025-12)

```
husamguk/                         # Godot 프로젝트 루트
├── project.godot                 # ✅ DataManager, GameManager autoload 등록
│
├── addons/
│   └── yaml/                     # ✅ godot-yaml (fimbul-works)
│
├── src/                          # 게임 코드
│   ├── autoload/                 # 싱글톤
│   │   ├── data_manager.gd       # ✅ YAML 로딩, 로컬라이제이션, 팩토리, 지형/맵/부대 로딩
│   │   ├── game_manager.gd       # ✅ 런 오케스트레이션, 씬 전환, 웨이브 전투
│   │   └── save_manager.gd       # ✅ 스텁 (Phase 7 구현 예정)
│   │
│   ├── core/                     # 핵심 데이터 클래스
│   │   ├── general.gd            # ✅ 장수, 스킬 실행, 쿨다운
│   │   ├── unit.gd               # ✅ ATB, 전투 로직, 특성 보너스
│   │   ├── buff.gd               # ✅ 버프/디버프 시스템
│   │   ├── card.gd               # ✅ 카드 효과 실행, 타겟팅
│   │   ├── run_state.gd          # ✅ 런 레벨 상태 지속성
│   │   ├── terrain_tile.gd       # ✅ 지형 데이터, 스탯 수정자 (Phase 5A)
│   │   ├── battle_map.gd         # ✅ 16×16 그리드, 스폰 존 (Phase 5A)
│   │   ├── corps.gd              # ✅ 부대 (장수 + 병사), ATB, 공격 범위 (Phase 5B)
│   │   ├── formation.gd          # ✅ 진형 스탯 수정자 (Phase 5B)
│   │   └── corps_command.gd      # ✅ 명령 시스템 (5가지 타입) (Phase 5C)
│   │
│   ├── systems/
│   │   ├── battle/
│   │   │   └── battle_manager.gd # ✅ 웨이브 시스템, 부대 배치, 명령 큐, 공격 범위, 상태 머신
│   │   └── internal_affairs/
│   │       └── internal_affairs_manager.gd  # ✅ 내정 이벤트 시스템
│   │
│   ├── tools/
│   │   └── battle_simulator.gd   # ✅ Headless 전투 시뮬레이터
│   │
│   └── ui/
│       ├── battle/
│       │   ├── battle_ui.gd      # ✅ 메인 전투 컨트롤러 (유닛 기반)
│       │   ├── unit_display.gd   # ✅ HP/ATB 바, 시각 피드백
│       │   ├── skill_bar.gd      # ✅ 스킬 UI (왼쪽 사이드바)
│       │   ├── skill_button.gd   # ✅ 개별 스킬 버튼
│       │   ├── card_hand.gd      # ✅ 카드 핸드 UI (하단)
│       │   ├── card_display.gd   # ✅ 개별 카드 표시
│       │   ├── placeholder_sprite.gd  # ✅ 플레이스홀더 그래픽
│       │   ├── tile_display.gd   # ✅ 단일 타일 UI (Phase 5A)
│       │   ├── tile_grid_ui.gd   # ✅ 16×16 그리드 UI (Phase 5A)
│       │   ├── corps_display.gd  # ✅ 부대 정보 오버레이 (Phase 5B)
│       │   ├── command_panel.gd  # ✅ 명령 선택 UI (Phase 5C)
│       │   ├── movement_overlay.gd  # ✅ 이동 범위 오버레이 (Phase 5C)
│       │   └── corps_battle_ui.gd  # ✅ 부대 전투 통합 (Phase 5C)
│       ├── internal_affairs/
│       │   ├── internal_affairs_ui.gd  # ✅ 내정 선택 화면
│       │   └── choice_button.gd  # ✅ 선택지 버튼
│       ├── enhancement/
│       │   └── enhancement_card.gd  # ✅ 강화 카드 표시 (운명적 조우에서 재사용)
│       ├── fateful_encounter/
│       │   ├── fateful_encounter_ui.gd  # ✅ 운명적 조우 화면 (Phase 3D)
│       │   └── npc_portrait_display.gd  # ✅ NPC 초상화 및 대화 표시
│       ├── main_menu_ui.gd       # ✅ 메인 메뉴
│       ├── victory_ui.gd         # ✅ 승리 화면
│       └── defeat_ui.gd          # ✅ 패배 화면
│
├── scenes/
│   ├── main_menu.tscn            # ✅ 진입점
│   ├── battle.tscn               # ✅ 전투 씬 (웨이브 기반, Phase 4)
│   ├── battle_simulator.tscn     # ✅ 전투 시뮬레이터 (headless)
│   ├── internal_affairs.tscn     # ✅ 내정 씬
│   ├── fateful_encounter.tscn    # ✅ 운명적 조우 씬 (Phase 3D)
│   ├── corps_battle_test.tscn    # ✅ 부대 전투 테스트 씬 (Phase 5)
│   ├── victory_screen.tscn       # ✅ 승리 화면
│   └── defeat_screen.tscn        # ✅ 패배 화면
│
├── data/                         # YAML 데이터
│   ├── generals/
│   │   ├── _schema.yaml          # ✅ 스키마 정의
│   │   ├── hubaekje.yaml         # ✅ 견훤, 신검, 진홍애
│   │   ├── taebong.yaml          # ✅ 왕건, 홍유, 복지겸일
│   │   └── silla.yaml            # ✅ 신라 3장수 (총 9명)
│   ├── units/
│   │   ├── _schema.yaml          # ✅ 스키마 정의
│   │   └── base_units.yaml       # ✅ 6종 병종
│   ├── cards/
│   │   ├── _schema.yaml          # ✅ 스키마 정의
│   │   ├── starter_deck.yaml     # ✅ 기본 덱 (5장)
│   │   └── advanced_cards.yaml   # ✅ 고급 카드 (8장, 총 13장)
│   ├── events/
│   │   ├── _schema.yaml          # ✅ 스키마 정의
│   │   ├── military_events.yaml  # ✅ 군사 이벤트 (5개)
│   │   ├── economic_events.yaml  # ✅ 경제 이벤트 (5개)
│   │   ├── diplomatic_events.yaml  # ✅ 외교 이벤트 (5개)
│   │   └── personnel_events.yaml  # ✅ 인사 이벤트 (5개, 총 20개)
│   ├── enhancements/
│   │   ├── _schema.yaml          # ✅ 스키마 정의
│   │   └── combat_enhancements.yaml  # ✅ 14개 강화 (테마 태그 포함, Phase 3D)
│   ├── npcs/                     # ✅ Phase 3D - 운명적 조우
│   │   ├── _schema.yaml          # ✅ NPC 스키마 정의
│   │   └── fateful_encounter_npcs.yaml  # ✅ 5명 NPC (도선국사, 이제마, 원효, 의상, 최치원)
│   ├── battles/                  # ✅ Phase 4 - 웨이브 시스템
│   │   ├── _schema.yaml          # ✅ 전투 스키마 정의
│   │   └── stage_battles.yaml    # ✅ 3개 스테이지 전투 정의
│   ├── terrain/                  # ✅ Phase 5A - 지형 시스템
│   │   ├── _schema.yaml          # ✅ 지형 스키마 정의
│   │   └── base_terrain.yaml     # ✅ 6개 지형 타입
│   ├── maps/                     # ✅ Phase 5A - 맵 데이터
│   │   ├── _schema.yaml          # ✅ 맵 스키마 정의
│   │   └── stage_maps.yaml       # ✅ 3개 스테이지 맵
│   ├── corps/                    # ✅ Phase 5B - 부대 시스템
│   │   ├── _schema.yaml          # ✅ 부대 스키마 정의
│   │   └── base_corps.yaml       # ✅ 6개 부대 템플릿
│   ├── formations/               # ✅ Phase 5B - 진형 시스템
│   │   ├── _schema.yaml          # ✅ 진형 스키마 정의
│   │   └── base_formations.yaml  # ✅ 5개 진형
│   └── localization/
│       ├── ko.yaml               # ✅ 한국어 (283 스트링, Phase 5C)
│       └── en.yaml               # ✅ 영어 (283 스트링, Phase 5C)
│
├── docs/                         # 설계 문서 & 가이드
│   └── BATTLE_SIMULATOR.md       # ✅ 전투 시뮬레이터 사용 가이드
├── simulation_config.yaml        # ✅ 전투 시뮬레이터 시나리오
├── output/simulation/            # ✅ 시뮬레이터 출력 (CSV/JSON)
│
└── assets/
    └── audio/
        └── bgm/
            └── battle_theme.ogg  # ✅ 전투 BGM (루핑)

**범례:**
- ✅ Phase 5C 구현 완료
- 🔲 향후 Phase 구현 예정 (Phase 6+)
```

### 2.2 전체 구조 (계획)

```
project_root/
├── project.godot
├── addons/
│   └── yaml/                     # YAML 파싱 플러그인
│
├── src/                          # 게임 코드
│   ├── autoload/                 # 싱글톤 (전역 매니저)
│   │   ├── game_manager.gd       # ✅ Phase 3
│   │   ├── data_manager.gd       # ✅ Phase 1
│   │   ├── save_manager.gd       # ✅ Phase 3 (스텁, Phase 4 구현)
│   │   └── audio_manager.gd      # 🔲 Phase 4
│   │
│   ├── core/                     # 핵심 데이터 클래스
│   │   ├── general.gd            # ✅ Phase 2
│   │   ├── unit.gd               # ✅ Phase 1
│   │   ├── buff.gd               # ✅ Phase 2
│   │   ├── card.gd               # ✅ Phase 2
│   │   ├── run_state.gd          # ✅ Phase 3
│   │   ├── nation.gd             # 🔲 Phase 4 (데이터만 Phase 3)
│   │   └── event.gd              # 🔲 Phase 4 (데이터만 Phase 3)
│   │
│   ├── systems/                  # 게임 시스템
│   │   ├── internal_affairs/     # ✅ Phase 3
│   │   ├── battle/               # ✅ Phase 2
│   │   └── roguelite/            # ✅ Phase 3 (GameManager)
│   │
│   └── ui/                       # UI 컴포넌트
│       ├── common/               # 🔲 Phase 4
│       ├── main_menu_ui.gd       # ✅ Phase 3
│       ├── victory_ui.gd         # ✅ Phase 3
│       ├── defeat_ui.gd          # ✅ Phase 3
│       ├── internal_affairs/     # ✅ Phase 3
│       ├── enhancement/          # ✅ Phase 3
│       └── battle/               # ✅ Phase 2
│
├── scenes/                       # 씬 파일 (.tscn)
│   ├── main.tscn                 # 🔲 Phase 4 (project.godot에서 설정)
│   ├── main_menu.tscn            # ✅ Phase 3
│   ├── battle.tscn               # ✅ Phase 1
│   ├── internal_affairs.tscn     # ✅ Phase 3
│   ├── enhancement_selection.tscn  # ✅ Phase 3
│   ├── victory_screen.tscn       # ✅ Phase 3
│   └── defeat_screen.tscn        # ✅ Phase 3
│
├── data/                         # 기본 게임 데이터 (YAML)
│   ├── generals/                 # ✅ Phase 1 (9명)
│   ├── units/                    # ✅ Phase 1 (6종)
│   ├── nations/                  # 🔲 Phase 4 (국가별 보너스 구현 예정)
│   ├── cards/                    # ✅ Phase 2 (13장)
│   ├── events/                   # ✅ Phase 3 (20개, 4 카테고리)
│   ├── enhancements/             # ✅ Phase 3 (14개)
│   └── localization/             # ✅ Phase 3 (ko, en - 189 스트링)
│
├── assets/                       # 기본 에셋
│   ├── sprites/                  # 🔲 플레이스홀더 사용중
│   ├── ui/                       # 🔲 플레이스홀더 사용중
│   ├── audio/                    # ✅ Phase 3 (전투 BGM)
│   └── fonts/                    # 🔲 미구현
│
└── mods/                         # 🔲 MOD 시스템 Phase 4
    └── example_mod/
        ├── mod.yaml
        ├── data/
        └── assets/
```

---

## 3. 핵심 아키텍처

### 3.1 데이터 흐름

```
[YAML 파일들]
     ↓
[DataManager] ─── MOD 파일 병합 ───→ [런타임 Dictionary]
     ↓
[Factory 패턴으로 객체 생성]
     ↓
[GameManager가 게임 상태 관리]
     ↓
[각 System이 로직 처리]
     ↓
[UI가 시그널로 상태 반영]
```

### 3.2 주요 Autoload

| 이름 | 역할 | 구현 상태 |
|------|------|----------|
| `GameManager` | 런 상태 관리(RunState), 스테이지 진행(1-3), 씬 전환, 게임 흐름 제어 | ✅ Phase 3 |
| `DataManager` | YAML 로딩, MOD 병합, 데이터 조회 API, 팩토리 패턴 객체 생성 | ✅ Phase 1 |
| `SaveManager` | 메타 프로그레션 저장/로드 (영구 업그레이드, 언락) | ✅ 스텁 (Phase 4 구현) |
| `AudioManager` | BGM/SFX 재생, 볼륨 제어 | 🔲 Phase 4 |

### 3.3 시그널 기반 통신

```gdscript
# 예: 전투에서 유닛 행동 시
signal unit_action_ready(unit: Unit)
signal unit_took_damage(unit: Unit, amount: int)
signal global_turn_triggered(turn_number: int)
signal battle_ended(result: BattleResult)
```

### 3.4 완전한 게임 루프 (Phase 3 구현)

```
메인 메뉴 (main_menu.tscn)
  ↓
[새 게임 시작] GameManager.start_new_run()
  ↓ RunState 생성, current_stage = 1
  ↓
전투 1단계 (battle.tscn)
  ↓ BattleManager: 이중 레이어 타이밍 (ATB + 글로벌 턴)
  ↓ [승리] GameManager.on_battle_ended()
  ↓ RunState에 유닛 상태 저장 (HP, 스탯, 버프, 쿨다운)
  ↓
내정 (internal_affairs.tscn)
  ↓ 3턴, 각 턴마다 4개 카테고리(군사/경제/외교/인사)에서 3개 선택지
  ↓ InternalAffairsManager.execute_event()
  ↓ RunState 수정 (스탯, 덱, 이벤트 플래그, 페널티)
  ↓
강화 선택 (enhancement_selection.tscn)
  ↓ 3개 강화 중 1개 선택 (1 common, 1 rare, 1 legendary)
  ↓ GameManager.on_enhancement_selected()
  ↓ RunState.active_enhancements에 추가
  ↓ current_stage += 1
  ↓
전투 2단계
  ↓ RunState에서 유닛 복원 (HP, 스탯, 버프 유지)
  ↓ 강화 효과 적용
  ↓ [승리] → 내정 → 강화 선택
  ↓
전투 3단계 (최종 전투)
  ↓ [승리 또는 패배]
  ↓
승리/패배 화면 (victory_screen.tscn / defeat_screen.tscn)
  ↓ 런 통계 표시 (클리어 스테이지, 전투 승리, 선택한 내정, 강화)
  ↓ [메인 메뉴로] GameManager.clear_run()
  ↓ RunState = null
  ↓
메인 메뉴
```

**핵심 특징:**
- **RunState 지속성**: 전투 → 내정 → 강화 사이클 간 모든 상태 유지
- **3 스테이지 구조**: 각 스테이지 = 전투 → 내정 → 강화 (3단계는 강화 없음)
- **내정 턴 제한**: 정확히 3턴, 각 턴마다 3개 선택지
- **강화 희귀도**: Common 5개, Rare 5개, Legendary 4개 풀에서 랜덤 선택
- **이벤트 플래그**: 내정 선택에 따른 분기 가능, 런 내에서만 유지

---

## 4. 데이터 구조 (YAML 스키마)

### 4.1 장수 (generals/*.yaml)

```yaml
# data/generals/hubaekje.yaml
generals:
  - id: "gyeonhwon"
    name_key: "GENERAL_GYEONHWON"  # 로컬라이제이션 키
    nation: "hubaekje"
    role: "assault"  # assault | command | special
    portrait: "res://assets/sprites/portraits/gyeonhwon.png"
    
    base_stats:
      leadership: 92
      combat: 95
      intelligence: 78
      politics: 65
    
    skill:
      id: "fury_of_baekje"
      name_key: "SKILL_FURY_OF_BAEKJE"
      description_key: "SKILL_FURY_OF_BAEKJE_DESC"
      cooldown: 3  # ATB 턴 기준
      effect:
        type: "damage"
        target: "single_enemy"
        multiplier: 2.5
        bonus_condition:
          trigger: "target_hp_above_50"
          extra_multiplier: 0.5
    
    unique_events:
      - "event_founding_hubaekje"
      - "event_silla_invasion"
```

### 4.2 병종/유닛 (units/*.yaml)

```yaml
# data/units/infantry.yaml
units:
  - id: "spearman"
    name_key: "UNIT_SPEARMAN"
    category: "infantry"
    sprite_sheet: "res://assets/sprites/units/spearman.png"
    
    base_stats:
      hp: 100
      attack: 25
      defense: 30
      atb_speed: 1.0  # 기준값 1.0
    
    traits:
      - id: "anti_cavalry"
        description_key: "TRAIT_ANTI_CAVALRY"
        effect:
          damage_bonus_vs: "cavalry"
          bonus_percent: 50
    
    formation_position: "front"  # front | back
```

### 4.3 국가 (nations/*.yaml)

```yaml
# data/nations/hubaekje.yaml
nation:
  id: "hubaekje"
  name_key: "NATION_HUBAEKJE"
  color: "#C41E3A"  # UI 테마 색상
  emblem: "res://assets/sprites/emblems/hubaekje.png"
  
  playstyle:
    description_key: "NATION_HUBAEKJE_STYLE"
    atb_modifier: 1.15      # 전체 ATB 15% 빠름
    attack_modifier: 1.10   # 공격력 10% 증가
    defense_modifier: 0.95  # 방어력 5% 감소
  
  starting_cards:
    - "card_aggressive_charge"
    - "card_intimidate"
    - "card_plunder"
  
  playable_generals:
    - "gyeonhwon"
    - "singeom"
    - "general_hubaekje_3"
```

### 4.4 강화 카드 (cards/*.yaml)

```yaml
# data/cards/tactics.yaml
cards:
  - id: "card_aggressive_charge"
    name_key: "CARD_AGGRESSIVE_CHARGE"
    description_key: "CARD_AGGRESSIVE_CHARGE_DESC"
    rarity: "common"  # common | uncommon | rare | legendary
    icon: "res://assets/ui/cards/aggressive_charge.png"
    
    effect:
      type: "buff"
      target: "all_allies"
      stat: "attack"
      value: 20
      value_type: "percent"
      duration: 2  # 글로벌 턴 수
    
    penalty: null  # 페널티 없음

  - id: "card_desperate_assault"
    name_key: "CARD_DESPERATE_ASSAULT"
    rarity: "rare"
    
    effect:
      type: "buff"
      target: "all_allies"
      stat: "attack"
      value: 40
      value_type: "percent"
      duration: 3
    
    penalty:
      type: "dot"  # damage over time
      target: "all_allies"
      stat: "hp"
      value: 5
      value_type: "percent"
      duration: 3
```

### 4.5 이벤트 (events/*.yaml)

```yaml
# data/events/hubaekje_story.yaml
events:
  - id: "event_founding_hubaekje"
    type: "fixed"  # fixed | random
    trigger:
      stage: 1
      timing: "stage_end"
      nation: "hubaekje"
    
    title_key: "EVENT_FOUNDING_HUBAEKJE_TITLE"
    description_key: "EVENT_FOUNDING_HUBAEKJE_DESC"
    illustration: "res://assets/sprites/events/founding.png"
    
    choices:
      - id: "choice_declare"
        text_key: "EVENT_FOUNDING_CHOICE_DECLARE"
        effects:
          - type: "add_card"
            card_id: "card_kings_authority"
          - type: "modify_stat"
            target: "nation"
            stat: "morale"
            value: 20

  - id: "event_hojok_submit"
    type: "random"
    trigger:
      stage: [1, 2]
      timing: "internal_affairs"
      probability: 0.15
    
    choices:
      - id: "accept"
        text_key: "EVENT_HOJOK_ACCEPT"
        effects:
          - type: "add_troops"
            value: 30
            value_type: "percent"
        consequences:
          - type: "flag"
            flag: "hojok_betrayal_possible"
            
      - id: "refuse"
        text_key: "EVENT_HOJOK_REFUSE"
        effects:
          - type: "modify_stat"
            stat: "morale"
            value: 20
        consequences:
          - type: "add_enemy"
            enemy_id: "hojok_army"
            
      - id: "marriage"  # 조건부 선택지
        text_key: "EVENT_HOJOK_MARRIAGE"
        condition:
          general: "wanggeon"
        effects:
          - type: "add_passive"
            passive_id: "hojok_alliance"
```

### 4.6 강화 (enhancements/*.yaml)

```yaml
# data/enhancements/combat_enhancements.yaml
enhancements:
  - id: "enhancement_first_strike"
    name_key: "ENHANCEMENT_FIRST_STRIKE"
    description_key: "ENHANCEMENT_FIRST_STRIKE_DESC"
    rarity: "common"  # common | rare | legendary
    icon: "res://assets/ui/enhancements/first_strike.png"

    effect:
      type: "combat_modifier"
      trigger: "battle_start"
      stat: "atb_current"
      target: "all_allies"
      value: 50  # 전투 시작 시 아군 전체 ATB +50

  - id: "enhancement_veteran_troops"
    name_key: "ENHANCEMENT_VETERAN_TROOPS"
    rarity: "rare"

    effect:
      type: "stat_modifier"
      trigger: "permanent"
      stats:
        - stat: "attack"
          value: 15
          value_type: "percent"
        - stat: "defense"
          value: 10
          value_type: "percent"

  - id: "enhancement_legendary_commander"
    name_key: "ENHANCEMENT_LEGENDARY_COMMANDER"
    rarity: "legendary"

    effects:  # 복수 효과 가능
      - type: "stat_modifier"
        trigger: "permanent"
        stat: "attack"
        value: 25
        value_type: "percent"
      - type: "ability"
        trigger: "battle_start"
        ability_id: "mass_morale_boost"
        cooldown_reduction: 1
```

**희귀도별 밸런스:**
- **Common (5개)**: 단순 스탯 증가 (~10%), 전투 시작 보너스
- **Rare (5개)**: 복합 스탯 증가 (~15%), 특수 능력 쿨다운 감소
- **Legendary (4개)**: 강력한 복합 효과 (~25%), 게임 플레이 변화 능력

### 4.7 로컬라이제이션 (localization/*.yaml)

```yaml
# data/localization/ko.yaml
locale: "ko"

strings:
  # 국가
  NATION_HUBAEKJE: "후백제"
  NATION_TAEBONG: "태봉"
  NATION_SILLA: "신라"

  # 장수
  GENERAL_GYEONHWON: "견훤"
  GENERAL_WANGGEON: "왕건"

  # 스킬
  SKILL_FURY_OF_BAEKJE: "백제의 분노"
  SKILL_FURY_OF_BAEKJE_DESC: "단일 적에게 250%의 피해를 입힌다. 대상 HP가 50% 이상이면 추가 50% 피해."

  # UI
  UI_START_RUN: "출정하기"
  UI_CONTINUE: "계속하기"
  UI_SETTINGS: "설정"
```

### 4.8 전투 (battles/*.yaml) - Phase 4

```yaml
# data/battles/stage_battles.yaml
battles:
  - id: "stage_1_battle"
    name_key: "BATTLE_STAGE_1"
    difficulty: "tutorial"

    waves:
      - wave_number: 1
        enemies:
          - unit_id: "spearman"
          - unit_id: "swordsman"

      - wave_number: 2
        enemies:
          - unit_id: "spearman"
          - unit_id: "archer"
          - unit_id: "swordsman"
        wave_rewards:
          hp_recovery_percent: 10
          global_turn_reset: true
          buff_extension_turns: 1

      - wave_number: 3
        enemies:
          - unit_id: "light_cavalry"
          - unit_id: "archer"
          - unit_id: "spearman"
          - unit_id: "swordsman"
            general_id: "enemy_general_1"  # 보스 웨이브
        wave_rewards:
          hp_recovery_percent: 20
          global_turn_reset: true
          buff_extension_turns: 2
```

**웨이브 보상 설명:**
- `hp_recovery_percent`: 최대 HP 대비 회복 비율 (0-100)
- `global_turn_reset`: 즉시 글로벌 턴 카드 드로우
- `buff_extension_turns`: 활성 버프 지속시간 연장 턴 수

### 4.9 지형 (terrain/*.yaml) - Phase 5A

```yaml
# data/terrain/base_terrain.yaml
terrain:
  - id: "plain"
    name_key: "TERRAIN_PLAIN"
    color: "#90EE90"  # 연한 초록
    passable: true
    movement_cost: 1.0
    defense_modifier: 0
    attack_modifier: 0
    atb_modifier: 0

  - id: "mountain"
    name_key: "TERRAIN_MOUNTAIN"
    color: "#8B4513"  # 갈색
    passable: true
    movement_cost: 2.5
    defense_modifier: 30  # +30% 방어
    attack_modifier: -10  # -10% 공격
    atb_modifier: 0

  - id: "forest"
    name_key: "TERRAIN_FOREST"
    color: "#228B22"  # 짙은 초록
    passable: true
    movement_cost: 1.5
    defense_modifier: 20  # +20% 방어
    attack_modifier: 0
    atb_modifier: -0.05  # -5% ATB 속도

  - id: "wall"
    name_key: "TERRAIN_WALL"
    color: "#696969"  # 회색
    passable: false
    movement_cost: 999
    defense_modifier: 0
    attack_modifier: 0
    atb_modifier: 0
```

**지형 수정자 설명:**
- `movement_cost`: 이동 비용 승수 (1.0 = 기본)
- `defense_modifier`: 방어력 % 수정 (타일에 있을 때)
- `attack_modifier`: 공격력 % 수정 (타일에서 공격 시)
- `atb_modifier`: ATB 속도 평탄 수정 (타일에 있을 때)

### 4.10 맵 (maps/*.yaml) - Phase 5A

```yaml
# data/maps/stage_maps.yaml
maps:
  - id: "stage_1_map"
    name_key: "MAP_STAGE_1"
    size: 16  # 16×16 그리드

    # 지형 레이아웃 (16줄, 각 16개 ID)
    terrain:
      - ["plain", "plain", "plain", "mountain", ...]  # 행 0
      - ["plain", "forest", "plain", "plain", ...]    # 행 1
      # ... 총 16행

    # 아군 부대 스폰 존 (Vector2i 좌표)
    ally_spawn_zone:
      - [0, 7]
      - [0, 8]
      - [1, 7]
      - [1, 8]

    # 적군 부대 스폰 존
    enemy_spawn_zone:
      - [15, 7]
      - [15, 8]
      - [14, 7]
      - [14, 8]
```

**맵 구조:**
- 16×16 타일 그리드
- 각 타일은 지형 ID를 참조
- 스폰 존은 부대 초기 배치 위치 정의

### 4.11 부대 (corps/*.yaml) - Phase 5B

```yaml
# data/corps/base_corps.yaml
corps:
  - id: "spear_corps"
    name_key: "CORPS_SPEAR"
    category: "infantry"
    soldier_count: 100
    soldier_unit_id: "spearman"

    base_stats:
      hp_per_soldier: 10
      attack_per_soldier: 2
      defense: 30
      atb_speed: 1.0
      movement_range: 2
      attack_range: 1  # 근접

    available_formations:
      - "default"
      - "hakik"
      - "bangwon"
      - "jangsa"
      - "eorin"

    traits:  # 선택 사항, units와 동일 구조
      - id: "anti_cavalry"
        effect:
          damage_bonus_vs: "cavalry"
          bonus_percent: 50

  - id: "archer_corps"
    name_key: "CORPS_ARCHER"
    category: "archer"
    soldier_count: 80
    soldier_unit_id: "archer"

    base_stats:
      hp_per_soldier: 8
      attack_per_soldier: 3
      defense: 15
      atb_speed: 0.9
      movement_range: 2
      attack_range: 5  # 원거리

    available_formations:
      - "default"
      - "hakik"
      - "eorin"
```

**부대 특징:**
- 부대 총 HP = `hp_per_soldier × (soldier_count + 장수 통솔력 보너스)`
- 부대 총 공격 = `attack_per_soldier × 병사 수 + 방어/진형 수정자`
- `attack_range`: 공격 가능 거리 (보병 1, 기병 2, 궁병 4-5)
- 장수 통솔력: +1 병사/10 통솔력

### 4.12 진형 (formations/*.yaml) - Phase 5B

```yaml
# data/formations/base_formations.yaml
formations:
  - id: "default"
    name_key: "FORMATION_DEFAULT"
    description_key: "FORMATION_DEFAULT_DESC"

    modifiers:
      attack_modifier: 0     # % 수정
      defense_modifier: 0    # % 수정
      atb_modifier: 0.0      # 평탄 수정
      movement_modifier: 0   # 평탄 수정 (타일)

    category: ["infantry", "cavalry", "archer"]  # 모든 유닛 사용 가능

  - id: "hakik"  # 학익진 (Crane Wing)
    name_key: "FORMATION_HAKIK"
    description_key: "FORMATION_HAKIK_DESC"

    modifiers:
      attack_modifier: 30    # +30% 공격
      defense_modifier: -10  # -10% 방어
      atb_modifier: 0.1      # +0.1 ATB 속도
      movement_modifier: 0

    category: ["infantry", "cavalry"]

  - id: "bongsi"  # 봉시진 (Arrow Point)
    name_key: "FORMATION_BONGSI"

    modifiers:
      attack_modifier: 50
      defense_modifier: -30
      atb_modifier: 0.2
      movement_modifier: 1   # +1 이동 범위

    category: ["cavalry"]  # 기병 전용

  - id: "bangwon"  # 방원진 (Circular)
    name_key: "FORMATION_BANGWON"

    modifiers:
      attack_modifier: -20
      defense_modifier: 50
      atb_modifier: -0.2
      movement_modifier: -1  # -1 이동 범위

    category: ["infantry"]
```

**진형 수정자 설명:**
- `attack_modifier`: 공격력 % 증감
- `defense_modifier`: 방어력 % 증감
- `atb_modifier`: ATB 속도 평탄 증감 (0.1 = +10%)
- `movement_modifier`: 이동 범위 타일 증감
- `category`: 이 진형을 사용할 수 있는 부대 타입

---

## 5. MOD 시스템

### 5.1 MOD 구조

```
mods/
└── my_custom_mod/
    ├── mod.yaml           # 필수: MOD 메타정보
    ├── data/
    │   ├── generals/
    │   │   └── custom_generals.yaml
    │   └── localization/
    │       └── ko.yaml    # 기존 ko.yaml에 병합됨
    └── assets/
        └── sprites/
            └── portraits/
                └── custom_general.png
```

### 5.2 mod.yaml

```yaml
mod:
  id: "my_custom_mod"
  name: "나만의 장수 팩"
  version: "1.0.0"
  author: "작성자"
  description: "새로운 장수 3명을 추가합니다."
  
  # 로드 순서 (낮을수록 먼저 로드, 나중 로드가 덮어씀)
  load_order: 100
  
  # 의존성 (선택)
  dependencies: []
  
  # 호환 게임 버전
  game_version: ">=1.0.0"
```

### 5.3 DataManager의 MOD 병합 로직

```gdscript
# src/autoload/data_manager.gd
extends Node

var _data: Dictionary = {}
var _loaded_mods: Array[String] = []

func _ready() -> void:
    _load_base_data()
    _load_mods()

func _load_base_data() -> void:
    # data/ 폴더의 모든 YAML 로드
    _data = _load_yaml_recursive("res://data/")

func _load_mods() -> void:
    var mods_path := "user://mods/"  # 또는 프로젝트 내 mods/
    var mod_dirs := _get_mod_directories(mods_path)
    
    # load_order 순으로 정렬
    mod_dirs.sort_custom(_compare_mod_load_order)
    
    for mod_dir in mod_dirs:
        _merge_mod_data(mod_dir)

func _merge_mod_data(mod_path: String) -> void:
    var mod_data := _load_yaml_recursive(mod_path + "/data/")
    _deep_merge(_data, mod_data)

func _deep_merge(base: Dictionary, override: Dictionary) -> void:
    # 같은 id를 가진 항목은 덮어씀
    # 배열은 id 기준으로 병합
    pass

# 데이터 조회 API
func get_general(id: String) -> Dictionary:
    return _data.generals.get(id, {})

func get_all_generals_by_nation(nation_id: String) -> Array:
    return _data.generals.values().filter(
        func(g): return g.nation == nation_id
    )

func get_localized(key: String) -> String:
    var locale := TranslationServer.get_locale().substr(0, 2)
    return _data.localization.get(locale, {}).get(key, key)
```

---

## 6. 프로토타입용 에셋 규격

### 6.1 필수 에셋 목록

#### 스프라이트

| 카테고리 | 항목 | 규격 | 수량 | 우선순위 |
|----------|------|------|------|----------|
| 초상화 | 장수 초상화 | 256×256 px, PNG | 9개 (3국가×3장수) | P0 |
| 유닛 | 전투 유닛 스프라이트 | 64×64 px, PNG | 6개 (기본 병종) | P0 |
| 유닛 | 유닛 애니메이션 | 64×64 px, 스프라이트시트 | idle 4프레임, attack 4프레임 | P1 |
| UI | 카드 프레임 | 180×240 px, PNG | 4개 (등급별) | P0 |
| UI | 카드 아이콘 | 64×64 px, PNG | 10개 (기본 카드) | P1 |
| UI | 버튼 | 가변, 9-patch PNG | 3종 (normal/hover/pressed) | P0 |
| UI | ATB 게이지 | 200×20 px, PNG | 2개 (배경/채움) | P0 |
| 맵 | 전투 배경 | 1920×1080 px, PNG | 3개 (지형별) | P1 |
| 국가 | 문장/엠블럼 | 128×128 px, PNG | 3개 | P1 |

#### 오디오

| 카테고리 | 항목 | 형식 | 수량 | 우선순위 |
|----------|------|------|------|----------|
| BGM | 메인 메뉴 | OGG, 루프 | 1개 | P1 |
| BGM | 내정 | OGG, 루프 | 1개 | P1 |
| BGM | 전투 | OGG, 루프 | 1개 | P1 |
| SFX | UI 클릭 | WAV/OGG | 2개 | P0 |
| SFX | 공격 타격 | WAV/OGG | 3개 | P1 |
| SFX | 스킬 사용 | WAV/OGG | 3개 | P1 |

#### 폰트

| 용도 | 권장 | 형식 |
|------|------|------|
| UI 기본 | Noto Sans KR | TTF/OTF |
| 제목/강조 | 조선굴림체 또는 유사 전통 서체 | TTF/OTF |

### 6.2 Placeholder 전략

프로토타입 초기에는 모든 에셋 대신 placeholder를 사용:

```
[Placeholder 규칙]
- 초상화: 단색 사각형 + 이름 텍스트
- 유닛: 색상으로 구분된 원/사각형
- 카드: 단색 배경 + 텍스트
- 버튼: Godot 기본 테마 활용
```

```gdscript
# 에셋 로딩 시 fallback
func load_portrait(path: String) -> Texture2D:
    if ResourceLoader.exists(path):
        return load(path)
    else:
        return _generate_placeholder_portrait()
```

---

## 7. 프로토타입 구현 로드맵

### Phase 1: 전투 코어 ✅ 완료 (2025-12-29)

```
[구현 항목]
✅ 프로젝트 세팅 및 기본 구조
✅ YAML 파서 연동 (godot-yaml 플러그인)
✅ DataManager 기본 구현
✅ Unit 클래스 (HP, ATB, 기본 스탯)
✅ ATB 시스템 (게이지 충전 → 행동)
✅ 기본 공격 로직
✅ 전투 씬 UI (유닛 배치, HP바, ATB바)
✅ 전투 종료 판정

[테스트 데이터]
✅ 장수 9명 (3 국가 × 3 역할)
✅ 유닛 6종 (보병, 창병, 궁병, 기병, 특수병, 공성병)
```

### Phase 2: 전투 확장 ✅ 완료 (2025-12-29)

```
[구현 항목]
✅ 장수 고유 스킬 시스템 (9개 스킬)
✅ 글로벌 턴 시스템 (10초 간격, ATB 일시정지/재개)
✅ 카드 시스템 (덱, 드로우, 사용)
✅ 전투 카드 효과 (버프/디버프)
✅ 버프 지속시간 시스템
✅ 스킬 쿨다운 시스템 (ATB 독립)
✅ 이중 레이어 타이밍 (ATB + 글로벌 턴)
🔲 진형 선택 (Phase 4 예정, 현재 유닛 데이터에 하드코딩)

[테스트 데이터]
✅ 카드 13장 (기본 덱 5장 + 고급 카드 8장)
✅ 스킬 9종 (장수별 고유 스킬)
```

### Phase 3: 내정 연결 ✅ 완료 (2025-12-30)

```
[구현 항목]
✅ GameManager autoload (런 오케스트레이션)
✅ RunState 클래스 (유닛 상태 지속성)
✅ 내정 씬 기본 UI
✅ 선택지 시스템 (3턴, 각 턴 3개 선택지)
✅ 4개 카테고리 (군사/경제/외교/인사)
✅ 선택 → 효과 적용 (InternalAffairsManager)
✅ 내정 → 전투 전환
✅ 스테이지 진행 흐름 (1-3)
✅ 강화 선택 화면 (3개 중 1개, 희귀도별)
✅ 승리/패배 화면 (통계 표시)
✅ 메인 메뉴 → 런 시작 → 엔딩 흐름
✅ 이벤트 플래그 시스템

[테스트 데이터]
✅ 내정 이벤트 20개 (카테고리당 5개)
✅ 강화 14개 (Common 5, Rare 5, Legendary 4)
✅ 로컬라이제이션 189 스트링 (한/영)
```

### Phase 3D: 운명적 조우 (Fateful Encounter) ✅ 완료

```
[구현 항목]
✅ NPC 시스템 (5명: 도선국사, 이제마, 원효, 의상, 최치원)
✅ NPC별 고유 대화 (greeting, dialogue, offer)
✅ 테마 기반 강화 필터링 (healing, mystic, tactical 등)
✅ 강화 14개에 테마 태그 추가
✅ 가로 레이아웃 UI (초상화 좌측, 정보 우측)
✅ NPC 초상화 플레이스홀더 시스템
✅ DataManager NPC 로딩 및 테마 필터링 API

[데이터]
✅ NPC 데이터 5개 (YAML) - 한국 역사 인물
✅ 강화 테마 태그 추가 (14개 모두)
✅ 로컬라이제이션 216 스트링 (한/영, +27개)

[UI 흐름]
전투 승리 → 내정 → **운명적 조우** → 다음 전투
- 5명 한국 역사 인물 중 랜덤 1명 NPC 등장
- NPC 테마에 맞는 강화 3개 제공 (1 common, 1 rare, 1 legendary)
- 플레이어가 1개 선택
```

### Phase 4: 웨이브 시스템 & 전투 개선 ✅ 완료

```
[구현 항목]
✅ 웨이브 기반 전투 시스템 (3-4 웨이브/스테이지)
✅ 전투 데이터 스키마 및 YAML 정의 (data/battles/)
✅ 웨이브 보상 (HP 회복, 글로벌 턴 리셋, 버프 연장)
✅ 웨이브 UI (카운터, 전환 메시지)
✅ ATB 속도 최적화 (4배 가속: ~2.5초/행동)
✅ 웨이브별 동적 적 생성
✅ 장수 쿨다운 스테이지 간 리셋

[웨이브 구조]
- 스테이지 1: 3 웨이브 (2, 3, 4 적)
- 스테이지 2: 3 웨이브 (3, 3, 4 적)
- 스테이지 3: 3 웨이브 (3, 4, 5 적) - 보스 장수 2명

[테스트]
✅ Battle Simulator (headless 밸런스 테스트)
✅ 10배 가속 시뮬레이션
✅ CSV/JSON 통계 출력
```

### Phase 5: 부대 & 그리드 시스템 ✅ 완료

```
[Phase 5A: 16×16 타일 기반 지형 그리드]
✅ 6개 지형 타입 및 수정자
✅ TerrainTile 및 BattleMap 클래스
✅ 3개 스테이지 맵 (스폰 존 포함)
✅ TileDisplay (40×40px) 및 TileGridUI (640×640px)
✅ DataManager 지형/맵 로딩

[Phase 5B: 부대 시스템]
✅ Corps 클래스 (장수 + 병사, 그리드 배치)
✅ 6개 부대 템플릿
✅ Formation 클래스 (5개 진형)
✅ 유닛 타입별 공격 범위 (보병: 1, 기병: 2, 궁병: 4-5)
✅ CorpsDisplay 컴포넌트

[Phase 5C: 명령 시스템으로 강화된 ATB]
✅ CorpsCommand 클래스 (5가지 명령 타입)
✅ CommandPanel UI (ATTACK, DEFEND, EVADE, WATCH, MOVE)
✅ MovementOverlay (범위 강조, 목적지 선택)
✅ 글로벌 턴 중 이동 단계 실행
✅ BattleManager 명령 큐 및 실행
✅ 공격 범위 검증
✅ CorpsBattleUI 통합 (테스트 씬)
✅ 67개 추가 로컬라이제이션 문자열 (→ 총 283개)

[플레이 가능]
✅ scenes/corps_battle_test.tscn - 16×16 그리드 부대 전술 전투
✅ 완전한 명령 시스템 및 공격 범위 검증
✅ 지형 효과 및 진형 수정자
✅ 글로벌 턴 중 이동 단계
```

### Phase 6: 부대/그리드 시스템 통합 🔲 다음 단계

```
[계획된 기능]
🔲 기존 웨이브 전투를 부대 기반으로 교체
🔲 그리드/지형 시스템을 메인 전투 씬에 통합
🔲 유닛 대신 부대를 타겟으로 하는 카드 시스템
🔲 RunState에 부대 상태 저장 기능
```

### Phase 7: 메타 프로그레션 🔲 계획됨

```
[계획된 기능]
🔲 SaveManager 완전 구현 (세이브/로드)
🔲 메타 프로그레션 언락 (영구 업그레이드)
🔲 플레이어 진행 추적
🔲 스테이지별 적 스케일링
🔲 MOD 시스템 완전 구현
🔲 AudioManager 구현
🔲 추가 콘텐츠 (이벤트, 강화, 카드)
🔲 밸런스 조정 및 폴리시
```

---

## 8. 핵심 클래스 설계

### 8.1 Unit 클래스

```gdscript
# src/core/unit.gd
class_name Unit
extends RefCounted

signal atb_filled(unit: Unit)
signal took_damage(amount: int, current_hp: int)
signal died()

var id: String
var display_name: String
var category: String  # infantry, cavalry, archer

var max_hp: int
var current_hp: int
var attack: int
var defense: int
var atb_speed: float

var atb_current: float = 0.0
var atb_max: float = 100.0

var traits: Array[Dictionary] = []
var buffs: Array[Buff] = []

var is_ally: bool = true

func _init(data: Dictionary) -> void:
    id = data.get("id", "")
    display_name = DataManager.get_localized(data.get("name_key", ""))
    category = data.get("category", "infantry")
    
    var stats := data.get("base_stats", {})
    max_hp = stats.get("hp", 100)
    current_hp = max_hp
    attack = stats.get("attack", 10)
    defense = stats.get("defense", 10)
    atb_speed = stats.get("atb_speed", 1.0)
    
    traits = data.get("traits", [])

func tick_atb(delta: float) -> void:
    if current_hp <= 0:
        return
    
    atb_current += atb_speed * delta * _get_atb_modifier()
    
    if atb_current >= atb_max:
        atb_current = atb_max
        atb_filled.emit(self)

func take_damage(amount: int) -> void:
    var actual_damage := maxi(1, amount - _calculate_defense())
    current_hp -= actual_damage
    took_damage.emit(actual_damage, current_hp)
    
    if current_hp <= 0:
        current_hp = 0
        died.emit()

func calculate_attack_damage(target: Unit) -> int:
    var base_damage := attack
    base_damage = _apply_trait_bonuses(base_damage, target)
    base_damage = _apply_buff_bonuses(base_damage)
    return base_damage

func _get_atb_modifier() -> float:
    var modifier := 1.0
    for buff in buffs:
        if buff.stat == "atb_speed":
            modifier *= buff.get_multiplier()
    return modifier

func _calculate_defense() -> int:
    var total_defense := defense
    for buff in buffs:
        if buff.stat == "defense":
            total_defense += buff.get_value()
    return total_defense

func _apply_trait_bonuses(damage: int, target: Unit) -> int:
    for trait in traits:
        var effect := trait.get("effect", {})
        if effect.get("damage_bonus_vs", "") == target.category:
            damage = int(damage * (1.0 + effect.get("bonus_percent", 0) / 100.0))
    return damage

func _apply_buff_bonuses(damage: int) -> int:
    for buff in buffs:
        if buff.stat == "attack":
            damage += buff.get_value()
    return damage
```

### 8.2 BattleManager

```gdscript
# src/systems/battle/battle_manager.gd
class_name BattleManager
extends Node

signal battle_started()
signal global_turn_triggered(turn_number: int)
signal battle_ended(result: Dictionary)

enum BattleState { PREPARING, RUNNING, PAUSED, ENDED }

var state: BattleState = BattleState.PREPARING

var ally_units: Array[Unit] = []
var enemy_units: Array[Unit] = []

var global_turn_timer: float = 0.0
var global_turn_interval: float = 10.0  # 10초마다 글로벌 턴
var global_turn_count: int = 0

var card_deck: Array[Card] = []
var card_hand: Array[Card] = []

func start_battle(ally_data: Array, enemy_data: Array) -> void:
    _setup_units(ally_data, enemy_data)
    state = BattleState.RUNNING
    battle_started.emit()

func _process(delta: float) -> void:
    if state != BattleState.RUNNING:
        return
    
    _update_atb(delta)
    _update_global_turn(delta)
    _check_battle_end()

func _update_atb(delta: float) -> void:
    for unit in ally_units + enemy_units:
        unit.tick_atb(delta)

func _update_global_turn(delta: float) -> void:
    global_turn_timer += delta
    
    if global_turn_timer >= global_turn_interval:
        global_turn_timer = 0.0
        global_turn_count += 1
        _trigger_global_turn()

func _trigger_global_turn() -> void:
    state = BattleState.PAUSED
    global_turn_triggered.emit(global_turn_count)
    # UI에서 카드 사용 후 resume_battle() 호출

func resume_battle() -> void:
    state = BattleState.RUNNING

func use_card(card: Card, targets: Array[Unit]) -> void:
    card.apply_effect(targets)
    card_hand.erase(card)

func _check_battle_end() -> void:
    var allies_alive := ally_units.filter(func(u): return u.current_hp > 0)
    var enemies_alive := enemy_units.filter(func(u): return u.current_hp > 0)
    
    if enemies_alive.is_empty():
        _end_battle({"victory": true})
    elif allies_alive.is_empty():
        _end_battle({"victory": false})

func _end_battle(result: Dictionary) -> void:
    state = BattleState.ENDED
    battle_ended.emit(result)
```

### 8.3 RunState 클래스

```gdscript
# src/core/run_state.gd
class_name RunState
extends RefCounted

# 현재 스테이지 (1-3)
var current_stage: int = 1

# 유닛 상태 지속성 (전투 간 HP, 스탯, 버프 유지)
var unit_states: Array[Dictionary] = []

# 장수 쿨다운 상태 (스킬 쿨다운 전투 간 유지)
var general_cooldowns: Dictionary = {}

# 활성 강화 목록 (런 동안 누적)
var active_enhancements: Array[Dictionary] = []

# 덱 상태 (카드 추가/제거 가능)
var deck: Array[String] = []  # 카드 ID 배열

# 이벤트 플래그 (내정 선택 분기용)
var event_flags: Dictionary = {}

# 통계 (승리/패배 화면용)
var stats: Dictionary = {
    "stages_cleared": 0,
    "battles_won": 0,
    "internal_affairs_choices": [],
    "enhancements_acquired": []
}

func save_unit_state(unit: Unit) -> void:
    var state := {
        "id": unit.id,
        "current_hp": unit.current_hp,
        "max_hp": unit.max_hp,
        "attack": unit.attack,
        "defense": unit.defense,
        "atb_speed": unit.atb_speed,
        "buffs": []  # 전투 종료 시 일부 버프만 유지 (permanent 플래그)
    }

    for buff in unit.buffs:
        if buff.persistent:  # 런 레벨 버프만 저장
            state.buffs.append(buff.to_dict())

    unit_states.append(state)

func restore_unit_state(unit: Unit, saved_state: Dictionary) -> void:
    unit.current_hp = saved_state.get("current_hp", unit.max_hp)
    unit.max_hp = saved_state.get("max_hp", unit.max_hp)
    unit.attack = saved_state.get("attack", unit.attack)
    unit.defense = saved_state.get("defense", unit.defense)
    unit.atb_speed = saved_state.get("atb_speed", unit.atb_speed)

    # 저장된 버프 복원
    for buff_data in saved_state.get("buffs", []):
        var buff := Buff.from_dict(buff_data)
        unit.buffs.append(buff)

func apply_enhancements(units: Array[Unit]) -> void:
    for enhancement in active_enhancements:
        var effect := enhancement.get("effect", {})
        match effect.get("type", ""):
            "stat_modifier":
                _apply_stat_modifier(units, effect)
            "combat_modifier":
                _apply_combat_modifier(units, effect)
            "ability":
                _apply_ability_effect(units, effect)

func add_event_flag(flag: String) -> void:
    event_flags[flag] = true

func has_event_flag(flag: String) -> bool:
    return event_flags.get(flag, false)
```

### 8.4 GameManager

```gdscript
# src/autoload/game_manager.gd
extends Node

signal run_started()
signal stage_changed(stage_number: int)
signal run_ended(victory: bool)

var current_run: RunState = null

func start_new_run() -> void:
    current_run = RunState.new()
    current_run.current_stage = 1
    current_run.deck = ["card_basic_attack", "card_defend", "card_rally"]  # 기본 덱
    run_started.emit()
    _load_battle_scene()

func on_battle_ended(victory: bool) -> void:
    if not victory:
        _show_defeat_screen()
        return

    # 유닛 상태 저장
    var battle_manager := get_node_or_null("/root/BattleManager")
    if battle_manager:
        current_run.unit_states.clear()
        for unit in battle_manager.ally_units:
            current_run.save_unit_state(unit)

    current_run.stats.battles_won += 1

    # 다음 단계로 전환
    if current_run.current_stage < 3:
        _load_internal_affairs_scene()
    else:
        _show_victory_screen()

func on_internal_affairs_completed() -> void:
    _load_enhancement_selection_scene()

func on_enhancement_selected(enhancement: Dictionary) -> void:
    current_run.active_enhancements.append(enhancement)
    current_run.stats.enhancements_acquired.append(enhancement.id)

    if current_run.current_stage < 3:
        current_run.current_stage += 1
        current_run.stats.stages_cleared += 1
        stage_changed.emit(current_run.current_stage)
        _load_battle_scene()
    else:
        _show_victory_screen()

func clear_run() -> void:
    current_run = null
    _load_main_menu()

func _load_battle_scene() -> void:
    get_tree().change_scene_to_file("res://scenes/battle.tscn")

func _load_internal_affairs_scene() -> void:
    get_tree().change_scene_to_file("res://scenes/internal_affairs.tscn")

func _load_enhancement_selection_scene() -> void:
    get_tree().change_scene_to_file("res://scenes/enhancement_selection.tscn")

func _show_victory_screen() -> void:
    run_ended.emit(true)
    get_tree().change_scene_to_file("res://scenes/victory_screen.tscn")

func _show_defeat_screen() -> void:
    run_ended.emit(false)
    get_tree().change_scene_to_file("res://scenes/defeat_screen.tscn")

func _load_main_menu() -> void:
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
```

### 8.5 InternalAffairsManager

```gdscript
# src/systems/internal_affairs/internal_affairs_manager.gd
class_name InternalAffairsManager
extends Node

signal choices_presented(choices: Array[Dictionary])
signal choice_executed(choice: Dictionary)
signal turn_completed(turn_number: int)
signal all_turns_completed()

const TURNS_PER_PHASE := 3
const CHOICES_PER_TURN := 3

var current_turn: int = 1
var event_pool: Dictionary = {}

func _ready() -> void:
    _load_events()

func _load_events() -> void:
    # DataManager에서 이벤트 로드
    event_pool = {
        "military": DataManager.get_events_by_category("military"),
        "economic": DataManager.get_events_by_category("economic"),
        "diplomatic": DataManager.get_events_by_category("diplomatic"),
        "personnel": DataManager.get_events_by_category("personnel")
    }

func start_turn() -> void:
    var choices := _generate_choices()
    choices_presented.emit(choices)

func execute_choice(choice: Dictionary) -> void:
    var effects := choice.get("effects", [])

    for effect in effects:
        _apply_effect(effect)

    # 이벤트 플래그 설정
    if choice.has("flag"):
        GameManager.current_run.add_event_flag(choice.flag)

    GameManager.current_run.stats.internal_affairs_choices.append(choice.id)
    choice_executed.emit(choice)

    current_turn += 1

    if current_turn > TURNS_PER_PHASE:
        all_turns_completed.emit()
    else:
        turn_completed.emit(current_turn)

func _generate_choices() -> Array[Dictionary]:
    var choices: Array[Dictionary] = []
    var categories := ["military", "economic", "diplomatic", "personnel"]
    categories.shuffle()

    for i in CHOICES_PER_TURN:
        var category := categories[i]
        var events := event_pool[category]
        var event := events.pick_random()

        # 조건 체크 (이벤트 플래그)
        if _check_conditions(event):
            choices.append(event)

    return choices

func _check_conditions(event: Dictionary) -> bool:
    var condition := event.get("condition", {})
    if condition.is_empty():
        return true

    var required_flag := condition.get("flag", "")
    if required_flag.is_empty():
        return true

    return GameManager.current_run.has_event_flag(required_flag)

func _apply_effect(effect: Dictionary) -> void:
    match effect.get("type", ""):
        "modify_stat":
            _modify_unit_stat(effect)
        "add_card":
            _add_card_to_deck(effect)
        "add_troops":
            _add_troops(effect)
        # 기타 효과 타입...

func _modify_unit_stat(effect: Dictionary) -> void:
    var stat := effect.get("stat", "")
    var value := effect.get("value", 0)

    # RunState의 유닛 스탯 수정
    for unit_state in GameManager.current_run.unit_states:
        match stat:
            "attack":
                unit_state.attack += value
            "defense":
                unit_state.defense += value
            # 기타 스탯...
```

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2025-12-29 | 초안 작성 |
| 2025-12-29 | Phase 1 구현 상태 반영 (전투 코어) |
| 2025-12-29 | YAML 데이터 구조 및 로딩 시스템 추가 |
| 2025-12-29 | 전투 시스템 구조 및 ATB 로직 추가 |
| 2025-12-29 | UI 컴포넌트 구조 추가 (BattleUI, UnitDisplay, PlaceholderSprite) |
| 2025-12-29 | 전투 시스템 구현 완료 (ATB, 턴제, 전투 로직) |
| 2025-12-29 | 전투 씬 및 데모 구현 완료 |
| 2025-12-29 | Phase 2 구현 완료 (스킬, 카드, 버프 시스템) |
| 2025-12-30 | Phase 3 구현 완료 (내정 연결, 완전한 런 루프) |
| 2025-12-30 | GameManager 및 RunState 클래스 추가 |
| 2025-12-30 | 내정 시스템 구현 (20개 이벤트, 4개 카테고리) |
| 2025-12-30 | 강화 시스템 구현 (14개 강화, 희귀도별 분류) |
| 2025-12-30 | 메인 메뉴, 승리/패배 화면 구현 |
| 2025-12-30 | 완전한 게임 루프 문서화 (3.4절) |
| 2025-12-30 | InternalAffairsManager 클래스 설계 추가 (8.5절) |
| 2025-12-30 | 강화 데이터 스키마 추가 (4.6절) |
| 2025-12-30 | 로컬라이제이션 업데이트 (189 스트링) |
| 2025-12-30 | Phase 1-3 로드맵 완료 상태 반영 |
| 2025-12-30 | NPC 이름 변경: 중국 삼국지 인물 → 한국 역사 인물 (도선국사, 이제마, 원효, 의상, 최치원) |
| 2025-12-31 | Phase 4 구현 완료 반영 (웨이브 시스템, ATB 최적화) |
| 2025-12-31 | Phase 5A 구현 완료 반영 (16×16 지형 그리드 시스템) |
| 2025-12-31 | Phase 5B 구현 완료 반영 (부대 시스템, 진형) |
| 2025-12-31 | Phase 5C 구현 완료 반영 (명령 시스템, 이동 단계) |
| 2025-12-31 | 새 데이터 스키마 추가 (battles, terrain, maps, corps, formations) |
| 2025-12-31 | 프로젝트 구조 업데이트 (Phase 5C 상태) |
| 2025-12-31 | 로컬라이제이션 업데이트 (283 스트링) |
| 2025-12-31 | Phase 6-7 로드맵 추가 (부대 통합, 메타 프로그레션) |
