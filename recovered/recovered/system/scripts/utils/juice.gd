class_name Juice
extends RefCounted

static var _rng := RandomNumberGenerator.new()
const _JOLT_TW: StringName = &"_juice_jolt_tween"
const _PUNCH_TW: StringName = &"_juice_punch_tween"

static func jolt(node: Control, amount: float = 8.0, duration: float = 0.18) -> void :
	if not is_instance_valid(node):
		return
	if node.has_meta(_JOLT_TW):
		var old: Tween = node.get_meta(_JOLT_TW)
		if old is Tween and old.is_valid():
			old.kill()
	var base := Vector2(node.offset_left, node.offset_top)
	var tw := node.create_tween()
	node.set_meta(_JOLT_TW, tw)
	var step: float = 0.025
	var n: int = maxi(4, int(duration / step))
	var last := Vector2.ZERO
	for i in n:
		var f: float = amount * (1.0 - float(i) / float(n))
		var target: Vector2 = _rand_vec(f)
		tw.tween_method(_set_jolt_offset.bind(node, base), last, target, step)
		last = target
	tw.tween_method(_set_jolt_offset.bind(node, base), last, Vector2.ZERO, step)

static func _set_jolt_offset(shake: Vector2, node: Control, base: Vector2) -> void :
	if not is_instance_valid(node):
		return
	node.offset_left = base.x + shake.x
	node.offset_top = base.y + shake.y

static func flash(node: Node, alpha: float = 0.25, duration: float = 0.12) -> void :
	if not is_instance_valid(node) or not node.is_inside_tree():
		return
	var scene: Node = node.get_tree().current_scene
	if not scene is Control:
		return
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, alpha)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	scene.add_child(overlay)
	var tw := overlay.create_tween()
	tw.tween_property(overlay, "modulate:a", 0.0, duration)
	tw.tween_callback(overlay.queue_free)

static func punch(node: Control, squash: Vector2 = Vector2(1.18, 0.85), duration: float = 0.22) -> void :
	if not is_instance_valid(node):
		return
	if node.has_meta(_PUNCH_TW):
		var old: Tween = node.get_meta(_PUNCH_TW)
		if old is Tween and old.is_valid():
			old.kill()
	var orig: Vector2 = node.scale
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween()
	node.set_meta(_PUNCH_TW, tw)
	tw.tween_property(node, "scale", orig * squash, duration * 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", orig, duration * 0.75).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

static func pop_in(node: Control, from_scale: Vector2 = Vector2(1.7, 1.7), duration: float = 0.14) -> void :
	if not is_instance_valid(node):
		return
	node.scale = from_scale
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func hit_stop(scene: SceneTree, duration: float = 0.045, slow: float = 0.12) -> void :
	if scene == null:
		return
	Engine.time_scale = slow
	scene.create_timer(duration, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)

static func _rand_vec(mag: float) -> Vector2:
	return Vector2(_rng.randf_range(-mag, mag), _rng.randf_range(-mag, mag))
