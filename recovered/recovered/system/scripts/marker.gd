extends Tool
class_name Marker

@export var default_z: int = 5
@export var tex_rotation: float = -15
@export var shadow_offset: Vector2 = Vector2(-10, 10)

@export var mark_sfx: SFXClip
@export var pickup_sfx: SFXClip
@export var release_sfx: SFXClip

@onready var game_controller: GameController = $"../.."

@export var marker_shadow: TextureRect
@export var marker_texture: TextureRect

var original_position: Vector2
var hide_position: Vector2
var mouse_offset: Vector2
var original_shadow_offset: Vector2

var tween: Tween
var shown: bool = true

func _ready() -> void :
	Signals.form_field_marked.connect(_on_field_marked)
	Signals.form_field_unmarked.connect(_on_field_unmarked)
	Signals.request_marker_cancel.connect(_cancel)
	original_position = global_position
	hide_position = original_position + Vector2(500, 0)

	mouse_filter = Control.MOUSE_FILTER_STOP
	original_shadow_offset = marker_shadow.position

func mark(mistake: MistakeData):
	var case = game_controller.current_case
	if not case:
		return
	SoundManager.play_sfx(mark_sfx)
	if not case.player_marked_items.has(mistake):
		case.player_marked_items.append(mistake)

func unmark(mistake: MistakeData):
	var case = game_controller.current_case
	if not case:
		return
	case.player_marked_items.erase(mistake)

func _on_field_marked(mistake: MistakeData):
	mark(mistake)

func _on_field_unmarked(mistake: MistakeData):
	unmark(mistake)

func _process(_delta: float) -> void :
	if Global.marker_held:
		global_position = get_global_mouse_position() + mouse_offset

func _gui_input(event: InputEvent) -> void :
	super._gui_input(event)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_pick_up()

func _input(event):
	if not Global.marker_held:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel()

func _pick_up():
	if Global.marker_held:
		return

	SoundManager.play_sfx(pickup_sfx)

	marker_texture.rotation_degrees = tex_rotation
	marker_shadow.position = shadow_offset

	Global.marker_held = true
	dragging = true
	highlight.visible = false

	z_index = 1000

func _cancel():
	if not Global.marker_held:
		return

	Global.marker_held = false
	dragging = false
	global_position = original_position
	z_index = default_z
	SoundManager.play_sfx(release_sfx)

	marker_texture.rotation_degrees = 0
	marker_shadow.position = original_shadow_offset

func cancel_hold() -> void :
	_cancel()

func show_marker():
	if shown:
		return

	shown = true
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(
		self, 
		"global_position", 
		original_position, 
		0.5
	).set_trans(Tween.TransitionType.TRANS_EXPO)\
	.set_ease(Tween.EaseType.EASE_OUT)

func hide_marker():
	if not shown:
		return

	_cancel()
	shown = false
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(
		self, 
		"global_position", 
		hide_position, 
		0.5
	).set_trans(Tween.TransitionType.TRANS_EXPO)\
	.set_ease(Tween.EaseType.EASE_IN)
