# TileGridUI - 16x16 전투 그리드 UI
# Phase 5A: 전투 지형 시스템
#
# 전체 전투 맵을 표시하는 그리드 컨테이너.
# 타일 클릭/호버 처리, 하이라이트 관리.

class_name TileGridUI
extends Control

const TileDisplay = preload("res://src/ui/battle/tile_display.gd")
const BattleMap = preload("res://src/core/battle_map.gd")
const TerrainTile = preload("res://src/core/terrain_tile.gd")

## 타일 클릭 시그널
signal tile_clicked(grid_pos: Vector2i)

## 타일 호버 시그널
signal tile_hovered(grid_pos: Vector2i)

## 유닛 클릭 시그널
signal unit_clicked(grid_pos: Vector2i)

## 타일 크기 (픽셀)
const TILE_SIZE: int = 40

## 기본 그리드 크기
const DEFAULT_WIDTH: int = 16
const DEFAULT_HEIGHT: int = 16

## 현재 맵 데이터
var battle_map: BattleMap = null

## 그리드 크기
var grid_width: int = DEFAULT_WIDTH
var grid_height: int = DEFAULT_HEIGHT

## 타일 표시 2D 배열 (tile_displays[y][x])
var tile_displays: Array = []

## 현재 선택된 타일
var selected_tile: Vector2i = Vector2i(-1, -1)

## 현재 호버 중인 타일
var hovered_tile: Vector2i = Vector2i(-1, -1)

## 디버그 레이블 표시 여부
var show_debug_labels: bool = false


func _init() -> void:
	_create_grid()


func _create_grid() -> void:
	tile_displays.clear()

	# 기존 자식 노드 제거
	for child in get_children():
		child.queue_free()

	# 그리드 크기 설정
	custom_minimum_size = Vector2(TILE_SIZE * grid_width, TILE_SIZE * grid_height)
	size = custom_minimum_size

	# 타일 생성
	for y in range(grid_height):
		var row: Array = []
		for x in range(grid_width):
			var tile_display = TileDisplay.new()
			tile_display.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			tile_display.grid_pos = Vector2i(x, y)
			tile_display.tile_clicked.connect(_on_tile_clicked)
			tile_display.tile_hovered.connect(_on_tile_hovered)
			add_child(tile_display)
			row.append(tile_display)
		tile_displays.append(row)


## 맵 데이터로 그리드 초기화
func setup(map: BattleMap) -> void:
	battle_map = map

	if map == null:
		push_warning("TileGridUI: Null map provided")
		return

	# 그리드 크기가 다르면 재생성
	if map.width != grid_width or map.height != grid_height:
		grid_width = map.width
		grid_height = map.height
		_create_grid()

	# 각 타일에 지형 데이터 설정
	for y in range(grid_height):
		for x in range(grid_width):
			var terrain = map.get_terrain_at(Vector2i(x, y))
			if y < tile_displays.size() and x < tile_displays[y].size():
				var tile_display: TileDisplay = tile_displays[y][x]
				tile_display.setup_terrain(terrain)
				tile_display.show_terrain_label(show_debug_labels)


## 특정 타일들을 하이라이트
## positions: 하이라이트할 좌표 목록
## color: 하이라이트 색상
func highlight_tiles(positions: Array, color: Color) -> void:
	for pos in positions:
		if pos is Vector2i and _is_valid_pos(pos):
			tile_displays[pos.y][pos.x].set_highlight(color)


## 이동 가능한 타일을 하이라이트 (파란색)
func highlight_movement_tiles(positions: Array) -> void:
	highlight_tiles(positions, Color.DODGER_BLUE)


## 공격 가능한 타일을 하이라이트 (빨간색)
func highlight_attack_tiles(positions: Array) -> void:
	highlight_tiles(positions, Color.INDIAN_RED)


## 스폰 가능한 타일을 하이라이트 (녹색)
func highlight_spawn_tiles(positions: Array) -> void:
	highlight_tiles(positions, Color.LIME_GREEN)


## 모든 하이라이트 해제
func clear_all_highlights() -> void:
	for row in tile_displays:
		for tile in row:
			tile.clear_highlight()


## 특정 타일 선택
func select_tile(pos: Vector2i) -> void:
	# 이전 선택 해제
	if _is_valid_pos(selected_tile):
		tile_displays[selected_tile.y][selected_tile.x].set_selected(false)

	selected_tile = pos

	# 새 타일 선택
	if _is_valid_pos(pos):
		tile_displays[pos.y][pos.x].set_selected(true)


## 선택 해제
func clear_selection() -> void:
	if _is_valid_pos(selected_tile):
		tile_displays[selected_tile.y][selected_tile.x].set_selected(false)
	selected_tile = Vector2i(-1, -1)


## 특정 좌표의 TileDisplay 가져오기
func get_tile_display(pos: Vector2i) -> TileDisplay:
	if not _is_valid_pos(pos):
		return null
	return tile_displays[pos.y][pos.x]


## 그리드 좌표가 유효한지 확인
func _is_valid_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_width and pos.y >= 0 and pos.y < grid_height


## 화면 좌표를 그리드 좌표로 변환
func screen_to_grid(screen_pos: Vector2) -> Vector2i:
	var local_pos = screen_pos - global_position
	var grid_x = int(local_pos.x / TILE_SIZE)
	var grid_y = int(local_pos.y / TILE_SIZE)
	return Vector2i(grid_x, grid_y)


## 그리드 좌표를 화면 좌표로 변환 (타일 중심)
func grid_to_screen(grid_pos: Vector2i) -> Vector2:
	return global_position + Vector2(
		grid_pos.x * TILE_SIZE + TILE_SIZE / 2.0,
		grid_pos.y * TILE_SIZE + TILE_SIZE / 2.0
	)


## 타일 클릭 콜백
func _on_tile_clicked(grid_pos: Vector2i) -> void:
	tile_clicked.emit(grid_pos)


## 타일 호버 콜백
func _on_tile_hovered(grid_pos: Vector2i) -> void:
	if grid_pos != hovered_tile:
		hovered_tile = grid_pos
		tile_hovered.emit(grid_pos)


## 디버그 레이블 표시/숨김
func toggle_debug_labels() -> void:
	show_debug_labels = not show_debug_labels
	for row in tile_displays:
		for tile in row:
			tile.show_terrain_label(show_debug_labels)


## 아군 스폰 존 표시
func show_ally_spawn_zones() -> void:
	if battle_map == null:
		return
	highlight_spawn_tiles(battle_map.ally_spawn_zones)


## 적군 스폰 존 표시
func show_enemy_spawn_zones() -> void:
	if battle_map == null:
		return
	highlight_tiles(battle_map.enemy_spawn_zones, Color.ORANGE_RED)
