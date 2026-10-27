@tool
extends Tool
class_name MagnifyingGlass

@export var pickup_sfx: SFXClip
@export var release_sfx: SFXClip
@export var touch_hold_offset: Vector2 = Vector2(0, 0)

@export_group("Magnification")
@export var zoom: float = 3
@export_range(-1.0, 2.0) var distortion: float = -0.2
@export_range(0.0, 0.01) var chromatic_aberration: float = 0.002

@export_group("Frame")
@export var border_color: Color = Color(0, 0, 0, 0.85)
@export_range(0.0, 50.0) var border_thickness: float = 6.0
@export var lens_size: Vector2 = Vector2(200, 200)

@export_group("Glass Overlay")
@export var tint_color: Color = Color(0.82, 0.92, 1.0, 1.0)
@export_range(0.0, 1.0) var tint_strength: float = 0.08
@export var specular_color: Color = Color(1, 1, 1, 1)
@export_range(0.0, 2.0) var specular_intensity: float = 0.8
@export var specular_position: Vector2 = Vector2(0.32, 0.28)
@export_range(0.01, 0.5) var specular_spread: float = 0.1
@export var pixel_specular_color: Color = Color(1, 1, 1, 1)
@export_range(0.0, 2.0) var pixel_specular_intensity: float = 0.7
@export var pixel_specular_position: Vector2 = Vector2(0.66, 0.64)
@export_range(0.005, 0.2) var pixel_specular_size: float = 0.035
@export_range(4.0, 64.0) var pixel_grid: float = 20.0

@export_subgroup("Counter Pixel Specular")
@export var counter_pixel_specular_enabled: bool = true
@export var counter_pixel_specular_color: Color = Color(1, 1, 1, 1)
@export_range(0.0, 2.0) var counter_pixel_specular_intensity: float = 0.5
@export_range(0.005, 0.2) var counter_pixel_specular_size: float = 0.025
@export var counter_pixel_specular_mirror: Vector2 = Vector2(1.0, 1.0)

@export_subgroup("Pixel Specular Tracking")
@export var pixel_specular_track_enabled: bool = true
@export var pixel_specular_pos_left: Vector2 = Vector2(0.75, 0.25)
@export var pixel_specular_pos_right: Vector2 = Vector2(0.25, 0.25)
@export var pixel_specular_pos_top: Vector2 = Vector2(0.5, 0.05)
@export var pixel_specular_pos_bottom: Vector2 = Vector2(0.5, 0.4)

@export_subgroup("Frame Shadow Tracking")
@export var frame_shadow_track_enabled: bool = true
@export var frame_shadow_offset: Vector2 = Vector2(0.0, 0.0)
@export var frame_shadow_strength: float = 1.0

@export_range(0.0, 1.0) var bevel_intensity: float = 0.45
@export_range(0.0, 1.0) var bevel_start: float = 0.82
@export_range(0.001, 0.3) var bevel_softness: float = 0.08

@export_group("Z-Order")
@export var default_z: int = 100

@export_group("Animation")
@export var pick_up_duration: float = 0.2
@export var release_duration: float = 0.15
@export var pick_up_trans: Tween.TransitionType = Tween.TRANS_BACK
@export var pick_up_ease: Tween.EaseType = Tween.EASE_OUT
@export var release_trans: Tween.TransitionType = Tween.TRANS_QUART
@export var release_ease: Tween.EaseType = Tween.EASE_IN

@onready var lens: ColorRect = $Lens
@onready var overlay: ColorRect = $Overlay
@onready var idle_texture: Control = $IdleTexture
@onready var frame_texture: Control = $FrameTexture
@onready var frame_shadow: TextureRect = $FrameTexture / FrameShadow
@onready var back_buffer_copy: Node = get_parent().get_node_or_null("BackBufferCopy")

var original_position: Vector2
var frame_shadow_original_pos: Vector2
var held: bool = false
var drag_offset: Vector2
var scale_tween: Tween

var _hold_button: int = MOUSE_BUTTON_LEFT

