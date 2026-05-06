class_name MainGame
extends Node
## Main entry point for the game. Responsible for setting up the World layers and high level systems

var TEST_LEVEL = load("uid://ctyxyue66gfjy")
var TEST_LEVEL_02 = load("uid://kikf44gko1yv")

var _current_level : Node = null

@onready var level_root: Node2D = %LevelRoot

func _ready() -> void:
	# Provide access to main game through global script
	Global.main_game = self

	load_level(TEST_LEVEL_02)


func setup_game() -> void:
	pass

## Simple instantiation of input level scene and adding it as a child of the level layer
func load_level(level_scene : PackedScene) -> void:
	if _current_level != null:
		_current_level.queue_free()

	_current_level = level_scene.instantiate()
	level_root.add_child(_current_level)
