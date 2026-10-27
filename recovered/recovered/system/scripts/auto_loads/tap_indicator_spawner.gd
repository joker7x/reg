extends CanvasLayer

@export var indicator_scene: PackedScene
@export var enabled: = true
@export var handle_touch: = true
@export var handle_mouse: = true

func _input(event: InputEvent) -> void :
	if not enabled:
		return
	if handle_touch and event is InputEventScreenTouch and event.pressed and event.index == 0:
		spawn(event.position)
	elif handle_mouse and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		spawn(event.position)

func spawn(pos: Vector2) -> TapIndicator:
	if not indicator_scene:
		return null
	var indicator: = indicator_scene.instantiate() as TapIndicator
	if not indicator:
		return null
	indicator.global_position = pos
	add_child(indicator)
	return indicator
