# CorpsBattleUI - 군단 전투 UI
# Phase 5C: 향상된 ATB 시스템
#
# 그리드 기반 군단 전투 UI.
# TileGridUI, CommandPanel, MovementOverlay, CorpsDisplay 통합.

extends Control

const Corps = preload("res://src/core/corps.gd")
const CorpsCommand = preload("res://src/core/corps_command.gd")
const BattleMap = preload("res://src/core/battle_map.gd")
const TileGridUI = preload("res://src/ui/battle/tile_grid_ui.gd")
const CommandPanel = preload("res://src/ui/battle/command_panel.gd")
const MovementOverlay = preload("res://src/ui/battle/movement_overlay.gd")
const CorpsDisplay = preload("res://src/ui/battle/corps_display.gd")

## 전투 매니저
var battle_manager: BattleManager

## UI 컴포넌트
var tile_grid: TileGridUI
var command_panel: CommandPanel
var movement_overlay: MovementOverlay

## 군단 표시 관리
var corps_displays: Dictionary = {}  # Corps -> CorpsDisplay

## 현재 선택된 군단
var selected_corps: Corps = null

## 현재 명령 선택 상태
enum SelectionState { NONE, SELECTING_COMMAND, SELECTING_TARGET, SELECTING_MOVE }
var selection_state: SelectionState = SelectionState.NONE

## UI 레이아웃
var info_panel: PanelContainer
var info_label: Label
var state_label: Label

## 결과 레이블
var result_label: Label


func _ready() -> void:
	_create_ui()
	_setup_battle_manager()
	_start_test_battle()


func _create_ui() -> void:
	# 배경
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.1, 0.12, 0.15)
	bg.z_index = -1
	add_child(bg)

	# 타일 그리드 (중앙)
	tile_grid = TileGridUI.new()
	tile_grid.set_anchors_preset(Control.PRESET_CENTER)
	tile_grid.offset_left = -320
	tile_grid.offset_right = 320
	tile_grid.offset_top = -320
	tile_grid.offset_bottom = 320
	tile_grid.tile_clicked.connect(_on_tile_clicked)
	tile_grid.tile_hovered.connect(_on_tile_hovered)
	add_child(tile_grid)

	# 명령 패널 (왼쪽)
	command_panel = CommandPanel.new()
	command_panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	command_panel.offset_left = 20
	command_panel.offset_right = 220
	command_panel.offset_top = -150
	command_panel.offset_bottom = 150
	command_panel.command_selected.connect(_on_command_selected)
	command_panel.command_cancelled.connect(_on_command_cancelled)
	add_child(command_panel)

	# 이동 오버레이 컨트롤러
	movement_overlay = MovementOverlay.new()
	movement_overlay.connect_to_grid(tile_grid)
	movement_overlay.movement_selected.connect(_on_movement_selected)
	movement_overlay.movement_cancelled.connect(_on_movement_cancelled)

	# 정보 패널 (오른쪽)
	_create_info_panel()

	# 상태 레이블 (상단)
	state_label = Label.new()
	state_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	state_label.offset_top = 10
	state_label.offset_bottom = 40
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.add_theme_font_size_override("font_size", 18)
	state_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	add_child(state_label)

	# 결과 레이블 (중앙)
	result_label = Label.new()
	result_label.set_anchors_preset(Control.PRESET_CENTER)
	result_label.offset_left = -200
	result_label.offset_right = 200
	result_label.offset_top = -50
	result_label.offset_bottom = 50
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 48)
	result_label.add_theme_color_override("font_color", Color.GOLD)
	result_label.visible = false
	add_child(result_label)

	# 디버그 버튼
	_create_debug_buttons()


