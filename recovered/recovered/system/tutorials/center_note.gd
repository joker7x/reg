extends Control
class_name CenterNote







@export var enter_delay: float = 1.5

@export var exit_duration: float = 0.2

@export var enter_duration: float = 0.4

@export var enter_transition: Tween.TransitionType = Tween.TRANS_BACK
@export var enter_ease: Tween.EaseType = Tween.EASE_OUT

@export var exit_transition: Tween.TransitionType = Tween.TRANS_BACK
@export var exit_ease: Tween.EaseType = Tween.EASE_IN

@export var exit_spin_max_degrees: float = 720.0

@export var exit_spin_transition: Tween.TransitionType = Tween.TRANS_SPRING
@export var exit_spin_ease: Tween.EaseType = Tween.EASE_IN_OUT

@export var hide_offset: float = 50.0

@export var tilt_range: float = 2.0

@export var sequence_gap: float = 0.4


@export var note_colors: Array[Color] = [
	Color(1, 0.85, 0.85), 
	Color(0.85, 0.9, 1), 
	Color(0.85, 1, 0.85), 
	Color(1, 1, 0.8), 
	Color(0.92, 0.85, 1), 
]

@export_group("Hover")

@export var hover_color: Color = Color(1.15, 1.15, 1.15)

@export var hover_duration: float = 0.15

@export_group("Click Feedback")

@export var clicks_to_dismiss: int = 3

@export var shake_magnitude: float = 6.0

@export var shake_duration: float = 0.3

@export var flash_color: Color = Color(1, 0.3, 0.3, 1)

@export var flash_duration: float = 0.35

@export_group("Sound")

@export var click_sfxs: Array[SFXClip]

@export_group("Ink Splash")

@export var splash_droplet_count: int = 24

@export var splash_min_size: float = 4.0

@export var splash_max_size: float = 10.0

@export var splash_lifetime_min: float = 0.36

@export var splash_lifetime_max: float = 0.6

@export var splash_speed_min: float = 90.0

@export var splash_speed_max: float = 260.0

@export var splash_gravity: float = 520.0

@export var splash_fade: bool = true

@export var splash_shape: InkSplash.DropletShape = InkSplash.DropletShape.SQUARE

@export var splash_sfx: SFXClip = preload("res://resources/sfx/diamond_click_sfx.tres")

@onready var label: Label = $Label
@onready var paper: TextureRect = $PaperPanel
@onready var highlight: ColorRect = $Highlight

const NoteScene: = preload("res://system/tutorials/center_note.tscn")
const InkSplashScene: = preload("res://system/tools/ink_splash.tscn")

const ENTER_SFXS: Array[SFXClip] = [
	preload("res://resources/sfx/paper_p3_sfx.tres"), 
	preload("res://resources/sfx/paper_p5_sfx.tres"), 
]

var current_tween: Tween
var color_tween: Tween
var is_showing: bool = false
var _click_count: int = 0
var _last_press_ms: int = -1000


const PRESS_DEBOUNCE_MS: int = 50
var _is_hovered: bool = false

var _custom_instance: Node = null

var is_duplicate: bool = false


var _has_notes_beneath: bool = false
var _spawned: Array[CenterNote] = []

func _ready() -> void :
	mouse_filter = Control.MOUSE_FILTER_STOP
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


	if not is_duplicate:
		position = _center_pos()
		position.y = _hidden_y()

func _on_mouse_entered() -> void :
	_is_hovered = true
	_tween_color_to(hover_color)

func _on_mouse_exited() -> void :
	_is_hovered = false
	_tween_color_to(Color.WHITE)

func _gui_input(event: InputEvent) -> void :
	if not is_showing:
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
	_click_count += 1
	_flash_red()
	SoundManager.play_sfx_random(click_sfxs, "center_note_click")
	ScreenShake.shake(self, shake_duration, shake_magnitude)
	if _click_count >= clicks_to_dismiss:
		_click_count = 0
		hide_note()






func show_note(text_key: String, custom_scene: PackedScene = null) -> void :
	if is_showing:
		_spawn_note(text_key, custom_scene)
		return
	_reset_feedback()
	_apply_random_rotation()
	_apply_random_color()
	_set_note_content(text_key, custom_scene)


	scale = Vector2.ONE
	position = _center_pos()
	position.y = _hidden_y()
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	current_tween = create_tween()
	if enter_delay > 0.0:
		current_tween.tween_interval(enter_delay)
	current_tween.tween_callback(_play_enter_sfx)
	current_tween.tween_property(self, "position:y", _center_pos().y, enter_duration).set_trans(enter_transition).set_ease(enter_ease)
	is_showing = true


func _play_enter_sfx() -> void :
	SoundManager.play_sfx_random(ENTER_SFXS, "center_note_enter")



func _spawn_ink_splash() -> void :
	if splash_sfx:
		SoundManager.play_sfx(splash_sfx)
	var splash: = InkSplashScene.instantiate() as InkSplash
	if splash == null:
		return
	splash.ink_color = paper.modulate
	splash.z_index = 50
	splash.droplet_count = splash_droplet_count
	splash.min_size = splash_min_size
	splash.max_size = splash_max_size
	splash.lifetime_min = splash_lifetime_min
	splash.lifetime_max = splash_lifetime_max
	splash.speed_min = splash_speed_min
	splash.speed_max = splash_speed_max
	splash.gravity = splash_gravity
	splash.fade = splash_fade
	splash.droplet_shape = splash_shape

	splash.rect_width = size.x
	splash.rect_height = size.y
	splash.spawn_from_center = true
	get_tree().root.add_child(splash)



	splash.global_position = position + size * 0.5