func _ready() -> void :
	add_to_group("magnifier")
	hover_scale_target = self
	original_position = global_position
	if frame_shadow:
		frame_shadow_original_pos = frame_shadow.position
	mouse_filter = Control.MOUSE_FILTER_STOP
	if lens and lens.material:
		lens.material = lens.material.duplicate()
	if overlay and overlay.material:
		overlay.material = overlay.material.duplicate()
	if not Engine.is_editor_hint():
		zoom = GameSettings.magnifier_zoom
		GameSettings.magnifier_zoom_changed.connect(_on_magnifier_zoom_changed)
	_apply_lens_params()
	if Engine.is_editor_hint():

		_set_overlay_visible(false)
		can_highlight = false
	else:
		_set_overlay_visible(true)
		_update_shader()

func _exit_tree() -> void :
	if Engine.is_editor_hint():
		return

	if GameSettings.magnifier_zoom_changed.is_connected(_on_magnifier_zoom_changed):
		GameSettings.magnifier_zoom_changed.disconnect(_on_magnifier_zoom_changed)

func _on_magnifier_zoom_changed() -> void :
	zoom = GameSettings.magnifier_zoom
	_apply_lens_params()
	_update_shader()

func _process(_delta: float) -> void :
	if Engine.is_editor_hint():
		_apply_lens_params()
		_update_pixel_specular_position()
		return
	if held:
		global_position = _drag_position() + drag_offset
		_update_shader()

func _apply_lens_params() -> void :


	if lens:
		lens.size = lens_size
		lens.position = (size - lens_size) * 0.5
		lens.pivot_offset = lens_size * 0.5
	if overlay:
		overlay.size = lens_size
		overlay.position = (size - lens_size) * 0.5
		overlay.pivot_offset = lens_size * 0.5
	if frame_texture:
		frame_texture.size = lens_size
		frame_texture.position = (size - lens_size) * 0.5
		frame_texture.pivot_offset = lens_size * 0.5
	if lens and lens.material:
		lens.material.set_shader_parameter("zoom", zoom)
		lens.material.set_shader_parameter("distortion", distortion)
		lens.material.set_shader_parameter("chromatic_aberration", chromatic_aberration)
		lens.material.set_shader_parameter("border_color", border_color)
		lens.material.set_shader_parameter("border_thickness", border_thickness)
		lens.material.set_shader_parameter("magnifier_size", lens_size)
	if overlay and overlay.material:
		overlay.material.set_shader_parameter("tint_color", tint_color)
		overlay.material.set_shader_parameter("tint_strength", tint_strength)
		overlay.material.set_shader_parameter("specular_color", specular_color)
		overlay.material.set_shader_parameter("specular_intensity", specular_intensity)
		overlay.material.set_shader_parameter("specular_position", specular_position)
		overlay.material.set_shader_parameter("specular_spread", specular_spread)
		overlay.material.set_shader_parameter("pixel_specular_color", pixel_specular_color)
		overlay.material.set_shader_parameter("pixel_specular_intensity", pixel_specular_intensity)
		overlay.material.set_shader_parameter("pixel_specular_position", pixel_specular_position)
		overlay.material.set_shader_parameter("pixel_specular_size", pixel_specular_size)
		overlay.material.set_shader_parameter("pixel_grid", pixel_grid)
		overlay.material.set_shader_parameter("counter_pixel_specular_color", counter_pixel_specular_color)
		overlay.material.set_shader_parameter("counter_pixel_specular_intensity", counter_pixel_specular_intensity if counter_pixel_specular_enabled else 0.0)
		overlay.material.set_shader_parameter("counter_pixel_specular_size", counter_pixel_specular_size)
		overlay.material.set_shader_parameter("bevel_intensity", bevel_intensity)
		overlay.material.set_shader_parameter("bevel_start", bevel_start)
		overlay.material.set_shader_parameter("bevel_softness", bevel_softness)

func _update_shader() -> void :
	var screen_size = get_viewport().get_visible_rect().size
	lens.material.set_shader_parameter("magnifier_screen_pos", lens.global_position)
	lens.material.set_shader_parameter("screen_size", screen_size)
	_update_pixel_specular_position()

