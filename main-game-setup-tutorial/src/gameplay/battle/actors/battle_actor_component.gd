class_name BattleActorComponent
extends Node

signal start_spell_complete
signal defeated

@export var body: CharacterBody2D
@export var animation_controller: AnimationPlayer
#@export var abilities: Array[Ability]  #FUTURE: Add list of characters abilities

## Handle whatever needs handling when battle starts
func enter_battle(destination: Vector2) -> void:
	body.locked = true
	animation_controller.play(&"jump_to_battle")

	var tween : Tween = create_tween()

	tween.tween_property(
		body, "global_position", destination, 1.0
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT_IN)

	await tween.finished

func play_start_spell_animation() -> void:
	animation_controller.play_start_spell_animation()

func play_end_spell_animation() -> void:
	animation_controller.play_end_spell_animation()

func take_damage(amount: int) -> void:
	pass

func get_target_position() -> Vector2:
	return body.global_position

func _signal_start_spell_complete() -> void:
	start_spell_complete.emit()
