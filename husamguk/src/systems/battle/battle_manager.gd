class_name BattleManager
extends Node

const Corps = preload("res://src/core/corps.gd")
const CorpsCommand = preload("res://src/core/corps_command.gd")
const BattleMap = preload("res://src/core/battle_map.gd")
const TerrainTile = preload("res://src/core/terrain_tile.gd")

signal battle_started()
signal unit_action_ready(unit: Unit)
signal battle_ended(victory: bool)
signal global_turn_ready()  # Phase 2: Global turn system
signal wave_started(wave_number: int, total_waves: int)  # Phase 4: Wave system
signal wave_complete(wave_number: int, has_next_wave: bool)  # Phase 4: Wave complete
signal corps_action_ready(corps: Corps)  # Phase 5C: Corps ATB filled
signal command_executed(command: CorpsCommand)  # Phase 5C: Command executed
signal movement_phase_started()  # Phase 5C: Movement phase begins
signal movement_phase_ended()  # Phase 5C: Movement phase ends

enum BattleState { PREPARING, RUNNING, PAUSED_FOR_CARD, WAVE_TRANSITION, MOVEMENT_PHASE, ENDED }  # Phase 5C: Added MOVEMENT_PHASE

var state: BattleState = BattleState.PREPARING

var ally_units: Array[Unit] = []
var enemy_units: Array[Unit] = []

var action_queue: Array[Unit] = []  # Units waiting to act

# Phase 2: Global turn system
const GLOBAL_TURN_INTERVAL: float = 4.0  # seconds
var global_turn_timer: float = 0.0
var global_turn_count: int = 0

# Phase 4: Wave system
var battle_data: Dictionary = {}  # Full battle definition
var current_wave_index: int = 0   # 0-based wave index
var total_waves: int = 0

# Phase 5A: Terrain Grid
var battle_map: BattleMap = null
var corps_positions: Dictionary = {}  # Vector2i -> Corps (grid position to corps)

# Phase 5B: Corps system
var ally_corps: Array = []  # Array[Corps]
var enemy_corps: Array = []  # Array[Corps]
var corps_action_queue: Array = []  # Array[Corps] - Corps waiting to act

# Phase 5C: Command system
var pending_commands: Dictionary = {}  # Corps -> CorpsCommand
var movement_commands: Array = []  # Array[CorpsCommand] - MOVE commands to execute during global turn

func start_battle(ally_data: Array, enemy_data: Array) -> void:
	print("BattleManager: Starting battle with ", ally_data.size(), " allies vs ", enemy_data.size(), " enemies")

	# Create units from data
	for unit_id in ally_data:
		var unit = DataManager.create_unit_instance(unit_id, true)
		if unit:
			ally_units.append(unit)
			_connect_unit_signals(unit)
			print("  Ally: ", unit.display_name, " (", unit.category, ")")

	for unit_id in enemy_data:
		var unit = DataManager.create_unit_instance(unit_id, false)
		if unit:
			enemy_units.append(unit)
			_connect_unit_signals(unit)
			print("  Enemy: ", unit.display_name, " (", unit.category, ")")

	state = BattleState.RUNNING
	battle_started.emit()

# Phase 2: Start battle with generals assigned
func start_battle_with_generals(ally_data: Array, enemy_data: Array) -> void:
	print("BattleManager: Starting battle with generals")

	# Create ally units with generals
	for unit_config in ally_data:
		var unit_id = unit_config.get("id", "")
		var general = unit_config.get("general", null)
		var unit = DataManager.create_unit_instance(unit_id, true, general)
		if unit:
			ally_units.append(unit)
			_connect_unit_signals(unit)
			var general_name = general.display_name if general else "None"
			print("  Ally: ", unit.display_name, " (General: ", general_name, ")")

	# Create enemy units
	for unit_config in enemy_data:
		var unit_id = unit_config.get("id", "")
		var general = unit_config.get("general", null)
		var unit = DataManager.create_unit_instance(unit_id, false, general)
		if unit:
			enemy_units.append(unit)
			_connect_unit_signals(unit)
			print("  Enemy: ", unit.display_name, " (", unit.category, ")")

	state = BattleState.RUNNING
	battle_started.emit()

