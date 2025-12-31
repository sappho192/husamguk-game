# CorpsBattleUI - 군단 전투 UI
# Phase 5C: 향상된 ATB 시스템
#
# 그리드 기반 군단 전투 UI.
# TileGridUI, CommandPanel, MovementOverlay, CorpsDisplay 통합.
# Phase 5D: SkillBar, CardHand 통합

extends Control

const Corps = preload("res://src/core/corps.gd")
const CorpsCommand = preload("res://src/core/corps_command.gd")
const Formation = preload("res://src/core/formation.gd")
const BattleMap = preload("res://src/core/battle_map.gd")
const TileGridUI = preload("res://src/ui/battle/tile_grid_ui.gd")
const CommandPanel = preload("res://src/ui/battle/command_panel.gd")
const MovementOverlay = preload("res://src/ui/battle/movement_overlay.gd")
const CorpsDisplay = preload("res://src/ui/battle/corps_display.gd")
const FormationSelectDialog = preload("res://src/ui/battle/formation_select_dialog.gd")
const SkillBar = preload("res://src/ui/battle/skill_bar.gd")
const CardHand = preload("res://src/ui/battle/card_hand.gd")
const Card = preload("res://src/core/card.gd")

## 전투 매니저
var battle_manager: BattleManager

## UI 컴포넌트
var tile_grid: TileGridUI
var command_panel: CommandPanel
var movement_overlay: MovementOverlay
var formation_dialog: FormationSelectDialog  # Phase 5C: 진형 선택 다이얼로그
var skill_bar: SkillBar  # Phase 5D: 장수 스킬바
var card_hand: CardHand  # Phase 5D: 카드 덱
var card_toggle_button: Button  # Phase 5D: 카드 선택 UI 토글 버튼
var global_turn_bar: ProgressBar  # Phase 5D: 글로벌 턴 타이머

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
var resume_battle_button: Button
var wave_counter_label: Label
var wave_transition_label: Label

## 결과 레이블
var result_label: Label

## BGM (injected from scene)
@onready var battle_bgm: AudioStreamPlayer = get_node_or_null("BattleBGM")

## Phase 5D: Card deck management
var deck: Array[Card] = []
var discard_pile: Array[Card] = []
var global_turn_count: int = 0  # Track global turns for first-turn skip
var card_selected_this_turn: bool = false  # Track if card was selected this turn


func _ready() -> void:
	# Setup BGM looping (if available)
	if battle_bgm and battle_bgm.stream:
		battle_bgm.stream.loop = true

	_create_ui()

	# Localization
	if DataManager:
		resume_battle_button.text = DataManager.get_localized("UI_RESUME_BATTLE")

	_setup_battle_manager()
	_initialize_deck()  # Phase 5D: 덱 초기화
	_start_battle()


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

	# 진형 선택 다이얼로그 (Phase 5C)
	formation_dialog = FormationSelectDialog.new()
	formation_dialog.formation_selected.connect(_on_formation_selected)
	formation_dialog.cancelled.connect(_on_formation_dialog_cancelled)
	add_child(formation_dialog)

	# 이동 오버레이 컨트롤러
	movement_overlay = MovementOverlay.new()
	movement_overlay.connect_to_grid(tile_grid)
	movement_overlay.movement_selected.connect(_on_movement_selected)
	movement_overlay.movement_cancelled.connect(_on_movement_cancelled)

	# 정보 패널 (오른쪽)
	_create_info_panel()

	# Wave counter label (top center, above state label)
	wave_counter_label = Label.new()
	wave_counter_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	wave_counter_label.offset_top = 10
	wave_counter_label.offset_bottom = 40
	wave_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_counter_label.add_theme_font_size_override("font_size", 24)
	wave_counter_label.visible = false
	add_child(wave_counter_label)

	# Wave transition label (center screen)
	wave_transition_label = Label.new()
	wave_transition_label.set_anchors_preset(Control.PRESET_CENTER)
	wave_transition_label.offset_left = -300
	wave_transition_label.offset_right = 300
	wave_transition_label.offset_top = -50
	wave_transition_label.offset_bottom = 50
	wave_transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_transition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wave_transition_label.add_theme_font_size_override("font_size", 36)
	wave_transition_label.visible = false
	add_child(wave_transition_label)

	# 상태 레이블 (상단 - below wave counter)
	state_label = Label.new()
	state_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	state_label.offset_top = 45
	state_label.offset_bottom = 75
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

	# 전투 개시 버튼 (Phase 5C)
	_create_resume_battle_button()

	# Phase 5D: 글로벌 턴 타이머
	_create_global_turn_timer()

	# Phase 5D: 스킬바와 카드 핸드
	_create_skill_and_card_ui()


