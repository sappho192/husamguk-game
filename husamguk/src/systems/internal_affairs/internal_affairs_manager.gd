class_name InternalAffairsManager
extends Node

# Preload dependencies
const RunState = preload("res://src/core/run_state.gd")
const Buff = preload("res://src/core/buff.gd")

signal event_selected(event_data: Dictionary)
signal internal_affairs_completed()

const CHOICES_PER_PHASE = 3  # Fixed: 3 governance choices

var choices_made: int = 0
var current_run: RunState

func _ready() -> void:
	current_run = GameManager.current_run
	if not current_run:
		push_error("InternalAffairsManager: No active run!")

# Get 3 random event choices (one from each of 3 random categories)
func get_next_choices() -> Array[Dictionary]:
	var categories = ["military", "economic", "diplomatic", "personnel"]
	categories.shuffle()

	# Select 3 random categories
	var selected_categories = categories.slice(0, 3)

	var choices: Array[Dictionary] = []
	for category in selected_categories:
		var category_events = DataManager.get_events_by_category(category)

		# Filter by conditions (flag checks)
		var valid_events = category_events.filter(func(event): return _check_event_condition(event))

		if not valid_events.is_empty():
			valid_events.shuffle()
			var event = valid_events[0]

			# Localize event
			event["display_name"] = DataManager.get_localized(event.get("name_key", ""))
			event["display_description"] = DataManager.get_localized(event.get("description_key", ""))

			choices.append(event)

	return choices

# Check if event condition is met
func _check_event_condition(event: Dictionary) -> bool:
	if not event.has("condition"):
		return true  # No condition = always available

	var condition = event.get("condition", {})
	var cond_type = condition.get("type", "")

	match cond_type:
		"flag_exists":
			var flag_id = condition.get("flag_id", "")
			var expected = condition.get("value", true)
			return current_run.has_event_flag(flag_id) == expected
		"flag_equals":
			var flag_id = condition.get("flag_id", "")
			var expected_value = condition.get("value", null)
			return current_run.get_event_flag(flag_id) == expected_value
		"stage_min":
			var min_stage = condition.get("value", 1)
			return current_run.current_stage >= min_stage
		"stage_max":
			var max_stage = condition.get("value", 3)
			return current_run.current_stage <= max_stage
		_:
			return true

# Execute event effects
func execute_event(event: Dictionary) -> void:
	print("InternalAffairsManager: Executing event: ", event.get("id", "unknown"))

	var effects = event.get("effects", [])
	for effect in effects:
		_apply_effect(effect)

	# Record choice
	current_run.governance_choices_made.append({
		"event_id": event.get("id", ""),
		"stage": current_run.current_stage
	})

	choices_made += 1
	event_selected.emit(event)

	# Check if all choices made
	if choices_made >= CHOICES_PER_PHASE:
		print("InternalAffairsManager: All choices made, completing internal affairs")
		internal_affairs_completed.emit()

# Apply individual effect
func _apply_effect(effect: Dictionary) -> void:
	var effect_type = effect.get("type", "")

	match effect_type:
		"stat_boost":
			_apply_stat_boost(effect)
		"hp_restore":
			_apply_hp_restore(effect)
		"add_card":
			_apply_add_card(effect)
		"set_flag":
			_apply_set_flag(effect)
		"buff":
			_apply_buff(effect)
		"penalty":
			_apply_penalty(effect)

func _apply_stat_boost(effect: Dictionary) -> void:
	# Modify base stats in unit_states
	var target_type = effect.get("target", "all_units")
	var stat = effect.get("stat", "attack")
	var value = effect.get("value", 0)
	var value_type = effect.get("value_type", "flat")

	var unit_ids = current_run.unit_states.keys()
	if target_type == "random_unit" and not unit_ids.is_empty():
		# Apply to random unit
		unit_ids.shuffle()
		var unit_id = unit_ids[0]
		var unit_state = current_run.unit_states[unit_id]
		_modify_unit_stat(unit_state, stat, value, value_type)
	else:
		# Apply to all units
		for unit_state in current_run.unit_states.values():
			_modify_unit_stat(unit_state, stat, value, value_type)

	print("  Applied stat boost: ", stat, " ", value, " (", value_type, ")")

