extends Node

# Preload core classes
const Unit = preload("res://src/core/unit.gd")
const General = preload("res://src/core/general.gd")
const Card = preload("res://src/core/card.gd")
const BattleMap = preload("res://src/core/battle_map.gd")
const TerrainTile = preload("res://src/core/terrain_tile.gd")
const Corps = preload("res://src/core/corps.gd")
const Formation = preload("res://src/core/formation.gd")

# Data storage
var generals: Dictionary = {}      # id → general_data
var units: Dictionary = {}          # id → unit_data
var cards: Dictionary = {}          # id → card_data (Phase 2)
var events: Dictionary = {}         # id → event_data (Phase 3)
var enhancements: Dictionary = {}   # id → enhancement_data (Phase 3)
var npcs: Dictionary = {}           # id → npc_data (Phase 3D - Fateful Encounter)
var battles: Dictionary = {}        # id → battle_data (Phase 4 - Wave system)
var terrains: Dictionary = {}       # id → terrain_data (Phase 5A - Terrain system)
var maps: Dictionary = {}           # id → map_data (Phase 5A - Terrain system)
var corps_templates: Dictionary = {} # id → corps_data (Phase 5B - Corps system)
var formations: Dictionary = {}     # id → formation_data (Phase 5B - Corps system)
var localization: Dictionary = {}   # locale → (key → string)

func _ready() -> void:
	_load_all_data()

func _load_all_data() -> void:
	print("DataManager: Loading game data...")
	_load_terrains()  # Phase 5A: Load terrains first (needed by maps)
	_load_maps()      # Phase 5A: Load battle maps
	_load_formations()  # Phase 5B: Load formations before corps
	_load_corps()       # Phase 5B: Load corps templates
	_load_generals()
	_load_units()
	_load_cards()
	_load_events()
	_load_enhancements()
	_load_npcs()
	_load_battles()
	_load_localization()
	print("DataManager: Data loading complete")
	print("  - Terrains loaded: ", terrains.size())
	print("  - Maps loaded: ", maps.size())
	print("  - Formations loaded: ", formations.size())
	print("  - Corps templates loaded: ", corps_templates.size())
	print("  - Generals loaded: ", generals.size())
	print("  - Units loaded: ", units.size())
	print("  - Cards loaded: ", cards.size())
	print("  - Events loaded: ", events.size())
	print("  - Enhancements loaded: ", enhancements.size())
	print("  - NPCs loaded: ", npcs.size())
	print("  - Battles loaded: ", battles.size())
	print("  - Localization locales: ", localization.keys())

func _load_terrains() -> void:
	# Phase 5A: Load terrain data
	var terrain_files = ["base_terrain.yaml"]
	for file_name in terrain_files:
		var path = "res://data/terrain/" + file_name
		_load_yaml_list(path, "terrains", terrains)

func _load_maps() -> void:
	# Phase 5A: Load battle map data
	var map_files = ["stage_maps.yaml"]
	for file_name in map_files:
		var path = "res://data/maps/" + file_name
		_load_yaml_list(path, "maps", maps)

func _load_formations() -> void:
	# Phase 5B: Load formation data
	var formation_files = ["base_formations.yaml"]
	for file_name in formation_files:
		var path = "res://data/formations/" + file_name
		_load_yaml_list(path, "formations", formations)

func _load_corps() -> void:
	# Phase 5B: Load corps template data
	var corps_files = ["base_corps.yaml"]
	for file_name in corps_files:
		var path = "res://data/corps/" + file_name
		_load_yaml_list(path, "corps", corps_templates)

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

func _load_events() -> void:
	# Phase 3: Load event data
	var event_files = [
		"military_events.yaml",
		"economic_events.yaml",
		"diplomatic_events.yaml",
		"personnel_events.yaml"
	]
	for file_name in event_files:
		var path = "res://data/events/" + file_name
		_load_yaml_list(path, "events", events)

func _load_enhancements() -> void:
	# Phase 3: Load enhancement data
	var enhancement_files = ["combat_enhancements.yaml"]
	for file_name in enhancement_files:
		var path = "res://data/enhancements/" + file_name
		_load_yaml_list(path, "enhancements", enhancements)

func _load_npcs() -> void:
	# Phase 3D: Load NPC data (Fateful Encounter system)
	var npc_files = ["fateful_encounter_npcs.yaml"]
	for file_name in npc_files:
		var path = "res://data/npcs/" + file_name
		_load_yaml_list(path, "npcs", npcs)

