extends Control

# Fateful Encounter UI Controller
# Phase 3D - Replaces Enhancement Selection with narrative NPC encounters

# Preload UI components
const NPCPortraitDisplay = preload("res://src/ui/fateful_encounter/npc_portrait_display.gd")
const EnhancementCard = preload("res://src/ui/enhancement/enhancement_card.gd")

# UI Elements
var title_label: Label
var npc_display: NPCPortraitDisplay
var card_container: HBoxContainer
var enhancement_cards: Array[EnhancementCard] = []

# Current encounter data
var current_npc: Dictionary = {}

func _ready() -> void:
	# Create UI
	_create_ui()

	# Show fateful encounter
	_show_encounter()

func _create_ui() -> void:
	# Background
	var background = ColorRect.new()
	background.color = Color(0.1, 0.1, 0.15, 1.0)
	background.z_index = -1
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	# Main vertical container
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 30)
	add_child(main_vbox)

	# Top spacer
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 10)
	main_vbox.add_child(top_spacer)

	# Title
	title_label = Label.new()
	title_label.text = DataManager.get_localized("UI_FATEFUL_ENCOUNTER_TITLE")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	main_vbox.add_child(title_label)

	# NPC Portrait Display (horizontal layout: portrait left, info right)
	# Wrap in MarginContainer for side padding
	var npc_margin = MarginContainer.new()
	npc_margin.add_theme_constant_override("margin_left", 100)
	npc_margin.add_theme_constant_override("margin_right", 100)
	main_vbox.add_child(npc_margin)

	npc_display = NPCPortraitDisplay.new()
	npc_margin.add_child(npc_display)

	# Spacer before cards
	var middle_spacer = Control.new()
	middle_spacer.custom_minimum_size = Vector2(0, 30)
	main_vbox.add_child(middle_spacer)

	# Enhancement cards container
	card_container = HBoxContainer.new()
	card_container.alignment = BoxContainer.ALIGNMENT_CENTER
	card_container.add_theme_constant_override("separation", 30)
	main_vbox.add_child(card_container)

	# Bottom spacer
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 40)
	main_vbox.add_child(bottom_spacer)

func _show_encounter() -> void:
	# Select random NPC
	current_npc = DataManager.get_random_npc()
	if current_npc.is_empty():
		push_error("FatefulEncounterUI: No NPC data available!")
		return

	print("FatefulEncounterUI: Encountered ", current_npc.get("id", "unknown"))

	# Display NPC
	npc_display.setup(current_npc)

	# Get themed enhancements
	var choices = _get_themed_enhancements()
	print("FatefulEncounterUI: Showing ", choices.size(), " themed enhancement choices")

	# Create enhancement cards
	for enhancement in choices:
		var card = EnhancementCard.new()
		card.setup(enhancement)
		card.enhancement_selected.connect(_on_enhancement_selected)
		card_container.add_child(card)
		enhancement_cards.append(card)

func _get_themed_enhancements() -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var themes = current_npc.get("enhancement_themes", [])

	# Get themed enhancements for each rarity
	var common_pool = DataManager.get_enhancements_by_themes(themes, "common")
	var rare_pool = DataManager.get_enhancements_by_themes(themes, "rare")
	var legendary_pool = DataManager.get_enhancements_by_themes(themes, "legendary")

	# Fallback to random selection if theme pool is empty
	if common_pool.is_empty():
		print("FatefulEncounterUI: No themed common enhancements, using random selection")
		common_pool = DataManager.get_enhancements_by_rarity("common")

	if rare_pool.is_empty():
		print("FatefulEncounterUI: No themed rare enhancements, using random selection")
		rare_pool = DataManager.get_enhancements_by_rarity("rare")

	if legendary_pool.is_empty():
		print("FatefulEncounterUI: No themed legendary enhancements, using random selection")
		legendary_pool = DataManager.get_enhancements_by_rarity("legendary")

	# Select 1 from each pool
	if not common_pool.is_empty():
		common_pool.shuffle()
		choices.append(common_pool[0])

	if not rare_pool.is_empty():
		rare_pool.shuffle()
		choices.append(rare_pool[0])

	if not legendary_pool.is_empty():
		legendary_pool.shuffle()
		choices.append(legendary_pool[0])

	# If we have less than 3 choices, log error
	if choices.size() < 3:
		push_error("FatefulEncounterUI: Failed to get 3 enhancement choices!")

	return choices

func _on_enhancement_selected(enhancement_data: Dictionary) -> void:
	print("FatefulEncounterUI: Enhancement selected: ", enhancement_data.get("id", "unknown"))

	# Disable all cards
	for card in enhancement_cards:
		card.set_interactive(false)

	# Wait briefly for visual feedback
	await get_tree().create_timer(0.5).timeout

	# Check if still in tree (user might have changed scenes)
	if not is_inside_tree():
		return

	# Notify GameManager
	if GameManager:
		GameManager.on_enhancement_selected(enhancement_data)
	else:
		push_error("FatefulEncounterUI: GameManager not found!")
