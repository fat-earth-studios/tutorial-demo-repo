class_name SpellBase
extends Node2D

## Emitted when effect impact occurs, for aligning damage (or anything else) to that frame
signal impact_moment()

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	pass

	# DEBUG
	#await get_tree().create_timer(1.0).timeout
	#play_spell_animation()
#
	#animation_player.play(&"explosion")


func play_spell_animation() -> void:
	animation_player.play(&"explosion")

func _signal_impact_moment() -> void:
	print_debug("Impact happened now")
	impact_moment.emit()
