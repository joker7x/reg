extends Button

@export var hover_in_tp: TweenParameter
@export var hover_out_tp: TweenParameter
@export var rotate_tp: TweenParameter

var _scale_tween: Tween
var _rotate_tween: Tween

func _ready() -> void :
	mouse_entered.connect(_on_btn_hover_in)
	mouse_exited.connect(_on_btn_hover_out)
	pressed.connect(_play_btn_rotate)

func _on_btn_hover_in() -> void :
	_play_btn_scale(hover_in_tp)

func _on_btn_hover_out() -> void :
	_play_btn_scale(hover_out_tp)

func _play_btn_rotate() -> void :
	pivot_offset = size / 2.0
	rotation = 0.0
	if _rotate_tween:
		_rotate_tween.kill()
	_rotate_tween = create_tween()
	TweenUtils.apply_tween_preset(self, rotate_tp, _rotate_tween)

func _play_btn_scale(tp: TweenParameter) -> void :
	pivot_offset = size / 2.0
	if _scale_tween:
		_scale_tween.kill()
	_scale_tween = create_tween()
	TweenUtils.apply_tween_preset(self, tp, _scale_tween)
