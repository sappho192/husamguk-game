extends Node

# Battle Simulator for headless testing and balance tuning
# Usage: godot --headless --script src/tools/battle_simulator.gd -- [arguments]
#
# Arguments (Legacy Mode - single battle):
#   --team1 <general_id>,<unit_id>,<unit_id>,...
#   --team2 <general_id>,<unit_id>,<unit_id>,...
#   --iterations <number> (default: 1)
#   --output <path> (default: output/simulation)
#
# Arguments (Wave Mode - battle data):
#   --battle <battle_id> (e.g., stage1_battle, stage2_battle, stage3_battle)
#   --team <general_id>,<unit_id>,<unit_id>,... (ally team composition)
#   --iterations <number> (default: 1)
#   --output <path> (default: output/simulation)
#
# Config File Mode:
#   --batch-config <yaml_file> (run multiple scenarios from YAML)
#
# Example (Legacy):
#   godot --headless --script src/tools/battle_simulator.gd -- --team1 gyeonhwon,infantry,infantry --team2 wanggeon,cavalry --iterations 100
#
# Example (Wave):
#   godot --headless --script src/tools/battle_simulator.gd -- --battle stage1_battle --team gyeonhwon,spearman,spearman --iterations 50

const BattleManager = preload("res://src/systems/battle/battle_manager.gd")
const General = preload("res://src/core/general.gd")
const Unit = preload("res://src/core/unit.gd")

# Simulation configuration
var simulation_scenarios: Array[Dictionary] = []  # List of scenarios to run
var config_file: String = "simulation_config.yaml"  # Default config file
var output_base_path: String = "output/simulation"

# Legacy single-sim config (for CLI mode)
var team1_config: Dictionary = {}  # {general: String, units: Array[String]}
var team2_config: Dictionary = {}
var iterations: int = 1
var output_path: String = "output/simulation"

# Wave mode config
var use_wave_mode: bool = false
var battle_id: String = ""  # e.g., "stage1_battle"
var ally_team_config: Dictionary = {}  # {general: String, units: Array[String]}

# Battle manager instance
var battle_manager: BattleManager = null

# Statistics collection
var battle_results: Array[Dictionary] = []  # Raw data for CSV
var current_battle_id: int = 0
var current_battle_start_time: float = 0.0
var current_battle_stats: Dictionary = {}

# Aggregated statistics
var total_battles: int = 0
var team1_wins: int = 0
var team2_wins: int = 0
var total_duration: float = 0.0
var total_turns: int = 0

# Wave statistics (Phase 4)
var waves_cleared: int = 0
var total_wave_count: int = 0
var wave_stats: Array[Dictionary] = []  # Per-wave statistics

func _ready() -> void:
	print("=== Battle Simulator Started ===")

	# Speed up simulation (10x faster)
	Engine.time_scale = 10.0
	print("Time scale set to: ", Engine.time_scale, "x")

	# Wait for DataManager to load (it's an autoload)
	await get_tree().process_frame

	# Try to load config file first
	if FileAccess.file_exists("res://" + config_file):
		print("Loading configuration from: ", config_file)
		if not _load_config_file():
			print("ERROR: Failed to load config file")
			get_tree().quit(1)
			return
	else:
		# Fallback to command-line arguments
		print("No config file found, trying command-line arguments...")
		if not _parse_arguments():
			print("ERROR: Failed to parse arguments")
			get_tree().quit(1)
			return
		# Convert single config to scenario format
		simulation_scenarios = [{
			"name": "cli_simulation",
			"team1": team1_config,
			"team2": team2_config,
			"iterations": iterations,
			"output": output_path
		}]

	# Create output directory
	_ensure_output_directory()

	# Initialize battle manager
	battle_manager = BattleManager.new()
	add_child(battle_manager)
	battle_manager.battle_started.connect(_on_battle_started)
	battle_manager.battle_ended.connect(_on_battle_ended)
	battle_manager.unit_action_ready.connect(_on_unit_action)
	battle_manager.global_turn_ready.connect(_on_global_turn)
	battle_manager.wave_started.connect(_on_wave_started)
	battle_manager.wave_complete.connect(_on_wave_complete)

	# Start simulations
	_run_all_scenarios()

