class_name AbilityIcon
extends Control

@export var ability_texture : Texture2D = null
@export var cooldown_time   : float = 5.0

var _is_on_cooldown : bool = false
var _ability_flash_tween : Tween = null

@onready var ability_icon: TextureRect = $MarginContainer/AbilityIcon
@onready var cooldown_progress: TextureProgressBar = $CooldownProgress

@onready var ability_use_flash: ColorRect = $MarginContainer/AbilityUseFlash

@onready var cooldown_timer: Timer = $CooldownTimer

func _ready() -> void:
	if ability_texture == null:
		push_warning("Ability Slot: Does not have a texture")
	else:
		ability_icon.texture = ability_texture

	cooldown_timer.wait_time    = cooldown_time
	cooldown_progress.max_value = cooldown_time

	cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)

func _process(_delta: float) -> void:
	if _is_on_cooldown:
		#time_text.text = "%2.1f" % cooldown_timer.time_left
		cooldown_progress.value = cooldown_timer.time_left


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		try_start_action()


func try_start_action() -> void:
	if not _is_on_cooldown:
		start_action()

func start_action() -> void:
	_play_use_ability_flash()
	_is_on_cooldown = true
	#time_text.visible = true
	cooldown_timer.start()

func _play_use_ability_flash() -> void:
	if _ability_flash_tween:
		_ability_flash_tween.kill()

	ability_use_flash.self_modulate = Color(1.0, 1.0, 1.0, 0.0)

	_ability_flash_tween = create_tween()

	_ability_flash_tween.tween_property(
		ability_use_flash, "self_modulate", Color(1.0, 1.0, 1.0, 1.0), 0.667
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	_ability_flash_tween.tween_property(
		ability_use_flash, "self_modulate", Color(1.0, 1.0, 1.0, 0.0), 0.667
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	await _ability_flash_tween.finished


func _on_cooldown_timer_timeout() -> void:
	_is_on_cooldown = false
	#time_text.visible = false
