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

### 2.1 Phase 3D 구현 상태 (2025-12)

```
husamguk/                         # Godot 프로젝트 루트
├── project.godot                 # ✅ DataManager, GameManager autoload 등록
│
├── addons/
│   └── yaml/                     # ✅ godot-yaml (fimbul-works)
│
├── src/                          # 게임 코드
│   ├── autoload/                 # 싱글톤
│   │   ├── data_manager.gd       # ✅ YAML 로딩, 로컬라이제이션, 팩토리
│   │   ├── game_manager.gd       # ✅ 런 오케스트레이션, 씬 전환
│   │   └── save_manager.gd       # ✅ 스텁 (Phase 4 구현 예정)
│   │
│   ├── core/                     # 핵심 데이터 클래스
│   │   ├── general.gd            # ✅ 장수, 스킬 실행, 쿨다운
│   │   ├── unit.gd               # ✅ ATB, 전투 로직, 특성 보너스
│   │   ├── buff.gd               # ✅ 버프/디버프 시스템
│   │   ├── card.gd               # ✅ 카드 효과 실행, 타겟팅
│   │   └── run_state.gd          # ✅ 런 레벨 상태 지속성
│   │
│   ├── systems/
│   │   ├── battle/
│   │   │   └── battle_manager.gd # ✅ 이중 레이어 타이밍, 상태 머신
│   │   └── internal_affairs/
│   │       └── internal_affairs_manager.gd  # ✅ 내정 이벤트 시스템
│   │
│   └── ui/
│       ├── battle/
│       │   ├── battle_ui.gd      # ✅ 메인 전투 컨트롤러
│       │   ├── unit_display.gd   # ✅ HP/ATB 바, 시각 피드백
│       │   ├── skill_bar.gd      # ✅ 스킬 UI (왼쪽 사이드바)
│       │   ├── skill_button.gd   # ✅ 개별 스킬 버튼
│       │   ├── card_hand.gd      # ✅ 카드 핸드 UI (하단)
│       │   ├── card_display.gd   # ✅ 개별 카드 표시
│       │   └── placeholder_sprite.gd  # ✅ 플레이스홀더 그래픽
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
│   ├── battle.tscn               # ✅ 전투 씬
│   ├── internal_affairs.tscn     # ✅ 내정 씬
│   ├── fateful_encounter.tscn    # ✅ 운명적 조우 씬 (Phase 3D)
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
│   │   └── fateful_encounter_npcs.yaml  # ✅ 5명 NPC (좌자, 화타, 우길, 남화노선, 수경선생)
│   └── localization/
│       ├── ko.yaml               # ✅ 한국어 (216 스트링, Phase 3D)
│       └── en.yaml               # ✅ 영어 (216 스트링, Phase 3D)
│
└── assets/
    └── audio/
        └── bgm/
            └── battle_theme.ogg  # ✅ 전투 BGM (루핑)

**범례:**
- ✅ Phase 3 구현 완료
- 🔲 향후 Phase 구현 예정 (Phase 4+)
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
✅ NPC 시스템 (5명: 좌자, 화타, 우길, 남화노선, 수경선생)
✅ NPC별 고유 대화 (greeting, dialogue, offer)
✅ 테마 기반 강화 필터링 (healing, mystic, tactical 등)
✅ 강화 14개에 테마 태그 추가
✅ 가로 레이아웃 UI (초상화 좌측, 정보 우측)
✅ NPC 초상화 플레이스홀더 시스템
✅ DataManager NPC 로딩 및 테마 필터링 API

[데이터]
✅ NPC 데이터 5개 (YAML)
✅ 강화 테마 태그 추가 (14개 모두)
✅ 로컬라이제이션 216 스트링 (한/영, +27개)

[UI 흐름]
전투 승리 → 내정 → **운명적 조우** → 다음 전투
- 5명 중 랜덤 1명 NPC 등장
- NPC 테마에 맞는 강화 3개 제공 (1 common, 1 rare, 1 legendary)
- 플레이어가 1개 선택
```

### Phase 4: 메타 프로그레션 🔲 다음 단계

```
[구현 항목]
🔲 SaveManager 완전 구현
🔲 메타 프로그레션 언락 (영구 업그레이드)
🔲 스테이지별 적 스케일링
🔲 추가 콘텐츠 (이벤트, 강화, 카드)
🔲 진형 선택 시스템
🔲 밸런스 조정 및 폴리시
🔲 MOD 시스템 완전 구현
🔲 AudioManager 구현
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
