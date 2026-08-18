class_name IceSpell
extends SpellBase

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	play_spell_animation()

func play_spell_animation() -> void:
	animation_player.play(&"play_spell")
