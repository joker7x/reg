extends Control
class_name Tool

@export var highlight: TextureRect
@export var hover_scale_target: Control
@export var hover_scale: float = 1.15
@export var hover_duration: float = 0.12
@export var press_scale: float = 0.7
@export var press_duration: float = 0.15

enum HoverMode{SCALE, LIFT}


@export var hover_mode: HoverMode = HoverMode.SCALE

@export var hover_lift_amount: float = 8.0



@export var draggable: = false

var dragging: bool = false:
	set(v):
		var was: = dragging
		dragging = v
		if was != v:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if v else Input.MOUSE_MODE_VISIBLE
			if v:
				_reset_hover_scale()

var can_highlight: bool = true

var hover_tween: Tween
var flash_tween: Tween
var _pressing: = false


var active_touch_index: int = -1
var touch_pos: Vector2

var _hover_lift_initialized: = false
var _hover_lift_y: = 0.0

func _enter_tree() -> void :
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _gui_input(event: InputEvent) -> void :
	if draggable:
		if dragging:
			return
		if event is InputEventMouseButton\
		and event.button_index == MOUSE_BUTTON_LEFT\
		and event.pressed:
			_on_drag_press()
		elif event is InputEventScreenTouch and event.pressed:
			active_touch_index = event.index
			touch_pos = event.position
			_on_drag_press()
		return
	if event is InputEventMouseButton\
	and event.button_index == MOUSE_BUTTON_LEFT\
	and event.pressed:
		_pressing = true
		_tween_press_scale()

func _input(event: InputEvent) -> void :
	if not draggable or not dragging:
		return
	if event is InputEventScreenDrag and event.index == active_touch_index:
		touch_pos = event.position
		return
	if event is InputEventMouseButton\
	and event.button_index == MOUSE_BUTTON_LEFT\
	and not event.pressed:
		_on_drag_release()
	elif event is InputEventScreenTouch\
	and not event.pressed\
	and event.index == active_touch_index:
		_on_drag_release()



func _on_drag_press() -> void :
	pass


func _on_drag_release() -> void :
	pass



func _drag_position() -> Vector2:
	if active_touch_index != -1:
		return touch_pos
	return get_global_mouse_position()

func _on_mouse_entered():
	if can_highlight and not dragging:
		highlight.visible = true
	if not dragging:
		_tween_hover(hover_scale)

func _on_mouse_exit():
	highlight.visible = false
	_tween_hover(1.0)

func _tween_hover(target_scale: float) -> void :
	if hover_mode == HoverMode.LIFT:
		_tween_hover_lift( - hover_lift_amount if target_scale > 1.0 else 0.0)
	else:
		_tween_hover_scale(target_scale)

func _tween_hover_scale(target_scale: float) -> void :
	if not hover_scale_target or not is_instance_valid(hover_scale_target):
		return
	if hover_tween:
		hover_tween.kill()
	_center_hover_pivot()
	hover_tween = create_tween()
	hover_tween.tween_property(
		hover_scale_target, 
		"scale", 
		Vector2(target_scale, target_scale), 
		hover_duration
	).set_trans(Tween.TransitionType.TRANS_QUAD)\
	.set_ease(Tween.EaseType.EASE_OUT)

func _tween_hover_lift(offset_y: float) -> void :
	if hover_tween:
		hover_tween.kill()



	if offset_y != 0.0:
		_hover_lift_origin()
	hover_tween = create_tween()
	hover_tween.tween_property(
		self, 
		"position:y", 
		_hover_lift_origin() + offset_y, 
		hover_duration
	).set_trans(Tween.TransitionType.TRANS_QUAD)\
	.set_ease(Tween.EaseType.EASE_OUT)

func _tween_press_scale() -> void :
	if not hover_scale_target or not is_instance_valid(hover_scale_target):
		return
	if hover_tween:
		hover_tween.kill()
	_center_hover_pivot()
	hover_scale_target.scale = Vector2(press_scale, press_scale)
	hover_tween = create_tween()
	hover_tween.tween_property(
		hover_scale_target, 
		"scale", 
		Vector2.ONE, 
		press_duration
	).set_trans(Tween.TransitionType.TRANS_QUAD)\
	.set_ease(Tween.EaseType.EASE_OUT)

func _center_hover_pivot() -> void :
	if not hover_scale_target or not is_instance_valid(hover_scale_target):
		return
	var center: = hover_scale_target.size / 2.0
	if not hover_scale_target.get_combined_pivot_offset().is_equal_approx(center):
		hover_scale_target.pivot_offset = center
		hover_scale_target.pivot_offset_ratio = Vector2.ZERO

func _reset_hover_scale() -> void :
	if _pressing:
		_pressing = false
		return
	if hover_tween:
		hover_tween.kill()
	if hover_scale_target and is_instance_valid(hover_scale_target):
		hover_scale_target.scale = Vector2.ONE
	if _hover_lift_initialized:
		position.y = _hover_lift_y

func _hover_lift_origin() -> float:
	if not _hover_lift_initialized:
		_hover_lift_initialized = true
		_hover_lift_y = position.y
	return _hover_lift_y



func _flash_press(overlay: TextureRect, color: Color, duration: float) -> void :
	if flash_tween:
		flash_tween.kill()
	overlay.modulate = color
	flash_tween = create_tween()
	flash_tween.tween_property(overlay, "modulate", Color.WHITE, duration)



func _flash_press_all(overlays: Array[Control], color: Color, duration: float) -> void :
	if flash_tween:
		flash_tween.kill()
	flash_tween = create_tween().set_parallel(true)
	for overlay in overlays:
		if not overlay:
			continue
		overlay.modulate = color
		flash_tween.tween_property(overlay, "modulate", Color.WHITE, duration)

func _reset_flash(overlay: TextureRect) -> void :
	if flash_tween:
		flash_tween.kill()
		flash_tween = null
	if overlay:
		overlay.modulate = Color.WHITE
