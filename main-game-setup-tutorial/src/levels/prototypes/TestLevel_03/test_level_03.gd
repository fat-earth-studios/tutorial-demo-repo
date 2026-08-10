class_name TestLevel03
extends BaseLevel

@onready var player_spawn  : PlayerSpawn = $LevelObjects/PlayerSpawn
@onready var player_camera : Camera2D    = $LevelObjects/PlayerCamera

@onready var level_transition: LevelTransition = $Transitions/LevelTransition

func _ready() -> void:
	# Relay this transition volume's request through the BaseLevel request signal
	level_transition.transition_requested.connect(_request_level_transition)


func get_default_player_spawn() -> Vector2:
	return player_spawn.global_position

func get_player_camera() -> Camera2D:
	return player_camera