func _create_resume_battle_button() -> void:
	resume_battle_button = Button.new()
	resume_battle_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	resume_battle_button.offset_left = -100
	resume_battle_button.offset_right = 100
	resume_battle_button.offset_top = -80
	resume_battle_button.offset_bottom = -30
	resume_battle_button.custom_minimum_size = Vector2(200, 50)
	resume_battle_button.add_theme_font_size_override("font_size", 20)
	resume_battle_button.text = "전투 개시"  # Will be localized in _ready()
	resume_battle_button.pressed.connect(_on_resume_battle_pressed)
	resume_battle_button.visible = false  # 초기에는 숨김

	# 버튼 스타일
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.7, 0.3, 0.9)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	resume_battle_button.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = Color(0.4, 0.8, 0.4, 0.9)
	resume_battle_button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = style.duplicate()
	pressed_style.bg_color = Color(0.2, 0.6, 0.2, 0.9)
	resume_battle_button.add_theme_stylebox_override("pressed", pressed_style)

	add_child(resume_battle_button)


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


func _create_global_turn_timer() -> void:
	# Timer container - positioned above card hand
	var timer_container = VBoxContainer.new()
	timer_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	timer_container.offset_left = 340
	timer_container.offset_right = -340
	timer_container.offset_top = -280
	timer_container.offset_bottom = -230
	add_child(timer_container)

	# Timer label
	var timer_label = Label.new()
	timer_label.text = DataManager.get_localized("UI_GLOBAL_TURN") if DataManager else "Global Turn"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 16)
	timer_container.add_child(timer_label)

	# Global turn timer bar
	global_turn_bar = ProgressBar.new()
	global_turn_bar.custom_minimum_size = Vector2(400, 24)
	global_turn_bar.max_value = BattleManager.GLOBAL_TURN_INTERVAL
	global_turn_bar.value = 0
	global_turn_bar.show_percentage = false
	timer_container.add_child(global_turn_bar)

func _create_skill_and_card_ui() -> void:
	# Skill bar on left side
	skill_bar = SkillBar.new()
	skill_bar.skill_activated.connect(_on_skill_activated)
	add_child(skill_bar)

	# Card hand - full screen overlay (positioning handled in CardHand._init())
	card_hand = CardHand.new()
	card_hand.z_index = 100  # Ensure card hand is on top of all other UI elements
	card_hand.card_selected.connect(_on_card_selected)
	add_child(card_hand)

	# Card toggle button - always visible when card selection is active
	card_toggle_button = Button.new()
	card_toggle_button.text = "맵 확인"
	card_toggle_button.custom_minimum_size = Vector2(300, 50)
	card_toggle_button.add_theme_font_size_override("font_size", 18)
	card_toggle_button.z_index = 101  # Above card hand
	card_toggle_button.pressed.connect(_on_card_hand_toggle)

	# Position at bottom center
	card_toggle_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	card_toggle_button.offset_left = -150  # Half of width (300 / 2)
	card_toggle_button.offset_right = 150
	card_toggle_button.offset_top = -130  # Above bottom edge
	card_toggle_button.offset_bottom = -80

	card_toggle_button.visible = false  # Hidden initially
	add_child(card_toggle_button)

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
	battle_manager.wave_started.connect(_on_wave_started)
	battle_manager.wave_complete.connect(_on_wave_complete)


func _start_battle() -> void:
	if GameManager.current_run and GameManager.next_battle_config.has("battle_id"):
		var battle_id = GameManager.next_battle_config["battle_id"]
		var map_id = GameManager.next_battle_config.get("map_id", "stage_1_map")
		var ally_corps_data = GameManager.next_battle_config.get("ally_corps", [])

		print("CorpsBattleUI: Starting run-based wave battle: ", battle_id)
		_start_wave_battle(battle_id, map_id, ally_corps_data)
	else:
		print("CorpsBattleUI: Starting standalone test wave battle")
		_start_standalone_wave_battle()

