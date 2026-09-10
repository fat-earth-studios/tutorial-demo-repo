class_name BattleSession
extends Node

signal battle_finished
signal show_battle_ui

enum BattleState {
	ADVANCING,
	SLOWED,
	WAITING
}

# TODO: More hard coding for now
const HIGH_BLAZE_UID  : String = "uid://d12jrqqe5xuu8"
const SPELL_CHILL_UID : String = "uid://dffhodi2knh0e"

const PLAYER_TIME_BETWEEN_TURNS : float = 2.0

var _selected_spell_uid : String = ""

var _battle_state : BattleState = BattleState.WAITING
var _battle_timer : float = 0.0

var _player_is_ready : bool = true
var _next_player_turn_time : float = 0.0

var _main_game    : MainGame    = null
var _battle_arena : BattleArena = null
var _battle_ui    : BattleUi    = null

var _party   : Array[BattleActorComponent] = []
#var _enemies : Array[BattleActorComponent] = []

var _is_setup : bool = false

func _ready() -> void:
	pass


func setup(
		main_game : MainGame,
		arena     : BattleArena,
		battle_ui : BattleUi,
		party     : Array[BattleActorComponent]
		#enemies  : Array[BattleActorComponent]
) -> void:
	assert(not _is_setup, "BattleSession was already set up.")
	assert(is_instance_valid(main_game))
	assert(arena != null)
	assert(battle_ui != null)
	assert(not party.is_empty())
	#assert(not enemies.is_empty())

	_main_game = main_game
	_battle_arena = arena
	_battle_ui = battle_ui
	_party.assign(party)
	#_enemies.assign(enemies)

	# Connect the signals FUTURE cleanup
	_battle_ui.ability_selected.connect(_on_ability_selected)

	_is_setup = true


func start() -> void:
	assert(_is_setup, "BattleSession.start() called before setup")

	_battle_arena.arena_intro_finished.connect(_on_arena_intro_finished, CONNECT_ONE_SHOT)

	for actor : BattleActorComponent in _party:
		actor.enter_battle(_battle_arena.get_party_actor_position())

	_battle_arena.play_battle_start_animation()


func _process(delta: float) -> void:
	if _battle_state == BattleState.WAITING:
		return

	_battle_timer += delta

	if not _player_is_ready:
		if _battle_timer >= _next_player_turn_time:
			pass
			#

func _start_battle_processing() -> void:
	await get_tree().create_timer(0.5).timeout
	_battle_ui.battle_start()
	_battle_state = BattleState.ADVANCING

func _on_arena_intro_finished() -> void:
	_start_battle_processing()

func _on_ability_selected(ability_name : StringName) -> void:
	match ability_name:
		&"spell_high_blaze":
			_selected_spell_uid = HIGH_BLAZE_UID
		&"spell_chill":
			_selected_spell_uid = SPELL_CHILL_UID
		_:
			_selected_spell_uid = ""
