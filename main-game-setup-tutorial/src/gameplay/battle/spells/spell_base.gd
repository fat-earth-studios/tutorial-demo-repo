@abstract
class_name SpellBase
extends Node2D

## Emitted when effect impact occurs, for aligning damage (or anything else) to that frame
signal impact_moment()

## Emitted when the entire spell has completed
signal spell_animation_finished()

## Called to start the spell effect animation
@abstract func play_spell_animation() -> void

## Called to indicate the moment when spell should "hit"
func _signal_impact_moment() -> void:
	impact_moment.emit()

func _emit_spell_animation_finished() -> void:
	spell_animation_finished.emit()
