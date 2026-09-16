class_name Ability
extends Resource

enum TargetType {
	SINGLE,
	AOE,
	FRIENDLY_SINGLE,
	FRIENDLY_AOE
}

@export var display_name : StringName
@export var effect_scene : PackedScene
@export var damage_data  : float        # TODO: Flat value for now
@export var target_type  : TargetType
