extends Control
class_name DayStamp

@export_group("Position")

@export var day_start_stamp_position: Vector2 = Vector2(640, 120)

@export var day_end_stamp_position: Vector2 = Vector2(640, 360)

@export_group("Timing")

@export var pause_duration: float = 1.0

@export var descend_duration: float = 0.5

@export var ascend_duration: float = 0.25

@export_group("Fade")

@export var fade_duration: float = 1.0

@export_group("Stamp")

@export var start_x_offset: float = 0.0

@export var start_top_margin: float = 50.0

@export var label_offset: Vector2 = Vector2.ZERO

@export_group("Shake")

@export var shake_strength: float = 8.0

@export var shake_duration: float = 0.3

@export var stamp_sfx: SFXClip

@export var end_stamp_sfx: SFXClip

@export var start_splash_color: Color = Color(0.42, 0.13, 0.13, 0.85)

const InkSplashScene: = preload("res://system/tools/ink_splash.tscn")


const DESIGN_CENTER_X: float = 640.0


func _centered(pos: Vector2) -> Vector2:
	var v: = get_viewport_rect().size
	return Vector2(pos.x - DESIGN_CENTER_X + v.x * 0.5, pos.y)

@onready var stamp_visual: TextureRect = $StampVisual
@onready var day_label: Label = $DayLabel
@onready var end_label: Label = $EndLabel

var stamp_tween: Tween
var fade_tween: Tween

func stamp_day(text: String) -> void :
	_reset_label(end_label)
	_fit_day_label(text)
	_stamp(day_label, text, _centered(day_start_stamp_position))



func _fit_day_label(text: String) -> void :
	var font: = day_label.get_theme_font("font")
	var base_size: = day_label.get_theme_font_size("font_size")
	var max_width: = stamp_visual.size.x - 8.0
	var size: = base_size
	while size > 12:
		if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= max_width:
			break
		size -= 1
	day_label.add_theme_font_size_override("font_size", size)

func stamp_end(text: String) -> void :

	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
		fade_tween = null
	_reset_label(day_label)

	end_label.text = text
	end_label.modulate.a = 1.0
	end_label.visible = true
	var target_pos: = _centered(day_end_stamp_position) + label_offset - end_label.size / 2.0
	var start_pos: = Vector2(target_pos.x, - end_label.size.y - start_top_margin)
	end_label.global_position = start_pos

	stamp_tween = TweenUtils.animate_to(end_label, "global_position", target_pos, descend_duration, Tween.TRANS_EXPO, Tween.EASE_IN, Callable(), stamp_tween)
	stamp_tween.tween_callback(_play_end_sfx)
	stamp_tween.tween_callback( func(): ScreenShake.shake(get_tree().current_scene as Control, shake_duration, shake_strength))

func _stamp(label: Label, text: String, at: Vector2) -> void :
	label.text = text
	label.visible = false
	label.modulate.a = 1.0
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
		fade_tween = null

	var half: = stamp_visual.size / 2.0
	var start_pos: = Vector2(at.x + start_x_offset, - stamp_visual.size.y - start_top_margin)
	var target: = at - half
	stamp_visual.global_position = start_pos
	stamp_visual.visible = true

	stamp_tween = TweenUtils.animate_to(stamp_visual, "global_position", target, descend_duration, Tween.TRANS_EXPO, Tween.EASE_IN, Callable(), stamp_tween)
	stamp_tween.tween_callback(_on_impact.bind(label, at))
	stamp_tween.tween_interval(pause_duration)
	stamp_tween.tween_property(stamp_visual, "global_position", start_pos, ascend_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	stamp_tween.tween_callback( func(): stamp_visual.visible = false)
	if fade_duration > 0.0:
		stamp_tween.tween_callback(_fade_label.bind(label))
	else:
		stamp_tween.tween_callback( func(): label.visible = false)

func _fade_label(label: Label) -> void :
	fade_tween = TweenUtils.animate_to(label, "modulate:a", 0.0, fade_duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, func(): label.visible = false;label.modulate.a = 1.0;fade_tween = null, fade_tween)

func _reset_label(label: Label) -> void :
	label.visible = false
	label.modulate.a = 1.0

func _play_end_sfx() -> void :
	var clip: = end_stamp_sfx if end_stamp_sfx != null else stamp_sfx
	if clip:
		SoundManager.play_sfx(clip)

func _on_impact(label: Label, at: Vector2):
	if stamp_sfx:
		SoundManager.play_sfx(stamp_sfx)
	label.global_position = at + label_offset - label.size / 2.0
	label.visible = true
	_spawn_ink_splash(at)
	ScreenShake.shake(get_tree().current_scene as Control, shake_duration, shake_strength)

func _spawn_ink_splash(at: Vector2) -> void :
	var splash: = InkSplashScene.instantiate() as InkSplash
	if splash == null:
		return
	splash.ink_color = start_splash_color
	splash.z_index = 50
	add_child(splash)
	splash.global_position = at
