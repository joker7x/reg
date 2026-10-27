extends Node2D
class_name TapIndicator

@export_group("Circle")
@export var size: = 48.0
@export var color: Color = Color(1, 1, 1, 0.6)
@export var start_scale: = 1.0
@export var end_scale: = 0.0
@export var fade_out: = true

@export_group("Tween")
@export var duration: = 0.35
@export var delay: = 0.0
@export var transition: Tween.TransitionType = Tween.TRANS_CUBIC
@export var ease: Tween.EaseType = Tween.EASE_OUT

var _tween: Tween

func _ready() -> void :
	scale = Vector2.ONE * start_scale
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", Vector2.ONE * end_scale, duration)\
	.set_delay(delay).set_trans(transition).set_ease(ease)
	if fade_out:
		_tween.tween_property(self, "modulate:a", 0.0, duration)\
		.set_delay(delay).set_trans(transition).set_ease(ease)
	_tween.finished.connect(queue_free)

func _draw() -> void :
	draw_circle(Vector2.ZERO, size * 0.5, color)