func _update_pixel_specular_position() -> void :
	if not overlay or not overlay.material or not lens or Engine.is_editor_hint():
		return
	if pixel_specular_track_enabled:
		var screen_size = get_viewport().get_visible_rect().size
		var lens_center = lens.global_position + lens_size * 0.5

		var tx = clampf(lens_center.x / screen_size.x, 0.0, 1.0)
		var x_pos = pixel_specular_pos_left.lerp(pixel_specular_pos_right, tx)

		var ty = clampf(lens_center.y / screen_size.y, 0.0, 1.0)
		var y_pos = pixel_specular_pos_top.lerp(pixel_specular_pos_bottom, ty)

		var pos = Vector2(x_pos.x, y_pos.y)
		overlay.material.set_shader_parameter("pixel_specular_position", pos)

		var counter_pos = counter_pixel_specular_mirror - pos
		overlay.material.set_shader_parameter("counter_pixel_specular_position", counter_pos)
		_update_frame_shadow(counter_pos)
	else:
		overlay.material.set_shader_parameter("pixel_specular_position", pixel_specular_position)
		var counter_pos = counter_pixel_specular_mirror - pixel_specular_position
		overlay.material.set_shader_parameter("counter_pixel_specular_position", counter_pos)
		_update_frame_shadow(counter_pos)

func _update_frame_shadow(counter_pos: Vector2) -> void :
	if not frame_shadow or not frame_shadow_track_enabled:
		return
	var offset_from_center = (counter_pos - Vector2(0.5, 0.5)) * lens_size * frame_shadow_strength
	frame_shadow.position = frame_shadow_original_pos + offset_from_center + frame_shadow_offset

func _gui_input(event: InputEvent) -> void :
	if Engine.is_editor_hint():
		return
	if held:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			_hold_button = event.button_index
			_pick_up()
	elif event is InputEventScreenTouch and event.pressed:
		active_touch_index = event.index
		touch_pos = event.position
		_hold_button = -1
		_pick_up()

func _input(event: InputEvent) -> void :
	if Engine.is_editor_hint():
		return
	if not held:
		return
	if event is InputEventScreenDrag and event.index == active_touch_index:
		touch_pos = event.position
		return



	if event is InputEventMouseButton and event.pressed and _hold_button > 0\
	and event.button_index != _hold_button\
	and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT):
		Signals.next_document_requested.emit(event.position)
		return



	if event is InputEventScreenTouch and event.pressed and event.index != active_touch_index:
		Signals.next_document_requested.emit(event.position)
		return
	if event is InputEventMouseButton and event.button_index == _hold_button and not event.pressed:
		_release()
	elif event is InputEventScreenTouch and not event.pressed and event.index == active_touch_index:
		_release()

func _pick_up() -> void :
	SoundManager.play_sfx(pickup_sfx)
	held = true
	dragging = true
	Signals.request_marker_cancel.emit()
	if highlight:
		highlight.visible = false
	if idle_texture:
		idle_texture.visible = false
	if back_buffer_copy:
		back_buffer_copy.visible = true
	if scale_tween:
		scale_tween.kill()
	var nodes = [lens, overlay, frame_texture]
	for node in nodes:
		if node:
			node.scale = Vector2.ZERO
			node.visible = true
	drag_offset = - size * 0.5 + touch_hold_offset
	z_index = 1000
	_update_shader()
	scale_tween = create_tween().set_parallel(true)
	for node in nodes:
		if node:
			scale_tween.tween_property(node, "scale", Vector2.ONE, pick_up_duration).set_trans(pick_up_trans).set_ease(pick_up_ease)

func _release() -> void :
	SoundManager.play_sfx(release_sfx)
	held = false
	dragging = false
	active_touch_index = -1
	if scale_tween:
		scale_tween.kill()
	var nodes = [lens, overlay, frame_texture]
	scale_tween = create_tween().set_parallel(true)
	for node in nodes:
		if node:
			scale_tween.tween_property(node, "scale", Vector2.ZERO, release_duration).set_trans(release_trans).set_ease(release_ease)
	scale_tween.tween_property(self, "global_position", original_position, release_duration).set_trans(release_trans).set_ease(release_ease)
	scale_tween.chain().tween_callback(_finish_release)

func force_release() -> void :
	if not held:
		return
	_release()

func _finish_release() -> void :
	var nodes = [lens, overlay, frame_texture]
	for node in nodes:
		if node:
			node.visible = false
			node.scale = Vector2.ONE
	if back_buffer_copy:
		back_buffer_copy.visible = false
	if idle_texture:
		idle_texture.visible = true
	global_position = original_position
	z_index = default_z

func _set_overlay_visible(idle: bool) -> void :
	if idle_texture:
		idle_texture.visible = idle

	if lens:
		lens.visible = false
	if overlay:
		overlay.visible = not idle
	if frame_texture:
		frame_texture.visible = not idle
