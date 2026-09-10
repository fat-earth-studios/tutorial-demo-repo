@abstract
class_name BaseLevel
extends Node2D
## Abstract class for levels

signal level_transition_requested(level_scene_uid : String)
signal battle_transition_requested(battle_scene_uid : String)

func _on_level_transition_requested(level_scene_uid : String) -> void:
	level_transition_requested.emit(level_scene_uid)

func _on_battle_transition_requested(battle_scene_uid : String) -> void:
	battle_transition_requested.emit(battle_scene_uid)

## Provides default global position for player to be placed in level
@abstract func get_default_player_spawn() -> Vector2

## Provides the camera used in the level
@abstract func get_player_camera() -> Camera2D  # FUTURE (camera): This should be moved out of level into camera system/manager
