class_name General
extends RefCounted

var id: String
var display_name: String
var nation: String
var role: String  # assault, command, special
var portrait_path: String

var leadership: int
var combat: int
var intelligence: int
var politics: int

var skill: Dictionary  # Skill data (not implemented in Phase 1)

func _init(data: Dictionary) -> void:
	id = data.get("id", "")
	display_name = data.get("name_key", "")  # Will be localized by DataManager
	nation = data.get("nation", "")
	role = data.get("role", "assault")
	portrait_path = data.get("portrait", "")

	var stats = data.get("base_stats", {})
	leadership = stats.get("leadership", 50)
	combat = stats.get("combat", 50)
	intelligence = stats.get("intelligence", 50)
	politics = stats.get("politics", 50)

	skill = data.get("skill", {})
