# Corps - 군단 데이터 클래스
# Phase 5B: 군단 시스템
#
# 군단은 장수가 지휘하는 병사 그룹.
# 하나의 군단은 하나의 타일을 점유하며, 동일 병종 카테고리의 병사만 포함.

class_name Corps
extends RefCounted

const Buff = preload("res://src/core/buff.gd")
const General = preload("res://src/core/general.gd")
const Formation = preload("res://src/core/formation.gd")
const TerrainTile = preload("res://src/core/terrain_tile.gd")

## 시그널
signal atb_filled(corps: Corps)
signal took_damage(casualties: int, remaining: int)
signal destroyed()
signal formation_changed(old_formation: String, new_formation: String)
signal position_changed(old_pos: Vector2i, new_pos: Vector2i)

## === 식별 정보 ===
var id: String
var template_id: String           # 군단 템플릿 ID
var display_name: String
var category: String              # infantry, cavalry, archer

## === 지휘 구조 ===
var general: General = null       # 지휘 장수

## === 병사 구성 ===
var soldier_count: int            # 현재 병사 수
var max_soldier_count: int        # 최대 병사 수
var soldier_unit_id: String       # 병사 기본 유닛 ID

## === 기본 스탯 ===
var base_hp_per_soldier: int
var base_attack_per_soldier: int
var base_defense: int
var base_atb_speed: float
var base_movement_range: int
var base_attack_range: int         # 공격 사거리 (보병 1, 기병 2, 궁병 4-5)

## === 현재 상태 ===
var current_hp: int               # 총 HP (병사 수 * 병사당 HP)
var max_hp: int
var atb_current: float = 0.0
var atb_max: float = 100.0

## === 진형 ===
var current_formation: Formation = null
var available_formations: Array[String] = []

## === 버프/디버프 ===
var active_buffs: Array = []      # Array[Buff]

## === 그리드 위치 ===
var grid_position: Vector2i = Vector2i(-1, -1)
var current_terrain: TerrainTile = null

## === 전투 상태 ===
var is_ally: bool = true
var is_alive: bool = true

## === 특성 ===
var traits: Array[String] = []


func _init(data: Dictionary = {}, assigned_general: General = null) -> void:
	template_id = data.get("id", "")
	id = template_id + "_" + str(randi())  # 고유 인스턴스 ID
	display_name = data.get("name_key", "")
	category = data.get("category", "infantry")
	soldier_unit_id = data.get("soldier_unit_id", "")

	general = assigned_general

	# 기본 스탯 파싱
	var base_stats = data.get("base_stats", {})
	base_hp_per_soldier = base_stats.get("hp_per_soldier", 10)
	base_attack_per_soldier = base_stats.get("attack_per_soldier", 5)
	base_defense = base_stats.get("defense", 10)
	base_atb_speed = base_stats.get("atb_speed", 1.0)
	base_movement_range = base_stats.get("movement_range", 2)
	base_attack_range = base_stats.get("attack_range", 1)  # 기본 1 (근접)

	# 사용 가능 진형 파싱
	available_formations.clear()
	var formations = data.get("available_formations", ["default"])
	for formation_id in formations:
		available_formations.append(str(formation_id))

	# 특성 파싱
	traits.clear()
	var trait_list = data.get("traits", [])
	for trait_id in trait_list:
		traits.append(str(trait_id))

	# 병사 수 계산 (장수 통솔력 보너스)
	var base_count = data.get("base_soldier_count", 30)
	if general != null:
		# 통솔력 10당 병사 +1명
		max_soldier_count = base_count + int(general.leadership / 10)
	else:
		max_soldier_count = base_count
	soldier_count = max_soldier_count

	# HP 계산
	max_hp = soldier_count * base_hp_per_soldier
	current_hp = max_hp

	# 기본 진형 설정
	var default_formation_id = data.get("default_formation", "default")
	_set_formation_internal(default_formation_id)


## === ATB 시스템 ===

