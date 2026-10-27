extends Control

@export var duration: = 2.0
@export var delay: = 1.0

@export var amplitude: = 8.0
@export var hover_duration: = 1.2
var start_y: float

func _has_point(_point: Vector2) -> bool:
	return false

func _ready():

	start_y = position.y

	var hover_tween = create_tween()
	hover_tween.set_loops()
	hover_tween.set_trans(Tween.TRANS_SINE)
	hover_tween.set_ease(Tween.EASE_IN_OUT)


	hover_tween.tween_property(self, "position:y", start_y - amplitude, hover_duration)


	hover_tween.tween_property(self, "position:y", start_y, hover_duration)


	material = material.duplicate()

	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_method(
		func(v): material.set_shader_parameter("progress", v), 
		0.0, 1.0, duration
	)

	tween.tween_interval(delay)

	tween.tween_method(
		func(v): material.set_shader_parameter("progress", v), 
		1.0, 0.0, duration
	)

	tween.tween_interval(delay)