func _parse_arguments() -> bool:
	# Try environment variables first (for scene-based execution)
	var env_team1 = OS.get_environment("BATTLE_SIM_TEAM1")
	var env_team2 = OS.get_environment("BATTLE_SIM_TEAM2")
	var env_iterations = OS.get_environment("BATTLE_SIM_ITERATIONS")
	var env_output = OS.get_environment("BATTLE_SIM_OUTPUT")

	if not env_team1.is_empty() and not env_team2.is_empty():
		print("Using environment variables for configuration")
		team1_config = _parse_team_config(env_team1)
		team2_config = _parse_team_config(env_team2)
		if not env_iterations.is_empty():
			iterations = env_iterations.to_int()
		if not env_output.is_empty():
			output_path = env_output

		print("Team 1: ", team1_config)
		print("Team 2: ", team2_config)
		print("Iterations: ", iterations)
		print("Output path: ", output_path)
		return true

	# Fallback to command-line arguments (for direct script execution)
	var args = OS.get_cmdline_args()
	print("Command-line arguments: ", args)

	# Find the separator '--' which separates Godot args from script args
	var script_args_start = -1
	for i in range(args.size()):
		if args[i] == "--":
			script_args_start = i + 1
			break

	if script_args_start == -1:
		print("ERROR: No script arguments found. Use '--' to separate script arguments.")
		print("  OR set environment variables: BATTLE_SIM_TEAM1, BATTLE_SIM_TEAM2, etc.")
		return false

	# Parse script arguments
	var i = script_args_start
	while i < args.size():
		var arg = args[i]

		match arg:
			"--team1":
				if i + 1 < args.size():
					team1_config = _parse_team_config(args[i + 1])
					i += 2
				else:
					print("ERROR: --team1 requires a value")
					return false

			"--team2":
				if i + 1 < args.size():
					team2_config = _parse_team_config(args[i + 1])
					i += 2
				else:
					print("ERROR: --team2 requires a value")
					return false

			"--iterations":
				if i + 1 < args.size():
					iterations = args[i + 1].to_int()
					i += 2
				else:
					print("ERROR: --iterations requires a value")
					return false

			"--output":
				if i + 1 < args.size():
					output_path = args[i + 1]
					i += 2
				else:
					print("ERROR: --output requires a value")
					return false

			"--battle":
				if i + 1 < args.size():
					battle_id = args[i + 1]
					use_wave_mode = true
					i += 2
				else:
					print("ERROR: --battle requires a value")
					return false

			"--team":
				if i + 1 < args.size():
					ally_team_config = _parse_team_config(args[i + 1])
					i += 2
				else:
					print("ERROR: --team requires a value")
					return false

			_:
				print("WARNING: Unknown argument: ", arg)
				i += 1

	# Validate configuration
	if use_wave_mode:
		if battle_id.is_empty() or ally_team_config.is_empty():
			print("ERROR: Wave mode requires --battle and --team")
			return false
		print("Mode: Wave Battle")
		print("Battle ID: ", battle_id)
		print("Ally Team: ", ally_team_config)
		print("Iterations: ", iterations)
		print("Output path: ", output_path)
	else:
		if team1_config.is_empty() or team2_config.is_empty():
			print("ERROR: Legacy mode requires --team1 and --team2")
			return false
		print("Mode: Legacy (Single Battle)")
		print("Team 1: ", team1_config)
		print("Team 2: ", team2_config)
		print("Iterations: ", iterations)
		print("Output path: ", output_path)

	return true

func _parse_team_config(config_str: String) -> Dictionary:
	# Format: general_id,unit_id,unit_id,...
	var parts = config_str.split(",")
	if parts.size() < 2:
		push_error("Invalid team config: " + config_str)
		return {}

	return {
		"general": parts[0],
		"units": parts.slice(1)
	}

func _ensure_output_directory() -> void:
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(output_path):
		dir.make_dir_recursive(output_path)
		print("Created output directory: ", output_path)

