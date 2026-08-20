class_name LevelTransition
extends Area2D

const TEST_LEVEL_02 : String =  "uid://kikf44gko1yv"
const BATTLE_SCENE : String = "uid://b144aly8fprew"

signal transition_requested(scene_uid : String)

var _has_triggered : bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body : Node2D) -> void:
	if body is not Player:
		print_debug("Somehow something other than player entered")
		return

	# Don't let the signal fire twice
	if _has_triggered:
		print_debug("The Volume triggered more than once")
		return

	_has_triggered = true
	set_deferred(&"monitoring", false)

	print_debug("Player requested transition to: " + BATTLE_SCENE)
	transition_requested.emit(BATTLE_SCENE)
