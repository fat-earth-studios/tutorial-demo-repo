class_name BattleActorParty
extends Node2D

signal start_spell_complete

@onready var animation_player : AnimationPlayer = $AnimationPlayer

func play_start_spell_animation() -> void:
	animation_player.play(&"cast_spell_start")

func play_end_spell_animation() -> void:
	animation_player.play(&"cast_spell_end")

func _signal_start_spell_complete() -> void:
	start_spell_complete.emit()