func set_highlight_active(active: bool) -> void :
	highlight.visible = _has_notes_beneath and active
	for note in _spawned:
		if is_instance_valid(note):
			note.set_highlight_active(active)



func hide_note() -> void :
	if not is_showing and _spawned.is_empty():
		return
	if is_showing:
		is_showing = false
		pivot_offset = size * 0.5
		if current_tween and current_tween.is_valid():
			current_tween.kill()
		current_tween = create_tween()
		current_tween.set_parallel(true)
		current_tween.tween_property(self, "scale", Vector2.ZERO, exit_duration).set_trans(exit_transition).set_ease(exit_ease)
		if exit_spin_max_degrees != 0.0:
			current_tween.tween_property(self, "rotation", rotation + deg_to_rad(randf_range( - exit_spin_max_degrees, exit_spin_max_degrees)), exit_duration).set_trans(exit_spin_transition).set_ease(exit_spin_ease)
		current_tween.chain().tween_callback( func() -> void :
			_spawn_ink_splash()
			if is_duplicate:
				queue_free()
		)
	for note in _spawned:
		if is_instance_valid(note):
			note.hide_note()
	_spawned.clear()





func show_note_sequence(intros: Array) -> void :
	for i in range(intros.size() - 1, -1, -1):
		var item = intros[i]
		if item is NoteIntroData:
			show_note(item.note_text, item.custom_scene)
		else:
			show_note(str(item), null)
		if i > 0:
			await get_tree().create_timer(sequence_gap).timeout




func _spawn_note(text_key: String, custom_scene: PackedScene) -> void :
	var instance: = NoteScene.instantiate() as CenterNote
	instance.is_duplicate = true
	_copy_settings_to(instance)
	get_parent().add_child(instance)



	instance._has_notes_beneath = true
	instance.highlight.visible = true


	instance.position = position
	instance.size = size
	instance.position.y = _hidden_y()
	_spawned.append(instance)
	instance.show_note(text_key, custom_scene)




func _set_note_content(text_key: String, custom_scene: PackedScene) -> void :
	if _custom_instance:
		_custom_instance.queue_free()
		_custom_instance = null
	if custom_scene:
		label.visible = false
		paper.visible = false
		var inst: = custom_scene.instantiate()
		add_child(inst)
		if inst is Control:
			var ctrl: = inst as Control
			ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_mouse_ignore_recursive(ctrl)
		_custom_instance = inst
	else:
		label.visible = true
		paper.visible = true
		label.text = tr(text_key)


func _mouse_ignore_recursive(node: Node) -> void :
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_mouse_ignore_recursive(child)


func _copy_settings_to(other: CenterNote) -> void :
	other.enter_delay = enter_delay
	other.exit_duration = exit_duration
	other.enter_duration = enter_duration
	other.enter_transition = enter_transition
	other.enter_ease = enter_ease
	other.exit_transition = exit_transition
	other.exit_ease = exit_ease
	other.exit_spin_max_degrees = exit_spin_max_degrees
	other.exit_spin_transition = exit_spin_transition
	other.exit_spin_ease = exit_spin_ease
	other.hide_offset = hide_offset
	other.hover_color = hover_color
	other.hover_duration = hover_duration
	other.clicks_to_dismiss = clicks_to_dismiss
	other.shake_magnitude = shake_magnitude
	other.shake_duration = shake_duration
	other.flash_color = flash_color
	other.flash_duration = flash_duration
	other.click_sfxs = click_sfxs
	other.splash_droplet_count = splash_droplet_count
	other.splash_min_size = splash_min_size
	other.splash_max_size = splash_max_size
	other.splash_lifetime_min = splash_lifetime_min
	other.splash_lifetime_max = splash_lifetime_max
	other.splash_speed_min = splash_speed_min
	other.splash_speed_max = splash_speed_max
	other.splash_gravity = splash_gravity
	other.splash_fade = splash_fade
	other.splash_shape = splash_shape
	other.splash_sfx = splash_sfx
	other.tilt_range = tilt_range
	other.note_colors = note_colors


func _reset_feedback() -> void :
	if color_tween and color_tween.is_valid():
		color_tween.kill()
	modulate = _base_color()
	_click_count = 0


func _apply_random_rotation() -> void :
	pivot_offset = size * 0.5
	rotation = deg_to_rad(randf_range( - tilt_range, tilt_range)) if tilt_range > 0.0 else 0.0


func _apply_random_color() -> void :
	if not note_colors.is_empty():
		paper.modulate = note_colors.pick_random()

func _flash_red() -> void :
	if color_tween and color_tween.is_valid():
		color_tween.kill()
	modulate = flash_color
	color_tween = create_tween()
	color_tween.tween_property(self, "modulate", _base_color(), flash_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _base_color() -> Color:
	return hover_color if _is_hovered else Color.WHITE

func _tween_color_to(target: Color) -> void :
	if color_tween and color_tween.is_valid():
		color_tween.kill()
	color_tween = create_tween()
	color_tween.tween_property(self, "modulate", target, hover_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _center_pos() -> Vector2:
	var v: = get_viewport_rect().size
	return Vector2((v.x - size.x) * 0.5, (v.y - size.y) * 0.5)

func _hidden_y() -> float:
	return - size.y - hide_offset
