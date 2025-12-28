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
	custom_minimum_size = Vector2(0, 200)

	# Add background style
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	bg_style.border_width_top = 2
	bg_style.border_color = Color(0.6, 0.6, 0.7)
	add_theme_stylebox_override("panel", bg_style)

	# Create inner HBoxContainer for cards
	card_container = HBoxContainer.new()
	card_container.alignment = BoxContainer.ALIGNMENT_CENTER
	card_container.add_theme_constant_override("separation", 10)
	add_child(card_container)

	# Don't set anchors in init - parent will handle positioning

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
