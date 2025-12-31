class_name SkillBar
extends VBoxContainer

# Preload dependencies
const Unit = preload("res://src/core/unit.gd")
const Corps = preload("res://src/core/corps.gd")
const SkillButton = preload("res://src/ui/battle/skill_button.gd")

# Phase 5D: Changed to Variant to support both Unit and Corps
signal skill_activated(unit_or_corps)

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

# Phase 5D: Support both Unit and Corps
func setup(allies: Array) -> void:
	# Clear existing buttons
	for button in skill_buttons:
		button.queue_free()
	skill_buttons.clear()

	# Create skill button for each ally with a general
	for ally in allies:
		if ally.general:
			var button = SkillButton.new()
			button.setup(ally)
			button.skill_clicked.connect(_on_skill_clicked)
			add_child(button)
			skill_buttons.append(button)

func update_all_buttons() -> void:
	for button in skill_buttons:
		button.update_status()

# Phase 5D: Changed to Variant
func _on_skill_clicked(unit_or_corps) -> void:
	skill_activated.emit(unit_or_corps)
