class_name PlaceholderSprite
extends ColorRect

var unit_category: String = "infantry"
var unit_id: String = ""

func setup(category: String, id: String) -> void:
	unit_category = category
	unit_id = id
	_generate_placeholder()

func _generate_placeholder() -> void:
	# Set size
	custom_minimum_size = Vector2(64, 64)

	# Determine color by category
	color = _get_color_by_category(unit_category)

	# Add label
	var label = Label.new()
	label.text = _get_abbreviation(unit_id)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 16)
	add_child(label)

func _get_color_by_category(category: String) -> Color:
	match category:
		"infantry":
			return Color.STEEL_BLUE
		"cavalry":
			return Color.DARK_RED
		"archer":
			return Color.DARK_GREEN
		"special":
			return Color.PURPLE
		_:
			return Color.GRAY

func _get_abbreviation(id: String) -> String:
	# Get first 3 letters in uppercase
	return id.to_upper().substr(0, 3)
