class_name DiamondHotbar
extends Control

@onready var ability_icon   : AbilityIcon = $AbilityIcon
@onready var ability_icon_2 : AbilityIcon = $AbilityIcon2
@onready var ability_icon_3 : AbilityIcon = $AbilityIcon3
@onready var ability_icon_4 : AbilityIcon = $AbilityIcon4

func _ready() -> void:
	ability_icon.action_started.connect(_on_ability_icon_action_started)
	ability_icon_2.action_started.connect(_on_ability_icon_action_started)
	ability_icon_3.action_started.connect(_on_ability_icon_action_started)
	ability_icon_4.action_started.connect(_on_ability_icon_action_started)


func _on_ability_icon_action_started() -> void:
	ability_icon.start_cooldown()
	ability_icon_2.start_cooldown()
	ability_icon_3.start_cooldown()
	ability_icon_4.start_cooldown()
