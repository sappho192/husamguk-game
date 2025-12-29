extends Control

# Preload UI components
const ChoiceButton = preload("res://src/ui/internal_affairs/choice_button.gd")
const InternalAffairsManager = preload("res://src/systems/internal_affairs/internal_affairs_manager.gd")

var ia_manager: InternalAffairsManager

# UI Elements
var title_label: Label
var subtitle_label: Label
var choices_remaining_label: Label
var choice_container: HBoxContainer
var choice_buttons: Array[ChoiceButton] = []

func _ready() -> void:
	# Create Internal Affairs Manager
	ia_manager = InternalAffairsManager.new()
	add_child(ia_manager)

	# Connect signals
	ia_manager.event_selected.connect(_on_event_selected)
	ia_manager.internal_affairs_completed.connect(_on_internal_affairs_completed)

	# Create UI
	_create_ui()

	# Start first choice round
	_show_next_choices()

func _create_ui() -> void:
	# Main vertical container
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 20)
	add_child(main_vbox)

	# Title section
	var title_container = VBoxContainer.new()
	title_container.add_theme_constant_override("separation", 5)
	main_vbox.add_child(title_container)

	# Title
	title_label = Label.new()
	title_label.text = DataManager.get_localized("UI_INTERNAL_AFFAIRS_TITLE")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_container.add_child(title_label)

	# Subtitle
	subtitle_label = Label.new()
	subtitle_label.text = DataManager.get_localized("UI_INTERNAL_AFFAIRS_SUBTITLE")
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 18)
	subtitle_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	title_container.add_child(subtitle_label)

	# Choices remaining label
	choices_remaining_label = Label.new()
	choices_remaining_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choices_remaining_label.add_theme_font_size_override("font_size", 16)
	_update_choices_remaining()
	title_container.add_child(choices_remaining_label)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 50)
	main_vbox.add_child(spacer)

	# Choice buttons container
	choice_container = HBoxContainer.new()
	choice_container.alignment = BoxContainer.ALIGNMENT_CENTER
	choice_container.add_theme_constant_override("separation", 30)
	main_vbox.add_child(choice_container)

	# Bottom spacer to center vertically
	var bottom_spacer = Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(bottom_spacer)

func _show_next_choices() -> void:
	# Clear existing choice buttons
	for button in choice_buttons:
		button.queue_free()
	choice_buttons.clear()

	# Get new choices from manager
	var choices = ia_manager.get_next_choices()
	print("InternalAffairsUI: Showing ", choices.size(), " choices")

	# Create choice buttons
	for choice in choices:
		var button = ChoiceButton.new()
		button.setup(choice)
		button.choice_selected.connect(_on_choice_selected)
		choice_container.add_child(button)
		choice_buttons.append(button)

func _on_choice_selected(event_data: Dictionary) -> void:
	print("InternalAffairsUI: Choice selected: ", event_data.get("id", "unknown"))

	# Disable all buttons
	for button in choice_buttons:
		button.set_interactive(false)

	# Execute event
	ia_manager.execute_event(event_data)

	# Wait a moment, then show next choices or complete
	# (Only if this isn't the final choice and scene hasn't changed)
	if ia_manager.choices_made < InternalAffairsManager.CHOICES_PER_PHASE:
		if is_inside_tree():
			await get_tree().create_timer(1.0).timeout

		# Check again after await in case scene changed
		if is_inside_tree():
			_update_choices_remaining()
			_show_next_choices()

func _on_event_selected(event_data: Dictionary) -> void:
	print("InternalAffairsUI: Event executed: ", event_data.get("id", "unknown"))

func _on_internal_affairs_completed() -> void:
	print("InternalAffairsUI: Internal Affairs completed!")
	# Notify GameManager
	GameManager.on_internal_affairs_completed()

func _update_choices_remaining() -> void:
	var remaining = InternalAffairsManager.CHOICES_PER_PHASE - ia_manager.choices_made
	choices_remaining_label.text = DataManager.get_localized("UI_CHOICES_REMAINING") + ": " + str(remaining) + "/" + str(InternalAffairsManager.CHOICES_PER_PHASE)
