class_name BattleAction
extends RefCounted

signal action_completed

var _caster : BattleActorComponent
var _target_position : Vector2 # TODO: Add target as well for damage calculation
var _ability : SpellBase # TODO: Update for non-spells

func _init(
		caster_in : BattleActorComponent,
		target_position_in : Vector2,
		ability_in : SpellBase
) -> void:
	_caster = caster_in
	_target_position = target_position_in
	_ability = ability_in

	# FUTURE: Clean this up a bit
	_ability.global_position = _target_position

func execute() -> void:
	_caster.play_start_spell_animation()
	await _caster.start_spell_complete

	_ability.play_spell_animation()
	await _ability.spell_animation_finished

	_caster.play_end_spell_animation()

	action_completed.emit()
