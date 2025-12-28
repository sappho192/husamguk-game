class_name BattleManager
extends Node

signal battle_started()
signal unit_action_ready(unit: Unit)
signal battle_ended(victory: bool)

enum BattleState { PREPARING, RUNNING, PAUSED_FOR_ACTION, ENDED }

var state: BattleState = BattleState.PREPARING

var ally_units: Array[Unit] = []
var enemy_units: Array[Unit] = []

var action_queue: Array[Unit] = []  # Units waiting to act

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

func _process(delta: float) -> void:
	if state != BattleState.RUNNING:
		return

	_update_atb(delta)
	_process_action_queue()
	_check_battle_end()

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

	# Phase 1: All units auto-attack
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
