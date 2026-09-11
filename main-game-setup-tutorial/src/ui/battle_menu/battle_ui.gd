class_name BattleUi
extends Control

signal ui_ability_selected(ability : StringName)

@onready var diamond_hotbar: DiamondHotbar = $DiamondHotbar

func _ready() -> void:
	self.visible = false

	# FUTURE: Hard coded buttons for now
	diamond_hotbar.ability_selected.connect(_on_diamond_hotbar_ability_selected)

func battle_start() -> void:
	self.visible = true
	# TODO: Add sound effects and intro pop in

func _on_diamond_hotbar_ability_selected(ability_name : StringName) -> void:
	ui_ability_selected.emit(ability_name)
