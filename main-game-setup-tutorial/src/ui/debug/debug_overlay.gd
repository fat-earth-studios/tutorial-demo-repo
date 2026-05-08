extends Control

@onready var fps_label : Label = %FpsLabel

func _process(delta: float) -> void:
	fps_label.set_text("FPS: " + str(Engine.get_frames_per_second()))
