class_name Utils
extends Object


static func reset_tween(tween : Tween, parent : Node) -> Tween:
	if tween:
		tween.kill()

	return parent.create_tween()
