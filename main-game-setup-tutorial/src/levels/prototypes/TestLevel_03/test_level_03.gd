class_name TestLevel03
extends BaseLevel

@onready var player_spawn  : PlayerSpawn = $LevelObjects/PlayerSpawn
@onready var player_camera : Camera2D    = $LevelObjects/PlayerCamera

@onready var level_transition: LevelTransition = $Transitions/LevelTransition

func _ready() -> void:
	level_transition.transition_requested.connect(_on_level_transition_requested)

func _process(_delta: float) -> void:
	pass

func _physics_process(_delta: float) -> void:
	pass


func get_default_player_spawn() -> Vector2:
	return player_spawn.global_position

func get_player_camera() -> Camera2D:
	return player_camera


func _on_level_transition_requested(scene_uid : String) -> void:
	print_debug("Level sees the transition")
	signal_level_transition.emit(scene_uid)