func _run_simulations() -> void:
	print("\n=== Starting ", iterations, " simulation(s) ===\n")

	for i in range(iterations):
		current_battle_id = i + 1
		print("--- Battle ", current_battle_id, "/", iterations, " ---")

		# Reset battle stats
		if use_wave_mode:
			current_battle_stats = {
				"battle_id": current_battle_id,
				"mode": "wave",
				"battle_data_id": battle_id,
				"ally_config": _config_to_string(ally_team_config),
				"team1_damage_dealt": 0,
				"team2_damage_dealt": 0,
				"team1_damage_taken": 0,
				"team2_damage_taken": 0,
				"team1_skills_used": 0,
				"team2_skills_used": 0,
				"global_turns": 0,
				"waves_cleared": 0,
				"total_waves": 0,
				"wave_details": [],
				"unit_actions": []
			}
		else:
			current_battle_stats = {
				"battle_id": current_battle_id,
				"mode": "legacy",
				"team1_config": _config_to_string(team1_config),
				"team2_config": _config_to_string(team2_config),
				"team1_damage_dealt": 0,
				"team2_damage_dealt": 0,
				"team1_damage_taken": 0,
				"team2_damage_taken": 0,
				"team1_skills_used": 0,
				"team2_skills_used": 0,
				"global_turns": 0,
				"unit_actions": []
			}

		# Start battle
		_start_battle()

		# Wait for battle to end
		await battle_manager.battle_ended

		# Small delay between battles
		if is_inside_tree():
			await get_tree().create_timer(0.1).timeout

	# All simulations complete
	_finalize_results()

func _start_battle() -> void:
	# Reset battle manager state
	battle_manager.state = BattleManager.BattleState.PREPARING
	battle_manager.ally_units.clear()
	battle_manager.enemy_units.clear()
	battle_manager.action_queue.clear()
	battle_manager.global_turn_timer = 0.0
	battle_manager.global_turn_count = 0

	# Reset wave statistics
	wave_stats.clear()

	current_battle_start_time = Time.get_ticks_msec() / 1000.0

	if use_wave_mode:
		# Wave Mode: Start battle from battle data
		var ally_data: Array = []
		var general = DataManager.create_general_instance(ally_team_config["general"])
		if not general:
			push_error("Failed to create general: " + ally_team_config["general"])
			return

		var units = ally_team_config["units"]
		for i in range(units.size()):
			var unit_id = units[i]
			var unit_general = general if i == 0 else null
			ally_data.append({
				"id": unit_id,
				"general": unit_general
			})

		battle_manager.start_battle_from_data(battle_id, ally_data)

	else:
		# Legacy Mode: Direct team vs team
		var team1_data: Array = []
		var team2_data: Array = []

		# Team 1
		var general1 = DataManager.create_general_instance(team1_config["general"])
		if not general1:
			push_error("Failed to create general: " + team1_config["general"])
			return

		var team1_units = team1_config["units"]
		for i in range(team1_units.size()):
			var unit_id = team1_units[i]
			var unit_general = general1 if i == 0 else null
			team1_data.append({
				"id": unit_id,
				"general": unit_general
			})

		# Team 2
		var general2 = DataManager.create_general_instance(team2_config["general"])
		if not general2:
			push_error("Failed to create general: " + team2_config["general"])
			return

		var team2_units = team2_config["units"]
		for i in range(team2_units.size()):
			var unit_id = team2_units[i]
			var unit_general = general2 if i == 0 else null
			team2_data.append({
				"id": unit_id,
				"general": unit_general
			})

		battle_manager.start_battle_with_generals(team1_data, team2_data)

func _on_battle_started() -> void:
	print("Battle started!")

	# Connect unit signals for tracking
	for unit in battle_manager.ally_units:
		unit.took_damage.connect(_on_unit_took_damage.bind(unit, true))

	for unit in battle_manager.enemy_units:
		unit.took_damage.connect(_on_unit_took_damage.bind(unit, false))

func _on_unit_action(unit: Unit) -> void:
	# Track unit actions for statistics
	current_battle_stats["unit_actions"].append({
		"unit": unit.display_name,
		"is_ally": unit.is_ally,
		"atb": unit.atb_current,
		"hp": unit.current_hp
	})

func _on_unit_took_damage(amount: int, current_hp: int, unit: Unit, is_ally: bool) -> void:
	# Track damage dealt/taken
	if is_ally:
		current_battle_stats["team1_damage_taken"] += amount
		current_battle_stats["team2_damage_dealt"] += amount
	else:
		current_battle_stats["team2_damage_taken"] += amount
		current_battle_stats["team1_damage_dealt"] += amount

func _on_global_turn() -> void:
	current_battle_stats["global_turns"] += 1

	# Auto-resume battle (skip card selection in simulation)
	battle_manager.on_card_used()

