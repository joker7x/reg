extends Control

@export var show_pos_node: Control

@onready var settings_btn: Button = $AudioSettingsButton
var hide_pos: Vector2
var shown: bool = false

var tween: Tween

func _ready() -> void :
	hide_pos = global_position
	settings_btn.pressed.connect(_on_btn_pressed)

func back_to_mm():
	SaveSystem.save_progress()
	SceneTransition.change_scene_to("res://scenes/main_menu.tscn")

func _on_btn_pressed() -> void :
	_toggle()

func _toggle():
	Signals.request_marker_cancel.emit()
	if shown:
		_hide()
	else:
		_show()

func _show():
	shown = true
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "global_position", show_pos_node.global_position, 0.33)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)

func _hide():
	shown = false
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "global_position", hide_pos, 0.33)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	pass

func _input(event: InputEvent) -> void :
	if not shown:
		return
	var pos: Vector2
	var is_press: = false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.global_position
		is_press = true
	elif event is InputEventScreenTouch and event.pressed and event.index == 0:
		pos = event.position
		is_press = true
	if not is_press:
		return
	if get_global_rect().has_point(pos):
		return
	if settings_btn and settings_btn.get_global_rect().has_point(pos):
		return
	_hide()
	get_viewport().set_input_as_handled()
