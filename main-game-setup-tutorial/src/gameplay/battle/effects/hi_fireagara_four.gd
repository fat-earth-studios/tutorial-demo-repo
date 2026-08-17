class_name SpellBase
extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	pass

	#await get_tree().create_timer(1.0).timeout
#
	#animation_player.play(&"explosion")


func play_spell_animation() -> void:
	animation_player.play(&"explosion")