# Phase 4: Start battle from battle data (Wave system)
func start_battle_from_data(battle_id: String, ally_data: Array) -> void:
	print("BattleManager: Starting battle from data: ", battle_id)

	# Load battle definition
	battle_data = DataManager.get_battle(battle_id)
	if battle_data.is_empty():
		push_error("BattleManager: Battle not found: " + battle_id)
		return

	var waves = battle_data.get("waves", [])
	if waves.is_empty():
		push_error("BattleManager: No waves defined for battle: " + battle_id)
		return

	total_waves = waves.size()
	current_wave_index = 0

	# Create ally units
	for unit_config in ally_data:
		var unit_id = unit_config.get("id", "")
		var general = unit_config.get("general", null)
		var unit = DataManager.create_unit_instance(unit_id, true, general)
		if unit:
			ally_units.append(unit)
			_connect_unit_signals(unit)
			var general_name = general.display_name if general else "None"
			print("  Ally: ", unit.display_name, " (General: ", general_name, ")")

	# Start first wave
	_spawn_wave(0)
	state = BattleState.RUNNING
	battle_started.emit()

func _spawn_wave(wave_index: int) -> void:
	print("=== SPAWNING WAVE ", wave_index + 1, " / ", total_waves, " ===")

	var waves = battle_data.get("waves", [])
	if wave_index >= waves.size():
		push_error("BattleManager: Wave index out of bounds: ", wave_index)
		return

	var wave_data = waves[wave_index]
	var enemies_data = wave_data.get("enemies", [])

	# Clear existing enemies from previous wave
	for enemy in enemy_units:
		if enemy.atb_filled.is_connected(_on_unit_atb_filled):
			enemy.atb_filled.disconnect(_on_unit_atb_filled)
	enemy_units.clear()

	# Create enemy units for this wave
	for enemy_config in enemies_data:
		var unit_id = enemy_config.get("id", "")
		var general_id = enemy_config.get("general", null)
		var general = null
		if general_id:
			general = DataManager.create_general_instance(general_id)

		var unit = DataManager.create_unit_instance(unit_id, false, general)
		if unit:
			enemy_units.append(unit)
			_connect_unit_signals(unit)
			var general_name = general.display_name if general else "None"
			print("  Enemy: ", unit.display_name, " (General: ", general_name, ")")

	current_wave_index = wave_index
	wave_started.emit(wave_index + 1, total_waves)

func _on_wave_complete() -> void:
	print("=== WAVE ", current_wave_index + 1, " COMPLETE ===")

	var has_next_wave = current_wave_index + 1 < total_waves
	wave_complete.emit(current_wave_index + 1, has_next_wave)

	if has_next_wave:
		# Apply wave rewards
		var waves = battle_data.get("waves", [])
		var wave_data = waves[current_wave_index]
		_apply_wave_rewards(wave_data)

		# Transition to next wave
		state = BattleState.WAVE_TRANSITION
		await get_tree().create_timer(2.0).timeout  # 2 second pause

		if not is_inside_tree():
			return  # Scene was changed during wait

		_spawn_wave(current_wave_index + 1)
		state = BattleState.RUNNING
	else:
		# Battle victory
		_end_battle(true)

func _apply_wave_rewards(wave_data: Dictionary) -> void:
	var rewards = wave_data.get("wave_rewards", null)
	if rewards == null or rewards.is_empty():
		return

	print("Applying wave rewards...")

	# HP recovery
	var hp_recovery_pct = rewards.get("hp_recovery_percent", 0)
	if hp_recovery_pct > 0:
		for unit in ally_units:
			if unit.is_alive:
				var recovery = int(unit.max_hp * hp_recovery_pct / 100.0)
				unit.current_hp = mini(unit.current_hp + recovery, unit.max_hp)
				print("  ", unit.display_name, " recovered ", recovery, " HP")

	# Global turn reset
	var global_turn_reset = rewards.get("global_turn_reset", false)
	if global_turn_reset:
		global_turn_timer = GLOBAL_TURN_INTERVAL  # Trigger immediately
		print("  Global turn reset - card draw ready")

	# Buff duration extension
	var buff_extension = rewards.get("buff_duration_extension", 0)
	if buff_extension > 0:
		for unit in ally_units:
			for buff in unit.active_buffs:
				buff.duration += buff_extension
				print("  ", unit.display_name, " buffs extended by ", buff_extension, " turns")

