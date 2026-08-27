class_name BattleScene
extends Node2D

const WORLD_TRANSITION_DURATION : float = 0.75

## Percentage delay applied before camera movement (ex 0.7 - delay for 70% of World duration)
const CAMERA_DELAY_MULTIPLIER    : float = 0.7
## Multiplier for camera's duration relative to the World's (ex. 1.5 - duration is World duration * 1.5)
const CAMERA_DURATION_MULTIPLIER : float = 1.5

## How long the camera delays before starting relative to the World
const CAMERA_DELAY_DURATION      : float = WORLD_TRANSITION_DURATION * CAMERA_DELAY_MULTIPLIER
## How long the camera transitin lasts (based on World transition time)
const CAMERA_TRANSITION_DURATION : float = WORLD_TRANSITION_DURATION * CAMERA_DURATION_MULTIPLIER

@export var arena_world_origin : Vector2 = Vector2.ZERO

var _arena_shader_material : ShaderMaterial = null  ## Shader Material used to tild the battle scene

var _transition_tween : Tween = null


# DEBUG - temp to test impact
var _DEBUG_dmg_tween : Tween = null

@onready var main_battle_arena     : TextureRect = $BattleArena/MainBattleArena

@onready var battle_actors_party   : Node2D = $BattleActorsParty
@onready var battle_actors_enemies : Node2D = $BattleActorsEnemies

@onready var battle_actor_party_1 : BattleActorParty = $BattleActorsParty/BattleActorParty1

@onready var bonfire       : Bonfire  = $Decorations/Bonfire
@onready var battle_camera : Camera2D = $BattleCamera

# DEBUG - Buttons for replaying animation and resetting the view
@onready var button_play  : Button = %ButtonPlay
@onready var button_reset : Button = %ButtonReset
@onready var button_fire  : Button = %ButtonFire
@onready var button_ice   : Button = %ButtonIce
@onready var high_blaze  : HighBlaze = $EffectLayer/EffectRoot/HighBlaze
@onready var chill_spell : IceSpell  = $EffectLayer/EffectRoot/IceSpell
@onready var spell_layer : CanvasLayer = $EffectLayer

# DEBUG
@onready var main_battle_arena_2: TextureRect = $BattleArena/MainBattleArena2

# DEBUG Hard coded label, need to separate out
@onready var label_damage_text    : Label    = $BattleUI/LabelDamageText
@onready var marker_enemy_actor_1 : Marker2D = $BattleActorsEnemies/MarkerEnemyActor1

func _ready() -> void:
	# Set the location of the arena to the location in the world
	self.global_position = arena_world_origin
	align_spell_area() # Spell layer is a canvas layer and must be moved
	_arena_shader_material = main_battle_arena.material
	if _arena_shader_material == null:
		push_error("Material was not found")

	# DEBUG
	main_battle_arena_2.visible = false
	button_play.pressed. connect(_on_button_pressed      )
	button_reset.pressed.connect(_on_button_reset_pressed)
	button_fire.pressed. connect(_on_button_fire_pressed )
	button_ice.pressed.  connect(_on_button_chill_pressed)

	high_blaze.impact_moment. connect(_on_fire_impact )
	chill_spell.impact_moment.connect(_on_chill_impact)

	await get_tree().create_timer(1.0).timeout

	play_battle_start_animation()


