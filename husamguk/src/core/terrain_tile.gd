# TerrainTile - 지형 타일 데이터 클래스
# Phase 5A: 전투 지형 시스템
#
# 각 타일의 지형 타입과 효과를 정의.
# 이동 비용, 방어/공격 수정치, ATB 수정치 등을 관리.

class_name TerrainTile
extends RefCounted

## 지형 식별자
var id: String

## 표시 이름 (로컬라이제이션 키)
var name_key: String

## 설명 (로컬라이제이션 키)
var description_key: String

## 타일 색상 (표시용)
var color: Color

## 맵 그리드 문자열에서 사용하는 문자 코드
var char_code: String

## 이동 비용 배율 (1.0 = 기본, 높을수록 느림)
var movement_cost: float

## 방어력 수정치 (%)
var defense_modifier: int

## 공격력 수정치 (%)
var attack_modifier: int

## ATB 속도 수정치
var atb_modifier: float

## 이동 가능 여부
var passable: bool

## 특수 효과 목록
var special_effects: Array


func _init(data: Dictionary = {}) -> void:
	id = data.get("id", "plain")
	name_key = data.get("name_key", "")
	description_key = data.get("description_key", "")

	# 색상 파싱 (hex 문자열)
	var color_str: String = data.get("color", "#90EE90")
	color = Color.from_string(color_str, Color.LIGHT_GREEN)

	char_code = data.get("char_code", "P")
	movement_cost = data.get("movement_cost", 1.0)
	defense_modifier = data.get("defense_modifier", 0)
	attack_modifier = data.get("attack_modifier", 0)
	atb_modifier = data.get("atb_modifier", 0.0)
	passable = data.get("passable", true)
	special_effects = data.get("special_effects", [])


## 이동 가능한지 확인
func is_passable() -> bool:
	return passable


## 방어력 수정치를 적용한 값 계산
## base_defense: 기본 방어력
## returns: 수정된 방어력
func apply_defense_modifier(base_defense: int) -> int:
	return int(base_defense * (1.0 + defense_modifier / 100.0))


## 공격력 수정치를 적용한 값 계산
## base_attack: 기본 공격력
## returns: 수정된 공격력
func apply_attack_modifier(base_attack: int) -> int:
	return int(base_attack * (1.0 + attack_modifier / 100.0))


## ATB 속도 수정치를 적용한 값 계산
## base_atb_speed: 기본 ATB 속도
## returns: 수정된 ATB 속도
func apply_atb_modifier(base_atb_speed: float) -> float:
	return maxf(0.1, base_atb_speed + atb_modifier)


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


## 디버그용 문자열 표현
func _to_string() -> String:
	return "TerrainTile(%s, move=%.1f, def=%d%%, atk=%d%%)" % [
		id, movement_cost, defense_modifier, attack_modifier
	]