func _process(delta: float) -> void:
	match state:
		BattleState.RUNNING:
			# Only tick ATB and global timer when running
			_update_atb(delta)
			_update_corps_atb(delta)  # Phase 5C: Update corps ATB
			_tick_global_turn_timer(delta)
			_process_action_queue()
			_process_corps_action_queue()  # Phase 5C: Process corps actions
			_check_battle_end()
		BattleState.PREPARING:
			# Phase 5C: Preparation mode - pause all ATB, wait for player to set commands
			pass
		BattleState.PAUSED_FOR_CARD:
			# Waiting for card selection - no updates
			pass
		BattleState.ENDED:
			pass

func _update_atb(delta: float) -> void:
	for unit in ally_units + enemy_units:
		unit.tick_atb(delta)

func _on_unit_atb_filled(unit: Unit) -> void:
	if state == BattleState.RUNNING and not action_queue.has(unit):
		action_queue.append(unit)

func _process_action_queue() -> void:
	if action_queue.is_empty():
		return

	var unit = action_queue.pop_front()

	if not unit.is_alive:
		return

	# Phase 2: All units auto-attack (skills are triggered manually via UI)
	_execute_auto_attack(unit)

# Phase 5C: Process corps action queue
func _process_corps_action_queue() -> void:
	if corps_action_queue.is_empty():
		return

	var corps = corps_action_queue.pop_front()

	if not corps.is_alive:
		return

	# Execute the corps' assigned command (or auto-attack if none)
	process_immediate_command(corps)

func _execute_auto_attack(attacker: Unit) -> void:
	var targets = enemy_units if attacker.is_ally else ally_units
	var alive_targets = targets.filter(func(u): return u.is_alive)

	if alive_targets.is_empty():
		return

	# Simple targeting: first alive unit
	var target = alive_targets[0]
	var damage = attacker.calculate_attack_damage(target)

	print(attacker.display_name, " attacks ", target.display_name, " for ", damage, " damage")

	attacker.attack_target(target)
	attacker.reset_atb()

	# Visual feedback (emit signal for UI)
	unit_action_ready.emit(attacker)

func _check_battle_end() -> void:
	# Check both unit-based and corps-based battles
	var allies_alive_units = ally_units.filter(func(u): return u.is_alive)
	var enemies_alive_units = enemy_units.filter(func(u): return u.is_alive)
	var allies_alive_corps = ally_corps.filter(func(c): return c.is_alive)
	var enemies_alive_corps = enemy_corps.filter(func(c): return c.is_alive)

	# Use units if available, otherwise use corps
	var using_units = not ally_units.is_empty() or not enemy_units.is_empty()
	var using_corps = not ally_corps.is_empty() or not enemy_corps.is_empty()

	var allies_alive = allies_alive_units if using_units else allies_alive_corps
	var enemies_alive = enemies_alive_units if using_units else enemies_alive_corps

	# Don't check battle end if no units/corps are in battle yet
	if allies_alive.is_empty() and enemies_alive.is_empty():
		return

	if enemies_alive.is_empty():
		# Check if this is a wave-based battle
		if total_waves > 0:
			# Wave complete, check for next wave
			_on_wave_complete()
		else:
			# Non-wave battle - instant victory
			_end_battle(true)
	elif allies_alive.is_empty():
		_end_battle(false)

func _end_battle(victory: bool) -> void:
	if state == BattleState.ENDED:
		return

	state = BattleState.ENDED
	print("BattleManager: Battle ended - ", "VICTORY" if victory else "DEFEAT")
	battle_ended.emit(victory)

func _connect_unit_signals(unit: Unit) -> void:
	unit.atb_filled.connect(_on_unit_atb_filled)
	unit.died.connect(func(): print(unit.display_name, " has died!"))