func _on_wave_started(wave_number: int, total_waves: int) -> void:
	print("Wave ", wave_number, " / ", total_waves, " started!")
	current_battle_stats["total_waves"] = total_waves

	# Initialize wave tracking
	wave_stats.append({
		"wave_number": wave_number,
		"start_time": Time.get_ticks_msec() / 1000.0,
		"enemies_at_start": battle_manager.enemy_units.size(),
		"allies_alive_at_start": _count_alive_units(battle_manager.ally_units),
		"global_turns_at_start": battle_manager.global_turn_count
	})

func _on_wave_complete(wave_number: int, has_next_wave: bool) -> void:
	print("Wave ", wave_number, " complete! ", "Next wave pending." if has_next_wave else "Battle complete.")
	current_battle_stats["waves_cleared"] = wave_number
	waves_cleared += 1

	# Finalize wave statistics
	if wave_stats.size() > 0:
		var wave_stat = wave_stats[wave_stats.size() - 1]
		wave_stat["end_time"] = Time.get_ticks_msec() / 1000.0
		wave_stat["duration"] = wave_stat["end_time"] - wave_stat["start_time"]
		wave_stat["allies_alive_at_end"] = _count_alive_units(battle_manager.ally_units)
		wave_stat["global_turns_during_wave"] = battle_manager.global_turn_count - wave_stat["global_turns_at_start"]

		current_battle_stats["wave_details"].append(wave_stat.duplicate())

func _count_alive_units(units: Array[Unit]) -> int:
	var count = 0
	for unit in units:
		if unit.is_alive:
			count += 1
	return count

func _on_battle_ended(victory: bool) -> void:
	var duration = (Time.get_ticks_msec() / 1000.0) - current_battle_start_time

	print("Battle ended! ", "Team 1 Victory" if victory else "Team 2 Victory")
	print("  Duration: ", "%.2f" % duration, "s")
	print("  Global turns: ", current_battle_stats["global_turns"])
	print("  Team 1 damage: ", current_battle_stats["team1_damage_dealt"], " dealt, ", current_battle_stats["team1_damage_taken"], " taken")
	print("  Team 2 damage: ", current_battle_stats["team2_damage_dealt"], " dealt, ", current_battle_stats["team2_damage_taken"], " taken")

	# Record results
	current_battle_stats["winner"] = "team1" if victory else "team2"
	current_battle_stats["duration"] = duration
	battle_results.append(current_battle_stats.duplicate(true))

	# Update aggregated stats
	total_battles += 1
	if victory:
		team1_wins += 1
	else:
		team2_wins += 1
	total_duration += duration
	total_turns += current_battle_stats["global_turns"]

func _finalize_results() -> void:
	print("\n=== Simulation Complete ===")
	print("Total battles: ", total_battles)
	print("Team 1 wins: ", team1_wins, " (", "%.1f" % (team1_wins * 100.0 / total_battles), "%)")
	print("Team 2 wins: ", team2_wins, " (", "%.1f" % (team2_wins * 100.0 / total_battles), "%)")
	print("Average duration: ", "%.2f" % (total_duration / total_battles), "s")
	print("Average turns: ", "%.1f" % (total_turns / float(total_battles)))

	# Write CSV (raw data)
	_write_csv_results()

	# Write JSON (summary statistics)
	_write_json_summary()

	print("\nResults written to: ", output_path)
	print("  - battles.csv (raw data)")
	print("  - summary.json (statistics)")

	# Exit
	get_tree().quit(0)

