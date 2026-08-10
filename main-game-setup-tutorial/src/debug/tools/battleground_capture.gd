extends Node

const CAPTURE_SIZE : Vector2i = Vector2i(640, 360)
const OUTPUT_PATH  : String   = "user://mountaintop_battle_ground.png"

@export var battle_area_center  : Marker2D
@export var hide_during_capture : Array[CanvasItem]

@onready var _capture_viewport : SubViewport = $CaptureViewport
@onready var _capture_camera   : Camera2D    = $CaptureViewport/CaptureCamera


func _ready() -> void:
	await _capture_battle_ground()


func _capture_battle_ground() -> void:
	# Hide anything that should remain upright in the battle scene.
	var previous_visibility: Array[bool] = []

	for item: CanvasItem in hide_during_capture:
		previous_visibility.append(item.visible)
		item.visible = false

	# Render the currently loaded level from a second camera.
	_capture_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_capture_viewport.world_2d = get_viewport().world_2d
	_capture_viewport.size = CAPTURE_SIZE
	_capture_viewport.disable_3d = true
	_capture_viewport.use_hdr_2d = true
	_capture_viewport.transparent_bg = true
	_capture_viewport.canvas_cull_mask = get_viewport().canvas_cull_mask

	_capture_camera.global_position = battle_area_center.global_position
	_capture_camera.zoom = Vector2.ONE
	_capture_camera.position_smoothing_enabled = false
	_capture_camera.limit_enabled = false
	_capture_camera.enabled = true
	_capture_camera.make_current()
	_capture_camera.force_update_scroll()

	# Render exactly one frame.
	_capture_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw

	var image: Image = _capture_viewport.get_texture().get_image()

	# If hdr2d image was captured, convert in order to properly save png
	if _capture_viewport.use_hdr_2d:
		image.convert(Image.FORMAT_RGBA8)
		image.linear_to_srgb()

	var error: Error = image.save_png(OUTPUT_PATH)

	# Restore the exploration scene.
	for index: int in hide_during_capture.size():
		hide_during_capture[index].visible = previous_visibility[index]

	if error != OK:
		push_error("Battle-ground capture failed: %s" % error_string(error))
		return

	var absolute_path : String = ProjectSettings.globalize_path(OUTPUT_PATH)
	print("Battle ground saved to: ", absolute_path)
	OS.shell_show_in_file_manager(absolute_path)