## ATB 틱 (매 프레임 호출)
func tick_atb(delta: float) -> void:
	if not is_alive:
		return

	# ATB 증가 (스케일 팩터 27 - 1.5배 느림)
	atb_current += get_effective_atb_speed() * delta * 27.0

	if atb_current >= atb_max:
		atb_current = atb_max
		atb_filled.emit(self)


## ATB 리셋
func reset_atb() -> void:
	atb_current = 0.0


## === 유효 스탯 계산 ===

## 유효 공격력 (진형, 버프, 장수, 지형 적용)
func get_effective_attack() -> int:
	var base = soldier_count * base_attack_per_soldier
	var modifier = 1.0

	# 진형 수정치
	if current_formation != null:
		modifier += current_formation.attack_modifier / 100.0

	# 버프 수정치
	for buff in active_buffs:
		if buff.stat == Buff.Stat.ATTACK:
			modifier += buff.calculate_modifier(base) / float(base) if base > 0 else 0.0

	# 장수 무력 보너스 (최대 +50%)
	if general != null:
		modifier += general.combat / 200.0

	# 지형 수정치
	if current_terrain != null:
		modifier += current_terrain.attack_modifier / 100.0

	return maxi(1, int(base * modifier))


## 유효 방어력 (진형, 버프, 지형 적용)
func get_effective_defense() -> int:
	var base = base_defense
	var modifier = 1.0

	# 진형 수정치
	if current_formation != null:
		modifier += current_formation.defense_modifier / 100.0

	# 버프 수정치
	for buff in active_buffs:
		if buff.stat == Buff.Stat.DEFENSE:
			modifier += buff.calculate_modifier(base) / float(base) if base > 0 else 0.0

	# 지형 수정치
	if current_terrain != null:
		modifier += current_terrain.defense_modifier / 100.0

	return maxi(0, int(base * modifier))


## 유효 ATB 속도 (진형, 버프, 장수, 지형 적용)
func get_effective_atb_speed() -> float:
	var base = base_atb_speed
	var modifier = 0.0

	# 진형 수정치
	if current_formation != null:
		modifier += current_formation.atb_modifier

	# 버프 수정치
	for buff in active_buffs:
		if buff.stat == Buff.Stat.ATB_SPEED:
			modifier += buff.calculate_modifier(base)

	# 장수 지력 보너스 (최대 +0.2)
	if general != null:
		modifier += general.intelligence / 500.0

	# 지형 수정치
	if current_terrain != null:
		modifier += current_terrain.atb_modifier

	return maxf(0.1, base + modifier)


## 유효 이동 범위 (진형 적용)
func get_movement_range() -> int:
	var base = base_movement_range

	# 진형 수정치
	if current_formation != null:
		base += current_formation.movement_modifier

	return maxi(1, base)


## 유효 공격 사거리 (진형, 버프 적용)
func get_attack_range() -> int:
	var base = base_attack_range

	# 진형 수정치 (TODO: 진형에 attack_range_modifier 추가 시 적용)

	# 버프 수정치 (TODO: range 버프 시스템 추가 시 적용)

	return maxi(1, base)


## 대상까지의 거리 계산 (맨해튼 거리)
func distance_to(target: Corps) -> int:
	if target == null:
		return 999
	return abs(grid_position.x - target.grid_position.x) + abs(grid_position.y - target.grid_position.y)


## 대상이 공격 사거리 내에 있는지 확인
func is_target_in_range(target: Corps) -> bool:
	if target == null or not target.is_alive:
		return false
	return distance_to(target) <= get_attack_range()


## 공격 가능한 대상 목록 반환
func get_targets_in_range(all_targets: Array) -> Array:
	var in_range: Array = []
	for target in all_targets:
		if is_target_in_range(target):
			in_range.append(target)
	return in_range


## === 전투 ===

