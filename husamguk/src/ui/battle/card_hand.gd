class_name CardHand
extends PanelContainer

# Preload dependencies
const Card = preload("res://src/core/card.gd")
const CardDisplay = preload("res://src/ui/battle/card_display.gd")

signal card_selected(card: Card)

var hand: Array[Card] = []
var card_displays: Array[CardDisplay] = []
var card_container: HBoxContainer

func _init() -> void:
	# Full screen overlay
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Semi-transparent dark background overlay
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.0, 0.0, 0.0, 0.85)  # More opaque for better focus
	add_theme_stylebox_override("panel", bg_style)

	# Main container for card layout
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(main_vbox)

	# Add spacer to push cards to center
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 0)
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(top_spacer)

	# Title label
	var title_label = Label.new()
	title_label.text = "전략 카드 선택"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	main_vbox.add_child(title_label)

	# Spacer between title and cards
	main_vbox.add_child(_create_spacer(40))

	# Card container (horizontal)
	card_container = HBoxContainer.new()
	card_container.alignment = BoxContainer.ALIGNMENT_CENTER
	card_container.add_theme_constant_override("separation", 20)
	main_vbox.add_child(card_container)

	# Add bottom spacer to center cards vertically
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 0)
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(bottom_spacer)

	# Start hidden
	visible = false

func _create_spacer(height: int) -> Control:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer

func add_card(card: Card) -> void:
	if hand.size() >= 5:
		push_warning("CardHand: Hand is full (max 5 cards)")
		return

	hand.append(card)
	_update_display()

func remove_card(card: Card) -> void:
	hand.erase(card)
	_update_display()

func clear_hand() -> void:
	hand.clear()
	_update_display()

func _update_display() -> void:
	# Clear existing displays
	for display in card_displays:
		display.queue_free()
	card_displays.clear()

	# Create new displays
	for card in hand:
		var display = CardDisplay.new()
		display.setup(card)
		display.card_clicked.connect(_on_card_clicked)
		card_container.add_child(display)
		card_displays.append(display)

func _on_card_clicked(card: Card) -> void:
	card_selected.emit(card)

func set_interactive(enabled: bool) -> void:
	for display in card_displays:
		display.set_interactive(enabled)
