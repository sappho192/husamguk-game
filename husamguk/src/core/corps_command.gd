# CorpsCommand - 군단 명령 데이터 클래스
# Phase 5C: 향상된 ATB 시스템
#
# 군단이 ATB가 차면 실행할 명령을 정의.
# 글로벌 턴에서 이동 명령이 실행됨.

class_name CorpsCommand
extends RefCounted

const Corps = preload("res://src/core/corps.gd")

## 명령 유형
enum CommandType {
	ATTACK,   # 공격: 대상 군단에 피해
	DEFEND,   # 방어: 다음 턴까지 방어력 증가
	EVADE,    # 회피: 다음 공격 회피 확률 증가
	WATCH,    # 경계: 적 이동 시 반격
	MOVE      # 이동: 지정 타일로 이동 (글로벌 턴에 실행)
}

## 명령 유형
var type: CommandType = CommandType.ATTACK

## 명령을 내린 군단
var source_corps: Corps = null

## 대상 군단 (ATTACK, WATCH 등)
var target_corps: Corps = null

## 대상 위치 (MOVE)
var target_position: Vector2i = Vector2i(-1, -1)

## 명령 생성 시간 (우선순위용)
var created_at: float = 0.0

## 명령 실행 여부
var executed: bool = false


func _init(cmd_type: CommandType = CommandType.ATTACK, source: Corps = null) -> void:
	type = cmd_type
	source_corps = source
	created_at = Time.get_ticks_msec() / 1000.0


## === 팩토리 메서드 ===
## 주의: 정적 메서드에서 클래스 자체 참조 불가로 인스턴스 메서드로 구현

## 공격 명령으로 설정
func set_as_attack(target: Corps) -> CorpsCommand:
	type = CommandType.ATTACK
	target_corps = target
	return self


## 방어 명령으로 설정
func set_as_defend() -> CorpsCommand:
	type = CommandType.DEFEND
	return self


## 회피 명령으로 설정
func set_as_evade() -> CorpsCommand:
	type = CommandType.EVADE
	return self


## 경계 명령으로 설정
func set_as_watch(target: Corps = null) -> CorpsCommand:
	type = CommandType.WATCH
	target_corps = target
	return self


## 이동 명령으로 설정
func set_as_move(destination: Vector2i) -> CorpsCommand:
	type = CommandType.MOVE
	target_position = destination
	return self


## === 유틸리티 ===

## 명령 유형 이름 반환
func get_type_name() -> String:
	match type:
		CommandType.ATTACK:
			return "ATTACK"
		CommandType.DEFEND:
			return "DEFEND"
		CommandType.EVADE:
			return "EVADE"
		CommandType.WATCH:
			return "WATCH"
		CommandType.MOVE:
			return "MOVE"
	return "UNKNOWN"


## 명령 유형별 로컬라이제이션 키
func get_type_localization_key() -> String:
	match type:
		CommandType.ATTACK:
			return "COMMAND_ATTACK"
		CommandType.DEFEND:
			return "COMMAND_DEFEND"
		CommandType.EVADE:
			return "COMMAND_EVADE"
		CommandType.WATCH:
			return "COMMAND_WATCH"
		CommandType.MOVE:
			return "COMMAND_MOVE"
	return "COMMAND_UNKNOWN"


## 명령이 대상을 필요로 하는지 확인
func requires_target_corps() -> bool:
	return type == CommandType.ATTACK


## 명령이 위치를 필요로 하는지 확인
func requires_target_position() -> bool:
	return type == CommandType.MOVE


## 명령이 유효한지 확인
func is_valid() -> bool:
	if source_corps == null:
		return false

	if not source_corps.is_alive:
		return false

	match type:
		CommandType.ATTACK:
			if target_corps == null:
				return false
			if not target_corps.is_alive:
				return false
		CommandType.MOVE:
			if target_position == Vector2i(-1, -1):
				return false

	return true


## 디버그용 문자열
func _to_string() -> String:
	var source_name = source_corps.get_display_name() if source_corps else "None"
	match type:
		CommandType.ATTACK:
			var target_name = target_corps.get_display_name() if target_corps else "None"
			return "Command(ATTACK: %s -> %s)" % [source_name, target_name]
		CommandType.MOVE:
			return "Command(MOVE: %s -> %s)" % [source_name, target_position]
		_:
			return "Command(%s: %s)" % [get_type_name(), source_name]
