extends Control

# Preload UI components
const EnhancementCard = preload("res://src/ui/enhancement/enhancement_card.gd")

# UI Elements
var title_label: Label
var subtitle_label: Label
var card_container: HBoxContainer
var enhancement_cards: Array[EnhancementCard] = []

func _ready() -> void:
	# Create UI
	_create_ui()

	# Show enhancement choices
	_show_enhancement_choices()

func _create_ui() -> void:
	# Main vertical container
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 30)
	add_child(main_vbox)

	# Title section
	var title_container = VBoxContainer.new()
	title_container.add_theme_constant_override("separation", 5)
	main_vbox.add_child(title_container)

	# Title
	title_label = Label.new()
	title_label.text = DataManager.get_localized("UI_ENHANCEMENT_TITLE")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_container.add_child(title_label)

	# Subtitle
	subtitle_label = Label.new()
	subtitle_label.text = DataManager.get_localized("UI_ENHANCEMENT_SUBTITLE")
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 18)
	subtitle_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	title_container.add_child(subtitle_label)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 50)
	main_vbox.add_child(spacer)

	# Enhancement cards container
	card_container = HBoxContainer.new()
	card_container.alignment = BoxContainer.ALIGNMENT_CENTER
	card_container.add_theme_constant_override("separation", 40)
	main_vbox.add_child(card_container)

	# Bottom spacer to center vertically
	var bottom_spacer = Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(bottom_spacer)

func _show_enhancement_choices() -> void:
	# Get 3 random enhancements (1 common, 1 rare, 1 legendary)
	var choices = _get_random_enhancements()
	print("EnhancementSelectionUI: Showing ", choices.size(), " enhancement choices")

	# Create enhancement cards
	for enhancement in choices:
		var card = EnhancementCard.new()
		card.setup(enhancement)
		card.enhancement_selected.connect(_on_enhancement_selected)
		card_container.add_child(card)
		enhancement_cards.append(card)

func _get_random_enhancements() -> Array[Dictionary]:
	var choices: Array[Dictionary] = []

	# Get 1 common enhancement
	var common_enhancements = DataManager.get_enhancements_by_rarity("common")
	if not common_enhancements.is_empty():
		common_enhancements.shuffle()
		choices.append(common_enhancements[0])

	# Get 1 rare enhancement
	var rare_enhancements = DataManager.get_enhancements_by_rarity("rare")
	if not rare_enhancements.is_empty():
		rare_enhancements.shuffle()
		choices.append(rare_enhancements[0])

	# Get 1 legendary enhancement
	var legendary_enhancements = DataManager.get_enhancements_by_rarity("legendary")
	if not legendary_enhancements.is_empty():
		legendary_enhancements.shuffle()
		choices.append(legendary_enhancements[0])

	return choices

func _on_enhancement_selected(enhancement_data: Dictionary) -> void:
	print("EnhancementSelectionUI: Enhancement selected: ", enhancement_data.get("id", "unknown"))

	# Disable all cards
	for card in enhancement_cards:
		card.set_interactive(false)

	# Wait a moment for visual feedback (only if scene is still valid)
	if is_inside_tree():
		await get_tree().create_timer(0.5).timeout

	# Notify GameManager (check again after await)
	if is_inside_tree():
		GameManager.on_enhancement_selected(enhancement_data)
