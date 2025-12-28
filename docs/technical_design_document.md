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

```
project_root/
├── project.godot
├── addons/
│   └── yaml_parser/              # YAML 파싱 플러그인
│
├── src/                          # 게임 코드
│   ├── autoload/                 # 싱글톤 (전역 매니저)
│   │   ├── game_manager.gd
│   │   ├── data_manager.gd       # YAML 로딩/MOD 병합
│   │   ├── save_manager.gd       # 메타 프로그레션 저장
│   │   └── audio_manager.gd
│   │
│   ├── core/                     # 핵심 데이터 클래스
│   │   ├── general.gd            # 장수
│   │   ├── unit.gd               # 전투 유닛
│   │   ├── nation.gd             # 국가
│   │   ├── card.gd               # 강화 카드
│   │   └── event.gd              # 이벤트
│   │
│   ├── systems/                  # 게임 시스템
│   │   ├── internal_affairs/     # 내정 시스템
│   │   ├── battle/               # 전투 시스템
│   │   └── roguelite/            # 강화/메타 프로그레션
│   │
│   └── ui/                       # UI 컴포넌트
│       ├── common/
│       ├── main_menu/
│       ├── internal_affairs/
│       └── battle/
│
├── scenes/                       # 씬 파일 (.tscn)
│   ├── main.tscn
│   ├── main_menu.tscn
│   ├── internal_affairs.tscn
│   └── battle.tscn
│
├── data/                         # 기본 게임 데이터 (YAML)
│   ├── generals/
│   │   ├── _schema.yaml          # 스키마 정의
│   │   ├── hubaekje.yaml
│   │   ├── taebong.yaml
│   │   └── silla.yaml
│   ├── units/
│   ├── nations/
│   ├── cards/
│   ├── events/
│   └── localization/
│       ├── ko.yaml
│       └── en.yaml
│
├── assets/                       # 기본 에셋
│   ├── sprites/
│   ├── ui/
│   ├── audio/
│   └── fonts/
│
└── mods/                         # MOD 폴더 (사용자 확장)
    └── example_mod/
        ├── mod.yaml              # MOD 메타정보
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

| 이름 | 역할 |
|------|------|
| `GameManager` | 런 상태, 스테이지 진행, 게임 흐름 제어 |
| `DataManager` | YAML 로딩, MOD 병합, 데이터 조회 API |
| `SaveManager` | 메타 프로그레션 저장/로드 |
| `AudioManager` | BGM/SFX 재생 |

### 3.3 시그널 기반 통신

```gdscript
# 예: 전투에서 유닛 행동 시
signal unit_action_ready(unit: Unit)
signal unit_took_damage(unit: Unit, amount: int)
signal global_turn_triggered(turn_number: int)
signal battle_ended(result: BattleResult)
```

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

### 4.6 로컬라이제이션 (localization/*.yaml)

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

### Phase 1: 전투 코어 (목표: 3 vs 3 전투 플레이 가능)

```
[구현 항목]
□ 프로젝트 세팅 및 기본 구조
□ YAML 파서 연동 (godot-yaml 플러그인)
□ DataManager 기본 구현
□ Unit 클래스 (HP, ATB, 기본 스탯)
□ ATB 시스템 (게이지 충전 → 행동)
□ 기본 공격 로직
□ 전투 씬 UI (유닛 배치, HP바, ATB바)
□ 전투 종료 판정

[테스트 데이터]
- 장수 2명 (아군 1, 적 1)
- 유닛 2종 (보병, 궁병)
```

### Phase 2: 전투 확장

```
[구현 항목]
□ 장수 고유 스킬 시스템
□ 글로벌 턴 시스템
□ 카드 시스템 (덱, 드로우, 사용)
□ 전투 카드 효과 (버프/디버프)
□ 진형 선택 (전투 시작 전)

[테스트 데이터]
- 카드 5종
- 스킬 3종
```

### Phase 3: 내정 연결

```
[구현 항목]
□ 내정 씬 기본 UI
□ 선택지 시스템 (3개 중 1개)
□ 선택 → 효과 적용
□ 내정 → 전투 전환
□ 스테이지 진행 흐름

[테스트 데이터]
- 내정 선택지 9개 (카테고리당 3개)
```

### Phase 4: 런 루프

```
[구현 항목]
□ 3 스테이지 연결
□ 강화 선택 화면 (3 중 1)
□ 게임오버 / 클리어 판정
□ 메인 메뉴 → 런 시작 → 엔딩 흐름
□ SaveManager (메타 프로그레션 저장)
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

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2025-01-XX | 초안 작성 |