# Phase 2: Global turn timer
func _tick_global_turn_timer(delta: float) -> void:
	global_turn_timer += delta

	if global_turn_timer >= GLOBAL_TURN_INTERVAL:
		global_turn_timer = 0.0
		global_turn_count += 1
		_trigger_global_turn()

func _trigger_global_turn() -> void:
	print("=== GLOBAL TURN ", global_turn_count, " ===")

	# Phase 5C: Execute movement phase first (before preparation)
	_execute_movement_phase()

	# Phase 5C: Enter preparation mode (was PAUSED_FOR_CARD)
	state = BattleState.PREPARING
	print("BattleManager: Entering PREPARING state")

	# Tick buff durations for all units (global turn based)
	for unit in ally_units + enemy_units:
		unit.tick_buff_durations()

	# Phase 5B: Tick buff durations for all corps
	for corps in ally_corps + enemy_corps:
		if corps.is_alive:
			corps.tick_buff_durations()

	# Tick skill cooldowns for ally generals (if they have generals)
	for unit in ally_units:
		if unit.general:
			unit.general.tick_cooldown()

	# Phase 5B: Tick cooldowns for ally corps generals
	for corps in ally_corps:
		if corps.is_alive and corps.general:
			corps.general.tick_cooldown()

	global_turn_ready.emit()

func resume_battle() -> void:
	# Called by UI when player clicks "Resume Battle" button after setting commands
	print("BattleManager: Resuming battle from PREPARING state")
	state = BattleState.RUNNING

# Legacy: Keep for backward compatibility, but redirect to resume_battle
func on_card_used() -> void:
	resume_battle()

# Phase 2: Execute unit skill (called from UI when player clicks skill icon)
func execute_unit_skill(unit: Unit) -> void:
	if not unit.is_alive:
		push_warning("Cannot execute skill - unit is dead")
		return

	if not unit.general or not unit.general.is_skill_ready():
		push_warning("Cannot execute skill - skill not ready")
		return

	_execute_skill(unit)

func _execute_skill(unit: Unit) -> void:
	var general = unit.general
	var targets = _get_skill_targets(general.skill, unit.is_ally, unit)

	# Execute the skill effect
	general.execute_skill_effect(unit, targets)

	# Note: Skills do NOT reset ATB - they are independent of the ATB system
	# ATB continues to fill normally for auto-attacks

	print(general.display_name, " (", unit.display_name, ") used skill!")

func _get_skill_targets(skill: Dictionary, is_ally: bool, caster: Unit) -> Array[Unit]:
	var effect = skill.get("effect", {})
	var target_type = effect.get("target", "single_enemy")

	var allies = ally_units.filter(func(u): return u.is_alive)
	var enemies = enemy_units.filter(func(u): return u.is_alive)

	match target_type:
		"single_enemy":
			var target_list = enemies if is_ally else allies
			if not target_list.is_empty():
				var result: Array[Unit] = [target_list[0]]
				return result
			else:
				var empty: Array[Unit] = []
				return empty
		"all_enemies":
			return enemies if is_ally else allies
		"single_ally":
			var target_list = allies if is_ally else enemies
			# Select lowest HP ally for healing
			if not target_list.is_empty():
				var lowest = target_list[0]
				for u in target_list:
					if u.current_hp < lowest.current_hp:
						lowest = u
				var result: Array[Unit] = [lowest]
				return result
			else:
				var empty: Array[Unit] = []
				return empty
		"all_allies":
			return allies if is_ally else enemies
		"self":
			if caster.is_alive:
				var result: Array[Unit] = [caster]
				return result
			else:
				var empty: Array[Unit] = []
				return empty
		_:
			var empty: Array[Unit] = []
			return empty

# DEBUG: Force battle result for testing
func force_victory() -> void:
	print("BattleManager: FORCE VICTORY - killing all enemies")
	for unit in enemy_units:
		if unit.is_alive:
			# Set HP directly to bypass defense calculation
			unit.current_hp = 0
			unit.is_alive = false
			unit.died.emit()
	_check_battle_end()

func force_defeat() -> void:
	print("BattleManager: FORCE DEFEAT - killing all allies")
	for unit in ally_units:
		if unit.is_alive:
			# Set HP directly to bypass defense calculation
			unit.current_hp = 0
			unit.is_alive = false
			unit.died.emit()
	_check_battle_end()

