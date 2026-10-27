extends Object
class_name TweenUtils

static func apply_tween_preset(
	target: Object, 
	preset: TweenParameter, 
	tween: Tween, 
	forward: bool = true, 
	parallel: bool = true
) -> PropertyTweener:

	if not target or not preset:
		printerr("Missing tween parameters! [target:%s, preset:%s, tween:%s]" % [target == null, preset == null, tween == null])
		return

	var path: = NodePath(preset.property)
	var base_value = target.get_indexed(path)

	var from_value = preset.from_value
	var to_value = preset.to_value

	if preset.relativity == TweenParameter.RelativityType.RELATIVE and base_value != null:
		from_value = base_value + preset.from_value
		to_value = base_value + preset.to_value

	var start_val = from_value if forward else to_value
	var end_val = to_value if forward else from_value

	if parallel:
		target.set_indexed(path, start_val)
		tween.parallel()

	var tweener: Tweener = tween.tween_property(
		target, 
		preset.property, 
		end_val, 
		preset.duration
	)
	if tweener:
		tweener.set_delay(preset.delay)
		tweener.set_trans(preset.transition)
		tweener.set_ease(preset.ease_type)
	else:
		printerr("Tweener Null!")

	return tweener

static func animate_to(
	node: Node, 
	property: String, 
	to: Variant, 
	duration: float, 
	trans: Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR, 
	ease: Tween.EaseType = Tween.EaseType.EASE_IN_OUT, 
	on_finished: Callable = Callable(), 
	slot: Tween = null
) -> Tween:


	if slot and slot.is_valid():
		slot.kill()
	var tween: = node.create_tween()
	tween.tween_property(node, property, to, duration).set_trans(trans).set_ease(ease)
	if on_finished.is_valid():
		tween.tween_callback(on_finished)
	return tween
