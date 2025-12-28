class_name SkillSelectionPanel
extends PanelContainer

# Preload dependencies
const Unit = preload("res://src/core/unit.gd")

signal skill_selected(unit: Unit, use_skill: bool)

var current_unit: Unit = null

# UI References (created in _init)
var name_label: Label
var skill_info: Label
var skill_button: Button
var auto_button: Button

func _init() -> void:
	_create_ui()
	visible = false

func _create_ui() -> void:
	# Container setup
	custom_minimum_size = Vector2(400, 200)

	# Background style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.GOLD
	add_theme_stylebox_override("panel", style)

	# Main VBox
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)

	# Title
	var title = Label.new()
	title.text = DataManager.get_localized("UI_SKILL_READY")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

	# Unit name
	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_label)

	# Skill info
	skill_info = Label.new()
	skill_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_info.custom_minimum_size = Vector2(350, 60)
	vbox.add_child(skill_info)

	# Button container
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 20)
	vbox.add_child(button_container)

	# Skill button
	skill_button = Button.new()
	skill_button.text = DataManager.get_localized("UI_USE_SKILL")
	skill_button.custom_minimum_size = Vector2(150, 40)
	skill_button.pressed.connect(_on_skill_pressed)
	button_container.add_child(skill_button)

	# Auto attack button
	auto_button = Button.new()
	auto_button.text = DataManager.get_localized("UI_AUTO_ATTACK")
	auto_button.custom_minimum_size = Vector2(150, 40)
	auto_button.pressed.connect(_on_auto_pressed)
	button_container.add_child(auto_button)

	# Center the panel (will be positioned by parent)
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -200
	offset_right = 200
	offset_top = -100
	offset_bottom = 100

func show_for_unit(unit: Unit) -> void:
	current_unit = unit

	# Update unit name
	name_label.text = unit.display_name

	# Update skill info
	if unit.general and not unit.general.skill.is_empty():
		var skill = unit.general.skill
		var skill_name = DataManager.get_localized(skill.get("name_key", ""))
		var skill_desc = DataManager.get_localized(skill.get("description_key", ""))

		if unit.general.is_skill_ready():
			skill_info.text = skill_name + "\n" + skill_desc
			skill_button.disabled = false
		else:
			var cooldown_text = DataManager.get_localized("UI_COOLDOWN") + " " + str(unit.general.current_cooldown)
			skill_info.text = skill_name + "\n" + cooldown_text
			skill_button.disabled = true
	else:
		skill_info.text = DataManager.get_localized("UI_NO_SKILL")
		skill_button.disabled = true

	visible = true

func _on_skill_pressed() -> void:
	skill_selected.emit(current_unit, true)
	visible = false

func _on_auto_pressed() -> void:
	skill_selected.emit(current_unit, false)
	visible = false
