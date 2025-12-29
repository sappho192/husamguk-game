class_name ChoiceButton
extends PanelContainer

signal choice_selected(event_data: Dictionary)

var event_data: Dictionary = {}
var is_interactive: bool = true

# UI Elements (created in _init)
var name_label: Label
var description_label: Label
var category_label: Label

func _init() -> void:
	custom_minimum_size = Vector2(300, 150)
	_create_ui()

func _create_ui() -> void:
	# Main vertical container
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	# Category label (top)
	category_label = Label.new()
	category_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	category_label.add_theme_font_size_override("font_size", 14)
	category_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(category_label)

	# Event name label
	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)

	# Description label
	description_label = Label.new()
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.add_theme_font_size_override("font_size", 14)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(description_label)

	# Default styling
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.5, 0.5, 0.6)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	add_theme_stylebox_override("panel", style)

func setup(event: Dictionary) -> void:
	event_data = event

	# Set labels
	name_label.text = event.get("display_name", "???")
	description_label.text = event.get("display_description", "")

	# Set category label and color
	var category = event.get("category", "")
	category_label.text = DataManager.get_localized("UI_CATEGORY_" + category.to_upper())

	# Category-based border color
	var border_color = _get_category_color(category)
	var style = get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style.border_color = border_color

func _get_category_color(category: String) -> Color:
	match category:
		"military":
			return Color(0.9, 0.3, 0.3)  # Red
		"economic":
			return Color(0.3, 0.9, 0.3)  # Green
		"diplomatic":
			return Color(0.3, 0.6, 0.9)  # Blue
		"personnel":
			return Color(0.9, 0.7, 0.3)  # Gold
		_:
			return Color(0.5, 0.5, 0.6)  # Gray

func set_interactive(enabled: bool) -> void:
	is_interactive = enabled
	mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE

	if enabled:
		modulate = Color.WHITE
	else:
		modulate = Color(0.6, 0.6, 0.6)

func _gui_input(event: InputEvent) -> void:
	if not is_interactive:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			choice_selected.emit(event_data)

func _mouse_enter() -> void:
	if is_interactive:
		# Brighten on hover
		modulate = Color(1.2, 1.2, 1.2)

func _mouse_exit() -> void:
	if is_interactive:
		modulate = Color.WHITE