func play_battle_start_animation() -> void:
	if _transition_tween:
		_transition_tween.kill()

	# Ensure correct starting position
	_reset_battle_view()

	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)

	# Moving the world
	_transition_tween.tween_method(
		_set_shader_progress, 0.0, 1.0, WORLD_TRANSITION_DURATION
	).set_trans(Tween.TRANS_LINEAR)

	var current_party_position_y : float = battle_actors_party.position.y
	var target_party_position_y  : float = current_party_position_y - 28.0

	# Moving the party, closest to camera
	_transition_tween.tween_property(
		battle_actors_party, "position:y", target_party_position_y, WORLD_TRANSITION_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# BONFIRE - Moving the Bonfire in the Middle
	_transition_tween.tween_property(
		bonfire, "position:y", 86.0, WORLD_TRANSITION_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


	var current_enemies_pos_y : float = battle_actors_enemies.position.y
	var final_enemies_pos_y   : float = current_enemies_pos_y - 4.0

	# ENEMIES - Moving the enemies at the end
	_transition_tween.tween_property(
		battle_actors_enemies, "position:y", final_enemies_pos_y, WORLD_TRANSITION_DURATION
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT_IN)


	# CAMERA - Delay set to avoid apparent object movement during start of transition
	#          Duration is a bit longer for cinematic purposes
	_transition_tween.tween_property(
		battle_camera, "position:y", -16.0, CAMERA_TRANSITION_DURATION
	).set_delay(CAMERA_DELAY_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	await _transition_tween.finished
	_transition_tween = null



func align_spell_area() -> void:
	spell_layer.follow_viewport_enabled = true
	spell_layer.follow_viewport_scale = 1.0
	spell_layer.transform = global_transform


func _set_shader_progress(progress : float) -> void:
	_arena_shader_material.set_shader_parameter(&"transition", progress)


# FUTURE (battle scene completion): Save - may be used for how actors work in final version
#func _update_battle_actors(progress : float) -> void:
	#var actor_progress : float = clampf(remap(progress, 0.15, 0.85, 0.0, 1.0), 0.0, 1.0)

# DEBUG - Move into own component
func show_damage_text(amount: int, duration: float = 2.0) -> void:
	if _DEBUG_dmg_tween:
		_DEBUG_dmg_tween.kill()


	var text_position : Vector2 = marker_enemy_actor_1.global_position
	var text_start_position : Vector2  = text_position - Vector2(0.0, 8.0)
	var text_end_position_y   : float  = text_position.y

	label_damage_text.text = str(amount)
	label_damage_text.modulate.a = 1.0
	label_damage_text.global_position = text_start_position

	_DEBUG_dmg_tween= get_tree().create_tween()
	_DEBUG_dmg_tween.set_parallel(true)
	_DEBUG_dmg_tween.tween_property(
		label_damage_text, 'global_position:y', text_end_position_y, duration
	).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	_DEBUG_dmg_tween.tween_property(
		label_damage_text, 'modulate:a', 0.0, duration).set_delay(0.5)



# END DEBUG damage text

func _reset_battle_view() -> void:
	battle_actors_party.position.y   = 0.0
	battle_actors_enemies.position.y = 0.0
	bonfire.position.y       = 102.0
	battle_camera.position.y = 0.0
	_set_shader_progress(0.0)

func _on_button_pressed() -> void:
	play_battle_start_animation.call_deferred()

func _on_button_reset_pressed() -> void:
	_reset_battle_view()
	# DEBUG
	bonfire.fire_is_out = false
	main_battle_arena.visible   = true
	main_battle_arena_2.visible = false

func _on_button_fire_pressed() -> void:
	_perform_spell_action.call_deferred(&"spell_blaze")
	#high_blaze.play_spell_animation()

func _on_fire_impact() -> void:
	bonfire.fire_is_out = false
	main_battle_arena.visible   = false
	main_battle_arena_2.visible = true
	show_damage_text(9001)


func _on_button_chill_pressed() -> void:
	_perform_spell_action.call_deferred(&"spell_chill")
	#chill_spell.play_spell_animation()

func _on_chill_impact() -> void:
	bonfire.fire_is_out = true
	show_damage_text(1006)


func _perform_spell_action(spell_name : StringName) -> void:
	battle_actor_party_1.play_start_spell_animation()
	await battle_actor_party_1.start_spell_complete

	var selected_spell : SpellBase
	match spell_name:
		&"spell_blaze":
			selected_spell = high_blaze
		&"spell_chill":
			selected_spell = chill_spell
		_:
			selected_spell = null

	if selected_spell:
		selected_spell.play_spell_animation()
		await selected_spell.spell_animation_finished

	battle_actor_party_1.play_end_spell_animation()
