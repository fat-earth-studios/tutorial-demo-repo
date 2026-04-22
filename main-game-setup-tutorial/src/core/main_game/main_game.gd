class_name MainGame
extends Node
## Main entry point for the game. Responsible for setting up the World layers and high level systems

var TEST_LEVEL = load("uid://ctyxyue66gfjy")

var _current_level : Node = null

@onready var level_layer : Node2D = %LevelLayer

func _ready() -> void:
	# Provide access to main game through global script
	Global.main_game = self

	load_level(TEST_LEVEL)


func setup_game() -> void:
	pass

## Simple instantiation of input level scene and adding it as a child of the level layer
func load_level(level_scene : PackedScene) -> void:
	if _current_level != null:
		_current_level.queue_free()

	_current_level = level_scene.instantiate()
	level_layer.add_child(_current_level)