# ====================================
# Phase 5A: Battle Map Integration
# ====================================

## 맵 설정
func set_battle_map(map: BattleMap) -> void:
	battle_map = map

## 맵 반환
func get_battle_map() -> BattleMap:
	return battle_map

## 위치에 군단이 있는지 확인
func is_position_occupied(pos: Vector2i) -> bool:
	return corps_positions.has(pos)

## 위치의 군단 반환
func get_corps_at_position(pos: Vector2i) -> Corps:
	return corps_positions.get(pos, null)

## 모든 점유 위치 반환 (MovementOverlay용)
func get_all_occupied_positions() -> Dictionary:
	return corps_positions.duplicate()

# ====================================
# Phase 5B: Corps System
# ====================================

## 군단 생성 및 추가
func add_corps(corps: Corps, grid_pos: Vector2i) -> void:
	if corps == null:
		return

	# 지형 타일 가져오기
	var terrain: TerrainTile = null
	if battle_map != null:
		terrain = battle_map.get_terrain_at(grid_pos)

	# 위치 설정
	corps.set_grid_position(grid_pos, terrain)
	corps_positions[grid_pos] = corps

	# ATB 시그널 연결
	corps.atb_filled.connect(_on_corps_atb_filled)
	corps.destroyed.connect(_on_corps_destroyed.bind(corps))

	# 아군/적군 배열에 추가
	if corps.is_ally:
		ally_corps.append(corps)
	else:
		enemy_corps.append(corps)

	print("BattleManager: Added %s at %s" % [corps.get_display_name(), grid_pos])

## 군단 제거
func remove_corps(corps: Corps) -> void:
	if corps == null:
		return

	# 위치에서 제거
	corps_positions.erase(corps.grid_position)

	# 배열에서 제거
	if corps in ally_corps:
		ally_corps.erase(corps)
	elif corps in enemy_corps:
		enemy_corps.erase(corps)

	# 대기 중인 명령 제거
	pending_commands.erase(corps)

## 군단 ATB 채워짐 핸들러
func _on_corps_atb_filled(corps: Corps) -> void:
	if state == BattleState.RUNNING and not corps_action_queue.has(corps):
		corps_action_queue.append(corps)
		corps_action_ready.emit(corps)

## 군단 파괴 핸들러
func _on_corps_destroyed(corps: Corps) -> void:
	print("BattleManager: %s destroyed!" % corps.get_display_name())
	remove_corps(corps)
	_check_corps_battle_end()

## 군단 ATB 업데이트
func _update_corps_atb(delta: float) -> void:
	for corps in ally_corps + enemy_corps:
		if corps.is_alive:
			corps.tick_atb(delta)

## 군단 전투 종료 확인
func _check_corps_battle_end() -> void:
	var allies_alive = ally_corps.filter(func(c): return c.is_alive)
	var enemies_alive = enemy_corps.filter(func(c): return c.is_alive)

	if enemies_alive.is_empty():
		_end_battle(true)
	elif allies_alive.is_empty():
		_end_battle(false)

# ====================================
# Phase 5C: Command System
# ====================================

## 명령 설정
func set_corps_command(corps: Corps, command: CorpsCommand) -> void:
	if corps == null or command == null:
		return

	pending_commands[corps] = command

	# 이동 명령은 별도로 저장 (글로벌 턴에 실행)
	if command.type == CorpsCommand.CommandType.MOVE:
		if command not in movement_commands:
			movement_commands.append(command)
		print("BattleManager: Movement command queued for %s to %s" % [
			corps.get_display_name(), command.target_position
		])

## 명령 취소
func cancel_corps_command(corps: Corps) -> void:
	if corps in pending_commands:
		var cmd = pending_commands[corps]
		if cmd in movement_commands:
			movement_commands.erase(cmd)
		pending_commands.erase(corps)

