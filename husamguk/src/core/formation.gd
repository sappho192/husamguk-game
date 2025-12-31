# Formation - 진형 데이터 클래스
# Phase 5B: 군단 시스템
#
# 진형은 군단의 스탯을 수정하는 전술적 배치 방식.
# 공격력, 방어력, ATB 속도, 이동 범위에 영향을 줌.

class_name Formation
extends RefCounted

## 진형 식별자
var id: String

## 표시 이름 (로컬라이제이션 키)
var name_key: String

## 설명 (로컬라이제이션 키)
var description_key: String

## 사용 가능 병종 제한 (비어있으면 전체 가능)
var category_restriction: Array[String] = []

## 스탯 수정치
var attack_modifier: int       # 공격력 수정 (%)
var defense_modifier: int      # 방어력 수정 (%)
var atb_modifier: float        # ATB 속도 수정 (절대값)
var movement_modifier: int     # 이동 범위 수정 (타일)

## 특수 효과 목록
var special_effects: Array = []

## 시각적 힌트 (UI 표시용)
var visual_hint: String


func _init(data: Dictionary = {}) -> void:
	id = data.get("id", "default")
	name_key = data.get("name_key", "")
	description_key = data.get("description_key", "")

	# 병종 제한 파싱
	var restrictions = data.get("category_restriction", [])
	category_restriction.clear()
	for restriction in restrictions:
		category_restriction.append(str(restriction))

	# 스탯 수정치 파싱
	var modifiers = data.get("stat_modifiers", {})
	attack_modifier = modifiers.get("attack_modifier", 0)
	defense_modifier = modifiers.get("defense_modifier", 0)
	atb_modifier = modifiers.get("atb_modifier", 0.0)
	movement_modifier = modifiers.get("movement_modifier", 0)

	# 특수 효과 파싱
	special_effects = data.get("special_effects", [])

	visual_hint = data.get("visual_hint", "")


## 특정 병종이 이 진형을 사용할 수 있는지 확인
func can_be_used_by(category: String) -> bool:
	if category_restriction.is_empty():
		return true
	return category in category_restriction


## 공격력 수정치 적용
## base_attack: 기본 공격력
## returns: 수정된 공격력
func apply_attack_modifier(base_attack: int) -> int:
	return int(base_attack * (1.0 + attack_modifier / 100.0))


## 방어력 수정치 적용
## base_defense: 기본 방어력
## returns: 수정된 방어력
func apply_defense_modifier(base_defense: int) -> int:
	return int(base_defense * (1.0 + defense_modifier / 100.0))


## ATB 속도 수정치 적용
## base_atb_speed: 기본 ATB 속도
## returns: 수정된 ATB 속도
func apply_atb_modifier(base_atb_speed: float) -> float:
	return maxf(0.1, base_atb_speed + atb_modifier)


## 이동 범위 수정치 적용
## base_movement: 기본 이동 범위
## returns: 수정된 이동 범위
func apply_movement_modifier(base_movement: int) -> int:
	return maxi(1, base_movement + movement_modifier)


## 특수 효과 확인
## effect_id: 효과 ID
## returns: 효과가 있으면 해당 효과 데이터, 없으면 null
func get_special_effect(effect_id: String) -> Dictionary:
	for effect in special_effects:
		if effect.get("effect_id", "") == effect_id:
			return effect
	return {}


## 특수 효과 값 가져오기
## effect_id: 효과 ID
## returns: 효과 값 (없으면 0)
func get_special_effect_value(effect_id: String) -> float:
	var effect = get_special_effect(effect_id)
	return effect.get("value", 0.0)


## 로컬라이즈된 이름 반환
func get_display_name() -> String:
	if name_key.is_empty():
		return id
	return DataManager.get_localized(name_key)


## 로컬라이즈된 설명 반환
func get_description() -> String:
	if description_key.is_empty():
		return ""
	return DataManager.get_localized(description_key)


## 진형 요약 문자열 (디버그/UI용)
func get_summary() -> String:
	var parts: Array[String] = []
	if attack_modifier != 0:
		parts.append("ATK %+d%%" % attack_modifier)
	if defense_modifier != 0:
		parts.append("DEF %+d%%" % defense_modifier)
	if atb_modifier != 0.0:
		parts.append("ATB %+.2f" % atb_modifier)
	if movement_modifier != 0:
		parts.append("MOV %+d" % movement_modifier)

	if parts.is_empty():
		return "No modifiers"
	return ", ".join(parts)


## 디버그용 문자열 표현
func _to_string() -> String:
	return "Formation(%s: %s)" % [id, get_summary()]
