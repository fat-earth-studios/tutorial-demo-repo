extends CharacterBody2D
## This is meant to test moving around the level only, this is not the actual character

const SPEED : float= 80.0

@onready var player_sprite_2d : Sprite2D = $PlayerSprite2D

func _physics_process(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#var direction_x : float = Input.get_axis("ui_left", "ui_right")
	#if direction_x:
		#velocity.x = direction_x * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
#
	#var direction_y : float = Input.get_axis("ui_up", "ui_down")
	#if direction_y:
		#velocity.y = direction_y * SPEED
	#else:
		#velocity.y = move_toward(velocity.x, 0, SPEED)

	var input_direction : Vector2 = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	velocity = input_direction * SPEED

	_handle_horizontal_flip()

	move_and_slide()

func _handle_horizontal_flip() -> void:
	if absf(velocity.x) > 0.1:
		player_sprite_2d.flip_h = true if (velocity.x > 0.0 ) else false
