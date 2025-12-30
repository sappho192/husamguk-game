extends Control

# UI Elements
var title_label: Label
var stats_container: VBoxContainer
var return_button: Button

# Run statistics (captured before run is cleared)
var stages_cleared: int = 0
var battles_won: int = 0
var choices_made: int = 0
var enhancements_gained: int = 0

func _init() -> void:
	_create_ui()

func _ready() -> void:
	# Set localized text (DataManager is now ready)
	_set_localized_text()

	# Capture run statistics before they're cleared
	if GameManager.current_run:
		var run = GameManager.current_run
		stages_cleared = run.current_stage
		battles_won = run.battle_results.filter(func(result): return result == true).size()
		choices_made = run.governance_choices_made.size()
		enhancements_gained = run.active_enhancements.size()

	# Display statistics
	_display_statistics()

	# Connect button
	return_button.pressed.connect(_on_return_button_pressed)

func _set_localized_text() -> void:
	title_label.text = DataManager.get_localized("UI_RUN_VICTORY")
	return_button.text = DataManager.get_localized("UI_RETURN_TO_MENU")

func _create_ui() -> void:
	# Main vertical container
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 20)
	add_child(main_vbox)

	# Top spacer
	var top_spacer = Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(top_spacer)

	# Victory title
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 64)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))  # Gold
	main_vbox.add_child(title_label)

	# Spacer
	var middle_spacer = Control.new()
	middle_spacer.custom_minimum_size = Vector2(0, 40)
	main_vbox.add_child(middle_spacer)

	# Statistics container
	stats_container = VBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 15)
	stats_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_vbox.add_child(stats_container)

	# Spacer before button
	var button_spacer = Control.new()
	button_spacer.custom_minimum_size = Vector2(0, 60)
	main_vbox.add_child(button_spacer)

	# Return to Menu button
	return_button = Button.new()
	return_button.custom_minimum_size = Vector2(300, 60)
	return_button.add_theme_font_size_override("font_size", 24)
	return_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_button(return_button, Color(0.3, 0.6, 0.9))  # Blue
	main_vbox.add_child(return_button)

	# Bottom spacer
	var bottom_spacer = Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(bottom_spacer)

func _display_statistics() -> void:
	# Clear existing stats (if any)
	for child in stats_container.get_children():
		child.queue_free()

	# Stages Cleared
	_add_stat_row(
		DataManager.get_localized("UI_STAGES_CLEARED"),
		str(stages_cleared) + " / 3"
	)

	# Battles Won
	_add_stat_row(
		DataManager.get_localized("UI_BATTLES_WON"),
		str(battles_won)
	)

	# Governance Choices
	_add_stat_row(
		DataManager.get_localized("UI_CHOICES_MADE"),
		str(choices_made)
	)

	# Enhancements Gained
	_add_stat_row(
		DataManager.get_localized("UI_ENHANCEMENTS_GAINED"),
		str(enhancements_gained)
	)

func _add_stat_row(label_text: String, value_text: String) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# Label
	var label = Label.new()
	label.text = label_text + ":"
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	label.custom_minimum_size = Vector2(300, 0)
	row.add_child(label)

	# Value
	var value = Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 24)
	value.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))  # Gold
	value.custom_minimum_size = Vector2(100, 0)
	row.add_child(value)

	stats_container.add_child(row)

func _style_button(button: Button, base_color: Color) -> void:
	# Normal state
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = base_color
	style_normal.corner_radius_top_left = 8
	style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_left = 8
	style_normal.corner_radius_bottom_right = 8
	style_normal.content_margin_left = 20
	style_normal.content_margin_right = 20
	style_normal.content_margin_top = 15
	style_normal.content_margin_bottom = 15
	button.add_theme_stylebox_override("normal", style_normal)

	# Hover state
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = base_color.lightened(0.2)
	style_hover.corner_radius_top_left = 8
	style_hover.corner_radius_top_right = 8
	style_hover.corner_radius_bottom_left = 8
	style_hover.corner_radius_bottom_right = 8
	style_hover.content_margin_left = 20
	style_hover.content_margin_right = 20
	style_hover.content_margin_top = 15
	style_hover.content_margin_bottom = 15
	button.add_theme_stylebox_override("hover", style_hover)

	# Pressed state
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = base_color.darkened(0.2)
	style_pressed.corner_radius_top_left = 8
	style_pressed.corner_radius_top_right = 8
	style_pressed.corner_radius_bottom_left = 8
	style_pressed.corner_radius_bottom_right = 8
	style_pressed.content_margin_left = 20
	style_pressed.content_margin_right = 20
	style_pressed.content_margin_top = 15
	style_pressed.content_margin_bottom = 15
	button.add_theme_stylebox_override("pressed", style_pressed)

func _on_return_button_pressed() -> void:
	print("VictoryUI: Returning to main menu...")
	GameManager.clear_run()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
