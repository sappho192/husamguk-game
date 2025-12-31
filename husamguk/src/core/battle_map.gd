# BattleMap - 전투 맵 데이터 클래스
# Phase 5A: 전투 지형 시스템
#
# 16x16 그리드 기반 전투 맵을 관리.
# 지형 정보, 스폰 존, 유닛 위치 등을 처리.

class_name BattleMap
extends RefCounted

const TerrainTile = preload("res://src/core/terrain_tile.gd")

## 기본 그리드 크기
const DEFAULT_WIDTH: int = 16
const DEFAULT_HEIGHT: int = 16

## 맵 식별자
var id: String

## 표시 이름 (로컬라이제이션 키)
var name_key: String

## 설명 (로컬라이제이션 키)
var description_key: String

## 맵 크기
var width: int
var height: int

## 지형 그리드 (2D 배열: terrain_grid[y][x])
var terrain_grid: Array = []

## 아군 스폰 가능 좌표
var ally_spawn_zones: Array[Vector2i] = []

## 적군 스폰 좌표
var enemy_spawn_zones: Array[Vector2i] = []

## 특수 타일 목록
var special_tiles: Array = []

## 지형 문자 코드 → 지형 ID 매핑
var _terrain_char_map: Dictionary = {}


func _init(data: Dictionary = {}) -> void:
	id = data.get("id", "")
	name_key = data.get("name_key", "")
	description_key = data.get("description_key", "")

	var size_data = data.get("size", {})
	width = size_data.get("width", DEFAULT_WIDTH)
	height = size_data.get("height", DEFAULT_HEIGHT)

	# 지형 문자 코드 맵 생성
	_build_terrain_char_map()

	# 지형 그리드 파싱
	var grid_string: String = data.get("terrain_grid", "")
	_parse_terrain_grid(grid_string)

	# 스폰 존 파싱
	_parse_spawn_zones(data)

	# 특수 타일 파싱
	special_tiles = data.get("special_tiles", [])


## DataManager에서 모든 지형 데이터를 로드하여 문자 코드 맵 생성
func _build_terrain_char_map() -> void:
	_terrain_char_map.clear()

	# DataManager에서 모든 지형 데이터 가져오기
	var all_terrains = DataManager.get_all_terrains()
	for terrain_id in all_terrains:
		var terrain_data = all_terrains[terrain_id]
		var char_code: String = terrain_data.get("char_code", "")
		if not char_code.is_empty():
			_terrain_char_map[char_code] = terrain_id

	# 기본 매핑 (DataManager 로드 전 fallback)
	if _terrain_char_map.is_empty():
		_terrain_char_map = {
			"P": "plain",
			"M": "mountain",
			"F": "forest",
			"R": "river",
			"D": "road",
			"W": "wall"
		}


## 지형 그리드 문자열을 파싱하여 TerrainTile 2D 배열로 변환
func _parse_terrain_grid(grid_string: String) -> void:
	terrain_grid.clear()

	var lines = grid_string.strip_edges().split("\n")

	for y in range(height):
		var row: Array = []
		var line: String = lines[y] if y < lines.size() else ""

		for x in range(width):
			var char_code: String = line[x] if x < line.length() else "P"
			var terrain_id: String = _terrain_char_map.get(char_code, "plain")
			var terrain_data = DataManager.get_terrain(terrain_id)

			# 지형 데이터가 없으면 기본값 사용
			if terrain_data.is_empty():
				terrain_data = {"id": "plain", "color": "#90EE90", "passable": true}

			var tile = TerrainTile.new(terrain_data)
			row.append(tile)

		terrain_grid.append(row)


