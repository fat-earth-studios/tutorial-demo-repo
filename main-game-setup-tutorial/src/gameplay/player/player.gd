class_name Player
extends CharacterBody2D
## Still contains placeholder code, but has more of what the final Player class will be
## FUTURE (player): Replace with the actual player implementation.

## A way for me (Danny) to still use the Ghost sprite when needed
@export var use_ghost_sprite : bool = false


enum FacingDirection {
	UP,
	DOWN,
	LEFT,
	RIGHT
}


const SPEED : float = 80.0
const SPRINT_MULTIPLIER_VALUE : float = 2.0 ## Increase speed by a multiple of this value when sprint held

var camera_look_direction : Vector2 = Vector2.ZERO

var _facing_direction : FacingDirection = FacingDirection.DOWN

var locked : bool = false

@onready var sprite_2d: Sprite2D = $Visuals/PlayerSprite2D
@onready var animation_player : AnimationPlayer = $AnimationPlayer

@onready var battle_actor_component : BattleActorComponent = $Components/BattleActor

# TESTING: Debug label to be used for testing
@onready var player_debug_label: Label = %PlayerDebugLabel
@onready var ghost_visuals: Node2D = $GhostVisuals

func _ready() -> void:
	sprite_2d.visible = not use_ghost_sprite
	ghost_visuals.visible = use_ghost_sprite

func _physics_process(_delta: float) -> void:
	if not locked:

		var input_direction : Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")

		var speed_multiplier : float = 1.0 if not Input.is_action_pressed(&"sprint") else SPRINT_MULTIPLIER_VALUE

		velocity = input_direction * SPEED * speed_multiplier

		# Add ability to look around using right stick
		# FUTURE (player): This is very fragile, need to add clear communication from player to camera
		camera_look_direction = Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")

		_update_animation(input_direction)

		player_debug_label.text = FacingDirection.find_key(_facing_direction)

		move_and_slide()

#func _handle_horizontal_flip() -> void:
	#if absf(velocity.x) > 0.1:
		#sprite_2d.flip_h = true if (velocity.x > 0.0 ) else false

func _update_animation(direction : Vector2) -> void:
	if direction == Vector2.ZERO:
		match _facing_direction:
			FacingDirection.DOWN:
				animation_player.play(&"idle_down")
			FacingDirection.UP:
				animation_player.play(&"idle_up")
			FacingDirection.LEFT:
				_flip_sprite_flip_h(true)
				animation_player.play(&"idle_side")
			FacingDirection.RIGHT:
				_flip_sprite_flip_h(false)
				animation_player.play(&"idle_side")
		return

	if absf(direction.x) > absf(direction.y):
		var facing_right : bool = direction.x > 0.0
		_facing_direction = FacingDirection.RIGHT if facing_right else FacingDirection.LEFT
		_flip_sprite_flip_h(not facing_right)
		animation_player.play(&"walk_side")
	elif direction.y > 0.0:
		_facing_direction = FacingDirection.DOWN
		_flip_sprite_flip_h(false)
		animation_player.play(&"walk_down")
	elif direction.y < 0.0:
		_facing_direction = FacingDirection.UP
		_flip_sprite_flip_h(false)
		animation_player.play(&"walk_up")

func _flip_sprite_flip_h(flip : bool) -> void:
	if not use_ghost_sprite:
		sprite_2d.flip_h = flip
	else:
		$GhostVisuals/GhostSprite.flip_h = !flip # NOTE: Not the cleanest, but just for debug stuff
