class_name SkillBar
extends VBoxContainer

# Preload dependencies
const Unit = preload("res://src/core/unit.gd")
const SkillButton = preload("res://src/ui/battle/skill_button.gd")

signal skill_activated(unit: Unit)

var skill_buttons: Array[SkillButton] = []

func _init() -> void:
	# Position on left side
	set_anchors_preset(Control.PRESET_LEFT_WIDE)
	offset_left = 10
	offset_right = 110
	offset_top = 50
	offset_bottom = -50

	# Styling
	add_theme_constant_override("separation", 10)

func setup(ally_units: Array[Unit]) -> void:
	# Clear existing buttons
	for button in skill_buttons:
		button.queue_free()
	skill_buttons.clear()

	# Create skill button for each ally unit with a general
	for unit in ally_units:
		if unit.general:
			var button = SkillButton.new()
			button.setup(unit)
			button.skill_clicked.connect(_on_skill_clicked)
			add_child(button)
			skill_buttons.append(button)

func update_all_buttons() -> void:
	for button in skill_buttons:
		button.update_status()

func _on_skill_clicked(unit: Unit) -> void:
	skill_activated.emit(unit)