func _load_battles() -> void:
	# Phase 4: Load battle data (Wave system)
	var battle_files = ["stage_battles.yaml"]
	for file_name in battle_files:
		var path = "res://data/battles/" + file_name
		_load_yaml_list(path, "battles", battles)

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

func get_event(id: String) -> Dictionary:
	return events.get(id, {})

func get_events_by_category(category: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event_data in events.values():
		if event_data.get("category", "") == category:
			result.append(event_data.duplicate(true))
	return result

func get_enhancement(id: String) -> Dictionary:
	return enhancements.get(id, {})

func get_enhancements_by_rarity(rarity: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for enhancement_data in enhancements.values():
		if enhancement_data.get("rarity", "") == rarity:
			result.append(enhancement_data.duplicate(true))
	return result

func get_enhancements_by_themes(themes: Array, rarity: String) -> Array[Dictionary]:
	# Phase 3D: Filter enhancements by themes and rarity for Fateful Encounter
	var result: Array[Dictionary] = []
	for enhancement_data in enhancements.values():
		# Check rarity match
		if enhancement_data.get("rarity", "") != rarity:
			continue

		# Check if enhancement has at least one matching theme
		var enh_themes = enhancement_data.get("themes", [])
		var has_matching_theme = false
		for theme in themes:
			if theme in enh_themes:
				has_matching_theme = true
				break

		if has_matching_theme:
			result.append(enhancement_data.duplicate(true))

	return result

func get_npc(id: String) -> Dictionary:
	return npcs.get(id, {})

func get_random_npc() -> Dictionary:
	# Phase 3D: Select a random NPC for Fateful Encounter
	var npc_list = npcs.values()
	if npc_list.is_empty():
		push_error("DataManager: No NPCs loaded!")
		return {}

	# Shuffle and return first NPC
	npc_list.shuffle()
	return npc_list[0].duplicate(true)

func get_battle(id: String) -> Dictionary:
	# Phase 4: Get battle definition by ID
	return battles.get(id, {})

# Phase 5A: Terrain and Map API

func get_terrain(id: String) -> Dictionary:
	# Get terrain data by ID
	return terrains.get(id, {})

func get_all_terrains() -> Dictionary:
	# Return all terrain data (for building char_code map)
	return terrains

func get_map(id: String) -> Dictionary:
	# Get battle map data by ID
	return maps.get(id, {})

func get_all_maps() -> Dictionary:
	# Return all map data
	return maps

# Phase 5B: Corps and Formation API

func get_formation(id: String) -> Dictionary:
	# Get formation data by ID
	return formations.get(id, {})

func get_all_formations() -> Dictionary:
	# Return all formation data
	return formations

func get_corps_template(id: String) -> Dictionary:
	# Get corps template data by ID
	return corps_templates.get(id, {})

func get_all_corps_templates() -> Dictionary:
	# Return all corps template data
	return corps_templates

func get_corps_templates_by_category(category: String) -> Array[Dictionary]:
	# Get all corps templates for a specific category
	var result: Array[Dictionary] = []
	for template in corps_templates.values():
		if template.get("category", "") == category:
			result.append(template.duplicate(true))
	return result

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

# Factory method to create terrain tile instances (Phase 5A)
func create_terrain_instance(terrain_id: String) -> TerrainTile:
	var terrain_data = get_terrain(terrain_id)
	if terrain_data.is_empty():
		push_error("DataManager: Terrain not found: " + terrain_id)
		return null

	var data_copy = terrain_data.duplicate(true)
	return TerrainTile.new(data_copy)

# Factory method to create battle map instances (Phase 5A)
func create_battle_map(map_id: String) -> BattleMap:
	var map_data = get_map(map_id)
	if map_data.is_empty():
		push_error("DataManager: Map not found: " + map_id)
		return null

	var data_copy = map_data.duplicate(true)
	return BattleMap.new(data_copy)

# Factory method to create formation instances (Phase 5B)
func create_formation_instance(formation_id: String) -> Formation:
	var formation_data = get_formation(formation_id)
	if formation_data.is_empty():
		push_error("DataManager: Formation not found: " + formation_id)
		return null

	var data_copy = formation_data.duplicate(true)
	return Formation.new(data_copy)

# Factory method to create corps instances (Phase 5B)
func create_corps_instance(corps_template_id: String, is_ally: bool, assigned_general: General = null) -> Corps:
	var corps_data = get_corps_template(corps_template_id)
	if corps_data.is_empty():
		push_error("DataManager: Corps template not found: " + corps_template_id)
		return null

	var data_copy = corps_data.duplicate(true)
	var corps = Corps.new(data_copy, assigned_general)
	corps.is_ally = is_ally
	return corps
