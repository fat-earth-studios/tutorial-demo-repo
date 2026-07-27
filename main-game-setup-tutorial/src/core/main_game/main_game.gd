class_name MainGame
extends Node
## Main entry point for the game.
## Responsible for setting up the World layers and coordinating high-level systems.

# FUTURE (main menu): Load test level for prototype
const TEST_LEVEL_02    : String =  "uid://kikf44gko1yv"
const PLAYER_SCENE_UID : String =  "uid://bk2cu2ameptuy"

var player : Player = null

var _current_level : BaseLevel = null

# Game World root nodes
@onready var level_root  : Node2D = %LevelRoot
@onready var entity_root : Node2D = %EntityRoot
@onready var effect_root : Node2D = %EffectRoot

# UI Root Nodes (FUTURE)
@onready var hud_root        : Control = %HudRoot
@onready var pause_root      : Control = %PauseRoot
@onready var transition_root : Control = %TransitionRoot

func _ready() -> void:
	_init_player()

	load_level(TEST_LEVEL_02)


func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return

	if event.is_action_pressed(&"debug_quit"):
		quit_game()


## Called to quit the application
## Propagates the close request notification to every node, and then quits the application
func quit_game() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()


## Loads a level scene that must extend BaseLevel
func load_level(level_scene : String) -> void:
	# Make sure this is called during idle time
	_perform_level_load.call_deferred(level_scene)


func _perform_level_load(level_scene_uid : String) -> void:
	if is_instance_valid(_current_level):
		_current_level.queue_free()
		_current_level = null
		# Wait to allow the queued deletion to process so it is out of the scene tree
		await get_tree().process_frame


	var new_level_packed : PackedScene = (
			ResourceLoader.load(level_scene_uid, "PackedScene") as PackedScene
	)

	if new_level_packed == null:
		push_error("Could not load level as a packed scene: " + level_scene_uid)
		return

	var new_level : Node = new_level_packed.instantiate()

	if not new_level:
		push_error("Could not instantiate new level " + level_scene_uid)
		return

	if new_level is not BaseLevel:
		new_level.free()  # Level must be freed to avoid unreferenced orphan nodes
		push_error("Loaded level is not of type BaseLevel " + level_scene_uid)
		return
	# FUTURE (main menu): Should have a fall back scene

	_current_level = new_level as BaseLevel

	level_root.add_child(_current_level)

	_place_player_at_level_spawn()
	_setup_level_camera()


## Instantiates the player and adds it to the entity layer
func _init_player() -> void:
	var player_scene : PackedScene = ResourceLoader.load(PLAYER_SCENE_UID) as PackedScene
	if player_scene == null:
		push_error("Could not load player scene: " + PLAYER_SCENE_UID)
		return

	var player_instance : Node = player_scene.instantiate()
	if not player_instance:
		push_error("Could not instantiate player scene " + PLAYER_SCENE_UID)
		return

	if player_instance is not Player:
		player_instance.free() # Node must be freed to avoid unreferenced orphan nodes
		push_error("Loaded player scene is not of type Player " + PLAYER_SCENE_UID)
		return

	player = player_instance as Player

	entity_root.add_child(player)


## Finds the default spawn location in currently loaded level, and places
##  the Player at that position.
func _place_player_at_level_spawn() -> void:
	if player == null:
		push_error("Cannot place player in level because it is null")
		return
	if _current_level == null:
		push_error("Cannot place player into level because level is null")
		return

	player.global_position = _current_level.get_default_player_spawn()

## Attaches player to the current camera as the target
func _setup_level_camera() -> void:
	if player == null or _current_level == null:
		return

	var level_camera : Camera2D = _current_level.get_player_camera()
	if level_camera == null:
		return

	# FUTURE (camera): Temporary hookup
	# NOTE: target variable was added as part of the custom camera script used for the prototype
	level_camera.target = player


func _init_systems() -> void:
	pass # FUTURE (systems): Will be called to set up high level systems
