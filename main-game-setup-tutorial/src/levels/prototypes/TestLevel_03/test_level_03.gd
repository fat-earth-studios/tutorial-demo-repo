class_name TestLevel03
extends BaseLevel

@onready var player_spawn  : PlayerSpawn = $LevelObjects/PlayerSpawn
@onready var player_camera : Camera2D    = $LevelObjects/PlayerCamera

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func _physics_process(_delta: float) -> void:
	pass


func get_default_player_spawn() -> Vector2:
	return player_spawn.global_position

func get_player_camera() -> Camera2D:
	return player_camera
