class_name BattleScene
extends Node2D

const TRANSITION_DURATION : float = 1.0

var _transition_tween : Tween = null
var _material : ShaderMaterial = null  ## Shader Material used to tild the battle scene


@onready var main_battle_arena     : TextureRect = $BattleArena/MainBattleArena
@onready var battle_actors_party   : Node2D = $BattleActorsParty
@onready var battle_actors_enemies : Node2D = $BattleActorsEnemies

@onready var bonfire       : Bonfire = $Decorations/Bonfire
@onready var battle_camera : Camera2D = $Camera2D

func _ready() -> void:
	_material = main_battle_arena.material
	if _material == null:
		push_error("Material was not found")

	play_battle_start_animation()

func play_battle_start_animation() -> void:
	if _transition_tween:
		_transition_tween.kill()

	# Ensure correct starting position
	battle_actors_party.position.y   = 0.0
	battle_actors_enemies.position.y = 0.0
	bonfire.position.y       = 188.0
	battle_camera.position.y = 180
	_set_shader_progress(0.0)


	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)

	# Moving the world
	_transition_tween.tween_method(
		_set_shader_progress, 0.0, 1.0, TRANSITION_DURATION
	).set_trans(Tween.TRANS_LINEAR)

	# Moving the party, closest to camera
	_transition_tween.tween_property(
		battle_actors_party, "position:y", -28.0, TRANSITION_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)



	# Moving the Bonfire in the Middle
	_transition_tween.tween_property(
		bonfire, "position:y", 176.0, TRANSITION_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


	# Moving the enemies at the end
	_transition_tween.tween_property(
		battle_actors_enemies, "position:y", -4.0, TRANSITION_DURATION
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)




	# Moving the Camera
	_transition_tween.tween_property(
		battle_camera, "position:y", 164.0, TRANSITION_DURATION
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)

	await _transition_tween.finished



func _set_shader_progress(progress : float) -> void:
	_material.set_shader_parameter("transition", progress)

#func _update_battle_actors(progress : float) -> void:
	#var actor_progress : float = clampf(remap(progress, 0.15, 0.85, 0.0, 1.0), 0.0, 1.0)


func _on_button_pressed() -> void:
	play_battle_start_animation.call_deferred()
