class_name Player
extends CharacterBody2D
## PLACEHOLDER: This script exists only to provide a movable player for demonstrating the project foundation.
## It is adapted from Godot's default CharacterBody2D template and is not intedned as an example of a
## complete player controller or gameplay architecture
## FUTURE (player): Replace with the actual player implementation.

const SPEED : float = 80.0
const SPRINT_MULTIPLIER_VALUE : float = 2.0 ## Increase speed by a multiple of this value when sprint held

var camera_look_direction : Vector2 = Vector2.ZERO

@onready var player_sprite_2d : Sprite2D = $PlayerSprite2D

func _physics_process(_delta: float) -> void:
	var input_direction : Vector2 = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")

	var speed_multiplier : float = 1.0 if not Input.is_action_pressed(&"sprint") else SPRINT_MULTIPLIER_VALUE

	velocity = input_direction * SPEED * speed_multiplier

	# Add ability to look around using right stick
	# FUTURE (player): This is very fragile, need to add clear communication from player to camera
	camera_look_direction = Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")

	_handle_horizontal_flip()

	move_and_slide()

func _handle_horizontal_flip() -> void:
	if absf(velocity.x) > 0.1:
		player_sprite_2d.flip_h = true if (velocity.x > 0.0 ) else false
