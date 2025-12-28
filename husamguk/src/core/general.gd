class_name General
extends RefCounted

# Preload dependencies
const Buff = preload("res://src/core/buff.gd")
const Unit = preload("res://src/core/unit.gd")

var id: String
var display_name: String
var nation: String
var role: String  # assault, command, special
var portrait_path: String

var leadership: int
var combat: int
var intelligence: int
var politics: int

var skill: Dictionary  # Skill data
var current_cooldown: int = 0  # Phase 2: Cooldown tracking

func _init(data: Dictionary) -> void:
	id = data.get("id", "")
	display_name = data.get("name_key", "")  # Will be localized by DataManager
	nation = data.get("nation", "")
	role = data.get("role", "assault")
	var portrait = data.get("portrait", null)
	portrait_path = portrait if portrait != null else ""

	var stats = data.get("base_stats", {})
	leadership = stats.get("leadership", 50)
	combat = stats.get("combat", 50)
	intelligence = stats.get("intelligence", 50)
	politics = stats.get("politics", 50)

	skill = data.get("skill", {})

# Phase 2: Skill system implementation
func is_skill_ready() -> bool:
	return current_cooldown == 0 and not skill.is_empty()

func use_skill() -> void:
	if not is_skill_ready():
		push_warning("General.use_skill(): Skill not ready!")
		return

	var cooldown = skill.get("cooldown", 3)
	current_cooldown = cooldown
	print(display_name, " used skill: ", skill.get("name_key", ""), " (CD: ", cooldown, " turns)")

func tick_cooldown() -> void:
	if current_cooldown > 0:
		current_cooldown -= 1
		if current_cooldown == 0:
			print(display_name, "'s skill is ready!")

func execute_skill_effect(caster: Unit, targets: Array[Unit]) -> void:
	if not is_skill_ready():
		push_warning("Cannot execute skill - not ready!")
		return

	var effect = skill.get("effect", {})
	var effect_type = effect.get("type", "")

	match effect_type:
		"damage":
			_execute_damage_skill(caster, targets, effect)
		"buff":
			_execute_buff_skill(targets, effect)
		"debuff":
			_execute_debuff_skill(targets, effect)
		"heal":
			_execute_heal_skill(targets, effect)
		"special":
			print("Special skill effects not yet implemented (Phase 3)")

	use_skill()  # Start cooldown

func _execute_damage_skill(caster: Unit, targets: Array[Unit], effect: Dictionary) -> void:
	var multiplier = effect.get("multiplier", 1.0)
	var base_damage = caster.get_effective_attack()

	for target in targets:
		if not target.is_alive:
			continue

		var damage = int(base_damage * multiplier)

		# Check bonus conditions
		var bonus_condition = effect.get("bonus_condition", {})
		if not bonus_condition.is_empty():
			if _check_bonus_condition(bonus_condition, target):
				var bonus_mult = bonus_condition.get("bonus_multiplier", 1.0)
				damage = int(damage * bonus_mult)
				print("  Bonus condition met! Damage: ", damage)

		target.take_damage(damage)
		print(caster.display_name, " skill dealt ", damage, " to ", target.display_name)

func _execute_buff_skill(targets: Array[Unit], effect: Dictionary) -> void:
	var buff_data = {
		"id": skill.get("id", "") + "_buff",
		"type": "buff",
		"stat": effect.get("stat", "attack"),
		"value": effect.get("value", 0),
		"value_type": "percent",  # Skills use percent
		"duration": effect.get("duration", 2),
		"source": "skill"
	}

	for target in targets:
		if not target.is_alive:
			continue
		var buff = Buff.new(buff_data)
		target.add_buff(buff)

func _execute_debuff_skill(targets: Array[Unit], effect: Dictionary) -> void:
	var debuff_data = {
		"id": skill.get("id", "") + "_debuff",
		"type": "debuff",
		"stat": effect.get("stat", "attack"),
		"value": effect.get("value", 0),
		"value_type": "percent",
		"duration": effect.get("duration", 2),
		"source": "skill"
	}

	for target in targets:
		if not target.is_alive:
			continue
		var debuff = Buff.new(debuff_data)
		target.add_buff(debuff)

func _execute_heal_skill(targets: Array[Unit], effect: Dictionary) -> void:
	var value = effect.get("value", 0)
	var value_type = effect.get("value_type", "percent")

	for target in targets:
		if not target.is_alive:
			continue

		var heal_amount = 0
		if value_type == "percent":
			heal_amount = int(target.max_hp * value / 100.0)
		else:
			heal_amount = int(value)

		target.current_hp = mini(target.max_hp, target.current_hp + heal_amount)
		print(target.display_name, " healed for ", heal_amount, " HP")

func _check_bonus_condition(condition: Dictionary, target: Unit) -> bool:
	var cond_type = condition.get("type", "")
	var cond_value = condition.get("value", "")

	match cond_type:
		"target_category":
			return target.category == cond_value
		"target_hp_below":
			var threshold = cond_value
			return (float(target.current_hp) / float(target.max_hp)) < (threshold / 100.0)
		_:
			return false
