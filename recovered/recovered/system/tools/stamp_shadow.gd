extends Control
class_name StampShadow


var target: Control



@export var vertical_offset: = 0.0

@export var min_alpha: = 0.2
@export var max_alpha: = 1.0
@export var fade_distance: = 300.0

@export var pickup_duration: = 0.3
@export var return_duration: = 0.3


var stop_y: = 0.0

var resting_position: = Vector2.ZERO


var tweening_alpha: = false

var initial_tween_active: = false

var _alpha_tween: Tween
var _pos_tween: Tween

func setup(follow_target: Control, at_stop_y: float) -> void :
	target = follow_target
	stop_y = at_stop_y
	resting_position = global_position



func random_stop_y(stop_node: Control) -> float:
	if not stop_node:
		return stop_y
	var top: = stop_node.global_position.y
	var bottom: = stop_node.global_position.y + stop_node.size.y
	stop_y = randf_range(top, bottom) - (size.y + vertical_offset)
	return stop_y

func calculate_alpha() -> float:
	if not target:
		return max_alpha
	var dist: float = abs(target.position.y - stop_y)
	var t: float = clamp(dist / fade_distance, min_alpha, 1.0)
	var alpha: float = lerp(max_alpha, min_alpha, t)
	return alpha



func update_follow() -> void :
	if not target:
		return

	if initial_tween_active:
		if not tweening_alpha:
			modulate.a = calculate_alpha()
		return

	position.x = target.position.x
	position.y = stop_y + size.y + vertical_offset
	if not tweening_alpha:
		modulate.a = calculate_alpha()


func tween_to_rest() -> void :
	if not target:
		return
	if _pos_tween:
		_pos_tween.kill()
	initial_tween_active = true
	var rest: = Vector2(target.position.x, stop_y + size.y + vertical_offset)
	_pos_tween = create_tween()
	_pos_tween.tween_property(
		self, 
		"position", 
		rest, 
		pickup_duration
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_pos_tween.tween_callback( func():
		initial_tween_active = false
		)


func tween_back(duration: float = -1.0) -> void :
	if duration < 0.0:
		duration = return_duration
	initial_tween_active = false
	if _pos_tween:
		_pos_tween.kill()
	_pos_tween = create_tween()
	_pos_tween.tween_property(
		self, 
		"global_position", 
		resting_position, 
		duration
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func fade_in(duration: float = 0.1, target_alpha: float = 1.0) -> void :
	if _alpha_tween:
		_alpha_tween.kill()
	tweening_alpha = true
	visible = true
	_alpha_tween = create_tween()
	_alpha_tween.tween_property(self, "modulate:a", target_alpha, duration)
	_alpha_tween.tween_callback( func():
		tweening_alpha = false
		)


func fade_out(duration: float = 0.1) -> void :
	if _alpha_tween:
		_alpha_tween.kill()
	tweening_alpha = true
	_alpha_tween = create_tween()
	_alpha_tween.tween_property(self, "modulate:a", 0.0, duration)
	_alpha_tween.tween_callback( func():
		visible = false
		tweening_alpha = false
		)
