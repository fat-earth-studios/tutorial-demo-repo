@abstract
class_name BaseBattleArena
extends Node2D

signal intro_animation_finished

## Function called to start battle animation,
##  will emit finished once into animation is complete
func play_battle_intro_animation() -> void:
	await _play_battle_intro_animation()
	intro_animation_finished.emit()

## Implementation function for playing the battle intro
@abstract func _play_battle_intro_animation() -> Signal
