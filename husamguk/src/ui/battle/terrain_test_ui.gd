# TerrainTestUI - 지형 시스템 테스트 UI
# Phase 5A: 전투 지형 시스템 테스트용

extends Control

const TileGridUI = preload("res://src/ui/battle/tile_grid_ui.gd")
const BattleMap = preload("res://src/core/battle_map.gd")

var tile_grid: TileGridUI
var info_label: Label
var map_selector: OptionButton
var debug_toggle: CheckButton

var current_map: BattleMap


func _ready() -> void:
	_create_ui()
	_load_first_map()


func _create_ui() -> void:
	# 맵 선택 드롭다운
	var top_bar = HBoxContainer.new()
	top_bar.position = Vector2(20, 20)
	add_child(top_bar)

	var map_label = Label.new()
	map_label.text = "Map: "
	top_bar.add_child(map_label)

	map_selector = OptionButton.new()
	map_selector.custom_minimum_size = Vector2(200, 30)
	var all_maps = DataManager.get_all_maps()
	for map_id in all_maps:
		var map_data = all_maps[map_id]
		var display_name = DataManager.get_localized(map_data.get("name_key", map_id))
		map_selector.add_item(display_name, map_selector.item_count)
		map_selector.set_item_metadata(map_selector.item_count - 1, map_id)
	map_selector.item_selected.connect(_on_map_selected)
	top_bar.add_child(map_selector)

	# 디버그 레이블 토글
	debug_toggle = CheckButton.new()
	debug_toggle.text = "Show Terrain Codes"
	debug_toggle.toggled.connect(_on_debug_toggled)
	top_bar.add_child(debug_toggle)

	# 스폰 존 표시 버튼
	var spawn_btn = Button.new()
	spawn_btn.text = "Show Spawn Zones"
	spawn_btn.pressed.connect(_on_show_spawn_zones)
	top_bar.add_child(spawn_btn)

	# 하이라이트 클리어 버튼
	var clear_btn = Button.new()
	clear_btn.text = "Clear Highlights"
	clear_btn.pressed.connect(_on_clear_highlights)
	top_bar.add_child(clear_btn)

	# 타일 그리드 (화면 중앙)
	tile_grid = TileGridUI.new()
	tile_grid.position = Vector2(
		(get_viewport_rect().size.x - tile_grid.custom_minimum_size.x) / 2,
		80
	)
	tile_grid.tile_clicked.connect(_on_tile_clicked)
	tile_grid.tile_hovered.connect(_on_tile_hovered)
	add_child(tile_grid)

	# 정보 레이블 (하단)
	info_label = Label.new()
	info_label.position = Vector2(20, get_viewport_rect().size.y - 100)
	info_label.custom_minimum_size = Vector2(600, 80)
	info_label.add_theme_font_size_override("font_size", 14)
	add_child(info_label)

	_update_info("Click a tile to see terrain info")


func _load_first_map() -> void:
	if map_selector.item_count > 0:
		map_selector.select(0)
		_on_map_selected(0)


func _on_map_selected(index: int) -> void:
	var map_id = map_selector.get_item_metadata(index)
	if map_id == null:
		return

	current_map = DataManager.create_battle_map(map_id)
	if current_map == null:
		_update_info("Failed to load map: " + str(map_id))
		return

	tile_grid.setup(current_map)
	tile_grid.toggle_debug_labels() if debug_toggle.button_pressed else null

	var map_name = DataManager.get_localized(current_map.name_key)
	_update_info("Loaded map: " + map_name + " (" + str(current_map.width) + "x" + str(current_map.height) + ")")


func _on_debug_toggled(toggled: bool) -> void:
	tile_grid.toggle_debug_labels()


func _on_show_spawn_zones() -> void:
	tile_grid.clear_all_highlights()
	tile_grid.show_ally_spawn_zones()
	tile_grid.show_enemy_spawn_zones()


func _on_clear_highlights() -> void:
	tile_grid.clear_all_highlights()
	tile_grid.clear_selection()


func _on_tile_clicked(grid_pos: Vector2i) -> void:
	tile_grid.select_tile(grid_pos)

	if current_map == null:
		return

	var terrain = current_map.get_terrain_at(grid_pos)
	if terrain == null:
		_update_info("Invalid position: " + str(grid_pos))
		return

	# 클릭한 타일에서 이동 가능한 범위 표시
	tile_grid.clear_all_highlights()
	var reachable = current_map.get_reachable_tiles(grid_pos, 3, {})
	tile_grid.highlight_movement_tiles(reachable)

	var terrain_name = DataManager.get_localized(terrain.name_key)
	var terrain_desc = DataManager.get_localized(terrain.description_key)
	var info_text = "Position: %s\n" % str(grid_pos)
	info_text += "Terrain: %s (%s)\n" % [terrain_name, terrain.id]
	info_text += "Move Cost: %.1f | Def: %+d%% | Atk: %+d%% | ATB: %+.2f\n" % [
		terrain.movement_cost, terrain.defense_modifier, terrain.attack_modifier, terrain.atb_modifier
	]
	info_text += "Passable: %s | Reachable tiles (range 3): %d" % [
		"Yes" if terrain.passable else "No", reachable.size()
	]

	_update_info(info_text)


func _on_tile_hovered(grid_pos: Vector2i) -> void:
	# 호버 시 간단한 정보 표시
	pass


func _update_info(text: String) -> void:
	info_label.text = text
