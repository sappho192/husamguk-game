class_name EnhancementCard
extends PanelContainer

signal enhancement_selected(enhancement_data: Dictionary)

var enhancement_data: Dictionary = {}
var is_interactive: bool = true

# UI Elements (created in _init)
var name_label: Label
var description_label: Label
var rarity_label: Label
var penalty_label: Label

func _init() -> void:
	custom_minimum_size = Vector2(280, 200)
	_create_ui()

func _create_ui() -> void:
	# Main vertical container
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)

	# Rarity label (top)
	rarity_label = Label.new()
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(rarity_label)

	# Enhancement name label
	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)

	# Description label
	description_label = Label.new()
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.add_theme_font_size_override("font_size", 14)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(description_label)

	# Penalty label (only shown if penalty exists)
	penalty_label = Label.new()
	penalty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	penalty_label.add_theme_font_size_override("font_size", 12)
	penalty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	penalty_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	penalty_label.visible = false
	vbox.add_child(penalty_label)

	# Default styling
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.5, 0.5, 0.6)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	add_theme_stylebox_override("panel", style)

func setup(enhancement: Dictionary) -> void:
	enhancement_data = enhancement

	# Set name and description
	name_label.text = DataManager.get_localized(enhancement.get("name_key", "???"))
	description_label.text = DataManager.get_localized(enhancement.get("description_key", ""))

	# Set rarity label and border color
	var rarity = enhancement.get("rarity", "common")
	rarity_label.text = rarity.to_upper()

	var border_color = _get_rarity_color(rarity)
	var style = get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style.border_color = border_color

	# Update rarity label color
	rarity_label.add_theme_color_override("font_color", border_color)

	# Show penalty if exists
	if enhancement.has("penalty"):
		var penalty = enhancement.get("penalty", {})
		var penalty_text = _format_penalty(penalty)
		if not penalty_text.is_empty():
			penalty_label.text = penalty_text
			penalty_label.visible = true

func _get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common":
			return Color(0.7, 0.7, 0.7)  # Gray
		"rare":
			return Color(0.3, 0.6, 1.0)  # Blue
		"legendary":
			return Color(1.0, 0.6, 0.0)  # Orange/Gold
		_:
			return Color(0.5, 0.5, 0.6)

func _format_penalty(penalty: Dictionary) -> String:
	var penalty_type = penalty.get("type", "")
	var stat = penalty.get("stat", "")
	var value = penalty.get("value", 0)
	var value_type = penalty.get("value_type", "flat")

	var stat_name = stat.capitalize()
	var value_str = str(value)
	if value_type == "percent":
		value_str += "%"

	return "Penalty: -" + value_str + " " + stat_name

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
			enhancement_selected.emit(enhancement_data)

func _mouse_enter() -> void:
	if is_interactive:
		# Scale up slightly on hover
		create_tween().tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
		modulate = Color(1.2, 1.2, 1.2)

func _mouse_exit() -> void:
	if is_interactive:
		create_tween().tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
		modulate = Color.WHITE