## 즉시 실행 가능한 명령 처리 (ATTACK, DEFEND, WATCH, CHANGE_FORMATION)
func process_immediate_command(corps: Corps) -> void:
	if corps not in pending_commands:
		# 기본 명령: 공격
		_execute_auto_attack_corps(corps)
		return

	var command: CorpsCommand = pending_commands[corps]
	var should_remove_command = true  # 명령 제거 여부

	match command.type:
		CorpsCommand.CommandType.ATTACK:
			# ATTACK 명령은 공격 성공 시에만 제거
			should_remove_command = _execute_attack_command(command)
		CorpsCommand.CommandType.DEFEND:
			_execute_defend_command(command)
		CorpsCommand.CommandType.WATCH:
			_execute_watch_command(command)
		CorpsCommand.CommandType.CHANGE_FORMATION:
			_execute_formation_change_command(command)
		CorpsCommand.CommandType.MOVE:
			# 이동 명령은 글로벌 턴에 실행됨 - 여기서는 대기
			print("BattleManager: %s waiting for movement phase" % corps.get_display_name())
			corps.reset_atb()
			return

	# 명령 실행 후 ATB 리셋
	corps.reset_atb()

	# 명령 제거 (ATTACK은 조건부)
	if should_remove_command:
		pending_commands.erase(corps)
		command_executed.emit(command)

## 공격 명령 실행 (Phase 5C: 이동 + 공격)
## returns: 공격 성공 여부 (true면 명령 제거, false면 명령 유지)
func _execute_attack_command(command: CorpsCommand) -> bool:
	var attacker = command.source_corps
	var target = command.target_corps

	if target == null or not target.is_alive:
		# 대상이 죽었으면 새 타겟 찾기
		# 1) 사거리 내 대상 우선
		target = _find_target_in_range(attacker)

		# 2) 사거리 내에 없으면 전체 맵에서 가장 가까운 적 찾기
		if target == null:
			target = _find_closest_enemy(attacker)

		# 3) 적이 아예 없으면 명령 제거
		if target == null:
			print("BattleManager: %s has no enemies left - command removed" % attacker.get_display_name())
			return true  # 명령 제거

		# 새 타겟으로 명령 갱신
		command.target_corps = target
		print("BattleManager: %s switches target to %s" % [
			attacker.get_display_name(), target.get_display_name()
		])

	# 사거리 확인
	if attacker.is_target_in_range(target):
		# 사거리 내 - 즉시 공격
		var damage = attacker.attack_target(target)
		print("BattleManager: %s attacks %s for %d damage (range: %d)" % [
			attacker.get_display_name(), target.get_display_name(), damage, attacker.get_attack_range()
		])
		return true  # 공격 성공 - 명령 제거
	else:
		# 사거리 밖 - 대상을 향해 이동
		var moved = _move_towards_target(attacker, target)
		if moved:
			print("BattleManager: %s moves toward %s (dist: %d -> %d)" % [
				attacker.get_display_name(), target.get_display_name(),
				attacker.distance_to(target) + 1, attacker.distance_to(target)
			])
			# 이동 후 사거리 확인 - 사거리 내에 들어왔으면 공격
			if attacker.is_target_in_range(target):
				var damage = attacker.attack_target(target)
				print("BattleManager: %s attacks %s after moving for %d damage" % [
					attacker.get_display_name(), target.get_display_name(), damage
				])
				return true  # 공격 성공 - 명령 제거
			else:
				return false  # 이동만 함 - 명령 유지
		else:
			print("BattleManager: %s cannot move toward %s - path blocked, command removed" % [
				attacker.get_display_name(), target.get_display_name()
			])
			return true  # 이동 불가 - 명령 제거

## 방어 명령 실행
func _execute_defend_command(command: CorpsCommand) -> void:
	var corps = command.source_corps
	# 방어 버프 적용 (방어력 +50%, 1턴)
	var Buff = preload("res://src/core/buff.gd")
	var defend_buff = Buff.new({
		"id": "defend_command",
		"type": "buff",
		"stat": "defense",
		"value": 50.0,
		"value_type": "percent",
		"duration": 1,
		"source": "command"
	})
	corps.add_buff(defend_buff)
	print("BattleManager: %s is defending (+50%% DEF for 1 turn)" % corps.get_display_name())

