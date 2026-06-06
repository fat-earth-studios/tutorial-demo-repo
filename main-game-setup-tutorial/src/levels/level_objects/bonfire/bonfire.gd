@icon("res://assets/art/ui/icons/bonfire_icon.svg")
class_name Bonfire
extends Node2D

@export var fire_is_out : bool = false ## Set to true to turn off the fire

@onready var fire_sprite : Sprite2D = $FireSprite

func _ready() -> void:
	if fire_is_out:
		fire_sprite.visible = false
	else:
		fire_sprite.visible = true

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	pass
