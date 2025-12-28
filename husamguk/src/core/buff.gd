class_name Buff
extends RefCounted

# Signals
signal duration_expired(buff: Buff)

# Enums
enum Type { BUFF, DEBUFF }
enum Stat { ATTACK, DEFENSE, HP, ATB_SPEED }

# Properties
var id: String
var buff_type: Type
var stat: Stat
var value: float  # Numeric value (flat or percent)
var value_type: String  # "flat" or "percent"
var duration: int  # Global turns remaining (0 = instant/permanent)
var source: String  # "skill" or "card"
var is_penalty: bool = false  # For penalty cards

# Constructor
func _init(data: Dictionary) -> void:
	id = data.get("id", "")
	buff_type = _parse_type(data.get("type", "buff"))
	stat = _parse_stat(data.get("stat", "attack"))
	value = data.get("value", 0.0)
	value_type = data.get("value_type", "flat")
	duration = data.get("duration", 0)
	source = data.get("source", "unknown")
	is_penalty = data.get("is_penalty", false)

# Type parsing
func _parse_type(type_string: String) -> Type:
	match type_string.to_lower():
		"buff":
			return Type.BUFF
		"debuff":
			return Type.DEBUFF
		_:
			return Type.BUFF

# Stat parsing
func _parse_stat(stat_string: String) -> Stat:
	match stat_string.to_lower():
		"attack":
			return Stat.ATTACK
		"defense":
			return Stat.DEFENSE
		"hp":
			return Stat.HP
		"atb_speed":
			return Stat.ATB_SPEED
		_:
			return Stat.ATTACK

# Calculate the modifier value for a given base stat
func calculate_modifier(base_value: float) -> float:
	if value_type == "percent":
		# Percent-based: multiply base by percentage
		var multiplier = value / 100.0
		if buff_type == Type.DEBUFF:
			return -base_value * multiplier
		else:
			return base_value * multiplier
	else:
		# Flat value: direct addition/subtraction
		if buff_type == Type.DEBUFF:
			return -value
		else:
			return value

# Tick down duration (called once per global turn)
func tick_duration() -> void:
	if duration > 0:
		duration -= 1
		if duration == 0:
			duration_expired.emit(self)

# Get display information for UI
func get_display_name() -> String:
	var stat_name = ""
	match stat:
		Stat.ATTACK:
			stat_name = "ATK"
		Stat.DEFENSE:
			stat_name = "DEF"
		Stat.HP:
			stat_name = "HP"
		Stat.ATB_SPEED:
			stat_name = "SPD"

	var sign = "+" if buff_type == Type.BUFF else "-"
	var value_str = ""
	if value_type == "percent":
		value_str = str(int(value)) + "%"
	else:
		value_str = str(int(value))

	return sign + value_str + " " + stat_name

func is_expired() -> bool:
	return duration == 0 and source != "permanent"
