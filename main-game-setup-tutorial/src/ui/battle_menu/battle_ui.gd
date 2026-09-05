class_name BattleUi
extends Control

signal ability_selected(ability : StringName)

@onready var high_blaze_button : Button = $PanelContainer/MarginContainer/VBoxContainer/HighBlazeButton
@onready var chill_button      : Button = $PanelContainer/MarginContainer/VBoxContainer/ChillButton

func _ready() -> void:
	self.visible = false

	# FUTURE: Hard coded buttons for now
	high_blaze_button.pressed.connect(_on_high_blaze_pressed)
	chill_button.pressed.connect(_on_chill_pressed)

func battle_start() -> void:
	self.visible = true
	# TODO: Add sound effects and intro pop in

func _on_high_blaze_pressed() -> void:
	ability_selected.emit(&"spell_high_blaze")

func _on_chill_pressed() -> void:
	ability_selected.emit(&"spell_chill")