func _modify_unit_stat(unit_state: Dictionary, stat: String, value: float, value_type: String) -> void:
	if not unit_state.has(stat):
		return

	var current_value = unit_state.get(stat, 0)

	if value_type == "percent":
		unit_state[stat] = int(current_value * (1.0 + value / 100.0))
	else:
		unit_state[stat] = current_value + int(value)

func _apply_hp_restore(effect: Dictionary) -> void:
	var target_type = effect.get("target", "all_units")
	var value = effect.get("value", 0)
	var value_type = effect.get("value_type", "percent")

	for unit_state in current_run.unit_states.values():
		var max_hp = unit_state.get("max_hp", 100)
		var current_hp = unit_state.get("current_hp", 0)

		var restore_amount = 0
		if value_type == "percent":
			restore_amount = int(max_hp * value / 100.0)
		else:
			restore_amount = int(value)

		unit_state["current_hp"] = mini(max_hp, current_hp + restore_amount)

	print("  Restored HP: ", value, " (", value_type, ")")

func _apply_add_card(effect: Dictionary) -> void:
	var card_id = effect.get("card_id", "")
	if card_id.is_empty():
		return

	current_run.deck_card_ids.append(card_id)
	current_run.cards_added.append(card_id)
	print("  Added card to deck: ", card_id)

func _apply_set_flag(effect: Dictionary) -> void:
	var flag_id = effect.get("flag_id", "")
	var flag_value = effect.get("flag_value", true)

	if not flag_id.is_empty():
		current_run.set_event_flag(flag_id, flag_value)
		print("  Set event flag: ", flag_id, " = ", flag_value)

func _apply_buff(effect: Dictionary) -> void:
	# Store buff to be applied at battle start
	var buff_data = {
		"id": "event_buff_" + str(Time.get_ticks_msec()),
		"type": "buff",
		"stat": effect.get("stat", "attack"),
		"value": effect.get("value", 0),
		"value_type": effect.get("value_type", "percent"),
		"duration": effect.get("duration", 999),
		"source": "event"
	}

	# Add to unit_states buffs
	var target_type = effect.get("target", "all_units")
	for unit_state in current_run.unit_states.values():
		var buffs = unit_state.get("buffs", [])
		buffs.append(buff_data)
		unit_state["buffs"] = buffs

	print("  Applied buff: ", buff_data.get("stat"), " +", buff_data.get("value"), "%")

func _apply_penalty(effect: Dictionary) -> void:
	# Similar to buff but negative
	var target_type = effect.get("target", "all_units")
	var stat = effect.get("stat", "hp")
	var value = effect.get("value", 0)
	var value_type = effect.get("value_type", "percent")

	if stat == "hp":
		# Immediate HP penalty
		var unit_states = current_run.unit_states.values()
		if target_type == "random_unit" and not unit_states.is_empty():
			# Apply to random unit
			var states_array = Array(unit_states)
			states_array.shuffle()
			var unit_state = states_array[0]
			var current_hp = unit_state.get("current_hp", 100)
			var penalty_amount = 0

			if value_type == "percent":
				penalty_amount = int(current_hp * value / 100.0)
			else:
				penalty_amount = int(value)

			unit_state["current_hp"] = maxi(1, current_hp - penalty_amount)
		else:
			# Apply to all units
			for unit_state in unit_states:
				var current_hp = unit_state.get("current_hp", 100)
				var penalty_amount = 0

				if value_type == "percent":
					penalty_amount = int(current_hp * value / 100.0)
				else:
					penalty_amount = int(value)

				unit_state["current_hp"] = maxi(1, current_hp - penalty_amount)
	else:
		# Stat penalty (stored as debuff)
		var debuff_data = {
			"id": "event_penalty_" + str(Time.get_ticks_msec()),
			"type": "debuff",
			"stat": stat,
			"value": value,
			"value_type": value_type,
			"duration": 999,
			"source": "event"
		}

		var unit_states = current_run.unit_states.values()
		if target_type == "random_unit" and not unit_states.is_empty():
			var states_array = Array(unit_states)
			states_array.shuffle()
			var unit_state = states_array[0]
			var buffs = unit_state.get("buffs", [])
			buffs.append(debuff_data)
			unit_state["buffs"] = buffs
		else:
			for unit_state in unit_states:
				var buffs = unit_state.get("buffs", [])
				buffs.append(debuff_data)
				unit_state["buffs"] = buffs

	print("  Applied penalty: ", stat, " -", value, " (", value_type, ")")
