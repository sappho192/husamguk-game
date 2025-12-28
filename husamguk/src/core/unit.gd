class_name Unit
extends RefCounted

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

# Traits & Buffs (Phase 1: simplified, no buffs)
var traits: Array = []

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

	atb_current += atb_speed * delta * 10.0  # Scale factor for faster testing

	if atb_current >= atb_max:
		atb_current = atb_max
		atb_filled.emit(self)

# Reset ATB after action
func reset_atb() -> void:
	atb_current = 0.0

# Combat
func take_damage(amount: int) -> void:
	var mitigated = maxi(1, amount - defense)  # Min 1 damage
	current_hp = maxi(0, current_hp - mitigated)
	took_damage.emit(mitigated, current_hp)

	if current_hp <= 0:
		is_alive = false
		died.emit()

func calculate_attack_damage(target: Unit) -> int:
	var damage = attack
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
