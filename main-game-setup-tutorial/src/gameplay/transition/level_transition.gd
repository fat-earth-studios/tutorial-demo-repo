class_name LevelTransition
extends Area2D

const TEST_LEVEL_02 : String =  "uid://kikf44gko1yv"

signal transition_requested(scene_uid : String)


var _has_triggered : bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body : Node2D) -> void:
	if body is not Player:
		print_debug("Somehow something other than player entered")
		return

	print_debug("Player entered the body" + TEST_LEVEL_02)
	_has_triggered = true

	transition_requested.emit(TEST_LEVEL_02)
