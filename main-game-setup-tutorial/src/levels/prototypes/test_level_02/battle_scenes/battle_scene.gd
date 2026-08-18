class_name BattleScene
extends Node2D

const WORLD_TRANSITION_DURATION : float = 0.75

## Percentage delay applied before camera movement (ex 0.7 - delay for 70% of World duration)
const CAMERA_DELAY_MULTIPLIER    : float = 0.7
## Multiplier for camera's duration relative to the World's (ex. 1.5 - duration is World duration * 1.5)
const CAMERA_DURATION_MULTIPLIER : float = 1.5

## How long the camera delays before starting relative to the World
const CAMERA_DELAY_DURATION      : float = WORLD_TRANSITION_DURATION * CAMERA_DELAY_MULTIPLIER
## How long the camera transitin lasts (based on World transition time)
const CAMERA_TRANSITION_DURATION : float = WORLD_TRANSITION_DURATION * CAMERA_DURATION_MULTIPLIER

var _arena_shader_material : ShaderMaterial = null  ## Shader Material used to tild the battle scene

var _transition_tween : Tween = null

@onready var main_battle_arena     : TextureRect = $BattleArena/MainBattleArena

@onready var battle_actors_party   : Node2D = $BattleActorsParty
@onready var battle_actors_enemies : Node2D = $BattleActorsEnemies

@onready var bonfire       : Bonfire  = $Decorations/Bonfire
@onready var battle_camera : Camera2D = $Camera2D

# DEBUG - Buttons for replaying animation and resetting the view
@onready var button_play  : Button = $CanvasLayer/ButtonPlay
@onready var button_reset : Button = $CanvasLayer/ButtonReset
@onready var button_fire: Button = $CanvasLayer/ButtonFire
@onready var hi_fireagara_four: SpellBase = $EffectLayer/EffectRoot/HiFireagaraFour

# DEBUG
@onready var main_battle_arena_2: TextureRect = $BattleArena/MainBattleArena2

func _ready() -> void:
	_arena_shader_material = main_battle_arena.material
	if _arena_shader_material == null:
		push_error("Material was not found")

	# DEBUG
	main_battle_arena_2.visible = false
	button_play.pressed.connect(_on_button_pressed)
	button_reset.pressed.connect(_on_button_reset_pressed)
	button_fire.pressed.connect(_on_button_fire_pressed)

	hi_fireagara_four.impact_moment.connect(_on_fire_impact)

	play_battle_start_animation()


func play_battle_start_animation() -> void:
	if _transition_tween:
		_transition_tween.kill()

	# Ensure correct starting position
	_reset_battle_view()

	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)

	# Moving the world
	_transition_tween.tween_method(
		_set_shader_progress, 0.0, 1.0, WORLD_TRANSITION_DURATION
	).set_trans(Tween.TRANS_LINEAR)

	# Moving the party, closest to camera
	_transition_tween.tween_property(
		battle_actors_party, "position:y", -28.0, WORLD_TRANSITION_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# BONFIRE - Moving the Bonfire in the Middle
	_transition_tween.tween_property(
		bonfire, "position:y", 176.0, WORLD_TRANSITION_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# ENEMIES - Moving the enemies at the end
	_transition_tween.tween_property(
		battle_actors_enemies, "position:y", -4.0, WORLD_TRANSITION_DURATION
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT_IN)


	# CAMERA - Delay set to avoid apparent object movement during start of transition
	#          Duration is a bit longer for cinematic purposes
	_transition_tween.tween_property(
		battle_camera, "position:y", 164.0, CAMERA_TRANSITION_DURATION
	).set_delay(CAMERA_DELAY_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	await _transition_tween.finished
	_transition_tween = null



func _set_shader_progress(progress : float) -> void:
	_arena_shader_material.set_shader_parameter("transition", progress)


# FUTURE (battle scene completion): Save - may be used for how actors work in final version
#func _update_battle_actors(progress : float) -> void:
	#var actor_progress : float = clampf(remap(progress, 0.15, 0.85, 0.0, 1.0), 0.0, 1.0)


func _reset_battle_view() -> void:
	battle_actors_party.position.y   = 0.0
	battle_actors_enemies.position.y = 0.0
	bonfire.position.y       = 188.0
	battle_camera.position.y = 180
	_set_shader_progress(0.0)

func _on_button_pressed() -> void:
	play_battle_start_animation.call_deferred()

func _on_button_reset_pressed() -> void:
	_reset_battle_view()
	# DEBUG
	bonfire.fire_is_out = false
	main_battle_arena.visible   = true
	main_battle_arena_2.visible = false

func _on_button_fire_pressed() -> void:
	hi_fireagara_four.play_spell_animation()

func _on_fire_impact() -> void:
	bonfire.fire_is_out = true
	main_battle_arena.visible   = false
	main_battle_arena_2.visible = true
