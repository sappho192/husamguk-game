class_name CardDisplay
extends PanelContainer

# Preload dependencies
const Card = preload("res://src/core/card.gd")

signal card_clicked(card: Card)

var card: Card
var is_interactive: bool = false

# UI References
var name_label: Label
var rarity_indicator: ColorRect
var desc_label: Label

func _init() -> void:
	custom_minimum_size = Vector2(120, 180)
	_create_ui()

func _create_ui() -> void:
	# Main VBox
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	add_child(vbox)

	# Card name
	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(100, 0)
	vbox.add_child(name_label)

	# Rarity color indicator
	rarity_indicator = ColorRect.new()
	rarity_indicator.custom_minimum_size = Vector2(100, 4)
	vbox.add_child(rarity_indicator)

	# Spacer for icon (placeholder)
	var icon_spacer = Control.new()
	icon_spacer.custom_minimum_size = Vector2(64, 64)
	vbox.add_child(icon_spacer)

	# Description
	desc_label = Label.new()
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(100, 0)
	desc_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(desc_label)

	# Default style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.GRAY
	add_theme_stylebox_override("panel", style)

func setup(card_instance: Card) -> void:
	card = card_instance

	# Set card name
	name_label.text = card.display_name

	# Set description
	desc_label.text = card.description

	# Set rarity color
	rarity_indicator.color = card.get_rarity_color()

	# Update border color based on rarity
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = card.get_rarity_color()
	add_theme_stylebox_override("panel", style)

func set_interactive(enabled: bool) -> void:
	is_interactive = enabled
	mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE

	# Visual feedback
	if enabled:
		modulate = Color.WHITE
	else:
		modulate = Color(0.7, 0.7, 0.7)

func _gui_input(event: InputEvent) -> void:
	if not is_interactive:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			card_clicked.emit(card)

func _mouse_enter() -> void:
	if is_interactive:
		# Highlight on hover
		modulate = Color(1.2, 1.2, 1.2)

func _mouse_exit() -> void:
	if is_interactive:
		modulate = Color.WHITE
