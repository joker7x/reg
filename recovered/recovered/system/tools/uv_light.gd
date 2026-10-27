@tool
extends Tool
class_name UVLight


@export var click_sfxs: Array[SFXClip] = []

@export_group("Textures")

@export var on_texture: Texture2D

@export var off_texture: Texture2D

@export_group("Z-Order")
@export var default_z: int = 100

@export_group("Animation")
@export var pick_up_duration: float = 0.2
@export var release_duration: float = 0.15
@export var pick_up_trans: Tween.TransitionType = Tween.TRANS_BACK
@export var pick_up_ease: Tween.EaseType = Tween.EASE_OUT
@export var release_trans: Tween.TransitionType = Tween.TRANS_QUART
@export var release_ease: Tween.EaseType = Tween.EASE_IN


var active: bool = false
var _last_press_ms: int = -1000


const PRESS_DEBOUNCE_MS: int = 50

@onready var glows: Control = $Glows
@onready var idle_texture: Control = $IdleTexture
@onready var lamp_texture: TextureRect = $IdleTexture / Texture
@onready var lamp_shadow: TextureRect = $IdleTexture / Shadow

func _ready() -> void :
	add_to_group("uv_light")
	hover_scale_target = self
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_texture(false)



func _apply_texture(on: bool) -> void :
	var tex: = on_texture if on else off_texture
	if tex == null:
		return
	if lamp_texture:
		lamp_texture.texture = tex
	if lamp_shadow:
		lamp_shadow.texture = tex

func _gui_input(event: InputEvent) -> void :
	if Engine.is_editor_hint():
		return
	var pressed: = false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = event.pressed
	elif event is InputEventScreenTouch:
		pressed = event.pressed
	if not pressed:
		return


	var now: = Time.get_ticks_msec()
	if now - _last_press_ms < PRESS_DEBOUNCE_MS:
		return
	_last_press_ms = now
	if event is InputEventScreenTouch:
		active_touch_index = event.index
		touch_pos = event.position
	_toggle()
	accept_event()

func _toggle() -> void :
	if active:
		_turn_off()
	else:
		_turn_on()

func _turn_on() -> void :
	if active:
		return
	SoundManager.play_sfx_random(click_sfxs, "uv_light_click")
	active = true
	_apply_texture(true)
	Signals.request_marker_cancel.emit()
	if highlight:
		highlight.visible = false
	z_index = default_z
	if glows:
		glows.visible = true

func _turn_off() -> void :
	if not active:
		return
	SoundManager.play_sfx_random(click_sfxs, "uv_light_click")
	active = false
	_apply_texture(false)
	if glows:
		glows.visible = false
	z_index = default_z

@export_group("Interaction")


@export_node_path("Control") var hit_area: NodePath

var _hit_area_node: Control

func _hit_area() -> Control:
	if _hit_area_node == null and not hit_area.is_empty():
		_hit_area_node = get_node_or_null(hit_area) as Control
		if _hit_area_node:
			_hit_area_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return _hit_area_node


func _has_point(point: Vector2) -> bool:
	var area: = _hit_area()
	if area:
		var global_rect: = area.get_global_rect()
		var local_rect: = Rect2(global_rect.position - global_position, global_rect.size)
		return local_rect.has_point(point)
	return Rect2(Vector2.ZERO, size).has_point(point)



func force_release() -> void :
	active = false
	_apply_texture(false)
	dragging = false
	active_touch_index = -1
	if glows:
		glows.visible = false
	z_index = default_z
