class_name MainGame
extends Node
## Main entry point for the game.
## Responsible for setting up the World layers and coordinating high-level systems.

# FUTURE (main menu): Load test level for prototype
# FUTURE (scene organization): Remove hard coded scene list in main
const TEST_LEVEL_02    : String = "uid://kikf44gko1yv"
const TEST_LEVEL_03    : String = "uid://be8ai3x7gg6h4"
const PLAYER_SCENE_UID : String = "uid://bk2cu2ameptuy"
const BATTLE_UI        : String = "uid://crwgde4f1udwl"

var player : Player = null

var _current_level : BaseLevel = null
var _current_ui    : Control = null
var _current_battle : BattleArena

# Game World root nodes
@onready var _level_root  : Node2D = %LevelRoot
@onready var _entity_root : Node2D = %EntityRoot
#@onready var _effect_root : Node2D = %EffectRoot  # FUTURE: Effects

# UI Root Nodes (FUTURE)
@onready var _ui_root         : Control = %UIRoot
#@onready var _pause_root      : Control = %PauseRoot  # FUTURE: (Pause Menu)
#@onready var _transition_root : Control = %TransitionRoot  # FUTURE: (Fading Transitions)

@onready var _systems_root : Node = $Systems

func _ready() -> void:
	_init_player()

	load_level(TEST_LEVEL_02)


func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return

	if event.is_action_pressed(&"debug_quit"):
		print_orphan_nodes() # <- just to check if any orphan nodes exist while testing
		quit_game()


## Called to quit the application
## Propagates the close request notification to every node, and then quits the application
func quit_game() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()


## Instantiates the player and adds it to the entity layer
func _init_player() -> void:
	var player_instance : Node = _instantiate_scene_from_uid(PLAYER_SCENE_UID)

	if player_instance == null:
		push_error("Could not instantiate player scene " + PLAYER_SCENE_UID)
		return

	if player_instance is not Player:
		player_instance.free() # Node must be freed to avoid unreferenced orphan nodes
		push_error("Loaded player scene is not of type Player " + PLAYER_SCENE_UID)
		return

	player = player_instance as Player

	_entity_root.add_child(player)

func _init_systems() -> void:
	pass # FUTURE (systems): Will be called to set up high level systems

#region Level load

## Loads a level scene that must extend BaseLevel
func load_level(level_scene_uid : String) -> void:
	_unload_current_level()

	var new_level : Node = _instantiate_scene_from_uid(level_scene_uid)

	if new_level == null:
		push_error("Failed to instantiate level scene " + level_scene_uid)
		return

	if new_level is not BaseLevel:
		new_level.free()  # Level must be freed to avoid unreferenced orphan nodes
		push_error("Loaded level is not of type BaseLevel " + level_scene_uid)
		return
	# FUTURE (main menu): Should have a fall back scene

	_current_level = new_level

	_current_level.level_transition_requested.connect(_on_current_level_transition_requested)
	_current_level.battle_transition_requested.connect(
			_on_current_level_battle_transition_requested
	)

	_level_root.add_child(_current_level)

	_place_player_at_level_spawn()
	_setup_level_camera()


## Checks if valid instance of _current_level exists and
##  removes it from scene tree and queues it to free
func _unload_current_level() -> void:
	if is_instance_valid(_current_level):
		var outgoing_level : Node = _current_level
		_current_level = null
		_level_root.remove_child(outgoing_level)
		outgoing_level.queue_free()


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

#endregion


#region UI Functions

## Loads, instantiates, and adds input UI scene to UI root
func load_ui(ui_scene_uid : String) -> void:
	_unload_current_ui()

	var new_ui : Node = _instantiate_scene_from_uid(ui_scene_uid)

	if new_ui == null:
		push_error("Could not instantiate new ui " + ui_scene_uid)
		return

	_current_ui = new_ui

	_ui_root.add_child(_current_ui)

func _unload_current_ui() -> void:
	if is_instance_valid(_current_ui):
		var outgoing_ui : Node = _current_ui
		_current_ui = null
		_ui_root.remove_child(outgoing_ui)
		outgoing_ui.queue_free()

#endregion



#region battle functions

## Called to enter a battle scene, will load the necessray scenes and start a battle session
func start_battle(battle_scene_uid : String) -> void:
	load_battle_scene(battle_scene_uid)
	if not is_instance_valid(_current_battle): #TODO: Look into load_battle_scene returning status
		push_error("Battle Instance not valid after loading")
		return

	load_ui(BATTLE_UI) # FUTURE: Remove Hard Coding
	if not is_instance_valid(_current_ui):
		push_error("Battle UI invalid after loading")

	# FUTURE: (battle actor components) - Add other party members and enemies
	var party_actors : Array[BattleActorComponent] = [player.battle_actor_component]

	var battle_session : BattleSession = BattleSession.new()
	battle_session.setup(self, _current_battle, _current_ui, party_actors)

	battle_session.battle_finished.connect(
			_on_battle_finished.bind(battle_session), CONNECT_ONE_SHOT
	)

	_systems_root.add_child(battle_session)
	battle_session.start()


func load_battle_scene(battle_scene_uid : String) -> void:
	# Battle scene will load into the level root
	# FUTURE: (retain pre-battle state) Save reference to level and remove from tree
	#          to re-enter tree once battle has completed
	_unload_current_level()

	var new_battle_instance : Node = _instantiate_scene_from_uid(battle_scene_uid)

	if new_battle_instance == null:
		push_error("Could not instantiate new level " + battle_scene_uid)
		return

	_current_battle = new_battle_instance as BattleArena

	# TODO: Connect any pre-battle markers (players to jump to)

	_level_root.add_child(_current_battle)

	#TODO: Should this have a return code for success, fail, other possible outcomes??

#endregion


#region helper functions

## Returns an instantiated Node that has not been added to the scene tree.
## The caller owns the returned Node and must either add or free it
func _instantiate_scene_from_uid(scene_uid : String) -> Node:
	var scene_packed : PackedScene = (
			ResourceLoader.load(scene_uid, "PackedScene") as PackedScene
	)

	if scene_packed == null:
		return null

	# The caller owns this node and is responsible to check if it is valid
	return scene_packed.instantiate()


#endregion

#region signal handlers

func _on_current_level_transition_requested(new_level_uid : String) -> void:
	load_level.call_deferred(new_level_uid)


func _on_current_level_battle_transition_requested(new_battle_uid : String) -> void:
	start_battle.call_deferred(new_battle_uid)


func _on_battle_finished(session : BattleSession) -> void:
	session.queue_free()
	# TODO: Probably needs more things

#endregion