## 회피 명령 실행
## 진형 변경 명령 실행 (Phase 5C)
func _execute_formation_change_command(command: CorpsCommand) -> void:
	var corps = command.source_corps
	if command.target_formation == null:
		push_warning("BattleManager: Formation change command without target formation")
		corps.reset_atb()
		return

	# 진형 변경 (formation_id를 전달)
	corps.set_formation(command.target_formation.id)
	print("BattleManager: %s changed formation to %s" % [
		corps.get_display_name(),
		command.target_formation.get_display_name()
	])

	corps.reset_atb()
	command_executed.emit(command)

## 경계 명령 실행 (Phase 5C)
func _execute_watch_command(command: CorpsCommand) -> void:
	var corps = command.source_corps
	# 경계 상태는 별도 플래그로 관리 (TODO: 반격 시스템 구현)
	print("BattleManager: %s is watching (counterattack ready)" % corps.get_display_name())

## 자동 공격 (군단 버전)
func _execute_auto_attack_corps(attacker: Corps) -> void:
	# 사거리 내 대상 찾기
	var target = _find_target_in_range(attacker)

	if target == null:
		# 사거리 내 대상 없음 - ATB 리셋만 하고 대기
		print("BattleManager: %s has no targets in range (range: %d) - skipping attack" % [
			attacker.get_display_name(), attacker.get_attack_range()
		])
		attacker.reset_atb()
		return

	var damage = attacker.attack_target(target)
	print("BattleManager: %s auto-attacks %s for %d damage (range: %d)" % [
		attacker.get_display_name(), target.get_display_name(), damage, attacker.get_attack_range()
	])
	attacker.reset_atb()

## 가장 가까운 군단 찾기
func _find_closest_corps(from_corps: Corps, targets: Array) -> Corps:
	if targets.is_empty():
		return null

	var closest = targets[0]
	var closest_dist = _manhattan_distance(from_corps.grid_position, closest.grid_position)

	for target in targets:
		var dist = _manhattan_distance(from_corps.grid_position, target.grid_position)
		if dist < closest_dist:
			closest = target
			closest_dist = dist

	return closest


## 사거리 내 대상 찾기 (가장 가까운 적 우선)
func _find_target_in_range(attacker: Corps) -> Corps:
	var targets = enemy_corps if attacker.is_ally else ally_corps
	var alive_targets = targets.filter(func(c): return c.is_alive)

	if alive_targets.is_empty():
		return null

	# 사거리 내 대상만 필터링
	var in_range_targets = attacker.get_targets_in_range(alive_targets)

	if in_range_targets.is_empty():
		return null

	# 사거리 내 가장 가까운 대상 반환
	return _find_closest_corps(attacker, in_range_targets)


## 가장 가까운 적 찾기 (전체 맵 탐색)
func _find_closest_enemy(attacker: Corps) -> Corps:
	var targets = enemy_corps if attacker.is_ally else ally_corps
	var alive_targets = targets.filter(func(c): return c.is_alive)

	if alive_targets.is_empty():
		return null

	return _find_closest_corps(attacker, alive_targets)


## 아군/적군의 사거리 내 대상 목록 반환 (UI용)
func get_attackable_targets(corps: Corps) -> Array:
	if corps == null or not corps.is_alive:
		return []

	var targets = enemy_corps if corps.is_ally else ally_corps
	var alive_targets = targets.filter(func(c): return c.is_alive)

	return corps.get_targets_in_range(alive_targets)

## 맨해튼 거리 계산
func _manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