## 스폰 존 좌표 파싱
func _parse_spawn_zones(data: Dictionary) -> void:
	ally_spawn_zones.clear()
	enemy_spawn_zones.clear()

	var ally_zones = data.get("ally_spawn_zones", [])
	for zone in ally_zones:
		var pos = Vector2i(zone.get("x", 0), zone.get("y", 0))
		if _is_valid_position(pos):
			ally_spawn_zones.append(pos)

	var enemy_zones = data.get("enemy_spawn_zones", [])
	for zone in enemy_zones:
		var pos = Vector2i(zone.get("x", 0), zone.get("y", 0))
		if _is_valid_position(pos):
			enemy_spawn_zones.append(pos)


## 좌표가 맵 범위 내인지 확인
func _is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height


## 특정 좌표의 지형 타일 반환
## pos: 그리드 좌표 (Vector2i)
## returns: TerrainTile 또는 null (범위 밖)
func get_terrain_at(pos: Vector2i) -> TerrainTile:
	if not _is_valid_position(pos):
		return null
	return terrain_grid[pos.y][pos.x]


## 특정 좌표의 지형 ID 반환
func get_terrain_id_at(pos: Vector2i) -> String:
	var terrain = get_terrain_at(pos)
	if terrain == null:
		return ""
	return terrain.id


## 특정 좌표가 이동 가능한지 확인
func is_passable(pos: Vector2i) -> bool:
	var terrain = get_terrain_at(pos)
	return terrain != null and terrain.is_passable()


## 특정 좌표가 맵 범위 내인지 확인
func is_valid_position(pos: Vector2i) -> bool:
	return _is_valid_position(pos)


## 주어진 위치에서 이동 가능한 인접 타일 목록 반환
## pos: 현재 위치
## returns: 이동 가능한 인접 좌표 목록
func get_adjacent_passable(pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var directions = [
		Vector2i(0, -1),  # 상
		Vector2i(0, 1),   # 하
		Vector2i(-1, 0),  # 좌
		Vector2i(1, 0),   # 우
	]

	for dir in directions:
		var adjacent = pos + dir
		if is_passable(adjacent):
			result.append(adjacent)

	return result


## 주어진 위치에서 범위 내 이동 가능한 모든 타일 반환 (BFS)
## start: 시작 위치
## movement_range: 이동 범위
## occupied_positions: 이미 점령된 위치 목록 (Dictionary[Vector2i, bool])
## returns: 이동 가능한 좌표 목록
func get_reachable_tiles(start: Vector2i, movement_range: int, occupied_positions: Dictionary = {}) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var visited: Dictionary = {}
	var queue: Array = []  # [position, remaining_movement]

	queue.append([start, movement_range])
	visited[start] = true

	while queue.size() > 0:
		var current = queue.pop_front()
		var pos: Vector2i = current[0]
		var remaining: int = current[1]

		# 시작 위치가 아니면 결과에 추가
		if pos != start and not occupied_positions.has(pos):
			result.append(pos)

		if remaining <= 0:
			continue

		# 인접 타일 탐색
		var adjacent = get_adjacent_passable(pos)
		for adj_pos in adjacent:
			if visited.has(adj_pos):
				continue

			var terrain = get_terrain_at(adj_pos)
			if terrain == null:
				continue

			# 이동 비용 계산
			var cost = int(ceil(terrain.movement_cost))
			if remaining >= cost:
				visited[adj_pos] = true
				queue.append([adj_pos, remaining - cost])

	return result


## 두 위치 간 맨해튼 거리 계산
func get_distance(from: Vector2i, to: Vector2i) -> int:
	return abs(from.x - to.x) + abs(from.y - to.y)


## 로컬라이즈된 맵 이름 반환
func get_display_name() -> String:
	if name_key.is_empty():
		return id
	return DataManager.get_localized(name_key)


## 디버그용: 맵을 문자열로 출력
func debug_print() -> void:
	print("=== BattleMap: %s ===" % id)
	print("Size: %dx%d" % [width, height])

	for y in range(height):
		var line = ""
		for x in range(width):
			var terrain = terrain_grid[y][x] as TerrainTile
			line += terrain.char_code
		print(line)

	print("Ally spawns: ", ally_spawn_zones)
	print("Enemy spawns: ", enemy_spawn_zones)
