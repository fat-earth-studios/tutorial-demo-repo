extends Control

@onready var fps_label    : Label = %FpsLabel
@onready var version_info : Label = %VersionInfo

func _ready() -> void:
	_add_version_to_info_label()

func _process(delta: float) -> void:
	fps_label.set_text("FPS: " + str(Engine.get_frames_per_second()))

func _add_version_to_info_label() -> void:
	var version_str : String = ProjectSettings.get_setting("application/config/version")
	version_info.text += version_str