func _start_wave_battle(battle_id: String, map_id: String, ally_corps_data: Array) -> void:
	var battle_map = DataManager.create_battle_map(map_id)
	if battle_map == null:
		push_error("CorpsBattleUI: Failed to load battle map: " + map_id)
		return

	tile_grid.setup(battle_map)
	movement_overlay.set_battle_map(battle_map)

	battle_manager.start_corps_battle_from_data(battle_id, ally_corps_data, battle_map)

func _start_standalone_wave_battle() -> void:
	var battle_map = DataManager.create_battle_map("stage_1_map")
	if battle_map == null:
		push_error("CorpsBattleUI: Failed to load battle map!")
		return

	tile_grid.setup(battle_map)
	movement_overlay.set_battle_map(battle_map)

	var gyeonhwon = DataManager.create_general_instance("gyeonhwon")
	var wanggeon = DataManager.create_general_instance("wanggeon")
	var singeom = DataManager.create_general_instance("singeom")

	var ally_corps_data = [
		{"template_id": "spear_corps", "general": gyeonhwon},
		{"template_id": "archer_corps", "general": wanggeon},
		{"template_id": "light_cavalry_corps", "general": singeom}
	]

	battle_manager.start_corps_battle_from_data("stage_1_corps_battle", ally_corps_data, battle_map)


func _on_battle_started() -> void:
	print("CorpsBattleUI: Battle started in PREPARING mode!")
	_update_state_label()

	# Create displays for ally corps only (enemies will be created in _on_wave_started)
	for corps in battle_manager.ally_corps:
		_create_corps_display(corps)

	if GameManager.current_run:
		GameManager.on_battle_ready(battle_manager, battle_manager.ally_corps)

	var ally_corps_with_generals: Array = []
	for corps in battle_manager.ally_corps:
		if corps.general:
			ally_corps_with_generals.append(corps)

	skill_bar.setup(ally_corps_with_generals)

	tile_grid.show_ally_spawn_zones()
	tile_grid.show_enemy_spawn_zones()
	await get_tree().create_timer(1.5).timeout
	if is_inside_tree():
		tile_grid.clear_all_highlights()

		if battle_manager.state == BattleManager.BattleState.PREPARING:
			resume_battle_button.visible = true


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

	# 시그널 연결
	corps.position_changed.connect(_on_corps_position_changed.bind(corps))
	corps.destroyed.connect(_on_corps_destroyed_ui.bind(corps))


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


func _on_corps_destroyed_ui(corps: Corps) -> void:
	print("CorpsBattleUI: Corps destroyed UI cleanup: %s" % corps.get_display_name())

	# 현재 선택된 군단이면 선택 해제
	if selected_corps == corps:
		_deselect_corps()

	# Display 제거
	var display = corps_displays.get(corps)
	if display:
		display.queue_free()
		corps_displays.erase(corps)


func _on_corps_clicked(corps: Corps) -> void:
	print("CorpsBattleUI: Corps clicked: %s" % corps.get_display_name())

	if selection_state == SelectionState.SELECTING_TARGET:
		if not corps.is_ally:
			_execute_attack_on_target(corps)
		else:
			tile_grid.clear_all_highlights()
			selection_state = SelectionState.NONE
			_select_corps(corps)
		return

	if corps.is_ally:
		_select_corps(corps)
	else:
		if selected_corps != null and battle_manager.state == BattleManager.BattleState.PREPARING:
			_execute_attack_on_target(corps)
			command_panel.hide_panel()


