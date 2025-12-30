class_name BattleManager
extends Node

signal battle_started()
signal unit_action_ready(unit: Unit)
signal battle_ended(victory: bool)
signal global_turn_ready()  # Phase 2: Global turn system

enum BattleState { PREPARING, RUNNING, PAUSED_FOR_CARD, ENDED }  # Phase 2: New pause state

var state: BattleState = BattleState.PREPARING

var ally_units: Array[Unit] = []
var enemy_units: Array[Unit] = []

var action_queue: Array[Unit] = []  # Units waiting to act

# Phase 2: Global turn system
const GLOBAL_TURN_INTERVAL: float = 10.0  # seconds
var global_turn_timer: float = 0.0
var global_turn_count: int = 0

func start_battle(ally_data: Array, enemy_data: Array) -> void:
	print("BattleManager: Starting battle with ", ally_data.size(), " allies vs ", enemy_data.size(), " enemies")

	# Create units from data
	for unit_id in ally_data:
		var unit = DataManager.create_unit_instance(unit_id, true)
		if unit:
			ally_units.append(unit)
			_connect_unit_signals(unit)
			print("  Ally: ", unit.display_name, " (", unit.category, ")")

	for unit_id in enemy_data:
		var unit = DataManager.create_unit_instance(unit_id, false)
		if unit:
			enemy_units.append(unit)
			_connect_unit_signals(unit)
			print("  Enemy: ", unit.display_name, " (", unit.category, ")")

	state = BattleState.RUNNING
	battle_started.emit()

# Phase 2: Start battle with generals assigned
func start_battle_with_generals(ally_data: Array, enemy_data: Array) -> void:
	print("BattleManager: Starting battle with generals")

	# Create ally units with generals
	for unit_config in ally_data:
		var unit_id = unit_config.get("id", "")
		var general = unit_config.get("general", null)
		var unit = DataManager.create_unit_instance(unit_id, true, general)
		if unit:
			ally_units.append(unit)
			_connect_unit_signals(unit)
			var general_name = general.display_name if general else "None"
			print("  Ally: ", unit.display_name, " (General: ", general_name, ")")

	# Create enemy units
	for unit_config in enemy_data:
		var unit_id = unit_config.get("id", "")
		var general = unit_config.get("general", null)
		var unit = DataManager.create_unit_instance(unit_id, false, general)
		if unit:
			enemy_units.append(unit)
			_connect_unit_signals(unit)
			print("  Enemy: ", unit.display_name, " (", unit.category, ")")

	state = BattleState.RUNNING
	battle_started.emit()

func _process(delta: float) -> void:
	match state:
		BattleState.RUNNING:
			# Only tick ATB and global timer when running
			_update_atb(delta)
			_tick_global_turn_timer(delta)
			_process_action_queue()
			_check_battle_end()
		BattleState.PAUSED_FOR_CARD:
			# Waiting for card selection - no updates
			pass
		BattleState.ENDED, BattleState.PREPARING:
			pass

func _update_atb(delta: float) -> void:
	for unit in ally_units + enemy_units:
		unit.tick_atb(delta)

func _on_unit_atb_filled(unit: Unit) -> void:
	if state == BattleState.RUNNING and not action_queue.has(unit):
		action_queue.append(unit)

func _process_action_queue() -> void:
	if action_queue.is_empty():
		return

	var unit = action_queue.pop_front()

	if not unit.is_alive:
		return

	# Phase 2: All units auto-attack (skills are triggered manually via UI)
	_execute_auto_attack(unit)

func _execute_auto_attack(attacker: Unit) -> void:
	var targets = enemy_units if attacker.is_ally else ally_units
	var alive_targets = targets.filter(func(u): return u.is_alive)

	if alive_targets.is_empty():
		return

	# Simple targeting: first alive unit
	var target = alive_targets[0]
	var damage = attacker.calculate_attack_damage(target)

	print(attacker.display_name, " attacks ", target.display_name, " for ", damage, " damage")

	attacker.attack_target(target)
	attacker.reset_atb()

	# Visual feedback (emit signal for UI)
	unit_action_ready.emit(attacker)

