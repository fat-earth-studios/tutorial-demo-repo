class_name HighBlaze
extends SpellBase

@onready var _animation_player: AnimationPlayer = $AnimationPlayer

func play_spell_animation() -> void:
	_animation_player.play(&"explosion")