func _select_corps(corps: Corps) -> void:
	# 파괴된 군단은 선택 불가
	if corps == null or not corps.is_alive:
		return

	# 이전 선택 해제
	if selected_corps != null and selected_corps in corps_displays:
		var prev_display = corps_displays[selected_corps]
		if prev_display and is_instance_valid(prev_display):
			prev_display.set_selected(false)

	selected_corps = corps

	if corps != null and corps in corps_displays:
		var display = corps_displays[corps]
		if display and is_instance_valid(display):
			display.set_selected(true)
		_update_info_panel(corps)

		# Phase 5C: PREPARING 상태일 때만 명령 패널 표시 (ATB 무관)
		if battle_manager.state == BattleManager.BattleState.PREPARING:
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
		var display = corps_displays[selected_corps]
		if display and is_instance_valid(display):
			display.set_selected(false)
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
			# Phase 5C: 공격 대상 선택 모드 (대상을 향해 이동 및 공격)
			selection_state = SelectionState.SELECTING_TARGET
			_highlight_all_enemies()
			command_panel.hide_panel()

		CorpsCommand.CommandType.DEFEND, CorpsCommand.CommandType.WATCH:
			# Phase 5C: 즉시 명령 설정 (현재 위치 사수)
			var command = CorpsCommand.new(command_type, selected_corps)
			battle_manager.set_corps_command(selected_corps, command)

			# 명령 표시기 업데이트
			if selected_corps in corps_displays:
				var display = corps_displays[selected_corps]
				if display and is_instance_valid(display):
					display.show_command_indicator(command_type)

			_deselect_corps()

		CorpsCommand.CommandType.CHANGE_FORMATION:
			# Phase 5C: 진형 선택 다이얼로그 표시
			formation_dialog.show_for_corps(selected_corps)
			command_panel.hide_panel()


## Phase 5C: 모든 적군을 하이라이트 (사거리 무관)
func _highlight_all_enemies() -> void:
	var enemy_positions: Array = []
	for corps in battle_manager.enemy_corps:
		if corps.is_alive:
			enemy_positions.append(corps.grid_position)

	if enemy_positions.is_empty():
		print("CorpsBattleUI: No enemies available")
		state_label.text = "No enemies!"
		return

	tile_grid.highlight_attack_tiles(enemy_positions)


## Legacy: 사거리 내 대상만 하이라이트 (사용 안 함)
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

	# Phase 5C: 사거리 무관하게 공격 명령 설정 (자동으로 이동 후 공격)
	var command = CorpsCommand.new(CorpsCommand.CommandType.ATTACK, selected_corps)
	command.set_as_attack(target)
	battle_manager.set_corps_command(selected_corps, command)

	# 명령 표시기 업데이트
	if selected_corps in corps_displays:
		var display = corps_displays[selected_corps]
		if display and is_instance_valid(display):
			display.show_command_indicator(CorpsCommand.CommandType.ATTACK)

	print("CorpsBattleUI: Set ATTACK command for %s -> %s" % [
		selected_corps.get_display_name(), target.get_display_name()
	])

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
		var display = corps_displays[selected_corps]
		if display and is_instance_valid(display):
			display.show_command_indicator(CorpsCommand.CommandType.MOVE)

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

	# Phase 5C: PREPARING 모드에서만 자동 선택 (RUNNING 중에는 명령에 따라 자동 행동)
	# RUNNING 모드에서는 더 이상 ATB 차면 명령 패널을 열지 않음
	pass


func _on_command_executed(command: CorpsCommand) -> void:
	# 명령 표시기 숨기기
	var corps = command.source_corps
	if corps in corps_displays:
		var display = corps_displays[corps]
		if display and is_instance_valid(display):
			display.hide_command_indicator()


func _on_movement_phase_started() -> void:
	print("CorpsBattleUI: Movement phase started")
	_update_state_label()


func _on_movement_phase_ended() -> void:
	print("CorpsBattleUI: Movement phase ended")
	_update_state_label()


func _on_global_turn_ready() -> void:
	global_turn_count += 1
	card_selected_this_turn = false  # Reset card selection flag
	print("CorpsBattleUI: Global turn ready - turn %d - entering PREPARING mode" % global_turn_count)
	_update_state_label()

	# Phase 5D: Show card selection UI starting from FIRST global turn
	# (전투 시작 시의 준비 단계에서는 숨김, 첫 글로벌 턴부터 표시)
	if global_turn_count >= 1 and card_hand:
		print("CorpsBattleUI: Showing card selection UI (turn %d)" % global_turn_count)
		card_hand.visible = true
		card_hand.set_interactive(true)
		card_toggle_button.visible = true
		card_toggle_button.text = "맵 확인"
	else:
		print("CorpsBattleUI: Card hand not shown - count: %d, card_hand: %s" % [global_turn_count, card_hand != null])

	# Phase 5C: PREPARING 모드에서 전투 개시 버튼 표시
	if battle_manager.state == BattleManager.BattleState.PREPARING:
		resume_battle_button.visible = true
		# 첫 PREPARING(전투 시작)에서는 항상 활성화, 글로벌 턴에서는 카드 선택 후에만 활성화
		if global_turn_count == 0:
			resume_battle_button.disabled = false
		else:
			resume_battle_button.disabled = !card_selected_this_turn  # Disable if card not selected


