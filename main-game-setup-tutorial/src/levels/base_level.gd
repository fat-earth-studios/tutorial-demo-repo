@abstract
class_name BaseLevel
extends Node2D
## Abstract class for levels

## Provides a player spawn location
@abstract func get_default_player_spawn() -> Vector2

## Provides the camera used in the level
@abstract func get_player_camera() -> Camera2D  # FUTURE (camera): This should be moved out of level into camera system/manager