func _write_csv_results() -> void:
	var csv_path = output_path + "/battles.csv"
	var file = FileAccess.open(csv_path, FileAccess.WRITE)

	if not file:
		push_error("Failed to open CSV file: " + csv_path)
		return

	# Write header (different for wave vs legacy mode)
	if use_wave_mode:
		file.store_line("battle_id,mode,battle_data_id,ally_config,winner,duration,global_turns,waves_cleared,total_waves,team1_damage_dealt,team1_damage_taken,team2_damage_dealt,team2_damage_taken")
	else:
		file.store_line("battle_id,mode,team1_config,team2_config,winner,duration,global_turns,team1_damage_dealt,team1_damage_taken,team2_damage_dealt,team2_damage_taken")

	# Write data rows
	for result in battle_results:
		if result.get("mode", "legacy") == "wave":
			var row = "%d,%s,%s,%s,%s,%.2f,%d,%d,%d,%d,%d,%d,%d" % [
				result["battle_id"],
				result["mode"],
				result["battle_data_id"],
				result["ally_config"],
				result["winner"],
				result["duration"],
				result["global_turns"],
				result.get("waves_cleared", 0),
				result.get("total_waves", 0),
				result["team1_damage_dealt"],
				result["team1_damage_taken"],
				result["team2_damage_dealt"],
				result["team2_damage_taken"]
			]
			file.store_line(row)
		else:
			var row = "%d,%s,%s,%s,%s,%.2f,%d,%d,%d,%d,%d" % [
				result["battle_id"],
				result["mode"],
				result["team1_config"],
				result["team2_config"],
				result["winner"],
				result["duration"],
				result["global_turns"],
				result["team1_damage_dealt"],
				result["team1_damage_taken"],
				result["team2_damage_dealt"],
				result["team2_damage_taken"]
			]
			file.store_line(row)

	file.close()
	print("CSV written: ", csv_path)

func _write_json_summary() -> void:
	var json_path = output_path + "/summary.json"

	# Calculate additional statistics
	var avg_duration = total_duration / total_battles if total_battles > 0 else 0.0
	var avg_turns = total_turns / float(total_battles) if total_battles > 0 else 0.0
	var team1_win_rate = team1_wins * 100.0 / total_battles if total_battles > 0 else 0.0
	var team2_win_rate = team2_wins * 100.0 / total_battles if total_battles > 0 else 0.0

	# Calculate damage statistics
	var total_team1_damage_dealt = 0
	var total_team1_damage_taken = 0
	var total_team2_damage_dealt = 0
	var total_team2_damage_taken = 0

	for result in battle_results:
		total_team1_damage_dealt += result["team1_damage_dealt"]
		total_team1_damage_taken += result["team1_damage_taken"]
		total_team2_damage_dealt += result["team2_damage_dealt"]
		total_team2_damage_taken += result["team2_damage_taken"]

	var avg_team1_damage_dealt = total_team1_damage_dealt / float(total_battles) if total_battles > 0 else 0.0
	var avg_team1_damage_taken = total_team1_damage_taken / float(total_battles) if total_battles > 0 else 0.0
	var avg_team2_damage_dealt = total_team2_damage_dealt / float(total_battles) if total_battles > 0 else 0.0
	var avg_team2_damage_taken = total_team2_damage_taken / float(total_battles) if total_battles > 0 else 0.0

	# Build summary dictionary
	var summary = {}

	if use_wave_mode:
		summary = {
			"simulation_config": {
				"mode": "wave",
				"battle_id": battle_id,
				"ally_team": _config_to_string(ally_team_config),
				"iterations": iterations
			},
			"results": {
				"total_battles": total_battles,
				"team1_wins": team1_wins,
				"team2_wins": team2_wins,
				"team1_win_rate": "%.2f%%" % team1_win_rate,
				"team2_win_rate": "%.2f%%" % team2_win_rate
			},
			"performance": {
				"average_duration_seconds": "%.2f" % avg_duration,
				"average_global_turns": "%.1f" % avg_turns,
				"total_duration_seconds": "%.2f" % total_duration
			},
			"wave_statistics": {
				"total_wave_count": total_wave_count,
				"waves_cleared": waves_cleared,
				"average_waves_per_battle": "%.2f" % (waves_cleared / float(total_battles)) if total_battles > 0 else 0.0
			},
			"damage_statistics": {
				"team1": {
					"avg_damage_dealt": "%.1f" % avg_team1_damage_dealt,
					"avg_damage_taken": "%.1f" % avg_team1_damage_taken,
					"total_damage_dealt": total_team1_damage_dealt,
					"total_damage_taken": total_team1_damage_taken
				},
				"team2": {
					"avg_damage_dealt": "%.1f" % avg_team2_damage_dealt,
					"avg_damage_taken": "%.1f" % avg_team2_damage_taken,
					"total_damage_dealt": total_team2_damage_dealt,
					"total_damage_taken": total_team2_damage_taken
				}
			}
		}
	else:
		summary = {
			"simulation_config": {
				"mode": "legacy",
				"team1": _config_to_string(team1_config),
				"team2": _config_to_string(team2_config),
				"iterations": iterations
			},
			"results": {
				"total_battles": total_battles,
				"team1_wins": team1_wins,
				"team2_wins": team2_wins,
				"team1_win_rate": "%.2f%%" % team1_win_rate,
				"team2_win_rate": "%.2f%%" % team2_win_rate
			},
			"performance": {
				"average_duration_seconds": "%.2f" % avg_duration,
				"average_global_turns": "%.1f" % avg_turns,
				"total_duration_seconds": "%.2f" % total_duration
			},
			"damage_statistics": {
				"team1": {
					"avg_damage_dealt": "%.1f" % avg_team1_damage_dealt,
					"avg_damage_taken": "%.1f" % avg_team1_damage_taken,
					"total_damage_dealt": total_team1_damage_dealt,
					"total_damage_taken": total_team1_damage_taken
				},
				"team2": {
					"avg_damage_dealt": "%.1f" % avg_team2_damage_dealt,
					"avg_damage_taken": "%.1f" % avg_team2_damage_taken,
					"total_damage_dealt": total_team2_damage_dealt,
					"total_damage_taken": total_team2_damage_taken
				}
			}
		}

	# Write JSON
	var json_string = JSON.stringify(summary, "\t")
	var file = FileAccess.open(json_path, FileAccess.WRITE)

	if not file:
		push_error("Failed to open JSON file: " + json_path)
		return

	file.store_string(json_string)
	file.close()
	print("JSON written: ", json_path)