## 피해 받기
func take_damage(amount: int) -> void:
	var effective_defense = get_effective_defense()
	var mitigated = maxi(1, amount - effective_defense)
	current_hp = maxi(0, current_hp - mitigated)

	# 사상자 계산
	var old_count = soldier_count
	soldier_count = ceili(float(current_hp) / float(base_hp_per_soldier))
	var casualties = old_count - soldier_count

	if casualties > 0:
		print("%s lost %d soldiers! (%d remaining)" % [get_display_name(), casualties, soldier_count])

	took_damage.emit(casualties, soldier_count)

	if current_hp <= 0:
		is_alive = false
		destroyed.emit()


## 대상 공격
func attack_target(target: Corps) -> int:
	var damage = get_effective_attack()

	# 특성 보너스 적용
	damage = _apply_trait_bonuses(damage, target)

	target.take_damage(damage)
	return damage


## 특성 보너스 적용
func _apply_trait_bonuses(damage: int, target: Corps) -> int:
	# 대기병 특성
	if "anti_cavalry" in traits and target.category == "cavalry":
		damage = int(damage * 1.5)

	# 돌격 특성 (첫 공격 시) - TODO: 첫 공격 여부 추적 필요

	return damage


## === 진형 ===

## 진형 변경
func set_formation(formation_id: String) -> bool:
	if formation_id not in available_formations:
		push_warning("Formation not available for this corps: " + formation_id)
		return false

	var old_formation_id = current_formation.id if current_formation else "none"
	if not _set_formation_internal(formation_id):
		return false

	formation_changed.emit(old_formation_id, formation_id)
	return true


## 내부 진형 설정
func _set_formation_internal(formation_id: String) -> bool:
	var formation_data = DataManager.get_formation(formation_id)
	if formation_data.is_empty():
		push_warning("Formation data not found: " + formation_id)
		return false

	var new_formation = Formation.new(formation_data)

	# 병종 제한 확인
	if not new_formation.can_be_used_by(category):
		push_warning("Formation %s cannot be used by %s" % [formation_id, category])
		return false

	current_formation = new_formation
	return true


## === 위치 ===

## 그리드 위치 설정
func set_grid_position(pos: Vector2i, terrain: TerrainTile = null) -> void:
	var old_pos = grid_position
	grid_position = pos
	current_terrain = terrain
	position_changed.emit(old_pos, pos)


## === 버프 ===

## 버프 추가
func add_buff(buff: Buff) -> void:
	active_buffs.append(buff)


## 버프 제거
func remove_buff(buff: Buff) -> void:
	active_buffs.erase(buff)


## 버프 지속시간 틱 (글로벌 턴마다 호출)
func tick_buff_durations() -> void:
	var expired_buffs: Array = []
	for buff in active_buffs:
		buff.duration -= 1
		if buff.duration <= 0:
			expired_buffs.append(buff)

	for buff in expired_buffs:
		remove_buff(buff)


## === HP 관리 ===

## HP 회복
func heal(amount: int) -> void:
	current_hp = mini(current_hp + amount, max_hp)
	soldier_count = ceili(float(current_hp) / float(base_hp_per_soldier))


## HP 퍼센트 회복
func heal_percent(percent: float) -> void:
	var amount = int(max_hp * percent / 100.0)
	heal(amount)


## === 유틸리티 ===

## 로컬라이즈된 이름 반환
func get_display_name() -> String:
	if display_name.is_empty():
		return template_id
	return DataManager.get_localized(display_name)


## 장수 이름 포함 전체 이름
func get_full_name() -> String:
	var corps_name = get_display_name()
	if general != null:
		return "%s의 %s" % [general.get_display_name(), corps_name]
	return corps_name


## HP 퍼센트
func get_hp_percent() -> float:
	if max_hp <= 0:
		return 0.0
	return float(current_hp) / float(max_hp) * 100.0


## ATB 퍼센트
func get_atb_percent() -> float:
	return atb_current / atb_max * 100.0


## 디버그용 문자열
func _to_string() -> String:
	return "Corps(%s, %s, %d/%d soldiers, HP: %d/%d)" % [
		template_id,
		current_formation.id if current_formation else "no_formation",
		soldier_count, max_soldier_count,
		current_hp, max_hp
	]
