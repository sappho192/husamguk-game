class_name Card
extends RefCounted

# Preload dependencies
const Buff = preload("res://src/core/buff.gd")
const Unit = preload("res://src/core/unit.gd")

# Properties
var id: String
var display_name: String
var description: String
var rarity: String  # common, uncommon, rare, legendary
var icon_path: String

var effect: Dictionary
var penalty: Dictionary
var condition: Dictionary

# Constructor
func _init(data: Dictionary) -> void:
	id = data.get("id", "")
	display_name = data.get("name_key", "")  # Already localized by DataManager
	description = data.get("description_key", "")  # Already localized
	rarity = data.get("rarity", "common")
	var icon = data.get("icon", null)
	icon_path = icon if icon != null else ""

	effect = data.get("effect", {})
	var penalty_data = data.get("penalty", null)
	penalty = penalty_data if penalty_data != null else {}
	var condition_data = data.get("condition", null)
	condition = condition_data if condition_data != null else {}

# Check if card can be used (condition checking)
func can_use(battle_state: Dictionary = {}) -> bool:
	if condition.is_empty():
		return true

	# Condition checking not fully implemented (Phase 3)
	# For now, all cards can be used
	return true

# Execute the card's effect
func execute_effect(ally_units: Array[Unit], enemy_units: Array[Unit]) -> void:
	var targets = _get_targets(ally_units, enemy_units)
	var effect_type = effect.get("type", "")

	print("Card '", display_name, "' used (", effect_type, ")")

	match effect_type:
		"buff", "debuff":
			_apply_buff_debuff(targets, effect)
		"damage":
			_apply_damage(targets)
		"heal":
			_apply_heal(targets)
		"special":
			_apply_special(targets, ally_units, enemy_units)

	# Apply penalty if present
	if not penalty.is_empty():
		_execute_penalty(ally_units, enemy_units)

# Get target units based on effect target type
func _get_targets(allies: Array[Unit], enemies: Array[Unit]) -> Array[Unit]:
	var target_type = effect.get("target", "all_allies")
	var alive_allies = allies.filter(func(u): return u.is_alive)
	var alive_enemies = enemies.filter(func(u): return u.is_alive)

	match target_type:
		"all_allies":
			return alive_allies
		"all_enemies":
			return alive_enemies
		"single_ally":
			# Select lowest HP ally for healing, or random for buffs
			if effect.get("type") == "heal":
				return [_select_lowest_hp_unit(alive_allies)]
			else:
				return [alive_allies[0]] if not alive_allies.is_empty() else []
		"single_enemy":
			# Select first alive enemy (simple targeting)
			return [alive_enemies[0]] if not alive_enemies.is_empty() else []
		"self":
			# Not applicable for cards (no caster unit)
			return alive_allies
		_:
			return []

# Apply buff or debuff
func _apply_buff_debuff(targets: Array[Unit], effect_data: Dictionary) -> void:
	var buff_data = {
		"id": id + "_effect",
		"type": effect_data.get("type", "buff"),
		"stat": effect_data.get("stat", "attack"),
		"value": effect_data.get("value", 0),
		"value_type": effect_data.get("value_type", "percent"),
		"duration": effect_data.get("duration", 2),
		"source": "card"
	}

	for target in targets:
		var buff = Buff.new(buff_data)
		target.add_buff(buff)

# Apply instant damage
func _apply_damage(targets: Array[Unit]) -> void:
	var damage_value = effect.get("value", 0)
	var value_type = effect.get("value_type", "flat")

	for target in targets:
		var damage = 0
		if value_type == "flat":
			damage = int(damage_value)
		else:
			# Percent-based damage (% of max HP)
			damage = int(target.max_hp * damage_value / 100.0)

		target.take_damage(damage)
		print("  ", target.display_name, " took ", damage, " damage from card")

# Apply instant heal
func _apply_heal(targets: Array[Unit]) -> void:
	var heal_value = effect.get("value", 0)
	var value_type = effect.get("value_type", "percent")

	for target in targets:
		var heal_amount = 0
		if value_type == "percent":
			heal_amount = int(target.max_hp * heal_value / 100.0)
		else:
			heal_amount = int(heal_value)

		target.current_hp = mini(target.max_hp, target.current_hp + heal_amount)
		print("  ", target.display_name, " healed ", heal_amount, " HP")

# Apply special effects (Phase 3)
func _apply_special(targets: Array[Unit], allies: Array[Unit], enemies: Array[Unit]) -> void:
	var special_id = effect.get("special_id", "")
	print("Special effect '", special_id, "' not yet implemented (Phase 3)")

	# Placeholder for special effects:
	# - instant_atb_fill: Fill all allies' ATB gauges
	# - reset_cooldowns: Reset all skill cooldowns
	# - convert_enemy: Turn enemy unit to ally
	# etc.

# Execute penalty effect
func _execute_penalty(allies: Array[Unit], enemies: Array[Unit]) -> void:
	var penalty_type = penalty.get("type", "")

	match penalty_type:
		"debuff":
			var penalty_targets = _get_penalty_targets(allies, enemies)
			_apply_buff_debuff(penalty_targets, penalty)
		"dot":
			# Damage over time - apply as a debuff with HP stat
			var penalty_targets = _get_penalty_targets(allies, enemies)
			_apply_buff_debuff(penalty_targets, penalty)
		"conditional":
			print("Conditional penalty not yet implemented (Phase 3)")
		"delayed":
			print("Delayed penalty not yet implemented (Phase 3)")

func _get_penalty_targets(allies: Array[Unit], enemies: Array[Unit]) -> Array[Unit]:
	var target_type = penalty.get("target", "all_allies")
	var alive_allies = allies.filter(func(u): return u.is_alive)
	var alive_enemies = enemies.filter(func(u): return u.is_alive)

	match target_type:
		"all_allies":
			return alive_allies
		"all_enemies":
			return alive_enemies
		_:
			return []

# Helper: Select unit with lowest HP (for healing)
func _select_lowest_hp_unit(units: Array[Unit]) -> Unit:
	if units.is_empty():
		return null

	var lowest = units[0]
	for unit in units:
		if unit.current_hp < lowest.current_hp:
			lowest = unit
	return lowest

# Get rarity color for UI
func get_rarity_color() -> Color:
	match rarity:
		"common":
			return Color.WHITE
		"uncommon":
			return Color.GREEN
		"rare":
			return Color.BLUE
		"legendary":
			return Color.GOLD
		_:
			return Color.GRAY
