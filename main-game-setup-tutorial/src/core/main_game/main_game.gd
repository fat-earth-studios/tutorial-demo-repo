class_name MainGame
extends Node
## Main entry point for the game.
## Responsible for setting up the World layers and coordinating high-level systems.

# FUTURE (main menu): Load test level for prototype
const TEST_LEVEL_02    : String =  "uid://kikf44gko1yv"
const TEST_LEVEL_03    : String = "uid://be8ai3x7gg6h4"
const PLAYER_SCENE_UID : String =  "uid://bk2cu2ameptuy"
const BATTLE_UI : String        = "uid://crwgde4f1udwl"

var player : Player = null

var _current_level : BaseLevel = null
var _current_ui    : Control = null
var _current_battle : BattleArena

# Game World root nodes
@onready var level_root  : Node2D = %LevelRoot
@onready var entity_root : Node2D = %EntityRoot
@onready var effect_root : Node2D = %EffectRoot

# UI Root Nodes (FUTURE)
@onready var ui_root         : Control = %UIRoot
@onready var pause_root      : Control = %PauseRoot
@onready var transition_root : Control = %TransitionRoot

@onready var systems_root : Node = $Systems

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


## Loads a level scene that must extend BaseLevel
func load_level(level_scene : String) -> void:
	# Make sure this is called during idle time
	_perform_level_load.call_deferred(level_scene)


func _perform_level_load(level_scene_uid : String) -> void:
	if is_instance_valid(_current_level):
		# Passing reference to local variable allows for cleanly removing from tree
		#  while using _current_level to load the new scene
		var outgoing_level : Node = _current_level
		_current_level = null

		level_root.remove_child(outgoing_level)
		outgoing_level.queue_free()


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

	_current_level = new_level

	_current_level.signal_level_transition.connect(_level_transition_signaled)
	_current_level.request_battle_transition.connect(_battle_transition_signaled)

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

func load_ui(ui_scene_uid : String) -> void:
	_perform_load_ui_scene(ui_scene_uid)


func _perform_load_ui_scene(ui_scene_uid : String) -> void:
	if is_instance_valid(_current_ui):
		# Passing reference to local variable allows for cleanly removing from tree
		#  while using _current_level to load the new scene
		var outgoing_ui : Node = _current_ui
		_current_ui = null

		ui_root.remove_child(outgoing_ui)
		outgoing_ui.queue_free()


	var new_ui_packed : PackedScene = (
			ResourceLoader.load(ui_scene_uid, "PackedScene") as PackedScene
	)

	if new_ui_packed == null:
		push_error("Could not load UI as a packed scene: " + ui_scene_uid)
		return

	var new_ui : Node = new_ui_packed.instantiate()

	if not new_ui:
		push_error("Could not instantiate new ui " + ui_scene_uid)
		return


	_current_ui = new_ui

	#_current_level.signal_level_transition.connect(_level_transition_signaled)
	#_current_level.request_battle_transition.connect(_battle_transition_signaled)

	ui_root.add_child(_current_ui)


func _init_systems() -> void:
	pass # FUTURE (systems): Will be called to set up high level systems


func _load_battle(battle_scene_uid : String) -> void:
	_begin_battle.call_deferred(battle_scene_uid)


func _begin_battle(battle_scene_uid : String) -> void:
	perform_load_battle(battle_scene_uid)
	if not is_instance_valid(_current_battle):
		push_error("Battle Instance not valid after loading")
		return

	_perform_load_ui_scene(BATTLE_UI)
	if not is_instance_valid(_current_ui):
		push_error("Battle UI invalid after loading")

	var party_actors : Array[BattleActorComponent] = [player.battle_actor_component]


	var battle_session : BattleSession = BattleSession.new()
	battle_session.setup(self, _current_battle, _current_ui, party_actors)

	battle_session.battle_finished.connect(
			_on_battle_finished.bind(battle_session), CONNECT_ONE_SHOT
	)

	systems_root.add_child(battle_session)
	battle_session.start()


func perform_load_battle(battle_scene_uid : String) -> void:
	if is_instance_valid(_current_level):
		var outgoing_level : Node = _current_level
		_current_level = null
		level_root.remove_child(outgoing_level)
		outgoing_level.queue_free()

	var new_battle_packed : PackedScene = (
			ResourceLoader.load(battle_scene_uid, "PackedScene") as PackedScene
	)

	if new_battle_packed == null:
		push_error("Could not load level as a packed scene: " + battle_scene_uid)
		return

	var new_battle : Node = new_battle_packed.instantiate()

	if not new_battle:
		push_error("Could not instantiate new level " + battle_scene_uid)
		return

	_current_battle = new_battle

	level_root.add_child(_current_battle)


func _level_transition_signaled(string_uid : String) -> void:
	load_level(string_uid)
	#print_debug("Main Game sees requested transition")



func _battle_transition_signaled(string_uid : String) -> void:
	print_debug("Main game got the battle transition signal")
	_load_battle(string_uid)
	#_load_battle(string_uid)
	#load_ui(ABILITY_SELECT_MENU)


func _on_battle_finished(session : BattleSession) -> void:
	session.queue_free()
	# TODO: Probably needs more things
