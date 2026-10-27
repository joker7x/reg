extends TextureButton

@export var hover_in_tp: TweenParameter
@export var hover_out_tp: TweenParameter
@export var pressed_tp: TweenParameter
@export var release_tp: TweenParameter

var _tween: Tween

func _ready() -> void :
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_animate.bind(hover_in_tp))
	mouse_exited.connect(_animate.bind(hover_out_tp))
	button_down.connect(_animate.bind(pressed_tp))
	button_up.connect(_animate.bind(release_tp))

func _animate(tp: TweenParameter) -> void :
	if not tp:
		return
	pivot_offset = size / 2.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	TweenUtils.apply_tween_preset(self, tp, _tween)