func _create_info_panel() -> void:
	info_panel = PanelContainer.new()
	info_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	info_panel.offset_left = -250
	info_panel.offset_right = -20
	info_panel.offset_top = -200
	info_panel.offset_bottom = 200

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	style.border_color = Color(0.3, 0.3, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	info_panel.add_theme_stylebox_override("panel", style)

	add_child(info_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	info_panel.add_child(vbox)

	var title = Label.new()
	title.text = DataManager.get_localized("UI_CORPS_INFO") if DataManager else "Corps Info"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	vbox.add_child(title)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	info_label = Label.new()
	info_label.text = "Select a corps to see details"
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info_label)


func _create_debug_buttons() -> void:
	var debug_container = VBoxContainer.new()
	debug_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	debug_container.offset_left = -150
	debug_container.offset_top = 50
	debug_container.offset_right = -10
	debug_container.offset_bottom = 150
	add_child(debug_container)

	var debug_label = Label.new()
	debug_label.text = "[DEBUG]"
	debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debug_label.add_theme_font_size_override("font_size", 12)
	debug_container.add_child(debug_label)

	var victory_btn = Button.new()
	victory_btn.text = "Force Victory"
	victory_btn.custom_minimum_size = Vector2(130, 30)
	victory_btn.pressed.connect(_on_force_victory)
	debug_container.add_child(victory_btn)

	var defeat_btn = Button.new()
	defeat_btn.text = "Force Defeat"
	defeat_btn.custom_minimum_size = Vector2(130, 30)
	defeat_btn.pressed.connect(_on_force_defeat)
	debug_container.add_child(defeat_btn)


func _setup_battle_manager() -> void:
	battle_manager = BattleManager.new()
	add_child(battle_manager)

	# 시그널 연결
	battle_manager.battle_started.connect(_on_battle_started)
	battle_manager.battle_ended.connect(_on_battle_ended)
	battle_manager.corps_action_ready.connect(_on_corps_action_ready)
	battle_manager.command_executed.connect(_on_command_executed)
	battle_manager.movement_phase_started.connect(_on_movement_phase_started)
	battle_manager.movement_phase_ended.connect(_on_movement_phase_ended)
	battle_manager.global_turn_ready.connect(_on_global_turn_ready)


func _start_test_battle() -> void:
	print("CorpsBattleUI: Starting test battle...")

	# 맵 로드
	var battle_map = DataManager.create_battle_map("stage_1_map")
	if battle_map == null:
		push_error("Failed to load battle map!")
		return

	battle_manager.set_battle_map(battle_map)
	tile_grid.setup(battle_map)
	movement_overlay.set_battle_map(battle_map)

	# 아군 군단 생성
	var gyeonhwon = DataManager.create_general_instance("gyeonhwon")
	var wanggeon = DataManager.create_general_instance("wanggeon")
	var singeom = DataManager.create_general_instance("singeom")

	var ally_spear = DataManager.create_corps_instance("spear_corps", true, gyeonhwon)
	var ally_archer = DataManager.create_corps_instance("archer_corps", true, wanggeon)
	var ally_cavalry = DataManager.create_corps_instance("light_cavalry_corps", true, singeom)

	# 아군 스폰 위치
	var ally_spawns = battle_map.ally_spawn_zones
	if ally_spawns.size() >= 3:
		battle_manager.add_corps(ally_spear, ally_spawns[0])
		battle_manager.add_corps(ally_archer, ally_spawns[1])
		battle_manager.add_corps(ally_cavalry, ally_spawns[2])

	# 적군 군단 생성
	var enemy1 = DataManager.create_corps_instance("sword_corps", false, null)
	var enemy2 = DataManager.create_corps_instance("archer_corps", false, null)
	var enemy3 = DataManager.create_corps_instance("heavy_cavalry_corps", false, null)

	# 적군 스폰 위치
	var enemy_spawns = battle_map.enemy_spawn_zones
	if enemy_spawns.size() >= 3:
		battle_manager.add_corps(enemy1, enemy_spawns[0])
		battle_manager.add_corps(enemy2, enemy_spawns[1])
		battle_manager.add_corps(enemy3, enemy_spawns[2])

	# 전투 시작
	battle_manager.state = BattleManager.BattleState.RUNNING
	battle_manager.battle_started.emit()


func _on_battle_started() -> void:
	print("CorpsBattleUI: Battle started!")
	_update_state_label()

	# 군단 표시 생성
	for corps in battle_manager.ally_corps + battle_manager.enemy_corps:
		_create_corps_display(corps)

	# 스폰 존 하이라이트 (잠시 후 해제)
	tile_grid.show_ally_spawn_zones()
	tile_grid.show_enemy_spawn_zones()
	await get_tree().create_timer(1.5).timeout
	if is_inside_tree():
		tile_grid.clear_all_highlights()


func _create_corps_display(corps: Corps) -> void:
	var display = CorpsDisplay.new()
	display.setup(corps)
	display.corps_clicked.connect(_on_corps_clicked)

	# 그리드 위치에 표시 배치
	var grid_pos = corps.grid_position
	var tile_display = tile_grid.get_tile_display(grid_pos)
	if tile_display:
		display.position = Vector2.ZERO
		tile_display.add_child(display)

	corps_displays[corps] = display

	# 위치 변경 시그널 연결
	corps.position_changed.connect(_on_corps_position_changed.bind(corps))


func _on_corps_position_changed(old_pos: Vector2i, new_pos: Vector2i, corps: Corps) -> void:
	var display = corps_displays.get(corps)
	if display == null:
		return

	# 이전 타일에서 제거
	var old_tile = tile_grid.get_tile_display(old_pos)
	if old_tile and display.get_parent() == old_tile:
		old_tile.remove_child(display)

	# 새 타일에 추가
	var new_tile = tile_grid.get_tile_display(new_pos)
	if new_tile:
		display.position = Vector2.ZERO
		new_tile.add_child(display)


func _on_corps_clicked(corps: Corps) -> void:
	print("CorpsBattleUI: Corps clicked: %s" % corps.get_display_name())

	# 적군 클릭 시 공격 대상 선택
	if selection_state == SelectionState.SELECTING_TARGET:
		if not corps.is_ally:
			_execute_attack_on_target(corps)
		else:
			# 아군 클릭 시 공격 선택 취소하고 새로운 군단 선택
			tile_grid.clear_all_highlights()
			selection_state = SelectionState.NONE
			_select_corps(corps)
		return

	# 아군 클릭 시 선택
	if corps.is_ally:
		_select_corps(corps)


func _select_corps(corps: Corps) -> void:
	# 이전 선택 해제
	if selected_corps != null and selected_corps in corps_displays:
		corps_displays[selected_corps].set_selected(false)

	selected_corps = corps

	if corps != null and corps in corps_displays:
		corps_displays[corps].set_selected(true)
		_update_info_panel(corps)

		# ATB가 차 있으면 명령 패널 표시
		if corps.atb_current >= corps.atb_max:
			command_panel.show_for_corps(corps)
			selection_state = SelectionState.SELECTING_COMMAND
		else:
			command_panel.hide_panel()
			selection_state = SelectionState.NONE


func _on_tile_clicked(grid_pos: Vector2i) -> void:
	print("CorpsBattleUI: Tile clicked at %s, selection_state=%d" % [grid_pos, selection_state])

	# 이동 선택 중이면 MovementOverlay에서 처리
	if selection_state == SelectionState.SELECTING_MOVE:
		print("CorpsBattleUI: In SELECTING_MOVE state, letting MovementOverlay handle it")
		return

	# 타일에 군단이 있으면 군단 선택
	var corps = battle_manager.get_corps_at_position(grid_pos)
	if corps != null:
		_on_corps_clicked(corps)
	else:
		# 빈 타일 클릭 - 선택 해제
		_deselect_corps()


func _on_tile_hovered(grid_pos: Vector2i) -> void:
	# 호버 정보 업데이트
	var terrain = tile_grid.battle_map.get_terrain_at(grid_pos) if tile_grid.battle_map else null
	if terrain:
		# 지형 정보 툴팁 표시 가능
		pass


func _deselect_corps() -> void:
	if selected_corps != null and selected_corps in corps_displays:
		corps_displays[selected_corps].set_selected(false)
	selected_corps = null
	command_panel.hide_panel()
	selection_state = SelectionState.NONE
	tile_grid.clear_all_highlights()
	info_label.text = "Select a corps to see details"


func _on_command_selected(command_type: CorpsCommand.CommandType) -> void:
	if selected_corps == null:
		return

	print("CorpsBattleUI: Command selected: %d for %s" % [command_type, selected_corps.get_display_name()])

	match command_type:
		CorpsCommand.CommandType.ATTACK:
			# 공격 대상 선택 모드
			selection_state = SelectionState.SELECTING_TARGET
			_highlight_attack_targets()
			command_panel.hide_panel()

		CorpsCommand.CommandType.MOVE:
			# 이동 위치 선택 모드
			print("CorpsBattleUI: Starting MOVE selection for %s" % selected_corps.get_display_name())
			selection_state = SelectionState.SELECTING_MOVE
			# 군단 표시의 마우스 입력 비활성화 (타일 클릭을 위해)
			_set_all_corps_displays_mouse_input(false)
			movement_overlay.set_occupied_positions(battle_manager.get_all_occupied_positions())
			movement_overlay.start_selection(selected_corps)
			movement_overlay.debug_print_reachable_tiles()
			command_panel.hide_panel()

		CorpsCommand.CommandType.DEFEND, CorpsCommand.CommandType.EVADE, CorpsCommand.CommandType.WATCH:
			# 즉시 실행 명령
			var command = CorpsCommand.new(command_type, selected_corps)
			battle_manager.set_corps_command(selected_corps, command)
			battle_manager.process_immediate_command(selected_corps)
			_deselect_corps()


func _highlight_attack_targets() -> void:
	if selected_corps == null:
		return

	# 사거리 내 대상만 하이라이트
	var attackable = battle_manager.get_attackable_targets(selected_corps)
	var enemy_positions: Array = []
	for corps in attackable:
		enemy_positions.append(corps.grid_position)

	if enemy_positions.is_empty():
		# 사거리 내 대상 없음 - 경고 메시지
		print("CorpsBattleUI: No targets in range (range: %d)" % selected_corps.get_attack_range())
		state_label.text = DataManager.get_localized("UI_NO_TARGETS_IN_RANGE") if DataManager else "No targets in range!"

	tile_grid.highlight_attack_tiles(enemy_positions)


func _execute_attack_on_target(target: Corps) -> void:
	if selected_corps == null:
		return

	# 사거리 확인
	if not selected_corps.is_target_in_range(target):
		print("CorpsBattleUI: Target out of range (dist: %d, range: %d)" % [
			selected_corps.distance_to(target), selected_corps.get_attack_range()
		])
		state_label.text = DataManager.get_localized("UI_TARGET_OUT_OF_RANGE") if DataManager else "Target out of range!"
		return

	var command = CorpsCommand.new(CorpsCommand.CommandType.ATTACK, selected_corps)
	command.set_as_attack(target)
	battle_manager.set_corps_command(selected_corps, command)
	battle_manager.process_immediate_command(selected_corps)

	tile_grid.clear_all_highlights()
	_deselect_corps()


func _on_command_cancelled() -> void:
	_deselect_corps()


func _on_movement_selected(destination: Vector2i) -> void:
	if selected_corps == null:
		return

	var command = CorpsCommand.new(CorpsCommand.CommandType.MOVE, selected_corps)
	command.set_as_move(destination)
	battle_manager.set_corps_command(selected_corps, command)

	# 명령 표시기 업데이트
	if selected_corps in corps_displays:
		corps_displays[selected_corps].show_command_indicator(CorpsCommand.CommandType.MOVE)

	# 군단 표시의 마우스 입력 재활성화
	_set_all_corps_displays_mouse_input(true)
	_deselect_corps()


func _on_movement_cancelled() -> void:
	# 군단 표시의 마우스 입력 재활성화
	_set_all_corps_displays_mouse_input(true)
	selection_state = SelectionState.NONE
	if selected_corps != null:
		command_panel.show_for_corps(selected_corps)
		selection_state = SelectionState.SELECTING_COMMAND


func _on_corps_action_ready(corps: Corps) -> void:
	print("CorpsBattleUI: Corps action ready: %s" % corps.get_display_name())

	# 아군이면 자동 선택
	if corps.is_ally:
		_select_corps(corps)


func _on_command_executed(command: CorpsCommand) -> void:
	# 명령 표시기 숨기기
	var corps = command.source_corps
	if corps in corps_displays:
		corps_displays[corps].hide_command_indicator()


func _on_movement_phase_started() -> void:
	print("CorpsBattleUI: Movement phase started")
	_update_state_label()


func _on_movement_phase_ended() -> void:
	print("CorpsBattleUI: Movement phase ended")
	_update_state_label()


func _on_global_turn_ready() -> void:
	print("CorpsBattleUI: Global turn ready")
	_update_state_label()


func _on_battle_ended(victory: bool) -> void:
	var text = DataManager.get_localized("UI_RUN_VICTORY") if victory else DataManager.get_localized("UI_RUN_DEFEAT")
	result_label.text = text
	result_label.visible = true
	print("CorpsBattleUI: Battle ended - %s" % text)


func _update_info_panel(corps: Corps) -> void:
	if corps == null:
		info_label.text = "Select a corps to see details"
		return

	var lines: Array = []
	lines.append("[%s]" % corps.get_display_name())
	if corps.general:
		lines.append("General: %s" % corps.general.display_name)
	lines.append("")
	lines.append("Soldiers: %d/%d" % [corps.soldier_count, corps.max_soldier_count])
	lines.append("HP: %d/%d (%.0f%%)" % [corps.current_hp, corps.max_hp, corps.get_hp_percent()])
	lines.append("ATB: %.0f%%" % corps.get_atb_percent())
	lines.append("")
	lines.append("ATK: %d" % corps.get_effective_attack())
	lines.append("DEF: %d" % corps.get_effective_defense())
	lines.append("ATB Speed: %.2f" % corps.get_effective_atb_speed())
	lines.append("Move Range: %d" % corps.get_movement_range())
	lines.append("Attack Range: %d" % corps.get_attack_range())

	if corps.current_formation:
		lines.append("")
		lines.append("Formation: %s" % corps.current_formation.get_display_name())

	info_label.text = "\n".join(lines)


func _update_state_label() -> void:
	if battle_manager == null:
		return

	var state_text = ""
	match battle_manager.state:
		BattleManager.BattleState.RUNNING:
			state_text = DataManager.get_localized("BATTLE_STATE_RUNNING")
		BattleManager.BattleState.PAUSED_FOR_CARD:
			state_text = DataManager.get_localized("BATTLE_STATE_PAUSED")
		BattleManager.BattleState.MOVEMENT_PHASE:
			state_text = DataManager.get_localized("BATTLE_STATE_MOVEMENT")
		BattleManager.BattleState.WAVE_TRANSITION:
			state_text = DataManager.get_localized("BATTLE_STATE_WAVE_TRANSITION")

	state_label.text = state_text


func _process(delta: float) -> void:
	# Corps ATB 업데이트
	if battle_manager and battle_manager.state == BattleManager.BattleState.RUNNING:
		battle_manager._update_corps_atb(delta)

	_update_state_label()


func _on_force_victory() -> void:
	for corps in battle_manager.enemy_corps.duplicate():
		corps.current_hp = 0
		corps.is_alive = false
		corps.destroyed.emit()
	battle_manager._check_corps_battle_end()


func _on_force_defeat() -> void:
	for corps in battle_manager.ally_corps.duplicate():
		corps.current_hp = 0
		corps.is_alive = false
		corps.destroyed.emit()
	battle_manager._check_corps_battle_end()


## 모든 군단 표시의 마우스 입력 활성화/비활성화
func _set_all_corps_displays_mouse_input(enabled: bool) -> void:
	for display in corps_displays.values():
		display.set_mouse_input_enabled(enabled)
