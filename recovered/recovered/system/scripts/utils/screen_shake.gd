extends RefCounted
class_name ScreenShake


const STEP: = 0.02

const SETTLE: = 0.05



static var _active: Dictionary = {}



static func shake(node: Node, duration: float, magnitude: float) -> void :
	if not is_instance_valid(node):
		return
	var id: = node.get_instance_id()
	var prev: Tween = _active.get(id)
	if prev and prev.is_valid():
		prev.kill()
	var original_pos: Vector2 = node.position
	var tween: = node.create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	var steps: = int(duration / STEP)
	for i in steps:
		var offset: = Vector2(
			randf_range( - magnitude, magnitude), 
			randf_range( - magnitude, magnitude)
		)
		tween.tween_property(node, "position", original_pos + offset, STEP)
	tween.tween_property(node, "position", original_pos, SETTLE)
	tween.finished.connect( func() -> void :
		if _active.get(id) == tween:
			_active.erase(id)
	)
	_active[id] = tween
