class_name RunState
extends RefCounted

# Preload dependencies
const Buff = preload("res://src/core/buff.gd")
const Corps = preload("res://src/core/corps.gd")

# Run progression
var current_stage: int = 1  # 1-3
var battle_results: Array[bool] = []  # Victory history

# Event flags (branching choices, reset each run)
var event_flags: Dictionary = {}  # flag_id → bool/int/string

# Unit state persistence (HP, buffs, stat mods)
var unit_states: Dictionary = {}  # unit_id → UnitState dictionary

# Phase 5: Corps state persistence (HP only - position/formation reset each stage)
var corps_states: Dictionary = {}  # corps_template_id → CorpsState dictionary

# Deck modifications
var deck_card_ids: Array[String] = []  # Current deck composition
var cards_added: Array[String] = []  # Cards added during run
var cards_removed: Array[String] = []  # Cards removed during run

# Run-level enhancements (temporary)
var active_enhancements: Array[Dictionary] = []  # Enhancement data

# Internal affairs tracking
var governance_choices_made: Array[Dictionary] = []  # Choice history

# Constructor - initialize with starter deck
func _init() -> void:
	# Starter deck: 3x aggressive charge, 2x iron defense, 2x field medic, 2x intimidate, 1x sabotage
	deck_card_ids = [
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

# Save unit state after battle
func save_unit_state(unit: Unit) -> void:
	var state_data = {
		"id": unit.id,
		"current_hp": unit.current_hp,
		"max_hp": unit.max_hp,
		"attack": unit.attack,
		"defense": unit.defense,
		"atb_speed": unit.atb_speed,
		"buffs": _serialize_buffs(unit.active_buffs),
		"general_id": unit.general.id if unit.general else null
	}
	unit_states[unit.id] = state_data

# Restore unit state before battle
func restore_unit_state(unit: Unit) -> void:
	if not unit_states.has(unit.id):
		return  # New unit, no state to restore

	var state = unit_states[unit.id]
	unit.current_hp = state.get("current_hp", unit.max_hp)
	unit.max_hp = state.get("max_hp", unit.max_hp)
	unit.attack = state.get("attack", unit.attack)
	unit.defense = state.get("defense", unit.defense)
	unit.atb_speed = state.get("atb_speed", unit.atb_speed)

	# Restore buffs
	var buff_data_array = state.get("buffs", [])
	for buff_data in buff_data_array:
		var buff = Buff.new(buff_data)
		unit.add_buff(buff)

	# NOTE: General cooldown is NOT restored - resets to 0 at the start of each battle
	# This ensures all skills are available at the beginning of every new battle stage

# Phase 5: Save corps state after battle
func save_corps_state(corps: Corps) -> void:
	var state_data = {
		"template_id": corps.template_id,
		"current_hp": corps.current_hp,
		"max_hp": corps.max_hp,
		"soldier_count": corps.soldier_count,
		"general_id": corps.general.id if corps.general else null
	}
	corps_states[corps.template_id] = state_data

# Phase 5: Restore corps state before battle
func restore_corps_state(corps: Corps) -> void:
	if not corps_states.has(corps.template_id):
		return  # New corps, no state to restore

	var state = corps_states[corps.template_id]
	corps.current_hp = state.get("current_hp", corps.max_hp)
	corps.max_hp = state.get("max_hp", corps.max_hp)
	corps.soldier_count = state.get("soldier_count", corps.soldier_count)

	# NOTE: Position and formation are NOT restored - they reset to spawn positions each stage
	# NOTE: General cooldown is NOT restored - resets to 0 at the start of each battle

# Apply run-level enhancement to units
func apply_enhancement_to_units(enhancement: Dictionary, units: Array) -> void:
	var effect_type = enhancement.get("effect_type", "")

	match effect_type:
		"stat_boost":
			_apply_stat_boost(enhancement, units)
		"buff":
			_apply_enhancement_buff(enhancement, units)
		"card_add":
			_apply_card_addition(enhancement)
		"special":
			_apply_special_enhancement(enhancement, units)

func _serialize_buffs(buffs: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for buff in buffs:
		result.append({
			"id": buff.id,
			"type": "buff" if buff.buff_type == Buff.Type.BUFF else "debuff",
			"stat": _buff_stat_to_string(buff.stat),
			"value": buff.value,
			"value_type": buff.value_type,
			"duration": buff.duration,
			"source": buff.source
		})
	return result

func _buff_stat_to_string(stat: Buff.Stat) -> String:
	match stat:
		Buff.Stat.ATTACK: return "attack"
		Buff.Stat.DEFENSE: return "defense"
		Buff.Stat.HP: return "hp"
		Buff.Stat.ATB_SPEED: return "atb_speed"
		_: return "attack"

# Enhancement application helpers (Phase 3C)
func _apply_stat_boost(enhancement: Dictionary, units: Array) -> void:
	# Permanent stat increase for run
	var effect = enhancement.get("effect", {})
	var target_type = effect.get("target", "all_units")
	var stat = effect.get("stat", "attack")
	var value = effect.get("value", 0)
	var value_type = effect.get("value_type", "flat")

	for unit in units:
		if target_type == "random_unit":
			# Apply to first unit only (simplified)
			_modify_unit_stat_direct(unit, stat, value, value_type)
			break
		else:
			# all_units
			_modify_unit_stat_direct(unit, stat, value, value_type)

	print("RunState: Applied stat boost: ", stat, " ", value, " (", value_type, ")")

func _modify_unit_stat_direct(unit: Unit, stat: String, value: float, value_type: String) -> void:
	match stat:
		"attack":
			if value_type == "percent":
				unit.attack = int(unit.attack * (1.0 + value / 100.0))
			else:
				unit.attack += int(value)
		"defense":
			if value_type == "percent":
				unit.defense = int(unit.defense * (1.0 + value / 100.0))
			else:
				unit.defense += int(value)
		"max_hp":
			if value_type == "percent":
				unit.max_hp = int(unit.max_hp * (1.0 + value / 100.0))
			else:
				unit.max_hp += int(value)
		"atb_speed":
			if value_type == "percent":
				unit.atb_speed = unit.atb_speed * (1.0 + value / 100.0)
			else:
				unit.atb_speed += value

func _apply_enhancement_buff(enhancement: Dictionary, units: Array) -> void:
	# Apply buff to units
	var effect = enhancement.get("effect", {})
	var buff_data = {
		"id": "enhancement_buff_" + enhancement.get("id", ""),
		"type": "buff",
		"stat": effect.get("stat", "attack"),
		"value": effect.get("value", 0),
		"value_type": effect.get("value_type", "percent"),
		"duration": effect.get("duration", 999),
		"source": "enhancement"
	}

	var target_type = effect.get("target", "all_units")
	for unit in units:
		var buff = Buff.new(buff_data)
		unit.add_buff(buff)

		if target_type == "random_unit":
			break

	print("RunState: Applied enhancement buff: ", buff_data.get("stat"), " +", buff_data.get("value"), "%")

func _apply_card_addition(enhancement: Dictionary) -> void:
	# Add card to deck
	var effect = enhancement.get("effect", {})
	var card_id = effect.get("card_id", "")
	if not card_id.is_empty():
		deck_card_ids.append(card_id)
		cards_added.append(card_id)
		print("RunState: Added card to deck: ", card_id)

func _apply_special_enhancement(enhancement: Dictionary, units: Array) -> void:
	# Special effects - implement in Phase 3C
	print("RunState: Special enhancement not yet implemented")

# Event flag management
func set_event_flag(flag_id: String, value: Variant) -> void:
	event_flags[flag_id] = value

func get_event_flag(flag_id: String, default_value: Variant = false) -> Variant:
	return event_flags.get(flag_id, default_value)

func has_event_flag(flag_id: String) -> bool:
	return event_flags.has(flag_id)
