extends Control

const MAX_VIEW_SIZE : Vector2i = Vector2i(640, 360)

const ZOOM_OUT_SCALE : float = 1.0
const ZOOM_IN_SCALE  : float = 2.0

var target_render_scale : float = ZOOM_IN_SCALE
var render_scale        : float = ZOOM_IN_SCALE

@onready var game_display   : TextureRect = %GameDisplay
@onready var world_viewport : SubViewport = %WorldViewport

func _ready() -> void:
	world_viewport.size = MAX_VIEW_SIZE

	game_display.texture = world_viewport.get_texture()

	game_display.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	game_display.stretch_mode = TextureRect.STRETCH_SCALE

	_update_game_display()

#func _process(delta: float) -> void:
	#render_scale = lerpf(render_scale, target_render_scale, 10.0 * delta)
	#_update_game_display()

func _physics_process(delta: float) -> void:
	render_scale = lerpf(render_scale, target_render_scale, 10.0 * delta)
	_update_game_display()

func zoom_out() -> void:
	target_render_scale = ZOOM_OUT_SCALE

func zoom_in() -> void:
	target_render_scale = ZOOM_IN_SCALE

func _update_game_display() -> void:
	var display_size : Vector2 = Vector2(MAX_VIEW_SIZE) * render_scale

	game_display.size     = display_size
	game_display.position = (Vector2(size) - display_size) * 0.5
