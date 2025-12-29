extends Control

# UI Elements
var title_label: Label
var subtitle_label: Label
var start_button: Button
var quit_button: Button

func _init() -> void:
	_create_ui()

func _ready() -> void:
	# Set localized text (DataManager is now ready)
	_set_localized_text()

	# Connect button signals
	start_button.pressed.connect(_on_start_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

func _set_localized_text() -> void:
	title_label.text = DataManager.get_localized("UI_GAME_TITLE")
	subtitle_label.text = DataManager.get_localized("UI_GAME_SUBTITLE")
	start_button.text = DataManager.get_localized("UI_START_NEW_RUN")
	quit_button.text = DataManager.get_localized("UI_QUIT")
	print("MainMenuUI: Text set - Title: ", title_label.text, ", Button: ", start_button.text)
	print("MainMenuUI: UI tree - Children count: ", get_child_count())
	print("MainMenuUI: title_label visible: ", title_label.visible, ", position: ", title_label.global_position)

func _create_ui() -> void:
	print("MainMenuUI: Creating UI elements...")
	# Main vertical container
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 40)
	add_child(main_vbox)
	print("MainMenuUI: Added main_vbox to scene")

	# Top spacer to center vertically
	var top_spacer = Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(top_spacer)

	# Title section
	var title_container = VBoxContainer.new()
	title_container.add_theme_constant_override("separation", 10)
	main_vbox.add_child(title_container)

	# Game title
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 72)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))  # Gold
	title_container.add_child(title_label)
	print("MainMenuUI: Added title_label")

	# Subtitle
	subtitle_label = Label.new()
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 24)
	subtitle_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	title_container.add_child(subtitle_label)

	# Spacer between title and buttons
	var middle_spacer = Control.new()
	middle_spacer.custom_minimum_size = Vector2(0, 80)
	main_vbox.add_child(middle_spacer)

	# Button container
	var button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 20)
	button_container.custom_minimum_size = Vector2(300, 0)
	button_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_vbox.add_child(button_container)

	# Start New Run button
	start_button = Button.new()
	start_button.custom_minimum_size = Vector2(300, 60)
	start_button.add_theme_font_size_override("font_size", 24)
	_style_button(start_button, Color(0.3, 0.6, 0.9))  # Blue
	button_container.add_child(start_button)
	print("MainMenuUI: Added start_button")

	# Quit button
	quit_button = Button.new()
	quit_button.custom_minimum_size = Vector2(300, 60)
	quit_button.add_theme_font_size_override("font_size", 24)
	_style_button(quit_button, Color(0.6, 0.3, 0.3))  # Red
	button_container.add_child(quit_button)

	# Bottom spacer
	var bottom_spacer = Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(bottom_spacer)

func _style_button(button: Button, base_color: Color) -> void:
	# Normal state
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = base_color
	style_normal.corner_radius_top_left = 8
	style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_left = 8
	style_normal.corner_radius_bottom_right = 8
	style_normal.content_margin_left = 20
	style_normal.content_margin_right = 20
	style_normal.content_margin_top = 15
	style_normal.content_margin_bottom = 15
	button.add_theme_stylebox_override("normal", style_normal)

	# Hover state
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = base_color.lightened(0.2)
	style_hover.corner_radius_top_left = 8
	style_hover.corner_radius_top_right = 8
	style_hover.corner_radius_bottom_left = 8
	style_hover.corner_radius_bottom_right = 8
	style_hover.content_margin_left = 20
	style_hover.content_margin_right = 20
	style_hover.content_margin_top = 15
	style_hover.content_margin_bottom = 15
	button.add_theme_stylebox_override("hover", style_hover)

	# Pressed state
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = base_color.darkened(0.2)
	style_pressed.corner_radius_top_left = 8
	style_pressed.corner_radius_top_right = 8
	style_pressed.corner_radius_bottom_left = 8
	style_pressed.corner_radius_bottom_right = 8
	style_pressed.content_margin_left = 20
	style_pressed.content_margin_right = 20
	style_pressed.content_margin_top = 15
	style_pressed.content_margin_bottom = 15
	button.add_theme_stylebox_override("pressed", style_pressed)

func _on_start_button_pressed() -> void:
	print("MainMenu: Starting new run...")
	GameManager.start_new_run()

func _on_quit_button_pressed() -> void:
	print("MainMenu: Quitting game...")
	get_tree().quit()
