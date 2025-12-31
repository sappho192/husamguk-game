# MovementOverlay - 이동 선택 오버레이 컨트롤러
# Phase 5C: 향상된 ATB 시스템
#
# 이동 명령 선택 시 이동 가능한 타일을 표시하고
# 타일 선택을 처리하는 컨트롤러.

class_name MovementOverlay
extends RefCounted

const Corps = preload("res://src/core/corps.gd")
const BattleMap = preload("res://src/core/battle_map.gd")
const TileGridUI = preload("res://src/ui/battle/tile_grid_ui.gd")

## 이동 타일 선택 완료 시그널
signal movement_selected(destination: Vector2i)

## 이동 취소 시그널
signal movement_cancelled()

## 연결된 TileGridUI
var tile_grid: TileGridUI = null

## 연결된 BattleMap
var battle_map: BattleMap = null

## 현재 이동 선택 중인 군단
var selecting_corps: Corps = null

## 이동 가능한 타일 목록 (빠른 검색을 위해 Dictionary 사용)
var reachable_tiles: Dictionary = {}  # Vector2i -> bool

## 점유된 위치 (다른 군단들의 위치)
var occupied_positions: Dictionary = {}  # Vector2i -> Corps

## 이동 선택 활성화 여부
var is_active: bool = false


## TileGridUI와 연결
func connect_to_grid(grid: TileGridUI) -> void:
	if tile_grid != null:
		tile_grid.tile_clicked.disconnect(_on_tile_clicked)

	tile_grid = grid

	if tile_grid != null:
		tile_grid.tile_clicked.connect(_on_tile_clicked)


## BattleMap 설정
func set_battle_map(map: BattleMap) -> void:
	battle_map = map


## 점유 위치 업데이트
func set_occupied_positions(positions: Dictionary) -> void:
	occupied_positions = positions


## 이동 선택 시작
func start_selection(corps: Corps) -> void:
	if tile_grid == null or battle_map == null:
		push_warning("MovementOverlay: TileGridUI or BattleMap not set")
		return

	if corps == null:
		push_warning("MovementOverlay: Null corps provided")
		return

	selecting_corps = corps
	is_active = true

	# 이동 가능한 타일 계산
	var movement_range = corps.get_movement_range()
	var start_pos = corps.grid_position

	reachable_tiles.clear()
	var raw_tiles = battle_map.get_reachable_tiles(start_pos, movement_range, occupied_positions)
	var tile_positions: Array[Vector2i] = []
	for tile in raw_tiles:
		reachable_tiles[tile] = true
		tile_positions.append(tile)

	# 타일 하이라이트
	tile_grid.clear_all_highlights()
	tile_grid.highlight_movement_tiles(tile_positions)

	# 현재 위치 선택 표시
	tile_grid.select_tile(start_pos)

	print("MovementOverlay: Started selection for %s at %s, range %d, %d reachable tiles" % [
		corps.get_display_name(), start_pos, movement_range, reachable_tiles.size()
	])


## 이동 선택 취소
func cancel_selection() -> void:
	if not is_active:
		return

	is_active = false
	selecting_corps = null
	reachable_tiles.clear()

	if tile_grid != null:
		tile_grid.clear_all_highlights()
		tile_grid.clear_selection()

	movement_cancelled.emit()


## 특정 타일이 이동 가능한지 확인
func is_tile_reachable(pos: Vector2i) -> bool:
	return reachable_tiles.has(pos)


## 타일 클릭 핸들러
func _on_tile_clicked(grid_pos: Vector2i) -> void:
	print("MovementOverlay: Tile clicked at %s, is_active=%s" % [grid_pos, is_active])

	if not is_active:
		return

	if selecting_corps == null:
		print("MovementOverlay: No selecting corps, cancelling")
		cancel_selection()
		return

	# 현재 위치 클릭 시 취소
	if grid_pos == selecting_corps.grid_position:
		print("MovementOverlay: Clicked current position, cancelling")
		cancel_selection()
		return

	# 이동 가능한 타일인지 확인
	var is_reachable = is_tile_reachable(grid_pos)
	print("MovementOverlay: Tile %s is reachable: %s (total reachable: %d)" % [
		grid_pos, is_reachable, reachable_tiles.size()
	])

	if not is_reachable:
		print("MovementOverlay: Tile %s is not reachable" % grid_pos)
		return

	# 이동 선택 완료
	var destination = grid_pos
	is_active = false

	if tile_grid != null:
		tile_grid.clear_all_highlights()
		tile_grid.clear_selection()

	print("MovementOverlay: Selected destination %s for %s" % [
		destination, selecting_corps.get_display_name()
	])

	movement_selected.emit(destination)

	# 상태 초기화
	selecting_corps = null
	reachable_tiles.clear()


## 마우스 위치에 따른 경로 미리보기 (선택적 기능)
func preview_path_to(target_pos: Vector2i) -> Array[Vector2i]:
	if not is_active or selecting_corps == null or battle_map == null:
		return []

	if not is_tile_reachable(target_pos):
		return []

	# A* 또는 간단한 경로 찾기
	# 현재는 단순히 시작점과 끝점만 반환
	var path: Array[Vector2i] = []
	path.append(selecting_corps.grid_position)
	path.append(target_pos)
	return path


## 디버그: 현재 도달 가능한 타일 목록 출력
func debug_print_reachable_tiles() -> void:
	print("MovementOverlay: Reachable tiles (%d):" % reachable_tiles.size())
	for pos in reachable_tiles.keys():
		print("  - %s" % pos)


## 현재 선택 중인 군단 반환
func get_selecting_corps() -> Corps:
	return selecting_corps


## 이동 거리 계산 (맨해튼 거리)
func get_distance_to(target_pos: Vector2i) -> int:
	if selecting_corps == null:
		return -1

	var start = selecting_corps.grid_position
	return abs(target_pos.x - start.x) + abs(target_pos.y - start.y)
