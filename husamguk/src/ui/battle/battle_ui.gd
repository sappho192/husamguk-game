extends Control

# Preload UI components
const SkillBar = preload("res://src/ui/battle/skill_bar.gd")
const CardHand = preload("res://src/ui/battle/card_hand.gd")
const Card = preload("res://src/core/card.gd")

@onready var ally_container: HBoxContainer = $AllyContainer
@onready var enemy_container: HBoxContainer = $EnemyContainer
@onready var result_label: Label = $ResultLabel
@onready var battle_bgm: AudioStreamPlayer = $BattleBGM

var battle_manager: BattleManager

# Phase 2: UI Components
var skill_bar: SkillBar
var card_hand: CardHand
var global_turn_bar: ProgressBar

# Phase 2: Card deck management
var deck: Array[Card] = []
var discard_pile: Array[Card] = []

func _ready() -> void:
	# Setup BGM looping
	if battle_bgm and battle_bgm.stream:
		battle_bgm.stream.loop = true

	# Create BattleManager
	battle_manager = BattleManager.new()
	add_child(battle_manager)

	# Connect signals
	battle_manager.battle_started.connect(_on_battle_started)
	battle_manager.battle_ended.connect(_on_battle_ended)
	battle_manager.global_turn_ready.connect(_on_global_turn_ready)

	# Hide result label initially
	result_label.visible = false

	# Phase 2: Create UI components
	_create_phase2_ui()

	# Initialize deck
	_initialize_deck()

	# Start test battle
	_start_test_battle()

func _start_test_battle() -> void:
	# Phase 2: Create generals for testing
	var gyeonhwon = DataManager.create_general_instance("gyeonhwon")
	var wanggeon = DataManager.create_general_instance("wanggeon")
	var singeom = DataManager.create_general_instance("singeom")

	# Create ally units with generals
	var ally_units_data = []
	ally_units_data.append({"id": "spearman", "general": gyeonhwon})
	ally_units_data.append({"id": "archer", "general": wanggeon})
	ally_units_data.append({"id": "swordsman", "general": singeom})

	# Enemy units (no generals for now)
	var enemy_units_data = []
	enemy_units_data.append({"id": "light_cavalry", "general": null})
	enemy_units_data.append({"id": "archer", "general": null})
	enemy_units_data.append({"id": "spearman", "general": null})

	battle_manager.start_battle_with_generals(ally_units_data, enemy_units_data)

func _on_battle_started() -> void:
	print("BattleUI: Battle started, creating unit displays")

	# Create UI for each ally unit
	for unit in battle_manager.ally_units:
		var display = _create_unit_display(unit)
		ally_container.add_child(display)

	# Create UI for each enemy unit
	for unit in battle_manager.enemy_units:
		var display = _create_unit_display(unit)
		enemy_container.add_child(display)

	# Setup skill bar with ally units
	skill_bar.setup(battle_manager.ally_units)

func _create_unit_display(unit: Unit) -> UnitDisplay:
	var display = UnitDisplay.new()
	display.setup(unit)
	return display

func _on_battle_ended(victory: bool) -> void:
	result_label.text = DataManager.get_localized("UI_BATTLE_VICTORY" if victory else "UI_BATTLE_DEFEAT")
	result_label.visible = true
	print("BattleUI: Battle ended - ", result_label.text)

# Phase 2: Create UI components
func _create_phase2_ui() -> void:
	# Global turn timer container - positioned above card hand
	var timer_container = VBoxContainer.new()
	timer_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	timer_container.offset_left = 340
	timer_container.offset_right = -340
	timer_container.offset_top = -280
	timer_container.offset_bottom = -230
	add_child(timer_container)

	# Timer label
	var timer_label = Label.new()
	timer_label.text = DataManager.get_localized("UI_GLOBAL_TURN")
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 16)
	timer_container.add_child(timer_label)

	# Global turn timer bar
	global_turn_bar = ProgressBar.new()
	global_turn_bar.custom_minimum_size = Vector2(400, 24)
	global_turn_bar.max_value = BattleManager.GLOBAL_TURN_INTERVAL
	global_turn_bar.value = 0
	global_turn_bar.show_percentage = false
	timer_container.add_child(global_turn_bar)

	# Skill bar on left side
	skill_bar = SkillBar.new()
	skill_bar.skill_activated.connect(_on_skill_activated)
	add_child(skill_bar)

	# Card hand
	card_hand = CardHand.new()
	card_hand.card_selected.connect(_on_card_selected)

	# Position card hand BEFORE adding as child
	card_hand.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	card_hand.offset_top = -230
	card_hand.offset_bottom = -10
	card_hand.offset_left = 10
	card_hand.offset_right = -10

	add_child(card_hand)

func _process(_delta: float) -> void:
	# Update global turn timer bar
	if battle_manager:
		global_turn_bar.value = battle_manager.global_turn_timer

	# Update skill bar buttons
	if skill_bar:
		skill_bar.update_all_buttons()

# Phase 2: Initialize card deck
func _initialize_deck() -> void:
	# Build starter deck: 3x aggressive charge, 2x iron defense, 2x field medic, 2x intimidate, 1x sabotage
	var deck_composition = [
		"card_aggressive_charge",
		"card_aggressive_charge",
		"card_aggressive_charge",
		"card_iron_defense",
		"card_iron_defense",
		"card_field_medic",
		"card_field_medic",
		"card_intimidate",
		"card_intimidate",
		"card_sabotage"
	]

	for card_id in deck_composition:
		var card = DataManager.create_card_instance(card_id)
		if card:
			deck.append(card)

	# Shuffle deck
	deck.shuffle()
	print("Deck initialized with ", deck.size(), " cards")

	# Draw initial hand (3 cards)
	for i in range(3):
		_draw_card()

	# Cards start disabled - only enabled on global turn
	card_hand.set_interactive(false)

func _draw_card() -> void:
	if deck.is_empty():
		print("Deck is empty! Shuffling discard pile...")
		# Reshuffle discard pile back into deck
		deck = discard_pile.duplicate()
		discard_pile.clear()
		deck.shuffle()

	if deck.is_empty():
		print("No cards available to draw!")
		return

	var card = deck.pop_front()
	card_hand.add_card(card)
	print("Drew card: ", card.display_name)

# Phase 2: Skill activation handler
func _on_skill_activated(unit: Unit) -> void:
	if unit.general:
		print("BattleUI: Skill activated for ", unit.general.display_name, " (", unit.display_name, ")")
	else:
		print("BattleUI: Skill activated for ", unit.display_name)
	battle_manager.execute_unit_skill(unit)

# Phase 2: Global turn handler
func _on_global_turn_ready() -> void:
	print("BattleUI: Global turn ready, enabling card selection")
	card_hand.set_interactive(true)
	# Could add visual indicator here (flashing timer, etc.)

func _on_card_selected(card: Card) -> void:
	print("BattleUI: Card selected: ", card.display_name)

	# Execute card effect
	card.execute_effect(battle_manager.ally_units, battle_manager.enemy_units)

	# Remove from hand and add to discard
	card_hand.remove_card(card)
	discard_pile.append(card)

	# Draw new card
	_draw_card()

	# Disable card interaction
	card_hand.set_interactive(false)

	# Resume battle
	battle_manager.on_card_used()
