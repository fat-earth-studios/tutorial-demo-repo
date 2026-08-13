class_name BattleScene
extends Node2D

const TRANSITION_DURATION : float = 2.0

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

	await get_tree().create_timer(1.0).timeout

	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)
	_transition_tween.set_trans(Tween.TRANS_CUBIC)
	_transition_tween.set_ease(Tween.EASE_IN)

	_transition_tween.tween_method(_set_shader_progress, 0.0, 1.0, TRANSITION_DURATION)

	_transition_tween.tween_property(
		battle_actors_party, "position:y", -28.0, TRANSITION_DURATION
	)

	_transition_tween.tween_property(
		battle_actors_enemies, "position:y", -4.0, TRANSITION_DURATION
	)

	_transition_tween.tween_property(
		bonfire, "position:y", 176.0, TRANSITION_DURATION
	)

	_transition_tween.tween_property(
		battle_camera, "position:y", 164.0, TRANSITION_DURATION
	)

	await _transition_tween.finished



func _set_shader_progress(progress : float) -> void:
	_material.set_shader_parameter("transition", progress)

#func _update_battle_actors(progress : float) -> void:
	#pass
	#var actor_progress := clampf(remap(progress, ))
