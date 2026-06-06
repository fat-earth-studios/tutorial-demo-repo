extends Camera2D
## PLACEHOLDER: This script exists only to provide a basic camera for demonstrating
## the project foundation. It is not intended as an example of a complete camera system.
## FUTURE (camera): Replace with the actual camera implementation.

const LERP_WEIGHT : float = 2.0
const CAMERA_LOOK_AHEAD_VAL : Vector2 = Vector2(0.0, -8.0)
const CAMERA_LOOK_AMOUNT    : float =  64.0  ## Value when player input to look ahead

var target : Node2D = null

func _physics_process(delta : float) -> void:
	_follow_camera_target(delta)

func _follow_camera_target(delta : float) -> void:
	if not target:
		return

	# Offset value is amount to lead the player
	var target_camera_offset : Vector2 = CAMERA_LOOK_AHEAD_VAL
	var target_global_pos    : Vector2 = target.global_position + target_camera_offset
	# FUTURE (player): This is very fragile as it assumes the target is a player, need to fix in future update
	target_global_pos += target.camera_look_direction * CAMERA_LOOK_AMOUNT

	var camera_pos_out : Vector2

	camera_pos_out.x = lerpf(global_position.x, target_global_pos.x, LERP_WEIGHT * delta)
	camera_pos_out.y = lerpf(global_position.y, target_global_pos.y, LERP_WEIGHT * delta)


	global_position = camera_pos_out
