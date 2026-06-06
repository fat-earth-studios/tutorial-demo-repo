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


## Called for loading a level scene.
## NOTE: The input level_scene must extend BaseLevel
func load_level(level_scene : String) -> void:
	# Make sure this is called during idle time
	_deferred_load_level.call_deferred(level_scene)

func _deferred_load_level(level_scene_uid : String) -> void:
	if _current_level != null:
		_current_level.queue_free()
		_current_level = null

	# Allow the old level to finish freeing before adding the new one
	await get_tree().process_frame

	var new_level_packed : PackedScene =\
		ResourceLoader.load(level_scene_uid, "PackedScene") as PackedScene
	if new_level_packed == null:
		push_error("Could not load level as a packed scene: " + level_scene_uid)
		return

	_current_level = new_level_packed.instantiate() as BaseLevel
	if _current_level == null:
		push_error("Loaded level is not of type Level or does not exist")
		return
		# FUTURE (main menu): Should have a fall back scene

	level_root.add_child(_current_level)

	# Allow level to fully process before accessing it
	await get_tree().process_frame
	_place_player_at_level_spawn()
	_setup_level_camera()


## Instantiates the player and adds it to the entity layer
func _init_player() -> void:
	var player_scene : PackedScene = ResourceLoader.load(PLAYER_SCENE_UID) as PackedScene
	if player_scene == null:
		push_error("Could not load player scene: " + PLAYER_SCENE_UID)
		return

	player = player_scene.instantiate() as Player
	if player == null:
		push_error("Loaded player scene does not extend player or DNE: " + PLAYER_SCENE_UID)
		return

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
	# Will become: camera_system.set_target(player)
	level_camera.target = player


func _init_systems() -> void:
	pass # FUTURE (systems): Will be called to set up high level systems