func _on_battle_ended(victory: bool) -> void:
	# Phase 5: Redirect to GameManager if run is active
	if GameManager.current_run:
		# Pass ally corps for state saving
		GameManager.on_battle_ended(victory, battle_manager.ally_corps)
	else:
		# Standalone battle (no run active) - show result
		var text = DataManager.get_localized("UI_BATTLE_VICTORY" if victory else "UI_BATTLE_DEFEAT")
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
		BattleManager.BattleState.PREPARING:
			state_text = DataManager.get_localized("BATTLE_STATE_PREPARING")
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

	# Phase 5D: Update global turn timer bar
	if battle_manager and global_turn_bar:
		global_turn_bar.value = battle_manager.global_turn_timer

	# Phase 5D: Update skill bar buttons
	if skill_bar:
		skill_bar.update_all_buttons()


func _on_force_victory() -> void:
	for corps in battle_manager.enemy_corps.duplicate():
		corps.current_hp = 0
		corps.is_alive = false
		corps.destroyed.emit()


func _on_force_defeat() -> void:
	for corps in battle_manager.ally_corps.duplicate():
		corps.current_hp = 0
		corps.is_alive = false
		corps.destroyed.emit()


## 전투 개시 버튼 클릭 (Phase 5C)
func _on_resume_battle_pressed() -> void:
	print("CorpsBattleUI: Resume battle button pressed")

	# If in global turn (card selection mode), call on_card_used() to transition state
	if global_turn_count > 0:
		battle_manager.on_card_used()
	else:
		# First PREPARING (battle start), just resume
		battle_manager.resume_battle()

	resume_battle_button.visible = false
	_deselect_corps()


## 진형 선택 다이얼로그 - 진형 선택됨 (Phase 5C)
func _on_formation_selected(formation: Formation) -> void:
	if selected_corps == null:
		return

	# 현재 진형과 같은 진형을 선택한 경우 무시
	if selected_corps.current_formation and formation.id == selected_corps.current_formation.id:
		print("CorpsBattleUI: Same formation selected, ignoring")
		return

	print("CorpsBattleUI: Formation selected: %s for %s" % [
		formation.get_display_name(), selected_corps.get_display_name()
	])

	# PREPARING 모드에서는 즉시 진형 변경 적용
	if battle_manager.state == BattleManager.BattleState.PREPARING:
		selected_corps.set_formation(formation.id)
		print("CorpsBattleUI: Formation changed immediately (PREPARING mode)")

		# 명령 패널을 다시 열어서 추가 명령을 내릴 수 있게 함
		command_panel.show_for_corps(selected_corps)
	else:
		# 일반 모드에서는 명령 큐에 추가
		var command = CorpsCommand.new(CorpsCommand.CommandType.CHANGE_FORMATION, selected_corps)
		command.target_formation = formation
		battle_manager.set_corps_command(selected_corps, command)

		# 명령 표시기 업데이트
		if selected_corps in corps_displays:
			var display = corps_displays[selected_corps]
			if display and is_instance_valid(display):
				display.show_command_indicator(CorpsCommand.CommandType.CHANGE_FORMATION)

		_deselect_corps()


## 진형 선택 다이얼로그 - 취소됨 (Phase 5C)
func _on_formation_dialog_cancelled() -> void:
	# 명령 패널 다시 표시
	if selected_corps != null:
		command_panel.show_for_corps(selected_corps)


## 모든 군단 표시의 마우스 입력 활성화/비활성화
func _set_all_corps_displays_mouse_input(enabled: bool) -> void:
	for display in corps_displays.values():
		display.set_mouse_input_enabled(enabled)

# ====================================
# Phase 5D: Deck & Card System
# ====================================

