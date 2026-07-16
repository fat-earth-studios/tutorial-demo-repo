@tool # or @abstract (if either is needed)
@icon("res://path/to/icon.svg")
class_name PascalCase
extends Node
## Brief description of class
##
## Longer documentation goes here

# signals
signal something_happened(value : int)

# enums (PascalCase, members are CONSTANT_CASE)
enum EnumName
{
  ITEM_1,
  ITEM_2
}

#constants (CONSTANT_CASE)
const CONSTANT_VARIABLE : float = 9.42

# export variables (snake_case)
@export var exported_variable : float = 0.0

# public variables (non-underscore-prefixed snake_case)
var is_a_public_variable : bool = true

# private variables (underscore-prefixed _snake_case)
var _this_is_private : int = 42

# onready variables (snake_case)
@onready var on_ready_var : Sprite2D = $Sprite2D

# Optional built-in virtual methods:
# _init()
# _enter_tree()
# _ready()
# Remaining built-in virtual methods

func _ready() -> void:
  pass

func _process(_delta: float) -> void:
  pass

func _physics_process(_delta: float) -> void:
  pass

# public methods (non-underscore-prefixed snake_case)
func do_a_thing(the_thing : Thing) -> void:
  pass

# private methods (underscore-prefixed _snake_case)
func _do_a_thing_but_private() -> void:
  pass

# Callback
func _on_a_thing_happening() -> void:
  pass

# Inner class
class InnerClassName:
  pass
