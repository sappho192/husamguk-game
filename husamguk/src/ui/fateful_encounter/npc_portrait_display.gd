extends HBoxContainer

# NPC Portrait Display Component
# Phase 3D - Fateful Encounter System
# Displays NPC portrait (left) and info (right) in horizontal layout

var npc_data: Dictionary = {}

# UI Elements (created in _init)
var portrait_container: PanelContainer
var portrait_placeholder: ColorRect
var info_container: VBoxContainer
var name_title_container: VBoxContainer
var name_label: Label
var title_label: Label
var dialogue_label: Label

func _init() -> void:
	name = "NPCPortraitDisplay"
	add_theme_constant_override("separation", 20)
	alignment = ALIGNMENT_BEGIN

	# Left side: Portrait
	portrait_container = PanelContainer.new()
	portrait_container.custom_minimum_size = Vector2(150, 150)
	add_child(portrait_container)

	# Portrait placeholder (colored rectangle with initial)
	portrait_placeholder = ColorRect.new()
	portrait_placeholder.custom_minimum_size = Vector2(150, 150)
	portrait_container.add_child(portrait_placeholder)

	# Right side: Info container
	info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_container.add_theme_constant_override("separation", 10)
	add_child(info_container)

	# Name and title container
	name_title_container = VBoxContainer.new()
	name_title_container.add_theme_constant_override("separation", 5)
	info_container.add_child(name_title_container)

	# NPC name label
	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.add_theme_font_size_override("font_size", 28)
	name_title_container.add_child(name_label)

	# NPC title label
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.add_theme_font_size_override("font_size", 16)
	name_title_container.add_child(title_label)

	# Dialogue label (combines greeting, dialogue, and offer)
	dialogue_label = Label.new()
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_font_size_override("font_size", 14)
	dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_container.add_child(dialogue_label)

func _ready() -> void:
	# Apply styling in _ready after DataManager is loaded
	if not npc_data.is_empty():
		_apply_npc_data()

func setup(npc_dict: Dictionary) -> void:
	npc_data = npc_dict.duplicate(true)

	if is_inside_tree():
		_apply_npc_data()

func _apply_npc_data() -> void:
	# Get localized strings
	var npc_name = DataManager.get_localized(npc_data.get("name_key", ""))
	var npc_title = DataManager.get_localized(npc_data.get("title_key", ""))
	var npc_greeting = DataManager.get_localized(npc_data.get("greeting_key", ""))
	var npc_dialogue = DataManager.get_localized(npc_data.get("dialogue_key", ""))
	var npc_offer = DataManager.get_localized(npc_data.get("offer_key", ""))

	# Set text
	name_label.text = npc_name
	title_label.text = npc_title

	# Combine all dialogue into one text block
	var full_dialogue = npc_greeting + "\n\n" + npc_dialogue + "\n\n" + npc_offer
	dialogue_label.text = full_dialogue

	# Set portrait color
	var bg_color = npc_data.get("background_color", "#4A7C59")
	portrait_placeholder.color = Color(bg_color)

	# Add first character of NPC name as placeholder portrait
	if not npc_name.is_empty():
		var initial_label = Label.new()
		initial_label.text = npc_name.substr(0, 1)
		initial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		initial_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		initial_label.add_theme_font_size_override("font_size", 64)
		initial_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		portrait_placeholder.add_child(initial_label)

	# Style portrait container
	var style = StyleBoxFlat.new()
	style.bg_color = Color(bg_color, 0.3)
	style.border_color = Color(bg_color)
	style.set_border_width_all(4)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	portrait_container.add_theme_stylebox_override("panel", style)

	# Style labels
	title_label.modulate = Color(0.7, 0.7, 0.7)  # Muted gray
