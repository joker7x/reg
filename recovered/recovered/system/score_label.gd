extends Control
class_name ScoreLabel

@export var label: Label
@export var move_tp: TweenParameter
@export var fade_tp: TweenParameter
@export var stay_duration: float = 2.5

var text: String

var move_tween: Tween
var fade_tween: Tween

func populate(text: String, color: Color):
	label.position.x = move_tp.from_value
	label.modulate = color
	label.text = text

	if move_tween:
		move_tween.kill()
	move_tween = create_tween()
	TweenUtils.apply_tween_preset(label, move_tp, move_tween)

	await get_tree().create_timer(stay_duration).timeout
	queue_free()
