class_name BattleManager
extends Node

signal battle_started()
signal unit_action_ready(unit: Unit)
signal battle_ended(victory: bool)
signal global_turn_ready()  # Phase 2: Global turn system
signal wave_started(wave_number: int, total_waves: int)  # Phase 4: Wave system
signal wave_complete(wave_number: int, has_next_wave: bool)  # Phase 4: Wave complete

enum BattleState { PREPARING, RUNNING, PAUSED_FOR_CARD, WAVE_TRANSITION, ENDED }  # Phase 4: Added WAVE_TRANSITION

var state: BattleState = BattleState.PREPARING

var ally_units: Array[Unit] = []
var enemy_units: Array[Unit] = []

var action_queue: Array[Unit] = []  # Units waiting to act

# Phase 2: Global turn system
const GLOBAL_TURN_INTERVAL: float = 10.0  # seconds
var global_turn_timer: float = 0.0
var global_turn_count: int = 0

# Phase 4: Wave system
var battle_data: Dictionary = {}  # Full battle definition
var current_wave_index: int = 0   # 0-based wave index
var total_waves: int = 0

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

# Phase 4: Start battle from battle data (Wave system)
func start_battle_from_data(battle_id: String, ally_data: Array) -> void:
	print("BattleManager: Starting battle from data: ", battle_id)

	# Load battle definition
	battle_data = DataManager.get_battle(battle_id)
	if battle_data.is_empty():
		push_error("BattleManager: Battle not found: " + battle_id)
		return

	var waves = battle_data.get("waves", [])
	if waves.is_empty():
		push_error("BattleManager: No waves defined for battle: " + battle_id)
		return

	total_waves = waves.size()
	current_wave_index = 0

	# Create ally units
	for unit_config in ally_data:
		var unit_id = unit_config.get("id", "")
		var general = unit_config.get("general", null)
		var unit = DataManager.create_unit_instance(unit_id, true, general)
		if unit:
			ally_units.append(unit)
			_connect_unit_signals(unit)
			var general_name = general.display_name if general else "None"
			print("  Ally: ", unit.display_name, " (General: ", general_name, ")")

	# Start first wave
	_spawn_wave(0)
	state = BattleState.RUNNING
	battle_started.emit()

func _spawn_wave(wave_index: int) -> void:
	print("=== SPAWNING WAVE ", wave_index + 1, " / ", total_waves, " ===")

	var waves = battle_data.get("waves", [])
	if wave_index >= waves.size():
		push_error("BattleManager: Wave index out of bounds: ", wave_index)
		return

	var wave_data = waves[wave_index]
	var enemies_data = wave_data.get("enemies", [])

	# Clear existing enemies from previous wave
	for enemy in enemy_units:
		if enemy.atb_filled.is_connected(_on_unit_atb_filled):
			enemy.atb_filled.disconnect(_on_unit_atb_filled)
	enemy_units.clear()

	# Create enemy units for this wave
	for enemy_config in enemies_data:
		var unit_id = enemy_config.get("id", "")
		var general_id = enemy_config.get("general", null)
		var general = null
		if general_id:
			general = DataManager.create_general_instance(general_id)

		var unit = DataManager.create_unit_instance(unit_id, false, general)
		if unit:
			enemy_units.append(unit)
			_connect_unit_signals(unit)
			var general_name = general.display_name if general else "None"
			print("  Enemy: ", unit.display_name, " (General: ", general_name, ")")

	current_wave_index = wave_index
	wave_started.emit(wave_index + 1, total_waves)

func _on_wave_complete() -> void:
	print("=== WAVE ", current_wave_index + 1, " COMPLETE ===")

	var has_next_wave = current_wave_index + 1 < total_waves
	wave_complete.emit(current_wave_index + 1, has_next_wave)

	if has_next_wave:
		# Apply wave rewards
		var waves = battle_data.get("waves", [])
		var wave_data = waves[current_wave_index]
		_apply_wave_rewards(wave_data)

		# Transition to next wave
		state = BattleState.WAVE_TRANSITION
		await get_tree().create_timer(2.0).timeout  # 2 second pause

		if not is_inside_tree():
			return  # Scene was changed during wait

		_spawn_wave(current_wave_index + 1)
		state = BattleState.RUNNING
	else:
		# Battle victory
		_end_battle(true)

func _apply_wave_rewards(wave_data: Dictionary) -> void:
	var rewards = wave_data.get("wave_rewards", null)
	if rewards == null or rewards.is_empty():
		return

	print("Applying wave rewards...")

	# HP recovery
	var hp_recovery_pct = rewards.get("hp_recovery_percent", 0)
	if hp_recovery_pct > 0:
		for unit in ally_units:
			if unit.is_alive:
				var recovery = int(unit.max_hp * hp_recovery_pct / 100.0)
				unit.current_hp = mini(unit.current_hp + recovery, unit.max_hp)
				print("  ", unit.display_name, " recovered ", recovery, " HP")

	# Global turn reset
	var global_turn_reset = rewards.get("global_turn_reset", false)
	if global_turn_reset:
		global_turn_timer = GLOBAL_TURN_INTERVAL  # Trigger immediately
		print("  Global turn reset - card draw ready")

	# Buff duration extension
	var buff_extension = rewards.get("buff_duration_extension", 0)
	if buff_extension > 0:
		for unit in ally_units:
			for buff in unit.active_buffs:
				buff.duration += buff_extension
				print("  ", unit.display_name, " buffs extended by ", buff_extension, " turns")

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
		# Check if this is a wave-based battle
		if total_waves > 0:
			# Wave complete, check for next wave
			_on_wave_complete()
		else:
			# Non-wave battle - instant victory
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
