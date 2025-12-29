extends Node

# Phase 3: Stub only - meta-progression in Phase 4
# This manager will handle:
# - Permanent unlocks (generals, cards, internal affairs options)
# - Meta-progression stats (total victories, best run, etc.)
# - SaveManager must keep meta-progression SEPARATE from run state

var meta_progression: Dictionary = {
	"unlocked_generals": ["gyeonhwon", "wanggeon", "singeom"],  # Starter generals
	"unlocked_cards": [],
	"total_victories": 0,
	"best_stage_reached": 0
}

func _ready() -> void:
	print("SaveManager: Initialized (stub - Phase 4)")

# Placeholder methods
func save_meta_progression() -> void:
	print("SaveManager: save_meta_progression() not yet implemented (Phase 4)")

func load_meta_progression() -> void:
	print("SaveManager: load_meta_progression() not yet implemented (Phase 4)")

func unlock_general(general_id: String) -> void:
	if not meta_progression["unlocked_generals"].has(general_id):
		meta_progression["unlocked_generals"].append(general_id)

func is_general_unlocked(general_id: String) -> bool:
	return meta_progression["unlocked_generals"].has(general_id)
