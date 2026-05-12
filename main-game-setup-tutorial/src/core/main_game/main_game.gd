class_name MainGame
extends Node
## Main entry point for the game. Responsible for setting up the World layers and high level systems

var TEST_LEVEL    : PackedScene = load("uid://ctyxyue66gfjy")
var TEST_LEVEL_02 : PackedScene = load("uid://kikf44gko1yv")

var _current_level : Node = null

@onready var game_display_layer : Control = $GameDisplayLayer

# Game World root nodes
@onready var level_root  : Node2D = %LevelRoot
@onready var entity_root : Node2D = %EntityRoot
@onready var effect_root : Node2D = %EffectRoot

# UI Root Nodes
@onready var hud_root : Control = %HudRoot


func _ready() -> void:
	# Provide access to main game through global script
	Global.main_game = self

	load_level(TEST_LEVEL_02)
	#load_level(TEST_LEVEL)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"exit_appliation"):
		print_debug("Qutting game - orphan nodes (if nothing prints everything is ok)")
		print_orphan_nodes()
		#get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
		get_tree().quit()

	if event.is_action_pressed(&"zoom_in"):
		game_display_layer.zoom_in()

	if event.is_action_pressed(&"zoom_out"):
		game_display_layer.zoom_out()


func setup_game() -> void:
	pass

## Simple instantiation of input level scene and adding it as a child of the level layer
func load_level(level_scene : PackedScene) -> void:
	if _current_level != null:
		_current_level.queue_free()

	_current_level = level_scene.instantiate()
	level_root.add_child(_current_level)
