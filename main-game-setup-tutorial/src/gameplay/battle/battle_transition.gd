class_name BattleTransition
extends Area2D

@export_file("*.tscn")
var battle_scene_uid : String

signal battle_transition_requested(scene_uid : String)

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

	print_debug("Player requested transition to: " + battle_scene_uid)
	battle_transition_requested.emit(battle_scene_uid)
