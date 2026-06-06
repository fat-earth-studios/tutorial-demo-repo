class_name TestLevel02
extends BaseLevel
## PLACEHOLDER: This script and corresponding scene exists only to provide a level for demonstrating the project foundation.
## It is not intended as an example of a completed level scene or script.

## FUTURE (level): Replace with the actual level implementation.

@onready var player_spawn_marker : PlayerSpawn = $Entities/PlayerSpawn
# FUTURE (camera): This will be moved to camera system/manager
@onready var player_camera : Camera2D = $Entities/PlayerCamera

func get_default_player_spawn() -> Vector2:
	return player_spawn_marker.global_position

func get_player_camera() -> Camera2D:
	return player_camera
