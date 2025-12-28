class_name Unit
extends RefCounted

# Preload dependencies
const Buff = preload("res://src/core/buff.gd")

# Signals
signal atb_filled(unit: Unit)
signal took_damage(amount: int, current_hp: int)
signal died()

# Identity
var id: String
var display_name: String
var category: String  # infantry, cavalry, archer

# Stats
var max_hp: int
var current_hp: int
var attack: int
var defense: int
var atb_speed: float

# ATB
var atb_current: float = 0.0
var atb_max: float = 100.0

# Traits & Buffs
var traits: Array = []
var active_buffs: Array[Buff] = []  # Phase 2: Buff/debuff system

# General reference (Phase 2: For skill execution)
var general: General = null

# Battle state
var is_ally: bool = true
var is_alive: bool = true
var formation_position: String  # front, back

# Constructor
func _init(data: Dictionary) -> void:
	id = data.get("id", "")
	display_name = data.get("name_key", "")  # Will be localized by DataManager
	category = data.get("category", "infantry")
	formation_position = data.get("formation_position", "front")

	var stats = data.get("base_stats", {})
	max_hp = stats.get("hp", 100)
	current_hp = max_hp
	attack = stats.get("attack", 20)
	defense = stats.get("defense", 10)
	atb_speed = stats.get("atb_speed", 1.0)

	traits = data.get("traits", [])

# ATB Update (called every frame)
func tick_atb(delta: float) -> void:
	if not is_alive:
		return

	# Use effective ATB speed (includes buffs)
	atb_current += get_effective_atb_speed() * delta * 10.0  # Scale factor for faster testing

	if atb_current >= atb_max:
		atb_current = atb_max
		atb_filled.emit(self)

# Reset ATB after action
func reset_atb() -> void:
	atb_current = 0.0

# Combat
func take_damage(amount: int) -> void:
	# Use effective defense (includes buffs)
	var mitigated = maxi(1, amount - get_effective_defense())  # Min 1 damage
	current_hp = maxi(0, current_hp - mitigated)
	took_damage.emit(mitigated, current_hp)

	if current_hp <= 0:
		is_alive = false
		died.emit()

func calculate_attack_damage(target: Unit) -> int:
	# Use effective attack (includes buffs)
	var damage = get_effective_attack()

	# Apply trait bonuses (e.g., anti-cavalry)
	for trait_data in traits:
		var effect = trait_data.get("effect", {})
		if effect.has("damage_bonus_vs"):
			if effect["damage_bonus_vs"] == target.category:
				var bonus_pct = effect.get("bonus_percent", 0)
				damage = int(damage * (1.0 + bonus_pct / 100.0))
	return damage

func attack_target(target: Unit) -> void:
	var damage = calculate_attack_damage(target)
	target.take_damage(damage)

# Buff management (Phase 2)
func add_buff(buff: Buff) -> void:
	active_buffs.append(buff)
	buff.duration_expired.connect(_on_buff_expired)
	print(display_name, " gained buff: ", buff.get_display_name(), " (", buff.duration, " turns)")

func remove_buff(buff: Buff) -> void:
	active_buffs.erase(buff)
	print(display_name, " lost buff: ", buff.get_display_name())

func _on_buff_expired(buff: Buff) -> void:
	remove_buff(buff)

func tick_buff_durations() -> void:
	# Called once per global turn
	for buff in active_buffs.duplicate():  # Duplicate to avoid modification during iteration
		buff.tick_duration()

# Effective stat calculation (includes buffs)
func get_effective_attack() -> int:
	var total = float(attack)
	for buff in active_buffs:
		if buff.stat == Buff.Stat.ATTACK:
			total += buff.calculate_modifier(attack)
	return int(total)

func get_effective_defense() -> int:
	var total = float(defense)
	for buff in active_buffs:
		if buff.stat == Buff.Stat.DEFENSE:
			total += buff.calculate_modifier(defense)
	return maxi(0, int(total))  # Defense can't go negative

func get_effective_atb_speed() -> float:
	var total = atb_speed
	for buff in active_buffs:
		if buff.stat == Buff.Stat.ATB_SPEED:
			total += buff.calculate_modifier(atb_speed)
	return maxf(0.1, total)  # Minimum speed to prevent freezing
