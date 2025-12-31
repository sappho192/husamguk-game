extends Node

# Preload dependencies
const RunState = preload("res://src/core/run_state.gd")

# Signals
signal stage_completed(stage_num: int, victory: bool)
signal run_completed(victory: bool)
signal scene_transition_started(scene_path: String)

# Run state (ephemeral, cleared on run end)
var current_run: RunState = null

# Battle configuration (for next battle) - Phase 5: Corps system
var next_battle_config: Dictionary = {}  # map_id, ally_corps, stage

# Scene paths
const BATTLE_SCENE = "res://scenes/corps_battle_test.tscn"
const INTERNAL_AFFAIRS_SCENE = "res://scenes/internal_affairs.tscn"
const ENHANCEMENT_SCENE = "res://scenes/fateful_encounter.tscn"
const MAIN_MENU_SCENE = "res://scenes/main_menu.tscn"
const VICTORY_SCENE = "res://scenes/victory_screen.tscn"
const DEFEAT_SCENE = "res://scenes/defeat_screen.tscn"

func _ready() -> void:
	print("GameManager: Initialized")

# Start new run
func start_new_run() -> void:
	print("GameManager: Starting new run")
	current_run = RunState.new()
	_prepare_stage_1()

func _prepare_stage_1() -> void:
	var gyeonhwon = DataManager.create_general_instance("gyeonhwon")
	var wanggeon = DataManager.create_general_instance("wanggeon")
	var singeom = DataManager.create_general_instance("singeom")

	next_battle_config = {
		"stage": 1,
		"battle_id": "stage_1_corps_battle",
		"map_id": "stage_1_map",
		"ally_corps": [
			{"template_id": "spear_corps", "general": gyeonhwon},
			{"template_id": "archer_corps", "general": wanggeon},
			{"template_id": "light_cavalry_corps", "general": singeom}
		]
	}

	_transition_to_battle()

# Transition to battle scene
func _transition_to_battle() -> void:
	print("GameManager: Transitioning to battle (Stage ", current_run.current_stage, ")")
	scene_transition_started.emit(BATTLE_SCENE)
	get_tree().change_scene_to_file(BATTLE_SCENE)

# Called by BattleUI after battle setup - Phase 5: Corps system
func on_battle_ready(battle_manager, ally_corps: Array) -> void:
	print("GameManager: Battle ready, restoring run state (Corps)")

	# Restore corps states from run (HP, soldier count)
	for corps in ally_corps:
		current_run.restore_corps_state(corps)

	# TODO Phase 5: Apply active enhancements to Corps
	# (Enhancement system will need to support Corps in future phase)

# Called when battle ends - Phase 5: Corps system
func on_battle_ended(victory: bool, ally_corps: Array) -> void:
	print("GameManager: Battle ended (Stage ", current_run.current_stage, ") - ", "VICTORY" if victory else "DEFEAT")

	# Record result
	current_run.battle_results.append(victory)

	if not victory:
		_handle_defeat()
		return

	# Save corps states for carry-forward
	for corps in ally_corps:
		current_run.save_corps_state(corps)

	# Emit stage completion
	stage_completed.emit(current_run.current_stage, victory)

	# Proceed to next phase
	if current_run.current_stage < 3:
		_transition_to_internal_affairs()
	else:
		_handle_run_victory()

# Transition to internal affairs
func _transition_to_internal_affairs() -> void:
	print("GameManager: Transitioning to Internal Affairs")
	scene_transition_started.emit(INTERNAL_AFFAIRS_SCENE)
	get_tree().change_scene_to_file(INTERNAL_AFFAIRS_SCENE)

# Transition to enhancement selection
func _transition_to_enhancement_selection() -> void:
	print("GameManager: Transitioning to Enhancement Selection")
	scene_transition_started.emit(ENHANCEMENT_SCENE)
	get_tree().change_scene_to_file(ENHANCEMENT_SCENE)

# Called when internal affairs complete (3 choices made)
func on_internal_affairs_completed() -> void:
	print("GameManager: Internal affairs completed, moving to enhancement selection")
	_transition_to_enhancement_selection()

# Called when enhancement selected
func on_enhancement_selected(enhancement: Dictionary) -> void:
	print("GameManager: Enhancement selected: ", enhancement.get("id", "unknown"))
	current_run.active_enhancements.append(enhancement)

	# Advance to next stage
	current_run.current_stage += 1
	_prepare_next_stage()

func _prepare_next_stage() -> void:
	print("GameManager: Preparing Stage ", current_run.current_stage)

	var gyeonhwon = DataManager.create_general_instance("gyeonhwon")
	var wanggeon = DataManager.create_general_instance("wanggeon")
	var singeom = DataManager.create_general_instance("singeom")

	var battle_id = "stage_%d_corps_battle" % current_run.current_stage
	var map_id = "stage_%d_map" % current_run.current_stage
	
	next_battle_config["stage"] = current_run.current_stage
	next_battle_config["battle_id"] = battle_id
	next_battle_config["map_id"] = map_id
	next_battle_config["ally_corps"] = [
		{"template_id": "spear_corps", "general": gyeonhwon},
		{"template_id": "archer_corps", "general": wanggeon},
		{"template_id": "light_cavalry_corps", "general": singeom}
	]

	_transition_to_battle()

# Handle defeat
func _handle_defeat() -> void:
	print("GameManager: Run ended in defeat")
	run_completed.emit(false)
	# Transition to defeat screen (current_run stays active for stats capture)
	scene_transition_started.emit(DEFEAT_SCENE)
	get_tree().change_scene_to_file(DEFEAT_SCENE)
	# Note: current_run will be cleared when returning to main menu from defeat screen

# Handle run victory (cleared all 3 stages)
func _handle_run_victory() -> void:
	print("GameManager: Run completed successfully!")
	run_completed.emit(true)
	# Transition to victory screen (current_run stays active for stats capture)
	scene_transition_started.emit(VICTORY_SCENE)
	get_tree().change_scene_to_file(VICTORY_SCENE)
	# Note: current_run will be cleared when returning to main menu from victory screen

# Get current deck composition
func get_current_deck() -> Array[String]:
	if current_run:
		return current_run.deck_card_ids.duplicate()
	return []

# Clear current run (called when returning to main menu)
func clear_run() -> void:
	print("GameManager: Clearing current run")
	current_run = null