## 대상을 향해 이동 (Phase 5C: ATTACK 명령용 - BFS로 최적 경로 탐색)
## returns: 이동 성공 여부
func _move_towards_target(attacker: Corps, target: Corps) -> bool:
	if attacker == null or target == null:
		return false

	var current_pos = attacker.grid_position
	var target_pos = target.grid_position
	var movement_range = attacker.get_movement_range()

	# BFS로 도달 가능한 모든 타일 탐색
	var queue: Array = []  # [{pos: Vector2i, cost: float}]
	var visited: Dictionary = {}  # Vector2i -> float (누적 이동 비용)
	var reachable_tiles: Array = []  # [{pos: Vector2i, distance: int}]

	queue.append({"pos": current_pos, "cost": 0.0})
	visited[current_pos] = 0.0

	# 4방향 탐색용
	var directions = [
		Vector2i(0, -1),  # 위
		Vector2i(0, 1),   # 아래
		Vector2i(-1, 0),  # 왼쪽
		Vector2i(1, 0)    # 오른쪽
	]

	while not queue.is_empty():
		var current = queue.pop_front()
		var pos = current["pos"]
		var cost = current["cost"]

		# movement_range 초과하면 스킵
		if cost > movement_range:
			continue

		# 도달 가능한 타일 기록 (현재 위치 제외)
		if pos != current_pos:
			var distance = _manhattan_distance(pos, target_pos)
			reachable_tiles.append({"pos": pos, "distance": distance})

		# 4방향 탐색
		for dir in directions:
			var new_pos = pos + dir

			# 맵 범위 확인
			if battle_map != null and not battle_map.is_valid_position(new_pos):
				continue

			# 통행 가능 확인
			if battle_map != null and not battle_map.is_passable(new_pos):
				continue

			# 점유 확인 (대상 위치는 제외)
			if new_pos != target_pos and is_position_occupied(new_pos):
				continue

			# 지형 비용 가져오기
			var terrain_cost = 1.0
			if battle_map != null:
				var terrain = battle_map.get_terrain_at(new_pos)
				if terrain:
					terrain_cost = terrain.movement_cost

			var new_cost = cost + terrain_cost

			# movement_range 초과하면 스킵
			if new_cost > movement_range:
				continue

			# 이미 방문했고 더 낮은 비용으로 도달했으면 스킵
			if new_pos in visited and visited[new_pos] <= new_cost:
				continue

			# 방문 기록
			visited[new_pos] = new_cost

			# 큐에 추가
			queue.append({"pos": new_pos, "cost": new_cost})

	# 도달 가능한 타일 중 대상까지 거리가 가장 가까운 타일 찾기
	if reachable_tiles.is_empty():
		return false

	reachable_tiles.sort_custom(func(a, b): return a["distance"] < b["distance"])
	var best_tile = reachable_tiles[0]
	var best_pos = best_tile["pos"]

	# 이동 실행
	corps_positions.erase(current_pos)

	var new_terrain: TerrainTile = null
	if battle_map != null:
		new_terrain = battle_map.get_terrain_at(best_pos)

	attacker.set_grid_position(best_pos, new_terrain)
	corps_positions[best_pos] = attacker

	return true

# ====================================
# Phase 5C: Movement Phase
# ====================================

## 이동 페이즈 실행 (글로벌 턴에서 호출)
func _execute_movement_phase() -> void:
	if movement_commands.is_empty():
		return

	print("=== MOVEMENT PHASE START ===")
	state = BattleState.MOVEMENT_PHASE
	movement_phase_started.emit()

	# 이동 명령들을 순차적으로 실행
	var commands_to_execute = movement_commands.duplicate()
	movement_commands.clear()

	for command in commands_to_execute:
		if command.is_valid():
			_execute_move_command(command)
			command.executed = true
			command_executed.emit(command)
		else:
			print("BattleManager: Invalid move command skipped")

	print("=== MOVEMENT PHASE END ===")
	movement_phase_ended.emit()

## 이동 명령 실행
func _execute_move_command(command: CorpsCommand) -> void:
	var corps = command.source_corps
	var destination = command.target_position

	if corps == null or not corps.is_alive:
		return

	# 목적지 유효성 확인
	if battle_map != null and not battle_map.is_passable(destination):
		print("BattleManager: Cannot move to impassable tile %s" % destination)
		return

	if is_position_occupied(destination):
		print("BattleManager: Destination %s is occupied" % destination)
		return

	# 이동 실행
	var old_pos = corps.grid_position
	corps_positions.erase(old_pos)

	var new_terrain: TerrainTile = null
	if battle_map != null:
		new_terrain = battle_map.get_terrain_at(destination)

	corps.set_grid_position(destination, new_terrain)
	corps_positions[destination] = corps

	print("BattleManager: %s moved from %s to %s" % [
		corps.get_display_name(), old_pos, destination
	])

	# 명령 제거
	pending_commands.erase(corps)