func _initialize_deck() -> void:
	# Phase 5D: Get deck from GameManager if run is active
	var deck_composition: Array[String] = []

	if GameManager.current_run:
		deck_composition = GameManager.get_current_deck()
		print("Deck loaded from run state: ", deck_composition.size(), " cards")
	else:
		# Standalone battle - use default starter deck
		deck_composition = [
			"card_aggressive_charge",
			"card_aggressive_charge",
			"card_aggressive_charge",
			"card_iron_defense",
			"card_iron_defense",
			"card_field_medic",
			"card_field_medic",
			"card_intimidate",
			"card_intimidate",
			"card_sabotage"
		]

	for card_id in deck_composition:
		var card = DataManager.create_card_instance(card_id)
		if card:
			deck.append(card)

	# Shuffle deck
	deck.shuffle()
	print("Deck initialized with ", deck.size(), " cards")

	# Draw initial hand (3 cards)
	for i in range(3):
		_draw_card()

	# Cards start disabled - only enabled on global turn
	card_hand.set_interactive(false)

func _draw_card() -> void:
	if deck.is_empty():
		print("Deck is empty! Shuffling discard pile...")
		# Reshuffle discard pile back into deck
		deck = discard_pile.duplicate()
		discard_pile.clear()
		deck.shuffle()

	if deck.is_empty():
		print("No cards available to draw!")
		return

	var card = deck.pop_front()
	card_hand.add_card(card)
	print("Drew card: ", card.display_name)

# ====================================
# Phase 5D: Event Handlers
# ====================================

func _on_skill_activated(unit_or_corps) -> void:
	# SkillBar는 Unit을 기대하지만, Corps를 전달받음
	# Corps에 general이 있으면 스킬 실행
	if unit_or_corps is Corps:
		var corps = unit_or_corps as Corps
		if corps.general:
			print("CorpsBattleUI: Skill activated for ", corps.general.display_name, " (", corps.get_display_name(), ")")
			battle_manager.execute_corps_skill(corps)
	else:
		# Unit (legacy)
		print("CorpsBattleUI: Skill activated (Unit-based, not supported in Corps mode)")

func _on_card_selected(card: Card) -> void:
	print("CorpsBattleUI: Card selected: ", card.display_name)

	# Execute card effect on Corps
	card.execute_effect_corps(battle_manager.ally_corps, battle_manager.enemy_corps)

	# Remove from hand and add to discard
	card_hand.remove_card(card)
	discard_pile.append(card)

	# Draw new card
	_draw_card()

	# Mark card as selected
	card_selected_this_turn = true

	# Enable resume button
	if resume_battle_button:
		resume_battle_button.disabled = false

	# Disable card interaction and hide card selection UI
	card_hand.set_interactive(false)
	card_hand.visible = false
	card_toggle_button.visible = false

	# Don't auto-resume - let user click resume button
	print("CorpsBattleUI: Card effect applied. Click '전투 개시' to resume battle.")


func _on_card_hand_toggle() -> void:
	card_hand.visible = !card_hand.visible

	if card_hand.visible:
		card_toggle_button.text = "맵 확인"
	else:
		card_toggle_button.text = "카드 선택"

	print("CorpsBattleUI: Card hand toggled - visible: ", card_hand.visible)

# ====================================
# Wave System Handlers
# ====================================

func _on_wave_started(wave_number: int, total_waves: int) -> void:
	print("CorpsBattleUI: Wave ", wave_number, " / ", total_waves, " started")

	wave_counter_label.text = "Wave %d / %d" % [wave_number, total_waves]
	wave_counter_label.visible = true

	for corps in battle_manager.enemy_corps.duplicate():
		if corps in corps_displays:
			var display = corps_displays[corps]
			if display:
				display.queue_free()
			corps_displays.erase(corps)

	for corps in battle_manager.enemy_corps:
		_create_corps_display(corps)

	if wave_number > 1:
		wave_transition_label.text = "Wave %d" % wave_number
		wave_transition_label.visible = true
		
		if not is_inside_tree():
			return
			
		await get_tree().create_timer(1.5).timeout
		
		if not is_inside_tree():
			return
			
		wave_transition_label.visible = false

		if battle_manager.state == BattleManager.BattleState.PREPARING:
			resume_battle_button.visible = true

func _on_wave_complete(wave_number: int, has_next_wave: bool) -> void:
	print("CorpsBattleUI: Wave ", wave_number, " complete. Next wave: ", has_next_wave)

	if has_next_wave and is_inside_tree():
		wave_transition_label.text = "Wave %d Complete!" % wave_number
		wave_transition_label.visible = true
