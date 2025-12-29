class_name SkillButton
extends Button

# Preload dependencies
const Unit = preload("res://src/core/unit.gd")

signal skill_clicked(unit: Unit)

var unit: Unit
var is_skill_ready: bool = false

func setup(unit_instance: Unit) -> void:
	unit = unit_instance
	custom_minimum_size = Vector2(80, 80)

	# Update display
	_update_display()

	# Connect to button press
	pressed.connect(_on_pressed)

func _update_display() -> void:
	if not unit or not unit.general:
		text = "???"
		disabled = true
		return

	# Check if skill is ready (cooldown 0 only, independent of ATB)
	is_skill_ready = unit.general.is_skill_ready()

	# Get localized skill name
	var skill_name = ""
	if unit.general.skill.has("name_key"):
		var name_key = unit.general.skill.get("name_key", "")
		skill_name = DataManager.get_localized(name_key)

	# Display skill name + status
	text = skill_name + "\n"

	if is_skill_ready:
		text += "[준비]"
		disabled = false
		modulate = Color.WHITE
	else:
		# On cooldown
		text += "CD:" + str(unit.general.current_cooldown)
		disabled = true
		modulate = Color(0.6, 0.6, 0.6)

func update_status() -> void:
	_update_display()

func _on_pressed() -> void:
	if is_skill_ready:
		skill_clicked.emit(unit)
