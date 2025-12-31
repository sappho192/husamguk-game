class_name SkillButton
extends Button

# Preload dependencies
const Unit = preload("res://src/core/unit.gd")
const Corps = preload("res://src/core/corps.gd")

# Phase 5D: Changed to Variant to support both Unit and Corps
signal skill_clicked(unit_or_corps)

# Phase 5D: Changed to Variant
var unit_or_corps = null
var is_skill_ready: bool = false

# Phase 5D: Support both Unit and Corps
func setup(entity) -> void:
	unit_or_corps = entity
	custom_minimum_size = Vector2(80, 80)

	# Update display
	_update_display()

	# Connect to button press
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

func _update_display() -> void:
	if not unit_or_corps:
		text = "???"
		disabled = true
		return

	# Get general (both Unit and Corps have .general)
	var general = unit_or_corps.general if unit_or_corps else null
	if not general:
		text = "???"
		disabled = true
		return

	# Check if skill is ready (cooldown 0 only, independent of ATB)
	is_skill_ready = general.is_skill_ready()

	# Get localized skill name
	var skill_name = ""
	if general.skill.has("name_key"):
		var name_key = general.skill.get("name_key", "")
		skill_name = DataManager.get_localized(name_key)

	# Display skill name + status
	text = skill_name + "\n"

	if is_skill_ready:
		text += "[준비]"
		disabled = false
		modulate = Color.WHITE
	else:
		# On cooldown
		text += "CD:" + str(general.current_cooldown)
		disabled = true
		modulate = Color(0.6, 0.6, 0.6)

func update_status() -> void:
	_update_display()

func _on_pressed() -> void:
	if is_skill_ready:
		skill_clicked.emit(unit_or_corps)
