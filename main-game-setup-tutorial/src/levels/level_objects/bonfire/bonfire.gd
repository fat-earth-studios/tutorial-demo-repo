@tool
class_name Bonfire
extends Node2D

## Set to true to turn off the fire
@export var fire_is_out : bool = false:
	set(value):
		fire_is_out = value
		_update_fire_visual()

@onready var fire_sprite : Sprite2D = $FireSprite

func _ready() -> void:
	_update_fire_visual()

func _update_fire_visual() -> void:
	if not fire_sprite:
		return

	if fire_is_out:
		fire_sprite.visible = false
	else:
		fire_sprite.visible = true
