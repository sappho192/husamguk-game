extends Node

# Preload core classes
const Unit = preload("res://src/core/unit.gd")
const General = preload("res://src/core/general.gd")
const Card = preload("res://src/core/card.gd")

# Data storage
var generals: Dictionary = {}      # id → general_data
var units: Dictionary = {}          # id → unit_data
var cards: Dictionary = {}          # id → card_data (Phase 2)
var localization: Dictionary = {}   # locale → (key → string)

func _ready() -> void:
	_load_all_data()

func _load_all_data() -> void:
	print("DataManager: Loading game data...")
	_load_generals()
	_load_units()
	_load_cards()
	_load_localization()
	print("DataManager: Data loading complete")
	print("  - Generals loaded: ", generals.size())
	print("  - Units loaded: ", units.size())
	print("  - Cards loaded: ", cards.size())
	print("  - Localization locales: ", localization.keys())

func _load_generals() -> void:
	var general_files = ["hubaekje.yaml", "taebong.yaml", "silla.yaml"]
	for file_name in general_files:
		var path = "res://data/generals/" + file_name
		_load_yaml_list(path, "generals", generals)

func _load_units() -> void:
	var path = "res://data/units/base_units.yaml"
	_load_yaml_list(path, "units", units)

func _load_cards() -> void:
	# Phase 2: Load card data
	var card_files = ["starter_deck.yaml", "advanced_cards.yaml"]
	for file_name in card_files:
		var path = "res://data/cards/" + file_name
		_load_yaml_list(path, "cards", cards)

func _load_localization() -> void:
	var locale_files = ["ko.yaml", "en.yaml"]
	for file_name in locale_files:
		var path = "res://data/localization/" + file_name
		var data = _parse_yaml_file(path)
		if data.is_empty():
			continue

		var locale = data.get("locale", "")
		var strings = data.get("strings", {})
		if not locale.is_empty():
			localization[locale] = strings
			print("  Loaded localization: ", locale, " (", strings.size(), " strings)")

func _load_yaml_list(path: String, key: String, target_dict: Dictionary) -> void:
	var data = _parse_yaml_file(path)
	if data.is_empty():
		return

	var items = data.get(key, [])
	for item in items:
		var id = item.get("id", "")
		if not id.is_empty():
			target_dict[id] = item

func _parse_yaml_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("DataManager: File not found: " + path)
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DataManager: Failed to open file: " + path)
		return {}

	var content = file.get_as_text()
	file.close()

	# Use godot-yaml addon to parse
	var result = YAML.parse(content)

	if result.has_error():
		push_error("DataManager: YAML parse error in " + path + ": " + str(result.get_error()))
		return {}

	return result.get_data()

# Data query API
func get_general(id: String) -> Dictionary:
	return generals.get(id, {})

func get_unit(id: String) -> Dictionary:
	return units.get(id, {})

func get_card(id: String) -> Dictionary:
	return cards.get(id, {})

func get_localized(key: String) -> String:
	var locale = TranslationServer.get_locale().substr(0, 2)  # "ko", "en"
	var strings = localization.get(locale, {})
	var translated = strings.get(key, "")

	# Fallback to English if not found in current locale
	if translated.is_empty() and locale != "en":
		strings = localization.get("en", {})
		translated = strings.get(key, "")

	# Fallback to key itself if not found anywhere
	if translated.is_empty():
		return key

	return translated

# Factory method to create unit instances
func create_unit_instance(unit_id: String, is_ally: bool, general: General = null) -> Unit:
	var unit_data = get_unit(unit_id)
	if unit_data.is_empty():
		push_error("DataManager: Unit not found: " + unit_id)
		return null

	# Create a copy and localize the name
	var data_copy = unit_data.duplicate(true)
	data_copy["name_key"] = get_localized(data_copy.get("name_key", unit_id))

	var unit = Unit.new(data_copy)
	unit.is_ally = is_ally
	unit.general = general  # Phase 2: Assign general for skill execution
	return unit

# Factory method to create general instances
func create_general_instance(general_id: String) -> General:
	var general_data = get_general(general_id)
	if general_data.is_empty():
		push_error("DataManager: General not found: " + general_id)
		return null

	# Create a copy and localize the name
	var data_copy = general_data.duplicate(true)
	data_copy["name_key"] = get_localized(data_copy.get("name_key", general_id))

	return General.new(data_copy)

# Factory method to create card instances (Phase 2)
func create_card_instance(card_id: String) -> Card:
	var card_data = get_card(card_id)
	if card_data.is_empty():
		push_error("DataManager: Card not found: " + card_id)
		return null

	# Create a copy and localize strings
	var data_copy = card_data.duplicate(true)
	data_copy["name_key"] = get_localized(data_copy.get("name_key", card_id))
	data_copy["description_key"] = get_localized(data_copy.get("description_key", ""))

	return Card.new(data_copy)
