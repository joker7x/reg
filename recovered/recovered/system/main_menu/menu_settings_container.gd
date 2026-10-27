extends Control



@export var settings_button: Button
@export var panel: Panel


@export var settings_label: RichTextLabel

@export var show_duration: float = 0.33
@export var show_transition: Tween.TransitionType = Tween.TRANS_EXPO
@export var show_ease: Tween.EaseType = Tween.EASE_OUT

@export var hide_duration: float = 0.33
@export var hide_transition: Tween.TransitionType = Tween.TRANS_EXPO
@export var hide_ease: Tween.EaseType = Tween.EASE_OUT

@export var show_sfx: SFXClip
@export var hide_sfx: SFXClip

@export var close_on_outside_click: bool = false


@export var hide_offset: Vector2 = Vector2(0.0, 250.0)

var shown: bool = false
var _tween: Tween = null

func _ready() -> void :
	position = _hide_pos()
	if settings_button and not settings_button.pressed.is_connected(_on_btn_pressed):
		settings_button.pressed.connect(_on_btn_pressed)
	get_viewport().size_changed.connect(_on_viewport_resized)
	_refresh_settings_label()
	GameSettings.language_changed.connect(_refresh_settings_label)


func _exit_tree() -> void :
	if GameSettings.language_changed.is_connected(_refresh_settings_label):
		GameSettings.language_changed.disconnect(_refresh_settings_label)


func _refresh_settings_label() -> void :
	if settings_label:
		settings_label.text = "============\n[wave]%s" % tr("Settings")

func _on_viewport_resized() -> void :
	if _tween and _tween.is_valid():
		_tween.kill()
		_tween = null
	position = _hide_pos() if not shown else Vector2.ZERO

func _show_pos() -> Vector2:
	return Vector2.ZERO



func _hide_pos() -> Vector2:
	return hide_offset

func _on_btn_pressed() -> void :
	if shown:
		_hide()
	else:
		_show()

func _show() -> void :
	shown = true
	if show_sfx:
		SoundManager.play_sfx(show_sfx)
	_tween = TweenUtils.animate_to(self, "position", _show_pos(), show_duration, show_transition, show_ease, Callable(), _tween)

func _hide() -> void :
	shown = false
	if hide_sfx:
		SoundManager.play_sfx(hide_sfx)
	_tween = TweenUtils.animate_to(self, "position", _hide_pos(), hide_duration, hide_transition, hide_ease, Callable(), _tween)

func _input(event: InputEvent) -> void :
	if not shown or not close_on_outside_click:
		return
	var pos: = Vector2.ZERO
	var is_press: = false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.global_position
		is_press = true
	elif event is InputEventScreenTouch and event.pressed and event.index == 0:
		pos = event.position
		is_press = true
	if not is_press:
		return
	if panel and panel.get_global_rect().has_point(pos):
		return
	if settings_button and settings_button.get_global_rect().has_point(pos):
		return
	_hide()
	get_viewport().set_input_as_handled()