func _config_to_string(config: Dictionary) -> String:
	var general = config.get("general", "")
	var units = config.get("units", [])
	return general + "," + ",".join(units)

func _load_config_file() -> bool:
	var file = FileAccess.open("res://" + config_file, FileAccess.READ)
	if not file:
		push_error("Failed to open config file: " + config_file)
		return false

	var content = file.get_as_text()
	file.close()

	var result = YAML.parse(content)
	if result.has_error():
		push_error("YAML parse error: " + str(result.get_error()))
		return false

	var data = result.get_data()
	var simulations = data.get("simulations", [])

	if simulations.is_empty():
		push_error("No simulations found in config file")
		return false

	for sim in simulations:
		var scenario = {
			"name": sim.get("name", "unnamed"),
			"iterations": sim.get("iterations", 1),
			"output": output_base_path + "/" + sim.get("name", "unnamed")
		}

		# Check if this is a wave mode scenario
		if sim.has("battle_id") and sim.has("ally_team"):
			scenario["mode"] = "wave"
			scenario["battle_id"] = sim.get("battle_id", "")
			scenario["ally_team"] = sim.get("ally_team", {})
		else:
			scenario["mode"] = "legacy"
			scenario["team1"] = sim.get("team1", {})
			scenario["team2"] = sim.get("team2", {})

		simulation_scenarios.append(scenario)

	print("Loaded ", simulation_scenarios.size(), " scenarios from config file")
	return true

func _run_all_scenarios() -> void:
	print("\n=== Running ", simulation_scenarios.size(), " scenario(s) ===\n")

	for scenario in simulation_scenarios:
		await _run_scenario(scenario)

	print("\n=== All scenarios complete ===")
	get_tree().quit(0)

func _run_scenario(scenario: Dictionary) -> void:
	print("\n========================================")
	print("Scenario: ", scenario["name"])
	print("========================================")

	# Set up scenario
	iterations = scenario["iterations"]
	output_path = scenario["output"]

	var mode = scenario.get("mode", "legacy")
	if mode == "wave":
		use_wave_mode = true
		battle_id = scenario["battle_id"]
		ally_team_config = scenario["ally_team"]
		print("Mode: Wave Battle")
		print("Battle ID: ", battle_id)
		print("Ally Team: ", ally_team_config)
	else:
		use_wave_mode = false
		team1_config = scenario["team1"]
		team2_config = scenario["team2"]
		print("Mode: Legacy")
		print("Team 1: ", team1_config)
		print("Team 2: ", team2_config)

	# Reset statistics
	battle_results.clear()
	current_battle_id = 0
	total_battles = 0
	team1_wins = 0
	team2_wins = 0
	total_duration = 0.0
	total_turns = 0
	waves_cleared = 0
	total_wave_count = 0

	# Create output directory for this scenario
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(output_path):
		dir.make_dir_recursive(output_path)

	# Run simulations
	await _run_simulations()

	print("\nScenario '", scenario["name"], "' complete!")
