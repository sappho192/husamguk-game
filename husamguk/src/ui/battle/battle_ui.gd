extends Control

@onready var ally_container: HBoxContainer = $AllyContainer
@onready var enemy_container: HBoxContainer = $EnemyContainer
@onready var result_label: Label = $ResultLabel

var battle_manager: BattleManager

func _ready() -> void:
	# Create BattleManager
	battle_manager = BattleManager.new()
	add_child(battle_manager)

	# Connect signals
	battle_manager.battle_started.connect(_on_battle_started)
	battle_manager.battle_ended.connect(_on_battle_ended)

	# Hide result label initially
	result_label.visible = false

	# Start test battle
	_start_test_battle()

func _start_test_battle() -> void:
	# Test data: 3v3 battle
	var ally_data = ["spearman", "archer", "swordsman"]
	var enemy_data = ["light_cavalry", "archer", "spearman"]

	battle_manager.start_battle(ally_data, enemy_data)

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

func _create_unit_display(unit: Unit) -> UnitDisplay:
	var display = UnitDisplay.new()
	display.setup(unit)
	return display

func _on_battle_ended(victory: bool) -> void:
	result_label.text = DataManager.get_localized("UI_BATTLE_VICTORY" if victory else "UI_BATTLE_DEFEAT")
	result_label.visible = true
	print("BattleUI: Battle ended - ", result_label.text)
