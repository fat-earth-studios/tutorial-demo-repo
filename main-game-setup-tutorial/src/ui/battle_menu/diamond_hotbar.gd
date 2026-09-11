class_name DiamondHotbar
extends Control

signal ability_selected(ability_name : StringName)

@onready var icon_list : Array[Node] = self.get_children()

func _ready() -> void:
	for icon : AbilityIcon in icon_list:
		icon.action_started.connect(_on_ability_icon_action.bind(icon))

func _on_ability_icon_action(icon_selected : AbilityIcon) -> void:
	# Emit signal with chosen ability
	ability_selected.emit(icon_selected.ability_name)

	icon_selected.start_action()
	for icon : AbilityIcon in icon_list:
		icon.start_cooldown()
