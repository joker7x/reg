extends Control
class_name MarkerLine

@export var base_width: = 12
@export var min_width: = 6.0
@export var max_width: = 20
@export var color: = Color(1.0, 0.0, 0.0, 0.502)
@export var duration: = 0.05

@export var start_offset_range: = 14.0
@export var end_offset_range: = 14.0

@export var points: = 16
@export var wobble: = 1

const MarkerSplashScene: = preload("res://system/tools/marker_splash.tscn")

@onready var line: Line2D = $Line2D
var width_curve: = Curve.new()


var _anim_points: Array = []
var _anim_time: float = 0.0
var _anim_duration: float = 0.0
var _anim_total: int = 0
var _splash: MarkerSplash = null

func _ready():



	layout_direction = Control.LAYOUT_DIRECTION_LTR
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_right = 0.0
	offset_top = 0.0
	offset_bottom = 0.0

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.default_color = color
	line.width = base_width
	line.width_curve = width_curve
	line.clear_points()
	hide()

func erase():
	_anim_points.clear()
	_stop_splash()
	line.clear_points()
	width_curve.clear_points()
	hide()

func draw_across(field: Control):
	show()
	line.clear_points()
	width_curve.clear_points()
	_stop_splash()

	var rect: = field.get_rect()
	var y: = rect.size.y * 0.5
	_anim_points.clear()
	var start_x = randf_range( - start_offset_range, start_offset_range)
	var end_x = rect.size.x + randf_range( - end_offset_range, end_offset_range)
	for i in points:
		var t: = float(i) / (points - 1)
		var x: float = lerp(start_x, end_x, t)
		var jitter_y: = randf_range( - wobble, wobble)
		_anim_points.append(Vector2(x, y + jitter_y))

		var w: = randf_range(min_width, max_width)
		width_curve.add_point(Vector2(t, w))


	width_curve.add_point(Vector2(0.0, 0.0))
	width_curve.add_point(Vector2(1.0, 0.0))

	line.width_curve = width_curve
	line.points = []

	_anim_total = _anim_points.size()
	_anim_duration = duration
	_anim_time = 0.0
	_start_splash()

func _process(delta: float) -> void :
	if _anim_points.is_empty():
		return
	_anim_time += delta
	var progress: float = clamp(_anim_time / _anim_duration, 0.0, 1.0)
	var count: int = clampi(int(round(progress * _anim_total)), 1, _anim_total)
	if line.points.size() != count:
		var pts: = PackedVector2Array()
		for i in count:
			pts.append(_anim_points[i])
		line.points = pts

	if _splash:
		_splash.set_target_local(_anim_points[count - 1])
	if progress >= 1.0:
		_anim_points.clear()
		_stop_splash()

func _start_splash() -> void :
	if _splash and is_instance_valid(_splash):
		_splash.emitting = true
		return
	var splash: = MarkerSplashScene.instantiate() as MarkerSplash
	if not splash:
		return

	add_child(splash)
	splash.set_target_local(_anim_points[0] if not _anim_points.is_empty() else Vector2.ZERO)
	_splash = splash

func _stop_splash() -> void :
	if _splash and is_instance_valid(_splash):
		_splash.stop()
	_splash = null