func _check_battle_end() -> void:
	var allies_alive = ally_units.filter(func(u): return u.is_alive)
	var enemies_alive = enemy_units.filter(func(u): return u.is_alive)

	if enemies_alive.is_empty():
		_end_battle(true)
	elif allies_alive.is_empty():
		_end_battle(false)

func _end_battle(victory: bool) -> void:
	if state == BattleState.ENDED:
		return

	state = BattleState.ENDED
	print("BattleManager: Battle ended - ", "VICTORY" if victory else "DEFEAT")
	battle_ended.emit(victory)

func _connect_unit_signals(unit: Unit) -> void:
	unit.atb_filled.connect(_on_unit_atb_filled)
	unit.died.connect(func(): print(unit.display_name, " has died!"))

# Phase 2: Global turn timer
func _tick_global_turn_timer(delta: float) -> void:
	global_turn_timer += delta

	if global_turn_timer >= GLOBAL_TURN_INTERVAL:
		global_turn_timer = 0.0
		global_turn_count += 1
		_trigger_global_turn()

func _trigger_global_turn() -> void:
	print("=== GLOBAL TURN ", global_turn_count, " ===")
	state = BattleState.PAUSED_FOR_CARD

	# Tick buff durations for all units (global turn based)
	for unit in ally_units + enemy_units:
		unit.tick_buff_durations()

	# Tick skill cooldowns for ally generals (if they have generals)
	for unit in ally_units:
		if unit.general:
			unit.general.tick_cooldown()

	global_turn_ready.emit()

func on_card_used() -> void:
	# Called by UI after player selects and uses a card
	print("Card used, resuming battle")
	state = BattleState.RUNNING

# Phase 2: Execute unit skill (called from UI when player clicks skill icon)
func execute_unit_skill(unit: Unit) -> void:
	if not unit.is_alive:
		push_warning("Cannot execute skill - unit is dead")
		return

	if not unit.general or not unit.general.is_skill_ready():
		push_warning("Cannot execute skill - skill not ready")
		return

	_execute_skill(unit)

func _execute_skill(unit: Unit) -> void:
	var general = unit.general
	var targets = _get_skill_targets(general.skill, unit.is_ally, unit)

	# Execute the skill effect
	general.execute_skill_effect(unit, targets)

	# Note: Skills do NOT reset ATB - they are independent of the ATB system
	# ATB continues to fill normally for auto-attacks

	print(general.display_name, " (", unit.display_name, ") used skill!")

func _get_skill_targets(skill: Dictionary, is_ally: bool, caster: Unit) -> Array[Unit]:
	var effect = skill.get("effect", {})
	var target_type = effect.get("target", "single_enemy")

	var allies = ally_units.filter(func(u): return u.is_alive)
	var enemies = enemy_units.filter(func(u): return u.is_alive)

	match target_type:
		"single_enemy":
			var target_list = enemies if is_ally else allies
			if not target_list.is_empty():
				var result: Array[Unit] = [target_list[0]]
				return result
			else:
				var empty: Array[Unit] = []
				return empty
		"all_enemies":
			return enemies if is_ally else allies
		"single_ally":
			var target_list = allies if is_ally else enemies
			# Select lowest HP ally for healing
			if not target_list.is_empty():
				var lowest = target_list[0]
				for u in target_list:
					if u.current_hp < lowest.current_hp:
						lowest = u
				var result: Array[Unit] = [lowest]
				return result
			else:
				var empty: Array[Unit] = []
				return empty
		"all_allies":
			return allies if is_ally else enemies
		"self":
			if caster.is_alive:
				var result: Array[Unit] = [caster]
				return result
			else:
				var empty: Array[Unit] = []
				return empty
		_:
			var empty: Array[Unit] = []
			return empty

# DEBUG: Force battle result for testing
func force_victory() -> void:
	print("BattleManager: FORCE VICTORY - killing all enemies")
	for unit in enemy_units:
		if unit.is_alive:
			# Set HP directly to bypass defense calculation
			unit.current_hp = 0
			unit.is_alive = false
			unit.died.emit()
	_check_battle_end()

func force_defeat() -> void:
	print("BattleManager: FORCE DEFEAT - killing all allies")
	for unit in ally_units:
		if unit.is_alive:
			# Set HP directly to bypass defense calculation
			unit.current_hp = 0
			unit.is_alive = false
			unit.died.emit()
	_check_battle_end()
