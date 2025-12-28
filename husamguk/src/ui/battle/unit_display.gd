class_name UnitDisplay
extends VBoxContainer

var unit: Unit

# Child nodes
var name_label: Label
var sprite_container: Control
var hp_bar: ProgressBar
var atb_bar: ProgressBar

func _init() -> void:
	# Create UI elements immediately
	_create_ui()

func _create_ui() -> void:
	# Name label
	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(name_label)

	# Sprite container
	sprite_container = Control.new()
	sprite_container.custom_minimum_size = Vector2(64, 64)
	add_child(sprite_container)

	# HP bar
	hp_bar = ProgressBar.new()
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(80, 16)
	add_child(hp_bar)

	# ATB bar
	atb_bar = ProgressBar.new()
	atb_bar.show_percentage = false
	atb_bar.custom_minimum_size = Vector2(80, 12)
	add_child(atb_bar)

	# Style bars
	var hp_style = StyleBoxFlat.new()
	hp_style.bg_color = Color.DARK_GREEN
	hp_bar.add_theme_stylebox_override("fill", hp_style)

	var atb_style = StyleBoxFlat.new()
	atb_style.bg_color = Color.GOLD
	atb_bar.add_theme_stylebox_override("fill", atb_style)

func setup(unit_instance: Unit) -> void:
	unit = unit_instance

	# Connect signals
	unit.took_damage.connect(_on_unit_took_damage)
	unit.died.connect(_on_unit_died)

	# Initialize UI
	name_label.text = unit.display_name
	hp_bar.max_value = unit.max_hp
	hp_bar.value = unit.current_hp
	atb_bar.max_value = unit.atb_max
	atb_bar.value = 0

	# Generate placeholder sprite
	_create_placeholder_sprite()

func _process(_delta: float) -> void:
	if unit:
		atb_bar.value = unit.atb_current

func _create_placeholder_sprite() -> void:
	var placeholder = PlaceholderSprite.new()
	placeholder.setup(unit.category, unit.id)
	sprite_container.add_child(placeholder)

func _on_unit_took_damage(_amount: int, current_hp: int) -> void:
	hp_bar.value = current_hp

func _on_unit_died() -> void:
	modulate = Color(0.5, 0.5, 0.5, 0.5)  # Gray out
