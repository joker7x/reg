class_name TouchSlider
extends HSlider



@export var touch_pad_vertical: float = 16.0

func _has_point(point: Vector2) -> bool:
	var pad: = touch_pad_vertical
	return Rect2(Vector2(0.0, - pad), size + Vector2(0.0, pad * 2.0)).has_point(point)
